import 'dart:async';

import 'package:test/test.dart';
import 'package:unitdb_client/unitdb_client.dart';

void main() {
  group('Result', () {
    test('reports an error', () {
      final r = Result()..setError('boom');
      expect(r.error(), 'boom');
      expect(r.completer.isCompleted, isTrue);
    });

    test('get throws when the result has an error', () {
      final r = Result()..setError('boom');
      expect(r.get(const Duration(milliseconds: 10)), throwsA(anything));
    });

    test('get returns promptly for a completed result', () async {
      final r = Result()..flowComplete();
      final sw = Stopwatch()..start();
      await r.get(const Duration(seconds: 5));
      expect(sw.elapsed, lessThan(const Duration(seconds: 1)));
    });

    test('get returns as soon as the result completes', () async {
      final r = Result();
      Timer(const Duration(milliseconds: 50), r.flowComplete);
      final sw = Stopwatch()..start();
      await r.get(const Duration(seconds: 5));
      expect(sw.elapsed, lessThan(const Duration(seconds: 1)),
          reason: 'get should not wait out the whole duration');
    });

    test('get stops waiting when the duration passes', () async {
      final r = Result();
      var hung = false;
      final got = await r
          .get(const Duration(milliseconds: 100))
          .timeout(const Duration(seconds: 2), onTimeout: () {
        hung = true;
        return false;
      });
      expect(hung, isFalse,
          reason: 'get(100ms) was still waiting after 2s for a result that never completes');
      expect(got, isNot(true), reason: 'an incomplete result is not a success');
    });

    test('an error after completion does not throw', () {
      final r = Result()..flowComplete();
      expect(() => r.setError('late'), returnsNormally);
    });

    test('completion after an error does not throw', () {
      // The connection's clean-up does exactly this for pending results.
      final r = Result()..setError('lost');
      expect(r.flowComplete, returnsNormally);
    });
  });

  group('ConnectReturnCode', () {
    test('indexes are the codes the server sends (docs/utp.md)', () {
      expect(ConnectReturnCode.values.map((c) => c.index), List.generate(11, (i) => i));
      expect(ConnectReturnCode.Accepted.index, 0x00);
      expect(ConnectReturnCode.ErrRefusedBadProtocolVersion.index, 0x01);
      expect(ConnectReturnCode.ErrRefusedIDRejected.index, 0x02);
      expect(ConnectReturnCode.ErrRefusedBadID.index, 0x03);
      expect(ConnectReturnCode.ErrNotAuthorized.index, 0x04);
      expect(ConnectReturnCode.ErrServerError.index, 0x05);
      expect(ConnectReturnCode.ErrBadToken.index, 0x06);
      expect(ConnectReturnCode.ErrForbidden.index, 0x07);
      expect(ConnectReturnCode.ErrSessionInUse.index, 0x08);
      expect(ConnectReturnCode.ErrUnknownEpoch.index, 0x09);
    });

    test("the client's no-answer code is past the server's", () {
      expect(ConnectReturnCode.ErrServerUnavailable.index, 10);
      expect(ConnectReturnCode.ErrServerUnavailable,
          isNot(ConnectReturnCode.ErrNotAuthorized));
    });

    test('the renamed names are kept as deprecated aliases, by code', () {
      // ignore: deprecated_member_use_from_same_package
      expect(ConnectReturnCode.ErrRefusedServerUnavailable, ConnectReturnCode.ErrNotAuthorized);
      // ignore: deprecated_member_use_from_same_package
      expect(ConnectReturnCode.ErrNotAuthorised, ConnectReturnCode.ErrServerError);
      // ignore: deprecated_member_use_from_same_package
      expect(ConnectReturnCode.ErrBadRequest, ConnectReturnCode.ErrBadToken);
    });

    test('fromCode', () {
      expect(ConnectReturnCode.fromCode(4), ConnectReturnCode.ErrNotAuthorized);
      expect(ConnectReturnCode.fromCode(null), isNull);
      expect(ConnectReturnCode.fromCode(-1), isNull);
      expect(ConnectReturnCode.fromCode(0x17), isNull);
    });
  });

  group('ConnectResult', () {
    test('carries the return code', () {
      final r = ConnectResult()..returnCode = ConnectReturnCode.ErrNotAuthorized.index;
      expect(r.returnCode, ConnectReturnCode.ErrNotAuthorized.index);
    });
  });
}
