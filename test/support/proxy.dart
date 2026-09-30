// A TCP proxy between a client and a server, for tests that cut or stall a
// connection while the server stays up.

import 'dart:async';
import 'dart:io';

class Proxy {
  Proxy(this.target);

  /// target is the port the proxy forwards to, on the loopback address.
  final int target;
  int port;
  ServerSocket _listener;
  final _pairs = <List<Socket>>[];

  /// While hold is set, what the server sends is held back, not forwarded,
  /// and lost when the connection is cut.
  bool hold = false;

  Future<void> start() async {
    _listener = await ServerSocket.bind(InternetAddress.loopbackIPv4, port ?? 0);
    port = _listener.port;
    _listener.listen((client) async {
      Socket server;
      try {
        server = await Socket.connect(InternetAddress.loopbackIPv4, target);
      } on SocketException {
        client.destroy();
        return;
      }
      final pair = [client, server];
      _pairs.add(pair);
      client.listen(server.add,
          onDone: () => server.destroy(), onError: (_) => server.destroy());
      server.listen((data) {
        if (!hold) client.add(data);
      }, onDone: () => client.destroy(), onError: (_) => client.destroy());
    });
  }

  /// cut closes the connections, and stops taking new ones until start is
  /// called again, on the same port.
  Future<void> cut() async {
    await _listener?.close();
    _listener = null;
    for (final pair in _pairs) {
      for (final s in pair) {
        s.destroy();
      }
    }
    _pairs.clear();
    hold = false;
  }

  Future<void> stop() => cut();
}
