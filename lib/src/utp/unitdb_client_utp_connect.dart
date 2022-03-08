part of unitdb_client;

class Connect implements UtpMessage {
  Connect.withOptions(Options opts, Uri server) {
    this._cleanSessFlag = opts.cleanSession;
    this._clientID = opts.clientID;
    this._insecureFlag = opts.insecureFlag;

    var user = server.userInfo?.split(':') ?? [];
    print('connect::withOption - user $user userName ${opts.username}');
    var username =
        user.length == 0 || user[0].isEmpty ? opts.username : user[0];
    var password = user.length > 1 && user[1].isNotEmpty
        ? Uint16List.fromList(user[1].codeUnits)
        : opts.password;

    if (username.isNotEmpty) {
      this._username = username;
      //mustn't have password without user as well
      if (password.isNotEmpty) {
        this._password = password;
      }
    }

    this._sessionData = opts.sessionData;

    print('connect::withOptions - username $username');

    // this._keepAlive = opts.keepAlive;
  }

  bool _cleanSessFlag;
  String _clientID;
  bool _insecureFlag;
  String _username;
  Uint8List _password;
  String _sessionData;
  // int _keepAlive;

  /// type returns the Message type.
  MessageType type() {
    return MessageType.values[pbx.MessageType.CONNECT.value];
  }

  /// getInfo returns Qos and MessageID of this Message.
  Info getInfo() {
    return Info(0, 0);
  }

  ByteBuffer encode() {
    final conn = pbx.Connect();
    conn.cleanSessFlag = _cleanSessFlag;
    conn.clientID = _clientID ?? "";
    conn.insecureFlag = _insecureFlag;
    conn.username = _username ?? "";
    if (_password != null) {
      conn.password = _password;
    }
    conn.sessionData = _sessionData;
    final data = conn.writeToBuffer();

    final fh =
        FixedHeader(pbx.MessageType.CONNECT, pbx.FlowControl.NONE, data.length);
    final msg = fh.pack();
    msg.addAll(data);
    return msg;
  }
}

class ConnectAcknowledge implements UtpMessage {
  ConnectAcknowledge(int returnCode, int epoch, int connID) {
    this._returnCode = returnCode;
    this._epoch = epoch;
    this._connID = connID;
  }

  int _returnCode;

  int _epoch;

  int _connID;

  int get returnCode => _returnCode;

  int get epoch => _epoch;

  int get connID => _connID;

  /// type returns the Message type.
  MessageType type() {
    return MessageType.values[pbx.MessageType.CONNECT.value];
  }

  /// getInfo returns Qos and MessageID of this Message.
  Info getInfo() {
    return Info(1, 0);
  }

  ByteBuffer encode() {
    final connack = pbx.ConnectAcknowledge();
    connack.returnCode = _returnCode;
    connack.epoch = _epoch;
    connack.connID = _connID;
    final data = connack.writeToBuffer();

    final fh = FixedHeader(
        pbx.MessageType.CONNECT, pbx.FlowControl.ACKNOWLEDGE, data.length);
    final msg = fh.pack();
    msg.addAll(data);
    return msg;
  }
}

class Pingreq implements UtpMessage {
  Pingreq() {
    pingreq = pbx.PingRequest();
  }
  pbx.PingRequest pingreq;

  /// type returns the Message type.
  MessageType type() {
    return MessageType.values[pbx.MessageType.PINGREQ.value];
  }

  /// getInfo returns Qos and MessageID of this Message.
  Info getInfo() {
    return Info(0, 0);
  }

  ByteBuffer encode() {
    ByteBuffer msg;

    var data = pingreq.writeToBuffer();

    var fh =
        FixedHeader(pbx.MessageType.PINGREQ, pbx.FlowControl.NONE, data.length);
    msg = fh.pack();
    msg.addAll(data);
    return msg;
  }
}

class Disconnect implements UtpMessage {
  Disconnect() {
    disconn = pbx.Disconnect();
  }
  pbx.Disconnect disconn;

  /// type returns the Message type.
  MessageType type() {
    return MessageType.values[pbx.MessageType.DISCONNECT.value];
  }

  /// getInfo returns Qos and MessageID of this Message.
  Info getInfo() {
    return Info(0, 0);
  }

  ByteBuffer encode() {
    ByteBuffer msg;

    var data = disconn.writeToBuffer();

    var fh = FixedHeader(
        pbx.MessageType.DISCONNECT, pbx.FlowControl.NONE, data.length);
    msg = fh.pack();
    msg.addAll(data);
    return msg;
  }
}
