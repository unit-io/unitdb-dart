part of unitdb_client;

class Message extends Event {
  // A Message made with Message() is empty: it has no topic or payload.
  Message();
  Message.messageFromPublish(int messageID, PublishMessage p, Function() ack) {
    this._topic = p.topic;
    this._messageID = messageID;
    this._payload = p.payload;
  }
  String _topic = '';
  int _messageID = 0;
  Uint8List _payload = Uint8List(0);

  String get topic => _topic;

  int get messageID => _messageID;

  Uint8List get payload => _payload;
}
