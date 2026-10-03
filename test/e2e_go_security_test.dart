// Tests of unitdb's security stage 2 against the real unitdb server (Go):
// v2 client IDs and topic keys, client ID renewal, keygen with a ttl,
// revocation, and a service vouching for a connection. They run when
// UNITDB_E2E_GO=1, as e2e_go_server_test.dart, against a server source that
// has them (skipped otherwise). They build the server's cmd/mintid for v1
// IDs, IDs of a given contract or lifetime, and service IDs.
@Tags(['go-server'])
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' hide ByteBuffer;

import 'package:test/test.dart';
import 'package:unitdb_client/unitdb_client.dart';

import 'support/go_server.dart';
import 'support/proxy.dart';

final base64url = RegExp(r'^[A-Za-z0-9_-]+$');
final decimal = RegExp(r'^[0-9]+$');

/// eventually waits until cond holds, or fails the test after timeout.
Future<void> eventually(String what, bool Function() cond,
    {Duration timeout = const Duration(seconds: 15)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!cond()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('timed out waiting for $what');
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

Uint8List bytes(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  final enabled = Platform.environment['UNITDB_E2E_GO'] == '1';
  final stage2 = enabled && serverHasSecurityStage2();
  final skip = !enabled
      ? 'set UNITDB_E2E_GO=1 to run against the Go server'
      : !stage2
          ? 'the server at ${serverDir()} predates security stage 2 '
              '(v2 IDs and keys, renewal, unitdb/revoke)'
          : false;
  // client_id_ttl and primary_id_ttl give renewed IDs a lifetime: a fresh
  // one is not renewed again.
  final server = GoServer(config: {'client_id_ttl': '1h', 'primary_id_ttl': '1h'});
  final clients = <Client>[];

  setUpAll(() async {
    if (stage2) await server.start();
  });
  tearDownAll(() async {
    if (stage2) await server.stop();
  });
  tearDown(() async {
    for (final c in clients) {
      try {
        await c.disconnect().timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
    clients.clear();
    if (stage2 && server.process == null) await server.start();
  });

  String target() => '127.0.0.1:${server.grpcPort}';

  Options options() => Options()
      .withAutoReconnect(false)
      .withConnectTimeout(const Duration(seconds: 5));

  /// connect connects a client with clientID, without the insecure flag
  /// unless opts has it, and fails the test unless it is accepted.
  Future<Client> connect(String clientID, [Options? opts, String? to]) async {
    final c = Client(to ?? target(), clientID, opts ?? options());
    clients.add(c);
    final r = await c.connect().timeout(const Duration(seconds: 15)) as ConnectResult;
    expect(r.error(), isNull, reason: 'connect: return code ${r.returnCode}\n${server.logs}');
    return c;
  }

  /// returnCode connects a client with clientID, and returns the return code
  /// of its connect.
  Future<int?> returnCode(String clientID) async {
    final c = Client(target(), clientID, options());
    final r = await c.connect().timeout(const Duration(seconds: 15)) as ConnectResult;
    if (r.error() == null) await c.disconnect();
    return r.returnCode;
  }

  /// published publishes to topic on c, and reports whether the server took
  /// it: it acknowledges it, or refuses it with a message on unitdb/error/.
  Future<bool> published(Client c, String topic) async {
    var refused = false;
    final sub = c.messageStream.listen((ms) {
      if (ms.any((m) => m.topic == 'unitdb/error/')) refused = true;
    });
    try {
      final p = c.publish(topic, bytes('x'));
      await eventually('the publish to $topic taken or refused',
          () => refused || p.completer.isCompleted,
          timeout: const Duration(seconds: 5));
      return !refused && p.error() == null;
    } finally {
      await sub.cancel();
    }
  }

  /// status waits for an API request's result, and returns its status.
  Future<int?> status(ApiResult r) async {
    try {
      await r.get(const Duration(seconds: 5));
    } catch (_) {}
    return r.status;
  }

  test('renews a v1 client ID: adopted, told, used to reconnect, sessions kept', () async {
    final v1 = (await mintid(server, ['-v1'])).clientID;
    expect(v1.length, 52);
    final proxy = Proxy(server.grpcPort);
    await proxy.start();
    addTearDown(proxy.stop);

    // A local store of its own, kept by user name.
    final user = 'dart-renew-$pid';
    addTearDown(() {
      final f = File('db_$user.sqlite');
      if (f.existsSync()) f.deleteSync();
    });
    final renewed = <String>[];
    var connected = 0, lost = 0;
    final client = await connect(
        v1,
        Options()
            .withInsecure()
            .withUserNamePassword(user, Uint8List(0))
            .withPersistenceStore(PersistenceStore.Localdb)
            .withSessionKey(0x5e55) // a session of its own: the publisher shares the ID
            .withClientIdHandler(renewed.add)
            .withConnectionHandler((_) => connected++)
            .withConnectionLostHandler(() => lost++)
            .withMaxReconnectDuration(const Duration(milliseconds: 500))
            .withConnectTimeout(const Duration(seconds: 2)),
        '127.0.0.1:${proxy.port}');
    final store = client.localStore;
    final sessionId = client.sessionId;
    expect(store, isNotNull);

    await eventually('the renewed client ID', () => renewed.isNotEmpty);
    final v2 = renewed.single;
    expect(v2.length, 94, reason: 'a v2 client ID');
    expect(v2, matches(base64url));
    expect(client.clientId, v2);

    final got = <String>[];
    client.messageStream.listen((ms) => got.addAll(
        ms.where((m) => m.topic.startsWith('dart.')).map((m) => utf8.decode(m.payload))));
    final s = client.subscribe('dart.renew.reliable', deliveryMode: DeliveryMode.reliable);
    expect(await s.get(const Duration(seconds: 5)), isTrue, reason: 'subscribe: ${s.error()}');

    // Reliable messages the client does not get before its connection
    // drops: only its resumed session on the server has them.
    proxy.hold = true;
    final pub = await connect(v1, options().withInsecure());
    for (final m in ['r0', 'r1', 'r2']) {
      final p = pub.publish('dart.renew.reliable', bytes(m), deliveryMode: DeliveryMode.reliable);
      expect(await p.get(const Duration(seconds: 5)), isTrue);
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(got, isEmpty);
    await proxy.cut();
    await eventually('the connection lost handler', () => lost > 0);
    await proxy.start();
    await eventually('the reconnection', () => connected >= 2);
    await eventually('the messages of the resumed session',
        () => ['r0', 'r1', 'r2'].every(got.contains),
        timeout: const Duration(seconds: 20));

    // It reconnected with the renewed ID: the v1 one would be renewed again.
    await Future<void>.delayed(const Duration(seconds: 1));
    expect(renewed, [v2], reason: 'the reconnect was renewed again');
    expect(client.clientId, v2);
    // The local store and session stay.
    expect(client.localStore, same(store));
    expect(client.sessionId, sessionId);
  }, skip: skip);

  test('renews an ID near its expiry, and reconnects with it once the old one expired', () async {
    // Renewed past 80% of its 10 s: from 8 s on.
    final old = (await mintid(server, ['-ttl', '10s'])).clientID;
    final minted = DateTime.now();
    expect(old.length, 94);
    await Future<void>.delayed(const Duration(milliseconds: 8500));

    final renewed = <String>[];
    var connected = 0, lost = 0;
    final client = await connect(
        old,
        Options()
            .withInsecure()
            .withClientIdHandler(renewed.add)
            .withConnectionHandler((_) => connected++)
            .withConnectionLostHandler(() => lost++)
            .withMaxReconnectDuration(const Duration(milliseconds: 500))
            .withConnectTimeout(const Duration(seconds: 2)));
    await eventually('the renewed client ID', () => renewed.isNotEmpty);
    expect(renewed.single, isNot(old));
    expect(client.clientId, renewed.single);

    // Once the old ID expired, the server refuses it.
    final expiry = minted.add(const Duration(seconds: 11));
    await Future<void>.delayed(expiry.difference(DateTime.now()));
    expect(await returnCode(old), ConnectReturnCode.ErrRefusedIDRejected.index);

    // The client reconnects, with the renewed ID.
    await server.kill();
    await eventually('the connection lost handler', () => lost > 0);
    await server.start();
    await eventually('the reconnection', () => connected >= 2, timeout: const Duration(seconds: 20));
    final s = client.subscribe('dart.renew.expiry');
    expect(await s.get(const Duration(seconds: 5)), isTrue);
    expect(renewed, hasLength(1));
  }, skip: skip);

  test('keygen: v2 keys with a uuid, a ttl, and topics parsed with them', () async {
    final primary = await connect(await newClientID(server.grpcPort));
    final idr = primary.requestClientId();
    expect(await idr.get(const Duration(seconds: 5)), isTrue);
    expect(idr.clientId.length, 94);
    expect(idr.clientId, matches(base64url));
    expect(idr.uuid, matches(decimal));
    final user = await connect(idr.clientId);

    // A key with '-' or '_' in it: most have one.
    const topic = 'dart.keys.v2-topic_a';
    TopicKey? key;
    for (var i = 0; i < 20 && key == null; i++) {
      final r = primary.keygen([KeyRequest(topic, ttl: '1h')]);
      expect(await r.get(const Duration(seconds: 5)), isTrue);
      final k = r.keys.single;
      expect(k.status, 200);
      expect(k.topic, topic);
      expect(k.key.length, 48, reason: 'a v2 key');
      expect(k.key, matches(base64url));
      expect(k.uuid, matches(decimal));
      if (k.key.contains('-') || k.key.contains('_')) key = k;
    }
    expect(key, isNotNull, reason: "no key with '-' or '_'");

    // The client parses keyed topics, and the server takes them.
    final keyed = '${key!.key}/$topic';
    expect(PublicationTopic(keyed).topic, topic);
    final filter = TopicFilter(keyed, user.messageStream);
    final got = <String>[];
    filter.messageStream.listen((ms) => got.addAll(ms.map((m) => utf8.decode(m.payload))));
    final s = user.subscribe(keyed);
    expect(await s.get(const Duration(seconds: 5)), isTrue);
    final p = primary.publish(keyed, bytes('v2'));
    expect(await p.get(const Duration(seconds: 5)), isTrue, reason: 'publish: ${p.error()}');
    await eventually('the message on the keyed topic', () => got.contains('v2'));

    // A key with a ttl of its own expires.
    final short = primary.keygen([KeyRequest('dart.keys.short', ttl: '2s')]);
    expect(await short.get(const Duration(seconds: 5)), isTrue);
    final shortKey = short.keys.single.key;
    expect(await published(user, '$shortKey/dart.keys.short'), isTrue);
    await Future<void>.delayed(const Duration(seconds: 3));
    expect(await published(user, '$shortKey/dart.keys.short'), isFalse,
        reason: 'an expired key opened its topic');

    // A ttl that is not a duration; a client that is not primary.
    expect(await status(primary.keygen([KeyRequest(topic, ttl: 'soon')])), 400);
    expect(await status(user.keygen([KeyRequest(topic)])), 403);
  }, skip: skip);

  test('revokes a key and a client ID by uuid', () async {
    final primary = await connect(await newClientID(server.grpcPort));
    final idr = primary.requestClientId();
    expect(await idr.get(const Duration(seconds: 5)), isTrue);
    final user = await connect(idr.clientId);

    Future<TopicKey> keygen(String topic) async {
      final r = primary.keygen([KeyRequest(topic)]);
      expect(await r.get(const Duration(seconds: 5)), isTrue);
      return r.keys.single;
    }

    final key = await keygen('dart.revoke.key');
    expect(await published(user, '${key.key}/dart.revoke.key'), isTrue);
    // Not by a secondary client.
    expect(await status(user.revoke(key.uuid)), 403);
    expect(await status(user.revokeAll()), 403);
    expect(await published(user, '${key.key}/dart.revoke.key'), isTrue);

    final r = primary.revoke(key.uuid);
    expect(await r.get(const Duration(seconds: 5)), isTrue);
    expect(r.status, 200);
    expect(await published(user, '${key.key}/dart.revoke.key'), isFalse,
        reason: 'a revoked key opened its topic');

    // Until a time to come.
    final until = await keygen('dart.revoke.until');
    expect(await status(primary.revoke(until.uuid,
        until: DateTime.now().add(const Duration(hours: 1)))), 200);
    expect(await published(user, '${until.key}/dart.revoke.until'), isFalse);

    // Nothing to revoke, or an until gone by.
    expect(await status(primary.revoke('0')), 400);
    expect(await status(primary.revoke('not-a-number')), 400);
    expect(await status(primary.revoke(until.uuid,
        until: DateTime.now().subtract(const Duration(hours: 1)))), 400);

    // A client ID: refused at connect, with return code 2.
    expect(await status(primary.revoke(idr.uuid)), 200);
    expect(await returnCode(idr.clientId), ConnectReturnCode.ErrRefusedIDRejected.index);
  }, skip: skip);

  test('revokes every ID and key the contract was issued', () async {
    final contract = 0x7e5c0000 + pid % 0x10000;
    final admin = (await mintid(server, ['-contract', '$contract'])).clientID;
    final primary = await connect(admin);
    final r = primary.keygen([KeyRequest('dart.revoke.all')]);
    expect(await r.get(const Duration(seconds: 5)), isTrue);
    final key = r.keys.single.key;
    final idr = primary.requestClientId();
    expect(await idr.get(const Duration(seconds: 5)), isTrue);

    // Issue times are whole seconds.
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    final all = primary.revokeAll();
    expect(await all.get(const Duration(seconds: 5)), isTrue);
    expect(all.status, 200);
    expect(await returnCode(idr.clientId), ConnectReturnCode.ErrRefusedIDRejected.index);
    expect(await returnCode(admin), ConnectReturnCode.ErrRefusedIDRejected.index);

    // What the contract is issued after works; what it was before does not.
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    final after = await connect((await mintid(server, ['-contract', '$contract'])).clientID);
    expect(await published(after, '$key/dart.revoke.all'), isFalse,
        reason: 'a key issued before revoking all opened its topic');
    final fresh = after.keygen([KeyRequest('dart.revoke.all')]);
    expect(await fresh.get(const Duration(seconds: 5)), isTrue);
    expect(await published(after, '${fresh.keys.single.key}/dart.revoke.all'), isTrue);
  }, skip: skip);

  test('a service vouches for a connection', () async {
    final contract = 0x5e7c0000 + pid % 0x10000;
    final service = await mintid(server, ['-contract', '$contract', '-service']);
    final admin = (await mintid(server, ['-contract', '$contract'])).clientID;
    final primary = await connect(admin);
    final idr = primary.requestClientId();
    expect(await idr.get(const Duration(seconds: 5)), isTrue);
    final user = await connect(idr.clientId);

    // Without topic keys, refused.
    expect(await published(user, 'dart.vouch.topic'), isFalse);
    // Not by an ID that is not a service's.
    expect(await status(user.vouch(admin)), 403);
    expect(await published(user, 'dart.vouch.topic'), isFalse);

    final v = user.vouch(service.clientID);
    expect(await v.get(const Duration(seconds: 5)), isTrue);
    expect(v.status, 200);
    expect(await published(user, 'dart.vouch.topic'), isTrue);
    // A service hands its users keys.
    final k = user.keygen([KeyRequest('dart.vouch.keyed')]);
    expect(await k.get(const Duration(seconds: 5)), isTrue);
    expect(k.keys.single.key.length, 48);

    // A service of another contract does not vouch.
    final other = await mintid(server, ['-contract', '${contract + 1}', '-service']);
    final stranger = await connect(idr.clientId);
    expect(await status(stranger.vouch(other.clientID)), 403);
  }, skip: skip);
}
