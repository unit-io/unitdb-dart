part of unitdb_client;

class RelayRequest {
  RelayRequest(String topic, String last, {Map<String, String> tags}) {
    this._topic = topic;
    this._tags = tags;
    this._last = last;
  }
  String _topic;
  Map<String, String> _tags;
  String _last;

  String get topic => _topic;
  Map<String, String> get tags => _tags;
  String get last => _last;
}

class Relay implements UtpMessage {
  Relay(int messageID, List<RelayRequest> requests) {
    this._messageID = messageID;
    this._requests = requests;
  }

  int _messageID;
  List<RelayRequest> _requests;

  List<RelayRequest> get requests => _requests;

  /// type returns the Message type.
  MessageType type() {
    return MessageType.values[pbx.MessageType.RELAY.value];
  }

  /// getInfo returns Qos and MessageID of this Message.
  Info getInfo() {
    return Info(1, _messageID);
  }

  ByteBuffer encode() {
    List<pbx.RelayRequest> requests = [];
    for (var r in this._requests) {
      final req = pbx.RelayRequest();
      req.topic = r.topic;
      r.tags?.forEach((key, value) {
        req.tags[key] = value;
      });
      req.last = r.last;
      requests.add(req);
    }

    final rel = pbx.Relay();
    rel.messageID = _messageID;
    rel.relayRequests.addAll(requests);
    final data = rel.writeToBuffer();

    final fh =
        FixedHeader(pbx.MessageType.RELAY, pbx.FlowControl.NONE, data.length);
    final msg = fh.pack();
    msg.addAll(data);
    return msg;
  }

  static UtpMessage unpack(typed.Uint8Buffer data) {
    final rel = pbx.Relay();
    rel.mergeFromBuffer(data);

    List<RelayRequest> requests = [];
    for (var req in rel.relayRequests) {
      requests.add(RelayRequest(req.topic, req.last, tags: req.tags));
    }

    return Relay(rel.messageID, requests);
  }
}
