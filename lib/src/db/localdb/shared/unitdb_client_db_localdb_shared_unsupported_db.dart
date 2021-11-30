import 'package:unitdb_client/src/db/localdb/unitdb_client_db_localdb_adapter.dart';

class SharedDb {
  static LocalDb localDb(String userId) {
    throw UnsupportedError(
      'No implementation of the constructDatabase api provided',
    );
  }
}
