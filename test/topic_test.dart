import 'dart:async';

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
          1, PublishMessage(topic, null, ''), () {});
      changes.add([msg('groups.a.message'), msg('groups.b.other'), msg('groups.c.message')]);
      await Future<void>.delayed(Duration.zero);

      expect(got, ['groups.a.message', 'groups.c.message']);
    });
  });
}
