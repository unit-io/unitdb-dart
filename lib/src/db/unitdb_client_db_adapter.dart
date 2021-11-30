import 'package:unitdb_client/unitdb_client.dart';

abstract class Adapter {
  /// Creates a new local db connection
  Future<void> connect(String userId, {bool reset = false});

  /// Closes the local db connection
  Future<void> disconnect();

  // Put message is used to store a message.
  // it returns an error if some error was encountered during storage.
  Future<void> putMessage(int connectionId, UtpMessage message);

  // Get message performs a query and attempts to fetch message for the given key
  Future<UtpMessage> getMessage(int connectionId, int key);

  // Delete message is used to delete message.
  // it returns an error if some error was encountered during delete.
  Future<void> deleteMessage(int connectionId, int key);

  // Keys performs a query and attempts to fetch all keys.
  Future<List<int>> keys();
}
