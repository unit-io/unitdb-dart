part of unitdb_client;

class PublicationTopic extends Topic {
  PublicationTopic(String topic)
      : super(topic, <dynamic>[
          Topic.validateMinLength,
          Topic.validateMaxLenth,
          Topic.validateMaxDepth,
          _validateWildcards
        ]);

  /// Validates that publication topic has no wildcards.
  static void _validateWildcards(Topic topicInstance) {
    if (topicInstance.hasWildcard) {
      throw Exception(
          'unitdb_client::PublicationTopic: Cannot publish to a topic that contains topic wildcard (* or ...)');
    }
  }
}

class TopicFilter extends Topic {
  TopicFilter(this._subscriptionTopic, this._changes)
      : super(_subscriptionTopic, <dynamic>[
          Topic.validateMinLength,
          Topic.validateMaxLenth,
          Topic.validateMaxDepth,
          Topic.validateMultiWildcard,
          Topic.validateTopicParts
        ]) {
    _changes.listen(_filter);
    _updates = StreamController<List<Message>>.broadcast(sync: true);
  }

  final String _subscriptionTopic;

  String get subscriptionTopic => _subscriptionTopic;

  final Stream<List<Message>> _changes;

  StreamController<List<Message>> _updates;

  Stream<List<Message>> get messageStream => _updates.stream;

  void _filter(List<Message> e) {
    String lastTopic;

    try {
      final msgs = <Message>[];

      for (final message in e) {
        lastTopic = message.topic;
        if (matches(PublicationTopic(message.topic))) {
          msgs.add(message);
        }
      }

      if (msgs.isNotEmpty) {
        _updates.add(msgs);
      }
    } on RangeError catch (e) {
      print(
          'TopicFilter::_topicIn - cannot process received topic: $lastTopic - exception is $e');
    }
  }

  bool matches(Topic publicationTopic) {
    // If the topic is just multi wildcard then return matches to true.
    if (topic == Topic.wildcardSymbol) {
      return true;
    }

    // If the topics are an exact match then matches to true.
    if (topic == publicationTopic.topic) {
      return true;
    }

    // no match yet so we need to check each part
    for (var i = 0; i < topicParts.length; i++) {
      final lhsPart = topicParts[i];
      // If we've reached a multi wildcard in the lhs topic,
      // we have a match.
      // (this is the rule finance matches finance or finance...)
      if (lhsPart == Topic.multiWildcardSymbol) {
        return true;
      }
      final isLhsWildcard = lhsPart == Topic.wildcardSymbol;
      // If we've reached a wildcard match but the matchee does
      // not have anything at this part level then it's not a match.
      // (this is the rule 'finance does not match finance.*'
      if (isLhsWildcard && publicationTopic.topicParts.length <= i) {
        return false;
      }
      // if lhs is not a wildcard we need to check whether the
      // two parts match each other.
      if (!isLhsWildcard) {
        final rhsPart = publicationTopic.topicParts[i];
        // If the lhs part is not wildcard then we need an exact match
        if (lhsPart != rhsPart) {
          return false;
        }
      }
      // If we're at the last part of the lhs topic but there are
      // more patrs in the in the publicationTopic then the publicationTopic
      // is too specific to be a match.
      if (i + 1 == topicParts.length &&
          publicationTopic.topicParts.length > topicParts.length) {
        return false;
      }
      // If we're here the current part matches so check the next
    }
    // If we exit out of the loop without a return then we have a full match which would
    // have been caught by the original exact match check at the top anyway.
    return true;
  }
}
