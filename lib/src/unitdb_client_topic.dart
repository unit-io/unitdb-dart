part of unitdb_client;

abstract class Topic {
  Topic(this.topic, List<dynamic> validations) {
    parseTopic();
    // run all validations
    for (final dynamic validation in validations) {
      validation(this);
    }
  }

  /// Key separator
  static const String keySeparator = '/';

  /// Topic Separator
  static const String topicSeparator = '.';

  /// Multiwildcard
  static const String multiWildcardSymbol = '...';

  /// Wildcard
  static const String wildcardSymbol = '*';

  /// Topic length
  static const int maxTopicLength = 65535;

  /// Topic depth
  static const int maxTopicDepth = 100;

  String topic;

  /// Topic parts
  List<String> topicParts;

  void parseTopic() {
    var parts = topic.split(keySeparator);
    if (parts.length > 1) {
      topic = parts[1];
    }

    topicParts = topic.split(topicSeparator);
  }

  bool get hasWildcard =>
      topic.contains(multiWildcardSymbol) || topic.contains(wildcardSymbol);

  static void validateMinLength(Topic topicInstance) {
    if (topicInstance.topic.isEmpty) {
      throw Exception(
          'unitdb_client::Topic: Topic must contain at least one character');
    }
  }

  static void validateMaxLenth(Topic topicInstance) {
    if (topicInstance.topic.length > maxTopicLength) {
      throw Exception(
          'unitdb_client::Topic: The length of topic ${topicInstance.topic.length} is longer than the max Topic length allowed $maxTopicLength');
    }
  }

  static void validateMaxDepth(Topic topicInstance) {
    if (topicInstance.topicParts.length > maxTopicDepth) {
      throw Exception(
          'unitdb_client::Topic: The depath of topic ${topicInstance.topicParts.length} is longer than the max Topic length allowed $maxTopicDepth');
    }
  }

  static void validateMultiWildcard(Topic topicInstance) {
    if (topicInstance.topic.contains(multiWildcardSymbol) &&
        !(topicInstance.topic.endsWith(multiWildcardSymbol))) {
      throw Exception(
          'unitdb_client::Topic: The topic multiwild ... can only be present at the end of a topic');
    }
  }

  static void validateTopicParts(Topic topicInstance) {
    final invalidPart = topicInstance.topicParts
        .any((String part) => part.contains(wildcardSymbol) && part.length > 1);
    if (invalidPart) {
      throw Exception(
          'unitdb_client::Topic: Topic part contains a wildcard but is more than one character long');
    }
  }
}
