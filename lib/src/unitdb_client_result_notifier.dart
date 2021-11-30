part of unitdb_client;

/// MessageAndResult is a type that contains both a Message and a Result.
/// This type is passed via channels between client connection interface and
/// goroutines responsible for sending and receiving messages from server
class MessageAndResult {
  UtpMessage m;
  Result r;

  MessageAndResult(this.m, {this.r});
}

abstract class ResultNotifier {
  flowComplete();

  /// get returns if server call is complete with error result of call
  /// get blocks until server call is complete or context is done or till duration specified
  Future<bool> get(Duration waitDuration);
}

class Result implements ResultNotifier {
  String _err;
  final completer = Completer<bool>();
  void flowComplete() {
    completer.complete(null);
  }

  void setError(String err) {
    _err = err;
    flowComplete();
  }

  String error() {
    return _err;
  }

  /// get returns if server call is complete with error result of call
  /// get blocks until server call is complete or context is done or till duration specified
  Future<bool> get(Duration waitDuration) async {
    if (_err != null && _err.isNotEmpty) {
      throw _err;
    }
    if (!completer.isCompleted) {
      await Future.delayed(waitDuration);
    }
    return completer.future;
  }
}

/// ConnectResult is an extension of result containing extra fields
/// it provides information about calls to Connect()
class ConnectResult extends Result {
  int _returnCode;
  bool _sessionPresent;

  /// ReturnCode returns the acknowledgement code in the connack sent
  /// in response to a Connect()
  int get returnCode => _returnCode;

  set returnCode(int rc) {
    _returnCode = rc;
  }

  /// SessionPresent returns a bool representing the value of the
  /// session present field in the connack sent in response to a Connect()
  bool get sessionPresent => _sessionPresent;
}

/// PublishResult is an extension of result containing the extra fields
/// required to provide information about calls to Publish()
class PublishResult extends Result {
  @protected
  int messageID;
}

/// RelayResult is an extension of result containing the extra fields
/// required to provide information about calls to Relay()
class RelayResult extends Result {
  @protected
  int messageID;
  Map<String, ByteBuffer> relResult;

  /// Result returns a map of topics that were requested along with
  /// the matching return code from the server. This is either the DeliveryMode
  /// value of the relay request or an error code.
  Map<String, ByteBuffer> get result => relResult;
}

/// SubscribeResult is an extension of result containing the extra fields
/// required to provide information about calls to Subscribe()
class SubscribeResult extends Result {
  @protected
  int messageID;
  Map<String, ByteBuffer> subResult;

  /// Result returns a map of topics that were subscribed to along with
  /// the matching return code from the server. This is either the deliveryMode
  /// value of the subscription or an error code.
  Map<String, ByteBuffer> get result => subResult;
}

/// UnsubscribeResult is an extension of result containing the extra fields
/// required to provide information about calls to Unsubscribe()
class UnsubscribeResult extends Result {
  @protected
  int messageID;
}

/// DisconnectResult is an extension of result containing the extra fields
/// required to provide information about calls to Disconnect()
class DisconnectResult extends Result {}
