part of unitdb_client;

/// MessageHandler is a callback type which can be set to be
/// executed upon the arrival of messages published to topics
/// to which the client is subscribed.
typedef MessageHandler = void Function(dynamic, Stream<Message>);

/// OnConnectionHandler is a callback that is called when connection to the server is established.
typedef OnConnectionHandler = void Function(dynamic);

/// ConnectionLostHandler is a callback that is set to be executed
/// upon an uninteded disconnection from server.
typedef ConnectionLostHandler = void Function();

/// HeartBeatHandler is a callback that is set to be executed
/// when ping response is received from the server.
/// Can be used for health monitoring outside of the client itself.
typedef HeartBeatHandler = void Function();

/// ClientIdHandler is a callback that is called with the client ID the
/// server renewed the client's with (see Options.withClientIdHandler).
typedef ClientIdHandler = void Function(String clientId);

enum PersistenceStore { None, Memory, Localdb }

class Options {
  Options();

  static const _defaultWriteTimeout = Duration(seconds: 60);

  // The fields are unset (null) until withDefaultOptions() fills in their
  // defaults. A connection holds the options withDefaultOptions() returned
  // and reads them through the _resolved getters below, which fall back to
  // the same defaults.
  static const _defaultKeepAlive = 60;
  static const _defaultPingTimeout = Duration(seconds: 60);
  static const _defaultConnectTimeout = Duration(seconds: 60);
  static const _defaultMaxReconnectDuration = Duration(minutes: 10);
  static const _defaultMaxConnectRetryDuration = Duration(seconds: 30);

  List<Uri>? servers;
  String? authority;
  PersistenceStore? persistenceStore;
  String? clientID;
  bool? insecureFlag;
  String? username;
  Uint8List? password;
  String? sessionData;
  bool? cleanSession;
  // tls.Config tLSConfig;
  int? keepAlive;
  int? sessionKey;
  Duration? pingTimeout;
  Duration? connectTimeout;
  Duration? maxReconnectDuration;
  bool? autoReconnect;
  Duration? maxConnectRetryDuration;
  bool? connectRetry;
  String? storePath;
  int? storeSize;
  Duration? storeLogReleaseDuration;
  MessageHandler? defaultMessageHandler;
  OnConnectionHandler? onConnectionHandler;
  ConnectionLostHandler? connectionLostHandler;
  HeartBeatHandler? heartBeatHandler;
  ClientIdHandler? clientIdHandler;
  Duration? writeTimeout;
  Duration? batchDuration;
  int? batchByteThreshold;
  int? batchCountThreshold;

  void addServer(String target) {
    var re = RegExp(r'%(25)?');
    if (target.isNotEmpty && target[0] == ':') {
      target = "127.0.0.1" + target;
    }
    if (!target.contains('://')) {
      target = "grpc://" + target;
    }
    target = target.replaceAll(re, "%25");
    var uri = Uri.parse(target);
    (this.servers ??= <Uri>[]).add(uri);
  }

  void setClientID(String clientID) {
    this.clientID = clientID;
  }

  /// WithDefaultOptions will create client connection with some default values.
  ///   CleanSession: True
  ///   KeepAlive: 30 (seconds)
  ///   ConnectTimeout: 30 (seconds)
  Options withDefaultOptions() {
    var o = Options();
    o.authority = this.authority ?? '';
    o.persistenceStore = this.persistenceStore ?? PersistenceStore.None;
    o.insecureFlag = this.insecureFlag ?? false;
    o.username = this.username ?? "";
    o.password = this.password ?? Uint8List(0);
    o.sessionData = this.sessionData ?? "";
    o.cleanSession = this.cleanSession ?? false;
    o.keepAlive = this.keepAlive ?? _defaultKeepAlive;
    o.pingTimeout = this.pingTimeout ?? _defaultPingTimeout;
    o.connectTimeout = this.connectTimeout ?? _defaultConnectTimeout;
    o.maxReconnectDuration =
        this.maxReconnectDuration ?? _defaultMaxReconnectDuration;
    o.autoReconnect = this.autoReconnect ?? true;
    o.maxConnectRetryDuration =
        this.maxConnectRetryDuration ?? _defaultMaxConnectRetryDuration;
    o.connectRetry = this.connectRetry ?? false;
    o.sessionKey = this.sessionKey ?? 0;
    o.writeTimeout =
        this.writeTimeout ?? _defaultWriteTimeout; // 0 represents timeout disabled
    o.onConnectionHandler = this.onConnectionHandler;
    o.defaultMessageHandler = this.defaultMessageHandler;
    o.connectionLostHandler = this.connectionLostHandler;
    o.heartBeatHandler = this.heartBeatHandler;
    o.clientIdHandler = this.clientIdHandler;
    o.storePath = this.storePath ?? "/tmp/uniteb";
    o.storeSize = this.storeSize ?? 1 << 27;
    if (o._resolvedWriteTimeout.inSeconds > 0) {
      o.storeLogReleaseDuration =
          this.storeLogReleaseDuration ?? o.writeTimeout;
    } else {
      o.storeLogReleaseDuration = this.storeLogReleaseDuration ??
          Duration(minutes: 1); // must be greater than WriteTimeout
    }
    o.batchDuration = this.batchDuration ?? Duration(milliseconds: 100);
    // publish request (containing a batch of messages) in bytes. Must be lower
    // than the gRPC limit of 4 MiB.
    o.batchByteThreshold = this.batchByteThreshold ?? 4 * 1024 * 1024;
    o.batchCountThreshold = this.batchCountThreshold ?? 1000;
    return o;
  }

  List<Uri> get _resolvedServers => servers ?? const <Uri>[];
  String get _resolvedAuthority => authority ?? '';
  bool get _resolvedInsecureFlag => insecureFlag ?? false;
  String get _resolvedUsername => username ?? "";
  Uint8List get _resolvedPassword => password ?? Uint8List(0);
  bool get _resolvedCleanSession => cleanSession ?? false;
  int get _resolvedKeepAlive => keepAlive ?? _defaultKeepAlive;
  Duration get _resolvedPingTimeout => pingTimeout ?? _defaultPingTimeout;
  Duration get _resolvedConnectTimeout =>
      connectTimeout ?? _defaultConnectTimeout;
  Duration get _resolvedMaxReconnectDuration =>
      maxReconnectDuration ?? _defaultMaxReconnectDuration;
  bool get _resolvedAutoReconnect => autoReconnect ?? true;
  Duration get _resolvedMaxConnectRetryDuration =>
      maxConnectRetryDuration ?? _defaultMaxConnectRetryDuration;
  bool get _resolvedConnectRetry => connectRetry ?? false;
  Duration get _resolvedWriteTimeout => writeTimeout ?? _defaultWriteTimeout;

  /// WithAuthority returns an Option which makes client connection and set Authority
  Options withAuthority(String authority) {
    this.authority = authority;
    return this;
  }

  /// WithClientID  returns an Option which makes client connection and set ClientID
  Options withClientID(String clientID) {
    this.clientID = clientID;
    return this;
  }

  /// WithPersistenceStore uses persistence store to persisting messages until it get an acknowledgement from Server.
  Options withPersistenceStore(PersistenceStore persistenceStore) {
    this.persistenceStore = persistenceStore;
    return this;
  }

  /// WithInsecure returns an Option which makes client connection
  /// with insecure flag so that client can provide topic with key prefix.
  /// Use insecure flag only for test and debug connection and not for live client.
  ///
  /// Since unitdb v0.6.0 the server refuses a client that connects with the
  /// insecure flag, with Connect Return Code 4,
  /// ConnectReturnCode.ErrNotAuthorized,
  /// unless its config sets `"allow_insecure": true`, which only a standalone
  /// server honors, for development. Clients publish and subscribe with topic
  /// keys instead, and a trusted backend connects with a service client ID
  /// (minted by the server's `cmd/mintid -service`), which needs no keys,
  /// or vouches with it for a connection it opens (Connection.vouch).
  Options withInsecure() {
    this.insecureFlag = true;
    return this;
  }

  /// WithUserNamePassword returns an Option which makes client connection and pass UserName
  Options withUserNamePassword(String userName, Uint8List password) {
    print('withUserNamePassword - userName $userName');
    this.username = userName;
    this.password = password;
    return this;
  }

  /// WithSessionData returns an Option which makes client connection and set SessionData
  @Deprecated('the server protocol has no session data; it is not sent')
  Options withSessionData(String sessionData) {
    this.sessionData = sessionData;
    return this;
  }

  /// WithSessionKey sets the key of the client's session, as unitdb-go's
  /// WithSessionKey. The server keys a session by the client ID and this
  /// key: clients sharing a client ID keep separate sessions with different
  /// keys. 0, the default, keys the session by the client ID alone.
  Options withSessionKey(int sessionKey) {
    this.sessionKey = sessionKey;
    return this;
  }

  /// WithCleanSession returns an Option which makes client connection and set CleanSession
  Options withCleanSession() {
    this.cleanSession = true;
    return this;
  }

  // // WithTLSConfig will set an SSL/TLS configuration to be used when connecting
  // // to server.
  // Options withTLSConfig(tls.Config t) {
  // 		this.tLSConfig = t;
  // }

  /// WithKeepAlive will set the amount of time (in seconds) that the client
  /// should wait before sending a PING request to the server. This will
  /// allow the client to know that a connection has not been lost with the
  /// server.
  Options withKeepAlive(int secs) {
    this.keepAlive = secs;
    return this;
  }

  /// WithPingTimeout will set the amount of time (in seconds) that the client
  /// will wait after sending a PING request to the server, before deciding
  /// that the connection has been lost. Default is 10 seconds.
  Options withPingTimeout(Duration t) {
    this.pingTimeout = t;
    return this;
  }

  /// WithWriteTimeout puts a limit on how long a publish should block until it unblocks with a
  /// timeout error. A duration of 0 never times out. Default never times out
  Options withWriteTimeout(Duration t) {
    this.writeTimeout = t;
    return this;
  }

  /// WithConnectTimeout limits how long the client will wait when trying to open a connection
  /// to server before timing out and erroring the attempt. A duration of 0 never times out.
  /// Default 30 seconds.
  Options withConnectTimeout(Duration t) {
    this.connectTimeout = t;
    return this;
  }

  /// WithMaxReconnectDuration sets the maximum time that will be waited between reconnection attempts
  /// when connection is lost
  Options withMaxReconnectDuration(Duration t) {
    this.maxReconnectDuration = t;
    return this;
  }

  /// WithAutoReconnect sets whether the automatic reconnection logic should be used
  /// when the connection is lost, even if disabled the ConnectionLostHandler is still called
  Options withAutoReconnect(bool autoReconnect) {
    this.autoReconnect = autoReconnect;
    return this;
  }

  /// WithConnectRetryDuration sets the time that will be waited between connection attempts
  /// when initially connecting
  Options withMaxConnectRetryDuration(Duration t) {
    this.maxConnectRetryDuration = t;
    return this;
  }

  /// WithConnectRetry sets whether the connect function will automatically retry the connection in case of a failure
  /// Setting this to TRUE permits mesages to be published before the connection is established
  Options withConnectRetry(bool connectRetry) {
    this.connectRetry = connectRetry;
    return this;
  }

  /// WithStoreDir sets database directory.
  Options withStorePath(String path) {
    this.storePath = path;
    return this;
  }

  /// WithStoreSize sets buffer size store will use to write messages into log.
  Options withStoreSize(int size) {
    this.storeSize = size;
    return this;
  }

  /// WithStoreLogReleaseDuration sets log release duration, it must be greater than WriteTimeout.
  Options withStoreLogReleaseDuration(Duration t) {
    if (t > (this.writeTimeout ?? _defaultWriteTimeout)) {
      this.storeLogReleaseDuration = t;
    }
    return this;
  }

  /// WithDefaultMessageHandler set default message handler to be called
  /// on message receive to all topics client has subscribed to.
  Options withDefaultMessageHandler(MessageHandler defaultHandler) {
    this.defaultMessageHandler = defaultHandler;
    return this;
  }

  /// WithConnectionHandler set handler function to be called when client is connected.
  Options withConnectionHandler(OnConnectionHandler handler) {
    this.onConnectionHandler = handler;
    return this;
  }

  /// WithConnectionLostHandler set handler function to be called
  /// when connection to the client is lost.
  Options withConnectionLostHandler(ConnectionLostHandler handler) {
    this.connectionLostHandler = handler;
    return this;
  }

  /// HeartBeatHandler is a callback that is set to be executed
  /// when ping response is received from the server.
  /// Can be used for health monitoring outside of the client itself.
  Options withHeartBeatHandler(HeartBeatHandler handler) {
    this.heartBeatHandler = handler;
    return this;
  }

  /// WithClientIdHandler sets a handler to be called with the client ID the
  /// server renewed the client's with, for the application to keep it, and
  /// connect with it from then on.
  ///
  /// After a client connects, the server (unitdb v0.6.0 and later) may send
  /// it its client ID sealed again, on `unitdb/clientid/`: when it connected
  /// with a v1 ID, with a v2 one sealed with a key being retired, or with
  /// one past 80% of its lifetime (the server's `client_id_ttl` or
  /// `primary_id_ttl`). It is the same ID: the same contract, permissions
  /// and sessions, with a new expiry. The client takes it whether or not a
  /// handler is set: it connects with it from then on, reconnects included,
  /// and Connection.clientId returns it. Its local store, kept by user name,
  /// and its session on the server, are kept. But an application that does
  /// not keep the new ID connects with the old one the next time it starts,
  /// and once that one expires the server refuses it, with
  /// ConnectReturnCode.ErrRefusedIDRejected.
  ///
  /// The handler runs on the client's read loop: keep it short, and start
  /// any slow work, such as writing the ID to storage, without waiting for
  /// it.
  Options withClientIdHandler(ClientIdHandler handler) {
    this.clientIdHandler = handler;
    return this;
  }

  /// withBatchDuration sets batch duration to group publish requestes into single group.
  /// Default 100 milliseconds.
  Options withBatchDuration(Duration t) {
    this.batchDuration = t;
    return this;
  }

  /// withBatchByteThreshold sets byte threshold for publish batch.
  /// Default 3.5 iMB.
  Options withBatchByteThreshold(int size) {
    this.batchByteThreshold = size;
    return this;
  }

  /// withBatchCountThreshold sets message count threshold for publish batch.
  /// Default 1000.
  Options withBatchCountThreshold(int count) {
    this.batchCountThreshold = count;
    return this;
  }
}
