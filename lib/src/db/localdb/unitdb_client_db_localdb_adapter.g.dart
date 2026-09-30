// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unitdb_client_db_localdb_adapter.dart';

// ignore_for_file: type=lint
class $MessagesTable extends Messages
    with TableInfo<$MessagesTable, MessageEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
      'session_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _utpMessageMeta =
      const VerificationMeta('utpMessage');
  @override
  late final GeneratedColumn<Uint8List> utpMessage = GeneratedColumn<Uint8List>(
      'utp_message', aliasedName, true,
      type: DriftSqlType.blob, requiredDuringInsert: false);
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
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('utp_message')) {
      context.handle(
          _utpMessageMeta,
          utpMessage.isAcceptableOrUnknown(
              data['utp_message']!, _utpMessageMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageEntity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}session_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      utpMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}utp_message']),
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class MessageEntity extends DataClass implements Insertable<MessageEntity> {
  /// The message id
  final int id;

  /// Connection Id
  final int sessionId;

  /// The DateTime when the message was created.
  final DateTime createdAt;

  /// The message payload
  final Uint8List? utpMessage;
  const MessageEntity(
      {required this.id,
      required this.sessionId,
      required this.createdAt,
      this.utpMessage});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || utpMessage != null) {
      map['utp_message'] = Variable<Uint8List>(utpMessage);
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      createdAt: Value(createdAt),
      utpMessage: utpMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(utpMessage),
    );
  }

  factory MessageEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageEntity(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      utpMessage: serializer.fromJson<Uint8List?>(json['utpMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'utpMessage': serializer.toJson<Uint8List?>(utpMessage),
    };
  }

  MessageEntity copyWith(
          {int? id,
          int? sessionId,
          DateTime? createdAt,
          Value<Uint8List?> utpMessage = const Value.absent()}) =>
      MessageEntity(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        createdAt: createdAt ?? this.createdAt,
        utpMessage: utpMessage.present ? utpMessage.value : this.utpMessage,
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
  int get hashCode => Object.hash(
      id, sessionId, createdAt, $driftBlobEquality.hash(utpMessage));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageEntity &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.createdAt == this.createdAt &&
          $driftBlobEquality.equals(other.utpMessage, this.utpMessage));
}

class MessagesCompanion extends UpdateCompanion<MessageEntity> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<DateTime> createdAt;
  final Value<Uint8List?> utpMessage;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.utpMessage = const Value.absent(),
  });
  MessagesCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    this.createdAt = const Value.absent(),
    this.utpMessage = const Value.absent(),
  }) : sessionId = Value(sessionId);
  static Insertable<MessageEntity> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<DateTime>? createdAt,
    Expression<Uint8List>? utpMessage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (createdAt != null) 'created_at': createdAt,
      if (utpMessage != null) 'utp_message': utpMessage,
    });
  }

  MessagesCompanion copyWith(
      {Value<int>? id,
      Value<int>? sessionId,
      Value<DateTime>? createdAt,
      Value<Uint8List?>? utpMessage}) {
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

abstract class _$LocalDb extends GeneratedDatabase {
  _$LocalDb(QueryExecutor e) : super(e);
  late final $MessagesTable messages = $MessagesTable(this);
  late final MessageQuery messageQuery = MessageQuery(this as LocalDb);
  late final MessageCommand messageCommand = MessageCommand(this as LocalDb);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [messages];
}
