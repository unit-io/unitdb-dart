part of unitdb_client;

/// An enumeration of all Message types
enum MessageType {
  RESERVED,
  CONNECT,
  PUBLISH,
  RELAY,
  SUBSCRIBE,
  UNSUBSCRIBE,
  PINGREQ,
  DISCONNECT,
  FLOWCONTROL
}

/// Enumeration of error codes returned by Connect().
enum ConnectReturnCode {
  Accepted,
  ErrRefusedBadProtocolVersion,
  ErrRefusedIDRejected,
  ErrRefusedbADID,
  ErrRefusedServerUnavailable,
  ErrNotAuthorised,
  ErrBadRequest
}

/// Message is the interface all our Messages in the line protocol will be implementing
abstract class UtpMessage {
  ByteBuffer encode();
  MessageType type();
  Info getInfo();

  /// read unpacks the Message from the provided stream.
  static Future<UtpMessage> read(dynamic r) async {
    var fh = FixedHeader.internal();
    await fh.unpack(r);

    // Check for empty Messages
    switch (fh.messageType) {
      case MessageType.DISCONNECT:
        return Disconnect();
    }

    final rawMsg = await r.read(fh.messageSize);

    // unpack the body
    UtpMessage msg;
    if (fh.flowControl != FlowControl.NONE) {
      return ControlMessage.unpackControlMessage(fh, rawMsg);
    }

    switch (fh.messageType) {
      case MessageType.PUBLISH:
        msg = Publish.unpack(rawMsg);
        break;
      default:
        return msg;
    }

    return msg;
  }
}

/// Info returns Qos and MessageID by the Info() function called on the Message
class Info {
  Info(this.deliveryMode, this.messageID);

  int deliveryMode;
  int messageID;
}

class FixedHeader {
  FixedHeader.internal() {
    this.fh = pbx.FixedHeader();
  }
  FixedHeader(pbx.MessageType messageType, pbx.FlowControl flowControl,
      int messageLength) {
    this.fh = pbx.FixedHeader();
    this.fh.messageType = messageType;
    this.fh.flowControl = flowControl;
    this.fh.messageLength = messageLength;
  }

  pbx.FixedHeader fh;

  int get messageSize => fh.messageLength;

  MessageType get messageType => MessageType.values[fh.messageType.value];

  FlowControl get flowControl => FlowControl.values[fh.flowControl.value];

  ByteBuffer pack() {
    var h = fh.writeToBuffer();
    var size = encodeLength(h.length);

    var head = ByteBuffer(typed.Uint8Buffer());

    head.addAll(size);
    head.addAll(h);

    return head;
  }

  Future<void> unpack(dynamic r) async {
    final fhSize = await decodeLength(r);

    // read FixedHeader
    final head = await r.read(fhSize);

    fh.mergeFromBuffer(head);
  }

  static typed.Uint8Buffer encodeLength(var length) {
    var encLength = typed.Uint8Buffer();
    do {
      var digit = length % 128;
      length ~/= 128;
      if (length > 0) {
        digit |= 0x80;
      }
      encLength.add(digit);
      if (length == 0) {
        break;
      }
    } while (length == 0);
    return encLength;
  }

  static Future<int> decodeLength(dynamic r) async {
    int rLength = 0;
    int multiplier = 0;
    while (multiplier < 27) {
      var digit = await r.read(1);
      rLength |= (digit.single & 127) << multiplier;
      if ((digit.single & 128) == 0) {
        break;
      }
      multiplier += 7;
    }
    return rLength;
  }
}
