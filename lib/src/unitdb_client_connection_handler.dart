part of unitdb_client;

class ConnectionHandler {
  // _opts, _contract, _messageIds, _callbacks and _closed are set by the
  // Connection constructor.
  late Options _opts;
  late int _contract;
  late _MessageIdentifiers _messageIds; // local identifier of messages
  int? _connID; // Theunique id of the connection.

  int? get connectionId => _connID;

  int get sessionId => _opts._resolvedUsername.isNotEmpty
      ? _opts._resolvedUsername.hashCode
      : 1;

  late Map<int, MessageHandler?> _callbacks;

  /// The connection this handler belongs to, set by newConnection before
  /// the connection's loops run.
  late Connection _conn;

  Store? localStore;

  /// The Handler that is managing the connection to the remote server.
  @protected
  dynamic connectionHandler;
  // ServerConnection serverConn;

  // _lastTouched and _lastAction are set before the keepalive timer, which
  // reads them, starts.

  /// Time when the keepalive session was last refreshed
  late DateTime _lastTouched;

  /// Time when the session received any packer from client
  late DateTime _lastAction;

  final _waitGroup = <Future>[];
  Timer? _keepAliveTimer;
  int _pingOutstanding = 0;
  late int _closed;

  /// _down is set while the connection is lost and the client reconnects.
  bool _down = false;

  /// _inflight holds the requests the server has not answered, by message
  /// identifier, to send them again after a reconnect.
  final _inflight = <int, MessageAndResult>{};

  /// _subscriptions holds the client's subscriptions, to subscribe again
  /// after a reconnect.
  final _subscriptions = <String, Subscription>{};

  /// _pending holds the requests made while the client reconnects, until
  /// it is connected or their write timeout passes.
  final _pending = <MessageAndResult>[];

  /// _apiRequests holds the API requests waiting for the server's answer,
  /// by the topic it answers on, in the order they were sent.
  final _apiRequests = <String, List<_ApiRequest>>{};

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
  Future<int?> _connect(Connect cm) async {
    // try {
    var m = cm.encode();
    await connectionHandler.write(m);
    final next = await connectionHandler
        .hasNext()
        .timeout(_conn._opts._resolvedConnectTimeout)
        .catchError((dynamic e) {
      throw NoConnectionException('${e.toString()}');
    });
    if (next) {
      return _verifyCONNACK();
    }
    // The connection closed before a CONNACK.
    return ConnectReturnCode.ErrServerUnavailable.index;
  }

  /// This function is only used for receiving a connack
  /// when the connection is first started.
  /// This prevents receiving incoming data while resume
  /// is in progress if clean session is false.
  Future<int?> _verifyCONNACK() async {
    await connectionHandler
        .next(_conn._opts._resolvedConnectTimeout)
        .catchError((dynamic e) {
      throw NoConnectionException('${e.toString()}');
    });
    final ca = await UtpMessage.read(connectionHandler)
        .catchError((dynamic e) {
      throw NoConnectionException('${e.toString()}');
    }) as ConnectAcknowledge?;
    if (ca != null && ca.returnCode == ConnectReturnCode.Accepted.index) {
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
          .next(_conn._opts._resolvedConnectTimeout)
          .catchError((dynamic e) {
        throw NoConnectionException('${e.toString()}');
      });
      var msg =
          await UtpMessage.read(connectionHandler).catchError((dynamic e) {
        throw Exception('${e.toString()}');
      });
      if (msg == null) {
        // A packet type the client does not handle; skip it.
        continue;
      }

      /// Persist incoming
      _conn.storeInbound(msg);
      _handler(msg);
    }
    // The server ended the stream. Unless the client closed it, the
    // connection is lost.
    if (!_conn._isClosed()) {
      connectionHandler?.close();
      _conn._internalConnLost();
    }
  }

  /// handler handles inbound messages.
  _handler(UtpMessage msg) {
    _conn._updateLastAction();

    switch (msg.type()) {
      case MessageType.FLOWCONTROL:
        ControlMessage ctrl = msg as ControlMessage;
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
                r?.flowComplete();
                _messageIds._freeID(mId);
                _inflight.remove(mId);
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
            r?.flowComplete();
            _messageIds._freeID(mId);
            _inflight.remove(mId);
            break;
        }
        break;
      case MessageType.PUBLISH:
        final p = msg as Publish;
        _conn._onServerPublish(p);
        pub.sink.add(p);
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
          msg.r?.flowComplete();
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
      final ack = _ack(this as Connection, p);
      for (var pubMsg in p.messages) {
        var m = Message.messageFromPublish(p.getInfo().messageID, pubMsg, ack);
        eventChannel.notify(m);
        if (msg.hasListener) {
          msg.sink.add(m);
        }
      }
      // Acknowledge the delivery once it has been handed to the application.
      ack();
    });
  }

  /// keepAlive - Send ping when connection unused for set period
  /// connection passed in to avoid race condition on shutdown
  Future<void> _keepAlive() async {
    int pingInterval;
    var pingSent = _conn._timeNow();

    if (_opts._resolvedKeepAlive > 10) {
      pingInterval = 5;
    } else {
      pingInterval = _opts._resolvedKeepAlive ~/ 2;
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
      var liveDuration = Duration(seconds: _opts._resolvedKeepAlive).inSeconds;
      var timeout = _conn._timeNow().add(-_opts._resolvedPingTimeout);

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
          _conn._timeNow().difference(pingSent) >= _opts._resolvedPingTimeout) {
        await _conn
            ._internalConnLost(); // no harm in calling this if the connection is already down (better than stopping!)
        timer.cancel();
      }
    });
  }

  /// ack acknowledges a packet
  Function() _ack(Connection c, Publish msg) {
    return () {
      // The server expects an ACKNOWLEDGE for express deliveries and a RECEIPT
      // for reliable and batch deliveries, which it then COMPLETEs.
      switch (DeliveryMode.values[msg.getInfo().deliveryMode]) {
        case DeliveryMode.express:
          var ack = ControlMessage(msg.getInfo().messageID, MessageType.PUBLISH,
              FlowControl.ACKNOWLEDGE);
          send.sink.add(MessageAndResult(ack));
          break;
        case DeliveryMode.reliable:
        case DeliveryMode.batch:
          var rec = ControlMessage(msg.getInfo().messageID, MessageType.PUBLISH,
              FlowControl.RECEIPT);

          /// persist outbound
          _conn.storeOutbound(rec);

          send.sink.add(MessageAndResult(rec));
          break;
        default:
          break;
      }
    };
  }
}
