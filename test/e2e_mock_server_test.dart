// End-to-end tests of the client against an in-process gRPC server that speaks
// the client's own protocol (see support/mock_server.dart). Each test uses real
// Client objects over a real HTTP/2 connection and checks both what the client
// reports and what the server saw on the wire.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data' hide ByteBuffer;

import 'package:test/test.dart';
import 'package:unitdb_client/src/v1/unitdb/schema.pb.dart' as pbx;
import 'package:unitdb_client/unitdb_client.dart';

import 'support/mock_server.dart';

const clientID = 'UCBFDONCNJLaKMCAIeJBaOVfbAXUZHNPLDKKLDKLHZHKYIZLCDPQ';
const wait = Duration(seconds: 5);

Uint8List bytes(String s) => Uint8List.fromList(utf8.encode(s));

/// Waits for a client call to be acknowledged by the server. It uses the
/// result's completer directly rather than Result.get, which waits out its
/// whole duration (see result_test.dart).
Future<void> acked(Result r) async {
  await r.completer.future.timeout(wait);
  expect(r.error(), isNull);
}

void main() {
  MockServer server;
  final clients = <Client>[];

  setUp(() async {
    server = MockServer();
    await server.start();
  });

  tearDown(() async {
    for (final c in clients) {
      try {
        await c.disconnect().timeout(wait);
      } catch (_) {
        // A failing disconnect is covered by its own test.
      }
    }
    clients.clear();
    await server.stop();
  });

  Client newClient([Options opts]) {
    final c = Client('127.0.0.1:${server.port}', clientID,
        (opts ?? Options()).withConnectTimeout(const Duration(seconds: 3)));
    clients.add(c);
    return c;
  }

  Future<Client> connected([Options opts]) async {
    final c = newClient(opts);
    final r = await c.connect().timeout(wait);
    expect(r.error(), isNull, reason: 'connect failed');
    return c;
  }

  group('connect', () {
    test('is accepted and sends the client id', () async {
      final c = newClient(Options().withInsecure().withCleanSession());
      final r = await c.connect().timeout(wait) as ConnectResult;
      expect(r.error(), isNull);
      expect(r.returnCode, ConnectReturnCode.Accepted.index);

      final connect = server.sessions.single.connect;
      expect(connect.clientID, clientID);
      expect(connect.insecureFlag, isTrue);
      expect(connect.cleanSessFlag, isTrue);
    });

    test('sends the keep-alive interval', () async {
      await connected(Options().withKeepAlive(20));
      expect(server.sessions.single.connect.keepAlive, 20);
    });

    test('reports a refusal and its return code', () async {
      server.connectReturnCode = ConnectReturnCode.ErrNotAuthorised.index;
      final c = newClient();
      ConnectResult r;
      Object thrown;
      try {
        r = await c.connect().timeout(wait) as ConnectResult;
      } catch (e) {
        thrown = e;
      }
      expect(thrown, isNull, reason: 'connect threw instead of returning a result: $thrown');
      expect(r.error(), isNotNull);
      expect(r.returnCode, ConnectReturnCode.ErrNotAuthorised.index);
    });

    test('reports an error when no server is listening', () async {
      final port = server.port;
      await server.stop();
      final c = Client('127.0.0.1:$port', clientID,
          Options().withConnectTimeout(const Duration(seconds: 2)));
      clients.add(c);
      Result r;
      Object thrown;
      try {
        r = await c.connect().timeout(const Duration(seconds: 10));
      } catch (e) {
        thrown = e;
      }
      expect(thrown, isNull, reason: 'connect threw instead of returning a result: $thrown');
      expect(r.error(), isNotNull);
      server = MockServer();
      await server.start(); // for tearDown
    });
  });

  group('publish and subscribe', () {
    test('a subscriber receives what a publisher sends', () async {
      final sub = await connected();
      final got = <Message>[];
      sub.messageStream.listen(got.addAll);
      await acked(sub.subscribe('groups.private.x.message'));

      final pub = await connected();
      await acked(pub.publish('groups.private.x.message', bytes('hello'), ttl: '1m'));

      await _eventually(() => got.isNotEmpty);
      expect(got.single.topic, 'groups.private.x.message');
      expect(utf8.decode(got.single.payload), 'hello');

      final wire = pbx.Publish.fromBuffer(server.sessions[1].received
          .firstWhere((f) => f.type == pbx.MessageType.PUBLISH)
          .body);
      expect(wire.messages.single.ttl, '1m');
    });

    test('many messages arrive in order without loss', () async {
      final sub = await connected();
      final got = <String>[];
      sub.messageStream.listen((ms) => got.addAll(ms.map((m) => utf8.decode(m.payload))));
      await acked(sub.subscribe('groups.order.message'));

      final pub = await connected();
      final results = [
        for (var i = 0; i < 200; i++) pub.publish('groups.order.message', bytes('m$i'))
      ];
      for (final r in results) {
        await acked(r);
      }
      await _eventually(() => got.length >= 200);
      expect(got, [for (var i = 0; i < 200; i++) 'm$i']);
    });

    test('a topic filter selects matching messages', () async {
      final sub = await connected();
      final filter = TopicFilter('groups.*.message', sub.messageStream);
      final got = <String>[];
      filter.messageStream.listen((ms) => got.addAll(ms.map((m) => m.topic)));
      await acked(sub.subscribe('groups.a.message'));
      await acked(sub.subscribe('groups.b.other'));

      final pub = await connected();
      await acked(pub.publish('groups.a.message', bytes('1')));
      await acked(pub.publish('groups.b.other', bytes('2')));
      await _eventually(() => got.isNotEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(got, ['groups.a.message']);
    });

    test('unsubscribe stops delivery', () async {
      final sub = await connected();
      final got = <Message>[];
      sub.messageStream.listen(got.addAll);
      await acked(sub.subscribe('groups.u.message'));
      await acked(sub.unsubscribe(['groups.u.message']));

      final pub = await connected();
      await acked(pub.publish('groups.u.message', bytes('x')));
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(got, isEmpty);
    });

    test('a reliable publish is sent as reliable', () async {
      final pub = await connected();
      await acked(pub.publish('groups.r.message', bytes('x'),
          deliveryMode: DeliveryMode.reliable));
      final f = server.sessions.single.received
          .firstWhere((f) => f.type == pbx.MessageType.PUBLISH && f.flow == pbx.FlowControl.NONE);
      expect(pbx.Publish.fromBuffer(f.body).deliveryMode, DeliveryMode.reliable.index);
    });

    test('a subscription is sent with its delivery mode', () async {
      final sub = await connected();
      await acked(sub.subscribe('groups.r.message', deliveryMode: DeliveryMode.reliable));
      expect(server.sessions.single.subscriptions['groups.r.message'],
          DeliveryMode.reliable.index);
    });

    for (final c in [
      [DeliveryMode.express, pbx.FlowControl.ACKNOWLEDGE],
      [DeliveryMode.reliable, pbx.FlowControl.RECEIPT],
    ]) {
      test('a received ${c[0]} message is acknowledged with ${c[1]}', () async {
        final sub = await connected();
        sub.messageStream.listen((_) {});
        await acked(sub.subscribe('groups.ack.message', deliveryMode: c[0]));
        final pub = await connected();
        final got = server.waitFor(
            (f) => f.type == pbx.MessageType.PUBLISH && f.flow != pbx.FlowControl.NONE,
            timeout: const Duration(seconds: 3));
        await acked(pub.publish('groups.ack.message', bytes('x')));
        final f = await got;
        expect(f.flow, c[1]);
        // The ack must be for the id the server delivered with.
        expect(pbx.ControlMessage.fromBuffer(f.body).messageID, 1);
      });
    }
  });

  group('relay', () {
    test('retrieves stored messages', () async {
      final pub = await connected();
      for (var i = 0; i < 3; i++) {
        await acked(pub.publish('groups.relay.message', bytes('r$i')));
      }

      final reader = await connected();
      final got = <String>[];
      reader.messageStream.listen((ms) => got.addAll(ms.map((m) => utf8.decode(m.payload))));
      await acked(reader.relay(['groups.relay.message'], last: '1h'));
      await _eventually(() => got.length >= 3);
      expect(got, ['r0', 'r1', 'r2']);

      final wire = pbx.Relay.fromBuffer(server.sessions[1].received
          .firstWhere((f) => f.type == pbx.MessageType.RELAY)
          .body);
      expect(wire.relayRequests.single.last, '1h');
    });
  });

  group('keep-alive', () {
    test('pings the server and reports the heartbeat', () async {
      var beats = 0;
      await connected(Options().withKeepAlive(2).withHeartBeatHandler(() => beats++));
      await server.waitFor((f) => f.type == pbx.MessageType.PINGREQ,
          timeout: const Duration(seconds: 6));
      await _eventually(() => beats > 0, timeout: const Duration(seconds: 3));
    });

    test('reports a lost connection when pings go unanswered', () async {
      server.answerPings = false;
      final lost = Completer<void>();
      await connected(Options()
          .withKeepAlive(2)
          .withPingTimeout(const Duration(seconds: 1))
          .withAutoReconnect(false)
          .withConnectionLostHandler(() {
        if (!lost.isCompleted) lost.complete();
      }));
      await lost.future.timeout(const Duration(seconds: 10));
    });
  });

  group('disconnect', () {
    test('tells the server and rejects later calls', () async {
      final c = await connected();
      await c.disconnect().timeout(wait);
      await server.waitFor((f) => f.type == pbx.MessageType.DISCONNECT,
          timeout: const Duration(seconds: 2)).catchError((_) {
        // It may already have been received before we started waiting.
        expect(server.sessions.single.received.map((f) => f.type),
            contains(pbx.MessageType.DISCONNECT));
      });
      final r = c.publish('groups.x', bytes('late'));
      expect(r.error(), isNotNull);
    });

    test('succeeds with calls still waiting for the server', () async {
      final c = await connected();
      // Close the server side first so the publish is never acknowledged.
      server.sessions.single.close();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final pending = c.publish('groups.pending', bytes('x'));
      await expectLater(c.disconnect().timeout(wait), completes);
      expect(pending.completer.isCompleted, isTrue,
          reason: 'a pending call should be completed with an error on disconnect');
    });

    test('a server-side close is reported as a lost connection', () async {
      final lost = Completer<void>();
      await connected(Options().withAutoReconnect(false).withConnectionLostHandler(() {
        if (!lost.isCompleted) lost.complete();
      }));
      server.sessions.single.close();
      await lost.future.timeout(const Duration(seconds: 5));
    });
  });
}

Future<void> _eventually(bool Function() condition,
    {Duration timeout = const Duration(seconds: 5)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
