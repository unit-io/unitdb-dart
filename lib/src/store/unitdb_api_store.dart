import 'package:mutex/mutex.dart';
import 'package:unitdb_client/unitdb_client.dart';
import 'package:unitdb_client/src/db/unitdb_client_db_adapter.dart';
import 'package:unitdb_client/src/db/localdb/unitdb_client_db_localdb_adapter.dart'
    as adapter;
import 'package:unitdb_client/src/db/localdb/unitdb_client_db_localdb.dart';

class Store extends Adapter {
  adapter.LocalDb db;
  final _mutex = ReadWriteMutex();

  adapter.LocalDb _defaultDatabaseProvider(String userId) =>
      SharedDb.localDb(userId);

  @override
  Future<void> connect(String userId, {bool reset = false}) async {
    if (db != null) {
      throw Exception('An instance of LocalDb is already connected.');
    }
    db = _defaultDatabaseProvider(userId);
    _mutex.protectWrite(() async {
      if (reset) {
        print('localstore: reset db');
        await db.reset();
      }
    });
  }

  @override
  Future<void> putMessage(int sessionId, UtpMessage message) {
    return _mutex
        .protectRead(() => db.messageCommand.putMessage(sessionId, message));
  }

  @override
  Future<UtpMessage> getMessage(int sessionId, int key) {
    return _mutex.protectRead(() => db.messageQuery.getMessage(sessionId, key));
  }

  @override
  Future<void> deleteMessage(int sessionId, int key) {
    return _mutex
        .protectRead(() => db.messageCommand.deleteMessage(sessionId, key));
  }

  @override
  Future<List<int>> keys() {
    return _mutex.protectRead(() => db.messageQuery.keys);
  }

// handle which outgoing messages are stored
  Future<void> persistOutbound(int sessionId, UtpMessage outMessage) {
    switch (outMessage.type()) {
      case MessageType.PUBLISH:
      case MessageType.SUBSCRIBE:
      case MessageType.UNSUBSCRIBE:
        // Received a publish. store it in ibound
        // until ACKNOWLEDGE or COMPLETE is sent
        putMessage(sessionId, outMessage);
        break;
    }
    if (outMessage.type() == MessageType.FLOWCONTROL) {
      final message = outMessage as ControlMessage;
      switch (message.flowControl) {
        case FlowControl.RECEIPT:
          // Received a RECEIPT control message. store it in obound
          // until COMPLETE is received.
          putMessage(sessionId, outMessage);
          break;
      }
    }
  }

// handle which incoming messages are stored
  Future<void> persistInbound(int sessionId, UtpMessage inMessage) {
    switch (inMessage.type()) {
      case MessageType.PUBLISH:
        // Received a publish. store it in ibound
        // until COMPLETE sent
        putMessage(sessionId, inMessage);
        break;
    }
    if (inMessage.type() == MessageType.FLOWCONTROL) {
      final message = inMessage as ControlMessage;
      switch (message.flowControl) {
        case FlowControl.ACKNOWLEDGE:
        case FlowControl.COMPLETE:
          // Sending ACKNOWLEDGE, delete matching PUBLISH for EXPRESS delivery mode
          // or sending COMPLETE, delete matching RECEIVE for RELIABLE delivery mode from ibound
          deleteMessage(sessionId, inMessage.getInfo().messageID);
          break;
        case FlowControl.NOTIFY:
          // Sending RECEIPT. store in obound
          // until COMPLETE received
          putMessage(sessionId, inMessage);
          break;
      }
    }
  }

  @override
  Future<void> disconnect() async => _mutex.protectWrite(() async {
        if (db != null) {
          await db.disconnect();
          db = null;
        }
      });
}
