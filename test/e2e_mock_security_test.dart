// Tests of client ID renewal and the server's API requests (keygen, client
// IDs, revocation, vouching) against the in-process server of
// support/mock_server.dart: what the client sends, and how it takes the
// answers. e2e_go_security_test.dart runs them against the Go server.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data' hide ByteBuffer;

import 'package:test/test.dart';
import 'package:unitdb_client/src/v1/unitdb/schema.pb.dart' as pbx;
import 'package:unitdb_client/unitdb_client.dart';

import 'support/mock_server.dart';

const wait = Duration(seconds: 5);

// A v1 client ID, and a v2 one, as the server issues them: 94 characters of
// base64url, '-' and '_' included.
const v1ID = 'UCBFDONCNJLaKMCAIeJBaOVfbAXUZHNPLDKKLDKLHZHKYIZLCDPQ';
const v2ID =
    'AQ-_mZkS7c3lV0rB8xYqN2uT5wHjK1pLs9dFgE6hC4vRaXoIbM3nP0QeWzUyJtGi_kOl7fDs-8vA2cBn5mXq1rTy6uIo9p';

Future<void> eventually(String what, bool Function() cond,
    {Duration timeout = wait}) async {
  final deadline = DateTime.now().add(timeout);
  while (!cond()) {
    if (DateTime.now().isAfter(deadline)) fail('timed out waiting for $what');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  late MockServer server;
  final clients = <Client>[];

  setUp(() async {
    server = MockServer();
    await server.start();
  });

  tearDown(() async {
    for (final c in clients) {
      try {
        await c.disconnect().timeout(wait);
      } catch (_) {}
    }
    clients.clear();
    await server.stop();
  });

  Future<Client> connected(Options opts, {String clientID = v1ID}) async {
    final c = Client('127.0.0.1:${server.port}', clientID,
        opts.withConnectTimeout(const Duration(seconds: 3)));
    clients.add(c);
    final r = await c.connect().timeout(wait);
    expect(r.error(), isNull, reason: 'connect failed');
    return c;
  }

  /// connectIDs returns the client IDs of the CONNECTs the server got.
  List<String> connectIDs() => [
        for (final s in server.sessions)
          for (final f in s.received)
            if (f.type == pbx.MessageType.CONNECT && f.flow == pbx.FlowControl.NONE)
              pbx.Connect.fromBuffer(f.body).clientID
      ];

  group('client ID renewal', () {
    test('is adopted, told to the handler, and used to reconnect', () async {
      expect(v2ID.length, 94);
      server.renewClientID = v2ID;
      final renewed = <String>[];
      var connectedCount = 0;
      final c = await connected(Options()
          .withClientIdHandler(renewed.add)
          .withConnectionHandler((_) => connectedCount++)
          .withMaxReconnectDuration(const Duration(milliseconds: 200)));
      final topics = <String>[];
      c.messageStream.listen((ms) => topics.addAll(ms.map((m) => m.topic)));

      await eventually('the client ID handler', () => renewed.isNotEmpty);
      expect(renewed, [v2ID]);
      expect(c.clientId, v2ID);

      // The server loses the connection: the client reconnects with the
      // renewed ID.
      server.sessions.single.close();
      await eventually('the reconnection', () => connectedCount >= 2);
      expect(connectIDs(), [v1ID, v2ID]);
      expect(renewed, [v2ID], reason: 'the handler is called once per renewal');
    });

    test('is adopted without a handler, and used by a later connect', () async {
      server.renewClientID = v2ID;
      final c = await connected(Options());
      await eventually('the renewal', () => c.clientId == v2ID);
      await c.disconnect();
      final r = await c.connect().timeout(wait);
      expect(r.error(), isNull);
      expect(connectIDs(), [v1ID, v2ID]);
    });

    test('a handler that throws does not stop the client', () async {
      server.renewClientID = v2ID;
      final c = await connected(
          Options().withClientIdHandler((_) => throw StateError('app bug')));
      await eventually('the renewal', () => c.clientId == v2ID);
      final p = c.publish('dart.renew.after', Uint8List.fromList([1]));
      await p.completer.future.timeout(wait);
      expect(p.error(), isNull);
    });

    test('an ID the client already has is not told again', () async {
      server.renewClientID = v1ID;
      final renewed = <String>[];
      final c = await connected(Options().withClientIdHandler(renewed.add));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(renewed, isEmpty);
      expect(c.clientId, v1ID);
    });
  });

  group('API requests', () {
    /// requests records the API requests the server got, as decoded JSON.
    final requests = <String, List<Object?>>{};
    setUp(() => requests.clear());

    void answer(Map<String, Object?> answers) {
      server.answerApi = (topic, payload) {
        (requests[topic] ??= []).add(jsonDecode(utf8.decode(payload)));
        final a = answers[topic];
        return a == null ? null : utf8.encode(jsonEncode(a));
      };
    }

    test('keygen sends ttl, and gives the keys and their uuids', () async {
      final key = 'Ab-_' * 12;
      answer({
        'unitdb/keygen': [
          {'status': 200, 'key': key, 'topic': 'teams.alpha...', 'uuid': '1234567890123'},
          {'status': 200, 'key': 'K' * 26, 'topic': 'teams.beta', 'uuid': ''},
        ]
      });
      final c = await connected(Options());
      final r = c.keygen([
        KeyRequest('teams.alpha...', ttl: '24h'),
        KeyRequest('teams.beta', type: 'r'),
      ]);
      expect(await r.get(wait), isTrue);
      expect(requests['unitdb/keygen'], [
        [
          {'topic': 'teams.alpha...', 'type': 'rw', 'ttl': '24h'},
          {'topic': 'teams.beta', 'type': 'r'},
        ]
      ]);
      expect(r.status, 200);
      expect(r.keys.map((k) => [k.key, k.topic, k.uuid]), [
        [key, 'teams.alpha...', '1234567890123'],
        ['K' * 26, 'teams.beta', ''],
      ]);
    });

    test('a refused request fails with the status', () async {
      answer({
        'unitdb/keygen': {'status': 403, 'message': 'use the primary client Id'}
      });
      final c = await connected(Options());
      final r = c.keygen([KeyRequest('teams.alpha')]);
      await expectLater(r.get(wait), throwsA(contains('403')));
      expect(r.status, 403);
      expect(r.message, 'use the primary client Id');
      expect(r.keys, isEmpty);
    });

    test('requestClientId gives the ID and its uuid', () async {
      answer({
        'unitdb/clientid': {'status': 200, 'key': v2ID, 'uuid': '42'}
      });
      final c = await connected(Options());
      final r = c.requestClientId();
      expect(await r.get(wait), isTrue);
      expect(r.clientId, v2ID);
      expect(r.uuid, '42');
    });

    test('revoke, revokeAll and vouch send their requests', () async {
      answer({
        'unitdb/revoke': {'status': 200},
        'unitdb/service': {'status': 200},
      });
      final c = await connected(Options());
      final until = DateTime.utc(2030, 1, 2, 3, 4, 5);
      for (final r in [
        c.revoke('18446744073709551615'),
        c.revoke('7', until: until),
        c.revokeAll(),
        c.vouch(v2ID),
      ]) {
        expect(await r.get(wait), isTrue);
        expect(r.status, 200);
      }
      expect(requests['unitdb/revoke'], [
        {'uuid': '18446744073709551615'},
        {'uuid': '7', 'until': until.millisecondsSinceEpoch ~/ 1000},
        {'all': true},
      ]);
      expect(requests['unitdb/service'], [
        {'client_id': v2ID}
      ]);
    });

    test('answers complete the requests in order', () async {
      var n = 0;
      server.answerApi = (topic, payload) =>
          utf8.encode(jsonEncode({'status': 200, 'key': 'id${n++}', 'uuid': '$n'}));
      final c = await connected(Options());
      final rs = [for (var i = 0; i < 5; i++) c.requestClientId()];
      for (var i = 0; i < rs.length; i++) {
        expect(await rs[i].get(wait), isTrue);
        expect(rs[i].clientId, 'id$i');
      }
    });

    test('fails on disconnect without an answer, and when not connected',
        () async {
      final c = await connected(Options());
      final r = c.revokeAll(); // the mock does not answer
      await c.disconnect();
      await expectLater(r.get(wait), throwsA(anything));
      await expectLater(c.vouch(v2ID).get(wait), throwsA(anything));
    });
  });
}
