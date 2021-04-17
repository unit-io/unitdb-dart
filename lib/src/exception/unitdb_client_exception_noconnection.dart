part of unitdb_client;

class NoConnectionException implements Exception {
  NoConnectionException(String txt) {
    _message = 'unitdb_client::NoConnectionException:$txt';
  }

  String _message;

  @override
  String toString() => _message;
}
