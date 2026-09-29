// Reconnection tests against the real unitdb server (Go): a client with
// auto reconnect loses its server and connects again by itself. Ported from
// unitdb-go's reconnect_e2e_test.go. They run when UNITDB_E2E_GO=1, as
// e2e_go_server_test.dart.
@Tags(['go-server'])
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' hide ByteBuffer;

import 'package:test/test.dart';
import 'package:unitdb_client/unitdb_client.dart';

import 'support/go_server.dart';
import 'support/proxy.dart';

/// Events records a client's connection handler calls.
class Events {
  int connected = 0;
  int lost = 0;

  Options options(Options o) => o
      .withConnectionHandler((_) => connected++)
      .withConnectionLostHandler(() => lost++);
}

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

void main() {
  final enabled = Platform.environment['UNITDB_E2E_GO'] == '1';
  final skip = enabled ? false : 'set UNITDB_E2E_GO=1 to run against the Go server';
  final server = GoServer();

  setUpAll(() async {
    if (enabled) await server.start();
  });
  tearDownAll(() async {
    if (enabled) await server.stop();
  });
  // Every test leaves the server running for the next.
  tearDown(() async {
    if (enabled && server.process == null) await server.start();
  });

  String target() => '127.0.0.1:${server.grpcPort}';

  Options reconnecting(Events e) => e.options(Options()
      .withInsecure()
      .withAutoReconnect(true)
      .withMaxReconnectDuration(const Duration(milliseconds: 500))
      .withConnectTimeout(const Duration(seconds: 2)));

  /// publishOnce publishes payload on topic from a client of its own, with
  /// clientID: a client ID is a contract's, and topics are the contract's.
  Future<void> publishOnce(String clientID, String topic, String payload,
      {String ttl = '', DeliveryMode deliveryMode = DeliveryMode.express}) async {
    final pub = Client(target(), clientID,
        Options().withInsecure().withAutoReconnect(false));
    final r = await pub.connect().timeout(const Duration(seconds: 10));
    expect(r.error(), isNull);
    final p = pub.publish(topic, Uint8List.fromList(utf8.encode(payload)),
        ttl: ttl, deliveryMode: deliveryMode);
    expect(await p.get(const Duration(seconds: 5)), isTrue, reason: 'publish: ${p.error()}');
    await pub.disconnect();
  }

  test('reconnects after a server restart and receives again', () async {
    final e = Events();
    final cid = await newClientID(server.grpcPort);
    final client = Client(target(), cid, reconnecting(e));
    final r = await client.connect().timeout(const Duration(seconds: 10));
    expect(r.error(), isNull, reason: 'server logs:\n${server.logs}');
    final got = <String>[];
    client.messageStream.listen((ms) => got.addAll(ms.map((m) => utf8.decode(m.payload))));
    final s = client.subscribe('dart.rc.restart');
    expect(await s.get(const Duration(seconds: 5)), isTrue, reason: 'subscribe: ${s.error()}');

    await server.kill();
    await eventually('the connection lost handler', () => e.lost > 0);
    // The server is down for a while: the client keeps trying.
    await Future<void>.delayed(const Duration(seconds: 1));
    await server.start();
    await eventually('the reconnection', () => e.connected >= 2);
    await Future<void>.delayed(const Duration(milliseconds: 500));

    await publishOnce(cid, 'dart.rc.restart', 'back');
    await eventually('the message after the restart', () => got.contains('back'));
    await client.disconnect();
  }, skip: skip);

  test('a reconnect resumes the session: messages in flight are delivered', () async {
    // The client reaches the server through a proxy, which can stall and cut
    // its connection while the server stays up.
    final proxy = Proxy(server.grpcPort);
    await proxy.start();
    addTearDown(proxy.stop);

    final e = Events();
    final cid = await newClientID(server.grpcPort);
    // A session of its own: the publisher shares the client ID.
    final client = Client('127.0.0.1:${proxy.port}', cid, reconnecting(e).withSessionKey(0x5e55));
    expect((await client.connect().timeout(const Duration(seconds: 10))).error(), isNull);
    final got = <String>[];
    client.messageStream.listen((ms) => got.addAll(ms.map((m) => utf8.decode(m.payload))));
    final s = client.subscribe('dart.rs.reliable', deliveryMode: DeliveryMode.reliable);
    expect(await s.get(const Duration(seconds: 5)), isTrue, reason: 'subscribe: ${s.error()}');

    // Reliable messages published while the server's notifications do not
    // reach the client: the server keeps them in the session's log until the
    // client receives them. It keeps no express message.
    proxy.hold = true;
    for (final m in ['r0', 'r1', 'r2']) {
      await publishOnce(cid, 'dart.rs.reliable', m, deliveryMode: DeliveryMode.reliable);
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(got, isEmpty, reason: 'the proxy let notifications through');

    // The connection drops, and the client reconnects a while later. Only a
    // resumed session has the messages: a new one, or a new subscription,
    // does not.
    await proxy.cut();
    await eventually('the connection lost handler', () => e.lost > 0);
    await Future<void>.delayed(const Duration(seconds: 1));
    await proxy.start();
    await eventually('the reconnection', () => e.connected >= 2);
    await eventually('the messages of the resumed session',
        () => ['r0', 'r1', 'r2'].every(got.contains),
        timeout: const Duration(seconds: 20));
    await client.disconnect();
  }, skip: skip);

  test('a publish made while reconnecting waits for the connection', () async {
    final e = Events();
    final cid = await newClientID(server.grpcPort);
    final client = Client(target(), cid,
        reconnecting(e).withWriteTimeout(const Duration(seconds: 20)));
    expect((await client.connect().timeout(const Duration(seconds: 10))).error(), isNull);

    await server.kill();
    await eventually('the connection lost handler', () => e.lost > 0);
    final p = client.publish('dart.rc.queued', Uint8List.fromList(utf8.encode('queued')),
        ttl: '1h');
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await server.start();
    expect(await p.get(const Duration(seconds: 20)), isTrue,
        reason: 'publish made while reconnecting: ${p.error()}');

    // The message was stored: a relay from another client returns it.
    final reader = Client(target(), cid, Options().withInsecure().withAutoReconnect(false));
    expect((await reader.connect().timeout(const Duration(seconds: 10))).error(), isNull);
    final got = <String>[];
    reader.messageStream.listen((ms) => got.addAll(ms.map((m) => utf8.decode(m.payload))));
    reader.relay(['dart.rc.queued'], last: '1h');
    await eventually('the relayed message', () => got.contains('queued'));
    await reader.disconnect();
    await client.disconnect();
  }, skip: skip);

  test('disconnect while reconnecting returns, and the client stays closed', () async {
    final e = Events();
    final client = Client(target(), await newClientID(server.grpcPort), reconnecting(e));
    expect((await client.connect().timeout(const Duration(seconds: 10))).error(), isNull);

    await server.kill();
    await eventually('the connection lost handler', () => e.lost > 0);
    await client.disconnect().timeout(const Duration(seconds: 1),
        onTimeout: () => fail('disconnect while reconnecting did not return'));

    await server.start();
    final connected = e.connected;
    await Future<void>.delayed(const Duration(seconds: 2));
    expect(e.connected, connected, reason: 'the client reconnected after disconnect');
    final p = client.publish('dart.rc.closed', Uint8List.fromList([1]));
    expect(p.get(const Duration(seconds: 1)), throwsA(anything),
        reason: 'publish after disconnect succeeded');
  }, skip: skip);

  test('does not reconnect with auto reconnect off', () async {
    final e = Events();
    final client = Client(target(), await newClientID(server.grpcPort),
        e.options(Options().withInsecure().withAutoReconnect(false)));
    expect((await client.connect().timeout(const Duration(seconds: 10))).error(), isNull);

    await server.kill();
    await eventually('the connection lost handler', () => e.lost > 0);
    await server.start();
    await Future<void>.delayed(const Duration(seconds: 2));
    expect(e.connected, 1, reason: 'the client reconnected with auto reconnect off');
  }, skip: skip);

  test('connects to the next server when the first is down', () async {
    final dead = await freePort();
    final e = Events();
    // The target is tried after the servers added.
    final client = Client(target(), await newClientID(server.grpcPort),
        e.options(Options().withInsecure().withConnectTimeout(const Duration(seconds: 2)))
          ..addServer('127.0.0.1:$dead'));
    final r = await client.connect().timeout(const Duration(seconds: 15));
    expect(r.error(), isNull, reason: 'connect with the first server down');
    expect(e.connected, 1);
    await client.disconnect();
  }, skip: skip);
}
