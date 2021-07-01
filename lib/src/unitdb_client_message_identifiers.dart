part of unitdb_client;

/// Message identifier handling
class _MessageIdentifiers {
  /// Constructor
  factory _MessageIdentifiers() => _singleton;
  _MessageIdentifiers._internal();
  static final _MessageIdentifiers _singleton = _MessageIdentifiers._internal();

  int _mid;

  /// Mid
  int get mid => _mid;

  Map<int, Result> index = new Map(); // map[MID]Result

  void _cleanUp() {
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
  _reset() {
    _mid = 0;
  }

  /// Frees the Mid
  _freeID(int id) {
    index.remove(id);
  }

  /// Gets next message identifier
  int _nextID(Result r) {
    _mid++;
    index[_mid] = r;
    return _mid;
  }

  /// Gets type for Mid
  Result _getType(int id) {
    return index[id];
  }
}
