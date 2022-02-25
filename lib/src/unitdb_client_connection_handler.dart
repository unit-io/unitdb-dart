part of unitdb_client;

class ConnectionHandler {
  Options _opts;
  int _contract;
  _MessageIdentifiers _messageIds; // local identifier of messages
  int _connID; // Theunique id of the connection.

  int get connectionId => _connID;

  int get sessionId => _opts.username.isNotEmpty ? _opts.username.hashCode : 1;

  Map<int, MessageHandler> _callbacks;

  Connection _conn;

  Store localStore;

  /// The Handler that is managing the connection to the remote server.
  @protected
  dynamic connectionHandler;
  // ServerConnection serverConn;

  /// Time when the keepalive session was last refreshed
  DateTime _lastTouched;

  /// Time when the session received any packer from client
  DateTime _lastAction;

  final _waitGroup = <Future>[];
  Timer _keepAliveTimer;
  int _pingOutstanding;
  int _closed;

  final send = StreamController<MessageAndResult>();

  final pub = StreamController<Publish>();

  final msg = StreamController<Message>();

  final EventChannel<Message> _eventChannel = EventChannel<Message>();

  EventChannel<Message> get eventChannel => _eventChannel;

  Future<bool> newConnection(Connection conn, Uri uri, Duration timeout,
      {String authority = ""}) async {
    this._conn = conn;
    return connectionHandler.newConnection(uri, timeout, authority: authority);
  }

  /// Connect takes a connected net.Conn and performs the initial handshake. Paramaters are:
  /// conn - Connected net.Conn
  /// cm - Connect Packet
  Future<int> _connect(Connect cm) async {
    // try {
    var m = cm.encode();
    await connectionHandler.write(m);
    final next = await connectionHandler
        .hasNext()
        .timeout(_conn._opts.connectTimeout)
        .catchError((dynamic e) {
      throw NoConnectionException('${e.toString()}');
    });
    if (next) {
      return _verifyCONNACK();
    }
    return ConnectReturnCode.ErrRefusedServerUnavailable.index;
  }

  /// This function is only used for receiving a connack
  /// when the connection is first started.
  /// This prevents receiving incoming data while resume
  /// is in progress if clean session is false.
  Future<int> _verifyCONNACK() async {
    await connectionHandler
        .next(_conn._opts.connectTimeout)
        .catchError((dynamic e) {
      throw NoConnectionException('${e.toString()}');
    });
    ConnectAcknowledge ca =
        await UtpMessage.read(connectionHandler).catchError((dynamic e) {
      throw NoConnectionException('${e.toString()}');
    });
    if (ca?.returnCode == ConnectReturnCode.Accepted.index) {
      _connID = ca.connID;
      return ca.returnCode;
    }

    return ca?.returnCode;
  }

  /// readLoop reads incoming messages from conn.
  void _readLoop() async {
    while (await connectionHandler.hasNext().catchError((dynamic e) {
      throw NoConnectionException('${e.toString()}');
    })) {
      if (_conn._isClosed()) {
        return;
      }
      await connectionHandler
          .next(_conn._opts.connectTimeout)
          .catchError((dynamic e) {
        throw NoConnectionException('${e.toString()}');
      });
      var msg =
          await UtpMessage.read(connectionHandler).catchError((dynamic e) {
        throw Exception('${e.toString()}');
      });

      /// Persist incoming
      _conn.storeInbound(msg);
      _handler(msg);
    }
  }

  /// handler handles inbound messages.
  _handler(UtpMessage msg) {
    _conn._updateLastAction();

    switch (msg.type()) {
      case MessageType.FLOWCONTROL:
        ControlMessage ctrl = msg;
        switch (ctrl.flowControl) {
          case FlowControl.ACKNOWLEDGE:
            switch (ctrl.messageType) {
              case MessageType.PINGREQ:
                _conn._pingAcknowledgmentReceived();
                break;
              case MessageType.PUBLISH:
              case MessageType.SUBSCRIBE:
              case MessageType.UNSUBSCRIBE:
              case MessageType.RELAY:
                var mId = ctrl.getInfo().messageID;
                final r = _messageIds._getType(mId);
                r.flowComplete();
                _messageIds._freeID(mId);
                break;
            }
            break;
          case FlowControl.NOTIFY:
            final recv = ControlMessage(msg.getInfo().messageID,
                MessageType.PUBLISH, FlowControl.RECEIVE);
            send.sink.add(MessageAndResult(recv));
            break;
          case FlowControl.COMPLETE:
            var mId = msg.getInfo().messageID;
            final r = _messageIds._getType(mId);
            r.flowComplete();
            _messageIds._freeID(mId);
            break;
        }
        break;
      case MessageType.PUBLISH:
        pub.sink.add(msg);
        break;
      case MessageType.DISCONNECT:
        _conn.serverDisconnect();
        break;
    }
  }

  Future<void> _writeLoop() async {
    send.stream.listen((msg) {
      switch (msg.m.type()) {
        case MessageType.DISCONNECT:
          msg.r.flowComplete();
          var mId = msg.m.getInfo().messageID;
          _messageIds._freeID(mId);
          break;
      }
      var m = msg.m.encode();
      connectionHandler.write(m);
    });
  }

  void _dispatcher() async {
    // dispatch message to default callback function
    if (_callbacks.isNotEmpty) {
      var handler = _callbacks[0];
      if (handler != null) {
        handler(_conn, msg.stream);
      }
    }
    pub.stream.listen((p) {
      for (var pubMsg in p.messages) {
        var m = Message.messageFromPublish(
            p.getInfo().messageID, pubMsg, _ack(this, p));
        eventChannel.notify(m);
        if (msg.hasListener) {
          msg.sink.add(m);
        }
      }
    });
  }

  /// keepAlive - Send ping when connection unused for set period
  /// connection passed in to avoid race condition on shutdown
  Future<void> _keepAlive() async {
    int pingInterval;
    var pingSent = _conn._timeNow();

    if (_opts.keepAlive > 10) {
      pingInterval = 5;
    } else {
      pingInterval = _opts.keepAlive ~/ 2;
    }

    // /// Send an initial ping request
    // connectionHandler.write(Pingreq().encode());

    _keepAliveTimer =
        await Timer.periodic(Duration(seconds: pingInterval), (timer) async {
      if (_conn._isClosed()) {
        timer.cancel();
      }

      final sinceLastSent = _conn._timeNow().difference(_lastAction).inSeconds;
      final sinceLastReceived =
          _conn._timeNow().difference(_lastTouched).inSeconds;
      var liveDuration = Duration(seconds: _opts.keepAlive).inSeconds;
      var timeout = _conn._timeNow().add(-_opts.pingTimeout);

      if (sinceLastSent >= liveDuration || sinceLastReceived >= liveDuration) {
        if (_pingOutstanding == 0) {
          var ping = Pingreq();
          var m = ping.encode();
          _pingOutstanding++;
          connectionHandler.write(m);
          _conn._updateLastAction();
          pingSent = _conn._timeNow();
        }
      }
      if (_pingOutstanding > 0 &&
          _conn._timeNow().difference(pingSent) >= _opts.pingTimeout) {
        await _conn
            ._internalConnLost(); // no harm in calling this if the connection is already down (better than stopping!)
        timer.cancel();
      }
    });
  }

  /// ack acknowledges a packet
  Function() _ack(Connection c, Publish msg) {
    return () {
      switch (DeliveryMode.values[msg.getInfo().deliveryMode]) {
        case DeliveryMode.express:
          var rec = ControlMessage(msg.getInfo().messageID, MessageType.PUBLISH,
              FlowControl.RECEIPT);

          /// persist outbound
          _conn.storeOutbound(rec);

          send.sink.add(MessageAndResult(rec));
          break;
        case DeliveryMode.reliable:
        case DeliveryMode.batch:
          var ack = ControlMessage(msg.getInfo().messageID, MessageType.PUBLISH,
              FlowControl.ACKNOWLEDGE);

          /// persist outbound
          _conn.storeOutbound(ack);

          send.sink.add(MessageAndResult(ack));
          break;
      }
    };
  }
}
