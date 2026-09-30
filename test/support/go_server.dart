// The unitdb server (Go), built from source and run for the end-to-end tests.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:grpc/grpc.dart' show ChannelCredentials, ChannelOptions, ClientChannel;
import 'package:unitdb_client/src/v1/unitdb/schema.pb.dart' as pbx;
import 'package:unitdb_client/src/v1/unitdb/schema.pbgrpc.dart' as pbgrpc;

import 'mock_server.dart' show Frame;

// The server refuses to start without a key of its own, and client IDs are
// signed with it: the tests ask the server for theirs (newClientID).
const serverKey = 'test-only-key-do-not-use-0000000';

/// newClientID asks the server for a new primary client ID: it assigns one
/// to a CONNECT without an ID, and sends it on unitdb/clientid/.
Future<String> newClientID(int grpcPort) async {
  final channel = ClientChannel('127.0.0.1',
      port: grpcPort,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()));
  final out = StreamController<pbx.Packet>();
  try {
    final connect = pbx.Connect()..keepAlive = 30;
    out.add(pbx.Packet()
      ..data = Frame.encode(
          pbx.MessageType.CONNECT, pbx.FlowControl.NONE, connect.writeToBuffer()));
    final replies = pbgrpc.UnitdbClient(channel).stream(out.stream);
    await for (final packet in replies.timeout(const Duration(seconds: 10))) {
      final f = Frame.parse(packet.data);
      if (f.type != pbx.MessageType.PUBLISH) continue;
      for (final m in pbx.Publish.fromBuffer(f.body).messages) {
        if (m.topic.startsWith('unitdb/clientid/')) {
          return utf8.decode(m.payload);
        }
      }
    }
    throw StateError('the server did not assign a client ID');
  } finally {
    await out.close();
    await channel.shutdown();
  }
}

Future<int> freePort() async {
  final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = s.port;
  await s.close();
  return port;
}

class GoServer {
  Process process;
  int grpcPort;
  int tcpPort;
  Directory dir;
  String bin;
  final logs = StringBuffer();

  /// start builds the server, once, and starts it on free ports.
  Future<void> start() async {
    if (bin == null) {
      final src = Platform.environment['UNITDB_SERVER_DIR'] ??
          '${Directory.current.parent.path}/unitdb/server';
      dir = await Directory.systemTemp.createTemp('unitdb-dart-e2e');
      bin = '${dir.path}/unitdb-server';
      final build =
          await Process.run('go', ['build', '-o', bin, '.'], workingDirectory: src);
      if (build.exitCode != 0) {
        throw StateError('go build failed in $src:\n${build.stderr}');
      }
      grpcPort = await freePort();
      tcpPort = await freePort();
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
    }
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

  /// kill stops the server at once, keeping its ports and store for a
  /// restart.
  Future<void> kill() async {
    process?.kill(ProcessSignal.sigkill);
    await process?.exitCode;
    process = null;
  }

  Future<void> stop() async {
    await kill();
    await dir?.delete(recursive: true);
  }
}

