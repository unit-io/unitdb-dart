part of unitdb_client;

class InvalidHaderException implements Exception {
  InvalidHaderException(String txt) {
    _message = 'unitdb_client::InvalidHeaderException:$txt';
  }

  String _message;

  @override
  String toString() => _message;
}
