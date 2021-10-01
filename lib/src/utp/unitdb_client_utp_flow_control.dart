part of unitdb_client;

/// An enumeration of all Flow Controls
enum FlowControl { NONE, ACKNOWLEDGE, NOTIFY, RECEIVE, RECEIPT, COMPLETE }

class ControlMessage implements UtpMessage {
  ControlMessage(
      int messageID, MessageType messageType, FlowControl flowControl) {
    this._messageID = messageID;
    this._messageType = messageType;
    this._flowControl = flowControl;
  }

  int _messageID;
  MessageType _messageType;
  FlowControl _flowControl;

  int get messageID => _messageID;

  MessageType get messageType => _messageType;

  FlowControl get flowControl => _flowControl;

  /// type returns the Message type.
  MessageType type() {
    return MessageType.FLOWCONTROL;
  }

  /// getInfo returns Qos and MessageID of this Message.
  Info getInfo() {
    return Info(1, _messageID);
  }

  /// encodeControlMessage encodes the Control Message into binary data
  ByteBuffer encode() {
    FixedHeader fh;
    final cm = pbx.ControlMessage();
    cm.messageID = _messageID;
    final data = cm.writeToBuffer();

    switch (flowControl) {
      case FlowControl.ACKNOWLEDGE:
        switch (messageType) {
          case MessageType.CONNECT:
            fh = FixedHeader(pbx.MessageType.CONNECT,
                pbx.FlowControl.ACKNOWLEDGE, data.length);
            break;
          case MessageType.PUBLISH:
            fh = FixedHeader(pbx.MessageType.PUBLISH,
                pbx.FlowControl.ACKNOWLEDGE, data.length);
            break;
          case MessageType.RELAY:
            fh = FixedHeader(pbx.MessageType.RELAY, pbx.FlowControl.ACKNOWLEDGE,
                data.length);
            break;

          case MessageType.SUBSCRIBE:
            fh = FixedHeader(pbx.MessageType.SUBSCRIBE,
                pbx.FlowControl.ACKNOWLEDGE, data.length);
            break;
          case MessageType.UNSUBSCRIBE:
            fh = FixedHeader(pbx.MessageType.UNSUBSCRIBE,
                pbx.FlowControl.ACKNOWLEDGE, data.length);
            break;
          case MessageType.PINGREQ:
            fh = FixedHeader(pbx.MessageType.PINGREQ,
                pbx.FlowControl.ACKNOWLEDGE, data.length);
            break;
        }
        break;
      case FlowControl.NOTIFY:
        fh = FixedHeader(
            pbx.MessageType.PUBLISH, pbx.FlowControl.NOTIFY, data.length);
        break;
      case FlowControl.RECEIVE:
        fh = FixedHeader(
            pbx.MessageType.PUBLISH, pbx.FlowControl.RECEIVE, data.length);
        break;
      case FlowControl.RECEIPT:
        fh = FixedHeader(
            pbx.MessageType.PUBLISH, pbx.FlowControl.RECEIPT, data.length);
        break;
      case FlowControl.COMPLETE:
        fh = FixedHeader(
            pbx.MessageType.PUBLISH, pbx.FlowControl.COMPLETE, data.length);
        break;
    }

    final msg = fh.pack();
    msg.addAll(data);
    return msg;
  }

  static UtpMessage unpackControlMessage(
      FixedHeader h, typed.Uint8Buffer data) {
    switch (h.messageType) {
      case MessageType.CONNECT:
        final connack = pbx.ConnectAcknowledge();
        connack.mergeFromBuffer(data);
        return ConnectAcknowledge(
            connack.returnCode, connack.epoch, connack.connID);
    }

    final msg = pbx.ControlMessage();
    msg.mergeFromBuffer(data);

    return ControlMessage(msg.messageID, h.messageType, h.flowControl);
  }
}
