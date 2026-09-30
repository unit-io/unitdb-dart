part of unitdb_web_client;

class WebsocketConnectionHandler {
  WebSocket? _serverConn;

  StreamQueue<MessageEvent>? inPacket;

  /// InMsg is the type to use for reading request data from the streaming
  /// endpoint. This must be a non-nil allocated value and must NOT point to
  /// the same value as OutMsg since they may be used concurrently.
  ///
  /// The Reset method will be called on InMsg during Reads so data you
  /// set initially will be lost. Set by newConnection.
  late ByteBuffer inMsg;

  /// readOffset tracks where we've read up to if we're reading a result
  /// that didn't fully fit into the target slice. See Read.
  int readOffset = 0;

  Future<bool> newConnection(Uri uri, Duration timeout,
      {String authority = ""}) {
    var r = ConnectResult();
    this.readOffset = 0;
    this.inMsg = ByteBuffer(typed.Uint8Buffer());

    print(uri.toString());
    final serverConn = WebSocket(uri.toString());
    this._serverConn = serverConn;
    serverConn.binaryType = 'arraybuffer';
    // Set before any of the socket's events, which cancel them, arrive.
    late StreamSubscription closeEvents;
    late StreamSubscription errorEvents;
    serverConn.onOpen.listen((e) {
      closeEvents.cancel();
      errorEvents.cancel();
      _startListening(serverConn);
      return r.completer.complete(true);
    });

    closeEvents = serverConn.onClose.listen((e) {
      print('WebsocketConnectionHandler::newConnection - websocket is closed');
      closeEvents.cancel();
      errorEvents.cancel();
      return r.completer.completeError(
          'WebsocketConnectionHandler::newConnection - websocket is closed');
    });

    errorEvents = serverConn.onError.listen((e) {
      print(
          'WebsocketConnectionHandler::newConnection - websocket has erred $e');
      closeEvents.cancel();
      errorEvents.cancel();
      return r.completer.completeError(
          'WebsocketConnectionHandler::newConnection - websocket has erred $e');
    });

    print(
        'WebsocketConnectionHandler::newConnection - connection is waiting ${uri.toString()}');
    return r.completer.future;
  }

  Future<bool> hasNext() {
    final nextCompleter = Completer<bool>();
    _packets('hasNext').hasNext
        .then((value) => nextCompleter.complete(value))
        .catchError((e) {
      final message =
          'GrpcConnectionHandler::read - error occured ${e.toString()}';
      print(message);
      nextCompleter.completeError(message);
    });

    return nextCompleter.future;
  }

  Future<bool> next(Duration timeout) async {
    final nextCompleter = Completer<bool>();
    // A timeout fails the read.
    await _packets('next').next.timeout(timeout).then((message) {
      inMsg.writeList(Uint8List.view(message.data));
      nextCompleter.complete(true);
    }).catchError((e) {
      final error =
          'WebsocketConnectionHandler::read - error occured ${e.toString()}';
      print(error);
      nextCompleter.completeError(error);
    });

    return nextCompleter.future;
  }

  /// _packets returns the incoming packets; there are none once closed.
  StreamQueue<MessageEvent> _packets(String caller) {
    final packets = inPacket;
    if (packets == null) {
      throw NoConnectionException(
          'WebsocketConnectionHandler::$caller - closed');
    }
    return packets;
  }

  /// read implements stream reader.
  Future<typed.Uint8Buffer> read(int length) async {
    // Attempt to read a value only if we're not still decoding a
    // partial read value from the last result.
    // write to slice
    var p = inMsg.getRange(readOffset, readOffset + length);
    // If we have an error or we've read the full amount then we're done.
    // The error case is obvious. The case where we've read the full amount
    // is also a terminating condition and err == nil (we know this since its
    // checking that case) so we return the full amount and no error.
    if (inMsg.length <= p.length + readOffset) {
      // Reset the read offset since we're done.
      readOffset = 0;

      // Reset our response value for the next read and so that we
      // don't potentially store a large response structure in memory.
      inMsg.shrink();

      return p;
    }

    // We didn't read the full amount so we need to store this for future reads
    readOffset += p.length;

    return p;
  }

  /// write implements stream write.
  Future<int> write(ByteBuffer p) async {
    var total = p.length;
    do {
      // Write our data into the request. Any error means we abort.
      var data = ByteData.view(p.read(p.length).buffer);
      _serverConn?.sendTypedData(data);
      // We sent partial data so we continue writing the remainder
    } while (total == p.availableBytes);

    // If we sent the full amount of data, we're done. We respond with
    // "total" in case we sent across multiple frames.
    return total;
  }

  /// shrink the inMsg ByteBuffer.
  void shrink() {
    inMsg.shrink();
    readOffset = 0;
  }

  /// close will close the client if this is a client. If this is a server
  /// stream this does nothing since gRPC expects you to close the stream by
  /// returning from the RPC call.
  ///
  /// This calls CloseSend underneath for clients, so read the documentation
  /// for that to understand the semantics of this call.
  void close() {
    final serverConn = _serverConn;
    if (serverConn != null) {
      serverConn.close();
      _serverConn = null;
      inPacket?.cancel();
      inPacket = null;
    }
  }

  void _startListening(WebSocket serverConn) {
    print('startlistening');
    this.inPacket = StreamQueue<MessageEvent>(serverConn.onMessage);
    serverConn.onClose.listen((e) {
      print('WebsocketConnectionHandler::newConnection - onClose ${e.reason}');
      close();
    });
    serverConn.onError.listen((e) {
      print(
          'WebsocketConnectionHandler::newConnection - onError ${e.toString()}');
      close();
    });
  }
}
