import 'package:drift/drift.dart';
import 'package:unitdb_client/unitdb_client.dart';
import 'package:unitdb_client/src/db/localdb/unitdb_client_db_localdb.dart';
import 'package:unitdb_client/src/db/localdb/unitdb_client_db_localdb_adapter.dart';

part 'unitdb_client_db_localdb_command_message.g.dart';

/// The Data Access Object [Messages] command operations.
@DriftAccessor(tables: [Messages])
class MessageCommand extends DatabaseAccessor<LocalDb>
    with _$MessageCommandMixin {
  /// Creates a new message query instance
  MessageCommand(LocalDb db) : super(db);

  Future<void> putMessage(int sessionId, UtpMessage message) =>
      transaction(() async {
        return into(messages)
            .insertOnConflictUpdate(message.toEntity(sessionId: sessionId));
      });

  /// Removes all the messages by matching [Messages.id] in [messageIds]
  Future<int> deleteMessage(int sessionId, int key) => (delete(messages)
        ..where((tbl) => tbl.sessionId.equals(sessionId))
        ..where((tbl) => tbl.id.equals(key)))
      .go();
}
