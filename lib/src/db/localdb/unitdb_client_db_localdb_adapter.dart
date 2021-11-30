import 'package:drift/drift.dart';
import 'package:unitdb_client/src/db/localdb/query/unitdb_client_db_localdb_query.dart';
import 'package:unitdb_client/src/db/localdb/command/unitdb_client_db_localdb_command.dart';
import 'package:unitdb_client/src/db/localdb/unitdb_client_db_localdb.dart';

part 'unitdb_client_db_localdb_adapter.g.dart';

/// A local database implemeted using drift
@DriftDatabase(tables: [Messages], daos: [MessageQuery, MessageCommand])
class LocalDb extends _$LocalDb {
  /// Create a new local database instance
  LocalDb(this._userId, QueryExecutor executor) : super(executor);

  /// Instantiate a new database instance
  LocalDb.connect(this._userId, DatabaseConnection connection)
      : super(connection.executor);

  final String _userId;

  String get userId => _userId;

  @override
  int get schemaVersion => 1;

  /// Delete all tables
  Future<void> reset() => batch((batch) {
        allTables.forEach((table) {
          delete(table).go();
        });
      });

  /// Close the database instance
  Future<void> disconnect() => close();
}
