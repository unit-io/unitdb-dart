import 'dart:async';
import 'dart:typed_data' hide ByteBuffer;

import 'package:test/test.dart';
import 'package:unitdb_client/unitdb_client.dart';

TopicFilter filter(String topic) =>
    TopicFilter(topic, StreamController<List<Message>>.broadcast().stream);

bool matches(String subscription, String publication) =>
    filter(subscription).matches(PublicationTopic(publication));

void main() {
  group('PublicationTopic', () {
    test('accepts a plain topic', () {
      final t = PublicationTopic('groups.private.673651407196578720.message');
      expect(t.topicParts, ['groups', 'private', '673651407196578720', 'message']);
      expect(t.hasWildcard, isFalse);
    });

    test('strips a key prefix', () {
      final t = PublicationTopic('KEY123/groups.private.message');
      expect(t.topic, 'groups.private.message');
    });

    test('rejects an empty topic', () {
      expect(() => PublicationTopic(''), throwsException);
    });

    test('rejects wildcards', () {
      expect(() => PublicationTopic('groups.*.message'), throwsException);
      expect(() => PublicationTopic('groups...'), throwsException);
    });

    test('rejects a topic longer than the maximum length', () {
      expect(() => PublicationTopic('a' * (Topic.maxTopicLength + 1)),
          throwsException);
    });

    test('rejects a topic deeper than the maximum depth', () {
      final deep = List.filled(Topic.maxTopicDepth + 1, 'a').join('.');
      expect(() => PublicationTopic(deep), throwsException);
    });

    test('keeps the whole topic after the key separator', () {
      // The topic part may itself contain '/' characters.
      final t = PublicationTopic('KEY/groups/a.b');
      expect(t.topic, 'groups/a.b');
    });
  });

  group('v2 keys', () {
    // A v2 topic key: 48 characters of base64url, '-' and '_' included, and
    // never the '/' separator nor the '.' of topics.
    final key = 'Zq-_3xK8vB2mN-p_Lw7RtY4uE9iO0aS1dF6gH5jC2kV8bX3n';
    // A v1 signed key, of 26 characters, and an unsigned one, of 13.
    const v1Key = 'AbCdEfGhIjKlMnOpQrStUvWxYz';
    const unsigned = 'AbCdEfGhIjKlM';

    test('have the length the server issues', () {
      expect(key.length, 48);
      expect(v1Key.length, 26);
    });

    test('are stripped from a publication topic', () {
      for (final k in [key, v1Key, unsigned, '-_-_', '_', '-']) {
        final t = PublicationTopic('$k/groups.private-room.my_topic');
        expect(t.topic, 'groups.private-room.my_topic', reason: k);
        expect(t.topicParts, ['groups', 'private-room', 'my_topic'], reason: k);
        expect(t.hasWildcard, isFalse, reason: k);
      }
    });

    test('are stripped from a filter, wildcards kept', () {
      expect(filter('$key/groups.*.message').topicParts, ['groups', '*', 'message']);
      expect(filter('$key/groups...').topicParts, ['groups', '...']);
      expect(filter('$key/...').topicParts, ['...']);
      expect(() => filter('$key/groups...private'), throwsException);
    });

    test('a keyed filter matches its topics, keyed or not', () {
      expect(matches('$key/groups.*.message', 'groups.a-b.message'), isTrue);
      expect(matches('$key/groups.*.message', '$key/groups.a_b.message'), isTrue);
      expect(matches('$key/groups...', 'groups.x.y'), isTrue);
      expect(matches('$key/...', 'any.topic'), isTrue);
      expect(matches('$key/groups.a', 'groups.b'), isFalse);
      expect(matches('$key/groups.a', 'groups.a'), isTrue);
    });
  });

  group('TopicFilter validation', () {
    test('accepts single and trailing multi-level wildcards', () {
      expect(() => filter('groups.*.message'), returnsNormally);
      expect(() => filter('groups.private...'), returnsNormally);
    });

    test('rejects a multi-level wildcard that is not at the end', () {
      expect(() => filter('groups...private'), throwsException);
    });

    test('rejects a part mixing a wildcard with other characters', () {
      expect(() => filter('groups.pri*.message'), throwsException);
    });
  });

  group('TopicFilter.matches', () {
    test('matches an exact topic', () {
      expect(matches('groups.private.message', 'groups.private.message'), isTrue);
    });

    test('does not match a different topic', () {
      expect(matches('groups.private.message', 'groups.public.message'), isFalse);
    });

    test('single-level wildcard matches exactly one part', () {
      expect(matches('groups.*.message', 'groups.private.message'), isTrue);
      expect(matches('groups.*.message', 'groups.private.x.message'), isFalse);
      expect(matches('groups.*', 'groups'), isFalse);
    });

    test('bare multi-level wildcard matches everything', () {
      expect(matches('...', 'groups.private.message'), isTrue);
    });

    test('bare single-level wildcard matches everything', () {
      expect(matches('*', 'groups'), isTrue);
    });

    test('trailing multi-level wildcard matches deeper topics', () {
      expect(matches('groups.private...', 'groups.private.673651407196578720.message'),
          isTrue);
      expect(matches('groups.private...', 'groups.private.x'), isTrue);
      expect(matches('groups.private...', 'groups.public.x'), isFalse);
      // "finance..." also matches "finance" itself.
      expect(matches('groups.private...', 'groups.private'), isTrue);
      expect(matches('groups.private...', 'groups'), isFalse);
    });

    test('a shorter publication does not match a longer filter', () {
      expect(matches('groups.private.message', 'groups.private'), isFalse);
    });

    test('a longer publication does not match a shorter filter', () {
      expect(matches('groups.private', 'groups.private.message'), isFalse);
    });
  });

  group('TopicFilter stream', () {
    test('forwards only matching messages', () async {
      final changes = StreamController<List<Message>>.broadcast(sync: true);
      final f = TopicFilter('groups.*.message', changes.stream);
      final got = <String>[];
      f.messageStream.listen((msgs) => got.addAll(msgs.map((m) => m.topic)));

      Message msg(String topic) => Message.messageFromPublish(
          1, PublishMessage(topic, Uint8List(0), ''), () {});
      changes.add([msg('groups.a.message'), msg('groups.b.other'), msg('groups.c.message')]);
      await Future<void>.delayed(Duration.zero);

      expect(got, ['groups.a.message', 'groups.c.message']);
    });
  });
}
