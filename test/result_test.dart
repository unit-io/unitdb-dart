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
        return null;
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

  group('ConnectResult', () {
    test('carries the return code', () {
      final r = ConnectResult()..returnCode = ConnectReturnCode.ErrNotAuthorised.index;
      expect(r.returnCode, ConnectReturnCode.ErrNotAuthorised.index);
    });
  });
}
