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

import 'support/go_server.dart';

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
    final clientID = await newClientID(server.grpcPort);
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
