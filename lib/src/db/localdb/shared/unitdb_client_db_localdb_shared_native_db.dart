import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:unitdb_client/src/db/localdb/unitdb_client_db_localdb_adapter.dart';

class SharedDb {
  static LocalDb localDb(String userId) {
    final dbName = 'db_$userId';
    return LocalDb(
      userId,
      LazyDatabase(
        () async => _localDb(
          dbName,
          logStatements: false,
        ),
      ),
    );
  }

  static Future<NativeDatabase> _localDb(
    String dbName, {
    bool logStatements = false,
  }) async {
    if (Platform.isIOS || Platform.isAndroid) {
      // final dir = await getApplicationDocumentsDirectory();
      // final path = join(dir.path, '$dbName.sqlite');
      final file = File('$dbName.sqlite');
      return NativeDatabase(file, logStatements: logStatements);
    }
    if (Platform.isMacOS || Platform.isLinux) {
      final file = File('$dbName.sqlite');
      return NativeDatabase(file, logStatements: logStatements);
    }
    return NativeDatabase.memory(logStatements: logStatements);
  }
}
