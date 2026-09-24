import 'dart:convert';
import 'dart:typed_data' hide ByteBuffer;

import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'package:unitdb_client/src/v1/unitdb/schema.pb.dart' as pbx;
import 'package:unitdb_client/unitdb_client.dart';

/// Reads from an in-memory frame the way the gRPC handler does.
class BytesReader {
  BytesReader(List<int> bytes) : _bytes = bytes;
  final List<int> _bytes;
  int _pos = 0;

  Future<typed.Uint8Buffer> read(int n) async {
    if (_pos + n > _bytes.length) {
      throw StateError('read past end: want $n at $_pos of ${_bytes.length}');
    }
    final out = typed.Uint8Buffer()..addAll(_bytes.sublist(_pos, _pos + n));
    _pos += n;
    return out;
  }

  int get remaining => _bytes.length - _pos;
}

/// Splits an encoded frame into its FixedHeader and body.
class Frame {
  Frame(List<int> bytes) {
    var len = 0, shift = 0, i = 0;
    while (true) {
      final b = bytes[i++];
      len |= (b & 0x7f) << shift;
      if (b & 0x80 == 0) break;
      shift += 7;
    }
    header = pbx.FixedHeader.fromBuffer(bytes.sublist(i, i + len));
    body = bytes.sublist(i + len);
  }
  pbx.FixedHeader header;
  List<int> body;
}

List<int> bytesOf(UtpMessage m) => m.encode().buffer.toList();

Future<UtpMessage> roundTrip(UtpMessage m) => UtpMessage.read(BytesReader(bytesOf(m)));

Uint8List bytes(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  group('FixedHeader length encoding', () {
    Future<int> decode(List<int> b) => FixedHeader.decodeLength(BytesReader(b));

    test('encodes lengths below 128 in one byte', () {
      expect(FixedHeader.encodeLength(0).toList(), [0]);
      expect(FixedHeader.encodeLength(127).toList(), [127]);
    });

    test('encodes lengths of 128 and above in several bytes', () {
      expect(FixedHeader.encodeLength(128).toList(), [0x80, 0x01]);
      expect(FixedHeader.encodeLength(300).toList(), [0xac, 0x02]);
      expect(FixedHeader.encodeLength(16384).toList(), [0x80, 0x80, 0x01]);
    });

    test('decodes multi-byte lengths', () async {
      expect(await decode([0x7f]), 127);
      expect(await decode([0x80, 0x01]), 128);
      expect(await decode([0xac, 0x02]), 300);
    });

    test('round-trips lengths', () async {
      for (final n in [0, 1, 127, 128, 255, 300, 16383, 16384, 1 << 20]) {
        expect(await decode(FixedHeader.encodeLength(n).toList()), n, reason: '$n');
      }
    });
  });

  group('Publish', () {
    test('round-trips topic, payload, ttl and message id', () async {
      final m = await roundTrip(
          Publish(7, [PublishMessage('groups.a.message', bytes('hello'), '1m')]));
      expect(m, isA<Publish>());
      final p = m as Publish;
      expect(p.getInfo().messageID, 7);
      expect(p.messages.single.topic, 'groups.a.message');
      expect(utf8.decode(p.messages.single.payload), 'hello');
      expect(p.messages.single.ttl, '1m');
    });

    test('carries several messages', () async {
      final p = await roundTrip(Publish(1, [
        PublishMessage('a', bytes('1'), ''),
        PublishMessage('b', bytes('2'), ''),
      ])) as Publish;
      expect(p.messages.map((m) => m.topic), ['a', 'b']);
    });

    test('puts the delivery mode on the wire', () {
      final f = Frame(bytesOf(
          Publish(1, [PublishMessage('a', bytes('x'), '')], DeliveryMode.reliable)));
      expect(f.header.messageType, pbx.MessageType.PUBLISH);
      expect(pbx.Publish.fromBuffer(f.body).deliveryMode, DeliveryMode.reliable.index);
    });

    test('keeps the delivery mode when decoded', () async {
      final p = await roundTrip(
          Publish(1, [PublishMessage('a', bytes('x'), '')], DeliveryMode.batch));
      expect(p.getInfo().deliveryMode, DeliveryMode.batch.index);
    });

    test('declares the body length in the header', () {
      final f = Frame(bytesOf(Publish(1, [PublishMessage('a', bytes('x' * 500), '')])));
      expect(f.header.messageLength, f.body.length);
    });
  });

  group('Subscribe, Unsubscribe and Relay', () {
    test('Subscribe carries topic, delivery mode and delay', () {
      final f = Frame(bytesOf(
          Subscribe(3, [Subscription('groups.*.message', DeliveryMode.reliable, 5)])));
      expect(f.header.messageType, pbx.MessageType.SUBSCRIBE);
      final s = pbx.Subscribe.fromBuffer(f.body);
      expect(s.messageID, 3);
      expect(s.subscriptions.single.topic, 'groups.*.message');
      expect(s.subscriptions.single.deliveryMode, DeliveryMode.reliable.index);
      expect(s.subscriptions.single.delay, 5);
    });

    test('Unsubscribe carries its topics', () {
      final f = Frame(bytesOf(Unsubscribe(4, [Subscription('a'), Subscription('b')])));
      expect(f.header.messageType, pbx.MessageType.UNSUBSCRIBE);
      expect(pbx.Unsubscribe.fromBuffer(f.body).subscriptions.map((s) => s.topic),
          ['a', 'b']);
    });

    test('Relay carries topic and last', () {
      final f = Frame(bytesOf(Relay(5, [RelayRequest('groups.a', '10m')])));
      expect(f.header.messageType, pbx.MessageType.RELAY);
      final r = pbx.Relay.fromBuffer(f.body);
      expect(r.messageID, 5);
      expect(r.relayRequests.single.topic, 'groups.a');
      expect(r.relayRequests.single.last, '10m');
    });
  });

  group('ControlMessage', () {
    for (final fc in [
      FlowControl.NOTIFY,
      FlowControl.RECEIVE,
      FlowControl.RECEIPT,
      FlowControl.COMPLETE,
    ]) {
      test('round-trips $fc', () async {
        final m = await roundTrip(ControlMessage(42, MessageType.PUBLISH, fc))
            as ControlMessage;
        expect(m.messageID, 42);
        expect(m.flowControl, fc);
        expect(m.messageType, MessageType.PUBLISH);
      });
    }

    for (final mt in [
      MessageType.PUBLISH,
      MessageType.SUBSCRIBE,
      MessageType.UNSUBSCRIBE,
      MessageType.RELAY,
      MessageType.PINGREQ,
    ]) {
      test('round-trips an ACKNOWLEDGE for $mt', () async {
        final m = await roundTrip(ControlMessage(9, mt, FlowControl.ACKNOWLEDGE))
            as ControlMessage;
        expect(m.messageID, 9);
        expect(m.messageType, mt);
        expect(m.flowControl, FlowControl.ACKNOWLEDGE);
      });
    }

    test('decodes a connect acknowledgement', () async {
      final m = await roundTrip(ConnectAcknowledge(0, 1234, 77));
      expect(m, isA<ConnectAcknowledge>());
      final ca = m as ConnectAcknowledge;
      expect(ca.returnCode, 0);
      expect(ca.epoch, 1234);
      expect(ca.connID, 77);
    });
  });

  group('Connect', () {
    Uri uri(String s) => (Options()..addServer(s)).servers.single;
    pbx.Connect encode(Options o, [String server = ':6080']) =>
        pbx.Connect.fromBuffer(Frame(bytesOf(
                Connect.withOptions(o.withDefaultOptions()..clientID = 'CID', uri(server))))
            .body);

    test('carries client id and flags', () {
      final c = encode(Options().withInsecure().withCleanSession());
      expect(c.clientID, 'CID');
      expect(c.insecureFlag, isTrue);
      expect(c.cleanSessFlag, isTrue);
    });

    test('carries user name and password', () {
      final c = encode(
          Options().withUserNamePassword('alice', Uint8List.fromList([1, 2, 3])));
      expect(c.username, 'alice');
      expect(c.password, [1, 2, 3]);
    });

    test('carries the keep-alive interval', () {
      final c = encode(Options().withKeepAlive(15));
      expect(c.keepAlive, 15);
    });

    test('takes credentials from the server URL', () {
      final c = encode(Options(), 'grpc://bob:secret@localhost:6080');
      expect(c.username, 'bob');
      expect(utf8.decode(c.password), 'secret');
    });
  });
}
