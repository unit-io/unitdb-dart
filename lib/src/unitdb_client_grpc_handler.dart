part of unitdb_client;

class GrpcConnectionHandler {
  ClientChannel _channel;
  UnitdbClient _serverConn;

  ResponseStream<pbx.Packet> stream;
  StreamQueue<pbx.Packet> inPacket;
  final outPacket = StreamController<pbx.Packet>();

  /// readOffset tracks where we've read up to if we're reading a result
  /// that didn't fully fit into the target slice. See Read.
  int readOffset;

  Future<bool> newConnection(Uri uri, Duration timeout) {
    var r = ConnectResult();
    this.readOffset = 0;
    this._channel = ClientChannel(uri.host,
        port: uri.port,
        options:
            const ChannelOptions(credentials: ChannelCredentials.insecure()));
    this._serverConn = UnitdbClient(this._channel);
    this.stream = _serverConn.stream(outPacket.stream);
    this.inPacket = StreamQueue<pbx.Packet>(this.stream);
    r.completer.complete(null);
    return r.completer.future;
  }

  /// InMsg is the type to use for reading request data from the streaming
  /// endpoint. This must be a non-nil allocated value and must NOT point to
  /// the same value as OutMsg since they may be used concurrently.
  ///
  /// The Reset method will be called on InMsg during Reads so data you
  /// set initially will be lost.
  final inMsg = ByteBuffer(typed.Uint8Buffer());

  Future<bool> _hasNext() {
    return inPacket.hasNext;
  }

  Future<void> _next() {
    inPacket.next.then((inMsg) => this.inMsg.writeList(inMsg.data));
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
      inMsg.reset();

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
      final packet = pbx.Packet();
      packet.data = p.read(p.length);
      outPacket.sink.add(packet);

      // We sent partial data so we continue writing the remainder
    } while (total == p.availableBytes);

    // If we sent the full amount of data, we're done. We respond with
    // "total" in case we sent across multiple frames.
    return total;
  }

  /// shrink the inMsg ByteBuffer.
  void _shrink() {
    inMsg.removeRange(0, readOffset);
    readOffset = 0;
  }

  /// close will close the client if this is a client. If this is a server
  /// stream this does nothing since gRPC expects you to close the stream by
  /// returning from the RPC call.
  ///
  /// This calls CloseSend underneath for clients, so read the documentation
  /// for that to understand the semantics of this call.
  void close() {
    if (_serverConn != null) {
      inPacket.cancel();
      outPacket.close();
      _channel.shutdown();
      _serverConn = null;
    }
  }
}
