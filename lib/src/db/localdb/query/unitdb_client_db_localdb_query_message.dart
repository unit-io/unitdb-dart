import 'package:drift/drift.dart';
import 'package:unitdb_client/src/db/localdb/unitdb_client_db_localdb.dart';
import 'package:unitdb_client/src/db/localdb/unitdb_client_db_localdb_adapter.dart';
import 'package:unitdb_client/unitdb_client.dart';

part 'unitdb_client_db_localdb_query_message.g.dart';

/// The Data Access Object [Messages] query operation.
@DriftAccessor(tables: [Messages])
class MessageQuery extends DatabaseAccessor<LocalDb> with _$MessageQueryMixin {
  /// Creates a new message query instance
  MessageQuery(LocalDb db) : super(db);

  /// Returns a single message by matching the [Messages.id] with [key]
  Future<UtpMessage> getMessage(int connectionId, int key) async =>
      await (select(messages)
            ..where((m) => m.connectionId.equals(connectionId))
            ..where((m) => m.id.equals(key)))
          .map((messageEntity) async => await messageEntity.toMessage())
          .getSingleOrNull();

  /// Get the keys from the local db
  Future<List<int>> get keys =>
      (select(messages)..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
          .map((g) => g.id)
          .get();
}
