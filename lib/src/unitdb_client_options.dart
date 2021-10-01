part of unitdb_client;

/// MessageHandler is a callback type which can be set to be
/// executed upon the arrival of messages published to topics
/// to which the client is subscribed.
typedef MessageHandler = void Function(Client, Stream<Message>);

/// OnConnectionHandler is a callback that is called when connection to the server is established.
typedef OnConnectionHandler = Function(Client);

/// ConnectionLostHandler is a callback that is set to be executed
/// upon an uninteded disconnection from server.
typedef ConnectionLostHandler = Function(Client);

class Options {
  Options();

  List<Uri> servers;
  String clientID;
  bool insecureFlag;
  String username;
  Uint8List password;
  bool cleanSession;
  // tls.Config tLSConfig;
  int keepAlive;
  Duration pingTimeout;
  Duration connectTimeout;
  String storePath;
  int storeSize;
  Duration storeLogReleaseDuration;
  MessageHandler defaultMessageHandler;
  OnConnectionHandler onConnectionHandler;
  ConnectionLostHandler connectionLostHandler;
  Duration writeTimeout;
  Duration batchDuration;
  int batchByteThreshold;
  int batchCountThreshold;

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
    this.servers = this.servers ?? List<Uri>();
    this.servers.add(uri);
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
    o.insecureFlag = this.insecureFlag ?? false;
    o.username = this.username ?? "";
    o.password = this.password ?? Uint8List(0);
    o.cleanSession = this.cleanSession ?? true;
    o.keepAlive = this.keepAlive ?? 60;
    o.pingTimeout = this.pingTimeout ?? Duration(seconds: 60);
    o.connectTimeout = this.connectTimeout ?? Duration(seconds: 60);
    o.writeTimeout = this.writeTimeout ??
        Duration(seconds: 60); // 0 represents timeout disabled
    o.onConnectionHandler = this.onConnectionHandler;
    o.defaultMessageHandler = this.defaultMessageHandler;
    o.connectionLostHandler = this.connectionLostHandler;
    o.storePath = this.storePath ?? "/tmp/uniteb";
    o.storeSize = this.storeSize ?? 1 << 27;
    if (o.writeTimeout.inSeconds > 0) {
      o.storeLogReleaseDuration =
          this.storeLogReleaseDuration ?? o.writeTimeout;
    } else {
      o.storeLogReleaseDuration = this.storeLogReleaseDuration ??
          Duration(minutes: 1); // must be greater than WriteTimeout
    }
    o.batchDuration = this.batchDuration ?? Duration(milliseconds: 100);
    // publish request (containing a batch of messages) in bytes. Must be lower
    // than the gRPC limit of 4 MiB.
    o.batchByteThreshold = 4 * 1024 * 1024;
    o.batchCountThreshold = 1000;
    return o;
  }

  /// WithClientID  returns an Option which makes client connection and set ClientID
  Options withClientID(String clientID) {
    this.clientID = clientID;
    return this;
  }

  /// WithInsecure returns an Option which makes client connection
  /// with insecure flag so that client can provide topic with key prefix.
  /// Use insecure flag only for test and debug connection and not for live client.
  Options withInsecure() {
    this.insecureFlag = true;
    return this;
  }

  /// WithUserName returns an Option which makes client connection and pass UserName
  Options withUserNamePassword(String userName, Uint8List password) {
    this.username = userName;
    this.password = password;
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
    if (t > this.writeTimeout) {
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
