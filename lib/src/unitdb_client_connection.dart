part of unitdb_client;

/// Various constant parts of the Client Connection.
/// MasterContract contract is default contract used for topics if client program does not specify Contract in the request
const MasterContract = 3376684800;

class Connection with ConnectionHandler {
  Connection(String target, String clientID, Options opts) {
    // set default options
    this.opts = opts.withDefaultOptions();
    this.contract = MasterContract;
    this.messageIds = _MessageIdentifiers();
    this.callbacks = Map<int, MessageHandler>();

    this.opts.addServer(target);
    this.opts.setClientID(clientID);
    this.callbacks[0] = opts.defaultMessageHandler;
  }

  /// The stream on which all subscribed topic messages are published to.
  Stream<List<Message>> get messageStream => eventChannel?.changes;

  void cancelTimer() {
    keepAliveTimer.cancel();
  }

  Future<void> _close() async {
    if (!_setClosed()) {
      // error disconnecting client.
      return;
    }

    await Future.wait(waitGroup);

    cancelTimer();
    connectionHandler.close();
    send.close();
    pub.close();
  }

  /// Connect will create a connection to the server
  /// The context will be used in the grpc stream connection.
  Future<Result> connect() async {
    var r = ConnectResult(); // Connect to the server
    if (opts.servers.length == 0) {
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

    if (opts.keepAlive != 0) {
      _updateLastAction();
      _updateLastTouched();
      waitGroup.add(_keepAlive());
    }

    _readLoop(); // process incoming messages
    waitGroup.add(_writeLoop()); // send messages to servers
    _dispatcher(); // dispatch messages to client

    return r;
  }

  Future<ConnectReturnCode> _attemptConnection() async {
    int returnCode;
    for (var uri in opts.servers) {
      try {
        await newConnection(this, uri, opts.connectTimeout);
        // get Connect message from options.
        var cm = Connect.withOptions(opts, uri);
        returnCode = await _connect(cm);
        if (returnCode == ConnectReturnCode.Accepted.index) {
          break;
        }
      } on Exception catch (e) {
        final message =
            'Connect: The connection to the unite messaging server ${uri.host}:${uri.port} could not be made.';
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
    r.get(opts.writeTimeout);

    await _close();
    messageIds._cleanUp();
  }

// serverDisconnect cleanup when server send disconnect request or an error occurs.
  void serverDisconnect() {
    if (_isClosed()) {
      // Disconnect() called but not connected
      return;
    }
    if (opts.connectionLostHandler != null) {
      opts.connectionLostHandler(this);
    }
  }

  /// internalConnLost cleanup when connection is lost or an error occurs
  Future<void> _internalConnLost() async {
    // It is possible that internalConnLost will be called multiple times simultaneously
    // (including after sending a DisconnectPacket) as such we only do cleanup etc if the
    // routines were actually running and are not being disconnected at users request
    if (!_isClosed()) {
      if (opts.cleanSession) {
        messageIds._cleanUp();
      }
      if (opts.connectionLostHandler != null) {
        opts.connectionLostHandler(this);
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
    final messageID = messageIds._nextID(r);
    final pub = Publish(messageID, messages);

    var publishWaitTimeout = opts.writeTimeout;
    if (publishWaitTimeout == 0) {
      publishWaitTimeout = opts.writeTimeout;
    }

    send.sink.add(MessageAndResult(pub, r: r));

    return r;
  }

  /// Subscribe starts a new subscription. Provide a MessageHandler to be executed when
  /// a message is published on the topic provided.
  Result subscribe(String topic,
      {deliveryMode = DeliveryMode.express, int delay = 0, String last = ""}) {
    var r = SubscribeResult();
    if (_isClosed()) {
      r.setError("error not connected");
      return r;
    }

    final subs = [Subscription(topic, deliveryMode, delay, last)];
    final messageID = messageIds._nextID(r);
    final sub = Subscribe(messageID, subs);

    var subscribeWaitTimeout = opts.writeTimeout;
    if (subscribeWaitTimeout == 0) {
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
    final messageID = messageIds._nextID(r);
    final unsub = Unsubscribe(messageID, subs);

    var unsubscribeWaitTimeout = opts.writeTimeout;
    if (unsubscribeWaitTimeout == 0) {
      unsubscribeWaitTimeout = Duration(seconds: 30);
    }

    send.sink.add(MessageAndResult(unsub, r: r));

    return r;
  }

  /// timeNow returns current wall time in UTC rounded to milliseconds.
  DateTime _timeNow() {
    return DateTime.now();
  }

  void _updateLastAction() {
    if (opts.keepAlive != 0) {
      lastAction = _timeNow();
    }
  }

  void _updateLastTouched() {
    lastTouched = _timeNow();
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
