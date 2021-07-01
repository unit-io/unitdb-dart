part of unitdb_client;

class ConnectionHandler {
  Options opts;
  int contract;
  _MessageIdentifiers messageIds; // local identifier of messages
  int connID; // Theunique id of the connection.
  Map<int, MessageHandler> callbacks;
  Connection conn;

  /// The Handler that is managing the connection to the remote server.
  @protected
  dynamic connectionHandler;
  // ServerConnection serverConn;

  /// Time when the keepalive session was last refreshed
  DateTime lastTouched;

  /// Time when the session received any packer from client
  DateTime lastAction;

  final waitGroup = <Future>[];
  Timer keepAliveTimer;
  int _closed;

  final send = StreamController<MessageAndResult>();

  final pub = StreamController<Publish>();

  final msg = StreamController<Message>();

  final EventChannel<Message> _eventChannel = EventChannel<Message>();

  EventChannel<Message> get eventChannel => _eventChannel;

  Future<bool> newConnection(Connection conn, Uri uri, Duration timeout) async {
    this.conn = conn;
    return connectionHandler.newConnection(uri, timeout);
  }

  /// Connect takes a connected net.Conn and performs the initial handshake. Paramaters are:
  /// conn - Connected net.Conn
  /// cm - Connect Packet
  Future<int> _connect(Connect cm) async {
    try {
      var m = cm.encode();
      await connectionHandler.write(m);
      if (await connectionHandler._hasNext()) {
        await connectionHandler._next();
      }
    } on Exception catch (e) {
      rethrow;
    }
    return await _verifyCONNACK();
  }

  /// This function is only used for receiving a connack
  /// when the connection is first started.
  /// This prevents receiving incoming data while resume
  /// is in progress if clean session is false.
  Future<int> _verifyCONNACK() async {
    ConnectAcknowledge ca = await UtpMessage.read(connectionHandler);
    if (ca.returnCode == ConnectReturnCode.Accepted.index) {
      connID = ca.connID;
      messageIds._reset();
      return ca.returnCode;
    }

    return ca.returnCode;
  }

  /// readLoop reads incoming messages from conn.
  Future<void> _readLoop() async {
    // await for (var inMsg in serverConn.stream) {
    //   serverConn.inPacket.sink.add(inMsg);
    while (await connectionHandler._hasNext()) {
      await connectionHandler._next();
      var msg = await UtpMessage.read(connectionHandler);
      connectionHandler._shrink();
      _handler(msg);
    }
  }

  /// handler handles inbound messages.
  _handler(UtpMessage msg) {
    conn._updateLastAction();

    switch (msg.type()) {
      case MessageType.FLOWCONTROL:
        ControlMessage ctrl = msg;
        switch (ctrl.flowControl) {
          case FlowControl.ACKNOWLEDGE:
            switch (ctrl.messageType) {
              case MessageType.PINGREQ:
                conn._updateLastTouched();
                break;
              case MessageType.PUBLISH:
              case MessageType.SUBSCRIBE:
              case MessageType.UNSUBSCRIBE:
                var mId = ctrl.getInfo().messageID;
                final r = messageIds._getType(mId);
                r.flowComplete();
                messageIds._freeID(mId);
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
            final r = messageIds._getType(mId);
            r.flowComplete();
            messageIds._freeID(mId);
            break;
        }
        break;
      case MessageType.PUBLISH:
        pub.sink.add(msg);
        break;
      case MessageType.DISCONNECT:
        conn.serverDisconnect();
        break;
    }
  }

  Future<void> _writeLoop() async {
    send.stream.listen((msg) {
      switch (msg.m.type()) {
        case MessageType.DISCONNECT:
          msg.r.flowComplete();
          var mId = msg.m.getInfo().messageID;
          messageIds._freeID(mId);
          break;
      }
      var m = msg.m.encode();
      connectionHandler.write(m);
    });
  }

  Future<void> _dispatcher() async {
    // dispatch message to default callback function
    if (callbacks.isNotEmpty) {
      var handler = callbacks[0];
      if (handler != null) {
        handler(conn, msg.stream);
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
    var pingSent = conn._timeNow();

    if (opts.keepAlive > 10) {
      pingInterval = 5;
    } else {
      pingInterval = opts.keepAlive ~/ 2;
    }

    keepAliveTimer =
        await Timer.periodic(Duration(seconds: pingInterval), (timer) async {
      var live = conn._timeNow().add(-Duration(seconds: opts.keepAlive));
      var timeout = conn._timeNow().add(-opts.pingTimeout);

      if (lastAction.isAfter(live) && lastTouched.isBefore(timeout)) {
        var ping = Pingreq();
        var m = ping.encode();
        connectionHandler.write(m);
        pingSent = conn._timeNow();
      }
      if (lastTouched.isBefore(timeout) && pingSent.isBefore(timeout)) {
        await conn
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
          var p = ControlMessage(msg.getInfo().messageID, MessageType.PUBLISH,
              FlowControl.RECEIPT);
          send.sink.add(MessageAndResult(p));
          break;
        case DeliveryMode.reliable:
        case DeliveryMode.batch:
          var p = ControlMessage(msg.getInfo().messageID, MessageType.PUBLISH,
              FlowControl.ACKNOWLEDGE);
          send.sink.add(MessageAndResult(p));
          break;
      }
    };
  }
}
