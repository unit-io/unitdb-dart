// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unitdb_client_db_localdb_adapter.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
class MessageEntity extends DataClass implements Insertable<MessageEntity> {
  /// The message id
  final int id;

  /// Connection Id
  final int sessionId;

  /// The DateTime when the message was created.
  final DateTime createdAt;

  /// The message payload
  final Uint8List utpMessage;
  MessageEntity(
      {@required this.id,
      @required this.sessionId,
      @required this.createdAt,
      this.utpMessage});
  factory MessageEntity.fromData(Map<String, dynamic> data, {String prefix}) {
    final effectivePrefix = prefix ?? '';
    return MessageEntity(
      id: const IntType().mapFromDatabaseResponse(data['${effectivePrefix}id']),
      sessionId: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}session_id']),
      createdAt: const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at']),
      utpMessage: const BlobType()
          .mapFromDatabaseResponse(data['${effectivePrefix}utp_message']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<int>(id);
    }
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<int>(sessionId);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || utpMessage != null) {
      map['utp_message'] = Variable<Uint8List>(utpMessage);
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      utpMessage: utpMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(utpMessage),
    );
  }

  factory MessageEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageEntity(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      utpMessage: serializer.fromJson<Uint8List>(json['utpMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'utpMessage': serializer.toJson<Uint8List>(utpMessage),
    };
  }

  MessageEntity copyWith(
          {int id, int sessionId, DateTime createdAt, Uint8List utpMessage}) =>
      MessageEntity(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        createdAt: createdAt ?? this.createdAt,
        utpMessage: utpMessage ?? this.utpMessage,
      );
  @override
  String toString() {
    return (StringBuffer('MessageEntity(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('createdAt: $createdAt, ')
          ..write('utpMessage: $utpMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionId, createdAt, utpMessage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageEntity &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.createdAt == this.createdAt &&
          other.utpMessage == this.utpMessage);
}

class MessagesCompanion extends UpdateCompanion<MessageEntity> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<DateTime> createdAt;
  final Value<Uint8List> utpMessage;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.utpMessage = const Value.absent(),
  });
  MessagesCompanion.insert({
    this.id = const Value.absent(),
    @required int sessionId,
    this.createdAt = const Value.absent(),
    this.utpMessage = const Value.absent(),
  }) : sessionId = Value(sessionId);
  static Insertable<MessageEntity> custom({
    Expression<int> id,
    Expression<int> sessionId,
    Expression<DateTime> createdAt,
    Expression<Uint8List> utpMessage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (createdAt != null) 'created_at': createdAt,
      if (utpMessage != null) 'utp_message': utpMessage,
    });
  }

  MessagesCompanion copyWith(
      {Value<int> id,
      Value<int> sessionId,
      Value<DateTime> createdAt,
      Value<Uint8List> utpMessage}) {
    return MessagesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      createdAt: createdAt ?? this.createdAt,
      utpMessage: utpMessage ?? this.utpMessage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (utpMessage.present) {
      map['utp_message'] = Variable<Uint8List>(utpMessage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('createdAt: $createdAt, ')
          ..write('utpMessage: $utpMessage')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages
    with TableInfo<$MessagesTable, MessageEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  GeneratedColumn<int> _id;
  @override
  GeneratedColumn<int> get id =>
      _id ??= GeneratedColumn<int>('id', aliasedName, false,
          type: const IntType(), requiredDuringInsert: false);
  final VerificationMeta _sessionIdMeta = const VerificationMeta('sessionId');
  GeneratedColumn<int> _sessionId;
  @override
  GeneratedColumn<int> get sessionId =>
      _sessionId ??= GeneratedColumn<int>('session_id', aliasedName, false,
          type: const IntType(), requiredDuringInsert: true);
  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  GeneratedColumn<DateTime> _createdAt;
  @override
  GeneratedColumn<DateTime> get createdAt =>
      _createdAt ??= GeneratedColumn<DateTime>('created_at', aliasedName, false,
          type: const IntType(),
          requiredDuringInsert: false,
          defaultValue: currentDateAndTime);
  final VerificationMeta _utpMessageMeta = const VerificationMeta('utpMessage');
  GeneratedColumn<Uint8List> _utpMessage;
  @override
  GeneratedColumn<Uint8List> get utpMessage => _utpMessage ??=
      GeneratedColumn<Uint8List>('utp_message', aliasedName, true,
          type: const BlobType(), requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, sessionId, createdAt, utpMessage];
  @override
  String get aliasedName => _alias ?? 'messages';
  @override
  String get actualTableName => 'messages';
  @override
  VerificationContext validateIntegrity(Insertable<MessageEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id'], _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id'], _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at'], _createdAtMeta));
    }
    if (data.containsKey('utp_message')) {
      context.handle(
          _utpMessageMeta,
          utpMessage.isAcceptableOrUnknown(
              data['utp_message'], _utpMessageMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageEntity map(Map<String, dynamic> data, {String tablePrefix}) {
    return MessageEntity.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

abstract class _$LocalDb extends GeneratedDatabase {
  _$LocalDb(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  $MessagesTable _messages;
  $MessagesTable get messages => _messages ??= $MessagesTable(this);
  MessageQuery _messageQuery;
  MessageQuery get messageQuery =>
      _messageQuery ??= MessageQuery(this as LocalDb);
  MessageCommand _messageCommand;
  MessageCommand get messageCommand =>
      _messageCommand ??= MessageCommand(this as LocalDb);
  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [messages];
}
