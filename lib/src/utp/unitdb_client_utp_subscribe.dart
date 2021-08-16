part of unitdb_client;

class Subscription {
  Subscription(String topic,
      [deliveryMode = DeliveryMode.express, int delay = 0]) {
    this._topic = topic;
    this._deliveryMode = deliveryMode;
    this._delay = delay;
  }
  String _topic;
  DeliveryMode _deliveryMode;
  int _delay;

  String get topic => _topic;
  int get deliveryMode => _deliveryMode.index;
  int get delay => _delay;
}

class Subscribe implements UtpMessage {
  Subscribe(int messageID, List<Subscription> subs) {
    this._messageID = messageID;
    this._subscriptions = subs;
  }
  int _messageID;
  List<Subscription> _subscriptions;

  /// type returns the Message type.
  MessageType type() {
    return MessageType.values[pbx.MessageType.SUBSCRIBE.value];
  }

  /// getInfo returns Qos and MessageID of this Message.
  Info getInfo() {
    return Info(1, _messageID);
  }

  ByteBuffer encode() {
    List<pbx.Subscription> subscriptions = [];
    for (var s in this._subscriptions) {
      final subscription = pbx.Subscription();
      subscription.topic = s.topic;
      subscription.deliveryMode = s.deliveryMode;
      subscription.delay = s.delay;
      subscriptions.add(subscription);
    }

    final sub = pbx.Subscribe();
    sub.messageID = _messageID;
    sub.subscriptions.addAll(subscriptions);
    final data = sub.writeToBuffer();

    final fh = FixedHeader(
        pbx.MessageType.SUBSCRIBE, pbx.FlowControl.NONE, data.length);
    final msg = fh.pack();
    msg.addAll(data);
    return msg;
  }
}

class Unsubscribe implements UtpMessage {
  Unsubscribe(int messageID, List<Subscription> subs) {
    this._messageID = messageID;
    this._subscriptions = subs;
  }
  int _messageID;
  List<Subscription> _subscriptions;

  /// type returns the Message type.
  MessageType type() {
    return MessageType.values[pbx.MessageType.UNSUBSCRIBE.value];
  }

  /// getInfo returns Qos and MessageID of this Message.
  Info getInfo() {
    return Info(1, _messageID);
  }

  ByteBuffer encode() {
    List<pbx.Subscription> subscriptions = [];
    for (var s in this._subscriptions) {
      final subscription = pbx.Subscription();
      subscription.topic = s.topic;
      subscription.deliveryMode = s.deliveryMode;
      subscription.delay = s.delay;
      subscriptions.add(subscription);
    }

    final sub = pbx.Unsubscribe();
    sub.messageID = _messageID;
    sub.subscriptions.addAll(subscriptions);
    final data = sub.writeToBuffer();

    final fh = FixedHeader(
        pbx.MessageType.UNSUBSCRIBE, pbx.FlowControl.NONE, data.length);
    final msg = fh.pack();
    msg.addAll(data);
    return msg;
  }
}
