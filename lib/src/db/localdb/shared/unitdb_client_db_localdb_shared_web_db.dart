import 'package:drift/web.dart';
import 'package:unitdb_client/src/db/localdb/unitdb_client_db_localdb_adapter.dart';

class SharedDb {
  static LocalDb localDb(String userId) {
    final dbName = 'db_$userId';
    final queryExecutor = WebDatabase(dbName, logStatements: true);
    return LocalDb(userId, queryExecutor);
  }
}
