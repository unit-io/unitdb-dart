part of unitdb_client;

/// Message identifier handling
class MessageIdentifiers {
  /// Constructor
  factory MessageIdentifiers() => _singleton;
  MessageIdentifiers._internal();
  static final MessageIdentifiers _singleton = MessageIdentifiers._internal();

  int _mid;

  /// Mid
  int get mid => _mid;

  Map<int, Result> index = new Map(); // map[MID]Result

  void cleanUp() {
    index.forEach((mId, result) {
      switch (result.runtimeType) {
        case PublishResult:
          result.setError("connection lost before Publish completed");
          break;
        case SubscribeResult:
          result.setError("connection lost before Subscribe completed");
          break;
        case UnsubscribeResult:
          result.setError("connection lost before Unsubscribe completed");
          break;
      }
    });
  }

  /// Resets the Mid
  reset() {
    _mid = 0;
  }

  /// Frees the Mid
  freeID(int id) {
    index.remove(id);
  }

  /// Gets next message identifier
  int nextID(Result r) {
    _mid++;
    index[_mid] = r;
    return _mid;
  }

  /// Gets type for Mid
  Result getType(int id) {
    return index[id];
  }
}
