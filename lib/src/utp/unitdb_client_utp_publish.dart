part of unitdb_client;

class PublishMessage {
  PublishMessage(String topic, Uint8List payload, String ttl) {
    this._topic = topic;
    this._payload = payload;
    this._ttl = ttl;
  }
  String _topic;
  Uint8List _payload;
  String _ttl;

  String get topic => _topic;
  Uint8List get payload => _payload;
  String get ttl => _ttl;
}

class Publish implements UtpMessage {
  Publish(int messageID, List<PublishMessage> messages,
      [deliveryMode = DeliveryMode.express]) {
    this._messageID = messageID;
    this._messages = messages;
    this._deliveryMode = deliveryMode;
  }
  int _messageID;
  DeliveryMode _deliveryMode;
  List<PublishMessage> _messages;

  List<PublishMessage> get messages => _messages;

  /// type returns the Message type.
  MessageType type() {
    return MessageType.values[pbx.MessageType.PUBLISH.value];
  }

  /// getInfo returns Qos and MessageID of this Message.
  Info getInfo() {
    return Info(_deliveryMode.index, _messageID);
  }

  ByteBuffer encode() {
    List<pbx.PublishMessage> messages = [];
    for (var m in this._messages) {
      final message = pbx.PublishMessage();
      message.topic = m.topic;
      message.payload = m.payload;
      message.ttl = m.ttl;
      messages.add(message);
    }

    final pub = pbx.Publish();
    pub.messageID = _messageID;
    pub.messages.addAll(messages);
    final data = pub.writeToBuffer();

    final fh =
        FixedHeader(pbx.MessageType.PUBLISH, pbx.FlowControl.NONE, data.length);
    final msg = fh.pack();
    msg.addAll(data);
    return msg;
  }

  static UtpMessage unpack(typed.Uint8Buffer data) {
    final pub = pbx.Publish();
    pub.mergeFromBuffer(data);

    List<PublishMessage> messages = [];
    for (var message in pub.messages) {
      messages.add(PublishMessage(message.topic, message.payload, message.ttl));
    }

    return Publish(pub.messageID, messages);
  }
}
