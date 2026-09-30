part of localdb;

/// Represents a [Messages] table in [LocalDb].
@DataClassName('MessageEntity')
class Messages extends Table {
  /// The message id
  IntColumn get id => integer()();

  /// Connection Id
  IntColumn get sessionId => integer()();

  /// The DateTime when the message was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// The message payload
  BlobColumn get utpMessage => blob().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mapping functions for [MessageEntity]
extension MessageEntityX on MessageEntity {
  /// Maps a [MessageEntity] into [Message]
  Future<UtpMessage?> toMessage() async {
    final m = utpMessage;
    return m == null ? null : await UtpMessage.read(ByteBuffer.fromList(m));
  }
}

/// Mapping functions for [Message]
extension MessageX on UtpMessage {
  /// Maps a [Message] into [MessageEntity]
  MessagesCompanion toEntity({required int sessionId}) => MessagesCompanion.insert(
        id: Value(getInfo().messageID),
        sessionId: sessionId,
        utpMessage: Value(Uint8List.fromList(this.encode().readAll())),
      );
}
