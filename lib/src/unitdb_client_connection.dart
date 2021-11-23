part of unitdb_client;

/// Various constant parts of the Client Connection.
/// MasterContract contract is default contract used for topics if client program does not specify Contract in the request
const MasterContract = 3376684800;

class Connection with ConnectionHandler {
  Connection(String target, String clientID, Options opts) {
    // set default options
    this._opts = opts.withDefaultOptions();
    this._contract = MasterContract;
    this._messageIds = _MessageIdentifiers();
    this._callbacks = Map<int, MessageHandler>();

    this._opts.addServer(target);
    this._opts.setClientID(clientID);
    this._callbacks[0] = opts.defaultMessageHandler;
  }

  /// The stream on which all subscribed topic messages are published to.
  Stream<List<Message>> get messageStream => eventChannel?.changes;

  void cancelTimer() {
    _keepAliveTimer.cancel();
  }

  Future<void> _close() async {
    if (!_setClosed()) {
      // error disconnecting client.
      return;
    }

    await Future.wait(_waitGroup);

    cancelTimer();
    connectionHandler.close();
    await send.close();
    await pub.close();
  }

  /// Connect will create a connection to the server
  /// The context will be used in the grpc stream connection.
  Future<Result> connect() async {
    var r = ConnectResult(); // Connect to the server
    if (_opts.servers.isEmpty) {
      r.setError("no servers defined to connect to");
      // no servers defined to connect to.
      return r;
    }

    try {
      var rc = await _attemptConnection();
      r.returnCode = rc.index;
      if (rc != ConnectReturnCode.Accepted) {
        r.setError("failed to connect to messaging server");
        throw "failed to connect to messaging server, $rc";
      }
    } on Exception catch (e) {
      r.setError(e.toString());
      rethrow;
    }
    _setConnected();

    if (_opts.onConnectionHandler != null) {
      _opts.onConnectionHandler(this);
    }

    if (_opts.keepAlive != 0) {
      _pingOutstanding = 0;
      _updateLastAction();
      _updateLastTouched();
      _waitGroup.add(_keepAlive());
    }

    _readLoop(); // process incoming messages
    _waitGroup.add(_writeLoop()); // send messages to servers
    _dispatcher(); // dispatch messages to client

    return r;
  }

  Future<ConnectReturnCode> _attemptConnection() async {
    int returnCode;
    for (var uri in _opts.servers) {
      try {
        await newConnection(this, uri, _opts.connectTimeout);
        // get Connect message from options.
        var cm = Connect.withOptions(_opts, uri);
        returnCode = await _connect(cm);
        if (returnCode == ConnectReturnCode.Accepted.index) {
          break;
        }
      } on Exception catch (e) {
        final message =
            'Connect: The connection to the unitdb messaging server ${uri.host}:${uri.port} could not be made. ${e.toString()}';
        throw NoConnectionException(message);
      }
      if (connectionHandler != null) {
        connectionHandler.close();
      }
    }
    return ConnectReturnCode.values[returnCode];
  }

  /// disconnect will disconnect the connection to the server
  Future<void> disconnect() async {
    if (_isClosed()) {
      // Disconnect() called but not connected
      return;
    }

    var p = Disconnect();
    var r = DisconnectResult();
    send.sink.add(MessageAndResult(p, r: r));
    // await r.get(opts.writeTimeout);

    await _close();
    _messageIds._cleanUp();
  }

// serverDisconnect cleanup when server send disconnect request or an error occurs.
  void serverDisconnect() {
    if (_isClosed()) {
      // Disconnect() called but not connected
      return;
    }
    if (_opts.connectionLostHandler != null) {
      _opts.connectionLostHandler();
    }
  }

  /// internalConnLost cleanup when connection is lost or an error occurs
  Future<void> _internalConnLost() async {
    // It is possible that internalConnLost will be called multiple times simultaneously
    // (including after sending a DisconnectPacket) as such we only do cleanup etc if the
    // routines were actually running and are not being disconnected at users request
    if (!_isClosed()) {
      if (_opts.cleanSession) {
        _messageIds._cleanUp();
      }
      if (_opts.connectionLostHandler != null) {
        _opts.connectionLostHandler();
      }
    }

    await _close();
  }

  /// publish will publish a message with the specified delivery mode and content
  /// to the specified topic.
  Result publish(String topic, Uint8List payload,
      {deliveryMode = DeliveryMode.express, int delay = 0, String ttl = ""}) {
    var r = PublishResult();
    if (_isClosed()) {
      r.setError("error not connected");
      return r;
    }

    List<PublishMessage> messages = [PublishMessage(topic, payload, ttl)];
    final messageID = _messageIds._nextID(r);
    final pub = Publish(messageID, messages);

    var publishWaitTimeout = _opts.writeTimeout;
    if (publishWaitTimeout.inMilliseconds == 0) {
      publishWaitTimeout = _opts.writeTimeout;
    }

    send.sink.add(MessageAndResult(pub, r: r));

    return r;
  }

// Relay send a new relay request. Provide a MessageHandler to be executed when
// a message is published on the topic provided.
  Result relay(List<String> topics, {String last = ""}) {
    var r = RelayResult();
    if (_isClosed()) {
      r.setError("error not connected");
      return r;
    }

    List<RelayRequest> requests = [];

    for (final topic in topics) {
      requests.add(RelayRequest(topic, last));
    }

    final messageID = _messageIds._nextID(r);
    final rel = Relay(messageID, requests);

    var relayWaitTimeout = _opts.writeTimeout;
    if (relayWaitTimeout.inMilliseconds == 0) {
      relayWaitTimeout = _opts.writeTimeout;
    }

    send.sink.add(MessageAndResult(rel, r: r));

    return r;
  }

  /// Subscribe starts a new subscription. Provide a MessageHandler to be executed when
  /// a message is published on the topic provided.
  Result subscribe(String topic,
      {deliveryMode = DeliveryMode.express, int delay = 0}) {
    var r = SubscribeResult();
    if (_isClosed()) {
      r.setError("error not connected");
      return r;
    }

    final subs = [Subscription(topic, deliveryMode, delay)];
    final messageID = _messageIds._nextID(r);
    final sub = Subscribe(messageID, subs);

    var subscribeWaitTimeout = _opts.writeTimeout;
    if (subscribeWaitTimeout.inMilliseconds == 0) {
      subscribeWaitTimeout = Duration(seconds: 30);
    }

    send.sink.add(MessageAndResult(sub, r: r));

    return r;
  }

  /// Unsubscribe will end the subscription from each of the topics provided.
  /// Messages published to those topics from other clients will no longer be
  /// received.
  Result unsubscribe(List<String> topics) {
    var r = UnsubscribeResult();
    if (_isClosed()) {
      r.setError("error not connected");
      return r;
    }

    List<Subscription> subs = [];
    for (var topic in topics) {
      subs.add(Subscription(topic));
    }
    final messageID = _messageIds._nextID(r);
    final unsub = Unsubscribe(messageID, subs);

    var unsubscribeWaitTimeout = _opts.writeTimeout;
    if (unsubscribeWaitTimeout.inMilliseconds == 0) {
      unsubscribeWaitTimeout = Duration(seconds: 30);
    }

    send.sink.add(MessageAndResult(unsub, r: r));

    return r;
  }

  /// timeNow returns current wall time in UTC rounded to milliseconds.
  DateTime _timeNow() {
    return DateTime.now();
  }

  void _pingAcknowledgmentReceived() {
    _pingOutstanding = 0;
    _updateLastTouched();
    if (_opts.heartBeatHandler != null) {
      _opts.heartBeatHandler();
    }
  }

  void _updateLastAction() {
    if (_opts.keepAlive != 0) {
      _lastAction = _timeNow();
    }
  }

  void _updateLastTouched() {
    _lastTouched = _timeNow();
  }

  /// Set connected flag; return true if not already connected.
  bool _setConnected() {
    if (_closed == 0) {
      return true;
    }
    _closed = 0;
    return false;
  }

  /// Set closed flag; return true if not already closed.
  bool _setClosed() {
    if (_closed == 1) {
      return false;
    }
    _closed = 1;
    return true;
  }

  /// Check whether connection was closed.
  bool _isClosed() {
    return _closed != 0;
  }
}
