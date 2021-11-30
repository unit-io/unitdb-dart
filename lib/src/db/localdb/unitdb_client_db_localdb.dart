library localdb;

import 'package:drift/drift.dart';

export 'shared/unitdb_client_db_localdb_shared_unsupported_db.dart'
    if (dart.library.io) './shared/unitdb_client_db_localdb_shared_native_db.dart' // implementation using dart:io
    if (dart.library.html) './shared/unitdb_client_db_localdb_shared_web_db.dart';

import 'package:unitdb_client/src/db/localdb/unitdb_client_db_localdb_adapter.dart';
import 'package:unitdb_client/unitdb_client.dart';

part './entity/unitdb_client_db_localdb_entity_message.dart';
