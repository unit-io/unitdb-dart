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
    this._messageIds._reset();
    this._callbacks = Map<int, MessageHandler>();

    this._opts.addServer(target);
    this._opts.setClientID(clientID);
    this._callbacks[0] = opts.defaultMessageHandler;
    this._closed = 1;
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

    /// disconnect local store
    await localStore?.disconnect();
    localStore = null;
  }

  /// Connect will create a connection to the server
  /// The context will be used in the grpc stream connection.
  Future<Result> connect() async {
    var r = ConnectResult(); // Connect to the server
    var sleep = Duration(seconds: 1);
    if (_opts.servers.isEmpty) {
      r.setError("no servers defined to connect to");
      // no servers defined to connect to.
      return r;
    }
    if (_opts.connectRetry && !_isClosed()) {
      r.returnCode = ConnectReturnCode.Accepted.index;
      r.flowComplete();
      return r;
    }

    if (_opts.persistenceStore == PersistenceStore.Localdb) {
      localStore = Store();
      await localStore.connect(_opts.username, reset: _opts.cleanSession);
    }

    if (_opts.connectRetry && !_opts.cleanSession) {
      _resumeMessageIds();
    }

    retry:
    while (true) {
      try {
        var rc = await _attemptConnection();
        r.returnCode = rc.index;
        if (rc != ConnectReturnCode.Accepted) {
          if (_opts.connectRetry) {
            await Future.delayed(sleep);
            if (sleep < _opts.maxConnectRetryDuration) {
              sleep *= 2;
            }
            if (_isClosed()) {
              continue retry;
            }
          }
          throw "failed to connect to messaging server, $rc";
        }
        break retry;
      } on Exception catch (e) {
        _setClosed();
        if (connectionHandler != null) {
          connectionHandler.close();
        }
        localStore?.disconnect();
        localStore = null;

        r.setError(e.toString());
        return r;
      }
    }

    _setConnected();

    if (_opts.keepAlive != 0) {
      _pingOutstanding = 0;
      _updateLastAction();
      _updateLastTouched();
      _waitGroup.add(_keepAlive());
    }

    runZonedGuarded(() async {
      try {
        _readLoop(); // process incoming messages
        _waitGroup.add(_writeLoop()); // send messages to servers
        _dispatcher(); // dispatch messages to client
      } on Exception catch (e) {
        final error =
            'Connection - internal connection lost to the unitdb messaging server. ${e.toString()}}';
        print(error);
      }
    }, (e, s) {
      final error =
          'Connection - internal connection lost to the unitdb messaging server. ${e.toString()}; ${s.toString()}';
      print(error);
      if (connectionHandler != null) {
        connectionHandler.close();
      }
      _conn._internalConnLost();
    });

    if (!_opts.cleanSession) {
      await _resume();
    }

    if (_opts.onConnectionHandler != null) {
      _opts.onConnectionHandler(this);
    }

    return r;
  }

  Future<ConnectReturnCode> _attemptConnection() async {
    int returnCode;

    for (var uri in _opts.servers) {
      String error;
      await runZonedGuarded(() async {
        await newConnection(this, uri, _opts.connectTimeout,
                authority: _opts.authority)
            .timeout(_opts.connectTimeout)
            .catchError((dynamic e) {
          error =
              'Connect: The connection to the unitdb messaging server ${uri.host}:${uri.port} could not be made. $e}';
          print(error);
        });
        if (error == null) {
          // get Connect message from options.
          var cm = Connect.withOptions(_opts, uri);
          returnCode = await _connect(cm).catchError((dynamic e) {
            final message =
                'Connect: The connection to the unitdb messaging server ${uri.host}:${uri.port} could not be made. ${e.toString()}';
            print(message);
          });
        }
      }, (e, s) {
        error =
            'Connect: The connection to the unitdb messaging server ${uri.host}:${uri.port} could not be made. ${e.toString()}; ${s.toString()}';
        print(error);
      });
      if (returnCode == ConnectReturnCode.Accepted.index) {
        return ConnectReturnCode.Accepted;
      }
      if (connectionHandler != null) {
        connectionHandler.close();
      }
    }
    return ConnectReturnCode.ErrRefusedServerUnavailable;
  }

// internal function used to reconnect the client when it loses its connection
  Future<void> reconnect() async {
    var sleep = Duration(seconds: 1);

    while (true) {
      try {
        var rc = await _attemptConnection();
        if (rc == ConnectReturnCode.Accepted) {
          _setConnected();
          break;
        }
      } on Exception catch (e) {
        final message =
            'Connection::reconnect - Exception occured ${e.toString()}';
        print(message);
        _setClosed();
        if (connectionHandler != null) {
          connectionHandler.close();
        }
        localStore?.disconnect();
        localStore = null;
        throw NoConnectionException(message);
      }
      await Future.delayed(sleep);
      if (sleep < _opts.maxReconnectDuration) {
        sleep *= 2;
      }

      if (sleep > _opts.maxReconnectDuration) {
        sleep = _opts.maxReconnectDuration;
      }
      // Disconnect may have been called
      if (_isClosed()) {
        return;
      }
    }

    if (_opts.keepAlive != 0) {
      _pingOutstanding = 0;
      _updateLastAction();
      _updateLastTouched();
      _waitGroup.add(_keepAlive());
    }

    runZonedGuarded(() async {
      try {
        _readLoop(); // process incoming messages
      } on Exception catch (e) {
        final error =
            'Connection - internal connection lost to the unitdb messaging server. ${e.toString()}}';
        print(error);
      }
    }, (e, s) {
      final error =
          'Connection - internal connection lost to the unitdb messaging server. ${e.toString()}; ${s.toString()}';
      print(error);
      if (connectionHandler != null) {
        connectionHandler.close();
      }
      _conn._internalConnLost();
    });

    _resume();

    if (_opts.onConnectionHandler != null) {
      _opts.onConnectionHandler(this);
    }
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
      if (_opts.cleanSession && !_opts.autoReconnect) {
        _messageIds._cleanUp();
      }
      if (_opts.autoReconnect) {
        reconnect();
      }
      if (_opts.connectionLostHandler != null) {
        _opts.connectionLostHandler();
      }
    }
  }

  /// publish will publish a message with the specified delivery mode and content
  /// to the specified topic.
  Result publish(String topic, Uint8List payload,
      {deliveryMode = DeliveryMode.express, int delay = 0, String ttl = ""}) {
    var r = PublishResult();
    if (!_opts.connectRetry && _isClosed()) {
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

    /// persist outbound
    storeOutbound(pub);

    switch (_isClosed()) {
      case true:
        print('storing publish message, topic: $topic');
        break;
      default:
        send.sink.add(MessageAndResult(pub, r: r));
    }

    return r;
  }

// Relay send a new relay request. Provide a MessageHandler to be executed when
// a message is published on the topic provided.
  Result relay(List<String> topics, {String last = ""}) {
    var r = RelayResult();
    if (!_opts.connectRetry && _isClosed()) {
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

    /// persist outbound
    storeOutbound(rel);

    switch (_isClosed()) {
      case true:
        print('storing relay message, topics: $topics');
        break;
      default:
        send.sink.add(MessageAndResult(rel, r: r));
    }

    return r;
  }

  /// Subscribe starts a new subscription. Provide a MessageHandler to be executed when
  /// a message is published on the topic provided.
  Result subscribe(String topic,
      {deliveryMode = DeliveryMode.express, int delay = 0}) {
    var r = SubscribeResult();
    if (!_opts.connectRetry && _isClosed()) {
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

    /// persist outbound
    storeOutbound(sub);

    switch (_isClosed()) {
      case true:
        print('storing subscribe message, topic: $topic');
        break;
      default:
        send.sink.add(MessageAndResult(sub, r: r));
    }

    return r;
  }

  /// Unsubscribe will end the subscription from each of the topics provided.
  /// Messages published to those topics from other clients will no longer be
  /// received.
  Result unsubscribe(List<String> topics) {
    var r = UnsubscribeResult();
    if (!_opts.connectRetry && _isClosed()) {
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

    /// persist outbound
    storeOutbound(unsub);

    switch (_isClosed()) {
      case true:
        print('storing unsubcribe message, topics: $topics');
        break;
      default:
        send.sink.add(MessageAndResult(unsub, r: r));
    }

    return r;
  }

  /// Resume message Ids for publish message to ensure these are are not duplicated
  Future<void> _resumeMessageIds() async {
    final keys = await localStore?.keys();
    if (keys == null) {
      return;
    }
    for (final key in keys) {
      final message =
          await localStore?.getMessage(sessionId, key)?.catchError((dynamic e) {
        final error = 'Connect: error on resume message Ids. $e}';
        print(error);
      });
      if (message == null) {
        continue;
      }
      switch (message.type()) {
        case MessageType.PUBLISH:
          var r = PublishResult();
          r.messageID = message.getInfo().messageID;
          _messageIds._resumeID(r.messageID, r);
      }
    }
  }

  // Load all stored messages and resend them to ensure DeliveryMode even after an application crash.
  Future<void> _resume() async {
    final keys = await localStore?.keys();
    if (keys == null) {
      return;
    }
    for (final key in keys) {
      final message =
          await localStore?.getMessage(sessionId, key)?.catchError((dynamic e) {
        final error = 'Connect: error on resume. $e}';
        print(error);
      });
      if (message == null) {
        continue;
      }
      switch (message.type()) {
        case MessageType.RELAY:
          var r = RelayResult();
          r.messageID = message.getInfo().messageID;
          send.sink.add(MessageAndResult(message, r: r));
          break;
        case MessageType.SUBSCRIBE:
          var r = SubscribeResult();
          r.messageID = message.getInfo().messageID;
          send.sink.add(MessageAndResult(message, r: r));
          break;
        case MessageType.UNSUBSCRIBE:
          var r = UnsubscribeResult();
          r.messageID = message.getInfo().messageID;
          send.sink.add(MessageAndResult(message, r: r));
          break;
        case MessageType.PUBLISH:
          var r = PublishResult();
          r.messageID = message.getInfo().messageID;
          send.sink.add(MessageAndResult(message, r: r));
          break;
        case MessageType.FLOWCONTROL:
          final controlMessage = message as ControlMessage;
          switch (controlMessage.flowControl) {
            case FlowControl.RECEIPT:
              send.sink.add(MessageAndResult(controlMessage));
              break;
            case FlowControl.NOTIFY:
              final recv = ControlMessage(message.getInfo().messageID,
                  MessageType.PUBLISH, FlowControl.RECEIVE);
              send.sink.add(MessageAndResult(recv));
              break;
          }
          break;
        default:
          await localStore?.deleteMessage(sessionId, key);
      }
    }
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

  void storeInbound(UtpMessage inMessage) {
    localStore?.persistInbound(sessionId, inMessage);
  }

  void storeOutbound(UtpMessage outMessage) {
    localStore?.persistOutbound(sessionId, outMessage);
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
