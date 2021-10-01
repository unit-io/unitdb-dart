part of unitdb_client;

class Message extends Event {
  Message();
  Message.messageFromPublish(int messageID, PublishMessage p, Function() ack) {
    this._topic = p.topic;
    this._messageID = messageID;
    this._payload = p.payload;
  }
  String _topic;
  int _messageID;
  Uint8List _payload;

  String get topic => _topic;

  int get messageID => _messageID;

  Uint8List get payload => _payload;
}
