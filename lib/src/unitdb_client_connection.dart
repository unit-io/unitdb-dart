part of unitdb_client;

/// Various constant parts of the Client Connection.
/// MasterContract contract is default contract used for topics if client program does not specify Contract in the request
const MasterContract = 3376684800;

/// clientIdTopic is the topic the server sends a client a client ID on: a
/// renewed one after it connected (see Options.withClientIdHandler), or a
/// new one when it connected without one, or with one the server cannot
/// open.
const clientIdTopic = 'unitdb/clientid/';

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

  /// The client ID the client connects with: the one it was made with, or
  /// the one the server renewed it with since (see
  /// Options.withClientIdHandler).
  String get clientId => _opts.clientID ?? '';

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
        r.returnCode = rc;
        if (rc != ConnectReturnCode.Accepted.index) {
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
              "failed to connect to messaging server, ${_describeReturnCode(rc)}");
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

  /// _describeReturnCode names a return code of a CONNECT, for errors.
  static String _describeReturnCode(int code) {
    final rc = ConnectReturnCode.fromCode(code);
    return rc == null ? 'return code $code' : 'return code $code (${rc.name})';
  }

  /// _attemptConnection tries each server in turn, with the client's current
  /// client ID, which a renewal may have replaced. It returns Accepted's
  /// code, or the last return code a server sent, or ErrServerUnavailable's
  /// if no server answered.
  Future<int> _attemptConnection({bool resume = false}) async {
    int? returnCode;
    var result = ConnectReturnCode.ErrServerUnavailable.index;

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
        return ConnectReturnCode.Accepted.index;
      }
      final code = returnCode;
      if (code != null) {
        result = code;
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
      int? rc;
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
      if (rc == ConnectReturnCode.Accepted.index) {
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
    _failApiRequests(err);
  }

  /// _failApiRequests fails the API requests the server has not answered.
  /// With unanswered only, it fails those whose publish the server
  /// acknowledged, whose answers a lost connection lost: a reconnect sends
  /// the others again.
  void _failApiRequests(String err, {bool unanswered = false}) {
    for (final queue in _apiRequests.values) {
      queue.removeWhere((a) {
        if (unanswered && !a.p.completer.isCompleted) {
          return false;
        }
        a.r.setError(err);
        return true;
      });
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

    _failApiRequests('client disconnected');
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
      _failApiRequests('connection lost before the answer', unanswered: true);
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

  /// _onServerPublish handles what the server publishes to the client itself,
  /// before the message is dispatched: a renewed client ID, and the answers
  /// to API requests. The messages are dispatched, and acknowledged, as any
  /// other.
  void _onServerPublish(Publish p) {
    for (final m in p.messages) {
      if (m.topic == clientIdTopic) {
        _adoptClientId(utf8.decode(m.payload, allowMalformed: true));
        continue;
      }
      final queue = _apiRequests[m.topic];
      if (queue == null || queue.isEmpty) {
        continue;
      }
      // The server answers a connection's requests in order.
      final a = queue.removeAt(0);
      Object? answer;
      try {
        answer = jsonDecode(utf8.decode(m.payload));
      } on FormatException catch (e) {
        a.r.setError('unexpected answer on ${m.topic}: $e');
        continue;
      }
      a.r._take(answer);
    }
  }

  /// _adoptClientId takes a client ID the server renewed the client's with:
  /// the client connects with it from now on, reconnects included, and the
  /// client ID handler is told, to keep it.
  void _adoptClientId(String id) {
    if (id.isEmpty || id == _opts.clientID) {
      return;
    }
    _opts.setClientID(id);
    final handler = _opts.clientIdHandler;
    if (handler == null) {
      return;
    }
    try {
      handler(id);
    } catch (e, s) {
      print('Connection::clientIdHandler - $e; $s');
    }
  }

  /// _apiRequest publishes payload, as JSON, to the server's API topic
  /// `unitdb/<name>`, and completes r with the server's answer. The request
  /// is not kept in the local store: after a restart, nothing waits for its
  /// answer.
  T _apiRequest<T extends ApiResult>(String name, Object? payload, T r) {
    if (_isClosed()) {
      r.setError("error not connected");
      return r;
    }
    final topic = 'unitdb/$name';
    final p = PublishResult();
    final pub = Publish(_messageIds._nextID(p), [
      PublishMessage(
          topic, Uint8List.fromList(utf8.encode(jsonEncode(payload))), '')
    ]);
    final a = _ApiRequest(r, p);
    (_apiRequests[topic] ??= <_ApiRequest>[]).add(a);
    p.completer.future.then((_) {
      final err = p.error();
      if (err != null && _apiRequests[topic]?.remove(a) == true) {
        r.setError(err);
      }
    });
    _submit(MessageAndResult(pub, r: p));
    return r;
  }

  /// keygen asks the server for topic keys, one for each request: a
  /// `unitdb/keygen` request, which only a primary client, or a connection
  /// trusted as a service's, may make. The result completes with the keys,
  /// each with the uuid to revoke it with (none for a v1 key, which only
  /// unitdb v0.6.0 issues), or with an error, whose status is the server's:
  /// 400 for a ttl that is not a duration, 403 for a client that may not,
  /// 503 for a ttl in a v0.6.0 cluster with nodes that don't read v2 keys
  /// yet.
  ///
  /// ```dart
  /// final r = client.keygen([KeyRequest('teams.alpha...', type: 'rw', ttl: '24h')]);
  /// await r.get(const Duration(seconds: 5));
  /// final key = r.keys.single; // key.key, key.uuid
  /// client.subscribe('${key.key}/teams.alpha...');
  /// ```
  KeyGenResult keygen(List<KeyRequest> requests) =>
      _apiRequest('keygen', requests.map((k) => k.toJson()).toList(),
          KeyGenResult());

  /// requestClientId asks the server for a new secondary client ID of the
  /// client's contract: a `unitdb/clientid` request, which only a primary
  /// client may make (status 403 otherwise). The result has the ID, and its
  /// uuid to revoke it with (none for a v1 ID, which only unitdb v0.6.0
  /// issues).
  ClientIdResult requestClientId() =>
      _apiRequest('clientid', null, ClientIdResult());

  /// revoke revokes the v2 client ID or topic key of the client's contract
  /// with uuid, in decimal, as keygen and requestClientId give it: for ever,
  /// or until [until]. A revoked client ID is refused at connect, with
  /// ConnectReturnCode.ErrRefusedIDRejected; a revoked key with status 401.
  /// What is open stays: connections and subscriptions, until the client
  /// reconnects or subscribes again.
  ///
  /// Only a primary client may revoke (status 403 otherwise, a client a
  /// service vouched for included). The server answers 400 to a uuid of 0
  /// or not decimal, or an until gone by, and 404 if it is older than
  /// revocations.
  ApiResult revoke(String uuid, {DateTime? until}) =>
      _apiRequest(
          'revoke',
          {
            'uuid': uuid,
            if (until != null) 'until': until.millisecondsSinceEpoch ~/ 1000,
          },
          ApiResult());

  /// revokeAll revokes every client ID and topic key the client's contract
  /// was issued before now, in whole seconds, IDs sealed again from v1 ones
  /// included (and, on unitdb v0.6.0, every v1 ID and key): the client's own
  /// ID included, so get the IDs and keys to keep using a second later. Only a primary client may (status 403 otherwise); a
  /// cluster with nodes that don't read v2 client IDs and keys yet refuses
  /// it with status 503.
  ApiResult revokeAll() => _apiRequest('revoke', {'all': true}, ApiResult());

  /// vouch has a trusted service vouch for the connection, with the
  /// service's client ID: a `unitdb/service` request. The connection then
  /// publishes and subscribes on the contract's topics without topic keys,
  /// and may generate them, until it closes. The server answers 403 to an ID
  /// that is not a service's of the connection's contract, or that expired
  /// or was revoked. Keep service IDs on servers, never on clients or
  /// devices: a backend that opens connections for its users vouches for
  /// them.
  ApiResult vouch(String serviceClientId) =>
      _apiRequest('service', {'client_id': serviceClientId}, ApiResult());

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
