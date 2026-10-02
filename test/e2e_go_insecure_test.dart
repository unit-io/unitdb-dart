// End-to-end test of the insecure flag against the real unitdb server (Go):
// since v0.6.0, a server refuses a client that connects with withInsecure
// unless its config sets allow_insecure. It only runs when UNITDB_E2E_GO=1,
// and against a server source that has allow_insecure (earlier servers
// accept the flag).
@Tags(['go-server'])
import 'dart:io';

import 'package:test/test.dart';
import 'package:unitdb_client/unitdb_client.dart';

import 'support/go_server.dart';

void main() {
  final enabled = Platform.environment['UNITDB_E2E_GO'] == '1';
  final refuses = enabled && serverRefusesInsecure();
  final skip = !enabled
      ? 'set UNITDB_E2E_GO=1 to run against the Go server'
      : !refuses
          ? 'the server at ${serverDir()} predates allow_insecure (unitdb v0.6.0), '
              'and accepts the insecure flag'
          : false;
  // A server as deployed: no allow_insecure.
  final server = GoServer(allowInsecure: false);

  setUpAll(() async {
    if (refuses) await server.start();
  });
  tearDownAll(() async {
    if (refuses) await server.stop();
  });

  // Return code 0x04: the server's Unauthorized for a CONNECT (the client's
  // ConnectReturnCode names it ErrRefusedServerUnavailable).
  const unauthorized = 4;

  test('a server without allow_insecure refuses a client with withInsecure', () async {
    final clientID = await newClientID(server.grpcPort);
    Options options() => Options()
        .withAutoReconnect(false)
        .withConnectTimeout(const Duration(seconds: 5));

    final insecure = Client('127.0.0.1:${server.grpcPort}', clientID, options().withInsecure());
    final r = await insecure.connect().timeout(const Duration(seconds: 15)) as ConnectResult;
    expect(r.error(), isNotNull, reason: 'an insecure client connected');
    expect(r.returnCode, unauthorized);

    // The refusal is the server's CONNACK, not a server that did not answer.
    expect(await connackReturnCode(server.grpcPort, clientID, insecure: true), unauthorized);

    // The same client ID connects without the flag.
    final secure = Client('127.0.0.1:${server.grpcPort}', clientID, options());
    final ok = await secure.connect().timeout(const Duration(seconds: 15)) as ConnectResult;
    expect(ok.error(), isNull, reason: 'server logs:\n${server.logs}');
    expect(ok.returnCode, ConnectReturnCode.Accepted.index);
    await secure.disconnect();
  }, skip: skip);
}
