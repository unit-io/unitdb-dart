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

  Map<int, Result> _messageIds = Map();

  void _cleanUp() {
    _messageIds.forEach((mId, result) {
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
      print(
          'messageIds::cleanUp - messageId: $mId messageType: ${result.runtimeType}');
      result.flowComplete();
    });
    _messageIds = Map();
  }

  /// Resets the Mid
  _reset() {
    _mid = 0;
  }

  /// Frees the Mid
  _freeID(int id) {
    _messageIds.remove(id);
  }

  _resumeID(int id, Result r) {
    _messageIds[_mid] = r;
  }

  /// Gets next message identifier
  int _nextID(Result r) {
    _mid++;
    if (_messageIds.containsKey(_mid)) {
      _nextID(r);
    }
    _messageIds[_mid] = r;
    return _mid;
  }

  /// Gets type for Mid
  Result _getType(int id) {
    return _messageIds[id];
  }
}
