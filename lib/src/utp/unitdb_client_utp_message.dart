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

/// The return codes of a CONNECT, as ConnectResult.returnCode reports them:
/// a value's index is the code. Indexes 0 to 9 are the codes the server
/// sends in its CONNACK (unitdb's docs/utp.md, Connect Return Code);
/// [ErrServerUnavailable] is the client's own, for a connect that no server
/// answered.
enum ConnectReturnCode {
  /// 0x00: the connection is accepted.
  Accepted,

  /// 0x01: unacceptable protocol version.
  ErrRefusedBadProtocolVersion,

  /// 0x02: the client ID is refused: missing, invalid, expired or revoked.
  /// A client that sent none, or one the server cannot open, is sent a new
  /// primary client ID on `unitdb/clientid/`; an expired or revoked one gets
  /// none, and needs a new ID from its primary client.
  ErrRefusedIDRejected,

  /// 0x03: unacceptable client ID, access not allowed.
  ErrRefusedBadID,

  /// 0x04: not authorized: a refused security key, or the insecure flag
  /// (Options.withInsecure) to a server without `allow_insecure`.
  ErrNotAuthorized,

  /// 0x05: the server failed.
  ErrServerError,

  /// 0x06: authentication failed.
  ErrBadToken,

  /// 0x07: forbidden.
  ErrForbidden,

  /// 0x08: the session is in use by another connection.
  ErrSessionInUse,

  /// 0x09: unknown epoch.
  ErrUnknownEpoch,

  /// No server answered the CONNECT: none could be reached, or the
  /// connection closed before a CONNACK. The client reports it; the server
  /// never sends it, and its index, 10, is past the server's codes.
  ErrServerUnavailable;

  /// The name return code 4 had: the server sends 4 for not authorized, as
  /// [ErrNotAuthorized], and the client reports a connect that no server
  /// answered as [ErrServerUnavailable].
  @Deprecated('the server sends 4 for not authorized: use ErrNotAuthorized, '
      'or ErrServerUnavailable for a connect that no server answered')
  static const ErrRefusedServerUnavailable = ErrNotAuthorized;

  /// The name return code 5 had: the server sends 5 for a server error, as
  /// [ErrServerError], and 4 for not authorized, as [ErrNotAuthorized].
  @Deprecated('the server sends 5 for a server error: use ErrServerError, '
      'or ErrNotAuthorized for not authorized (4)')
  static const ErrNotAuthorised = ErrServerError;

  /// The name return code 6 had: the server sends 6 for a failed
  /// authentication, as [ErrBadToken].
  @Deprecated('the server sends 6 for a failed authentication: use ErrBadToken')
  static const ErrBadRequest = ErrBadToken;

  /// fromCode returns the value of return code [code], or null for a code
  /// this client does not know.
  static ConnectReturnCode? fromCode(int? code) =>
      code != null && code >= 0 && code < values.length ? values[code] : null;
}

/// Message is the interface all our Messages in the line protocol will be implementing
abstract class UtpMessage {
  ByteBuffer encode();
  MessageType type();
  Info getInfo();

  /// read unpacks the Message from the provided stream.
  static Future<UtpMessage?> read(dynamic r) async {
    final readCompleter = Completer<UtpMessage>();
    var fh = FixedHeader.internal();
    await fh.unpack(r).catchError((dynamic e) {
      final message = 'UtpMessage::read - error reading utp message $e}';
      readCompleter.completeError(message);
    });

    // Check for empty Messages
    switch (fh.messageType) {
      case MessageType.DISCONNECT:
        return Disconnect();
    }

    UtpMessage? msg;

    try {
      final rawMsg = await r.read(fh.messageSize);

      // unpack the body
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
    } catch (e) {
      readCompleter.completeError(e.toString());
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

  late pbx.FixedHeader fh;

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
    final unpackCompleter = Completer<void>();
    try {
      final fhSize = await decodeLength(r);

      // read FixedHeader
      final head = await r.read(fhSize);

      fh.mergeFromBuffer(head);
      unpackCompleter.complete();
    } catch (e) {
      unpackCompleter.completeError(e.toString());
    }

    return unpackCompleter.future;
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
    } while (length > 0);
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
