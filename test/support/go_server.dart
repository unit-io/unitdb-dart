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

/// connackReturnCode sends the server a CONNECT, and returns the return code
/// of the CONNACK it answers with.
Future<int> connackReturnCode(int grpcPort, String clientID,
    {bool insecure = false}) async {
  final channel = ClientChannel('127.0.0.1',
      port: grpcPort,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()));
  final out = StreamController<pbx.Packet>();
  try {
    final connect = pbx.Connect()
      ..keepAlive = 30
      ..clientID = clientID
      ..insecureFlag = insecure;
    out.add(pbx.Packet()
      ..data = Frame.encode(
          pbx.MessageType.CONNECT, pbx.FlowControl.NONE, connect.writeToBuffer()));
    final replies = pbgrpc.UnitdbClient(channel).stream(out.stream);
    await for (final packet in replies.timeout(const Duration(seconds: 10))) {
      final f = Frame.parse(packet.data);
      if (f.type == pbx.MessageType.CONNECT &&
          f.flow == pbx.FlowControl.ACKNOWLEDGE) {
        return pbx.ConnectAcknowledge.fromBuffer(f.body).returnCode;
      }
    }
    throw StateError('the server sent no CONNACK');
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

/// serverDir is the server's main package: UNITDB_SERVER_DIR, or
/// ../unitdb/server next to this repository.
String serverDir() =>
    Platform.environment['UNITDB_SERVER_DIR'] ??
    '${Directory.current.parent.path}/unitdb/server';

/// serverRefusesInsecure tells whether the server source is unitdb v0.6.0 or
/// later, which refuses a CONNECT's insecure flag unless its config sets
/// allow_insecure. Earlier servers accept the flag, and ignore the setting.
bool serverRefusesInsecure() {
  final config = File('${serverDir()}/internal/config/config.go');
  return config.existsSync() &&
      config.readAsStringSync().contains('"allow_insecure"');
}

class GoServer {
  /// allowInsecure sets the server's allow_insecure, so that it accepts
  /// clients that connect with the insecure flag (withInsecure), as the
  /// tests' clients do. Without it, unitdb v0.6.0 and later refuse them.
  GoServer({this.allowInsecure = true, this.config = const {}});

  final bool allowInsecure;

  /// config holds settings added to the server's config, such as
  /// `client_id_ttl`.
  final Map<String, Object?> config;
  Process? process;
  // grpcPort, tcpPort and dir are set with bin, by the first start.
  late int grpcPort;
  late int tcpPort;
  late Directory dir;
  String? bin;
  final logs = StringBuffer();

  /// start builds the server, once, and starts it on free ports.
  Future<void> start() async {
    var bin = this.bin;
    if (bin == null) {
      final src = serverDir();
      dir = await Directory.systemTemp.createTemp('unitdb-dart-e2e');
      bin = this.bin = '${dir.path}/unitdb-server';
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
        // Honored standalone only, as here; servers before v0.6.0 ignore it.
        'allow_insecure': allowInsecure,
        'cluster_config': {'self': ''},
        'store_config': {
          'reset': false,
          'adapters': {
            'unitdb': {'database': 'unitdb', 'mem_size': 500000000}
          }
        },
        ...config,
      }));
    }
    final process = this.process =
        await Process.start(bin, ['-config', 'e2e.conf', '-db_path', '${dir.path}/db']);
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
    if (bin != null) {
      await dir.delete(recursive: true);
    }
  }
}


/// MintedID is a client ID minted by the server's cmd/mintid.
class MintedID {
  MintedID(this.clientID, this.contract, this.uuid);
  final String clientID;
  final int contract;

  /// The ID's uuid, in decimal; "0" for a v1 ID.
  final String uuid;
}

String? _mintidBin;

/// mintid runs the server's cmd/mintid, built once, with args and the
/// server's config, for its key, and returns the client ID it minted. The
/// server must have started, which writes its config.
Future<MintedID> mintid(GoServer server, List<String> args) async {
  var bin = _mintidBin;
  if (bin == null) {
    final dir = await Directory.systemTemp.createTemp('unitdb-dart-mintid');
    bin = '${dir.path}/mintid';
    final build = await Process.run('go', ['build', '-o', bin, './cmd/mintid'],
        workingDirectory: serverDir());
    if (build.exitCode != 0) {
      throw StateError('go build ./cmd/mintid failed in ${serverDir()}:\n${build.stderr}');
    }
    _mintidBin = bin;
  }
  final run = await Process.run(bin, ['-config', '${server.dir.path}/e2e.conf', ...args]);
  if (run.exitCode != 0) {
    throw StateError('mintid $args: ${run.stderr}');
  }
  final fields = <String, String>{};
  for (final line in LineSplitter.split(run.stdout as String)) {
    final i = line.indexOf(':');
    if (i > 0) fields[line.substring(0, i).trim()] = line.substring(i + 1).trim();
  }
  final id = fields['client id'];
  if (id == null) {
    throw StateError('mintid printed no client id:\n${run.stdout}');
  }
  return MintedID(id, int.parse(fields['contract'] ?? '0'), fields['uuid'] ?? '0');
}

/// serverHasSecurityStage2 tells whether the server source issues v2 client
/// IDs and keys, renews client IDs and takes unitdb/revoke and
/// unitdb/service requests, as unitdb's security stage 2 does.
bool serverHasSecurityStage2() =>
    File('${serverDir()}/internal/revocation.go').existsSync() &&
    File('${serverDir()}/cmd/mintid/main.go').existsSync();
