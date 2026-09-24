import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:unitdb_client/unitdb_client.dart';

void main() {
  group('Options.withDefaultOptions', () {
    test('fills documented defaults', () {
      final o = Options().withDefaultOptions();
      expect(o.authority, '');
      expect(o.persistenceStore, PersistenceStore.None);
      expect(o.insecureFlag, isFalse);
      expect(o.username, '');
      expect(o.password, isEmpty);
      expect(o.cleanSession, isFalse);
      expect(o.keepAlive, 60);
      expect(o.pingTimeout, const Duration(seconds: 60));
      expect(o.connectTimeout, const Duration(seconds: 60));
      expect(o.maxReconnectDuration, const Duration(minutes: 10));
      expect(o.autoReconnect, isTrue);
      expect(o.connectRetry, isFalse);
      expect(o.writeTimeout, const Duration(seconds: 60));
      expect(o.storeLogReleaseDuration, o.writeTimeout);
      expect(o.batchDuration, const Duration(milliseconds: 100));
      expect(o.batchByteThreshold, 4 * 1024 * 1024);
      expect(o.batchCountThreshold, 1000);
    });

    test('keeps values set by the builder methods', () {
      final o = Options()
          .withAuthority('host.example')
          .withInsecure()
          .withCleanSession()
          .withKeepAlive(15)
          .withPingTimeout(const Duration(seconds: 3))
          .withConnectTimeout(const Duration(seconds: 4))
          .withWriteTimeout(const Duration(seconds: 5))
          .withAutoReconnect(false)
          .withConnectRetry(true)
          .withMaxReconnectDuration(const Duration(seconds: 6))
          .withMaxConnectRetryDuration(const Duration(seconds: 7))
          .withBatchDuration(const Duration(milliseconds: 250))
          .withSessionData('data')
          .withPersistenceStore(PersistenceStore.Memory)
          .withDefaultOptions();
      expect(o.authority, 'host.example');
      expect(o.insecureFlag, isTrue);
      expect(o.cleanSession, isTrue);
      expect(o.keepAlive, 15);
      expect(o.pingTimeout, const Duration(seconds: 3));
      expect(o.connectTimeout, const Duration(seconds: 4));
      expect(o.writeTimeout, const Duration(seconds: 5));
      expect(o.autoReconnect, isFalse);
      expect(o.connectRetry, isTrue);
      expect(o.maxReconnectDuration, const Duration(seconds: 6));
      expect(o.maxConnectRetryDuration, const Duration(seconds: 7));
      expect(o.batchDuration, const Duration(milliseconds: 250));
      expect(o.sessionData, 'data');
      expect(o.persistenceStore, PersistenceStore.Memory);
    });

    test('keeps user and password', () {
      final pw = Uint8List.fromList([1, 2, 3]);
      final o = Options().withUserNamePassword('alice', pw).withDefaultOptions();
      expect(o.username, 'alice');
      expect(o.password, pw);
    });

    test('keeps batch thresholds set by the builder methods', () {
      final o = Options()
          .withBatchByteThreshold(1024)
          .withBatchCountThreshold(10)
          .withDefaultOptions();
      expect(o.batchByteThreshold, 1024);
      expect(o.batchCountThreshold, 10);
    });
  });

  group('Options.withStoreLogReleaseDuration', () {
    test('accepts a duration longer than the write timeout', () {
      final o = Options()
          .withWriteTimeout(const Duration(seconds: 1))
          .withStoreLogReleaseDuration(const Duration(seconds: 5));
      expect(o.storeLogReleaseDuration, const Duration(seconds: 5));
    });

    test('ignores a duration shorter than the write timeout', () {
      final o = Options()
          .withWriteTimeout(const Duration(seconds: 10))
          .withStoreLogReleaseDuration(const Duration(seconds: 5));
      expect(o.storeLogReleaseDuration, isNull);
    });

    test('can be called before a write timeout is set', () {
      expect(
          () => Options()
              .withStoreLogReleaseDuration(const Duration(minutes: 2)),
          returnsNormally);
    });
  });

  group('Options.addServer', () {
    Uri server(String target) => (Options()..addServer(target)).servers.single;

    test('defaults the scheme to grpc', () {
      final uri = server('localhost:6080');
      expect(uri.scheme, 'grpc');
      expect(uri.host, 'localhost');
      expect(uri.port, 6080);
    });

    test('expands a bare port to localhost', () {
      final uri = server(':6080');
      expect(uri.host, '127.0.0.1');
      expect(uri.port, 6080);
    });

    test('keeps an explicit scheme', () {
      expect(server('ws://example.com:80').scheme, 'ws');
    });

    test('keeps user info', () {
      expect(server('grpc://user:pw@localhost:6080').userInfo, 'user:pw');
    });

    test('appends several servers in order', () {
      final o = Options()
        ..addServer(':1')
        ..addServer(':2');
      expect(o.servers.map((u) => u.port), [1, 2]);
    });
  });
}
