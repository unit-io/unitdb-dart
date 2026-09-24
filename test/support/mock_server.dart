// A minimal in-process unitdb server for end-to-end tests of the client.
//
// It implements the client's own gRPC service (schema.pbgrpc.dart) and the uTP
// framing: every Packet carries one frame of varint(len(header)) + FixedHeader
// + body. It acknowledges CONNECT/SUBSCRIBE/UNSUBSCRIBE/PUBLISH/RELAY/PINGREQ,
// routes publishes to subscribers, keeps published messages for relay, and
// records every frame it receives so tests can assert on the wire traffic.

import 'dart:async';

import 'package:grpc/grpc.dart';
import 'package:unitdb_client/src/v1/unitdb/schema.pb.dart' as pbx;
import 'package:unitdb_client/src/v1/unitdb/schema.pbgrpc.dart';

class Frame {
  Frame(this.header, this.body);
  final pbx.FixedHeader header;
  final List<int> body;

  pbx.MessageType get type => header.messageType;
  pbx.FlowControl get flow => header.flowControl;

  static Frame parse(List<int> bytes) {
    var len = 0, shift = 0, i = 0;
    while (true) {
      final b = bytes[i++];
      len |= (b & 0x7f) << shift;
      if (b & 0x80 == 0) break;
      shift += 7;
    }
    return Frame(pbx.FixedHeader.fromBuffer(bytes.sublist(i, i + len)),
        bytes.sublist(i + len));
  }

  static List<int> encode(
      pbx.MessageType type, pbx.FlowControl flow, List<int> body) {
    final h = (pbx.FixedHeader()
          ..messageType = type
          ..flowControl = flow
          ..messageLength = body.length)
        .writeToBuffer();
    final out = <int>[];
    var n = h.length;
    do {
      var digit = n % 128;
      n ~/= 128;
      if (n > 0) digit |= 0x80;
      out.add(digit);
    } while (n > 0);
    return out..addAll(h)..addAll(body);
  }
}

class StoredMessage {
  StoredMessage(this.topic, this.payload);
  final String topic;
  final List<int> payload;
}

/// One client stream on the server.
class MockSession {
  MockSession(this.server, this.id);
  final MockServer server;
  final int id;
  final out = StreamController<pbx.Packet>();
  final subscriptions = <String, int>{}; // topic -> delivery mode
  final received = <Frame>[];
  pbx.Connect connect;
  int _nextId = 0;
  bool closed = false;

  void send(pbx.MessageType type, pbx.FlowControl flow, List<int> body) {
    if (closed) return;
    out.add(pbx.Packet()..data = Frame.encode(type, flow, body));
  }

  void ack(pbx.MessageType type, int messageID) => send(type,
      pbx.FlowControl.ACKNOWLEDGE, (pbx.ControlMessage()..messageID = messageID).writeToBuffer());

  void deliver(String topic, List<int> payload, int mode) {
    final pub = pbx.Publish()
      ..messageID = ++_nextId
      ..deliveryMode = mode
      ..messages.add(pbx.PublishMessage()
        ..topic = topic
        ..payload = payload);
    send(pbx.MessageType.PUBLISH, pbx.FlowControl.NONE, pub.writeToBuffer());
  }

  void close() {
    if (closed) return;
    closed = true;
    out.close();
  }
}

class MockServer extends UnitdbServiceBase {
  MockServer({this.connectReturnCode = 0});

  /// Return code sent in every CONNECT acknowledgement.
  int connectReturnCode;

  /// When false, the server never answers PINGREQ.
  bool answerPings = true;

  final sessions = <MockSession>[];
  final stored = <StoredMessage>[];
  final _events = StreamController<Frame>.broadcast();

  /// Every frame received from any client, as it arrives.
  Stream<Frame> get frames => _events.stream;

  Server _grpc;
  int get port => _grpc.port;

  Future<void> start() async {
    _grpc = Server([this]);
    await _grpc.serve(address: '127.0.0.1', port: 0);
  }

  Future<void> stop() async {
    for (final s in sessions) {
      s.close();
    }
    await _grpc.shutdown();
  }

  /// Waits for the next received frame matching [test].
  Future<Frame> waitFor(bool Function(Frame) test,
      {Duration timeout = const Duration(seconds: 5)}) {
    return frames.firstWhere(test).timeout(timeout);
  }

  @override
  Stream<pbx.Packet> stream(ServiceCall call, Stream<pbx.Packet> request) {
    final session = MockSession(this, sessions.length + 1);
    sessions.add(session);
    request.listen((packet) => _handle(session, Frame.parse(packet.data)),
        onDone: session.close, onError: (_) => session.close());
    return session.out.stream;
  }

  void _handle(MockSession s, Frame f) {
    s.received.add(f);
    _events.add(f);
    if (f.flow != pbx.FlowControl.NONE) {
      return; // client acks (RECEIPT, ACKNOWLEDGE, RECEIVE): recorded only
    }
    switch (f.type) {
      case pbx.MessageType.CONNECT:
        s.connect = pbx.Connect.fromBuffer(f.body);
        s.send(
            pbx.MessageType.CONNECT,
            pbx.FlowControl.ACKNOWLEDGE,
            (pbx.ConnectAcknowledge()
                  ..returnCode = connectReturnCode
                  ..epoch = 1
                  ..connID = s.id)
                .writeToBuffer());
        break;
      case pbx.MessageType.SUBSCRIBE:
        final sub = pbx.Subscribe.fromBuffer(f.body);
        for (final x in sub.subscriptions) {
          s.subscriptions[x.topic] = x.deliveryMode;
        }
        s.ack(pbx.MessageType.SUBSCRIBE, sub.messageID);
        break;
      case pbx.MessageType.UNSUBSCRIBE:
        final unsub = pbx.Unsubscribe.fromBuffer(f.body);
        for (final x in unsub.subscriptions) {
          s.subscriptions.remove(x.topic);
        }
        s.ack(pbx.MessageType.UNSUBSCRIBE, unsub.messageID);
        break;
      case pbx.MessageType.PUBLISH:
        final pub = pbx.Publish.fromBuffer(f.body);
        s.ack(pbx.MessageType.PUBLISH, pub.messageID);
        for (final m in pub.messages) {
          stored.add(StoredMessage(m.topic, m.payload));
          for (final other in sessions) {
            final mode = _match(other.subscriptions, m.topic);
            if (mode != null) {
              other.deliver(m.topic, m.payload, mode);
            }
          }
        }
        break;
      case pbx.MessageType.RELAY:
        final rel = pbx.Relay.fromBuffer(f.body);
        s.ack(pbx.MessageType.RELAY, rel.messageID);
        for (final req in rel.relayRequests) {
          for (final m in stored.where((m) => m.topic == req.topic)) {
            s.deliver(m.topic, m.payload, 0);
          }
        }
        break;
      case pbx.MessageType.PINGREQ:
        if (answerPings) {
          s.ack(pbx.MessageType.PINGREQ, 0);
        }
        break;
      case pbx.MessageType.DISCONNECT:
        s.close();
        break;
      default:
        break;
    }
  }

  /// Returns the delivery mode of the first subscription matching topic.
  static int _match(Map<String, int> subs, String topic) {
    for (final e in subs.entries) {
      if (_matches(e.key, topic)) return e.value;
    }
    return null;
  }

  static bool _matches(String filter, String topic) {
    if (filter == topic || filter == '...' || filter == '*') return true;
    if (filter.endsWith('...')) {
      final prefix = filter.substring(0, filter.length - 3);
      return topic.startsWith(prefix.endsWith('.') ? prefix : '$prefix.');
    }
    final f = filter.split('.'), t = topic.split('.');
    if (f.length != t.length) return false;
    for (var i = 0; i < f.length; i++) {
      if (f[i] != '*' && f[i] != t[i]) return false;
    }
    return true;
  }
}
