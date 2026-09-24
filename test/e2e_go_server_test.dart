// End-to-end test of the client against the real unitdb server (Go), built
// from source. It needs a Go toolchain and the server source, so it only runs
// when UNITDB_E2E_GO=1. UNITDB_SERVER_DIR points at the server's main package
// (default: ../unitdb/server next to this repository).
@Tags(['go-server'])
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' hide ByteBuffer;

import 'package:test/test.dart';
import 'package:unitdb_client/unitdb_client.dart';

const clientID = 'UCBFDONCNJLaKMCAIeJBaOVfbAXUZHNPLDKKLDKLHZHKYIZLCDPQ';
const serverKey = '4BWm1vZletvrCDGWsF6mex8oBSd59m6I';

Future<int> freePort() async {
  final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = s.port;
  await s.close();
  return port;
}

class GoServer {
  Process process;
  int grpcPort;
  Directory dir;
  final logs = StringBuffer();

  Future<void> start() async {
    final src = Platform.environment['UNITDB_SERVER_DIR'] ??
        '${Directory.current.parent.path}/unitdb/server';
    dir = await Directory.systemTemp.createTemp('unitdb-dart-e2e');
    final bin = '${dir.path}/unitdb-server';
    final build = await Process.run('go', ['build', '-o', bin, '.'], workingDirectory: src);
    if (build.exitCode != 0) {
      throw StateError('go build failed in $src:\n${build.stderr}');
    }
    grpcPort = await freePort();
    final tcpPort = await freePort();
    await File('${dir.path}/e2e.conf').writeAsString(jsonEncode({
      'listen': '127.0.0.1:$tcpPort',
      'grpc_listen': '127.0.0.1:$grpcPort',
      'logging_level': 'Error',
      'encryption_config': {'key': serverKey, 'identifier': 'local', 'sealed': false},
      'cluster_config': {'self': ''},
      'store_config': {
        'reset': false,
        'adapters': {
          'unitdb': {'database': 'unitdb', 'mem_size': 500000000}
        }
      },
    }));
    process = await Process.start(bin, ['-config', 'e2e.conf', '-db_path', '${dir.path}/db']);
    process.stdout.transform(utf8.decoder).listen(logs.write);
    process.stderr.transform(utf8.decoder).listen(logs.write);
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    while (true) {
      try {
        final s = await Socket.connect(InternetAddress.loopbackIPv4, grpcPort);
        s.destroy();
        return;
      } on SocketException {
        if (DateTime.now().isAfter(deadline)) {
          throw StateError('server did not start:\n$logs');
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  Future<void> stop() async {
    process?.kill(ProcessSignal.sigkill);
    await process?.exitCode;
    await dir?.delete(recursive: true);
  }
}

void main() {
  final enabled = Platform.environment['UNITDB_E2E_GO'] == '1';
  final server = GoServer();

  setUpAll(() async {
    if (enabled) await server.start();
  });
  tearDownAll(() async {
    if (enabled) await server.stop();
  });

  test('connects, subscribes, publishes and receives through the Go server', () async {
    Client client() => Client('127.0.0.1:${server.grpcPort}', clientID,
        Options().withInsecure().withConnectTimeout(const Duration(seconds: 5)));

    final sub = client();
    final got = <String>[];
    ConnectResult r;
    try {
      r = await sub.connect().timeout(const Duration(seconds: 15)) as ConnectResult;
    } catch (e) {
      fail('connect to the Go server failed: $e\nserver logs:\n${server.logs}');
    }
    expect(r.error(), isNull, reason: 'server logs:\n${server.logs}');
    expect(r.returnCode, ConnectReturnCode.Accepted.index);

    sub.messageStream.listen((ms) => got.addAll(ms.map((m) => utf8.decode(m.payload))));
    await sub.subscribe('groups.private.dart.message').completer.future
        .timeout(const Duration(seconds: 5));

    final pub = client();
    await pub.connect().timeout(const Duration(seconds: 15));
    await pub
        .publish('groups.private.dart.message', Uint8List.fromList(utf8.encode('hi')))
        .completer
        .future
        .timeout(const Duration(seconds: 5));

    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (got.isEmpty && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    expect(got, ['hi']);
  }, skip: enabled ? false : 'set UNITDB_E2E_GO=1 to run against the Go server');
}
