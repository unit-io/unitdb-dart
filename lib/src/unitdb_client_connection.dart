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
    this._callbacks = Map<int, MessageHandler?>();

    this._opts.addServer(target);
    this._opts.setClientID(clientID);
    this._callbacks[0] = opts.defaultMessageHandler;
    this._closed = 1;
  }

  /// The stream on which all subscribed topic messages are published to.
  Stream<List<Message>> get messageStream => eventChannel.changes;

  void cancelTimer() {
    _keepAliveTimer?.cancel();
  }

  Future<void> _close() async {
    if (!_setClosed()) {
      // error disconnecting client.
      return;
    }

    await Future.wait(_waitGroup);

    cancelTimer();
    // Drain queued messages (including DISCONNECT) to the server before
    // closing the connection they are written to.
    await send.close();
    final handler = connectionHandler;
    if (handler is GrpcConnectionHandler) {
      await handler.closeGracefully(const Duration(seconds: 1));
    } else {
      handler.close();
    }
    await pub.close();

    /// disconnect local store
    await localStore?.disconnect();
    localStore = null;
  }

  /// Connect will create a connection to the server
  /// The context will be used in the grpc stream connection.
  Future<Result> connect({String? userName, String? userToken}) async {
    _opts.withUserNamePassword(
        userName ?? _opts._resolvedUsername,
        userToken == null
            ? _opts._resolvedPassword
            : Uint8List.fromList(userToken.codeUnits));

    var r = ConnectResult(); // Connect to the server
    var sleep = Duration(seconds: 1);
    if (_opts._resolvedServers.isEmpty) {
      r.setError("no servers defined to connect to");
      // no servers defined to connect to.
      return r;
    }
    if (_opts._resolvedConnectRetry && !_isClosed()) {
      r.returnCode = ConnectReturnCode.Accepted.index;
      r.flowComplete();
      return r;
    }

    if (_opts.persistenceStore == PersistenceStore.Localdb) {
      final store = Store();
      localStore = store;
      await store.connect(_opts._resolvedUsername,
          reset: _opts._resolvedCleanSession);
    }

    if (_opts._resolvedConnectRetry && !_opts._resolvedCleanSession) {
      _resumeMessageIds();
    }

    retry:
    while (true) {
      try {
        var rc = await _attemptConnection();
        r.returnCode = rc.index;
        if (rc != ConnectReturnCode.Accepted) {
          if (_opts._resolvedConnectRetry) {
            await Future.delayed(sleep);
            if (sleep < _opts._resolvedMaxConnectRetryDuration) {
              sleep *= 2;
            }
            if (_isClosed()) {
              continue retry;
            }
          }
          throw NoConnectionException(
              "failed to connect to messaging server, $rc");
        }
        break retry;
      } catch (e) {
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

    if (_opts._resolvedKeepAlive != 0) {
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

    if (!_opts._resolvedCleanSession) {
      await _resume();
    }

    _opts.onConnectionHandler?.call(this);

    r.flowComplete();
    return r;
  }

  /// _attemptConnection tries each server in turn. It returns Accepted, or the
  /// last return code a server sent, or ErrRefusedServerUnavailable if no
  /// server answered.
  Future<ConnectReturnCode> _attemptConnection({bool resume = false}) async {
    int? returnCode;
    var result = ConnectReturnCode.ErrRefusedServerUnavailable;

    for (var uri in _opts._resolvedServers) {
      returnCode = null;
      String? error;
      await runZonedGuarded(() async {
        await newConnection(this, uri, _opts._resolvedConnectTimeout,
                authority: _opts._resolvedAuthority)
            .timeout(_opts._resolvedConnectTimeout)
            .catchError((dynamic e) {
          error =
              'Connect: The connection to the unitdb messaging server ${uri.host}:${uri.port} could not be made. $e}';
          print(error);
          return false;
        });
        if (error == null) {
          // get Connect message from options.
          var cm = Connect.withOptions(_opts, uri);
          if (resume) {
            // A reconnect resumes the session.
            cm._cleanSessFlag = false;
          }
          returnCode = await _connect(cm).catchError((dynamic e) {
            final message =
                'Connect: The connection to the unitdb messaging server ${uri.host}:${uri.port} could not be made. ${e.toString()}';
            print(message);
            return null;
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
      final code = returnCode;
      if (code != null &&
          code >= 0 &&
          code < ConnectReturnCode.values.length) {
        result = ConnectReturnCode.values[code];
      }
      if (connectionHandler != null) {
        connectionHandler.close();
      }
    }
    return result;
  }

/// reconnect connects the client again after it lost its connection,
  /// trying each server in turn and pausing longer after each failed round,
  /// up to maxReconnectDuration, until it connects or is disconnected.
  Future<void> reconnect() async {
    final max = _opts._resolvedMaxReconnectDuration;
    var sleep = const Duration(seconds: 1);
    if (sleep > max) {
      sleep = max;
    }
    while (!_isClosed()) {
      ConnectReturnCode? rc;
      try {
        rc = await _attemptConnection(resume: true);
      } catch (e) {
        print('Connection::reconnect - ${e.toString()}');
      }
      if (_isClosed()) {
        // Disconnect was called meanwhile.
        connectionHandler?.close();
        return;
      }
      if (rc == ConnectReturnCode.Accepted) {
        _reconnected();
        return;
      }
      await Future<void>.delayed(sleep);
      sleep *= 2;
      if (sleep > max) {
        sleep = max;
      }
    }
  }

  /// _reconnected restarts the connection's loops, subscribes again to the
  /// client's topics, and sends again what the server had not answered, then
  /// what was requested while the client reconnected. A message in flight
  /// when the connection dropped can be delivered twice.
  void _reconnected() {
    _down = false;
    if (_opts._resolvedKeepAlive != 0) {
      cancelTimer();
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

    if (_subscriptions.isNotEmpty) {
      final r = SubscribeResult();
      final sub = Subscribe(_messageIds._nextID(r), _subscriptions.values.toList());
      send.sink.add(MessageAndResult(sub, r: r));
    }
    final queued = List<MessageAndResult>.from(_pending);
    _pending.clear();
    for (final m in _inflight.values.toList()) {
      if (!queued.contains(m)) {
        send.sink.add(m);
      }
    }
    for (final m in queued) {
      send.sink.add(m);
    }

    _opts.onConnectionHandler?.call(this);
  }

  /// _submit sends a request, or keeps it while the client reconnects, for
  /// up to the write timeout. A request is kept until the server answers it.
  void _submit(MessageAndResult m) {
    final id = m.m.getInfo().messageID;
    _inflight[id] = m;
    if (!_down) {
      send.sink.add(m);
      return;
    }
    _pending.add(m);
    Timer(_opts._resolvedWriteTimeout, () {
      if (_pending.remove(m)) {
        _fail(m, 'not connected within the write timeout');
      }
    });
  }

  /// _fail completes a request with err, and forgets it.
  void _fail(MessageAndResult m, String err) {
    final id = m.m.getInfo().messageID;
    _inflight.remove(id);
    _messageIds._freeID(id);
    m.r?.setError(err);
  }

  /// _failAll fails the requests the server has not answered.
  void _failAll(String err) {
    _pending.clear();
    for (final m in _inflight.values.toList()) {
      _fail(m, err);
    }
  }

  /// disconnect will disconnect the connection to the server
  Future<void> disconnect() async {
    if (_isClosed()) {
      // Disconnect() called but not connected
      return;
    }
    if (_down) {
      // Reconnecting: there is no connection to send DISCONNECT on. The
      // reconnect loop stops, seeing the client closed.
      _setClosed();
      _down = false;
      cancelTimer();
      _failAll('client disconnected');
      connectionHandler?.close();
      await localStore?.disconnect();
      localStore = null;
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
    _opts.connectionLostHandler?.call();
  }

  /// internalConnLost cleanup when connection is lost or an error occurs
  Future<void> _internalConnLost() async {
    // It is possible that internalConnLost will be called multiple times simultaneously
    // (including after sending a DisconnectPacket) as such we only do cleanup etc if the
    // routines were actually running and are not being disconnected at users request
    if (_isClosed() || _down) {
      // Closed, or a reconnect is under way.
      return;
    }
    connectionHandler?.close();
    if (_opts._resolvedAutoReconnect) {
      _down = true;
      _opts.connectionLostHandler?.call();
      reconnect();
      return;
    }
    // Without auto reconnect the client closes: its calls fail from now on.
    _setClosed();
    cancelTimer();
    _failAll('connection lost');
    _messageIds._cleanUp();
    _opts.connectionLostHandler?.call();
  }

  /// publish will publish a message with the specified delivery mode and content
  /// to the specified topic.
  Result publish(String topic, Uint8List payload,
      {deliveryMode = DeliveryMode.express, int delay = 0, String ttl = ""}) {
    var r = PublishResult();
    if (!_opts._resolvedConnectRetry && _isClosed()) {
      r.setError("error not connected");
      return r;
    }

    List<PublishMessage> messages = [PublishMessage(topic, payload, ttl)];
    final messageID = _messageIds._nextID(r);
    final pub = Publish(messageID, messages, deliveryMode);

    var publishWaitTimeout = _opts._resolvedWriteTimeout;
    if (publishWaitTimeout.inMilliseconds == 0) {
      publishWaitTimeout = _opts._resolvedWriteTimeout;
    }

    /// persist outbound
    storeOutbound(pub);

    switch (_isClosed()) {
      case true:
        print('storing publish message, topic: $topic');
        break;
      default:
        _submit(MessageAndResult(pub, r: r));
    }

    return r;
  }

// Relay send a new relay request. Provide a MessageHandler to be executed when
// a message is published on the topic provided.
  Result relay(List<String> topics, {String last = ""}) {
    var r = RelayResult();
    if (!_opts._resolvedConnectRetry && _isClosed()) {
      r.setError("error not connected");
      return r;
    }

    List<RelayRequest> requests = [];

    for (final topic in topics) {
      requests.add(RelayRequest(topic, last));
    }

    final messageID = _messageIds._nextID(r);
    final rel = Relay(messageID, requests);

    var relayWaitTimeout = _opts._resolvedWriteTimeout;
    if (relayWaitTimeout.inMilliseconds == 0) {
      relayWaitTimeout = _opts._resolvedWriteTimeout;
    }

    /// persist outbound
    storeOutbound(rel);

    switch (_isClosed()) {
      case true:
        print('storing relay message, topics: $topics');
        break;
      default:
        _submit(MessageAndResult(rel, r: r));
    }

    return r;
  }

  /// Subscribe starts a new subscription. Provide a MessageHandler to be executed when
  /// a message is published on the topic provided.
  Result subscribe(String topic,
      {deliveryMode = DeliveryMode.express, int delay = 0}) {
    var r = SubscribeResult();
    if (!_opts._resolvedConnectRetry && _isClosed()) {
      r.setError("error not connected");
      return r;
    }

    final subs = [Subscription(topic, deliveryMode, delay)];
    _subscriptions[topic] = subs[0];
    final messageID = _messageIds._nextID(r);
    final sub = Subscribe(messageID, subs);

    var subscribeWaitTimeout = _opts._resolvedWriteTimeout;
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
        _submit(MessageAndResult(sub, r: r));
    }

    return r;
  }

  /// Unsubscribe will end the subscription from each of the topics provided.
  /// Messages published to those topics from other clients will no longer be
  /// received.
  Result unsubscribe(List<String> topics) {
    var r = UnsubscribeResult();
    if (!_opts._resolvedConnectRetry && _isClosed()) {
      r.setError("error not connected");
      return r;
    }

    List<Subscription> subs = [];
    for (var topic in topics) {
      subs.add(Subscription(topic));
      _subscriptions.remove(topic);
    }
    final messageID = _messageIds._nextID(r);
    final unsub = Unsubscribe(messageID, subs);

    var unsubscribeWaitTimeout = _opts._resolvedWriteTimeout;
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
        _submit(MessageAndResult(unsub, r: r));
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
          await localStore?.getMessage(sessionId, key).catchError((dynamic e) {
        final error = 'Connect: error on resume message Ids. $e}';
        print(error);
        return null;
      });
      if (message == null) {
        continue;
      }
      switch (message.type()) {
        case MessageType.PUBLISH:
          var r = PublishResult();
          final id = message.getInfo().messageID;
          r.messageID = id;
          _messageIds._resumeID(id, r);
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
          await localStore?.getMessage(sessionId, key).catchError((dynamic e) {
        final error = 'Connect: error on resume. $e}';
        print(error);
        return null;
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
    _opts.heartBeatHandler?.call();
  }

  void _updateLastAction() {
    if (_opts._resolvedKeepAlive != 0) {
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
