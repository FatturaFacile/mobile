// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $EntityRecordsTable extends EntityRecords
    with TableInfo<$EntityRecordsTable, EntityRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntityRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, int> syncStatus =
      GeneratedColumn<int>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<SyncStatus>($EntityRecordsTable.$convertersyncStatus);
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverUpdatedAt =
      GeneratedColumn<DateTime>(
        'server_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    entity,
    id,
    tenantId,
    serverId,
    payload,
    syncStatus,
    localUpdatedAt,
    serverUpdatedAt,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entity_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntityRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localUpdatedAtMeta);
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, entity, id};
  @override
  EntityRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntityRecord(
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      syncStatus: $EntityRecordsTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_updated_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      ),
    );
  }

  @override
  $EntityRecordsTable createAlias(String alias) {
    return $EntityRecordsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatus, int, int> $convertersyncStatus =
      const EnumIndexConverter<SyncStatus>(SyncStatus.values);
}

class EntityRecord extends DataClass implements Insertable<EntityRecord> {
  final String entity;
  final String id;
  final String tenantId;
  final String? serverId;
  final String payload;
  final SyncStatus syncStatus;
  final DateTime localUpdatedAt;
  final DateTime? serverUpdatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? createdBy;
  final String? updatedBy;
  const EntityRecord({
    required this.entity,
    required this.id,
    required this.tenantId,
    this.serverId,
    required this.payload,
    required this.syncStatus,
    required this.localUpdatedAt,
    this.serverUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.createdBy,
    this.updatedBy,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity'] = Variable<String>(entity);
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['payload'] = Variable<String>(payload);
    {
      map['sync_status'] = Variable<int>(
        $EntityRecordsTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    if (!nullToAbsent || updatedBy != null) {
      map['updated_by'] = Variable<String>(updatedBy);
    }
    return map;
  }

  EntityRecordsCompanion toCompanion(bool nullToAbsent) {
    return EntityRecordsCompanion(
      entity: Value(entity),
      id: Value(id),
      tenantId: Value(tenantId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      payload: Value(payload),
      syncStatus: Value(syncStatus),
      localUpdatedAt: Value(localUpdatedAt),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      updatedBy: updatedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedBy),
    );
  }

  factory EntityRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntityRecord(
      entity: serializer.fromJson<String>(json['entity']),
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      payload: serializer.fromJson<String>(json['payload']),
      syncStatus: $EntityRecordsTable.$convertersyncStatus.fromJson(
        serializer.fromJson<int>(json['syncStatus']),
      ),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
      serverUpdatedAt: serializer.fromJson<DateTime?>(json['serverUpdatedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      updatedBy: serializer.fromJson<String?>(json['updatedBy']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entity': serializer.toJson<String>(entity),
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'serverId': serializer.toJson<String?>(serverId),
      'payload': serializer.toJson<String>(payload),
      'syncStatus': serializer.toJson<int>(
        $EntityRecordsTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
      'serverUpdatedAt': serializer.toJson<DateTime?>(serverUpdatedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdBy': serializer.toJson<String?>(createdBy),
      'updatedBy': serializer.toJson<String?>(updatedBy),
    };
  }

  EntityRecord copyWith({
    String? entity,
    String? id,
    String? tenantId,
    Value<String?> serverId = const Value.absent(),
    String? payload,
    SyncStatus? syncStatus,
    DateTime? localUpdatedAt,
    Value<DateTime?> serverUpdatedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> createdBy = const Value.absent(),
    Value<String?> updatedBy = const Value.absent(),
  }) => EntityRecord(
    entity: entity ?? this.entity,
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    serverId: serverId.present ? serverId.value : this.serverId,
    payload: payload ?? this.payload,
    syncStatus: syncStatus ?? this.syncStatus,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    updatedBy: updatedBy.present ? updatedBy.value : this.updatedBy,
  );
  EntityRecord copyWithCompanion(EntityRecordsCompanion data) {
    return EntityRecord(
      entity: data.entity.present ? data.entity.value : this.entity,
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      payload: data.payload.present ? data.payload.value : this.payload,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntityRecord(')
          ..write('entity: $entity, ')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('serverId: $serverId, ')
          ..write('payload: $payload, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    entity,
    id,
    tenantId,
    serverId,
    payload,
    syncStatus,
    localUpdatedAt,
    serverUpdatedAt,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntityRecord &&
          other.entity == this.entity &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.serverId == this.serverId &&
          other.payload == this.payload &&
          other.syncStatus == this.syncStatus &&
          other.localUpdatedAt == this.localUpdatedAt &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdBy == this.createdBy &&
          other.updatedBy == this.updatedBy);
}

class EntityRecordsCompanion extends UpdateCompanion<EntityRecord> {
  final Value<String> entity;
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String?> serverId;
  final Value<String> payload;
  final Value<SyncStatus> syncStatus;
  final Value<DateTime> localUpdatedAt;
  final Value<DateTime?> serverUpdatedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> createdBy;
  final Value<String?> updatedBy;
  final Value<int> rowid;
  const EntityRecordsCompanion({
    this.entity = const Value.absent(),
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.payload = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntityRecordsCompanion.insert({
    required String entity,
    required String id,
    required String tenantId,
    this.serverId = const Value.absent(),
    required String payload,
    required SyncStatus syncStatus,
    required DateTime localUpdatedAt,
    this.serverUpdatedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : entity = Value(entity),
       id = Value(id),
       tenantId = Value(tenantId),
       payload = Value(payload),
       syncStatus = Value(syncStatus),
       localUpdatedAt = Value(localUpdatedAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<EntityRecord> custom({
    Expression<String>? entity,
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? serverId,
    Expression<String>? payload,
    Expression<int>? syncStatus,
    Expression<DateTime>? localUpdatedAt,
    Expression<DateTime>? serverUpdatedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? createdBy,
    Expression<String>? updatedBy,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entity != null) 'entity': entity,
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (serverId != null) 'server_id': serverId,
      if (payload != null) 'payload': payload,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntityRecordsCompanion copyWith({
    Value<String>? entity,
    Value<String>? id,
    Value<String>? tenantId,
    Value<String?>? serverId,
    Value<String>? payload,
    Value<SyncStatus>? syncStatus,
    Value<DateTime>? localUpdatedAt,
    Value<DateTime?>? serverUpdatedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? createdBy,
    Value<String?>? updatedBy,
    Value<int>? rowid,
  }) {
    return EntityRecordsCompanion(
      entity: entity ?? this.entity,
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      serverId: serverId ?? this.serverId,
      payload: payload ?? this.payload,
      syncStatus: syncStatus ?? this.syncStatus,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(
        $EntityRecordsTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntityRecordsCompanion(')
          ..write('entity: $entity, ')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('serverId: $serverId, ')
          ..write('payload: $payload, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, QueueItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dependsOnMeta = const VerificationMeta(
    'dependsOn',
  );
  @override
  late final GeneratedColumn<String> dependsOn = GeneratedColumn<String>(
    'depends_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<int> state = GeneratedColumn<int>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sequence,
    uuid,
    tenantId,
    entity,
    entityId,
    method,
    path,
    payload,
    dependsOn,
    attempts,
    lastError,
    state,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueueItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    }
    if (data.containsKey('depends_on')) {
      context.handle(
        _dependsOnMeta,
        dependsOn.isAcceptableOrUnknown(data['depends_on']!, _dependsOnMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sequence};
  @override
  QueueItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueueItem(
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      ),
      dependsOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}depends_on'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class QueueItem extends DataClass implements Insertable<QueueItem> {
  final int sequence;
  final String uuid;
  final String tenantId;
  final String entity;
  final String entityId;
  final String method;
  final String path;
  final String? payload;

  /// UUID of a queue row that must succeed first (e.g. parent invoice before its lines).
  final String? dependsOn;
  final int attempts;
  final String? lastError;

  /// 0 pending, 1 failed (retry later), 2 conflict.
  final int state;
  final DateTime createdAt;
  const QueueItem({
    required this.sequence,
    required this.uuid,
    required this.tenantId,
    required this.entity,
    required this.entityId,
    required this.method,
    required this.path,
    this.payload,
    this.dependsOn,
    required this.attempts,
    this.lastError,
    required this.state,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sequence'] = Variable<int>(sequence);
    map['uuid'] = Variable<String>(uuid);
    map['tenant_id'] = Variable<String>(tenantId);
    map['entity'] = Variable<String>(entity);
    map['entity_id'] = Variable<String>(entityId);
    map['method'] = Variable<String>(method);
    map['path'] = Variable<String>(path);
    if (!nullToAbsent || payload != null) {
      map['payload'] = Variable<String>(payload);
    }
    if (!nullToAbsent || dependsOn != null) {
      map['depends_on'] = Variable<String>(dependsOn);
    }
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['state'] = Variable<int>(state);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      sequence: Value(sequence),
      uuid: Value(uuid),
      tenantId: Value(tenantId),
      entity: Value(entity),
      entityId: Value(entityId),
      method: Value(method),
      path: Value(path),
      payload: payload == null && nullToAbsent
          ? const Value.absent()
          : Value(payload),
      dependsOn: dependsOn == null && nullToAbsent
          ? const Value.absent()
          : Value(dependsOn),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      state: Value(state),
      createdAt: Value(createdAt),
    );
  }

  factory QueueItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueueItem(
      sequence: serializer.fromJson<int>(json['sequence']),
      uuid: serializer.fromJson<String>(json['uuid']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String>(json['entityId']),
      method: serializer.fromJson<String>(json['method']),
      path: serializer.fromJson<String>(json['path']),
      payload: serializer.fromJson<String?>(json['payload']),
      dependsOn: serializer.fromJson<String?>(json['dependsOn']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      state: serializer.fromJson<int>(json['state']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sequence': serializer.toJson<int>(sequence),
      'uuid': serializer.toJson<String>(uuid),
      'tenantId': serializer.toJson<String>(tenantId),
      'entity': serializer.toJson<String>(entity),
      'entityId': serializer.toJson<String>(entityId),
      'method': serializer.toJson<String>(method),
      'path': serializer.toJson<String>(path),
      'payload': serializer.toJson<String?>(payload),
      'dependsOn': serializer.toJson<String?>(dependsOn),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'state': serializer.toJson<int>(state),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  QueueItem copyWith({
    int? sequence,
    String? uuid,
    String? tenantId,
    String? entity,
    String? entityId,
    String? method,
    String? path,
    Value<String?> payload = const Value.absent(),
    Value<String?> dependsOn = const Value.absent(),
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    int? state,
    DateTime? createdAt,
  }) => QueueItem(
    sequence: sequence ?? this.sequence,
    uuid: uuid ?? this.uuid,
    tenantId: tenantId ?? this.tenantId,
    entity: entity ?? this.entity,
    entityId: entityId ?? this.entityId,
    method: method ?? this.method,
    path: path ?? this.path,
    payload: payload.present ? payload.value : this.payload,
    dependsOn: dependsOn.present ? dependsOn.value : this.dependsOn,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    state: state ?? this.state,
    createdAt: createdAt ?? this.createdAt,
  );
  QueueItem copyWithCompanion(SyncQueueCompanion data) {
    return QueueItem(
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      method: data.method.present ? data.method.value : this.method,
      path: data.path.present ? data.path.value : this.path,
      payload: data.payload.present ? data.payload.value : this.payload,
      dependsOn: data.dependsOn.present ? data.dependsOn.value : this.dependsOn,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      state: data.state.present ? data.state.value : this.state,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueueItem(')
          ..write('sequence: $sequence, ')
          ..write('uuid: $uuid, ')
          ..write('tenantId: $tenantId, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('method: $method, ')
          ..write('path: $path, ')
          ..write('payload: $payload, ')
          ..write('dependsOn: $dependsOn, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('state: $state, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sequence,
    uuid,
    tenantId,
    entity,
    entityId,
    method,
    path,
    payload,
    dependsOn,
    attempts,
    lastError,
    state,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueueItem &&
          other.sequence == this.sequence &&
          other.uuid == this.uuid &&
          other.tenantId == this.tenantId &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.method == this.method &&
          other.path == this.path &&
          other.payload == this.payload &&
          other.dependsOn == this.dependsOn &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.state == this.state &&
          other.createdAt == this.createdAt);
}

class SyncQueueCompanion extends UpdateCompanion<QueueItem> {
  final Value<int> sequence;
  final Value<String> uuid;
  final Value<String> tenantId;
  final Value<String> entity;
  final Value<String> entityId;
  final Value<String> method;
  final Value<String> path;
  final Value<String?> payload;
  final Value<String?> dependsOn;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<int> state;
  final Value<DateTime> createdAt;
  const SyncQueueCompanion({
    this.sequence = const Value.absent(),
    this.uuid = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.method = const Value.absent(),
    this.path = const Value.absent(),
    this.payload = const Value.absent(),
    this.dependsOn = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.state = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.sequence = const Value.absent(),
    required String uuid,
    required String tenantId,
    required String entity,
    required String entityId,
    required String method,
    required String path,
    this.payload = const Value.absent(),
    this.dependsOn = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.state = const Value.absent(),
    required DateTime createdAt,
  }) : uuid = Value(uuid),
       tenantId = Value(tenantId),
       entity = Value(entity),
       entityId = Value(entityId),
       method = Value(method),
       path = Value(path),
       createdAt = Value(createdAt);
  static Insertable<QueueItem> custom({
    Expression<int>? sequence,
    Expression<String>? uuid,
    Expression<String>? tenantId,
    Expression<String>? entity,
    Expression<String>? entityId,
    Expression<String>? method,
    Expression<String>? path,
    Expression<String>? payload,
    Expression<String>? dependsOn,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<int>? state,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (sequence != null) 'sequence': sequence,
      if (uuid != null) 'uuid': uuid,
      if (tenantId != null) 'tenant_id': tenantId,
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (method != null) 'method': method,
      if (path != null) 'path': path,
      if (payload != null) 'payload': payload,
      if (dependsOn != null) 'depends_on': dependsOn,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (state != null) 'state': state,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncQueueCompanion copyWith({
    Value<int>? sequence,
    Value<String>? uuid,
    Value<String>? tenantId,
    Value<String>? entity,
    Value<String>? entityId,
    Value<String>? method,
    Value<String>? path,
    Value<String?>? payload,
    Value<String?>? dependsOn,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<int>? state,
    Value<DateTime>? createdAt,
  }) {
    return SyncQueueCompanion(
      sequence: sequence ?? this.sequence,
      uuid: uuid ?? this.uuid,
      tenantId: tenantId ?? this.tenantId,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      method: method ?? this.method,
      path: path ?? this.path,
      payload: payload ?? this.payload,
      dependsOn: dependsOn ?? this.dependsOn,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (dependsOn.present) {
      map['depends_on'] = Variable<String>(dependsOn.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (state.present) {
      map['state'] = Variable<int>(state.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('sequence: $sequence, ')
          ..write('uuid: $uuid, ')
          ..write('tenantId: $tenantId, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('method: $method, ')
          ..write('path: $path, ')
          ..write('payload: $payload, ')
          ..write('dependsOn: $dependsOn, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('state: $state, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SyncCursorsTable extends SyncCursors
    with TableInfo<$SyncCursorsTable, SyncCursor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCursorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverTimeMeta = const VerificationMeta(
    'serverTime',
  );
  @override
  late final GeneratedColumn<String> serverTime = GeneratedColumn<String>(
    'server_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<String> cursor = GeneratedColumn<String>(
    'cursor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [tenantId, entity, serverTime, cursor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursors';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCursor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('server_time')) {
      context.handle(
        _serverTimeMeta,
        serverTime.isAcceptableOrUnknown(data['server_time']!, _serverTimeMeta),
      );
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, entity};
  @override
  SyncCursor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursor(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      serverTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_time'],
      ),
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor'],
      ),
    );
  }

  @override
  $SyncCursorsTable createAlias(String alias) {
    return $SyncCursorsTable(attachedDatabase, alias);
  }
}

class SyncCursor extends DataClass implements Insertable<SyncCursor> {
  final String tenantId;
  final String entity;
  final String? serverTime;
  final String? cursor;
  const SyncCursor({
    required this.tenantId,
    required this.entity,
    this.serverTime,
    this.cursor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['entity'] = Variable<String>(entity);
    if (!nullToAbsent || serverTime != null) {
      map['server_time'] = Variable<String>(serverTime);
    }
    if (!nullToAbsent || cursor != null) {
      map['cursor'] = Variable<String>(cursor);
    }
    return map;
  }

  SyncCursorsCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorsCompanion(
      tenantId: Value(tenantId),
      entity: Value(entity),
      serverTime: serverTime == null && nullToAbsent
          ? const Value.absent()
          : Value(serverTime),
      cursor: cursor == null && nullToAbsent
          ? const Value.absent()
          : Value(cursor),
    );
  }

  factory SyncCursor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursor(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      entity: serializer.fromJson<String>(json['entity']),
      serverTime: serializer.fromJson<String?>(json['serverTime']),
      cursor: serializer.fromJson<String?>(json['cursor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'entity': serializer.toJson<String>(entity),
      'serverTime': serializer.toJson<String?>(serverTime),
      'cursor': serializer.toJson<String?>(cursor),
    };
  }

  SyncCursor copyWith({
    String? tenantId,
    String? entity,
    Value<String?> serverTime = const Value.absent(),
    Value<String?> cursor = const Value.absent(),
  }) => SyncCursor(
    tenantId: tenantId ?? this.tenantId,
    entity: entity ?? this.entity,
    serverTime: serverTime.present ? serverTime.value : this.serverTime,
    cursor: cursor.present ? cursor.value : this.cursor,
  );
  SyncCursor copyWithCompanion(SyncCursorsCompanion data) {
    return SyncCursor(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      entity: data.entity.present ? data.entity.value : this.entity,
      serverTime: data.serverTime.present
          ? data.serverTime.value
          : this.serverTime,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursor(')
          ..write('tenantId: $tenantId, ')
          ..write('entity: $entity, ')
          ..write('serverTime: $serverTime, ')
          ..write('cursor: $cursor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tenantId, entity, serverTime, cursor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursor &&
          other.tenantId == this.tenantId &&
          other.entity == this.entity &&
          other.serverTime == this.serverTime &&
          other.cursor == this.cursor);
}

class SyncCursorsCompanion extends UpdateCompanion<SyncCursor> {
  final Value<String> tenantId;
  final Value<String> entity;
  final Value<String?> serverTime;
  final Value<String?> cursor;
  final Value<int> rowid;
  const SyncCursorsCompanion({
    this.tenantId = const Value.absent(),
    this.entity = const Value.absent(),
    this.serverTime = const Value.absent(),
    this.cursor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCursorsCompanion.insert({
    required String tenantId,
    required String entity,
    this.serverTime = const Value.absent(),
    this.cursor = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       entity = Value(entity);
  static Insertable<SyncCursor> custom({
    Expression<String>? tenantId,
    Expression<String>? entity,
    Expression<String>? serverTime,
    Expression<String>? cursor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (entity != null) 'entity': entity,
      if (serverTime != null) 'server_time': serverTime,
      if (cursor != null) 'cursor': cursor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCursorsCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? entity,
    Value<String?>? serverTime,
    Value<String?>? cursor,
    Value<int>? rowid,
  }) {
    return SyncCursorsCompanion(
      tenantId: tenantId ?? this.tenantId,
      entity: entity ?? this.entity,
      serverTime: serverTime ?? this.serverTime,
      cursor: cursor ?? this.cursor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (serverTime.present) {
      map['server_time'] = Variable<String>(serverTime.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<String>(cursor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorsCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('entity: $entity, ')
          ..write('serverTime: $serverTime, ')
          ..write('cursor: $cursor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TranslationsTable extends Translations
    with TableInfo<$TranslationsTable, Translation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TranslationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localeMeta = const VerificationMeta('locale');
  @override
  late final GeneratedColumn<String> locale = GeneratedColumn<String>(
    'locale',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [locale, tenantId, key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'translations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Translation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('locale')) {
      context.handle(
        _localeMeta,
        locale.isAcceptableOrUnknown(data['locale']!, _localeMeta),
      );
    } else if (isInserting) {
      context.missing(_localeMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {locale, tenantId, key};
  @override
  Translation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Translation(
      locale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $TranslationsTable createAlias(String alias) {
    return $TranslationsTable(attachedDatabase, alias);
  }
}

class Translation extends DataClass implements Insertable<Translation> {
  final String locale;
  final String tenantId;
  final String key;
  final String value;
  const Translation({
    required this.locale,
    required this.tenantId,
    required this.key,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['locale'] = Variable<String>(locale);
    map['tenant_id'] = Variable<String>(tenantId);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  TranslationsCompanion toCompanion(bool nullToAbsent) {
    return TranslationsCompanion(
      locale: Value(locale),
      tenantId: Value(tenantId),
      key: Value(key),
      value: Value(value),
    );
  }

  factory Translation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Translation(
      locale: serializer.fromJson<String>(json['locale']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'locale': serializer.toJson<String>(locale),
      'tenantId': serializer.toJson<String>(tenantId),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Translation copyWith({
    String? locale,
    String? tenantId,
    String? key,
    String? value,
  }) => Translation(
    locale: locale ?? this.locale,
    tenantId: tenantId ?? this.tenantId,
    key: key ?? this.key,
    value: value ?? this.value,
  );
  Translation copyWithCompanion(TranslationsCompanion data) {
    return Translation(
      locale: data.locale.present ? data.locale.value : this.locale,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Translation(')
          ..write('locale: $locale, ')
          ..write('tenantId: $tenantId, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(locale, tenantId, key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Translation &&
          other.locale == this.locale &&
          other.tenantId == this.tenantId &&
          other.key == this.key &&
          other.value == this.value);
}

class TranslationsCompanion extends UpdateCompanion<Translation> {
  final Value<String> locale;
  final Value<String> tenantId;
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const TranslationsCompanion({
    this.locale = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TranslationsCompanion.insert({
    required String locale,
    this.tenantId = const Value.absent(),
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : locale = Value(locale),
       key = Value(key),
       value = Value(value);
  static Insertable<Translation> custom({
    Expression<String>? locale,
    Expression<String>? tenantId,
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (locale != null) 'locale': locale,
      if (tenantId != null) 'tenant_id': tenantId,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TranslationsCompanion copyWith({
    Value<String>? locale,
    Value<String>? tenantId,
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return TranslationsCompanion(
      locale: locale ?? this.locale,
      tenantId: tenantId ?? this.tenantId,
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (locale.present) {
      map['locale'] = Variable<String>(locale.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TranslationsCompanion(')
          ..write('locale: $locale, ')
          ..write('tenantId: $tenantId, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CopilotConversationsTable extends CopilotConversations
    with TableInfo<$CopilotConversationsTable, CopilotConversationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CopilotConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    id,
    title,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'copilot_conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<CopilotConversationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, id};
  @override
  CopilotConversationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CopilotConversationRow(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CopilotConversationsTable createAlias(String alias) {
    return $CopilotConversationsTable(attachedDatabase, alias);
  }
}

class CopilotConversationRow extends DataClass
    implements Insertable<CopilotConversationRow> {
  final String tenantId;
  final String id;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CopilotConversationRow({
    required this.tenantId,
    required this.id,
    this.title,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CopilotConversationsCompanion toCompanion(bool nullToAbsent) {
    return CopilotConversationsCompanion(
      tenantId: Value(tenantId),
      id: Value(id),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CopilotConversationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CopilotConversationRow(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String?>(json['title']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String?>(title),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CopilotConversationRow copyWith({
    String? tenantId,
    String? id,
    Value<String?> title = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CopilotConversationRow(
    tenantId: tenantId ?? this.tenantId,
    id: id ?? this.id,
    title: title.present ? title.value : this.title,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CopilotConversationRow copyWithCompanion(CopilotConversationsCompanion data) {
    return CopilotConversationRow(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CopilotConversationRow(')
          ..write('tenantId: $tenantId, ')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tenantId, id, title, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CopilotConversationRow &&
          other.tenantId == this.tenantId &&
          other.id == this.id &&
          other.title == this.title &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CopilotConversationsCompanion
    extends UpdateCompanion<CopilotConversationRow> {
  final Value<String> tenantId;
  final Value<String> id;
  final Value<String?> title;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CopilotConversationsCompanion({
    this.tenantId = const Value.absent(),
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CopilotConversationsCompanion.insert({
    required String tenantId,
    required String id,
    this.title = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CopilotConversationRow> custom({
    Expression<String>? tenantId,
    Expression<String>? id,
    Expression<String>? title,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CopilotConversationsCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? id,
    Value<String?>? title,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CopilotConversationsCompanion(
      tenantId: tenantId ?? this.tenantId,
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CopilotConversationsCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CopilotMessagesTable extends CopilotMessages
    with TableInfo<$CopilotMessagesTable, CopilotMessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CopilotMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    id,
    conversationId,
    role,
    payload,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'copilot_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<CopilotMessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, id};
  @override
  CopilotMessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CopilotMessageRow(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CopilotMessagesTable createAlias(String alias) {
    return $CopilotMessagesTable(attachedDatabase, alias);
  }
}

class CopilotMessageRow extends DataClass
    implements Insertable<CopilotMessageRow> {
  final String tenantId;
  final String id;
  final String conversationId;
  final String role;
  final String payload;
  final DateTime createdAt;
  const CopilotMessageRow({
    required this.tenantId,
    required this.id,
    required this.conversationId,
    required this.role,
    required this.payload,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['id'] = Variable<String>(id);
    map['conversation_id'] = Variable<String>(conversationId);
    map['role'] = Variable<String>(role);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CopilotMessagesCompanion toCompanion(bool nullToAbsent) {
    return CopilotMessagesCompanion(
      tenantId: Value(tenantId),
      id: Value(id),
      conversationId: Value(conversationId),
      role: Value(role),
      payload: Value(payload),
      createdAt: Value(createdAt),
    );
  }

  factory CopilotMessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CopilotMessageRow(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      id: serializer.fromJson<String>(json['id']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      role: serializer.fromJson<String>(json['role']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'id': serializer.toJson<String>(id),
      'conversationId': serializer.toJson<String>(conversationId),
      'role': serializer.toJson<String>(role),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CopilotMessageRow copyWith({
    String? tenantId,
    String? id,
    String? conversationId,
    String? role,
    String? payload,
    DateTime? createdAt,
  }) => CopilotMessageRow(
    tenantId: tenantId ?? this.tenantId,
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    role: role ?? this.role,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
  );
  CopilotMessageRow copyWithCompanion(CopilotMessagesCompanion data) {
    return CopilotMessageRow(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      role: data.role.present ? data.role.value : this.role,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CopilotMessageRow(')
          ..write('tenantId: $tenantId, ')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(tenantId, id, conversationId, role, payload, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CopilotMessageRow &&
          other.tenantId == this.tenantId &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.role == this.role &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt);
}

class CopilotMessagesCompanion extends UpdateCompanion<CopilotMessageRow> {
  final Value<String> tenantId;
  final Value<String> id;
  final Value<String> conversationId;
  final Value<String> role;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CopilotMessagesCompanion({
    this.tenantId = const Value.absent(),
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.role = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CopilotMessagesCompanion.insert({
    required String tenantId,
    required String id,
    required String conversationId,
    required String role,
    required String payload,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       id = Value(id),
       conversationId = Value(conversationId),
       role = Value(role),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<CopilotMessageRow> custom({
    Expression<String>? tenantId,
    Expression<String>? id,
    Expression<String>? conversationId,
    Expression<String>? role,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (role != null) 'role': role,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CopilotMessagesCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? id,
    Value<String>? conversationId,
    Value<String>? role,
    Value<String>? payload,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CopilotMessagesCompanion(
      tenantId: tenantId ?? this.tenantId,
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CopilotMessagesCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditQueueEntriesTable extends AuditQueueEntries
    with TableInfo<$AuditQueueEntriesTable, AuditQueueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditQueueEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sequenceNumberMeta = const VerificationMeta(
    'sequenceNumber',
  );
  @override
  late final GeneratedColumn<int> sequenceNumber = GeneratedColumn<int>(
    'sequence_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previousHashMeta = const VerificationMeta(
    'previousHash',
  );
  @override
  late final GeneratedColumn<String> previousHash = GeneratedColumn<String>(
    'previous_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadHashMeta = const VerificationMeta(
    'payloadHash',
  );
  @override
  late final GeneratedColumn<String> payloadHash = GeneratedColumn<String>(
    'payload_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordHashMeta = const VerificationMeta(
    'recordHash',
  );
  @override
  late final GeneratedColumn<String> recordHash = GeneratedColumn<String>(
    'record_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncAttemptsMeta = const VerificationMeta(
    'syncAttempts',
  );
  @override
  late final GeneratedColumn<int> syncAttempts = GeneratedColumn<int>(
    'sync_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverReceiptMeta = const VerificationMeta(
    'serverReceipt',
  );
  @override
  late final GeneratedColumn<String> serverReceipt = GeneratedColumn<String>(
    'server_receipt',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    sequenceNumber,
    uuid,
    entityType,
    entityId,
    action,
    payloadJson,
    metadataJson,
    previousHash,
    payloadHash,
    recordHash,
    occurredAt,
    syncedAt,
    syncAttempts,
    lastError,
    serverReceipt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_queue_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditQueueRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('sequence_number')) {
      context.handle(
        _sequenceNumberMeta,
        sequenceNumber.isAcceptableOrUnknown(
          data['sequence_number']!,
          _sequenceNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sequenceNumberMeta);
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_metadataJsonMeta);
    }
    if (data.containsKey('previous_hash')) {
      context.handle(
        _previousHashMeta,
        previousHash.isAcceptableOrUnknown(
          data['previous_hash']!,
          _previousHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_previousHashMeta);
    }
    if (data.containsKey('payload_hash')) {
      context.handle(
        _payloadHashMeta,
        payloadHash.isAcceptableOrUnknown(
          data['payload_hash']!,
          _payloadHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadHashMeta);
    }
    if (data.containsKey('record_hash')) {
      context.handle(
        _recordHashMeta,
        recordHash.isAcceptableOrUnknown(data['record_hash']!, _recordHashMeta),
      );
    } else if (isInserting) {
      context.missing(_recordHashMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('sync_attempts')) {
      context.handle(
        _syncAttemptsMeta,
        syncAttempts.isAcceptableOrUnknown(
          data['sync_attempts']!,
          _syncAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('server_receipt')) {
      context.handle(
        _serverReceiptMeta,
        serverReceipt.isAcceptableOrUnknown(
          data['server_receipt']!,
          _serverReceiptMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, sequenceNumber};
  @override
  AuditQueueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditQueueRow(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      sequenceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence_number'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      )!,
      previousHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_hash'],
      )!,
      payloadHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_hash'],
      )!,
      recordHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_hash'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      syncAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      serverReceipt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_receipt'],
      ),
    );
  }

  @override
  $AuditQueueEntriesTable createAlias(String alias) {
    return $AuditQueueEntriesTable(attachedDatabase, alias);
  }
}

class AuditQueueRow extends DataClass implements Insertable<AuditQueueRow> {
  final String tenantId;
  final int sequenceNumber;
  final String uuid;
  final String entityType;
  final String entityId;
  final String action;
  final String payloadJson;
  final String metadataJson;
  final String previousHash;
  final String payloadHash;
  final String recordHash;
  final DateTime occurredAt;
  final DateTime? syncedAt;
  final int syncAttempts;
  final String? lastError;
  final String? serverReceipt;
  const AuditQueueRow({
    required this.tenantId,
    required this.sequenceNumber,
    required this.uuid,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.payloadJson,
    required this.metadataJson,
    required this.previousHash,
    required this.payloadHash,
    required this.recordHash,
    required this.occurredAt,
    this.syncedAt,
    required this.syncAttempts,
    this.lastError,
    this.serverReceipt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['sequence_number'] = Variable<int>(sequenceNumber);
    map['uuid'] = Variable<String>(uuid);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['action'] = Variable<String>(action);
    map['payload_json'] = Variable<String>(payloadJson);
    map['metadata_json'] = Variable<String>(metadataJson);
    map['previous_hash'] = Variable<String>(previousHash);
    map['payload_hash'] = Variable<String>(payloadHash);
    map['record_hash'] = Variable<String>(recordHash);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['sync_attempts'] = Variable<int>(syncAttempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || serverReceipt != null) {
      map['server_receipt'] = Variable<String>(serverReceipt);
    }
    return map;
  }

  AuditQueueEntriesCompanion toCompanion(bool nullToAbsent) {
    return AuditQueueEntriesCompanion(
      tenantId: Value(tenantId),
      sequenceNumber: Value(sequenceNumber),
      uuid: Value(uuid),
      entityType: Value(entityType),
      entityId: Value(entityId),
      action: Value(action),
      payloadJson: Value(payloadJson),
      metadataJson: Value(metadataJson),
      previousHash: Value(previousHash),
      payloadHash: Value(payloadHash),
      recordHash: Value(recordHash),
      occurredAt: Value(occurredAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      syncAttempts: Value(syncAttempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      serverReceipt: serverReceipt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverReceipt),
    );
  }

  factory AuditQueueRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditQueueRow(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      sequenceNumber: serializer.fromJson<int>(json['sequenceNumber']),
      uuid: serializer.fromJson<String>(json['uuid']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      action: serializer.fromJson<String>(json['action']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      metadataJson: serializer.fromJson<String>(json['metadataJson']),
      previousHash: serializer.fromJson<String>(json['previousHash']),
      payloadHash: serializer.fromJson<String>(json['payloadHash']),
      recordHash: serializer.fromJson<String>(json['recordHash']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      syncAttempts: serializer.fromJson<int>(json['syncAttempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      serverReceipt: serializer.fromJson<String?>(json['serverReceipt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'sequenceNumber': serializer.toJson<int>(sequenceNumber),
      'uuid': serializer.toJson<String>(uuid),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'action': serializer.toJson<String>(action),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'metadataJson': serializer.toJson<String>(metadataJson),
      'previousHash': serializer.toJson<String>(previousHash),
      'payloadHash': serializer.toJson<String>(payloadHash),
      'recordHash': serializer.toJson<String>(recordHash),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'syncAttempts': serializer.toJson<int>(syncAttempts),
      'lastError': serializer.toJson<String?>(lastError),
      'serverReceipt': serializer.toJson<String?>(serverReceipt),
    };
  }

  AuditQueueRow copyWith({
    String? tenantId,
    int? sequenceNumber,
    String? uuid,
    String? entityType,
    String? entityId,
    String? action,
    String? payloadJson,
    String? metadataJson,
    String? previousHash,
    String? payloadHash,
    String? recordHash,
    DateTime? occurredAt,
    Value<DateTime?> syncedAt = const Value.absent(),
    int? syncAttempts,
    Value<String?> lastError = const Value.absent(),
    Value<String?> serverReceipt = const Value.absent(),
  }) => AuditQueueRow(
    tenantId: tenantId ?? this.tenantId,
    sequenceNumber: sequenceNumber ?? this.sequenceNumber,
    uuid: uuid ?? this.uuid,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    action: action ?? this.action,
    payloadJson: payloadJson ?? this.payloadJson,
    metadataJson: metadataJson ?? this.metadataJson,
    previousHash: previousHash ?? this.previousHash,
    payloadHash: payloadHash ?? this.payloadHash,
    recordHash: recordHash ?? this.recordHash,
    occurredAt: occurredAt ?? this.occurredAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    syncAttempts: syncAttempts ?? this.syncAttempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    serverReceipt: serverReceipt.present
        ? serverReceipt.value
        : this.serverReceipt,
  );
  AuditQueueRow copyWithCompanion(AuditQueueEntriesCompanion data) {
    return AuditQueueRow(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      sequenceNumber: data.sequenceNumber.present
          ? data.sequenceNumber.value
          : this.sequenceNumber,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      action: data.action.present ? data.action.value : this.action,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      previousHash: data.previousHash.present
          ? data.previousHash.value
          : this.previousHash,
      payloadHash: data.payloadHash.present
          ? data.payloadHash.value
          : this.payloadHash,
      recordHash: data.recordHash.present
          ? data.recordHash.value
          : this.recordHash,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      syncAttempts: data.syncAttempts.present
          ? data.syncAttempts.value
          : this.syncAttempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      serverReceipt: data.serverReceipt.present
          ? data.serverReceipt.value
          : this.serverReceipt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditQueueRow(')
          ..write('tenantId: $tenantId, ')
          ..write('sequenceNumber: $sequenceNumber, ')
          ..write('uuid: $uuid, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('previousHash: $previousHash, ')
          ..write('payloadHash: $payloadHash, ')
          ..write('recordHash: $recordHash, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('lastError: $lastError, ')
          ..write('serverReceipt: $serverReceipt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tenantId,
    sequenceNumber,
    uuid,
    entityType,
    entityId,
    action,
    payloadJson,
    metadataJson,
    previousHash,
    payloadHash,
    recordHash,
    occurredAt,
    syncedAt,
    syncAttempts,
    lastError,
    serverReceipt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditQueueRow &&
          other.tenantId == this.tenantId &&
          other.sequenceNumber == this.sequenceNumber &&
          other.uuid == this.uuid &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.action == this.action &&
          other.payloadJson == this.payloadJson &&
          other.metadataJson == this.metadataJson &&
          other.previousHash == this.previousHash &&
          other.payloadHash == this.payloadHash &&
          other.recordHash == this.recordHash &&
          other.occurredAt == this.occurredAt &&
          other.syncedAt == this.syncedAt &&
          other.syncAttempts == this.syncAttempts &&
          other.lastError == this.lastError &&
          other.serverReceipt == this.serverReceipt);
}

class AuditQueueEntriesCompanion extends UpdateCompanion<AuditQueueRow> {
  final Value<String> tenantId;
  final Value<int> sequenceNumber;
  final Value<String> uuid;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> action;
  final Value<String> payloadJson;
  final Value<String> metadataJson;
  final Value<String> previousHash;
  final Value<String> payloadHash;
  final Value<String> recordHash;
  final Value<DateTime> occurredAt;
  final Value<DateTime?> syncedAt;
  final Value<int> syncAttempts;
  final Value<String?> lastError;
  final Value<String?> serverReceipt;
  final Value<int> rowid;
  const AuditQueueEntriesCompanion({
    this.tenantId = const Value.absent(),
    this.sequenceNumber = const Value.absent(),
    this.uuid = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.action = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.previousHash = const Value.absent(),
    this.payloadHash = const Value.absent(),
    this.recordHash = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.serverReceipt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditQueueEntriesCompanion.insert({
    required String tenantId,
    required int sequenceNumber,
    required String uuid,
    required String entityType,
    required String entityId,
    required String action,
    required String payloadJson,
    required String metadataJson,
    required String previousHash,
    required String payloadHash,
    required String recordHash,
    required DateTime occurredAt,
    this.syncedAt = const Value.absent(),
    this.syncAttempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.serverReceipt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       sequenceNumber = Value(sequenceNumber),
       uuid = Value(uuid),
       entityType = Value(entityType),
       entityId = Value(entityId),
       action = Value(action),
       payloadJson = Value(payloadJson),
       metadataJson = Value(metadataJson),
       previousHash = Value(previousHash),
       payloadHash = Value(payloadHash),
       recordHash = Value(recordHash),
       occurredAt = Value(occurredAt);
  static Insertable<AuditQueueRow> custom({
    Expression<String>? tenantId,
    Expression<int>? sequenceNumber,
    Expression<String>? uuid,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? action,
    Expression<String>? payloadJson,
    Expression<String>? metadataJson,
    Expression<String>? previousHash,
    Expression<String>? payloadHash,
    Expression<String>? recordHash,
    Expression<DateTime>? occurredAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? syncAttempts,
    Expression<String>? lastError,
    Expression<String>? serverReceipt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (sequenceNumber != null) 'sequence_number': sequenceNumber,
      if (uuid != null) 'uuid': uuid,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (action != null) 'action': action,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (previousHash != null) 'previous_hash': previousHash,
      if (payloadHash != null) 'payload_hash': payloadHash,
      if (recordHash != null) 'record_hash': recordHash,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (syncAttempts != null) 'sync_attempts': syncAttempts,
      if (lastError != null) 'last_error': lastError,
      if (serverReceipt != null) 'server_receipt': serverReceipt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditQueueEntriesCompanion copyWith({
    Value<String>? tenantId,
    Value<int>? sequenceNumber,
    Value<String>? uuid,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? action,
    Value<String>? payloadJson,
    Value<String>? metadataJson,
    Value<String>? previousHash,
    Value<String>? payloadHash,
    Value<String>? recordHash,
    Value<DateTime>? occurredAt,
    Value<DateTime?>? syncedAt,
    Value<int>? syncAttempts,
    Value<String?>? lastError,
    Value<String?>? serverReceipt,
    Value<int>? rowid,
  }) {
    return AuditQueueEntriesCompanion(
      tenantId: tenantId ?? this.tenantId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      uuid: uuid ?? this.uuid,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      payloadJson: payloadJson ?? this.payloadJson,
      metadataJson: metadataJson ?? this.metadataJson,
      previousHash: previousHash ?? this.previousHash,
      payloadHash: payloadHash ?? this.payloadHash,
      recordHash: recordHash ?? this.recordHash,
      occurredAt: occurredAt ?? this.occurredAt,
      syncedAt: syncedAt ?? this.syncedAt,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      lastError: lastError ?? this.lastError,
      serverReceipt: serverReceipt ?? this.serverReceipt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (sequenceNumber.present) {
      map['sequence_number'] = Variable<int>(sequenceNumber.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (previousHash.present) {
      map['previous_hash'] = Variable<String>(previousHash.value);
    }
    if (payloadHash.present) {
      map['payload_hash'] = Variable<String>(payloadHash.value);
    }
    if (recordHash.present) {
      map['record_hash'] = Variable<String>(recordHash.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (syncAttempts.present) {
      map['sync_attempts'] = Variable<int>(syncAttempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (serverReceipt.present) {
      map['server_receipt'] = Variable<String>(serverReceipt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditQueueEntriesCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('sequenceNumber: $sequenceNumber, ')
          ..write('uuid: $uuid, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('previousHash: $previousHash, ')
          ..write('payloadHash: $payloadHash, ')
          ..write('recordHash: $recordHash, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('syncAttempts: $syncAttempts, ')
          ..write('lastError: $lastError, ')
          ..write('serverReceipt: $serverReceipt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DssExecutiveSnapshotsTable extends DssExecutiveSnapshots
    with TableInfo<$DssExecutiveSnapshotsTable, DssSnapshotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DssExecutiveSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _legalEntityIdMeta = const VerificationMeta(
    'legalEntityId',
  );
  @override
  late final GeneratedColumn<String> legalEntityId = GeneratedColumn<String>(
    'legal_entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodPresetMeta = const VerificationMeta(
    'periodPreset',
  );
  @override
  late final GeneratedColumn<String> periodPreset = GeneratedColumn<String>(
    'period_preset',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _comparisonBaselineMeta =
      const VerificationMeta('comparisonBaseline');
  @override
  late final GeneratedColumn<String> comparisonBaseline =
      GeneratedColumn<String>(
        'comparison_baseline',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _overviewJsonMeta = const VerificationMeta(
    'overviewJson',
  );
  @override
  late final GeneratedColumn<String> overviewJson = GeneratedColumn<String>(
    'overview_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customersJsonMeta = const VerificationMeta(
    'customersJson',
  );
  @override
  late final GeneratedColumn<String> customersJson = GeneratedColumn<String>(
    'customers_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productsJsonMeta = const VerificationMeta(
    'productsJson',
  );
  @override
  late final GeneratedColumn<String> productsJson = GeneratedColumn<String>(
    'products_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _varianceJsonMeta = const VerificationMeta(
    'varianceJson',
  );
  @override
  late final GeneratedColumn<String> varianceJson = GeneratedColumn<String>(
    'variance_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inputsJsonMeta = const VerificationMeta(
    'inputsJson',
  );
  @override
  late final GeneratedColumn<String> inputsJson = GeneratedColumn<String>(
    'inputs_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _legalEntitiesJsonMeta = const VerificationMeta(
    'legalEntitiesJson',
  );
  @override
  late final GeneratedColumn<String> legalEntitiesJson =
      GeneratedColumn<String>(
        'legal_entities_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    legalEntityId,
    currency,
    periodPreset,
    comparisonBaseline,
    overviewJson,
    customersJson,
    productsJson,
    varianceJson,
    inputsJson,
    legalEntitiesJson,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dss_executive_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<DssSnapshotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('legal_entity_id')) {
      context.handle(
        _legalEntityIdMeta,
        legalEntityId.isAcceptableOrUnknown(
          data['legal_entity_id']!,
          _legalEntityIdMeta,
        ),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('period_preset')) {
      context.handle(
        _periodPresetMeta,
        periodPreset.isAcceptableOrUnknown(
          data['period_preset']!,
          _periodPresetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_periodPresetMeta);
    }
    if (data.containsKey('comparison_baseline')) {
      context.handle(
        _comparisonBaselineMeta,
        comparisonBaseline.isAcceptableOrUnknown(
          data['comparison_baseline']!,
          _comparisonBaselineMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_comparisonBaselineMeta);
    }
    if (data.containsKey('overview_json')) {
      context.handle(
        _overviewJsonMeta,
        overviewJson.isAcceptableOrUnknown(
          data['overview_json']!,
          _overviewJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_overviewJsonMeta);
    }
    if (data.containsKey('customers_json')) {
      context.handle(
        _customersJsonMeta,
        customersJson.isAcceptableOrUnknown(
          data['customers_json']!,
          _customersJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_customersJsonMeta);
    }
    if (data.containsKey('products_json')) {
      context.handle(
        _productsJsonMeta,
        productsJson.isAcceptableOrUnknown(
          data['products_json']!,
          _productsJsonMeta,
        ),
      );
    }
    if (data.containsKey('variance_json')) {
      context.handle(
        _varianceJsonMeta,
        varianceJson.isAcceptableOrUnknown(
          data['variance_json']!,
          _varianceJsonMeta,
        ),
      );
    }
    if (data.containsKey('inputs_json')) {
      context.handle(
        _inputsJsonMeta,
        inputsJson.isAcceptableOrUnknown(data['inputs_json']!, _inputsJsonMeta),
      );
    }
    if (data.containsKey('legal_entities_json')) {
      context.handle(
        _legalEntitiesJsonMeta,
        legalEntitiesJson.isAcceptableOrUnknown(
          data['legal_entities_json']!,
          _legalEntitiesJsonMeta,
        ),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    tenantId,
    legalEntityId,
    currency,
    periodPreset,
    comparisonBaseline,
  };
  @override
  DssSnapshotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DssSnapshotRow(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      legalEntityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legal_entity_id'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      periodPreset: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period_preset'],
      )!,
      comparisonBaseline: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comparison_baseline'],
      )!,
      overviewJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overview_json'],
      )!,
      customersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customers_json'],
      )!,
      productsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}products_json'],
      ),
      varianceJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variance_json'],
      ),
      inputsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inputs_json'],
      ),
      legalEntitiesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legal_entities_json'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $DssExecutiveSnapshotsTable createAlias(String alias) {
    return $DssExecutiveSnapshotsTable(attachedDatabase, alias);
  }
}

class DssSnapshotRow extends DataClass implements Insertable<DssSnapshotRow> {
  final String tenantId;

  /// Server legal entity id; empty for the snapshot that spans every legal entity.
  final String legalEntityId;
  final String currency;
  final String periodPreset;
  final String comparisonBaseline;
  final String overviewJson;
  final String customersJson;
  final String? productsJson;
  final String? varianceJson;
  final String? inputsJson;
  final String? legalEntitiesJson;
  final DateTime syncedAt;
  const DssSnapshotRow({
    required this.tenantId,
    required this.legalEntityId,
    required this.currency,
    required this.periodPreset,
    required this.comparisonBaseline,
    required this.overviewJson,
    required this.customersJson,
    this.productsJson,
    this.varianceJson,
    this.inputsJson,
    this.legalEntitiesJson,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['legal_entity_id'] = Variable<String>(legalEntityId);
    map['currency'] = Variable<String>(currency);
    map['period_preset'] = Variable<String>(periodPreset);
    map['comparison_baseline'] = Variable<String>(comparisonBaseline);
    map['overview_json'] = Variable<String>(overviewJson);
    map['customers_json'] = Variable<String>(customersJson);
    if (!nullToAbsent || productsJson != null) {
      map['products_json'] = Variable<String>(productsJson);
    }
    if (!nullToAbsent || varianceJson != null) {
      map['variance_json'] = Variable<String>(varianceJson);
    }
    if (!nullToAbsent || inputsJson != null) {
      map['inputs_json'] = Variable<String>(inputsJson);
    }
    if (!nullToAbsent || legalEntitiesJson != null) {
      map['legal_entities_json'] = Variable<String>(legalEntitiesJson);
    }
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  DssExecutiveSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return DssExecutiveSnapshotsCompanion(
      tenantId: Value(tenantId),
      legalEntityId: Value(legalEntityId),
      currency: Value(currency),
      periodPreset: Value(periodPreset),
      comparisonBaseline: Value(comparisonBaseline),
      overviewJson: Value(overviewJson),
      customersJson: Value(customersJson),
      productsJson: productsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(productsJson),
      varianceJson: varianceJson == null && nullToAbsent
          ? const Value.absent()
          : Value(varianceJson),
      inputsJson: inputsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(inputsJson),
      legalEntitiesJson: legalEntitiesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(legalEntitiesJson),
      syncedAt: Value(syncedAt),
    );
  }

  factory DssSnapshotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DssSnapshotRow(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      legalEntityId: serializer.fromJson<String>(json['legalEntityId']),
      currency: serializer.fromJson<String>(json['currency']),
      periodPreset: serializer.fromJson<String>(json['periodPreset']),
      comparisonBaseline: serializer.fromJson<String>(
        json['comparisonBaseline'],
      ),
      overviewJson: serializer.fromJson<String>(json['overviewJson']),
      customersJson: serializer.fromJson<String>(json['customersJson']),
      productsJson: serializer.fromJson<String?>(json['productsJson']),
      varianceJson: serializer.fromJson<String?>(json['varianceJson']),
      inputsJson: serializer.fromJson<String?>(json['inputsJson']),
      legalEntitiesJson: serializer.fromJson<String?>(
        json['legalEntitiesJson'],
      ),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'legalEntityId': serializer.toJson<String>(legalEntityId),
      'currency': serializer.toJson<String>(currency),
      'periodPreset': serializer.toJson<String>(periodPreset),
      'comparisonBaseline': serializer.toJson<String>(comparisonBaseline),
      'overviewJson': serializer.toJson<String>(overviewJson),
      'customersJson': serializer.toJson<String>(customersJson),
      'productsJson': serializer.toJson<String?>(productsJson),
      'varianceJson': serializer.toJson<String?>(varianceJson),
      'inputsJson': serializer.toJson<String?>(inputsJson),
      'legalEntitiesJson': serializer.toJson<String?>(legalEntitiesJson),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  DssSnapshotRow copyWith({
    String? tenantId,
    String? legalEntityId,
    String? currency,
    String? periodPreset,
    String? comparisonBaseline,
    String? overviewJson,
    String? customersJson,
    Value<String?> productsJson = const Value.absent(),
    Value<String?> varianceJson = const Value.absent(),
    Value<String?> inputsJson = const Value.absent(),
    Value<String?> legalEntitiesJson = const Value.absent(),
    DateTime? syncedAt,
  }) => DssSnapshotRow(
    tenantId: tenantId ?? this.tenantId,
    legalEntityId: legalEntityId ?? this.legalEntityId,
    currency: currency ?? this.currency,
    periodPreset: periodPreset ?? this.periodPreset,
    comparisonBaseline: comparisonBaseline ?? this.comparisonBaseline,
    overviewJson: overviewJson ?? this.overviewJson,
    customersJson: customersJson ?? this.customersJson,
    productsJson: productsJson.present ? productsJson.value : this.productsJson,
    varianceJson: varianceJson.present ? varianceJson.value : this.varianceJson,
    inputsJson: inputsJson.present ? inputsJson.value : this.inputsJson,
    legalEntitiesJson: legalEntitiesJson.present
        ? legalEntitiesJson.value
        : this.legalEntitiesJson,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  DssSnapshotRow copyWithCompanion(DssExecutiveSnapshotsCompanion data) {
    return DssSnapshotRow(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      legalEntityId: data.legalEntityId.present
          ? data.legalEntityId.value
          : this.legalEntityId,
      currency: data.currency.present ? data.currency.value : this.currency,
      periodPreset: data.periodPreset.present
          ? data.periodPreset.value
          : this.periodPreset,
      comparisonBaseline: data.comparisonBaseline.present
          ? data.comparisonBaseline.value
          : this.comparisonBaseline,
      overviewJson: data.overviewJson.present
          ? data.overviewJson.value
          : this.overviewJson,
      customersJson: data.customersJson.present
          ? data.customersJson.value
          : this.customersJson,
      productsJson: data.productsJson.present
          ? data.productsJson.value
          : this.productsJson,
      varianceJson: data.varianceJson.present
          ? data.varianceJson.value
          : this.varianceJson,
      inputsJson: data.inputsJson.present
          ? data.inputsJson.value
          : this.inputsJson,
      legalEntitiesJson: data.legalEntitiesJson.present
          ? data.legalEntitiesJson.value
          : this.legalEntitiesJson,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DssSnapshotRow(')
          ..write('tenantId: $tenantId, ')
          ..write('legalEntityId: $legalEntityId, ')
          ..write('currency: $currency, ')
          ..write('periodPreset: $periodPreset, ')
          ..write('comparisonBaseline: $comparisonBaseline, ')
          ..write('overviewJson: $overviewJson, ')
          ..write('customersJson: $customersJson, ')
          ..write('productsJson: $productsJson, ')
          ..write('varianceJson: $varianceJson, ')
          ..write('inputsJson: $inputsJson, ')
          ..write('legalEntitiesJson: $legalEntitiesJson, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tenantId,
    legalEntityId,
    currency,
    periodPreset,
    comparisonBaseline,
    overviewJson,
    customersJson,
    productsJson,
    varianceJson,
    inputsJson,
    legalEntitiesJson,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DssSnapshotRow &&
          other.tenantId == this.tenantId &&
          other.legalEntityId == this.legalEntityId &&
          other.currency == this.currency &&
          other.periodPreset == this.periodPreset &&
          other.comparisonBaseline == this.comparisonBaseline &&
          other.overviewJson == this.overviewJson &&
          other.customersJson == this.customersJson &&
          other.productsJson == this.productsJson &&
          other.varianceJson == this.varianceJson &&
          other.inputsJson == this.inputsJson &&
          other.legalEntitiesJson == this.legalEntitiesJson &&
          other.syncedAt == this.syncedAt);
}

class DssExecutiveSnapshotsCompanion extends UpdateCompanion<DssSnapshotRow> {
  final Value<String> tenantId;
  final Value<String> legalEntityId;
  final Value<String> currency;
  final Value<String> periodPreset;
  final Value<String> comparisonBaseline;
  final Value<String> overviewJson;
  final Value<String> customersJson;
  final Value<String?> productsJson;
  final Value<String?> varianceJson;
  final Value<String?> inputsJson;
  final Value<String?> legalEntitiesJson;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const DssExecutiveSnapshotsCompanion({
    this.tenantId = const Value.absent(),
    this.legalEntityId = const Value.absent(),
    this.currency = const Value.absent(),
    this.periodPreset = const Value.absent(),
    this.comparisonBaseline = const Value.absent(),
    this.overviewJson = const Value.absent(),
    this.customersJson = const Value.absent(),
    this.productsJson = const Value.absent(),
    this.varianceJson = const Value.absent(),
    this.inputsJson = const Value.absent(),
    this.legalEntitiesJson = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DssExecutiveSnapshotsCompanion.insert({
    required String tenantId,
    this.legalEntityId = const Value.absent(),
    required String currency,
    required String periodPreset,
    required String comparisonBaseline,
    required String overviewJson,
    required String customersJson,
    this.productsJson = const Value.absent(),
    this.varianceJson = const Value.absent(),
    this.inputsJson = const Value.absent(),
    this.legalEntitiesJson = const Value.absent(),
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       currency = Value(currency),
       periodPreset = Value(periodPreset),
       comparisonBaseline = Value(comparisonBaseline),
       overviewJson = Value(overviewJson),
       customersJson = Value(customersJson),
       syncedAt = Value(syncedAt);
  static Insertable<DssSnapshotRow> custom({
    Expression<String>? tenantId,
    Expression<String>? legalEntityId,
    Expression<String>? currency,
    Expression<String>? periodPreset,
    Expression<String>? comparisonBaseline,
    Expression<String>? overviewJson,
    Expression<String>? customersJson,
    Expression<String>? productsJson,
    Expression<String>? varianceJson,
    Expression<String>? inputsJson,
    Expression<String>? legalEntitiesJson,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (legalEntityId != null) 'legal_entity_id': legalEntityId,
      if (currency != null) 'currency': currency,
      if (periodPreset != null) 'period_preset': periodPreset,
      if (comparisonBaseline != null) 'comparison_baseline': comparisonBaseline,
      if (overviewJson != null) 'overview_json': overviewJson,
      if (customersJson != null) 'customers_json': customersJson,
      if (productsJson != null) 'products_json': productsJson,
      if (varianceJson != null) 'variance_json': varianceJson,
      if (inputsJson != null) 'inputs_json': inputsJson,
      if (legalEntitiesJson != null) 'legal_entities_json': legalEntitiesJson,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DssExecutiveSnapshotsCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? legalEntityId,
    Value<String>? currency,
    Value<String>? periodPreset,
    Value<String>? comparisonBaseline,
    Value<String>? overviewJson,
    Value<String>? customersJson,
    Value<String?>? productsJson,
    Value<String?>? varianceJson,
    Value<String?>? inputsJson,
    Value<String?>? legalEntitiesJson,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return DssExecutiveSnapshotsCompanion(
      tenantId: tenantId ?? this.tenantId,
      legalEntityId: legalEntityId ?? this.legalEntityId,
      currency: currency ?? this.currency,
      periodPreset: periodPreset ?? this.periodPreset,
      comparisonBaseline: comparisonBaseline ?? this.comparisonBaseline,
      overviewJson: overviewJson ?? this.overviewJson,
      customersJson: customersJson ?? this.customersJson,
      productsJson: productsJson ?? this.productsJson,
      varianceJson: varianceJson ?? this.varianceJson,
      inputsJson: inputsJson ?? this.inputsJson,
      legalEntitiesJson: legalEntitiesJson ?? this.legalEntitiesJson,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (legalEntityId.present) {
      map['legal_entity_id'] = Variable<String>(legalEntityId.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (periodPreset.present) {
      map['period_preset'] = Variable<String>(periodPreset.value);
    }
    if (comparisonBaseline.present) {
      map['comparison_baseline'] = Variable<String>(comparisonBaseline.value);
    }
    if (overviewJson.present) {
      map['overview_json'] = Variable<String>(overviewJson.value);
    }
    if (customersJson.present) {
      map['customers_json'] = Variable<String>(customersJson.value);
    }
    if (productsJson.present) {
      map['products_json'] = Variable<String>(productsJson.value);
    }
    if (varianceJson.present) {
      map['variance_json'] = Variable<String>(varianceJson.value);
    }
    if (inputsJson.present) {
      map['inputs_json'] = Variable<String>(inputsJson.value);
    }
    if (legalEntitiesJson.present) {
      map['legal_entities_json'] = Variable<String>(legalEntitiesJson.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DssExecutiveSnapshotsCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('legalEntityId: $legalEntityId, ')
          ..write('currency: $currency, ')
          ..write('periodPreset: $periodPreset, ')
          ..write('comparisonBaseline: $comparisonBaseline, ')
          ..write('overviewJson: $overviewJson, ')
          ..write('customersJson: $customersJson, ')
          ..write('productsJson: $productsJson, ')
          ..write('varianceJson: $varianceJson, ')
          ..write('inputsJson: $inputsJson, ')
          ..write('legalEntitiesJson: $legalEntitiesJson, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PermissionSnapshotsTable extends PermissionSnapshots
    with TableInfo<$PermissionSnapshotsTable, PermissionSnapshotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PermissionSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revokedAtMeta = const VerificationMeta(
    'revokedAt',
  );
  @override
  late final GeneratedColumn<DateTime> revokedAt = GeneratedColumn<DateTime>(
    'revoked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    userId,
    companyId,
    payload,
    fetchedAt,
    revokedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'permission_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<PermissionSnapshotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('revoked_at')) {
      context.handle(
        _revokedAtMeta,
        revokedAt.isAcceptableOrUnknown(data['revoked_at']!, _revokedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, userId, companyId};
  @override
  PermissionSnapshotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PermissionSnapshotRow(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
      revokedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}revoked_at'],
      ),
    );
  }

  @override
  $PermissionSnapshotsTable createAlias(String alias) {
    return $PermissionSnapshotsTable(attachedDatabase, alias);
  }
}

class PermissionSnapshotRow extends DataClass
    implements Insertable<PermissionSnapshotRow> {
  final String tenantId;
  final String userId;
  final String companyId;
  final String payload;
  final DateTime fetchedAt;
  final DateTime? revokedAt;
  const PermissionSnapshotRow({
    required this.tenantId,
    required this.userId,
    required this.companyId,
    required this.payload,
    required this.fetchedAt,
    this.revokedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['user_id'] = Variable<String>(userId);
    map['company_id'] = Variable<String>(companyId);
    map['payload'] = Variable<String>(payload);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    if (!nullToAbsent || revokedAt != null) {
      map['revoked_at'] = Variable<DateTime>(revokedAt);
    }
    return map;
  }

  PermissionSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return PermissionSnapshotsCompanion(
      tenantId: Value(tenantId),
      userId: Value(userId),
      companyId: Value(companyId),
      payload: Value(payload),
      fetchedAt: Value(fetchedAt),
      revokedAt: revokedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(revokedAt),
    );
  }

  factory PermissionSnapshotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PermissionSnapshotRow(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      userId: serializer.fromJson<String>(json['userId']),
      companyId: serializer.fromJson<String>(json['companyId']),
      payload: serializer.fromJson<String>(json['payload']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      revokedAt: serializer.fromJson<DateTime?>(json['revokedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'userId': serializer.toJson<String>(userId),
      'companyId': serializer.toJson<String>(companyId),
      'payload': serializer.toJson<String>(payload),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'revokedAt': serializer.toJson<DateTime?>(revokedAt),
    };
  }

  PermissionSnapshotRow copyWith({
    String? tenantId,
    String? userId,
    String? companyId,
    String? payload,
    DateTime? fetchedAt,
    Value<DateTime?> revokedAt = const Value.absent(),
  }) => PermissionSnapshotRow(
    tenantId: tenantId ?? this.tenantId,
    userId: userId ?? this.userId,
    companyId: companyId ?? this.companyId,
    payload: payload ?? this.payload,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    revokedAt: revokedAt.present ? revokedAt.value : this.revokedAt,
  );
  PermissionSnapshotRow copyWithCompanion(PermissionSnapshotsCompanion data) {
    return PermissionSnapshotRow(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      userId: data.userId.present ? data.userId.value : this.userId,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      payload: data.payload.present ? data.payload.value : this.payload,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      revokedAt: data.revokedAt.present ? data.revokedAt.value : this.revokedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PermissionSnapshotRow(')
          ..write('tenantId: $tenantId, ')
          ..write('userId: $userId, ')
          ..write('companyId: $companyId, ')
          ..write('payload: $payload, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('revokedAt: $revokedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(tenantId, userId, companyId, payload, fetchedAt, revokedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PermissionSnapshotRow &&
          other.tenantId == this.tenantId &&
          other.userId == this.userId &&
          other.companyId == this.companyId &&
          other.payload == this.payload &&
          other.fetchedAt == this.fetchedAt &&
          other.revokedAt == this.revokedAt);
}

class PermissionSnapshotsCompanion
    extends UpdateCompanion<PermissionSnapshotRow> {
  final Value<String> tenantId;
  final Value<String> userId;
  final Value<String> companyId;
  final Value<String> payload;
  final Value<DateTime> fetchedAt;
  final Value<DateTime?> revokedAt;
  final Value<int> rowid;
  const PermissionSnapshotsCompanion({
    this.tenantId = const Value.absent(),
    this.userId = const Value.absent(),
    this.companyId = const Value.absent(),
    this.payload = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.revokedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PermissionSnapshotsCompanion.insert({
    required String tenantId,
    required String userId,
    this.companyId = const Value.absent(),
    required String payload,
    required DateTime fetchedAt,
    this.revokedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       userId = Value(userId),
       payload = Value(payload),
       fetchedAt = Value(fetchedAt);
  static Insertable<PermissionSnapshotRow> custom({
    Expression<String>? tenantId,
    Expression<String>? userId,
    Expression<String>? companyId,
    Expression<String>? payload,
    Expression<DateTime>? fetchedAt,
    Expression<DateTime>? revokedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (userId != null) 'user_id': userId,
      if (companyId != null) 'company_id': companyId,
      if (payload != null) 'payload': payload,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (revokedAt != null) 'revoked_at': revokedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PermissionSnapshotsCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? userId,
    Value<String>? companyId,
    Value<String>? payload,
    Value<DateTime>? fetchedAt,
    Value<DateTime?>? revokedAt,
    Value<int>? rowid,
  }) {
    return PermissionSnapshotsCompanion(
      tenantId: tenantId ?? this.tenantId,
      userId: userId ?? this.userId,
      companyId: companyId ?? this.companyId,
      payload: payload ?? this.payload,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      revokedAt: revokedAt ?? this.revokedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (revokedAt.present) {
      map['revoked_at'] = Variable<DateTime>(revokedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PermissionSnapshotsCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('userId: $userId, ')
          ..write('companyId: $companyId, ')
          ..write('payload: $payload, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('revokedAt: $revokedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPurchaseRequisitionsTable extends LocalPurchaseRequisitions
    with
        TableInfo<
          $LocalPurchaseRequisitionsTable,
          LocalPurchaseRequisitionRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPurchaseRequisitionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requisitionNumberMeta = const VerificationMeta(
    'requisitionNumber',
  );
  @override
  late final GeneratedColumn<String> requisitionNumber =
      GeneratedColumn<String>(
        'requisition_number',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _requesterIdMeta = const VerificationMeta(
    'requesterId',
  );
  @override
  late final GeneratedColumn<String> requesterId = GeneratedColumn<String>(
    'requester_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requesterNameMeta = const VerificationMeta(
    'requesterName',
  );
  @override
  late final GeneratedColumn<String> requesterName = GeneratedColumn<String>(
    'requester_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costCenterIdMeta = const VerificationMeta(
    'costCenterId',
  );
  @override
  late final GeneratedColumn<String> costCenterId = GeneratedColumn<String>(
    'cost_center_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costCenterCodeMeta = const VerificationMeta(
    'costCenterCode',
  );
  @override
  late final GeneratedColumn<String> costCenterCode = GeneratedColumn<String>(
    'cost_center_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costCenterNameMeta = const VerificationMeta(
    'costCenterName',
  );
  @override
  late final GeneratedColumn<String> costCenterName = GeneratedColumn<String>(
    'cost_center_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _projectCodeMeta = const VerificationMeta(
    'projectCode',
  );
  @override
  late final GeneratedColumn<String> projectCode = GeneratedColumn<String>(
    'project_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _projectNameMeta = const VerificationMeta(
    'projectName',
  );
  @override
  late final GeneratedColumn<String> projectName = GeneratedColumn<String>(
    'project_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urgencyMeta = const VerificationMeta(
    'urgency',
  );
  @override
  late final GeneratedColumn<String> urgency = GeneratedColumn<String>(
    'urgency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('normal'),
  );
  static const VerificationMeta _requestedDeliveryDateMeta =
      const VerificationMeta('requestedDeliveryDate');
  @override
  late final GeneratedColumn<DateTime> requestedDeliveryDate =
      GeneratedColumn<DateTime>(
        'requested_delivery_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _justificationMeta = const VerificationMeta(
    'justification',
  );
  @override
  late final GeneratedColumn<String> justification = GeneratedColumn<String>(
    'justification',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('CHF'),
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending_upload'),
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendingSubmitMeta = const VerificationMeta(
    'pendingSubmit',
  );
  @override
  late final GeneratedColumn<bool> pendingSubmit = GeneratedColumn<bool>(
    'pending_submit',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_submit" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _budgetCheckSnapshotJsonMeta =
      const VerificationMeta('budgetCheckSnapshotJson');
  @override
  late final GeneratedColumn<String> budgetCheckSnapshotJson =
      GeneratedColumn<String>(
        'budget_check_snapshot_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _approvalProgressJsonMeta =
      const VerificationMeta('approvalProgressJson');
  @override
  late final GeneratedColumn<String> approvalProgressJson =
      GeneratedColumn<String>(
        'approval_progress_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _linkedRdoIdMeta = const VerificationMeta(
    'linkedRdoId',
  );
  @override
  late final GeneratedColumn<String> linkedRdoId = GeneratedColumn<String>(
    'linked_rdo_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkedRdoNumberMeta = const VerificationMeta(
    'linkedRdoNumber',
  );
  @override
  late final GeneratedColumn<String> linkedRdoNumber = GeneratedColumn<String>(
    'linked_rdo_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkedPoIdMeta = const VerificationMeta(
    'linkedPoId',
  );
  @override
  late final GeneratedColumn<String> linkedPoId = GeneratedColumn<String>(
    'linked_po_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkedPoNumberMeta = const VerificationMeta(
    'linkedPoNumber',
  );
  @override
  late final GeneratedColumn<String> linkedPoNumber = GeneratedColumn<String>(
    'linked_po_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverUpdatedAt =
      GeneratedColumn<DateTime>(
        'server_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    remoteId,
    tenantId,
    requisitionNumber,
    requesterId,
    requesterName,
    costCenterId,
    costCenterCode,
    costCenterName,
    projectId,
    projectCode,
    projectName,
    urgency,
    requestedDeliveryDate,
    justification,
    currency,
    totalAmount,
    status,
    syncStatus,
    syncError,
    pendingSubmit,
    budgetCheckSnapshotJson,
    approvalProgressJson,
    linkedRdoId,
    linkedRdoNumber,
    linkedPoId,
    linkedPoNumber,
    createdAt,
    updatedAt,
    serverUpdatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_purchase_requisitions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalPurchaseRequisitionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('requisition_number')) {
      context.handle(
        _requisitionNumberMeta,
        requisitionNumber.isAcceptableOrUnknown(
          data['requisition_number']!,
          _requisitionNumberMeta,
        ),
      );
    }
    if (data.containsKey('requester_id')) {
      context.handle(
        _requesterIdMeta,
        requesterId.isAcceptableOrUnknown(
          data['requester_id']!,
          _requesterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requesterIdMeta);
    }
    if (data.containsKey('requester_name')) {
      context.handle(
        _requesterNameMeta,
        requesterName.isAcceptableOrUnknown(
          data['requester_name']!,
          _requesterNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requesterNameMeta);
    }
    if (data.containsKey('cost_center_id')) {
      context.handle(
        _costCenterIdMeta,
        costCenterId.isAcceptableOrUnknown(
          data['cost_center_id']!,
          _costCenterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_costCenterIdMeta);
    }
    if (data.containsKey('cost_center_code')) {
      context.handle(
        _costCenterCodeMeta,
        costCenterCode.isAcceptableOrUnknown(
          data['cost_center_code']!,
          _costCenterCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_costCenterCodeMeta);
    }
    if (data.containsKey('cost_center_name')) {
      context.handle(
        _costCenterNameMeta,
        costCenterName.isAcceptableOrUnknown(
          data['cost_center_name']!,
          _costCenterNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_costCenterNameMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('project_code')) {
      context.handle(
        _projectCodeMeta,
        projectCode.isAcceptableOrUnknown(
          data['project_code']!,
          _projectCodeMeta,
        ),
      );
    }
    if (data.containsKey('project_name')) {
      context.handle(
        _projectNameMeta,
        projectName.isAcceptableOrUnknown(
          data['project_name']!,
          _projectNameMeta,
        ),
      );
    }
    if (data.containsKey('urgency')) {
      context.handle(
        _urgencyMeta,
        urgency.isAcceptableOrUnknown(data['urgency']!, _urgencyMeta),
      );
    }
    if (data.containsKey('requested_delivery_date')) {
      context.handle(
        _requestedDeliveryDateMeta,
        requestedDeliveryDate.isAcceptableOrUnknown(
          data['requested_delivery_date']!,
          _requestedDeliveryDateMeta,
        ),
      );
    }
    if (data.containsKey('justification')) {
      context.handle(
        _justificationMeta,
        justification.isAcceptableOrUnknown(
          data['justification']!,
          _justificationMeta,
        ),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('pending_submit')) {
      context.handle(
        _pendingSubmitMeta,
        pendingSubmit.isAcceptableOrUnknown(
          data['pending_submit']!,
          _pendingSubmitMeta,
        ),
      );
    }
    if (data.containsKey('budget_check_snapshot_json')) {
      context.handle(
        _budgetCheckSnapshotJsonMeta,
        budgetCheckSnapshotJson.isAcceptableOrUnknown(
          data['budget_check_snapshot_json']!,
          _budgetCheckSnapshotJsonMeta,
        ),
      );
    }
    if (data.containsKey('approval_progress_json')) {
      context.handle(
        _approvalProgressJsonMeta,
        approvalProgressJson.isAcceptableOrUnknown(
          data['approval_progress_json']!,
          _approvalProgressJsonMeta,
        ),
      );
    }
    if (data.containsKey('linked_rdo_id')) {
      context.handle(
        _linkedRdoIdMeta,
        linkedRdoId.isAcceptableOrUnknown(
          data['linked_rdo_id']!,
          _linkedRdoIdMeta,
        ),
      );
    }
    if (data.containsKey('linked_rdo_number')) {
      context.handle(
        _linkedRdoNumberMeta,
        linkedRdoNumber.isAcceptableOrUnknown(
          data['linked_rdo_number']!,
          _linkedRdoNumberMeta,
        ),
      );
    }
    if (data.containsKey('linked_po_id')) {
      context.handle(
        _linkedPoIdMeta,
        linkedPoId.isAcceptableOrUnknown(
          data['linked_po_id']!,
          _linkedPoIdMeta,
        ),
      );
    }
    if (data.containsKey('linked_po_number')) {
      context.handle(
        _linkedPoNumberMeta,
        linkedPoNumber.isAcceptableOrUnknown(
          data['linked_po_number']!,
          _linkedPoNumberMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  LocalPurchaseRequisitionRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPurchaseRequisitionRow(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      requisitionNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}requisition_number'],
      ),
      requesterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}requester_id'],
      )!,
      requesterName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}requester_name'],
      )!,
      costCenterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cost_center_id'],
      )!,
      costCenterCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cost_center_code'],
      )!,
      costCenterName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cost_center_name'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      projectCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_code'],
      ),
      projectName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_name'],
      ),
      urgency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}urgency'],
      )!,
      requestedDeliveryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}requested_delivery_date'],
      ),
      justification: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}justification'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      pendingSubmit: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_submit'],
      )!,
      budgetCheckSnapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}budget_check_snapshot_json'],
      ),
      approvalProgressJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approval_progress_json'],
      ),
      linkedRdoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_rdo_id'],
      ),
      linkedRdoNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_rdo_number'],
      ),
      linkedPoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_po_id'],
      ),
      linkedPoNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_po_number'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $LocalPurchaseRequisitionsTable createAlias(String alias) {
    return $LocalPurchaseRequisitionsTable(attachedDatabase, alias);
  }
}

class LocalPurchaseRequisitionRow extends DataClass
    implements Insertable<LocalPurchaseRequisitionRow> {
  final String localId;
  final String? remoteId;
  final String tenantId;
  final String? requisitionNumber;
  final String requesterId;
  final String requesterName;
  final String costCenterId;
  final String costCenterCode;
  final String costCenterName;
  final String? projectId;
  final String? projectCode;
  final String? projectName;
  final String urgency;
  final DateTime? requestedDeliveryDate;
  final String justification;
  final String currency;
  final double totalAmount;
  final String status;

  /// `synced`, `pending_upload`, or `sync_error`.
  final String syncStatus;
  final String? syncError;
  final bool pendingSubmit;
  final String? budgetCheckSnapshotJson;
  final String? approvalProgressJson;
  final String? linkedRdoId;
  final String? linkedRdoNumber;
  final String? linkedPoId;
  final String? linkedPoNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? serverUpdatedAt;
  final DateTime? deletedAt;
  const LocalPurchaseRequisitionRow({
    required this.localId,
    this.remoteId,
    required this.tenantId,
    this.requisitionNumber,
    required this.requesterId,
    required this.requesterName,
    required this.costCenterId,
    required this.costCenterCode,
    required this.costCenterName,
    this.projectId,
    this.projectCode,
    this.projectName,
    required this.urgency,
    this.requestedDeliveryDate,
    required this.justification,
    required this.currency,
    required this.totalAmount,
    required this.status,
    required this.syncStatus,
    this.syncError,
    required this.pendingSubmit,
    this.budgetCheckSnapshotJson,
    this.approvalProgressJson,
    this.linkedRdoId,
    this.linkedRdoNumber,
    this.linkedPoId,
    this.linkedPoNumber,
    required this.createdAt,
    required this.updatedAt,
    this.serverUpdatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['tenant_id'] = Variable<String>(tenantId);
    if (!nullToAbsent || requisitionNumber != null) {
      map['requisition_number'] = Variable<String>(requisitionNumber);
    }
    map['requester_id'] = Variable<String>(requesterId);
    map['requester_name'] = Variable<String>(requesterName);
    map['cost_center_id'] = Variable<String>(costCenterId);
    map['cost_center_code'] = Variable<String>(costCenterCode);
    map['cost_center_name'] = Variable<String>(costCenterName);
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    if (!nullToAbsent || projectCode != null) {
      map['project_code'] = Variable<String>(projectCode);
    }
    if (!nullToAbsent || projectName != null) {
      map['project_name'] = Variable<String>(projectName);
    }
    map['urgency'] = Variable<String>(urgency);
    if (!nullToAbsent || requestedDeliveryDate != null) {
      map['requested_delivery_date'] = Variable<DateTime>(
        requestedDeliveryDate,
      );
    }
    map['justification'] = Variable<String>(justification);
    map['currency'] = Variable<String>(currency);
    map['total_amount'] = Variable<double>(totalAmount);
    map['status'] = Variable<String>(status);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['pending_submit'] = Variable<bool>(pendingSubmit);
    if (!nullToAbsent || budgetCheckSnapshotJson != null) {
      map['budget_check_snapshot_json'] = Variable<String>(
        budgetCheckSnapshotJson,
      );
    }
    if (!nullToAbsent || approvalProgressJson != null) {
      map['approval_progress_json'] = Variable<String>(approvalProgressJson);
    }
    if (!nullToAbsent || linkedRdoId != null) {
      map['linked_rdo_id'] = Variable<String>(linkedRdoId);
    }
    if (!nullToAbsent || linkedRdoNumber != null) {
      map['linked_rdo_number'] = Variable<String>(linkedRdoNumber);
    }
    if (!nullToAbsent || linkedPoId != null) {
      map['linked_po_id'] = Variable<String>(linkedPoId);
    }
    if (!nullToAbsent || linkedPoNumber != null) {
      map['linked_po_number'] = Variable<String>(linkedPoNumber);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  LocalPurchaseRequisitionsCompanion toCompanion(bool nullToAbsent) {
    return LocalPurchaseRequisitionsCompanion(
      localId: Value(localId),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      tenantId: Value(tenantId),
      requisitionNumber: requisitionNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(requisitionNumber),
      requesterId: Value(requesterId),
      requesterName: Value(requesterName),
      costCenterId: Value(costCenterId),
      costCenterCode: Value(costCenterCode),
      costCenterName: Value(costCenterName),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      projectCode: projectCode == null && nullToAbsent
          ? const Value.absent()
          : Value(projectCode),
      projectName: projectName == null && nullToAbsent
          ? const Value.absent()
          : Value(projectName),
      urgency: Value(urgency),
      requestedDeliveryDate: requestedDeliveryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(requestedDeliveryDate),
      justification: Value(justification),
      currency: Value(currency),
      totalAmount: Value(totalAmount),
      status: Value(status),
      syncStatus: Value(syncStatus),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      pendingSubmit: Value(pendingSubmit),
      budgetCheckSnapshotJson: budgetCheckSnapshotJson == null && nullToAbsent
          ? const Value.absent()
          : Value(budgetCheckSnapshotJson),
      approvalProgressJson: approvalProgressJson == null && nullToAbsent
          ? const Value.absent()
          : Value(approvalProgressJson),
      linkedRdoId: linkedRdoId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedRdoId),
      linkedRdoNumber: linkedRdoNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedRdoNumber),
      linkedPoId: linkedPoId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedPoId),
      linkedPoNumber: linkedPoNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedPoNumber),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory LocalPurchaseRequisitionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPurchaseRequisitionRow(
      localId: serializer.fromJson<String>(json['localId']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      requisitionNumber: serializer.fromJson<String?>(
        json['requisitionNumber'],
      ),
      requesterId: serializer.fromJson<String>(json['requesterId']),
      requesterName: serializer.fromJson<String>(json['requesterName']),
      costCenterId: serializer.fromJson<String>(json['costCenterId']),
      costCenterCode: serializer.fromJson<String>(json['costCenterCode']),
      costCenterName: serializer.fromJson<String>(json['costCenterName']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      projectCode: serializer.fromJson<String?>(json['projectCode']),
      projectName: serializer.fromJson<String?>(json['projectName']),
      urgency: serializer.fromJson<String>(json['urgency']),
      requestedDeliveryDate: serializer.fromJson<DateTime?>(
        json['requestedDeliveryDate'],
      ),
      justification: serializer.fromJson<String>(json['justification']),
      currency: serializer.fromJson<String>(json['currency']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      status: serializer.fromJson<String>(json['status']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      pendingSubmit: serializer.fromJson<bool>(json['pendingSubmit']),
      budgetCheckSnapshotJson: serializer.fromJson<String?>(
        json['budgetCheckSnapshotJson'],
      ),
      approvalProgressJson: serializer.fromJson<String?>(
        json['approvalProgressJson'],
      ),
      linkedRdoId: serializer.fromJson<String?>(json['linkedRdoId']),
      linkedRdoNumber: serializer.fromJson<String?>(json['linkedRdoNumber']),
      linkedPoId: serializer.fromJson<String?>(json['linkedPoId']),
      linkedPoNumber: serializer.fromJson<String?>(json['linkedPoNumber']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      serverUpdatedAt: serializer.fromJson<DateTime?>(json['serverUpdatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'remoteId': serializer.toJson<String?>(remoteId),
      'tenantId': serializer.toJson<String>(tenantId),
      'requisitionNumber': serializer.toJson<String?>(requisitionNumber),
      'requesterId': serializer.toJson<String>(requesterId),
      'requesterName': serializer.toJson<String>(requesterName),
      'costCenterId': serializer.toJson<String>(costCenterId),
      'costCenterCode': serializer.toJson<String>(costCenterCode),
      'costCenterName': serializer.toJson<String>(costCenterName),
      'projectId': serializer.toJson<String?>(projectId),
      'projectCode': serializer.toJson<String?>(projectCode),
      'projectName': serializer.toJson<String?>(projectName),
      'urgency': serializer.toJson<String>(urgency),
      'requestedDeliveryDate': serializer.toJson<DateTime?>(
        requestedDeliveryDate,
      ),
      'justification': serializer.toJson<String>(justification),
      'currency': serializer.toJson<String>(currency),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'status': serializer.toJson<String>(status),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'syncError': serializer.toJson<String?>(syncError),
      'pendingSubmit': serializer.toJson<bool>(pendingSubmit),
      'budgetCheckSnapshotJson': serializer.toJson<String?>(
        budgetCheckSnapshotJson,
      ),
      'approvalProgressJson': serializer.toJson<String?>(approvalProgressJson),
      'linkedRdoId': serializer.toJson<String?>(linkedRdoId),
      'linkedRdoNumber': serializer.toJson<String?>(linkedRdoNumber),
      'linkedPoId': serializer.toJson<String?>(linkedPoId),
      'linkedPoNumber': serializer.toJson<String?>(linkedPoNumber),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'serverUpdatedAt': serializer.toJson<DateTime?>(serverUpdatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  LocalPurchaseRequisitionRow copyWith({
    String? localId,
    Value<String?> remoteId = const Value.absent(),
    String? tenantId,
    Value<String?> requisitionNumber = const Value.absent(),
    String? requesterId,
    String? requesterName,
    String? costCenterId,
    String? costCenterCode,
    String? costCenterName,
    Value<String?> projectId = const Value.absent(),
    Value<String?> projectCode = const Value.absent(),
    Value<String?> projectName = const Value.absent(),
    String? urgency,
    Value<DateTime?> requestedDeliveryDate = const Value.absent(),
    String? justification,
    String? currency,
    double? totalAmount,
    String? status,
    String? syncStatus,
    Value<String?> syncError = const Value.absent(),
    bool? pendingSubmit,
    Value<String?> budgetCheckSnapshotJson = const Value.absent(),
    Value<String?> approvalProgressJson = const Value.absent(),
    Value<String?> linkedRdoId = const Value.absent(),
    Value<String?> linkedRdoNumber = const Value.absent(),
    Value<String?> linkedPoId = const Value.absent(),
    Value<String?> linkedPoNumber = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> serverUpdatedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => LocalPurchaseRequisitionRow(
    localId: localId ?? this.localId,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    tenantId: tenantId ?? this.tenantId,
    requisitionNumber: requisitionNumber.present
        ? requisitionNumber.value
        : this.requisitionNumber,
    requesterId: requesterId ?? this.requesterId,
    requesterName: requesterName ?? this.requesterName,
    costCenterId: costCenterId ?? this.costCenterId,
    costCenterCode: costCenterCode ?? this.costCenterCode,
    costCenterName: costCenterName ?? this.costCenterName,
    projectId: projectId.present ? projectId.value : this.projectId,
    projectCode: projectCode.present ? projectCode.value : this.projectCode,
    projectName: projectName.present ? projectName.value : this.projectName,
    urgency: urgency ?? this.urgency,
    requestedDeliveryDate: requestedDeliveryDate.present
        ? requestedDeliveryDate.value
        : this.requestedDeliveryDate,
    justification: justification ?? this.justification,
    currency: currency ?? this.currency,
    totalAmount: totalAmount ?? this.totalAmount,
    status: status ?? this.status,
    syncStatus: syncStatus ?? this.syncStatus,
    syncError: syncError.present ? syncError.value : this.syncError,
    pendingSubmit: pendingSubmit ?? this.pendingSubmit,
    budgetCheckSnapshotJson: budgetCheckSnapshotJson.present
        ? budgetCheckSnapshotJson.value
        : this.budgetCheckSnapshotJson,
    approvalProgressJson: approvalProgressJson.present
        ? approvalProgressJson.value
        : this.approvalProgressJson,
    linkedRdoId: linkedRdoId.present ? linkedRdoId.value : this.linkedRdoId,
    linkedRdoNumber: linkedRdoNumber.present
        ? linkedRdoNumber.value
        : this.linkedRdoNumber,
    linkedPoId: linkedPoId.present ? linkedPoId.value : this.linkedPoId,
    linkedPoNumber: linkedPoNumber.present
        ? linkedPoNumber.value
        : this.linkedPoNumber,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  LocalPurchaseRequisitionRow copyWithCompanion(
    LocalPurchaseRequisitionsCompanion data,
  ) {
    return LocalPurchaseRequisitionRow(
      localId: data.localId.present ? data.localId.value : this.localId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      requisitionNumber: data.requisitionNumber.present
          ? data.requisitionNumber.value
          : this.requisitionNumber,
      requesterId: data.requesterId.present
          ? data.requesterId.value
          : this.requesterId,
      requesterName: data.requesterName.present
          ? data.requesterName.value
          : this.requesterName,
      costCenterId: data.costCenterId.present
          ? data.costCenterId.value
          : this.costCenterId,
      costCenterCode: data.costCenterCode.present
          ? data.costCenterCode.value
          : this.costCenterCode,
      costCenterName: data.costCenterName.present
          ? data.costCenterName.value
          : this.costCenterName,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      projectCode: data.projectCode.present
          ? data.projectCode.value
          : this.projectCode,
      projectName: data.projectName.present
          ? data.projectName.value
          : this.projectName,
      urgency: data.urgency.present ? data.urgency.value : this.urgency,
      requestedDeliveryDate: data.requestedDeliveryDate.present
          ? data.requestedDeliveryDate.value
          : this.requestedDeliveryDate,
      justification: data.justification.present
          ? data.justification.value
          : this.justification,
      currency: data.currency.present ? data.currency.value : this.currency,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      status: data.status.present ? data.status.value : this.status,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      pendingSubmit: data.pendingSubmit.present
          ? data.pendingSubmit.value
          : this.pendingSubmit,
      budgetCheckSnapshotJson: data.budgetCheckSnapshotJson.present
          ? data.budgetCheckSnapshotJson.value
          : this.budgetCheckSnapshotJson,
      approvalProgressJson: data.approvalProgressJson.present
          ? data.approvalProgressJson.value
          : this.approvalProgressJson,
      linkedRdoId: data.linkedRdoId.present
          ? data.linkedRdoId.value
          : this.linkedRdoId,
      linkedRdoNumber: data.linkedRdoNumber.present
          ? data.linkedRdoNumber.value
          : this.linkedRdoNumber,
      linkedPoId: data.linkedPoId.present
          ? data.linkedPoId.value
          : this.linkedPoId,
      linkedPoNumber: data.linkedPoNumber.present
          ? data.linkedPoNumber.value
          : this.linkedPoNumber,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPurchaseRequisitionRow(')
          ..write('localId: $localId, ')
          ..write('remoteId: $remoteId, ')
          ..write('tenantId: $tenantId, ')
          ..write('requisitionNumber: $requisitionNumber, ')
          ..write('requesterId: $requesterId, ')
          ..write('requesterName: $requesterName, ')
          ..write('costCenterId: $costCenterId, ')
          ..write('costCenterCode: $costCenterCode, ')
          ..write('costCenterName: $costCenterName, ')
          ..write('projectId: $projectId, ')
          ..write('projectCode: $projectCode, ')
          ..write('projectName: $projectName, ')
          ..write('urgency: $urgency, ')
          ..write('requestedDeliveryDate: $requestedDeliveryDate, ')
          ..write('justification: $justification, ')
          ..write('currency: $currency, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('status: $status, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('pendingSubmit: $pendingSubmit, ')
          ..write('budgetCheckSnapshotJson: $budgetCheckSnapshotJson, ')
          ..write('approvalProgressJson: $approvalProgressJson, ')
          ..write('linkedRdoId: $linkedRdoId, ')
          ..write('linkedRdoNumber: $linkedRdoNumber, ')
          ..write('linkedPoId: $linkedPoId, ')
          ..write('linkedPoNumber: $linkedPoNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    localId,
    remoteId,
    tenantId,
    requisitionNumber,
    requesterId,
    requesterName,
    costCenterId,
    costCenterCode,
    costCenterName,
    projectId,
    projectCode,
    projectName,
    urgency,
    requestedDeliveryDate,
    justification,
    currency,
    totalAmount,
    status,
    syncStatus,
    syncError,
    pendingSubmit,
    budgetCheckSnapshotJson,
    approvalProgressJson,
    linkedRdoId,
    linkedRdoNumber,
    linkedPoId,
    linkedPoNumber,
    createdAt,
    updatedAt,
    serverUpdatedAt,
    deletedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPurchaseRequisitionRow &&
          other.localId == this.localId &&
          other.remoteId == this.remoteId &&
          other.tenantId == this.tenantId &&
          other.requisitionNumber == this.requisitionNumber &&
          other.requesterId == this.requesterId &&
          other.requesterName == this.requesterName &&
          other.costCenterId == this.costCenterId &&
          other.costCenterCode == this.costCenterCode &&
          other.costCenterName == this.costCenterName &&
          other.projectId == this.projectId &&
          other.projectCode == this.projectCode &&
          other.projectName == this.projectName &&
          other.urgency == this.urgency &&
          other.requestedDeliveryDate == this.requestedDeliveryDate &&
          other.justification == this.justification &&
          other.currency == this.currency &&
          other.totalAmount == this.totalAmount &&
          other.status == this.status &&
          other.syncStatus == this.syncStatus &&
          other.syncError == this.syncError &&
          other.pendingSubmit == this.pendingSubmit &&
          other.budgetCheckSnapshotJson == this.budgetCheckSnapshotJson &&
          other.approvalProgressJson == this.approvalProgressJson &&
          other.linkedRdoId == this.linkedRdoId &&
          other.linkedRdoNumber == this.linkedRdoNumber &&
          other.linkedPoId == this.linkedPoId &&
          other.linkedPoNumber == this.linkedPoNumber &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.deletedAt == this.deletedAt);
}

class LocalPurchaseRequisitionsCompanion
    extends UpdateCompanion<LocalPurchaseRequisitionRow> {
  final Value<String> localId;
  final Value<String?> remoteId;
  final Value<String> tenantId;
  final Value<String?> requisitionNumber;
  final Value<String> requesterId;
  final Value<String> requesterName;
  final Value<String> costCenterId;
  final Value<String> costCenterCode;
  final Value<String> costCenterName;
  final Value<String?> projectId;
  final Value<String?> projectCode;
  final Value<String?> projectName;
  final Value<String> urgency;
  final Value<DateTime?> requestedDeliveryDate;
  final Value<String> justification;
  final Value<String> currency;
  final Value<double> totalAmount;
  final Value<String> status;
  final Value<String> syncStatus;
  final Value<String?> syncError;
  final Value<bool> pendingSubmit;
  final Value<String?> budgetCheckSnapshotJson;
  final Value<String?> approvalProgressJson;
  final Value<String?> linkedRdoId;
  final Value<String?> linkedRdoNumber;
  final Value<String?> linkedPoId;
  final Value<String?> linkedPoNumber;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> serverUpdatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const LocalPurchaseRequisitionsCompanion({
    this.localId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.requisitionNumber = const Value.absent(),
    this.requesterId = const Value.absent(),
    this.requesterName = const Value.absent(),
    this.costCenterId = const Value.absent(),
    this.costCenterCode = const Value.absent(),
    this.costCenterName = const Value.absent(),
    this.projectId = const Value.absent(),
    this.projectCode = const Value.absent(),
    this.projectName = const Value.absent(),
    this.urgency = const Value.absent(),
    this.requestedDeliveryDate = const Value.absent(),
    this.justification = const Value.absent(),
    this.currency = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.status = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.pendingSubmit = const Value.absent(),
    this.budgetCheckSnapshotJson = const Value.absent(),
    this.approvalProgressJson = const Value.absent(),
    this.linkedRdoId = const Value.absent(),
    this.linkedRdoNumber = const Value.absent(),
    this.linkedPoId = const Value.absent(),
    this.linkedPoNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPurchaseRequisitionsCompanion.insert({
    required String localId,
    this.remoteId = const Value.absent(),
    required String tenantId,
    this.requisitionNumber = const Value.absent(),
    required String requesterId,
    required String requesterName,
    required String costCenterId,
    required String costCenterCode,
    required String costCenterName,
    this.projectId = const Value.absent(),
    this.projectCode = const Value.absent(),
    this.projectName = const Value.absent(),
    this.urgency = const Value.absent(),
    this.requestedDeliveryDate = const Value.absent(),
    this.justification = const Value.absent(),
    this.currency = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.status = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.pendingSubmit = const Value.absent(),
    this.budgetCheckSnapshotJson = const Value.absent(),
    this.approvalProgressJson = const Value.absent(),
    this.linkedRdoId = const Value.absent(),
    this.linkedRdoNumber = const Value.absent(),
    this.linkedPoId = const Value.absent(),
    this.linkedPoNumber = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.serverUpdatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       tenantId = Value(tenantId),
       requesterId = Value(requesterId),
       requesterName = Value(requesterName),
       costCenterId = Value(costCenterId),
       costCenterCode = Value(costCenterCode),
       costCenterName = Value(costCenterName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalPurchaseRequisitionRow> custom({
    Expression<String>? localId,
    Expression<String>? remoteId,
    Expression<String>? tenantId,
    Expression<String>? requisitionNumber,
    Expression<String>? requesterId,
    Expression<String>? requesterName,
    Expression<String>? costCenterId,
    Expression<String>? costCenterCode,
    Expression<String>? costCenterName,
    Expression<String>? projectId,
    Expression<String>? projectCode,
    Expression<String>? projectName,
    Expression<String>? urgency,
    Expression<DateTime>? requestedDeliveryDate,
    Expression<String>? justification,
    Expression<String>? currency,
    Expression<double>? totalAmount,
    Expression<String>? status,
    Expression<String>? syncStatus,
    Expression<String>? syncError,
    Expression<bool>? pendingSubmit,
    Expression<String>? budgetCheckSnapshotJson,
    Expression<String>? approvalProgressJson,
    Expression<String>? linkedRdoId,
    Expression<String>? linkedRdoNumber,
    Expression<String>? linkedPoId,
    Expression<String>? linkedPoNumber,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? serverUpdatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (remoteId != null) 'remote_id': remoteId,
      if (tenantId != null) 'tenant_id': tenantId,
      if (requisitionNumber != null) 'requisition_number': requisitionNumber,
      if (requesterId != null) 'requester_id': requesterId,
      if (requesterName != null) 'requester_name': requesterName,
      if (costCenterId != null) 'cost_center_id': costCenterId,
      if (costCenterCode != null) 'cost_center_code': costCenterCode,
      if (costCenterName != null) 'cost_center_name': costCenterName,
      if (projectId != null) 'project_id': projectId,
      if (projectCode != null) 'project_code': projectCode,
      if (projectName != null) 'project_name': projectName,
      if (urgency != null) 'urgency': urgency,
      if (requestedDeliveryDate != null)
        'requested_delivery_date': requestedDeliveryDate,
      if (justification != null) 'justification': justification,
      if (currency != null) 'currency': currency,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (status != null) 'status': status,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncError != null) 'sync_error': syncError,
      if (pendingSubmit != null) 'pending_submit': pendingSubmit,
      if (budgetCheckSnapshotJson != null)
        'budget_check_snapshot_json': budgetCheckSnapshotJson,
      if (approvalProgressJson != null)
        'approval_progress_json': approvalProgressJson,
      if (linkedRdoId != null) 'linked_rdo_id': linkedRdoId,
      if (linkedRdoNumber != null) 'linked_rdo_number': linkedRdoNumber,
      if (linkedPoId != null) 'linked_po_id': linkedPoId,
      if (linkedPoNumber != null) 'linked_po_number': linkedPoNumber,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPurchaseRequisitionsCompanion copyWith({
    Value<String>? localId,
    Value<String?>? remoteId,
    Value<String>? tenantId,
    Value<String?>? requisitionNumber,
    Value<String>? requesterId,
    Value<String>? requesterName,
    Value<String>? costCenterId,
    Value<String>? costCenterCode,
    Value<String>? costCenterName,
    Value<String?>? projectId,
    Value<String?>? projectCode,
    Value<String?>? projectName,
    Value<String>? urgency,
    Value<DateTime?>? requestedDeliveryDate,
    Value<String>? justification,
    Value<String>? currency,
    Value<double>? totalAmount,
    Value<String>? status,
    Value<String>? syncStatus,
    Value<String?>? syncError,
    Value<bool>? pendingSubmit,
    Value<String?>? budgetCheckSnapshotJson,
    Value<String?>? approvalProgressJson,
    Value<String?>? linkedRdoId,
    Value<String?>? linkedRdoNumber,
    Value<String?>? linkedPoId,
    Value<String?>? linkedPoNumber,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? serverUpdatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return LocalPurchaseRequisitionsCompanion(
      localId: localId ?? this.localId,
      remoteId: remoteId ?? this.remoteId,
      tenantId: tenantId ?? this.tenantId,
      requisitionNumber: requisitionNumber ?? this.requisitionNumber,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      costCenterId: costCenterId ?? this.costCenterId,
      costCenterCode: costCenterCode ?? this.costCenterCode,
      costCenterName: costCenterName ?? this.costCenterName,
      projectId: projectId ?? this.projectId,
      projectCode: projectCode ?? this.projectCode,
      projectName: projectName ?? this.projectName,
      urgency: urgency ?? this.urgency,
      requestedDeliveryDate:
          requestedDeliveryDate ?? this.requestedDeliveryDate,
      justification: justification ?? this.justification,
      currency: currency ?? this.currency,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
      pendingSubmit: pendingSubmit ?? this.pendingSubmit,
      budgetCheckSnapshotJson:
          budgetCheckSnapshotJson ?? this.budgetCheckSnapshotJson,
      approvalProgressJson: approvalProgressJson ?? this.approvalProgressJson,
      linkedRdoId: linkedRdoId ?? this.linkedRdoId,
      linkedRdoNumber: linkedRdoNumber ?? this.linkedRdoNumber,
      linkedPoId: linkedPoId ?? this.linkedPoId,
      linkedPoNumber: linkedPoNumber ?? this.linkedPoNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (requisitionNumber.present) {
      map['requisition_number'] = Variable<String>(requisitionNumber.value);
    }
    if (requesterId.present) {
      map['requester_id'] = Variable<String>(requesterId.value);
    }
    if (requesterName.present) {
      map['requester_name'] = Variable<String>(requesterName.value);
    }
    if (costCenterId.present) {
      map['cost_center_id'] = Variable<String>(costCenterId.value);
    }
    if (costCenterCode.present) {
      map['cost_center_code'] = Variable<String>(costCenterCode.value);
    }
    if (costCenterName.present) {
      map['cost_center_name'] = Variable<String>(costCenterName.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (projectCode.present) {
      map['project_code'] = Variable<String>(projectCode.value);
    }
    if (projectName.present) {
      map['project_name'] = Variable<String>(projectName.value);
    }
    if (urgency.present) {
      map['urgency'] = Variable<String>(urgency.value);
    }
    if (requestedDeliveryDate.present) {
      map['requested_delivery_date'] = Variable<DateTime>(
        requestedDeliveryDate.value,
      );
    }
    if (justification.present) {
      map['justification'] = Variable<String>(justification.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (pendingSubmit.present) {
      map['pending_submit'] = Variable<bool>(pendingSubmit.value);
    }
    if (budgetCheckSnapshotJson.present) {
      map['budget_check_snapshot_json'] = Variable<String>(
        budgetCheckSnapshotJson.value,
      );
    }
    if (approvalProgressJson.present) {
      map['approval_progress_json'] = Variable<String>(
        approvalProgressJson.value,
      );
    }
    if (linkedRdoId.present) {
      map['linked_rdo_id'] = Variable<String>(linkedRdoId.value);
    }
    if (linkedRdoNumber.present) {
      map['linked_rdo_number'] = Variable<String>(linkedRdoNumber.value);
    }
    if (linkedPoId.present) {
      map['linked_po_id'] = Variable<String>(linkedPoId.value);
    }
    if (linkedPoNumber.present) {
      map['linked_po_number'] = Variable<String>(linkedPoNumber.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPurchaseRequisitionsCompanion(')
          ..write('localId: $localId, ')
          ..write('remoteId: $remoteId, ')
          ..write('tenantId: $tenantId, ')
          ..write('requisitionNumber: $requisitionNumber, ')
          ..write('requesterId: $requesterId, ')
          ..write('requesterName: $requesterName, ')
          ..write('costCenterId: $costCenterId, ')
          ..write('costCenterCode: $costCenterCode, ')
          ..write('costCenterName: $costCenterName, ')
          ..write('projectId: $projectId, ')
          ..write('projectCode: $projectCode, ')
          ..write('projectName: $projectName, ')
          ..write('urgency: $urgency, ')
          ..write('requestedDeliveryDate: $requestedDeliveryDate, ')
          ..write('justification: $justification, ')
          ..write('currency: $currency, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('status: $status, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('pendingSubmit: $pendingSubmit, ')
          ..write('budgetCheckSnapshotJson: $budgetCheckSnapshotJson, ')
          ..write('approvalProgressJson: $approvalProgressJson, ')
          ..write('linkedRdoId: $linkedRdoId, ')
          ..write('linkedRdoNumber: $linkedRdoNumber, ')
          ..write('linkedPoId: $linkedPoId, ')
          ..write('linkedPoNumber: $linkedPoNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPurchaseRequisitionLinesTable extends LocalPurchaseRequisitionLines
    with
        TableInfo<
          $LocalPurchaseRequisitionLinesTable,
          LocalPurchaseRequisitionLineRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPurchaseRequisitionLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requisitionLocalIdMeta =
      const VerificationMeta('requisitionLocalId');
  @override
  late final GeneratedColumn<String> requisitionLocalId =
      GeneratedColumn<String>(
        'requisition_local_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES local_purchase_requisitions (local_id) ON DELETE CASCADE',
        ),
      );
  static const VerificationMeta _lineNumberMeta = const VerificationMeta(
    'lineNumber',
  );
  @override
  late final GeneratedColumn<int> lineNumber = GeneratedColumn<int>(
    'line_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemTypeMeta = const VerificationMeta(
    'itemType',
  );
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
    'item_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('free_text'),
  );
  static const VerificationMeta _catalogItemIdMeta = const VerificationMeta(
    'catalogItemId',
  );
  @override
  late final GeneratedColumn<String> catalogItemId = GeneratedColumn<String>(
    'catalog_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _catalogSkuMeta = const VerificationMeta(
    'catalogSku',
  );
  @override
  late final GeneratedColumn<String> catalogSku = GeneratedColumn<String>(
    'catalog_sku',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uomMeta = const VerificationMeta('uom');
  @override
  late final GeneratedColumn<String> uom = GeneratedColumn<String>(
    'uom',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pz'),
  );
  static const VerificationMeta _lineTotalMeta = const VerificationMeta(
    'lineTotal',
  );
  @override
  late final GeneratedColumn<double> lineTotal = GeneratedColumn<double>(
    'line_total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    remoteId,
    tenantId,
    requisitionLocalId,
    lineNumber,
    itemType,
    catalogItemId,
    catalogSku,
    description,
    quantity,
    unitPrice,
    uom,
    lineTotal,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_purchase_requisition_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalPurchaseRequisitionLineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('requisition_local_id')) {
      context.handle(
        _requisitionLocalIdMeta,
        requisitionLocalId.isAcceptableOrUnknown(
          data['requisition_local_id']!,
          _requisitionLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requisitionLocalIdMeta);
    }
    if (data.containsKey('line_number')) {
      context.handle(
        _lineNumberMeta,
        lineNumber.isAcceptableOrUnknown(data['line_number']!, _lineNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_lineNumberMeta);
    }
    if (data.containsKey('item_type')) {
      context.handle(
        _itemTypeMeta,
        itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta),
      );
    }
    if (data.containsKey('catalog_item_id')) {
      context.handle(
        _catalogItemIdMeta,
        catalogItemId.isAcceptableOrUnknown(
          data['catalog_item_id']!,
          _catalogItemIdMeta,
        ),
      );
    }
    if (data.containsKey('catalog_sku')) {
      context.handle(
        _catalogSkuMeta,
        catalogSku.isAcceptableOrUnknown(data['catalog_sku']!, _catalogSkuMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('uom')) {
      context.handle(
        _uomMeta,
        uom.isAcceptableOrUnknown(data['uom']!, _uomMeta),
      );
    }
    if (data.containsKey('line_total')) {
      context.handle(
        _lineTotalMeta,
        lineTotal.isAcceptableOrUnknown(data['line_total']!, _lineTotalMeta),
      );
    } else if (isInserting) {
      context.missing(_lineTotalMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  LocalPurchaseRequisitionLineRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPurchaseRequisitionLineRow(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      requisitionLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}requisition_local_id'],
      )!,
      lineNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_number'],
      )!,
      itemType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_type'],
      )!,
      catalogItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catalog_item_id'],
      ),
      catalogSku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catalog_sku'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_price'],
      )!,
      uom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uom'],
      )!,
      lineTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}line_total'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $LocalPurchaseRequisitionLinesTable createAlias(String alias) {
    return $LocalPurchaseRequisitionLinesTable(attachedDatabase, alias);
  }
}

class LocalPurchaseRequisitionLineRow extends DataClass
    implements Insertable<LocalPurchaseRequisitionLineRow> {
  final String localId;
  final String? remoteId;
  final String tenantId;
  final String requisitionLocalId;
  final int lineNumber;

  /// `catalog_item` or `free_text`.
  final String itemType;
  final String? catalogItemId;
  final String? catalogSku;
  final String description;
  final double quantity;
  final double unitPrice;
  final String uom;
  final double lineTotal;
  final String? notes;
  const LocalPurchaseRequisitionLineRow({
    required this.localId,
    this.remoteId,
    required this.tenantId,
    required this.requisitionLocalId,
    required this.lineNumber,
    required this.itemType,
    this.catalogItemId,
    this.catalogSku,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.uom,
    required this.lineTotal,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['tenant_id'] = Variable<String>(tenantId);
    map['requisition_local_id'] = Variable<String>(requisitionLocalId);
    map['line_number'] = Variable<int>(lineNumber);
    map['item_type'] = Variable<String>(itemType);
    if (!nullToAbsent || catalogItemId != null) {
      map['catalog_item_id'] = Variable<String>(catalogItemId);
    }
    if (!nullToAbsent || catalogSku != null) {
      map['catalog_sku'] = Variable<String>(catalogSku);
    }
    map['description'] = Variable<String>(description);
    map['quantity'] = Variable<double>(quantity);
    map['unit_price'] = Variable<double>(unitPrice);
    map['uom'] = Variable<String>(uom);
    map['line_total'] = Variable<double>(lineTotal);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  LocalPurchaseRequisitionLinesCompanion toCompanion(bool nullToAbsent) {
    return LocalPurchaseRequisitionLinesCompanion(
      localId: Value(localId),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      tenantId: Value(tenantId),
      requisitionLocalId: Value(requisitionLocalId),
      lineNumber: Value(lineNumber),
      itemType: Value(itemType),
      catalogItemId: catalogItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(catalogItemId),
      catalogSku: catalogSku == null && nullToAbsent
          ? const Value.absent()
          : Value(catalogSku),
      description: Value(description),
      quantity: Value(quantity),
      unitPrice: Value(unitPrice),
      uom: Value(uom),
      lineTotal: Value(lineTotal),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory LocalPurchaseRequisitionLineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPurchaseRequisitionLineRow(
      localId: serializer.fromJson<String>(json['localId']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      requisitionLocalId: serializer.fromJson<String>(
        json['requisitionLocalId'],
      ),
      lineNumber: serializer.fromJson<int>(json['lineNumber']),
      itemType: serializer.fromJson<String>(json['itemType']),
      catalogItemId: serializer.fromJson<String?>(json['catalogItemId']),
      catalogSku: serializer.fromJson<String?>(json['catalogSku']),
      description: serializer.fromJson<String>(json['description']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      uom: serializer.fromJson<String>(json['uom']),
      lineTotal: serializer.fromJson<double>(json['lineTotal']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'remoteId': serializer.toJson<String?>(remoteId),
      'tenantId': serializer.toJson<String>(tenantId),
      'requisitionLocalId': serializer.toJson<String>(requisitionLocalId),
      'lineNumber': serializer.toJson<int>(lineNumber),
      'itemType': serializer.toJson<String>(itemType),
      'catalogItemId': serializer.toJson<String?>(catalogItemId),
      'catalogSku': serializer.toJson<String?>(catalogSku),
      'description': serializer.toJson<String>(description),
      'quantity': serializer.toJson<double>(quantity),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'uom': serializer.toJson<String>(uom),
      'lineTotal': serializer.toJson<double>(lineTotal),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  LocalPurchaseRequisitionLineRow copyWith({
    String? localId,
    Value<String?> remoteId = const Value.absent(),
    String? tenantId,
    String? requisitionLocalId,
    int? lineNumber,
    String? itemType,
    Value<String?> catalogItemId = const Value.absent(),
    Value<String?> catalogSku = const Value.absent(),
    String? description,
    double? quantity,
    double? unitPrice,
    String? uom,
    double? lineTotal,
    Value<String?> notes = const Value.absent(),
  }) => LocalPurchaseRequisitionLineRow(
    localId: localId ?? this.localId,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    tenantId: tenantId ?? this.tenantId,
    requisitionLocalId: requisitionLocalId ?? this.requisitionLocalId,
    lineNumber: lineNumber ?? this.lineNumber,
    itemType: itemType ?? this.itemType,
    catalogItemId: catalogItemId.present
        ? catalogItemId.value
        : this.catalogItemId,
    catalogSku: catalogSku.present ? catalogSku.value : this.catalogSku,
    description: description ?? this.description,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
    uom: uom ?? this.uom,
    lineTotal: lineTotal ?? this.lineTotal,
    notes: notes.present ? notes.value : this.notes,
  );
  LocalPurchaseRequisitionLineRow copyWithCompanion(
    LocalPurchaseRequisitionLinesCompanion data,
  ) {
    return LocalPurchaseRequisitionLineRow(
      localId: data.localId.present ? data.localId.value : this.localId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      requisitionLocalId: data.requisitionLocalId.present
          ? data.requisitionLocalId.value
          : this.requisitionLocalId,
      lineNumber: data.lineNumber.present
          ? data.lineNumber.value
          : this.lineNumber,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      catalogItemId: data.catalogItemId.present
          ? data.catalogItemId.value
          : this.catalogItemId,
      catalogSku: data.catalogSku.present
          ? data.catalogSku.value
          : this.catalogSku,
      description: data.description.present
          ? data.description.value
          : this.description,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      uom: data.uom.present ? data.uom.value : this.uom,
      lineTotal: data.lineTotal.present ? data.lineTotal.value : this.lineTotal,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPurchaseRequisitionLineRow(')
          ..write('localId: $localId, ')
          ..write('remoteId: $remoteId, ')
          ..write('tenantId: $tenantId, ')
          ..write('requisitionLocalId: $requisitionLocalId, ')
          ..write('lineNumber: $lineNumber, ')
          ..write('itemType: $itemType, ')
          ..write('catalogItemId: $catalogItemId, ')
          ..write('catalogSku: $catalogSku, ')
          ..write('description: $description, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('uom: $uom, ')
          ..write('lineTotal: $lineTotal, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    remoteId,
    tenantId,
    requisitionLocalId,
    lineNumber,
    itemType,
    catalogItemId,
    catalogSku,
    description,
    quantity,
    unitPrice,
    uom,
    lineTotal,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPurchaseRequisitionLineRow &&
          other.localId == this.localId &&
          other.remoteId == this.remoteId &&
          other.tenantId == this.tenantId &&
          other.requisitionLocalId == this.requisitionLocalId &&
          other.lineNumber == this.lineNumber &&
          other.itemType == this.itemType &&
          other.catalogItemId == this.catalogItemId &&
          other.catalogSku == this.catalogSku &&
          other.description == this.description &&
          other.quantity == this.quantity &&
          other.unitPrice == this.unitPrice &&
          other.uom == this.uom &&
          other.lineTotal == this.lineTotal &&
          other.notes == this.notes);
}

class LocalPurchaseRequisitionLinesCompanion
    extends UpdateCompanion<LocalPurchaseRequisitionLineRow> {
  final Value<String> localId;
  final Value<String?> remoteId;
  final Value<String> tenantId;
  final Value<String> requisitionLocalId;
  final Value<int> lineNumber;
  final Value<String> itemType;
  final Value<String?> catalogItemId;
  final Value<String?> catalogSku;
  final Value<String> description;
  final Value<double> quantity;
  final Value<double> unitPrice;
  final Value<String> uom;
  final Value<double> lineTotal;
  final Value<String?> notes;
  final Value<int> rowid;
  const LocalPurchaseRequisitionLinesCompanion({
    this.localId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.requisitionLocalId = const Value.absent(),
    this.lineNumber = const Value.absent(),
    this.itemType = const Value.absent(),
    this.catalogItemId = const Value.absent(),
    this.catalogSku = const Value.absent(),
    this.description = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.uom = const Value.absent(),
    this.lineTotal = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPurchaseRequisitionLinesCompanion.insert({
    required String localId,
    this.remoteId = const Value.absent(),
    required String tenantId,
    required String requisitionLocalId,
    required int lineNumber,
    this.itemType = const Value.absent(),
    this.catalogItemId = const Value.absent(),
    this.catalogSku = const Value.absent(),
    required String description,
    required double quantity,
    required double unitPrice,
    this.uom = const Value.absent(),
    required double lineTotal,
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       tenantId = Value(tenantId),
       requisitionLocalId = Value(requisitionLocalId),
       lineNumber = Value(lineNumber),
       description = Value(description),
       quantity = Value(quantity),
       unitPrice = Value(unitPrice),
       lineTotal = Value(lineTotal);
  static Insertable<LocalPurchaseRequisitionLineRow> custom({
    Expression<String>? localId,
    Expression<String>? remoteId,
    Expression<String>? tenantId,
    Expression<String>? requisitionLocalId,
    Expression<int>? lineNumber,
    Expression<String>? itemType,
    Expression<String>? catalogItemId,
    Expression<String>? catalogSku,
    Expression<String>? description,
    Expression<double>? quantity,
    Expression<double>? unitPrice,
    Expression<String>? uom,
    Expression<double>? lineTotal,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (remoteId != null) 'remote_id': remoteId,
      if (tenantId != null) 'tenant_id': tenantId,
      if (requisitionLocalId != null)
        'requisition_local_id': requisitionLocalId,
      if (lineNumber != null) 'line_number': lineNumber,
      if (itemType != null) 'item_type': itemType,
      if (catalogItemId != null) 'catalog_item_id': catalogItemId,
      if (catalogSku != null) 'catalog_sku': catalogSku,
      if (description != null) 'description': description,
      if (quantity != null) 'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (uom != null) 'uom': uom,
      if (lineTotal != null) 'line_total': lineTotal,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPurchaseRequisitionLinesCompanion copyWith({
    Value<String>? localId,
    Value<String?>? remoteId,
    Value<String>? tenantId,
    Value<String>? requisitionLocalId,
    Value<int>? lineNumber,
    Value<String>? itemType,
    Value<String?>? catalogItemId,
    Value<String?>? catalogSku,
    Value<String>? description,
    Value<double>? quantity,
    Value<double>? unitPrice,
    Value<String>? uom,
    Value<double>? lineTotal,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return LocalPurchaseRequisitionLinesCompanion(
      localId: localId ?? this.localId,
      remoteId: remoteId ?? this.remoteId,
      tenantId: tenantId ?? this.tenantId,
      requisitionLocalId: requisitionLocalId ?? this.requisitionLocalId,
      lineNumber: lineNumber ?? this.lineNumber,
      itemType: itemType ?? this.itemType,
      catalogItemId: catalogItemId ?? this.catalogItemId,
      catalogSku: catalogSku ?? this.catalogSku,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      uom: uom ?? this.uom,
      lineTotal: lineTotal ?? this.lineTotal,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (requisitionLocalId.present) {
      map['requisition_local_id'] = Variable<String>(requisitionLocalId.value);
    }
    if (lineNumber.present) {
      map['line_number'] = Variable<int>(lineNumber.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (catalogItemId.present) {
      map['catalog_item_id'] = Variable<String>(catalogItemId.value);
    }
    if (catalogSku.present) {
      map['catalog_sku'] = Variable<String>(catalogSku.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (uom.present) {
      map['uom'] = Variable<String>(uom.value);
    }
    if (lineTotal.present) {
      map['line_total'] = Variable<double>(lineTotal.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPurchaseRequisitionLinesCompanion(')
          ..write('localId: $localId, ')
          ..write('remoteId: $remoteId, ')
          ..write('tenantId: $tenantId, ')
          ..write('requisitionLocalId: $requisitionLocalId, ')
          ..write('lineNumber: $lineNumber, ')
          ..write('itemType: $itemType, ')
          ..write('catalogItemId: $catalogItemId, ')
          ..write('catalogSku: $catalogSku, ')
          ..write('description: $description, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('uom: $uom, ')
          ..write('lineTotal: $lineTotal, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPendingApprovalsTable extends LocalPendingApprovals
    with TableInfo<$LocalPendingApprovalsTable, LocalPendingApprovalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPendingApprovalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _approvalIdMeta = const VerificationMeta(
    'approvalId',
  );
  @override
  late final GeneratedColumn<String> approvalId = GeneratedColumn<String>(
    'approval_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requisitionRemoteIdMeta =
      const VerificationMeta('requisitionRemoteId');
  @override
  late final GeneratedColumn<String> requisitionRemoteId =
      GeneratedColumn<String>(
        'requisition_remote_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _requisitionNumberMeta = const VerificationMeta(
    'requisitionNumber',
  );
  @override
  late final GeneratedColumn<String> requisitionNumber =
      GeneratedColumn<String>(
        'requisition_number',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _requesterNameMeta = const VerificationMeta(
    'requesterName',
  );
  @override
  late final GeneratedColumn<String> requesterName = GeneratedColumn<String>(
    'requester_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costCenterCodeMeta = const VerificationMeta(
    'costCenterCode',
  );
  @override
  late final GeneratedColumn<String> costCenterCode = GeneratedColumn<String>(
    'cost_center_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costCenterNameMeta = const VerificationMeta(
    'costCenterName',
  );
  @override
  late final GeneratedColumn<String> costCenterName = GeneratedColumn<String>(
    'cost_center_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectNameMeta = const VerificationMeta(
    'projectName',
  );
  @override
  late final GeneratedColumn<String> projectName = GeneratedColumn<String>(
    'project_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urgencyMeta = const VerificationMeta(
    'urgency',
  );
  @override
  late final GeneratedColumn<String> urgency = GeneratedColumn<String>(
    'urgency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('normal'),
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('CHF'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending_approval'),
  );
  static const VerificationMeta _currentLevelMeta = const VerificationMeta(
    'currentLevel',
  );
  @override
  late final GeneratedColumn<int> currentLevel = GeneratedColumn<int>(
    'current_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _totalLevelsMeta = const VerificationMeta(
    'totalLevels',
  );
  @override
  late final GeneratedColumn<int> totalLevels = GeneratedColumn<int>(
    'total_levels',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _budgetStatusMeta = const VerificationMeta(
    'budgetStatus',
  );
  @override
  late final GeneratedColumn<String> budgetStatus = GeneratedColumn<String>(
    'budget_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ok'),
  );
  static const VerificationMeta _oneClickTokenMeta = const VerificationMeta(
    'oneClickToken',
  );
  @override
  late final GeneratedColumn<String> oneClickToken = GeneratedColumn<String>(
    'one_click_token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendingDecisionMeta = const VerificationMeta(
    'pendingDecision',
  );
  @override
  late final GeneratedColumn<String> pendingDecision = GeneratedColumn<String>(
    'pending_decision',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendingRejectionReasonMeta =
      const VerificationMeta('pendingRejectionReason');
  @override
  late final GeneratedColumn<String> pendingRejectionReason =
      GeneratedColumn<String>(
        'pending_rejection_reason',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _requestedAtMeta = const VerificationMeta(
    'requestedAt',
  );
  @override
  late final GeneratedColumn<DateTime> requestedAt = GeneratedColumn<DateTime>(
    'requested_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    approvalId,
    tenantId,
    requisitionRemoteId,
    requisitionNumber,
    requesterName,
    costCenterCode,
    costCenterName,
    projectName,
    urgency,
    totalAmount,
    currency,
    status,
    currentLevel,
    totalLevels,
    budgetStatus,
    oneClickToken,
    pendingDecision,
    pendingRejectionReason,
    syncStatus,
    syncError,
    requestedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_pending_approvals';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalPendingApprovalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('approval_id')) {
      context.handle(
        _approvalIdMeta,
        approvalId.isAcceptableOrUnknown(data['approval_id']!, _approvalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_approvalIdMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('requisition_remote_id')) {
      context.handle(
        _requisitionRemoteIdMeta,
        requisitionRemoteId.isAcceptableOrUnknown(
          data['requisition_remote_id']!,
          _requisitionRemoteIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requisitionRemoteIdMeta);
    }
    if (data.containsKey('requisition_number')) {
      context.handle(
        _requisitionNumberMeta,
        requisitionNumber.isAcceptableOrUnknown(
          data['requisition_number']!,
          _requisitionNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requisitionNumberMeta);
    }
    if (data.containsKey('requester_name')) {
      context.handle(
        _requesterNameMeta,
        requesterName.isAcceptableOrUnknown(
          data['requester_name']!,
          _requesterNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requesterNameMeta);
    }
    if (data.containsKey('cost_center_code')) {
      context.handle(
        _costCenterCodeMeta,
        costCenterCode.isAcceptableOrUnknown(
          data['cost_center_code']!,
          _costCenterCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_costCenterCodeMeta);
    }
    if (data.containsKey('cost_center_name')) {
      context.handle(
        _costCenterNameMeta,
        costCenterName.isAcceptableOrUnknown(
          data['cost_center_name']!,
          _costCenterNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_costCenterNameMeta);
    }
    if (data.containsKey('project_name')) {
      context.handle(
        _projectNameMeta,
        projectName.isAcceptableOrUnknown(
          data['project_name']!,
          _projectNameMeta,
        ),
      );
    }
    if (data.containsKey('urgency')) {
      context.handle(
        _urgencyMeta,
        urgency.isAcceptableOrUnknown(data['urgency']!, _urgencyMeta),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('current_level')) {
      context.handle(
        _currentLevelMeta,
        currentLevel.isAcceptableOrUnknown(
          data['current_level']!,
          _currentLevelMeta,
        ),
      );
    }
    if (data.containsKey('total_levels')) {
      context.handle(
        _totalLevelsMeta,
        totalLevels.isAcceptableOrUnknown(
          data['total_levels']!,
          _totalLevelsMeta,
        ),
      );
    }
    if (data.containsKey('budget_status')) {
      context.handle(
        _budgetStatusMeta,
        budgetStatus.isAcceptableOrUnknown(
          data['budget_status']!,
          _budgetStatusMeta,
        ),
      );
    }
    if (data.containsKey('one_click_token')) {
      context.handle(
        _oneClickTokenMeta,
        oneClickToken.isAcceptableOrUnknown(
          data['one_click_token']!,
          _oneClickTokenMeta,
        ),
      );
    }
    if (data.containsKey('pending_decision')) {
      context.handle(
        _pendingDecisionMeta,
        pendingDecision.isAcceptableOrUnknown(
          data['pending_decision']!,
          _pendingDecisionMeta,
        ),
      );
    }
    if (data.containsKey('pending_rejection_reason')) {
      context.handle(
        _pendingRejectionReasonMeta,
        pendingRejectionReason.isAcceptableOrUnknown(
          data['pending_rejection_reason']!,
          _pendingRejectionReasonMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('requested_at')) {
      context.handle(
        _requestedAtMeta,
        requestedAt.isAcceptableOrUnknown(
          data['requested_at']!,
          _requestedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requestedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {approvalId};
  @override
  LocalPendingApprovalRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPendingApprovalRow(
      approvalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approval_id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      requisitionRemoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}requisition_remote_id'],
      )!,
      requisitionNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}requisition_number'],
      )!,
      requesterName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}requester_name'],
      )!,
      costCenterCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cost_center_code'],
      )!,
      costCenterName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cost_center_name'],
      )!,
      projectName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_name'],
      ),
      urgency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}urgency'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      currentLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_level'],
      )!,
      totalLevels: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_levels'],
      )!,
      budgetStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}budget_status'],
      )!,
      oneClickToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}one_click_token'],
      ),
      pendingDecision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pending_decision'],
      ),
      pendingRejectionReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pending_rejection_reason'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      requestedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}requested_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalPendingApprovalsTable createAlias(String alias) {
    return $LocalPendingApprovalsTable(attachedDatabase, alias);
  }
}

class LocalPendingApprovalRow extends DataClass
    implements Insertable<LocalPendingApprovalRow> {
  final String approvalId;
  final String tenantId;
  final String requisitionRemoteId;
  final String requisitionNumber;
  final String requesterName;
  final String costCenterCode;
  final String costCenterName;
  final String? projectName;
  final String urgency;
  final double totalAmount;
  final String currency;
  final String status;
  final int currentLevel;
  final int totalLevels;
  final String budgetStatus;
  final String? oneClickToken;

  /// `'approve'` or `'reject'` while queued offline; `null` when awaiting manager action.
  final String? pendingDecision;
  final String? pendingRejectionReason;
  final String syncStatus;
  final String? syncError;
  final DateTime requestedAt;
  final DateTime updatedAt;
  const LocalPendingApprovalRow({
    required this.approvalId,
    required this.tenantId,
    required this.requisitionRemoteId,
    required this.requisitionNumber,
    required this.requesterName,
    required this.costCenterCode,
    required this.costCenterName,
    this.projectName,
    required this.urgency,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.currentLevel,
    required this.totalLevels,
    required this.budgetStatus,
    this.oneClickToken,
    this.pendingDecision,
    this.pendingRejectionReason,
    required this.syncStatus,
    this.syncError,
    required this.requestedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['approval_id'] = Variable<String>(approvalId);
    map['tenant_id'] = Variable<String>(tenantId);
    map['requisition_remote_id'] = Variable<String>(requisitionRemoteId);
    map['requisition_number'] = Variable<String>(requisitionNumber);
    map['requester_name'] = Variable<String>(requesterName);
    map['cost_center_code'] = Variable<String>(costCenterCode);
    map['cost_center_name'] = Variable<String>(costCenterName);
    if (!nullToAbsent || projectName != null) {
      map['project_name'] = Variable<String>(projectName);
    }
    map['urgency'] = Variable<String>(urgency);
    map['total_amount'] = Variable<double>(totalAmount);
    map['currency'] = Variable<String>(currency);
    map['status'] = Variable<String>(status);
    map['current_level'] = Variable<int>(currentLevel);
    map['total_levels'] = Variable<int>(totalLevels);
    map['budget_status'] = Variable<String>(budgetStatus);
    if (!nullToAbsent || oneClickToken != null) {
      map['one_click_token'] = Variable<String>(oneClickToken);
    }
    if (!nullToAbsent || pendingDecision != null) {
      map['pending_decision'] = Variable<String>(pendingDecision);
    }
    if (!nullToAbsent || pendingRejectionReason != null) {
      map['pending_rejection_reason'] = Variable<String>(
        pendingRejectionReason,
      );
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['requested_at'] = Variable<DateTime>(requestedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalPendingApprovalsCompanion toCompanion(bool nullToAbsent) {
    return LocalPendingApprovalsCompanion(
      approvalId: Value(approvalId),
      tenantId: Value(tenantId),
      requisitionRemoteId: Value(requisitionRemoteId),
      requisitionNumber: Value(requisitionNumber),
      requesterName: Value(requesterName),
      costCenterCode: Value(costCenterCode),
      costCenterName: Value(costCenterName),
      projectName: projectName == null && nullToAbsent
          ? const Value.absent()
          : Value(projectName),
      urgency: Value(urgency),
      totalAmount: Value(totalAmount),
      currency: Value(currency),
      status: Value(status),
      currentLevel: Value(currentLevel),
      totalLevels: Value(totalLevels),
      budgetStatus: Value(budgetStatus),
      oneClickToken: oneClickToken == null && nullToAbsent
          ? const Value.absent()
          : Value(oneClickToken),
      pendingDecision: pendingDecision == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingDecision),
      pendingRejectionReason: pendingRejectionReason == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingRejectionReason),
      syncStatus: Value(syncStatus),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      requestedAt: Value(requestedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalPendingApprovalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPendingApprovalRow(
      approvalId: serializer.fromJson<String>(json['approvalId']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      requisitionRemoteId: serializer.fromJson<String>(
        json['requisitionRemoteId'],
      ),
      requisitionNumber: serializer.fromJson<String>(json['requisitionNumber']),
      requesterName: serializer.fromJson<String>(json['requesterName']),
      costCenterCode: serializer.fromJson<String>(json['costCenterCode']),
      costCenterName: serializer.fromJson<String>(json['costCenterName']),
      projectName: serializer.fromJson<String?>(json['projectName']),
      urgency: serializer.fromJson<String>(json['urgency']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      currency: serializer.fromJson<String>(json['currency']),
      status: serializer.fromJson<String>(json['status']),
      currentLevel: serializer.fromJson<int>(json['currentLevel']),
      totalLevels: serializer.fromJson<int>(json['totalLevels']),
      budgetStatus: serializer.fromJson<String>(json['budgetStatus']),
      oneClickToken: serializer.fromJson<String?>(json['oneClickToken']),
      pendingDecision: serializer.fromJson<String?>(json['pendingDecision']),
      pendingRejectionReason: serializer.fromJson<String?>(
        json['pendingRejectionReason'],
      ),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      requestedAt: serializer.fromJson<DateTime>(json['requestedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'approvalId': serializer.toJson<String>(approvalId),
      'tenantId': serializer.toJson<String>(tenantId),
      'requisitionRemoteId': serializer.toJson<String>(requisitionRemoteId),
      'requisitionNumber': serializer.toJson<String>(requisitionNumber),
      'requesterName': serializer.toJson<String>(requesterName),
      'costCenterCode': serializer.toJson<String>(costCenterCode),
      'costCenterName': serializer.toJson<String>(costCenterName),
      'projectName': serializer.toJson<String?>(projectName),
      'urgency': serializer.toJson<String>(urgency),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'currency': serializer.toJson<String>(currency),
      'status': serializer.toJson<String>(status),
      'currentLevel': serializer.toJson<int>(currentLevel),
      'totalLevels': serializer.toJson<int>(totalLevels),
      'budgetStatus': serializer.toJson<String>(budgetStatus),
      'oneClickToken': serializer.toJson<String?>(oneClickToken),
      'pendingDecision': serializer.toJson<String?>(pendingDecision),
      'pendingRejectionReason': serializer.toJson<String?>(
        pendingRejectionReason,
      ),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'syncError': serializer.toJson<String?>(syncError),
      'requestedAt': serializer.toJson<DateTime>(requestedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalPendingApprovalRow copyWith({
    String? approvalId,
    String? tenantId,
    String? requisitionRemoteId,
    String? requisitionNumber,
    String? requesterName,
    String? costCenterCode,
    String? costCenterName,
    Value<String?> projectName = const Value.absent(),
    String? urgency,
    double? totalAmount,
    String? currency,
    String? status,
    int? currentLevel,
    int? totalLevels,
    String? budgetStatus,
    Value<String?> oneClickToken = const Value.absent(),
    Value<String?> pendingDecision = const Value.absent(),
    Value<String?> pendingRejectionReason = const Value.absent(),
    String? syncStatus,
    Value<String?> syncError = const Value.absent(),
    DateTime? requestedAt,
    DateTime? updatedAt,
  }) => LocalPendingApprovalRow(
    approvalId: approvalId ?? this.approvalId,
    tenantId: tenantId ?? this.tenantId,
    requisitionRemoteId: requisitionRemoteId ?? this.requisitionRemoteId,
    requisitionNumber: requisitionNumber ?? this.requisitionNumber,
    requesterName: requesterName ?? this.requesterName,
    costCenterCode: costCenterCode ?? this.costCenterCode,
    costCenterName: costCenterName ?? this.costCenterName,
    projectName: projectName.present ? projectName.value : this.projectName,
    urgency: urgency ?? this.urgency,
    totalAmount: totalAmount ?? this.totalAmount,
    currency: currency ?? this.currency,
    status: status ?? this.status,
    currentLevel: currentLevel ?? this.currentLevel,
    totalLevels: totalLevels ?? this.totalLevels,
    budgetStatus: budgetStatus ?? this.budgetStatus,
    oneClickToken: oneClickToken.present
        ? oneClickToken.value
        : this.oneClickToken,
    pendingDecision: pendingDecision.present
        ? pendingDecision.value
        : this.pendingDecision,
    pendingRejectionReason: pendingRejectionReason.present
        ? pendingRejectionReason.value
        : this.pendingRejectionReason,
    syncStatus: syncStatus ?? this.syncStatus,
    syncError: syncError.present ? syncError.value : this.syncError,
    requestedAt: requestedAt ?? this.requestedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalPendingApprovalRow copyWithCompanion(
    LocalPendingApprovalsCompanion data,
  ) {
    return LocalPendingApprovalRow(
      approvalId: data.approvalId.present
          ? data.approvalId.value
          : this.approvalId,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      requisitionRemoteId: data.requisitionRemoteId.present
          ? data.requisitionRemoteId.value
          : this.requisitionRemoteId,
      requisitionNumber: data.requisitionNumber.present
          ? data.requisitionNumber.value
          : this.requisitionNumber,
      requesterName: data.requesterName.present
          ? data.requesterName.value
          : this.requesterName,
      costCenterCode: data.costCenterCode.present
          ? data.costCenterCode.value
          : this.costCenterCode,
      costCenterName: data.costCenterName.present
          ? data.costCenterName.value
          : this.costCenterName,
      projectName: data.projectName.present
          ? data.projectName.value
          : this.projectName,
      urgency: data.urgency.present ? data.urgency.value : this.urgency,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      currency: data.currency.present ? data.currency.value : this.currency,
      status: data.status.present ? data.status.value : this.status,
      currentLevel: data.currentLevel.present
          ? data.currentLevel.value
          : this.currentLevel,
      totalLevels: data.totalLevels.present
          ? data.totalLevels.value
          : this.totalLevels,
      budgetStatus: data.budgetStatus.present
          ? data.budgetStatus.value
          : this.budgetStatus,
      oneClickToken: data.oneClickToken.present
          ? data.oneClickToken.value
          : this.oneClickToken,
      pendingDecision: data.pendingDecision.present
          ? data.pendingDecision.value
          : this.pendingDecision,
      pendingRejectionReason: data.pendingRejectionReason.present
          ? data.pendingRejectionReason.value
          : this.pendingRejectionReason,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      requestedAt: data.requestedAt.present
          ? data.requestedAt.value
          : this.requestedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPendingApprovalRow(')
          ..write('approvalId: $approvalId, ')
          ..write('tenantId: $tenantId, ')
          ..write('requisitionRemoteId: $requisitionRemoteId, ')
          ..write('requisitionNumber: $requisitionNumber, ')
          ..write('requesterName: $requesterName, ')
          ..write('costCenterCode: $costCenterCode, ')
          ..write('costCenterName: $costCenterName, ')
          ..write('projectName: $projectName, ')
          ..write('urgency: $urgency, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('currency: $currency, ')
          ..write('status: $status, ')
          ..write('currentLevel: $currentLevel, ')
          ..write('totalLevels: $totalLevels, ')
          ..write('budgetStatus: $budgetStatus, ')
          ..write('oneClickToken: $oneClickToken, ')
          ..write('pendingDecision: $pendingDecision, ')
          ..write('pendingRejectionReason: $pendingRejectionReason, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('requestedAt: $requestedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    approvalId,
    tenantId,
    requisitionRemoteId,
    requisitionNumber,
    requesterName,
    costCenterCode,
    costCenterName,
    projectName,
    urgency,
    totalAmount,
    currency,
    status,
    currentLevel,
    totalLevels,
    budgetStatus,
    oneClickToken,
    pendingDecision,
    pendingRejectionReason,
    syncStatus,
    syncError,
    requestedAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPendingApprovalRow &&
          other.approvalId == this.approvalId &&
          other.tenantId == this.tenantId &&
          other.requisitionRemoteId == this.requisitionRemoteId &&
          other.requisitionNumber == this.requisitionNumber &&
          other.requesterName == this.requesterName &&
          other.costCenterCode == this.costCenterCode &&
          other.costCenterName == this.costCenterName &&
          other.projectName == this.projectName &&
          other.urgency == this.urgency &&
          other.totalAmount == this.totalAmount &&
          other.currency == this.currency &&
          other.status == this.status &&
          other.currentLevel == this.currentLevel &&
          other.totalLevels == this.totalLevels &&
          other.budgetStatus == this.budgetStatus &&
          other.oneClickToken == this.oneClickToken &&
          other.pendingDecision == this.pendingDecision &&
          other.pendingRejectionReason == this.pendingRejectionReason &&
          other.syncStatus == this.syncStatus &&
          other.syncError == this.syncError &&
          other.requestedAt == this.requestedAt &&
          other.updatedAt == this.updatedAt);
}

class LocalPendingApprovalsCompanion
    extends UpdateCompanion<LocalPendingApprovalRow> {
  final Value<String> approvalId;
  final Value<String> tenantId;
  final Value<String> requisitionRemoteId;
  final Value<String> requisitionNumber;
  final Value<String> requesterName;
  final Value<String> costCenterCode;
  final Value<String> costCenterName;
  final Value<String?> projectName;
  final Value<String> urgency;
  final Value<double> totalAmount;
  final Value<String> currency;
  final Value<String> status;
  final Value<int> currentLevel;
  final Value<int> totalLevels;
  final Value<String> budgetStatus;
  final Value<String?> oneClickToken;
  final Value<String?> pendingDecision;
  final Value<String?> pendingRejectionReason;
  final Value<String> syncStatus;
  final Value<String?> syncError;
  final Value<DateTime> requestedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalPendingApprovalsCompanion({
    this.approvalId = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.requisitionRemoteId = const Value.absent(),
    this.requisitionNumber = const Value.absent(),
    this.requesterName = const Value.absent(),
    this.costCenterCode = const Value.absent(),
    this.costCenterName = const Value.absent(),
    this.projectName = const Value.absent(),
    this.urgency = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.currency = const Value.absent(),
    this.status = const Value.absent(),
    this.currentLevel = const Value.absent(),
    this.totalLevels = const Value.absent(),
    this.budgetStatus = const Value.absent(),
    this.oneClickToken = const Value.absent(),
    this.pendingDecision = const Value.absent(),
    this.pendingRejectionReason = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.requestedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPendingApprovalsCompanion.insert({
    required String approvalId,
    required String tenantId,
    required String requisitionRemoteId,
    required String requisitionNumber,
    required String requesterName,
    required String costCenterCode,
    required String costCenterName,
    this.projectName = const Value.absent(),
    this.urgency = const Value.absent(),
    required double totalAmount,
    this.currency = const Value.absent(),
    this.status = const Value.absent(),
    this.currentLevel = const Value.absent(),
    this.totalLevels = const Value.absent(),
    this.budgetStatus = const Value.absent(),
    this.oneClickToken = const Value.absent(),
    this.pendingDecision = const Value.absent(),
    this.pendingRejectionReason = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    required DateTime requestedAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : approvalId = Value(approvalId),
       tenantId = Value(tenantId),
       requisitionRemoteId = Value(requisitionRemoteId),
       requisitionNumber = Value(requisitionNumber),
       requesterName = Value(requesterName),
       costCenterCode = Value(costCenterCode),
       costCenterName = Value(costCenterName),
       totalAmount = Value(totalAmount),
       requestedAt = Value(requestedAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalPendingApprovalRow> custom({
    Expression<String>? approvalId,
    Expression<String>? tenantId,
    Expression<String>? requisitionRemoteId,
    Expression<String>? requisitionNumber,
    Expression<String>? requesterName,
    Expression<String>? costCenterCode,
    Expression<String>? costCenterName,
    Expression<String>? projectName,
    Expression<String>? urgency,
    Expression<double>? totalAmount,
    Expression<String>? currency,
    Expression<String>? status,
    Expression<int>? currentLevel,
    Expression<int>? totalLevels,
    Expression<String>? budgetStatus,
    Expression<String>? oneClickToken,
    Expression<String>? pendingDecision,
    Expression<String>? pendingRejectionReason,
    Expression<String>? syncStatus,
    Expression<String>? syncError,
    Expression<DateTime>? requestedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (approvalId != null) 'approval_id': approvalId,
      if (tenantId != null) 'tenant_id': tenantId,
      if (requisitionRemoteId != null)
        'requisition_remote_id': requisitionRemoteId,
      if (requisitionNumber != null) 'requisition_number': requisitionNumber,
      if (requesterName != null) 'requester_name': requesterName,
      if (costCenterCode != null) 'cost_center_code': costCenterCode,
      if (costCenterName != null) 'cost_center_name': costCenterName,
      if (projectName != null) 'project_name': projectName,
      if (urgency != null) 'urgency': urgency,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (currency != null) 'currency': currency,
      if (status != null) 'status': status,
      if (currentLevel != null) 'current_level': currentLevel,
      if (totalLevels != null) 'total_levels': totalLevels,
      if (budgetStatus != null) 'budget_status': budgetStatus,
      if (oneClickToken != null) 'one_click_token': oneClickToken,
      if (pendingDecision != null) 'pending_decision': pendingDecision,
      if (pendingRejectionReason != null)
        'pending_rejection_reason': pendingRejectionReason,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncError != null) 'sync_error': syncError,
      if (requestedAt != null) 'requested_at': requestedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPendingApprovalsCompanion copyWith({
    Value<String>? approvalId,
    Value<String>? tenantId,
    Value<String>? requisitionRemoteId,
    Value<String>? requisitionNumber,
    Value<String>? requesterName,
    Value<String>? costCenterCode,
    Value<String>? costCenterName,
    Value<String?>? projectName,
    Value<String>? urgency,
    Value<double>? totalAmount,
    Value<String>? currency,
    Value<String>? status,
    Value<int>? currentLevel,
    Value<int>? totalLevels,
    Value<String>? budgetStatus,
    Value<String?>? oneClickToken,
    Value<String?>? pendingDecision,
    Value<String?>? pendingRejectionReason,
    Value<String>? syncStatus,
    Value<String?>? syncError,
    Value<DateTime>? requestedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalPendingApprovalsCompanion(
      approvalId: approvalId ?? this.approvalId,
      tenantId: tenantId ?? this.tenantId,
      requisitionRemoteId: requisitionRemoteId ?? this.requisitionRemoteId,
      requisitionNumber: requisitionNumber ?? this.requisitionNumber,
      requesterName: requesterName ?? this.requesterName,
      costCenterCode: costCenterCode ?? this.costCenterCode,
      costCenterName: costCenterName ?? this.costCenterName,
      projectName: projectName ?? this.projectName,
      urgency: urgency ?? this.urgency,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      currentLevel: currentLevel ?? this.currentLevel,
      totalLevels: totalLevels ?? this.totalLevels,
      budgetStatus: budgetStatus ?? this.budgetStatus,
      oneClickToken: oneClickToken ?? this.oneClickToken,
      pendingDecision: pendingDecision ?? this.pendingDecision,
      pendingRejectionReason:
          pendingRejectionReason ?? this.pendingRejectionReason,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
      requestedAt: requestedAt ?? this.requestedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (approvalId.present) {
      map['approval_id'] = Variable<String>(approvalId.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (requisitionRemoteId.present) {
      map['requisition_remote_id'] = Variable<String>(
        requisitionRemoteId.value,
      );
    }
    if (requisitionNumber.present) {
      map['requisition_number'] = Variable<String>(requisitionNumber.value);
    }
    if (requesterName.present) {
      map['requester_name'] = Variable<String>(requesterName.value);
    }
    if (costCenterCode.present) {
      map['cost_center_code'] = Variable<String>(costCenterCode.value);
    }
    if (costCenterName.present) {
      map['cost_center_name'] = Variable<String>(costCenterName.value);
    }
    if (projectName.present) {
      map['project_name'] = Variable<String>(projectName.value);
    }
    if (urgency.present) {
      map['urgency'] = Variable<String>(urgency.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (currentLevel.present) {
      map['current_level'] = Variable<int>(currentLevel.value);
    }
    if (totalLevels.present) {
      map['total_levels'] = Variable<int>(totalLevels.value);
    }
    if (budgetStatus.present) {
      map['budget_status'] = Variable<String>(budgetStatus.value);
    }
    if (oneClickToken.present) {
      map['one_click_token'] = Variable<String>(oneClickToken.value);
    }
    if (pendingDecision.present) {
      map['pending_decision'] = Variable<String>(pendingDecision.value);
    }
    if (pendingRejectionReason.present) {
      map['pending_rejection_reason'] = Variable<String>(
        pendingRejectionReason.value,
      );
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (requestedAt.present) {
      map['requested_at'] = Variable<DateTime>(requestedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPendingApprovalsCompanion(')
          ..write('approvalId: $approvalId, ')
          ..write('tenantId: $tenantId, ')
          ..write('requisitionRemoteId: $requisitionRemoteId, ')
          ..write('requisitionNumber: $requisitionNumber, ')
          ..write('requesterName: $requesterName, ')
          ..write('costCenterCode: $costCenterCode, ')
          ..write('costCenterName: $costCenterName, ')
          ..write('projectName: $projectName, ')
          ..write('urgency: $urgency, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('currency: $currency, ')
          ..write('status: $status, ')
          ..write('currentLevel: $currentLevel, ')
          ..write('totalLevels: $totalLevels, ')
          ..write('budgetStatus: $budgetStatus, ')
          ..write('oneClickToken: $oneClickToken, ')
          ..write('pendingDecision: $pendingDecision, ')
          ..write('pendingRejectionReason: $pendingRejectionReason, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('requestedAt: $requestedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalApprovalAuditLogsTable extends LocalApprovalAuditLogs
    with TableInfo<$LocalApprovalAuditLogsTable, LocalApprovalAuditLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalApprovalAuditLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requisitionIdMeta = const VerificationMeta(
    'requisitionId',
  );
  @override
  late final GeneratedColumn<String> requisitionId = GeneratedColumn<String>(
    'requisition_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorIdMeta = const VerificationMeta(
    'actorId',
  );
  @override
  late final GeneratedColumn<String> actorId = GeneratedColumn<String>(
    'actor_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actorNameMeta = const VerificationMeta(
    'actorName',
  );
  @override
  late final GeneratedColumn<String> actorName = GeneratedColumn<String>(
    'actor_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorRoleMeta = const VerificationMeta(
    'actorRole',
  );
  @override
  late final GeneratedColumn<String> actorRole = GeneratedColumn<String>(
    'actor_role',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _channelMeta = const VerificationMeta(
    'channel',
  );
  @override
  late final GeneratedColumn<String> channel = GeneratedColumn<String>(
    'channel',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('web'),
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isLocalPendingMeta = const VerificationMeta(
    'isLocalPending',
  );
  @override
  late final GeneratedColumn<bool> isLocalPending = GeneratedColumn<bool>(
    'is_local_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_local_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    requisitionId,
    level,
    action,
    actorId,
    actorName,
    actorRole,
    channel,
    comment,
    occurredAt,
    isLocalPending,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_approval_audit_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalApprovalAuditLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('requisition_id')) {
      context.handle(
        _requisitionIdMeta,
        requisitionId.isAcceptableOrUnknown(
          data['requisition_id']!,
          _requisitionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requisitionIdMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('actor_id')) {
      context.handle(
        _actorIdMeta,
        actorId.isAcceptableOrUnknown(data['actor_id']!, _actorIdMeta),
      );
    }
    if (data.containsKey('actor_name')) {
      context.handle(
        _actorNameMeta,
        actorName.isAcceptableOrUnknown(data['actor_name']!, _actorNameMeta),
      );
    } else if (isInserting) {
      context.missing(_actorNameMeta);
    }
    if (data.containsKey('actor_role')) {
      context.handle(
        _actorRoleMeta,
        actorRole.isAcceptableOrUnknown(data['actor_role']!, _actorRoleMeta),
      );
    }
    if (data.containsKey('channel')) {
      context.handle(
        _channelMeta,
        channel.isAcceptableOrUnknown(data['channel']!, _channelMeta),
      );
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('is_local_pending')) {
      context.handle(
        _isLocalPendingMeta,
        isLocalPending.isAcceptableOrUnknown(
          data['is_local_pending']!,
          _isLocalPendingMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalApprovalAuditLogRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalApprovalAuditLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      requisitionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}requisition_id'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      actorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_id'],
      ),
      actorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_name'],
      )!,
      actorRole: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_role'],
      ),
      channel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel'],
      )!,
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      isLocalPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_local_pending'],
      )!,
    );
  }

  @override
  $LocalApprovalAuditLogsTable createAlias(String alias) {
    return $LocalApprovalAuditLogsTable(attachedDatabase, alias);
  }
}

class LocalApprovalAuditLogRow extends DataClass
    implements Insertable<LocalApprovalAuditLogRow> {
  final String id;
  final String tenantId;
  final String requisitionId;
  final int level;
  final String action;
  final String? actorId;
  final String actorName;
  final String? actorRole;
  final String channel;
  final String? comment;
  final DateTime occurredAt;
  final bool isLocalPending;
  const LocalApprovalAuditLogRow({
    required this.id,
    required this.tenantId,
    required this.requisitionId,
    required this.level,
    required this.action,
    this.actorId,
    required this.actorName,
    this.actorRole,
    required this.channel,
    this.comment,
    required this.occurredAt,
    required this.isLocalPending,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['requisition_id'] = Variable<String>(requisitionId);
    map['level'] = Variable<int>(level);
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || actorId != null) {
      map['actor_id'] = Variable<String>(actorId);
    }
    map['actor_name'] = Variable<String>(actorName);
    if (!nullToAbsent || actorRole != null) {
      map['actor_role'] = Variable<String>(actorRole);
    }
    map['channel'] = Variable<String>(channel);
    if (!nullToAbsent || comment != null) {
      map['comment'] = Variable<String>(comment);
    }
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['is_local_pending'] = Variable<bool>(isLocalPending);
    return map;
  }

  LocalApprovalAuditLogsCompanion toCompanion(bool nullToAbsent) {
    return LocalApprovalAuditLogsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      requisitionId: Value(requisitionId),
      level: Value(level),
      action: Value(action),
      actorId: actorId == null && nullToAbsent
          ? const Value.absent()
          : Value(actorId),
      actorName: Value(actorName),
      actorRole: actorRole == null && nullToAbsent
          ? const Value.absent()
          : Value(actorRole),
      channel: Value(channel),
      comment: comment == null && nullToAbsent
          ? const Value.absent()
          : Value(comment),
      occurredAt: Value(occurredAt),
      isLocalPending: Value(isLocalPending),
    );
  }

  factory LocalApprovalAuditLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalApprovalAuditLogRow(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      requisitionId: serializer.fromJson<String>(json['requisitionId']),
      level: serializer.fromJson<int>(json['level']),
      action: serializer.fromJson<String>(json['action']),
      actorId: serializer.fromJson<String?>(json['actorId']),
      actorName: serializer.fromJson<String>(json['actorName']),
      actorRole: serializer.fromJson<String?>(json['actorRole']),
      channel: serializer.fromJson<String>(json['channel']),
      comment: serializer.fromJson<String?>(json['comment']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      isLocalPending: serializer.fromJson<bool>(json['isLocalPending']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'requisitionId': serializer.toJson<String>(requisitionId),
      'level': serializer.toJson<int>(level),
      'action': serializer.toJson<String>(action),
      'actorId': serializer.toJson<String?>(actorId),
      'actorName': serializer.toJson<String>(actorName),
      'actorRole': serializer.toJson<String?>(actorRole),
      'channel': serializer.toJson<String>(channel),
      'comment': serializer.toJson<String?>(comment),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'isLocalPending': serializer.toJson<bool>(isLocalPending),
    };
  }

  LocalApprovalAuditLogRow copyWith({
    String? id,
    String? tenantId,
    String? requisitionId,
    int? level,
    String? action,
    Value<String?> actorId = const Value.absent(),
    String? actorName,
    Value<String?> actorRole = const Value.absent(),
    String? channel,
    Value<String?> comment = const Value.absent(),
    DateTime? occurredAt,
    bool? isLocalPending,
  }) => LocalApprovalAuditLogRow(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    requisitionId: requisitionId ?? this.requisitionId,
    level: level ?? this.level,
    action: action ?? this.action,
    actorId: actorId.present ? actorId.value : this.actorId,
    actorName: actorName ?? this.actorName,
    actorRole: actorRole.present ? actorRole.value : this.actorRole,
    channel: channel ?? this.channel,
    comment: comment.present ? comment.value : this.comment,
    occurredAt: occurredAt ?? this.occurredAt,
    isLocalPending: isLocalPending ?? this.isLocalPending,
  );
  LocalApprovalAuditLogRow copyWithCompanion(
    LocalApprovalAuditLogsCompanion data,
  ) {
    return LocalApprovalAuditLogRow(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      requisitionId: data.requisitionId.present
          ? data.requisitionId.value
          : this.requisitionId,
      level: data.level.present ? data.level.value : this.level,
      action: data.action.present ? data.action.value : this.action,
      actorId: data.actorId.present ? data.actorId.value : this.actorId,
      actorName: data.actorName.present ? data.actorName.value : this.actorName,
      actorRole: data.actorRole.present ? data.actorRole.value : this.actorRole,
      channel: data.channel.present ? data.channel.value : this.channel,
      comment: data.comment.present ? data.comment.value : this.comment,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      isLocalPending: data.isLocalPending.present
          ? data.isLocalPending.value
          : this.isLocalPending,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalApprovalAuditLogRow(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('requisitionId: $requisitionId, ')
          ..write('level: $level, ')
          ..write('action: $action, ')
          ..write('actorId: $actorId, ')
          ..write('actorName: $actorName, ')
          ..write('actorRole: $actorRole, ')
          ..write('channel: $channel, ')
          ..write('comment: $comment, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('isLocalPending: $isLocalPending')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    requisitionId,
    level,
    action,
    actorId,
    actorName,
    actorRole,
    channel,
    comment,
    occurredAt,
    isLocalPending,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalApprovalAuditLogRow &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.requisitionId == this.requisitionId &&
          other.level == this.level &&
          other.action == this.action &&
          other.actorId == this.actorId &&
          other.actorName == this.actorName &&
          other.actorRole == this.actorRole &&
          other.channel == this.channel &&
          other.comment == this.comment &&
          other.occurredAt == this.occurredAt &&
          other.isLocalPending == this.isLocalPending);
}

class LocalApprovalAuditLogsCompanion
    extends UpdateCompanion<LocalApprovalAuditLogRow> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> requisitionId;
  final Value<int> level;
  final Value<String> action;
  final Value<String?> actorId;
  final Value<String> actorName;
  final Value<String?> actorRole;
  final Value<String> channel;
  final Value<String?> comment;
  final Value<DateTime> occurredAt;
  final Value<bool> isLocalPending;
  final Value<int> rowid;
  const LocalApprovalAuditLogsCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.requisitionId = const Value.absent(),
    this.level = const Value.absent(),
    this.action = const Value.absent(),
    this.actorId = const Value.absent(),
    this.actorName = const Value.absent(),
    this.actorRole = const Value.absent(),
    this.channel = const Value.absent(),
    this.comment = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.isLocalPending = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalApprovalAuditLogsCompanion.insert({
    required String id,
    required String tenantId,
    required String requisitionId,
    this.level = const Value.absent(),
    required String action,
    this.actorId = const Value.absent(),
    required String actorName,
    this.actorRole = const Value.absent(),
    this.channel = const Value.absent(),
    this.comment = const Value.absent(),
    required DateTime occurredAt,
    this.isLocalPending = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tenantId = Value(tenantId),
       requisitionId = Value(requisitionId),
       action = Value(action),
       actorName = Value(actorName),
       occurredAt = Value(occurredAt);
  static Insertable<LocalApprovalAuditLogRow> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? requisitionId,
    Expression<int>? level,
    Expression<String>? action,
    Expression<String>? actorId,
    Expression<String>? actorName,
    Expression<String>? actorRole,
    Expression<String>? channel,
    Expression<String>? comment,
    Expression<DateTime>? occurredAt,
    Expression<bool>? isLocalPending,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (requisitionId != null) 'requisition_id': requisitionId,
      if (level != null) 'level': level,
      if (action != null) 'action': action,
      if (actorId != null) 'actor_id': actorId,
      if (actorName != null) 'actor_name': actorName,
      if (actorRole != null) 'actor_role': actorRole,
      if (channel != null) 'channel': channel,
      if (comment != null) 'comment': comment,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (isLocalPending != null) 'is_local_pending': isLocalPending,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalApprovalAuditLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? requisitionId,
    Value<int>? level,
    Value<String>? action,
    Value<String?>? actorId,
    Value<String>? actorName,
    Value<String?>? actorRole,
    Value<String>? channel,
    Value<String?>? comment,
    Value<DateTime>? occurredAt,
    Value<bool>? isLocalPending,
    Value<int>? rowid,
  }) {
    return LocalApprovalAuditLogsCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      requisitionId: requisitionId ?? this.requisitionId,
      level: level ?? this.level,
      action: action ?? this.action,
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
      actorRole: actorRole ?? this.actorRole,
      channel: channel ?? this.channel,
      comment: comment ?? this.comment,
      occurredAt: occurredAt ?? this.occurredAt,
      isLocalPending: isLocalPending ?? this.isLocalPending,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (requisitionId.present) {
      map['requisition_id'] = Variable<String>(requisitionId.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (actorId.present) {
      map['actor_id'] = Variable<String>(actorId.value);
    }
    if (actorName.present) {
      map['actor_name'] = Variable<String>(actorName.value);
    }
    if (actorRole.present) {
      map['actor_role'] = Variable<String>(actorRole.value);
    }
    if (channel.present) {
      map['channel'] = Variable<String>(channel.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (isLocalPending.present) {
      map['is_local_pending'] = Variable<bool>(isLocalPending.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalApprovalAuditLogsCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('requisitionId: $requisitionId, ')
          ..write('level: $level, ')
          ..write('action: $action, ')
          ..write('actorId: $actorId, ')
          ..write('actorName: $actorName, ')
          ..write('actorRole: $actorRole, ')
          ..write('channel: $channel, ')
          ..write('comment: $comment, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('isLocalPending: $isLocalPending, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MfgLocalWorkCentersTable extends MfgLocalWorkCenters
    with TableInfo<$MfgLocalWorkCentersTable, MfgWorkCenterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MfgLocalWorkCentersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    id,
    code,
    name,
    status,
    payload,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mfg_work_centers';
  @override
  VerificationContext validateIntegrity(
    Insertable<MfgWorkCenterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, id};
  @override
  MfgWorkCenterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MfgWorkCenterRow(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $MfgLocalWorkCentersTable createAlias(String alias) {
    return $MfgLocalWorkCentersTable(attachedDatabase, alias);
  }
}

class MfgWorkCenterRow extends DataClass
    implements Insertable<MfgWorkCenterRow> {
  final String tenantId;
  final String id;
  final String code;
  final String name;
  final String status;
  final String payload;
  final DateTime syncedAt;
  const MfgWorkCenterRow({
    required this.tenantId,
    required this.id,
    required this.code,
    required this.name,
    required this.status,
    required this.payload,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['status'] = Variable<String>(status);
    map['payload'] = Variable<String>(payload);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  MfgLocalWorkCentersCompanion toCompanion(bool nullToAbsent) {
    return MfgLocalWorkCentersCompanion(
      tenantId: Value(tenantId),
      id: Value(id),
      code: Value(code),
      name: Value(name),
      status: Value(status),
      payload: Value(payload),
      syncedAt: Value(syncedAt),
    );
  }

  factory MfgWorkCenterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MfgWorkCenterRow(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      status: serializer.fromJson<String>(json['status']),
      payload: serializer.fromJson<String>(json['payload']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'status': serializer.toJson<String>(status),
      'payload': serializer.toJson<String>(payload),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  MfgWorkCenterRow copyWith({
    String? tenantId,
    String? id,
    String? code,
    String? name,
    String? status,
    String? payload,
    DateTime? syncedAt,
  }) => MfgWorkCenterRow(
    tenantId: tenantId ?? this.tenantId,
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    status: status ?? this.status,
    payload: payload ?? this.payload,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  MfgWorkCenterRow copyWithCompanion(MfgLocalWorkCentersCompanion data) {
    return MfgWorkCenterRow(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      status: data.status.present ? data.status.value : this.status,
      payload: data.payload.present ? data.payload.value : this.payload,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MfgWorkCenterRow(')
          ..write('tenantId: $tenantId, ')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('status: $status, ')
          ..write('payload: $payload, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(tenantId, id, code, name, status, payload, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MfgWorkCenterRow &&
          other.tenantId == this.tenantId &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.status == this.status &&
          other.payload == this.payload &&
          other.syncedAt == this.syncedAt);
}

class MfgLocalWorkCentersCompanion extends UpdateCompanion<MfgWorkCenterRow> {
  final Value<String> tenantId;
  final Value<String> id;
  final Value<String> code;
  final Value<String> name;
  final Value<String> status;
  final Value<String> payload;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const MfgLocalWorkCentersCompanion({
    this.tenantId = const Value.absent(),
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.status = const Value.absent(),
    this.payload = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MfgLocalWorkCentersCompanion.insert({
    required String tenantId,
    required String id,
    required String code,
    required String name,
    this.status = const Value.absent(),
    required String payload,
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       id = Value(id),
       code = Value(code),
       name = Value(name),
       payload = Value(payload),
       syncedAt = Value(syncedAt);
  static Insertable<MfgWorkCenterRow> custom({
    Expression<String>? tenantId,
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? status,
    Expression<String>? payload,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (status != null) 'status': status,
      if (payload != null) 'payload': payload,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MfgLocalWorkCentersCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? id,
    Value<String>? code,
    Value<String>? name,
    Value<String>? status,
    Value<String>? payload,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return MfgLocalWorkCentersCompanion(
      tenantId: tenantId ?? this.tenantId,
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      status: status ?? this.status,
      payload: payload ?? this.payload,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MfgLocalWorkCentersCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('status: $status, ')
          ..write('payload: $payload, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MfgLocalMachinesTable extends MfgLocalMachines
    with TableInfo<$MfgLocalMachinesTable, MfgMachineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MfgLocalMachinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workCenterIdMeta = const VerificationMeta(
    'workCenterId',
  );
  @override
  late final GeneratedColumn<String> workCenterId = GeneratedColumn<String>(
    'work_center_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    id,
    code,
    name,
    workCenterId,
    status,
    payload,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mfg_machines';
  @override
  VerificationContext validateIntegrity(
    Insertable<MfgMachineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('work_center_id')) {
      context.handle(
        _workCenterIdMeta,
        workCenterId.isAcceptableOrUnknown(
          data['work_center_id']!,
          _workCenterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workCenterIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, id};
  @override
  MfgMachineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MfgMachineRow(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      workCenterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_center_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $MfgLocalMachinesTable createAlias(String alias) {
    return $MfgLocalMachinesTable(attachedDatabase, alias);
  }
}

class MfgMachineRow extends DataClass implements Insertable<MfgMachineRow> {
  final String tenantId;
  final String id;
  final String code;
  final String name;
  final String workCenterId;
  final String status;
  final String payload;
  final DateTime syncedAt;
  const MfgMachineRow({
    required this.tenantId,
    required this.id,
    required this.code,
    required this.name,
    required this.workCenterId,
    required this.status,
    required this.payload,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['work_center_id'] = Variable<String>(workCenterId);
    map['status'] = Variable<String>(status);
    map['payload'] = Variable<String>(payload);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  MfgLocalMachinesCompanion toCompanion(bool nullToAbsent) {
    return MfgLocalMachinesCompanion(
      tenantId: Value(tenantId),
      id: Value(id),
      code: Value(code),
      name: Value(name),
      workCenterId: Value(workCenterId),
      status: Value(status),
      payload: Value(payload),
      syncedAt: Value(syncedAt),
    );
  }

  factory MfgMachineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MfgMachineRow(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      workCenterId: serializer.fromJson<String>(json['workCenterId']),
      status: serializer.fromJson<String>(json['status']),
      payload: serializer.fromJson<String>(json['payload']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'workCenterId': serializer.toJson<String>(workCenterId),
      'status': serializer.toJson<String>(status),
      'payload': serializer.toJson<String>(payload),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  MfgMachineRow copyWith({
    String? tenantId,
    String? id,
    String? code,
    String? name,
    String? workCenterId,
    String? status,
    String? payload,
    DateTime? syncedAt,
  }) => MfgMachineRow(
    tenantId: tenantId ?? this.tenantId,
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    workCenterId: workCenterId ?? this.workCenterId,
    status: status ?? this.status,
    payload: payload ?? this.payload,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  MfgMachineRow copyWithCompanion(MfgLocalMachinesCompanion data) {
    return MfgMachineRow(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      workCenterId: data.workCenterId.present
          ? data.workCenterId.value
          : this.workCenterId,
      status: data.status.present ? data.status.value : this.status,
      payload: data.payload.present ? data.payload.value : this.payload,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MfgMachineRow(')
          ..write('tenantId: $tenantId, ')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('workCenterId: $workCenterId, ')
          ..write('status: $status, ')
          ..write('payload: $payload, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tenantId,
    id,
    code,
    name,
    workCenterId,
    status,
    payload,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MfgMachineRow &&
          other.tenantId == this.tenantId &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.workCenterId == this.workCenterId &&
          other.status == this.status &&
          other.payload == this.payload &&
          other.syncedAt == this.syncedAt);
}

class MfgLocalMachinesCompanion extends UpdateCompanion<MfgMachineRow> {
  final Value<String> tenantId;
  final Value<String> id;
  final Value<String> code;
  final Value<String> name;
  final Value<String> workCenterId;
  final Value<String> status;
  final Value<String> payload;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const MfgLocalMachinesCompanion({
    this.tenantId = const Value.absent(),
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.workCenterId = const Value.absent(),
    this.status = const Value.absent(),
    this.payload = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MfgLocalMachinesCompanion.insert({
    required String tenantId,
    required String id,
    required String code,
    required String name,
    required String workCenterId,
    this.status = const Value.absent(),
    required String payload,
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       id = Value(id),
       code = Value(code),
       name = Value(name),
       workCenterId = Value(workCenterId),
       payload = Value(payload),
       syncedAt = Value(syncedAt);
  static Insertable<MfgMachineRow> custom({
    Expression<String>? tenantId,
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? workCenterId,
    Expression<String>? status,
    Expression<String>? payload,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (workCenterId != null) 'work_center_id': workCenterId,
      if (status != null) 'status': status,
      if (payload != null) 'payload': payload,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MfgLocalMachinesCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? id,
    Value<String>? code,
    Value<String>? name,
    Value<String>? workCenterId,
    Value<String>? status,
    Value<String>? payload,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return MfgLocalMachinesCompanion(
      tenantId: tenantId ?? this.tenantId,
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      workCenterId: workCenterId ?? this.workCenterId,
      status: status ?? this.status,
      payload: payload ?? this.payload,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (workCenterId.present) {
      map['work_center_id'] = Variable<String>(workCenterId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MfgLocalMachinesCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('workCenterId: $workCenterId, ')
          ..write('status: $status, ')
          ..write('payload: $payload, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MfgLocalRoutingsTable extends MfgLocalRoutings
    with TableInfo<$MfgLocalRoutingsTable, MfgRoutingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MfgLocalRoutingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _routingNumberMeta = const VerificationMeta(
    'routingNumber',
  );
  @override
  late final GeneratedColumn<String> routingNumber = GeneratedColumn<String>(
    'routing_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<String> revision = GeneratedColumn<String>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    id,
    routingNumber,
    name,
    revision,
    status,
    isDefault,
    payload,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mfg_routings';
  @override
  VerificationContext validateIntegrity(
    Insertable<MfgRoutingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('routing_number')) {
      context.handle(
        _routingNumberMeta,
        routingNumber.isAcceptableOrUnknown(
          data['routing_number']!,
          _routingNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_routingNumberMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, id};
  @override
  MfgRoutingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MfgRoutingRow(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      routingNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}routing_number'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revision'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $MfgLocalRoutingsTable createAlias(String alias) {
    return $MfgLocalRoutingsTable(attachedDatabase, alias);
  }
}

class MfgRoutingRow extends DataClass implements Insertable<MfgRoutingRow> {
  final String tenantId;
  final String id;
  final String routingNumber;
  final String name;
  final String revision;
  final String status;
  final bool isDefault;
  final String payload;
  final DateTime syncedAt;
  const MfgRoutingRow({
    required this.tenantId,
    required this.id,
    required this.routingNumber,
    required this.name,
    required this.revision,
    required this.status,
    required this.isDefault,
    required this.payload,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['id'] = Variable<String>(id);
    map['routing_number'] = Variable<String>(routingNumber);
    map['name'] = Variable<String>(name);
    map['revision'] = Variable<String>(revision);
    map['status'] = Variable<String>(status);
    map['is_default'] = Variable<bool>(isDefault);
    map['payload'] = Variable<String>(payload);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  MfgLocalRoutingsCompanion toCompanion(bool nullToAbsent) {
    return MfgLocalRoutingsCompanion(
      tenantId: Value(tenantId),
      id: Value(id),
      routingNumber: Value(routingNumber),
      name: Value(name),
      revision: Value(revision),
      status: Value(status),
      isDefault: Value(isDefault),
      payload: Value(payload),
      syncedAt: Value(syncedAt),
    );
  }

  factory MfgRoutingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MfgRoutingRow(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      id: serializer.fromJson<String>(json['id']),
      routingNumber: serializer.fromJson<String>(json['routingNumber']),
      name: serializer.fromJson<String>(json['name']),
      revision: serializer.fromJson<String>(json['revision']),
      status: serializer.fromJson<String>(json['status']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      payload: serializer.fromJson<String>(json['payload']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'id': serializer.toJson<String>(id),
      'routingNumber': serializer.toJson<String>(routingNumber),
      'name': serializer.toJson<String>(name),
      'revision': serializer.toJson<String>(revision),
      'status': serializer.toJson<String>(status),
      'isDefault': serializer.toJson<bool>(isDefault),
      'payload': serializer.toJson<String>(payload),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  MfgRoutingRow copyWith({
    String? tenantId,
    String? id,
    String? routingNumber,
    String? name,
    String? revision,
    String? status,
    bool? isDefault,
    String? payload,
    DateTime? syncedAt,
  }) => MfgRoutingRow(
    tenantId: tenantId ?? this.tenantId,
    id: id ?? this.id,
    routingNumber: routingNumber ?? this.routingNumber,
    name: name ?? this.name,
    revision: revision ?? this.revision,
    status: status ?? this.status,
    isDefault: isDefault ?? this.isDefault,
    payload: payload ?? this.payload,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  MfgRoutingRow copyWithCompanion(MfgLocalRoutingsCompanion data) {
    return MfgRoutingRow(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      id: data.id.present ? data.id.value : this.id,
      routingNumber: data.routingNumber.present
          ? data.routingNumber.value
          : this.routingNumber,
      name: data.name.present ? data.name.value : this.name,
      revision: data.revision.present ? data.revision.value : this.revision,
      status: data.status.present ? data.status.value : this.status,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      payload: data.payload.present ? data.payload.value : this.payload,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MfgRoutingRow(')
          ..write('tenantId: $tenantId, ')
          ..write('id: $id, ')
          ..write('routingNumber: $routingNumber, ')
          ..write('name: $name, ')
          ..write('revision: $revision, ')
          ..write('status: $status, ')
          ..write('isDefault: $isDefault, ')
          ..write('payload: $payload, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tenantId,
    id,
    routingNumber,
    name,
    revision,
    status,
    isDefault,
    payload,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MfgRoutingRow &&
          other.tenantId == this.tenantId &&
          other.id == this.id &&
          other.routingNumber == this.routingNumber &&
          other.name == this.name &&
          other.revision == this.revision &&
          other.status == this.status &&
          other.isDefault == this.isDefault &&
          other.payload == this.payload &&
          other.syncedAt == this.syncedAt);
}

class MfgLocalRoutingsCompanion extends UpdateCompanion<MfgRoutingRow> {
  final Value<String> tenantId;
  final Value<String> id;
  final Value<String> routingNumber;
  final Value<String> name;
  final Value<String> revision;
  final Value<String> status;
  final Value<bool> isDefault;
  final Value<String> payload;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const MfgLocalRoutingsCompanion({
    this.tenantId = const Value.absent(),
    this.id = const Value.absent(),
    this.routingNumber = const Value.absent(),
    this.name = const Value.absent(),
    this.revision = const Value.absent(),
    this.status = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.payload = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MfgLocalRoutingsCompanion.insert({
    required String tenantId,
    required String id,
    required String routingNumber,
    required String name,
    required String revision,
    required String status,
    this.isDefault = const Value.absent(),
    required String payload,
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       id = Value(id),
       routingNumber = Value(routingNumber),
       name = Value(name),
       revision = Value(revision),
       status = Value(status),
       payload = Value(payload),
       syncedAt = Value(syncedAt);
  static Insertable<MfgRoutingRow> custom({
    Expression<String>? tenantId,
    Expression<String>? id,
    Expression<String>? routingNumber,
    Expression<String>? name,
    Expression<String>? revision,
    Expression<String>? status,
    Expression<bool>? isDefault,
    Expression<String>? payload,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (id != null) 'id': id,
      if (routingNumber != null) 'routing_number': routingNumber,
      if (name != null) 'name': name,
      if (revision != null) 'revision': revision,
      if (status != null) 'status': status,
      if (isDefault != null) 'is_default': isDefault,
      if (payload != null) 'payload': payload,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MfgLocalRoutingsCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? id,
    Value<String>? routingNumber,
    Value<String>? name,
    Value<String>? revision,
    Value<String>? status,
    Value<bool>? isDefault,
    Value<String>? payload,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return MfgLocalRoutingsCompanion(
      tenantId: tenantId ?? this.tenantId,
      id: id ?? this.id,
      routingNumber: routingNumber ?? this.routingNumber,
      name: name ?? this.name,
      revision: revision ?? this.revision,
      status: status ?? this.status,
      isDefault: isDefault ?? this.isDefault,
      payload: payload ?? this.payload,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (routingNumber.present) {
      map['routing_number'] = Variable<String>(routingNumber.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (revision.present) {
      map['revision'] = Variable<String>(revision.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MfgLocalRoutingsCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('id: $id, ')
          ..write('routingNumber: $routingNumber, ')
          ..write('name: $name, ')
          ..write('revision: $revision, ')
          ..write('status: $status, ')
          ..write('isDefault: $isDefault, ')
          ..write('payload: $payload, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MfgLocalRoutingStepsTable extends MfgLocalRoutingSteps
    with TableInfo<$MfgLocalRoutingStepsTable, MfgRoutingStepRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MfgLocalRoutingStepsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _routingIdMeta = const VerificationMeta(
    'routingId',
  );
  @override
  late final GeneratedColumn<String> routingId = GeneratedColumn<String>(
    'routing_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workCenterIdMeta = const VerificationMeta(
    'workCenterId',
  );
  @override
  late final GeneratedColumn<String> workCenterId = GeneratedColumn<String>(
    'work_center_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _machineCenterIdMeta = const VerificationMeta(
    'machineCenterId',
  );
  @override
  late final GeneratedColumn<String> machineCenterId = GeneratedColumn<String>(
    'machine_center_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    id,
    routingId,
    sequence,
    workCenterId,
    machineCenterId,
    payload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mfg_routing_steps';
  @override
  VerificationContext validateIntegrity(
    Insertable<MfgRoutingStepRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('routing_id')) {
      context.handle(
        _routingIdMeta,
        routingId.isAcceptableOrUnknown(data['routing_id']!, _routingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_routingIdMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    if (data.containsKey('work_center_id')) {
      context.handle(
        _workCenterIdMeta,
        workCenterId.isAcceptableOrUnknown(
          data['work_center_id']!,
          _workCenterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workCenterIdMeta);
    }
    if (data.containsKey('machine_center_id')) {
      context.handle(
        _machineCenterIdMeta,
        machineCenterId.isAcceptableOrUnknown(
          data['machine_center_id']!,
          _machineCenterIdMeta,
        ),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, id};
  @override
  MfgRoutingStepRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MfgRoutingStepRow(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      routingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}routing_id'],
      )!,
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      workCenterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_center_id'],
      )!,
      machineCenterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}machine_center_id'],
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $MfgLocalRoutingStepsTable createAlias(String alias) {
    return $MfgLocalRoutingStepsTable(attachedDatabase, alias);
  }
}

class MfgRoutingStepRow extends DataClass
    implements Insertable<MfgRoutingStepRow> {
  final String tenantId;
  final String id;
  final String routingId;
  final int sequence;
  final String workCenterId;
  final String? machineCenterId;
  final String payload;
  const MfgRoutingStepRow({
    required this.tenantId,
    required this.id,
    required this.routingId,
    required this.sequence,
    required this.workCenterId,
    this.machineCenterId,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['id'] = Variable<String>(id);
    map['routing_id'] = Variable<String>(routingId);
    map['sequence'] = Variable<int>(sequence);
    map['work_center_id'] = Variable<String>(workCenterId);
    if (!nullToAbsent || machineCenterId != null) {
      map['machine_center_id'] = Variable<String>(machineCenterId);
    }
    map['payload'] = Variable<String>(payload);
    return map;
  }

  MfgLocalRoutingStepsCompanion toCompanion(bool nullToAbsent) {
    return MfgLocalRoutingStepsCompanion(
      tenantId: Value(tenantId),
      id: Value(id),
      routingId: Value(routingId),
      sequence: Value(sequence),
      workCenterId: Value(workCenterId),
      machineCenterId: machineCenterId == null && nullToAbsent
          ? const Value.absent()
          : Value(machineCenterId),
      payload: Value(payload),
    );
  }

  factory MfgRoutingStepRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MfgRoutingStepRow(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      id: serializer.fromJson<String>(json['id']),
      routingId: serializer.fromJson<String>(json['routingId']),
      sequence: serializer.fromJson<int>(json['sequence']),
      workCenterId: serializer.fromJson<String>(json['workCenterId']),
      machineCenterId: serializer.fromJson<String?>(json['machineCenterId']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'id': serializer.toJson<String>(id),
      'routingId': serializer.toJson<String>(routingId),
      'sequence': serializer.toJson<int>(sequence),
      'workCenterId': serializer.toJson<String>(workCenterId),
      'machineCenterId': serializer.toJson<String?>(machineCenterId),
      'payload': serializer.toJson<String>(payload),
    };
  }

  MfgRoutingStepRow copyWith({
    String? tenantId,
    String? id,
    String? routingId,
    int? sequence,
    String? workCenterId,
    Value<String?> machineCenterId = const Value.absent(),
    String? payload,
  }) => MfgRoutingStepRow(
    tenantId: tenantId ?? this.tenantId,
    id: id ?? this.id,
    routingId: routingId ?? this.routingId,
    sequence: sequence ?? this.sequence,
    workCenterId: workCenterId ?? this.workCenterId,
    machineCenterId: machineCenterId.present
        ? machineCenterId.value
        : this.machineCenterId,
    payload: payload ?? this.payload,
  );
  MfgRoutingStepRow copyWithCompanion(MfgLocalRoutingStepsCompanion data) {
    return MfgRoutingStepRow(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      id: data.id.present ? data.id.value : this.id,
      routingId: data.routingId.present ? data.routingId.value : this.routingId,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      workCenterId: data.workCenterId.present
          ? data.workCenterId.value
          : this.workCenterId,
      machineCenterId: data.machineCenterId.present
          ? data.machineCenterId.value
          : this.machineCenterId,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MfgRoutingStepRow(')
          ..write('tenantId: $tenantId, ')
          ..write('id: $id, ')
          ..write('routingId: $routingId, ')
          ..write('sequence: $sequence, ')
          ..write('workCenterId: $workCenterId, ')
          ..write('machineCenterId: $machineCenterId, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tenantId,
    id,
    routingId,
    sequence,
    workCenterId,
    machineCenterId,
    payload,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MfgRoutingStepRow &&
          other.tenantId == this.tenantId &&
          other.id == this.id &&
          other.routingId == this.routingId &&
          other.sequence == this.sequence &&
          other.workCenterId == this.workCenterId &&
          other.machineCenterId == this.machineCenterId &&
          other.payload == this.payload);
}

class MfgLocalRoutingStepsCompanion extends UpdateCompanion<MfgRoutingStepRow> {
  final Value<String> tenantId;
  final Value<String> id;
  final Value<String> routingId;
  final Value<int> sequence;
  final Value<String> workCenterId;
  final Value<String?> machineCenterId;
  final Value<String> payload;
  final Value<int> rowid;
  const MfgLocalRoutingStepsCompanion({
    this.tenantId = const Value.absent(),
    this.id = const Value.absent(),
    this.routingId = const Value.absent(),
    this.sequence = const Value.absent(),
    this.workCenterId = const Value.absent(),
    this.machineCenterId = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MfgLocalRoutingStepsCompanion.insert({
    required String tenantId,
    required String id,
    required String routingId,
    required int sequence,
    required String workCenterId,
    this.machineCenterId = const Value.absent(),
    required String payload,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       id = Value(id),
       routingId = Value(routingId),
       sequence = Value(sequence),
       workCenterId = Value(workCenterId),
       payload = Value(payload);
  static Insertable<MfgRoutingStepRow> custom({
    Expression<String>? tenantId,
    Expression<String>? id,
    Expression<String>? routingId,
    Expression<int>? sequence,
    Expression<String>? workCenterId,
    Expression<String>? machineCenterId,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (id != null) 'id': id,
      if (routingId != null) 'routing_id': routingId,
      if (sequence != null) 'sequence': sequence,
      if (workCenterId != null) 'work_center_id': workCenterId,
      if (machineCenterId != null) 'machine_center_id': machineCenterId,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MfgLocalRoutingStepsCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? id,
    Value<String>? routingId,
    Value<int>? sequence,
    Value<String>? workCenterId,
    Value<String?>? machineCenterId,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return MfgLocalRoutingStepsCompanion(
      tenantId: tenantId ?? this.tenantId,
      id: id ?? this.id,
      routingId: routingId ?? this.routingId,
      sequence: sequence ?? this.sequence,
      workCenterId: workCenterId ?? this.workCenterId,
      machineCenterId: machineCenterId ?? this.machineCenterId,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (routingId.present) {
      map['routing_id'] = Variable<String>(routingId.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (workCenterId.present) {
      map['work_center_id'] = Variable<String>(workCenterId.value);
    }
    if (machineCenterId.present) {
      map['machine_center_id'] = Variable<String>(machineCenterId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MfgLocalRoutingStepsCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('id: $id, ')
          ..write('routingId: $routingId, ')
          ..write('sequence: $sequence, ')
          ..write('workCenterId: $workCenterId, ')
          ..write('machineCenterId: $machineCenterId, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MfgLocalOeeSummariesTable extends MfgLocalOeeSummaries
    with TableInfo<$MfgLocalOeeSummariesTable, MfgOeeSummaryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MfgLocalOeeSummariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeKeyMeta = const VerificationMeta(
    'scopeKey',
  );
  @override
  late final GeneratedColumn<String> scopeKey = GeneratedColumn<String>(
    'scope_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workCenterIdMeta = const VerificationMeta(
    'workCenterId',
  );
  @override
  late final GeneratedColumn<String> workCenterId = GeneratedColumn<String>(
    'work_center_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _machineCenterIdMeta = const VerificationMeta(
    'machineCenterId',
  );
  @override
  late final GeneratedColumn<String> machineCenterId = GeneratedColumn<String>(
    'machine_center_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fromAtMeta = const VerificationMeta('fromAt');
  @override
  late final GeneratedColumn<DateTime> fromAt = GeneratedColumn<DateTime>(
    'from_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toAtMeta = const VerificationMeta('toAt');
  @override
  late final GeneratedColumn<DateTime> toAt = GeneratedColumn<DateTime>(
    'to_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    scopeKey,
    workCenterId,
    machineCenterId,
    fromAt,
    toAt,
    payload,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mfg_oee_summaries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MfgOeeSummaryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('scope_key')) {
      context.handle(
        _scopeKeyMeta,
        scopeKey.isAcceptableOrUnknown(data['scope_key']!, _scopeKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKeyMeta);
    }
    if (data.containsKey('work_center_id')) {
      context.handle(
        _workCenterIdMeta,
        workCenterId.isAcceptableOrUnknown(
          data['work_center_id']!,
          _workCenterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workCenterIdMeta);
    }
    if (data.containsKey('machine_center_id')) {
      context.handle(
        _machineCenterIdMeta,
        machineCenterId.isAcceptableOrUnknown(
          data['machine_center_id']!,
          _machineCenterIdMeta,
        ),
      );
    }
    if (data.containsKey('from_at')) {
      context.handle(
        _fromAtMeta,
        fromAt.isAcceptableOrUnknown(data['from_at']!, _fromAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fromAtMeta);
    }
    if (data.containsKey('to_at')) {
      context.handle(
        _toAtMeta,
        toAt.isAcceptableOrUnknown(data['to_at']!, _toAtMeta),
      );
    } else if (isInserting) {
      context.missing(_toAtMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tenantId, scopeKey};
  @override
  MfgOeeSummaryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MfgOeeSummaryRow(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      scopeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_key'],
      )!,
      workCenterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_center_id'],
      )!,
      machineCenterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}machine_center_id'],
      ),
      fromAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}from_at'],
      )!,
      toAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}to_at'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $MfgLocalOeeSummariesTable createAlias(String alias) {
    return $MfgLocalOeeSummariesTable(attachedDatabase, alias);
  }
}

class MfgOeeSummaryRow extends DataClass
    implements Insertable<MfgOeeSummaryRow> {
  final String tenantId;

  /// `<workCenterId>:<machineId|all>`.
  final String scopeKey;
  final String workCenterId;
  final String? machineCenterId;
  final DateTime fromAt;
  final DateTime toAt;
  final String payload;
  final DateTime syncedAt;
  const MfgOeeSummaryRow({
    required this.tenantId,
    required this.scopeKey,
    required this.workCenterId,
    this.machineCenterId,
    required this.fromAt,
    required this.toAt,
    required this.payload,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['scope_key'] = Variable<String>(scopeKey);
    map['work_center_id'] = Variable<String>(workCenterId);
    if (!nullToAbsent || machineCenterId != null) {
      map['machine_center_id'] = Variable<String>(machineCenterId);
    }
    map['from_at'] = Variable<DateTime>(fromAt);
    map['to_at'] = Variable<DateTime>(toAt);
    map['payload'] = Variable<String>(payload);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  MfgLocalOeeSummariesCompanion toCompanion(bool nullToAbsent) {
    return MfgLocalOeeSummariesCompanion(
      tenantId: Value(tenantId),
      scopeKey: Value(scopeKey),
      workCenterId: Value(workCenterId),
      machineCenterId: machineCenterId == null && nullToAbsent
          ? const Value.absent()
          : Value(machineCenterId),
      fromAt: Value(fromAt),
      toAt: Value(toAt),
      payload: Value(payload),
      syncedAt: Value(syncedAt),
    );
  }

  factory MfgOeeSummaryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MfgOeeSummaryRow(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      scopeKey: serializer.fromJson<String>(json['scopeKey']),
      workCenterId: serializer.fromJson<String>(json['workCenterId']),
      machineCenterId: serializer.fromJson<String?>(json['machineCenterId']),
      fromAt: serializer.fromJson<DateTime>(json['fromAt']),
      toAt: serializer.fromJson<DateTime>(json['toAt']),
      payload: serializer.fromJson<String>(json['payload']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'scopeKey': serializer.toJson<String>(scopeKey),
      'workCenterId': serializer.toJson<String>(workCenterId),
      'machineCenterId': serializer.toJson<String?>(machineCenterId),
      'fromAt': serializer.toJson<DateTime>(fromAt),
      'toAt': serializer.toJson<DateTime>(toAt),
      'payload': serializer.toJson<String>(payload),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  MfgOeeSummaryRow copyWith({
    String? tenantId,
    String? scopeKey,
    String? workCenterId,
    Value<String?> machineCenterId = const Value.absent(),
    DateTime? fromAt,
    DateTime? toAt,
    String? payload,
    DateTime? syncedAt,
  }) => MfgOeeSummaryRow(
    tenantId: tenantId ?? this.tenantId,
    scopeKey: scopeKey ?? this.scopeKey,
    workCenterId: workCenterId ?? this.workCenterId,
    machineCenterId: machineCenterId.present
        ? machineCenterId.value
        : this.machineCenterId,
    fromAt: fromAt ?? this.fromAt,
    toAt: toAt ?? this.toAt,
    payload: payload ?? this.payload,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  MfgOeeSummaryRow copyWithCompanion(MfgLocalOeeSummariesCompanion data) {
    return MfgOeeSummaryRow(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      scopeKey: data.scopeKey.present ? data.scopeKey.value : this.scopeKey,
      workCenterId: data.workCenterId.present
          ? data.workCenterId.value
          : this.workCenterId,
      machineCenterId: data.machineCenterId.present
          ? data.machineCenterId.value
          : this.machineCenterId,
      fromAt: data.fromAt.present ? data.fromAt.value : this.fromAt,
      toAt: data.toAt.present ? data.toAt.value : this.toAt,
      payload: data.payload.present ? data.payload.value : this.payload,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MfgOeeSummaryRow(')
          ..write('tenantId: $tenantId, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('workCenterId: $workCenterId, ')
          ..write('machineCenterId: $machineCenterId, ')
          ..write('fromAt: $fromAt, ')
          ..write('toAt: $toAt, ')
          ..write('payload: $payload, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tenantId,
    scopeKey,
    workCenterId,
    machineCenterId,
    fromAt,
    toAt,
    payload,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MfgOeeSummaryRow &&
          other.tenantId == this.tenantId &&
          other.scopeKey == this.scopeKey &&
          other.workCenterId == this.workCenterId &&
          other.machineCenterId == this.machineCenterId &&
          other.fromAt == this.fromAt &&
          other.toAt == this.toAt &&
          other.payload == this.payload &&
          other.syncedAt == this.syncedAt);
}

class MfgLocalOeeSummariesCompanion extends UpdateCompanion<MfgOeeSummaryRow> {
  final Value<String> tenantId;
  final Value<String> scopeKey;
  final Value<String> workCenterId;
  final Value<String?> machineCenterId;
  final Value<DateTime> fromAt;
  final Value<DateTime> toAt;
  final Value<String> payload;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const MfgLocalOeeSummariesCompanion({
    this.tenantId = const Value.absent(),
    this.scopeKey = const Value.absent(),
    this.workCenterId = const Value.absent(),
    this.machineCenterId = const Value.absent(),
    this.fromAt = const Value.absent(),
    this.toAt = const Value.absent(),
    this.payload = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MfgLocalOeeSummariesCompanion.insert({
    required String tenantId,
    required String scopeKey,
    required String workCenterId,
    this.machineCenterId = const Value.absent(),
    required DateTime fromAt,
    required DateTime toAt,
    required String payload,
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       scopeKey = Value(scopeKey),
       workCenterId = Value(workCenterId),
       fromAt = Value(fromAt),
       toAt = Value(toAt),
       payload = Value(payload),
       syncedAt = Value(syncedAt);
  static Insertable<MfgOeeSummaryRow> custom({
    Expression<String>? tenantId,
    Expression<String>? scopeKey,
    Expression<String>? workCenterId,
    Expression<String>? machineCenterId,
    Expression<DateTime>? fromAt,
    Expression<DateTime>? toAt,
    Expression<String>? payload,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (scopeKey != null) 'scope_key': scopeKey,
      if (workCenterId != null) 'work_center_id': workCenterId,
      if (machineCenterId != null) 'machine_center_id': machineCenterId,
      if (fromAt != null) 'from_at': fromAt,
      if (toAt != null) 'to_at': toAt,
      if (payload != null) 'payload': payload,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MfgLocalOeeSummariesCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? scopeKey,
    Value<String>? workCenterId,
    Value<String?>? machineCenterId,
    Value<DateTime>? fromAt,
    Value<DateTime>? toAt,
    Value<String>? payload,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return MfgLocalOeeSummariesCompanion(
      tenantId: tenantId ?? this.tenantId,
      scopeKey: scopeKey ?? this.scopeKey,
      workCenterId: workCenterId ?? this.workCenterId,
      machineCenterId: machineCenterId ?? this.machineCenterId,
      fromAt: fromAt ?? this.fromAt,
      toAt: toAt ?? this.toAt,
      payload: payload ?? this.payload,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (scopeKey.present) {
      map['scope_key'] = Variable<String>(scopeKey.value);
    }
    if (workCenterId.present) {
      map['work_center_id'] = Variable<String>(workCenterId.value);
    }
    if (machineCenterId.present) {
      map['machine_center_id'] = Variable<String>(machineCenterId.value);
    }
    if (fromAt.present) {
      map['from_at'] = Variable<DateTime>(fromAt.value);
    }
    if (toAt.present) {
      map['to_at'] = Variable<DateTime>(toAt.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MfgLocalOeeSummariesCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('scopeKey: $scopeKey, ')
          ..write('workCenterId: $workCenterId, ')
          ..write('machineCenterId: $machineCenterId, ')
          ..write('fromAt: $fromAt, ')
          ..write('toAt: $toAt, ')
          ..write('payload: $payload, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EntityRecordsTable entityRecords = $EntityRecordsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $SyncCursorsTable syncCursors = $SyncCursorsTable(this);
  late final $TranslationsTable translations = $TranslationsTable(this);
  late final $CopilotConversationsTable copilotConversations =
      $CopilotConversationsTable(this);
  late final $CopilotMessagesTable copilotMessages = $CopilotMessagesTable(
    this,
  );
  late final $AuditQueueEntriesTable auditQueueEntries =
      $AuditQueueEntriesTable(this);
  late final $DssExecutiveSnapshotsTable dssExecutiveSnapshots =
      $DssExecutiveSnapshotsTable(this);
  late final $PermissionSnapshotsTable permissionSnapshots =
      $PermissionSnapshotsTable(this);
  late final $LocalPurchaseRequisitionsTable localPurchaseRequisitions =
      $LocalPurchaseRequisitionsTable(this);
  late final $LocalPurchaseRequisitionLinesTable localPurchaseRequisitionLines =
      $LocalPurchaseRequisitionLinesTable(this);
  late final $LocalPendingApprovalsTable localPendingApprovals =
      $LocalPendingApprovalsTable(this);
  late final $LocalApprovalAuditLogsTable localApprovalAuditLogs =
      $LocalApprovalAuditLogsTable(this);
  late final $MfgLocalWorkCentersTable mfgLocalWorkCenters =
      $MfgLocalWorkCentersTable(this);
  late final $MfgLocalMachinesTable mfgLocalMachines = $MfgLocalMachinesTable(
    this,
  );
  late final $MfgLocalRoutingsTable mfgLocalRoutings = $MfgLocalRoutingsTable(
    this,
  );
  late final $MfgLocalRoutingStepsTable mfgLocalRoutingSteps =
      $MfgLocalRoutingStepsTable(this);
  late final $MfgLocalOeeSummariesTable mfgLocalOeeSummaries =
      $MfgLocalOeeSummariesTable(this);
  late final PurchaseRequisitionDao purchaseRequisitionDao =
      PurchaseRequisitionDao(this as AppDatabase);
  late final ManufacturingDao manufacturingDao = ManufacturingDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    entityRecords,
    syncQueue,
    syncCursors,
    translations,
    copilotConversations,
    copilotMessages,
    auditQueueEntries,
    dssExecutiveSnapshots,
    permissionSnapshots,
    localPurchaseRequisitions,
    localPurchaseRequisitionLines,
    localPendingApprovals,
    localApprovalAuditLogs,
    mfgLocalWorkCenters,
    mfgLocalMachines,
    mfgLocalRoutings,
    mfgLocalRoutingSteps,
    mfgLocalOeeSummaries,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'local_purchase_requisitions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate(
          'local_purchase_requisition_lines',
          kind: UpdateKind.delete,
        ),
      ],
    ),
  ]);
}

typedef $$EntityRecordsTableCreateCompanionBuilder =
    EntityRecordsCompanion Function({
      required String entity,
      required String id,
      required String tenantId,
      Value<String?> serverId,
      required String payload,
      required SyncStatus syncStatus,
      required DateTime localUpdatedAt,
      Value<DateTime?> serverUpdatedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> createdBy,
      Value<String?> updatedBy,
      Value<int> rowid,
    });
typedef $$EntityRecordsTableUpdateCompanionBuilder =
    EntityRecordsCompanion Function({
      Value<String> entity,
      Value<String> id,
      Value<String> tenantId,
      Value<String?> serverId,
      Value<String> payload,
      Value<SyncStatus> syncStatus,
      Value<DateTime> localUpdatedAt,
      Value<DateTime?> serverUpdatedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> createdBy,
      Value<String?> updatedBy,
      Value<int> rowid,
    });

class $$EntityRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $EntityRecordsTable> {
  $$EntityRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, int> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EntityRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $EntityRecordsTable> {
  $$EntityRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EntityRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntityRecordsTable> {
  $$EntityRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, int> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);
}

class $$EntityRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntityRecordsTable,
          EntityRecord,
          $$EntityRecordsTableFilterComposer,
          $$EntityRecordsTableOrderingComposer,
          $$EntityRecordsTableAnnotationComposer,
          $$EntityRecordsTableCreateCompanionBuilder,
          $$EntityRecordsTableUpdateCompanionBuilder,
          (
            EntityRecord,
            BaseReferences<_$AppDatabase, $EntityRecordsTable, EntityRecord>,
          ),
          EntityRecord,
          PrefetchHooks Function()
        > {
  $$EntityRecordsTableTableManager(_$AppDatabase db, $EntityRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntityRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntityRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntityRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entity = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntityRecordsCompanion(
                entity: entity,
                id: id,
                tenantId: tenantId,
                serverId: serverId,
                payload: payload,
                syncStatus: syncStatus,
                localUpdatedAt: localUpdatedAt,
                serverUpdatedAt: serverUpdatedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entity,
                required String id,
                required String tenantId,
                Value<String?> serverId = const Value.absent(),
                required String payload,
                required SyncStatus syncStatus,
                required DateTime localUpdatedAt,
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntityRecordsCompanion.insert(
                entity: entity,
                id: id,
                tenantId: tenantId,
                serverId: serverId,
                payload: payload,
                syncStatus: syncStatus,
                localUpdatedAt: localUpdatedAt,
                serverUpdatedAt: serverUpdatedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EntityRecordsTable, EntityRecord>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $EntityRecordsTable,
                    EntityRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EntityRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntityRecordsTable,
      EntityRecord,
      $$EntityRecordsTableFilterComposer,
      $$EntityRecordsTableOrderingComposer,
      $$EntityRecordsTableAnnotationComposer,
      $$EntityRecordsTableCreateCompanionBuilder,
      $$EntityRecordsTableUpdateCompanionBuilder,
      (
        EntityRecord,
        BaseReferences<_$AppDatabase, $EntityRecordsTable, EntityRecord>,
      ),
      EntityRecord,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> sequence,
  required String uuid,
  required String tenantId,
  required String entity,
  required String entityId,
  required String method,
  required String path,
  Value<String?> payload,
  Value<String?> dependsOn,
  Value<int> attempts,
  Value<String?> lastError,
  Value<int> state,
  required DateTime createdAt,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> sequence,
  Value<String> uuid,
  Value<String> tenantId,
  Value<String> entity,
  Value<String> entityId,
  Value<String> method,
  Value<String> path,
  Value<String?> payload,
  Value<String?> dependsOn,
  Value<int> attempts,
  Value<String?> lastError,
  Value<int> state,
  Value<DateTime> createdAt,
});

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dependsOn => $composableBuilder(
    column: $table.dependsOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dependsOn => $composableBuilder(
    column: $table.dependsOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get dependsOn =>
      $composableBuilder(column: $table.dependsOn, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          QueueItem,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            QueueItem,
            BaseReferences<_$AppDatabase, $SyncQueueTable, QueueItem>,
          ),
          QueueItem,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sequence = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String?> payload = const Value.absent(),
                Value<String?> dependsOn = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> state = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SyncQueueCompanion(
                sequence: sequence,
                uuid: uuid,
                tenantId: tenantId,
                entity: entity,
                entityId: entityId,
                method: method,
                path: path,
                payload: payload,
                dependsOn: dependsOn,
                attempts: attempts,
                lastError: lastError,
                state: state,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> sequence = const Value.absent(),
                required String uuid,
                required String tenantId,
                required String entity,
                required String entityId,
                required String method,
                required String path,
                Value<String?> payload = const Value.absent(),
                Value<String?> dependsOn = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> state = const Value.absent(),
                required DateTime createdAt,
              }) => SyncQueueCompanion.insert(
                sequence: sequence,
                uuid: uuid,
                tenantId: tenantId,
                entity: entity,
                entityId: entityId,
                method: method,
                path: path,
                payload: payload,
                dependsOn: dependsOn,
                attempts: attempts,
                lastError: lastError,
                state: state,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncQueueTable, QueueItem>(table),
                  BaseReferences<_$AppDatabase, $SyncQueueTable, QueueItem>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      QueueItem,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (QueueItem, BaseReferences<_$AppDatabase, $SyncQueueTable, QueueItem>),
      QueueItem,
      PrefetchHooks Function()
    >;
typedef $$SyncCursorsTableCreateCompanionBuilder =
    SyncCursorsCompanion Function({
      required String tenantId,
      required String entity,
      Value<String?> serverTime,
      Value<String?> cursor,
      Value<int> rowid,
    });
typedef $$SyncCursorsTableUpdateCompanionBuilder =
    SyncCursorsCompanion Function({
      Value<String> tenantId,
      Value<String> entity,
      Value<String?> serverTime,
      Value<String?> cursor,
      Value<int> rowid,
    });

class $$SyncCursorsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverTime => $composableBuilder(
    column: $table.serverTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncCursorsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverTime => $composableBuilder(
    column: $table.serverTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncCursorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get serverTime => $composableBuilder(
    column: $table.serverTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);
}

class $$SyncCursorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncCursorsTable,
          SyncCursor,
          $$SyncCursorsTableFilterComposer,
          $$SyncCursorsTableOrderingComposer,
          $$SyncCursorsTableAnnotationComposer,
          $$SyncCursorsTableCreateCompanionBuilder,
          $$SyncCursorsTableUpdateCompanionBuilder,
          (
            SyncCursor,
            BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursor>,
          ),
          SyncCursor,
          PrefetchHooks Function()
        > {
  $$SyncCursorsTableTableManager(_$AppDatabase db, $SyncCursorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String?> serverTime = const Value.absent(),
                Value<String?> cursor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion(
                tenantId: tenantId,
                entity: entity,
                serverTime: serverTime,
                cursor: cursor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String entity,
                Value<String?> serverTime = const Value.absent(),
                Value<String?> cursor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion.insert(
                tenantId: tenantId,
                entity: entity,
                serverTime: serverTime,
                cursor: cursor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncCursorsTable, SyncCursor>(table),
                  BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursor>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncCursorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncCursorsTable,
      SyncCursor,
      $$SyncCursorsTableFilterComposer,
      $$SyncCursorsTableOrderingComposer,
      $$SyncCursorsTableAnnotationComposer,
      $$SyncCursorsTableCreateCompanionBuilder,
      $$SyncCursorsTableUpdateCompanionBuilder,
      (
        SyncCursor,
        BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursor>,
      ),
      SyncCursor,
      PrefetchHooks Function()
    >;
typedef $$TranslationsTableCreateCompanionBuilder =
    TranslationsCompanion Function({
      required String locale,
      Value<String> tenantId,
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$TranslationsTableUpdateCompanionBuilder =
    TranslationsCompanion Function({
      Value<String> locale,
      Value<String> tenantId,
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$TranslationsTableFilterComposer
    extends Composer<_$AppDatabase, $TranslationsTable> {
  $$TranslationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TranslationsTableOrderingComposer
    extends Composer<_$AppDatabase, $TranslationsTable> {
  $$TranslationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TranslationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TranslationsTable> {
  $$TranslationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get locale =>
      $composableBuilder(column: $table.locale, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$TranslationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TranslationsTable,
          Translation,
          $$TranslationsTableFilterComposer,
          $$TranslationsTableOrderingComposer,
          $$TranslationsTableAnnotationComposer,
          $$TranslationsTableCreateCompanionBuilder,
          $$TranslationsTableUpdateCompanionBuilder,
          (
            Translation,
            BaseReferences<_$AppDatabase, $TranslationsTable, Translation>,
          ),
          Translation,
          PrefetchHooks Function()
        > {
  $$TranslationsTableTableManager(_$AppDatabase db, $TranslationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TranslationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TranslationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TranslationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> locale = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TranslationsCompanion(
                locale: locale,
                tenantId: tenantId,
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String locale,
                Value<String> tenantId = const Value.absent(),
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => TranslationsCompanion.insert(
                locale: locale,
                tenantId: tenantId,
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TranslationsTable, Translation>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $TranslationsTable,
                    Translation
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TranslationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TranslationsTable,
      Translation,
      $$TranslationsTableFilterComposer,
      $$TranslationsTableOrderingComposer,
      $$TranslationsTableAnnotationComposer,
      $$TranslationsTableCreateCompanionBuilder,
      $$TranslationsTableUpdateCompanionBuilder,
      (
        Translation,
        BaseReferences<_$AppDatabase, $TranslationsTable, Translation>,
      ),
      Translation,
      PrefetchHooks Function()
    >;
typedef $$CopilotConversationsTableCreateCompanionBuilder =
    CopilotConversationsCompanion Function({
      required String tenantId,
      required String id,
      Value<String?> title,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CopilotConversationsTableUpdateCompanionBuilder =
    CopilotConversationsCompanion Function({
      Value<String> tenantId,
      Value<String> id,
      Value<String?> title,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CopilotConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $CopilotConversationsTable> {
  $$CopilotConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CopilotConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $CopilotConversationsTable> {
  $$CopilotConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CopilotConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CopilotConversationsTable> {
  $$CopilotConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CopilotConversationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CopilotConversationsTable,
          CopilotConversationRow,
          $$CopilotConversationsTableFilterComposer,
          $$CopilotConversationsTableOrderingComposer,
          $$CopilotConversationsTableAnnotationComposer,
          $$CopilotConversationsTableCreateCompanionBuilder,
          $$CopilotConversationsTableUpdateCompanionBuilder,
          (
            CopilotConversationRow,
            BaseReferences<
              _$AppDatabase,
              $CopilotConversationsTable,
              CopilotConversationRow
            >,
          ),
          CopilotConversationRow,
          PrefetchHooks Function()
        > {
  $$CopilotConversationsTableTableManager(
    _$AppDatabase db,
    $CopilotConversationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CopilotConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CopilotConversationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CopilotConversationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CopilotConversationsCompanion(
                tenantId: tenantId,
                id: id,
                title: title,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String id,
                Value<String?> title = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CopilotConversationsCompanion.insert(
                tenantId: tenantId,
                id: id,
                title: title,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $CopilotConversationsTable,
                    CopilotConversationRow
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CopilotConversationsTable,
                    CopilotConversationRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CopilotConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CopilotConversationsTable,
      CopilotConversationRow,
      $$CopilotConversationsTableFilterComposer,
      $$CopilotConversationsTableOrderingComposer,
      $$CopilotConversationsTableAnnotationComposer,
      $$CopilotConversationsTableCreateCompanionBuilder,
      $$CopilotConversationsTableUpdateCompanionBuilder,
      (
        CopilotConversationRow,
        BaseReferences<
          _$AppDatabase,
          $CopilotConversationsTable,
          CopilotConversationRow
        >,
      ),
      CopilotConversationRow,
      PrefetchHooks Function()
    >;
typedef $$CopilotMessagesTableCreateCompanionBuilder =
    CopilotMessagesCompanion Function({
      required String tenantId,
      required String id,
      required String conversationId,
      required String role,
      required String payload,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$CopilotMessagesTableUpdateCompanionBuilder =
    CopilotMessagesCompanion Function({
      Value<String> tenantId,
      Value<String> id,
      Value<String> conversationId,
      Value<String> role,
      Value<String> payload,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$CopilotMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $CopilotMessagesTable> {
  $$CopilotMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CopilotMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $CopilotMessagesTable> {
  $$CopilotMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CopilotMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CopilotMessagesTable> {
  $$CopilotMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CopilotMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CopilotMessagesTable,
          CopilotMessageRow,
          $$CopilotMessagesTableFilterComposer,
          $$CopilotMessagesTableOrderingComposer,
          $$CopilotMessagesTableAnnotationComposer,
          $$CopilotMessagesTableCreateCompanionBuilder,
          $$CopilotMessagesTableUpdateCompanionBuilder,
          (
            CopilotMessageRow,
            BaseReferences<
              _$AppDatabase,
              $CopilotMessagesTable,
              CopilotMessageRow
            >,
          ),
          CopilotMessageRow,
          PrefetchHooks Function()
        > {
  $$CopilotMessagesTableTableManager(
    _$AppDatabase db,
    $CopilotMessagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CopilotMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CopilotMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CopilotMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CopilotMessagesCompanion(
                tenantId: tenantId,
                id: id,
                conversationId: conversationId,
                role: role,
                payload: payload,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String id,
                required String conversationId,
                required String role,
                required String payload,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CopilotMessagesCompanion.insert(
                tenantId: tenantId,
                id: id,
                conversationId: conversationId,
                role: role,
                payload: payload,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CopilotMessagesTable, CopilotMessageRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CopilotMessagesTable,
                    CopilotMessageRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CopilotMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CopilotMessagesTable,
      CopilotMessageRow,
      $$CopilotMessagesTableFilterComposer,
      $$CopilotMessagesTableOrderingComposer,
      $$CopilotMessagesTableAnnotationComposer,
      $$CopilotMessagesTableCreateCompanionBuilder,
      $$CopilotMessagesTableUpdateCompanionBuilder,
      (
        CopilotMessageRow,
        BaseReferences<_$AppDatabase, $CopilotMessagesTable, CopilotMessageRow>,
      ),
      CopilotMessageRow,
      PrefetchHooks Function()
    >;
typedef $$AuditQueueEntriesTableCreateCompanionBuilder =
    AuditQueueEntriesCompanion Function({
      required String tenantId,
      required int sequenceNumber,
      required String uuid,
      required String entityType,
      required String entityId,
      required String action,
      required String payloadJson,
      required String metadataJson,
      required String previousHash,
      required String payloadHash,
      required String recordHash,
      required DateTime occurredAt,
      Value<DateTime?> syncedAt,
      Value<int> syncAttempts,
      Value<String?> lastError,
      Value<String?> serverReceipt,
      Value<int> rowid,
    });
typedef $$AuditQueueEntriesTableUpdateCompanionBuilder =
    AuditQueueEntriesCompanion Function({
      Value<String> tenantId,
      Value<int> sequenceNumber,
      Value<String> uuid,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> action,
      Value<String> payloadJson,
      Value<String> metadataJson,
      Value<String> previousHash,
      Value<String> payloadHash,
      Value<String> recordHash,
      Value<DateTime> occurredAt,
      Value<DateTime?> syncedAt,
      Value<int> syncAttempts,
      Value<String?> lastError,
      Value<String?> serverReceipt,
      Value<int> rowid,
    });

class $$AuditQueueEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $AuditQueueEntriesTable> {
  $$AuditQueueEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequenceNumber => $composableBuilder(
    column: $table.sequenceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadHash => $composableBuilder(
    column: $table.payloadHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordHash => $composableBuilder(
    column: $table.recordHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverReceipt => $composableBuilder(
    column: $table.serverReceipt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditQueueEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditQueueEntriesTable> {
  $$AuditQueueEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequenceNumber => $composableBuilder(
    column: $table.sequenceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadHash => $composableBuilder(
    column: $table.payloadHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordHash => $composableBuilder(
    column: $table.recordHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverReceipt => $composableBuilder(
    column: $table.serverReceipt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditQueueEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditQueueEntriesTable> {
  $$AuditQueueEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<int> get sequenceNumber => $composableBuilder(
    column: $table.sequenceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get previousHash => $composableBuilder(
    column: $table.previousHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadHash => $composableBuilder(
    column: $table.payloadHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordHash => $composableBuilder(
    column: $table.recordHash,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<int> get syncAttempts => $composableBuilder(
    column: $table.syncAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get serverReceipt => $composableBuilder(
    column: $table.serverReceipt,
    builder: (column) => column,
  );
}

class $$AuditQueueEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuditQueueEntriesTable,
          AuditQueueRow,
          $$AuditQueueEntriesTableFilterComposer,
          $$AuditQueueEntriesTableOrderingComposer,
          $$AuditQueueEntriesTableAnnotationComposer,
          $$AuditQueueEntriesTableCreateCompanionBuilder,
          $$AuditQueueEntriesTableUpdateCompanionBuilder,
          (
            AuditQueueRow,
            BaseReferences<
              _$AppDatabase,
              $AuditQueueEntriesTable,
              AuditQueueRow
            >,
          ),
          AuditQueueRow,
          PrefetchHooks Function()
        > {
  $$AuditQueueEntriesTableTableManager(
    _$AppDatabase db,
    $AuditQueueEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditQueueEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditQueueEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditQueueEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<int> sequenceNumber = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> metadataJson = const Value.absent(),
                Value<String> previousHash = const Value.absent(),
                Value<String> payloadHash = const Value.absent(),
                Value<String> recordHash = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> serverReceipt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditQueueEntriesCompanion(
                tenantId: tenantId,
                sequenceNumber: sequenceNumber,
                uuid: uuid,
                entityType: entityType,
                entityId: entityId,
                action: action,
                payloadJson: payloadJson,
                metadataJson: metadataJson,
                previousHash: previousHash,
                payloadHash: payloadHash,
                recordHash: recordHash,
                occurredAt: occurredAt,
                syncedAt: syncedAt,
                syncAttempts: syncAttempts,
                lastError: lastError,
                serverReceipt: serverReceipt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required int sequenceNumber,
                required String uuid,
                required String entityType,
                required String entityId,
                required String action,
                required String payloadJson,
                required String metadataJson,
                required String previousHash,
                required String payloadHash,
                required String recordHash,
                required DateTime occurredAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> syncAttempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> serverReceipt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditQueueEntriesCompanion.insert(
                tenantId: tenantId,
                sequenceNumber: sequenceNumber,
                uuid: uuid,
                entityType: entityType,
                entityId: entityId,
                action: action,
                payloadJson: payloadJson,
                metadataJson: metadataJson,
                previousHash: previousHash,
                payloadHash: payloadHash,
                recordHash: recordHash,
                occurredAt: occurredAt,
                syncedAt: syncedAt,
                syncAttempts: syncAttempts,
                lastError: lastError,
                serverReceipt: serverReceipt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AuditQueueEntriesTable, AuditQueueRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AuditQueueEntriesTable,
                    AuditQueueRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditQueueEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuditQueueEntriesTable,
      AuditQueueRow,
      $$AuditQueueEntriesTableFilterComposer,
      $$AuditQueueEntriesTableOrderingComposer,
      $$AuditQueueEntriesTableAnnotationComposer,
      $$AuditQueueEntriesTableCreateCompanionBuilder,
      $$AuditQueueEntriesTableUpdateCompanionBuilder,
      (
        AuditQueueRow,
        BaseReferences<_$AppDatabase, $AuditQueueEntriesTable, AuditQueueRow>,
      ),
      AuditQueueRow,
      PrefetchHooks Function()
    >;
typedef $$DssExecutiveSnapshotsTableCreateCompanionBuilder =
    DssExecutiveSnapshotsCompanion Function({
      required String tenantId,
      Value<String> legalEntityId,
      required String currency,
      required String periodPreset,
      required String comparisonBaseline,
      required String overviewJson,
      required String customersJson,
      Value<String?> productsJson,
      Value<String?> varianceJson,
      Value<String?> inputsJson,
      Value<String?> legalEntitiesJson,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$DssExecutiveSnapshotsTableUpdateCompanionBuilder =
    DssExecutiveSnapshotsCompanion Function({
      Value<String> tenantId,
      Value<String> legalEntityId,
      Value<String> currency,
      Value<String> periodPreset,
      Value<String> comparisonBaseline,
      Value<String> overviewJson,
      Value<String> customersJson,
      Value<String?> productsJson,
      Value<String?> varianceJson,
      Value<String?> inputsJson,
      Value<String?> legalEntitiesJson,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$DssExecutiveSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $DssExecutiveSnapshotsTable> {
  $$DssExecutiveSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get legalEntityId => $composableBuilder(
    column: $table.legalEntityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodPreset => $composableBuilder(
    column: $table.periodPreset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comparisonBaseline => $composableBuilder(
    column: $table.comparisonBaseline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overviewJson => $composableBuilder(
    column: $table.overviewJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customersJson => $composableBuilder(
    column: $table.customersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productsJson => $composableBuilder(
    column: $table.productsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get varianceJson => $composableBuilder(
    column: $table.varianceJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputsJson => $composableBuilder(
    column: $table.inputsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get legalEntitiesJson => $composableBuilder(
    column: $table.legalEntitiesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DssExecutiveSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $DssExecutiveSnapshotsTable> {
  $$DssExecutiveSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get legalEntityId => $composableBuilder(
    column: $table.legalEntityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodPreset => $composableBuilder(
    column: $table.periodPreset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comparisonBaseline => $composableBuilder(
    column: $table.comparisonBaseline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overviewJson => $composableBuilder(
    column: $table.overviewJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customersJson => $composableBuilder(
    column: $table.customersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productsJson => $composableBuilder(
    column: $table.productsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get varianceJson => $composableBuilder(
    column: $table.varianceJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputsJson => $composableBuilder(
    column: $table.inputsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get legalEntitiesJson => $composableBuilder(
    column: $table.legalEntitiesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DssExecutiveSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DssExecutiveSnapshotsTable> {
  $$DssExecutiveSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get legalEntityId => $composableBuilder(
    column: $table.legalEntityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get periodPreset => $composableBuilder(
    column: $table.periodPreset,
    builder: (column) => column,
  );

  GeneratedColumn<String> get comparisonBaseline => $composableBuilder(
    column: $table.comparisonBaseline,
    builder: (column) => column,
  );

  GeneratedColumn<String> get overviewJson => $composableBuilder(
    column: $table.overviewJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customersJson => $composableBuilder(
    column: $table.customersJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productsJson => $composableBuilder(
    column: $table.productsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get varianceJson => $composableBuilder(
    column: $table.varianceJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inputsJson => $composableBuilder(
    column: $table.inputsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get legalEntitiesJson => $composableBuilder(
    column: $table.legalEntitiesJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$DssExecutiveSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DssExecutiveSnapshotsTable,
          DssSnapshotRow,
          $$DssExecutiveSnapshotsTableFilterComposer,
          $$DssExecutiveSnapshotsTableOrderingComposer,
          $$DssExecutiveSnapshotsTableAnnotationComposer,
          $$DssExecutiveSnapshotsTableCreateCompanionBuilder,
          $$DssExecutiveSnapshotsTableUpdateCompanionBuilder,
          (
            DssSnapshotRow,
            BaseReferences<
              _$AppDatabase,
              $DssExecutiveSnapshotsTable,
              DssSnapshotRow
            >,
          ),
          DssSnapshotRow,
          PrefetchHooks Function()
        > {
  $$DssExecutiveSnapshotsTableTableManager(
    _$AppDatabase db,
    $DssExecutiveSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DssExecutiveSnapshotsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DssExecutiveSnapshotsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DssExecutiveSnapshotsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> legalEntityId = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> periodPreset = const Value.absent(),
                Value<String> comparisonBaseline = const Value.absent(),
                Value<String> overviewJson = const Value.absent(),
                Value<String> customersJson = const Value.absent(),
                Value<String?> productsJson = const Value.absent(),
                Value<String?> varianceJson = const Value.absent(),
                Value<String?> inputsJson = const Value.absent(),
                Value<String?> legalEntitiesJson = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DssExecutiveSnapshotsCompanion(
                tenantId: tenantId,
                legalEntityId: legalEntityId,
                currency: currency,
                periodPreset: periodPreset,
                comparisonBaseline: comparisonBaseline,
                overviewJson: overviewJson,
                customersJson: customersJson,
                productsJson: productsJson,
                varianceJson: varianceJson,
                inputsJson: inputsJson,
                legalEntitiesJson: legalEntitiesJson,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                Value<String> legalEntityId = const Value.absent(),
                required String currency,
                required String periodPreset,
                required String comparisonBaseline,
                required String overviewJson,
                required String customersJson,
                Value<String?> productsJson = const Value.absent(),
                Value<String?> varianceJson = const Value.absent(),
                Value<String?> inputsJson = const Value.absent(),
                Value<String?> legalEntitiesJson = const Value.absent(),
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => DssExecutiveSnapshotsCompanion.insert(
                tenantId: tenantId,
                legalEntityId: legalEntityId,
                currency: currency,
                periodPreset: periodPreset,
                comparisonBaseline: comparisonBaseline,
                overviewJson: overviewJson,
                customersJson: customersJson,
                productsJson: productsJson,
                varianceJson: varianceJson,
                inputsJson: inputsJson,
                legalEntitiesJson: legalEntitiesJson,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DssExecutiveSnapshotsTable, DssSnapshotRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $DssExecutiveSnapshotsTable,
                    DssSnapshotRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DssExecutiveSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DssExecutiveSnapshotsTable,
      DssSnapshotRow,
      $$DssExecutiveSnapshotsTableFilterComposer,
      $$DssExecutiveSnapshotsTableOrderingComposer,
      $$DssExecutiveSnapshotsTableAnnotationComposer,
      $$DssExecutiveSnapshotsTableCreateCompanionBuilder,
      $$DssExecutiveSnapshotsTableUpdateCompanionBuilder,
      (
        DssSnapshotRow,
        BaseReferences<
          _$AppDatabase,
          $DssExecutiveSnapshotsTable,
          DssSnapshotRow
        >,
      ),
      DssSnapshotRow,
      PrefetchHooks Function()
    >;
typedef $$PermissionSnapshotsTableCreateCompanionBuilder =
    PermissionSnapshotsCompanion Function({
      required String tenantId,
      required String userId,
      Value<String> companyId,
      required String payload,
      required DateTime fetchedAt,
      Value<DateTime?> revokedAt,
      Value<int> rowid,
    });
typedef $$PermissionSnapshotsTableUpdateCompanionBuilder =
    PermissionSnapshotsCompanion Function({
      Value<String> tenantId,
      Value<String> userId,
      Value<String> companyId,
      Value<String> payload,
      Value<DateTime> fetchedAt,
      Value<DateTime?> revokedAt,
      Value<int> rowid,
    });

class $$PermissionSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $PermissionSnapshotsTable> {
  $$PermissionSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get revokedAt => $composableBuilder(
    column: $table.revokedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PermissionSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $PermissionSnapshotsTable> {
  $$PermissionSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get revokedAt => $composableBuilder(
    column: $table.revokedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PermissionSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PermissionSnapshotsTable> {
  $$PermissionSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get revokedAt =>
      $composableBuilder(column: $table.revokedAt, builder: (column) => column);
}

class $$PermissionSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PermissionSnapshotsTable,
          PermissionSnapshotRow,
          $$PermissionSnapshotsTableFilterComposer,
          $$PermissionSnapshotsTableOrderingComposer,
          $$PermissionSnapshotsTableAnnotationComposer,
          $$PermissionSnapshotsTableCreateCompanionBuilder,
          $$PermissionSnapshotsTableUpdateCompanionBuilder,
          (
            PermissionSnapshotRow,
            BaseReferences<
              _$AppDatabase,
              $PermissionSnapshotsTable,
              PermissionSnapshotRow
            >,
          ),
          PermissionSnapshotRow,
          PrefetchHooks Function()
        > {
  $$PermissionSnapshotsTableTableManager(
    _$AppDatabase db,
    $PermissionSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PermissionSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PermissionSnapshotsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PermissionSnapshotsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> companyId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<DateTime?> revokedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PermissionSnapshotsCompanion(
                tenantId: tenantId,
                userId: userId,
                companyId: companyId,
                payload: payload,
                fetchedAt: fetchedAt,
                revokedAt: revokedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String userId,
                Value<String> companyId = const Value.absent(),
                required String payload,
                required DateTime fetchedAt,
                Value<DateTime?> revokedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PermissionSnapshotsCompanion.insert(
                tenantId: tenantId,
                userId: userId,
                companyId: companyId,
                payload: payload,
                fetchedAt: fetchedAt,
                revokedAt: revokedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PermissionSnapshotsTable, PermissionSnapshotRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $PermissionSnapshotsTable,
                    PermissionSnapshotRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PermissionSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PermissionSnapshotsTable,
      PermissionSnapshotRow,
      $$PermissionSnapshotsTableFilterComposer,
      $$PermissionSnapshotsTableOrderingComposer,
      $$PermissionSnapshotsTableAnnotationComposer,
      $$PermissionSnapshotsTableCreateCompanionBuilder,
      $$PermissionSnapshotsTableUpdateCompanionBuilder,
      (
        PermissionSnapshotRow,
        BaseReferences<
          _$AppDatabase,
          $PermissionSnapshotsTable,
          PermissionSnapshotRow
        >,
      ),
      PermissionSnapshotRow,
      PrefetchHooks Function()
    >;
typedef $$LocalPurchaseRequisitionsTableCreateCompanionBuilder =
    LocalPurchaseRequisitionsCompanion Function({
      required String localId,
      Value<String?> remoteId,
      required String tenantId,
      Value<String?> requisitionNumber,
      required String requesterId,
      required String requesterName,
      required String costCenterId,
      required String costCenterCode,
      required String costCenterName,
      Value<String?> projectId,
      Value<String?> projectCode,
      Value<String?> projectName,
      Value<String> urgency,
      Value<DateTime?> requestedDeliveryDate,
      Value<String> justification,
      Value<String> currency,
      Value<double> totalAmount,
      Value<String> status,
      Value<String> syncStatus,
      Value<String?> syncError,
      Value<bool> pendingSubmit,
      Value<String?> budgetCheckSnapshotJson,
      Value<String?> approvalProgressJson,
      Value<String?> linkedRdoId,
      Value<String?> linkedRdoNumber,
      Value<String?> linkedPoId,
      Value<String?> linkedPoNumber,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> serverUpdatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$LocalPurchaseRequisitionsTableUpdateCompanionBuilder =
    LocalPurchaseRequisitionsCompanion Function({
      Value<String> localId,
      Value<String?> remoteId,
      Value<String> tenantId,
      Value<String?> requisitionNumber,
      Value<String> requesterId,
      Value<String> requesterName,
      Value<String> costCenterId,
      Value<String> costCenterCode,
      Value<String> costCenterName,
      Value<String?> projectId,
      Value<String?> projectCode,
      Value<String?> projectName,
      Value<String> urgency,
      Value<DateTime?> requestedDeliveryDate,
      Value<String> justification,
      Value<String> currency,
      Value<double> totalAmount,
      Value<String> status,
      Value<String> syncStatus,
      Value<String?> syncError,
      Value<bool> pendingSubmit,
      Value<String?> budgetCheckSnapshotJson,
      Value<String?> approvalProgressJson,
      Value<String?> linkedRdoId,
      Value<String?> linkedRdoNumber,
      Value<String?> linkedPoId,
      Value<String?> linkedPoNumber,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> serverUpdatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$LocalPurchaseRequisitionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LocalPurchaseRequisitionsTable,
          LocalPurchaseRequisitionRow
        > {
  $$LocalPurchaseRequisitionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $LocalPurchaseRequisitionLinesTable,
    List<LocalPurchaseRequisitionLineRow>
  >
  _localPurchaseRequisitionLinesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.localPurchaseRequisitionLines,
        aliasName: 'local_purchase_requisitions__local_id__local_purchase_requisition_lines__requisition_local_id',
      );

  $$LocalPurchaseRequisitionLinesTableProcessedTableManager
  get localPurchaseRequisitionLinesRefs {
    final manager =
        $$LocalPurchaseRequisitionLinesTableTableManager(
          $_db,
          $_db.localPurchaseRequisitionLines,
        ).filter(
          (f) => f.requisitionLocalId.localId.sqlEquals(
            $_itemColumn<String>('local_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _localPurchaseRequisitionLinesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalPurchaseRequisitionsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPurchaseRequisitionsTable> {
  $$LocalPurchaseRequisitionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requisitionNumber => $composableBuilder(
    column: $table.requisitionNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requesterId => $composableBuilder(
    column: $table.requesterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requesterName => $composableBuilder(
    column: $table.requesterName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get costCenterId => $composableBuilder(
    column: $table.costCenterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get costCenterCode => $composableBuilder(
    column: $table.costCenterCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get costCenterName => $composableBuilder(
    column: $table.costCenterName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectCode => $composableBuilder(
    column: $table.projectCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get urgency => $composableBuilder(
    column: $table.urgency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get requestedDeliveryDate => $composableBuilder(
    column: $table.requestedDeliveryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get justification => $composableBuilder(
    column: $table.justification,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingSubmit => $composableBuilder(
    column: $table.pendingSubmit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get budgetCheckSnapshotJson => $composableBuilder(
    column: $table.budgetCheckSnapshotJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get approvalProgressJson => $composableBuilder(
    column: $table.approvalProgressJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedRdoId => $composableBuilder(
    column: $table.linkedRdoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedRdoNumber => $composableBuilder(
    column: $table.linkedRdoNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedPoId => $composableBuilder(
    column: $table.linkedPoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedPoNumber => $composableBuilder(
    column: $table.linkedPoNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> localPurchaseRequisitionLinesRefs(
    Expression<bool> Function(
      $$LocalPurchaseRequisitionLinesTableFilterComposer f,
    )
    f,
  ) {
    final $$LocalPurchaseRequisitionLinesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.localId,
          referencedTable: $db.localPurchaseRequisitionLines,
          getReferencedColumn: (t) => t.requisitionLocalId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalPurchaseRequisitionLinesTableFilterComposer(
                $db: $db,
                $table: $db.localPurchaseRequisitionLines,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$LocalPurchaseRequisitionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPurchaseRequisitionsTable> {
  $$LocalPurchaseRequisitionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requisitionNumber => $composableBuilder(
    column: $table.requisitionNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requesterId => $composableBuilder(
    column: $table.requesterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requesterName => $composableBuilder(
    column: $table.requesterName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get costCenterId => $composableBuilder(
    column: $table.costCenterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get costCenterCode => $composableBuilder(
    column: $table.costCenterCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get costCenterName => $composableBuilder(
    column: $table.costCenterName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectCode => $composableBuilder(
    column: $table.projectCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get urgency => $composableBuilder(
    column: $table.urgency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get requestedDeliveryDate => $composableBuilder(
    column: $table.requestedDeliveryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get justification => $composableBuilder(
    column: $table.justification,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingSubmit => $composableBuilder(
    column: $table.pendingSubmit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get budgetCheckSnapshotJson => $composableBuilder(
    column: $table.budgetCheckSnapshotJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get approvalProgressJson => $composableBuilder(
    column: $table.approvalProgressJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedRdoId => $composableBuilder(
    column: $table.linkedRdoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedRdoNumber => $composableBuilder(
    column: $table.linkedRdoNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedPoId => $composableBuilder(
    column: $table.linkedPoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedPoNumber => $composableBuilder(
    column: $table.linkedPoNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalPurchaseRequisitionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPurchaseRequisitionsTable> {
  $$LocalPurchaseRequisitionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get requisitionNumber => $composableBuilder(
    column: $table.requisitionNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get requesterId => $composableBuilder(
    column: $table.requesterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get requesterName => $composableBuilder(
    column: $table.requesterName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get costCenterId => $composableBuilder(
    column: $table.costCenterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get costCenterCode => $composableBuilder(
    column: $table.costCenterCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get costCenterName => $composableBuilder(
    column: $table.costCenterName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get projectCode => $composableBuilder(
    column: $table.projectCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get urgency =>
      $composableBuilder(column: $table.urgency, builder: (column) => column);

  GeneratedColumn<DateTime> get requestedDeliveryDate => $composableBuilder(
    column: $table.requestedDeliveryDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get justification => $composableBuilder(
    column: $table.justification,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<bool> get pendingSubmit => $composableBuilder(
    column: $table.pendingSubmit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get budgetCheckSnapshotJson => $composableBuilder(
    column: $table.budgetCheckSnapshotJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get approvalProgressJson => $composableBuilder(
    column: $table.approvalProgressJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get linkedRdoId => $composableBuilder(
    column: $table.linkedRdoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get linkedRdoNumber => $composableBuilder(
    column: $table.linkedRdoNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get linkedPoId => $composableBuilder(
    column: $table.linkedPoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get linkedPoNumber => $composableBuilder(
    column: $table.linkedPoNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> localPurchaseRequisitionLinesRefs<T extends Object>(
    Expression<T> Function(
      $$LocalPurchaseRequisitionLinesTableAnnotationComposer a,
    )
    f,
  ) {
    final $$LocalPurchaseRequisitionLinesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.localId,
          referencedTable: $db.localPurchaseRequisitionLines,
          getReferencedColumn: (t) => t.requisitionLocalId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalPurchaseRequisitionLinesTableAnnotationComposer(
                $db: $db,
                $table: $db.localPurchaseRequisitionLines,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$LocalPurchaseRequisitionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalPurchaseRequisitionsTable,
          LocalPurchaseRequisitionRow,
          $$LocalPurchaseRequisitionsTableFilterComposer,
          $$LocalPurchaseRequisitionsTableOrderingComposer,
          $$LocalPurchaseRequisitionsTableAnnotationComposer,
          $$LocalPurchaseRequisitionsTableCreateCompanionBuilder,
          $$LocalPurchaseRequisitionsTableUpdateCompanionBuilder,
          (
            LocalPurchaseRequisitionRow,
            $$LocalPurchaseRequisitionsTableReferences,
          ),
          LocalPurchaseRequisitionRow,
          PrefetchHooks Function({bool localPurchaseRequisitionLinesRefs})
        > {
  $$LocalPurchaseRequisitionsTableTableManager(
    _$AppDatabase db,
    $LocalPurchaseRequisitionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPurchaseRequisitionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalPurchaseRequisitionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalPurchaseRequisitionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String?> requisitionNumber = const Value.absent(),
                Value<String> requesterId = const Value.absent(),
                Value<String> requesterName = const Value.absent(),
                Value<String> costCenterId = const Value.absent(),
                Value<String> costCenterCode = const Value.absent(),
                Value<String> costCenterName = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String?> projectCode = const Value.absent(),
                Value<String?> projectName = const Value.absent(),
                Value<String> urgency = const Value.absent(),
                Value<DateTime?> requestedDeliveryDate = const Value.absent(),
                Value<String> justification = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<bool> pendingSubmit = const Value.absent(),
                Value<String?> budgetCheckSnapshotJson = const Value.absent(),
                Value<String?> approvalProgressJson = const Value.absent(),
                Value<String?> linkedRdoId = const Value.absent(),
                Value<String?> linkedRdoNumber = const Value.absent(),
                Value<String?> linkedPoId = const Value.absent(),
                Value<String?> linkedPoNumber = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPurchaseRequisitionsCompanion(
                localId: localId,
                remoteId: remoteId,
                tenantId: tenantId,
                requisitionNumber: requisitionNumber,
                requesterId: requesterId,
                requesterName: requesterName,
                costCenterId: costCenterId,
                costCenterCode: costCenterCode,
                costCenterName: costCenterName,
                projectId: projectId,
                projectCode: projectCode,
                projectName: projectName,
                urgency: urgency,
                requestedDeliveryDate: requestedDeliveryDate,
                justification: justification,
                currency: currency,
                totalAmount: totalAmount,
                status: status,
                syncStatus: syncStatus,
                syncError: syncError,
                pendingSubmit: pendingSubmit,
                budgetCheckSnapshotJson: budgetCheckSnapshotJson,
                approvalProgressJson: approvalProgressJson,
                linkedRdoId: linkedRdoId,
                linkedRdoNumber: linkedRdoNumber,
                linkedPoId: linkedPoId,
                linkedPoNumber: linkedPoNumber,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                Value<String?> remoteId = const Value.absent(),
                required String tenantId,
                Value<String?> requisitionNumber = const Value.absent(),
                required String requesterId,
                required String requesterName,
                required String costCenterId,
                required String costCenterCode,
                required String costCenterName,
                Value<String?> projectId = const Value.absent(),
                Value<String?> projectCode = const Value.absent(),
                Value<String?> projectName = const Value.absent(),
                Value<String> urgency = const Value.absent(),
                Value<DateTime?> requestedDeliveryDate = const Value.absent(),
                Value<String> justification = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<bool> pendingSubmit = const Value.absent(),
                Value<String?> budgetCheckSnapshotJson = const Value.absent(),
                Value<String?> approvalProgressJson = const Value.absent(),
                Value<String?> linkedRdoId = const Value.absent(),
                Value<String?> linkedRdoNumber = const Value.absent(),
                Value<String?> linkedPoId = const Value.absent(),
                Value<String?> linkedPoNumber = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPurchaseRequisitionsCompanion.insert(
                localId: localId,
                remoteId: remoteId,
                tenantId: tenantId,
                requisitionNumber: requisitionNumber,
                requesterId: requesterId,
                requesterName: requesterName,
                costCenterId: costCenterId,
                costCenterCode: costCenterCode,
                costCenterName: costCenterName,
                projectId: projectId,
                projectCode: projectCode,
                projectName: projectName,
                urgency: urgency,
                requestedDeliveryDate: requestedDeliveryDate,
                justification: justification,
                currency: currency,
                totalAmount: totalAmount,
                status: status,
                syncStatus: syncStatus,
                syncError: syncError,
                pendingSubmit: pendingSubmit,
                budgetCheckSnapshotJson: budgetCheckSnapshotJson,
                approvalProgressJson: approvalProgressJson,
                linkedRdoId: linkedRdoId,
                linkedRdoNumber: linkedRdoNumber,
                linkedPoId: linkedPoId,
                linkedPoNumber: linkedPoNumber,
                createdAt: createdAt,
                updatedAt: updatedAt,
                serverUpdatedAt: serverUpdatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $LocalPurchaseRequisitionsTable,
                    LocalPurchaseRequisitionRow
                  >(table),
                  $$LocalPurchaseRequisitionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({localPurchaseRequisitionLinesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (localPurchaseRequisitionLinesRefs)
                  db.localPurchaseRequisitionLines,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (localPurchaseRequisitionLinesRefs)
                    await $_getPrefetchedDataByColumns<
                      LocalPurchaseRequisitionRow,
                      $LocalPurchaseRequisitionsTable,
                      LocalPurchaseRequisitionLineRow,
                      $LocalPurchaseRequisitionLinesTable
                    >(
                      currentTable: table,
                      referencedTable:
                          $$LocalPurchaseRequisitionsTableReferences
                              ._localPurchaseRequisitionLinesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LocalPurchaseRequisitionsTableReferences(
                            db,
                            table,
                            p0,
                          ).localPurchaseRequisitionLinesRefs,
                      currentColumn: 'local_id',
                      referencedColumn: 'requisition_local_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LocalPurchaseRequisitionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalPurchaseRequisitionsTable,
      LocalPurchaseRequisitionRow,
      $$LocalPurchaseRequisitionsTableFilterComposer,
      $$LocalPurchaseRequisitionsTableOrderingComposer,
      $$LocalPurchaseRequisitionsTableAnnotationComposer,
      $$LocalPurchaseRequisitionsTableCreateCompanionBuilder,
      $$LocalPurchaseRequisitionsTableUpdateCompanionBuilder,
      (LocalPurchaseRequisitionRow, $$LocalPurchaseRequisitionsTableReferences),
      LocalPurchaseRequisitionRow,
      PrefetchHooks Function({bool localPurchaseRequisitionLinesRefs})
    >;
typedef $$LocalPurchaseRequisitionLinesTableCreateCompanionBuilder =
    LocalPurchaseRequisitionLinesCompanion Function({
      required String localId,
      Value<String?> remoteId,
      required String tenantId,
      required String requisitionLocalId,
      required int lineNumber,
      Value<String> itemType,
      Value<String?> catalogItemId,
      Value<String?> catalogSku,
      required String description,
      required double quantity,
      required double unitPrice,
      Value<String> uom,
      required double lineTotal,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$LocalPurchaseRequisitionLinesTableUpdateCompanionBuilder =
    LocalPurchaseRequisitionLinesCompanion Function({
      Value<String> localId,
      Value<String?> remoteId,
      Value<String> tenantId,
      Value<String> requisitionLocalId,
      Value<int> lineNumber,
      Value<String> itemType,
      Value<String?> catalogItemId,
      Value<String?> catalogSku,
      Value<String> description,
      Value<double> quantity,
      Value<double> unitPrice,
      Value<String> uom,
      Value<double> lineTotal,
      Value<String?> notes,
      Value<int> rowid,
    });

final class $$LocalPurchaseRequisitionLinesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LocalPurchaseRequisitionLinesTable,
          LocalPurchaseRequisitionLineRow
        > {
  $$LocalPurchaseRequisitionLinesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalPurchaseRequisitionsTable _requisitionLocalIdTable(
    _$AppDatabase db,
  ) => db.localPurchaseRequisitions.createAlias(
    'local_purchase_requisition_lines__requisition_local_id__local_purchase_requisitions__local_id',
  );

  $$LocalPurchaseRequisitionsTableProcessedTableManager get requisitionLocalId {
    final $_column = $_itemColumn<String>('requisition_local_id')!;

    final manager = $$LocalPurchaseRequisitionsTableTableManager(
      $_db,
      $_db.localPurchaseRequisitions,
    ).filter((f) => f.localId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_requisitionLocalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalPurchaseRequisitionLinesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPurchaseRequisitionLinesTable> {
  $$LocalPurchaseRequisitionLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lineNumber => $composableBuilder(
    column: $table.lineNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catalogItemId => $composableBuilder(
    column: $table.catalogItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catalogSku => $composableBuilder(
    column: $table.catalogSku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uom => $composableBuilder(
    column: $table.uom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lineTotal => $composableBuilder(
    column: $table.lineTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalPurchaseRequisitionsTableFilterComposer get requisitionLocalId {
    final $$LocalPurchaseRequisitionsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.requisitionLocalId,
          referencedTable: $db.localPurchaseRequisitions,
          getReferencedColumn: (t) => t.localId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalPurchaseRequisitionsTableFilterComposer(
                $db: $db,
                $table: $db.localPurchaseRequisitions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$LocalPurchaseRequisitionLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPurchaseRequisitionLinesTable> {
  $$LocalPurchaseRequisitionLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lineNumber => $composableBuilder(
    column: $table.lineNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catalogItemId => $composableBuilder(
    column: $table.catalogItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catalogSku => $composableBuilder(
    column: $table.catalogSku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uom => $composableBuilder(
    column: $table.uom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lineTotal => $composableBuilder(
    column: $table.lineTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalPurchaseRequisitionsTableOrderingComposer get requisitionLocalId {
    final $$LocalPurchaseRequisitionsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.requisitionLocalId,
          referencedTable: $db.localPurchaseRequisitions,
          getReferencedColumn: (t) => t.localId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalPurchaseRequisitionsTableOrderingComposer(
                $db: $db,
                $table: $db.localPurchaseRequisitions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$LocalPurchaseRequisitionLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPurchaseRequisitionLinesTable> {
  $$LocalPurchaseRequisitionLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<int> get lineNumber => $composableBuilder(
    column: $table.lineNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<String> get catalogItemId => $composableBuilder(
    column: $table.catalogItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get catalogSku => $composableBuilder(
    column: $table.catalogSku,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<String> get uom =>
      $composableBuilder(column: $table.uom, builder: (column) => column);

  GeneratedColumn<double> get lineTotal =>
      $composableBuilder(column: $table.lineTotal, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$LocalPurchaseRequisitionsTableAnnotationComposer get requisitionLocalId {
    final $$LocalPurchaseRequisitionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.requisitionLocalId,
          referencedTable: $db.localPurchaseRequisitions,
          getReferencedColumn: (t) => t.localId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalPurchaseRequisitionsTableAnnotationComposer(
                $db: $db,
                $table: $db.localPurchaseRequisitions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$LocalPurchaseRequisitionLinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalPurchaseRequisitionLinesTable,
          LocalPurchaseRequisitionLineRow,
          $$LocalPurchaseRequisitionLinesTableFilterComposer,
          $$LocalPurchaseRequisitionLinesTableOrderingComposer,
          $$LocalPurchaseRequisitionLinesTableAnnotationComposer,
          $$LocalPurchaseRequisitionLinesTableCreateCompanionBuilder,
          $$LocalPurchaseRequisitionLinesTableUpdateCompanionBuilder,
          (
            LocalPurchaseRequisitionLineRow,
            $$LocalPurchaseRequisitionLinesTableReferences,
          ),
          LocalPurchaseRequisitionLineRow,
          PrefetchHooks Function({bool requisitionLocalId})
        > {
  $$LocalPurchaseRequisitionLinesTableTableManager(
    _$AppDatabase db,
    $LocalPurchaseRequisitionLinesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPurchaseRequisitionLinesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalPurchaseRequisitionLinesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalPurchaseRequisitionLinesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> requisitionLocalId = const Value.absent(),
                Value<int> lineNumber = const Value.absent(),
                Value<String> itemType = const Value.absent(),
                Value<String?> catalogItemId = const Value.absent(),
                Value<String?> catalogSku = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<String> uom = const Value.absent(),
                Value<double> lineTotal = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPurchaseRequisitionLinesCompanion(
                localId: localId,
                remoteId: remoteId,
                tenantId: tenantId,
                requisitionLocalId: requisitionLocalId,
                lineNumber: lineNumber,
                itemType: itemType,
                catalogItemId: catalogItemId,
                catalogSku: catalogSku,
                description: description,
                quantity: quantity,
                unitPrice: unitPrice,
                uom: uom,
                lineTotal: lineTotal,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                Value<String?> remoteId = const Value.absent(),
                required String tenantId,
                required String requisitionLocalId,
                required int lineNumber,
                Value<String> itemType = const Value.absent(),
                Value<String?> catalogItemId = const Value.absent(),
                Value<String?> catalogSku = const Value.absent(),
                required String description,
                required double quantity,
                required double unitPrice,
                Value<String> uom = const Value.absent(),
                required double lineTotal,
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPurchaseRequisitionLinesCompanion.insert(
                localId: localId,
                remoteId: remoteId,
                tenantId: tenantId,
                requisitionLocalId: requisitionLocalId,
                lineNumber: lineNumber,
                itemType: itemType,
                catalogItemId: catalogItemId,
                catalogSku: catalogSku,
                description: description,
                quantity: quantity,
                unitPrice: unitPrice,
                uom: uom,
                lineTotal: lineTotal,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $LocalPurchaseRequisitionLinesTable,
                    LocalPurchaseRequisitionLineRow
                  >(table),
                  $$LocalPurchaseRequisitionLinesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({requisitionLocalId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (requisitionLocalId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.requisitionLocalId,
                        referencedTable:
                            $$LocalPurchaseRequisitionLinesTableReferences
                                ._requisitionLocalIdTable(db),
                        referencedColumn:
                            $$LocalPurchaseRequisitionLinesTableReferences
                                ._requisitionLocalIdTable(db)
                                .localId,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LocalPurchaseRequisitionLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalPurchaseRequisitionLinesTable,
      LocalPurchaseRequisitionLineRow,
      $$LocalPurchaseRequisitionLinesTableFilterComposer,
      $$LocalPurchaseRequisitionLinesTableOrderingComposer,
      $$LocalPurchaseRequisitionLinesTableAnnotationComposer,
      $$LocalPurchaseRequisitionLinesTableCreateCompanionBuilder,
      $$LocalPurchaseRequisitionLinesTableUpdateCompanionBuilder,
      (
        LocalPurchaseRequisitionLineRow,
        $$LocalPurchaseRequisitionLinesTableReferences,
      ),
      LocalPurchaseRequisitionLineRow,
      PrefetchHooks Function({bool requisitionLocalId})
    >;
typedef $$LocalPendingApprovalsTableCreateCompanionBuilder =
    LocalPendingApprovalsCompanion Function({
      required String approvalId,
      required String tenantId,
      required String requisitionRemoteId,
      required String requisitionNumber,
      required String requesterName,
      required String costCenterCode,
      required String costCenterName,
      Value<String?> projectName,
      Value<String> urgency,
      required double totalAmount,
      Value<String> currency,
      Value<String> status,
      Value<int> currentLevel,
      Value<int> totalLevels,
      Value<String> budgetStatus,
      Value<String?> oneClickToken,
      Value<String?> pendingDecision,
      Value<String?> pendingRejectionReason,
      Value<String> syncStatus,
      Value<String?> syncError,
      required DateTime requestedAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LocalPendingApprovalsTableUpdateCompanionBuilder =
    LocalPendingApprovalsCompanion Function({
      Value<String> approvalId,
      Value<String> tenantId,
      Value<String> requisitionRemoteId,
      Value<String> requisitionNumber,
      Value<String> requesterName,
      Value<String> costCenterCode,
      Value<String> costCenterName,
      Value<String?> projectName,
      Value<String> urgency,
      Value<double> totalAmount,
      Value<String> currency,
      Value<String> status,
      Value<int> currentLevel,
      Value<int> totalLevels,
      Value<String> budgetStatus,
      Value<String?> oneClickToken,
      Value<String?> pendingDecision,
      Value<String?> pendingRejectionReason,
      Value<String> syncStatus,
      Value<String?> syncError,
      Value<DateTime> requestedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalPendingApprovalsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPendingApprovalsTable> {
  $$LocalPendingApprovalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get approvalId => $composableBuilder(
    column: $table.approvalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requisitionRemoteId => $composableBuilder(
    column: $table.requisitionRemoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requisitionNumber => $composableBuilder(
    column: $table.requisitionNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requesterName => $composableBuilder(
    column: $table.requesterName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get costCenterCode => $composableBuilder(
    column: $table.costCenterCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get costCenterName => $composableBuilder(
    column: $table.costCenterName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get urgency => $composableBuilder(
    column: $table.urgency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentLevel => $composableBuilder(
    column: $table.currentLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalLevels => $composableBuilder(
    column: $table.totalLevels,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get budgetStatus => $composableBuilder(
    column: $table.budgetStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get oneClickToken => $composableBuilder(
    column: $table.oneClickToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pendingDecision => $composableBuilder(
    column: $table.pendingDecision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pendingRejectionReason => $composableBuilder(
    column: $table.pendingRejectionReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalPendingApprovalsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPendingApprovalsTable> {
  $$LocalPendingApprovalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get approvalId => $composableBuilder(
    column: $table.approvalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requisitionRemoteId => $composableBuilder(
    column: $table.requisitionRemoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requisitionNumber => $composableBuilder(
    column: $table.requisitionNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requesterName => $composableBuilder(
    column: $table.requesterName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get costCenterCode => $composableBuilder(
    column: $table.costCenterCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get costCenterName => $composableBuilder(
    column: $table.costCenterName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get urgency => $composableBuilder(
    column: $table.urgency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentLevel => $composableBuilder(
    column: $table.currentLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalLevels => $composableBuilder(
    column: $table.totalLevels,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get budgetStatus => $composableBuilder(
    column: $table.budgetStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get oneClickToken => $composableBuilder(
    column: $table.oneClickToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pendingDecision => $composableBuilder(
    column: $table.pendingDecision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pendingRejectionReason => $composableBuilder(
    column: $table.pendingRejectionReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalPendingApprovalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPendingApprovalsTable> {
  $$LocalPendingApprovalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get approvalId => $composableBuilder(
    column: $table.approvalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get requisitionRemoteId => $composableBuilder(
    column: $table.requisitionRemoteId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get requisitionNumber => $composableBuilder(
    column: $table.requisitionNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get requesterName => $composableBuilder(
    column: $table.requesterName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get costCenterCode => $composableBuilder(
    column: $table.costCenterCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get costCenterName => $composableBuilder(
    column: $table.costCenterName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get urgency =>
      $composableBuilder(column: $table.urgency, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get currentLevel => $composableBuilder(
    column: $table.currentLevel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalLevels => $composableBuilder(
    column: $table.totalLevels,
    builder: (column) => column,
  );

  GeneratedColumn<String> get budgetStatus => $composableBuilder(
    column: $table.budgetStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get oneClickToken => $composableBuilder(
    column: $table.oneClickToken,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pendingDecision => $composableBuilder(
    column: $table.pendingDecision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pendingRejectionReason => $composableBuilder(
    column: $table.pendingRejectionReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalPendingApprovalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalPendingApprovalsTable,
          LocalPendingApprovalRow,
          $$LocalPendingApprovalsTableFilterComposer,
          $$LocalPendingApprovalsTableOrderingComposer,
          $$LocalPendingApprovalsTableAnnotationComposer,
          $$LocalPendingApprovalsTableCreateCompanionBuilder,
          $$LocalPendingApprovalsTableUpdateCompanionBuilder,
          (
            LocalPendingApprovalRow,
            BaseReferences<
              _$AppDatabase,
              $LocalPendingApprovalsTable,
              LocalPendingApprovalRow
            >,
          ),
          LocalPendingApprovalRow,
          PrefetchHooks Function()
        > {
  $$LocalPendingApprovalsTableTableManager(
    _$AppDatabase db,
    $LocalPendingApprovalsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPendingApprovalsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalPendingApprovalsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalPendingApprovalsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> approvalId = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> requisitionRemoteId = const Value.absent(),
                Value<String> requisitionNumber = const Value.absent(),
                Value<String> requesterName = const Value.absent(),
                Value<String> costCenterCode = const Value.absent(),
                Value<String> costCenterName = const Value.absent(),
                Value<String?> projectName = const Value.absent(),
                Value<String> urgency = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> currentLevel = const Value.absent(),
                Value<int> totalLevels = const Value.absent(),
                Value<String> budgetStatus = const Value.absent(),
                Value<String?> oneClickToken = const Value.absent(),
                Value<String?> pendingDecision = const Value.absent(),
                Value<String?> pendingRejectionReason = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> requestedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPendingApprovalsCompanion(
                approvalId: approvalId,
                tenantId: tenantId,
                requisitionRemoteId: requisitionRemoteId,
                requisitionNumber: requisitionNumber,
                requesterName: requesterName,
                costCenterCode: costCenterCode,
                costCenterName: costCenterName,
                projectName: projectName,
                urgency: urgency,
                totalAmount: totalAmount,
                currency: currency,
                status: status,
                currentLevel: currentLevel,
                totalLevels: totalLevels,
                budgetStatus: budgetStatus,
                oneClickToken: oneClickToken,
                pendingDecision: pendingDecision,
                pendingRejectionReason: pendingRejectionReason,
                syncStatus: syncStatus,
                syncError: syncError,
                requestedAt: requestedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String approvalId,
                required String tenantId,
                required String requisitionRemoteId,
                required String requisitionNumber,
                required String requesterName,
                required String costCenterCode,
                required String costCenterName,
                Value<String?> projectName = const Value.absent(),
                Value<String> urgency = const Value.absent(),
                required double totalAmount,
                Value<String> currency = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> currentLevel = const Value.absent(),
                Value<int> totalLevels = const Value.absent(),
                Value<String> budgetStatus = const Value.absent(),
                Value<String?> oneClickToken = const Value.absent(),
                Value<String?> pendingDecision = const Value.absent(),
                Value<String?> pendingRejectionReason = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                required DateTime requestedAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalPendingApprovalsCompanion.insert(
                approvalId: approvalId,
                tenantId: tenantId,
                requisitionRemoteId: requisitionRemoteId,
                requisitionNumber: requisitionNumber,
                requesterName: requesterName,
                costCenterCode: costCenterCode,
                costCenterName: costCenterName,
                projectName: projectName,
                urgency: urgency,
                totalAmount: totalAmount,
                currency: currency,
                status: status,
                currentLevel: currentLevel,
                totalLevels: totalLevels,
                budgetStatus: budgetStatus,
                oneClickToken: oneClickToken,
                pendingDecision: pendingDecision,
                pendingRejectionReason: pendingRejectionReason,
                syncStatus: syncStatus,
                syncError: syncError,
                requestedAt: requestedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $LocalPendingApprovalsTable,
                    LocalPendingApprovalRow
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalPendingApprovalsTable,
                    LocalPendingApprovalRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalPendingApprovalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalPendingApprovalsTable,
      LocalPendingApprovalRow,
      $$LocalPendingApprovalsTableFilterComposer,
      $$LocalPendingApprovalsTableOrderingComposer,
      $$LocalPendingApprovalsTableAnnotationComposer,
      $$LocalPendingApprovalsTableCreateCompanionBuilder,
      $$LocalPendingApprovalsTableUpdateCompanionBuilder,
      (
        LocalPendingApprovalRow,
        BaseReferences<
          _$AppDatabase,
          $LocalPendingApprovalsTable,
          LocalPendingApprovalRow
        >,
      ),
      LocalPendingApprovalRow,
      PrefetchHooks Function()
    >;
typedef $$LocalApprovalAuditLogsTableCreateCompanionBuilder =
    LocalApprovalAuditLogsCompanion Function({
      required String id,
      required String tenantId,
      required String requisitionId,
      Value<int> level,
      required String action,
      Value<String?> actorId,
      required String actorName,
      Value<String?> actorRole,
      Value<String> channel,
      Value<String?> comment,
      required DateTime occurredAt,
      Value<bool> isLocalPending,
      Value<int> rowid,
    });
typedef $$LocalApprovalAuditLogsTableUpdateCompanionBuilder =
    LocalApprovalAuditLogsCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String> requisitionId,
      Value<int> level,
      Value<String> action,
      Value<String?> actorId,
      Value<String> actorName,
      Value<String?> actorRole,
      Value<String> channel,
      Value<String?> comment,
      Value<DateTime> occurredAt,
      Value<bool> isLocalPending,
      Value<int> rowid,
    });

class $$LocalApprovalAuditLogsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalApprovalAuditLogsTable> {
  $$LocalApprovalAuditLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requisitionId => $composableBuilder(
    column: $table.requisitionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorName => $composableBuilder(
    column: $table.actorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorRole => $composableBuilder(
    column: $table.actorRole,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocalPending => $composableBuilder(
    column: $table.isLocalPending,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalApprovalAuditLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalApprovalAuditLogsTable> {
  $$LocalApprovalAuditLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requisitionId => $composableBuilder(
    column: $table.requisitionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorName => $composableBuilder(
    column: $table.actorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorRole => $composableBuilder(
    column: $table.actorRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocalPending => $composableBuilder(
    column: $table.isLocalPending,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalApprovalAuditLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalApprovalAuditLogsTable> {
  $$LocalApprovalAuditLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get requisitionId => $composableBuilder(
    column: $table.requisitionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get actorId =>
      $composableBuilder(column: $table.actorId, builder: (column) => column);

  GeneratedColumn<String> get actorName =>
      $composableBuilder(column: $table.actorName, builder: (column) => column);

  GeneratedColumn<String> get actorRole =>
      $composableBuilder(column: $table.actorRole, builder: (column) => column);

  GeneratedColumn<String> get channel =>
      $composableBuilder(column: $table.channel, builder: (column) => column);

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isLocalPending => $composableBuilder(
    column: $table.isLocalPending,
    builder: (column) => column,
  );
}

class $$LocalApprovalAuditLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalApprovalAuditLogsTable,
          LocalApprovalAuditLogRow,
          $$LocalApprovalAuditLogsTableFilterComposer,
          $$LocalApprovalAuditLogsTableOrderingComposer,
          $$LocalApprovalAuditLogsTableAnnotationComposer,
          $$LocalApprovalAuditLogsTableCreateCompanionBuilder,
          $$LocalApprovalAuditLogsTableUpdateCompanionBuilder,
          (
            LocalApprovalAuditLogRow,
            BaseReferences<
              _$AppDatabase,
              $LocalApprovalAuditLogsTable,
              LocalApprovalAuditLogRow
            >,
          ),
          LocalApprovalAuditLogRow,
          PrefetchHooks Function()
        > {
  $$LocalApprovalAuditLogsTableTableManager(
    _$AppDatabase db,
    $LocalApprovalAuditLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalApprovalAuditLogsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalApprovalAuditLogsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalApprovalAuditLogsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> requisitionId = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String?> actorId = const Value.absent(),
                Value<String> actorName = const Value.absent(),
                Value<String?> actorRole = const Value.absent(),
                Value<String> channel = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<bool> isLocalPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalApprovalAuditLogsCompanion(
                id: id,
                tenantId: tenantId,
                requisitionId: requisitionId,
                level: level,
                action: action,
                actorId: actorId,
                actorName: actorName,
                actorRole: actorRole,
                channel: channel,
                comment: comment,
                occurredAt: occurredAt,
                isLocalPending: isLocalPending,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tenantId,
                required String requisitionId,
                Value<int> level = const Value.absent(),
                required String action,
                Value<String?> actorId = const Value.absent(),
                required String actorName,
                Value<String?> actorRole = const Value.absent(),
                Value<String> channel = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                required DateTime occurredAt,
                Value<bool> isLocalPending = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalApprovalAuditLogsCompanion.insert(
                id: id,
                tenantId: tenantId,
                requisitionId: requisitionId,
                level: level,
                action: action,
                actorId: actorId,
                actorName: actorName,
                actorRole: actorRole,
                channel: channel,
                comment: comment,
                occurredAt: occurredAt,
                isLocalPending: isLocalPending,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $LocalApprovalAuditLogsTable,
                    LocalApprovalAuditLogRow
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalApprovalAuditLogsTable,
                    LocalApprovalAuditLogRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalApprovalAuditLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalApprovalAuditLogsTable,
      LocalApprovalAuditLogRow,
      $$LocalApprovalAuditLogsTableFilterComposer,
      $$LocalApprovalAuditLogsTableOrderingComposer,
      $$LocalApprovalAuditLogsTableAnnotationComposer,
      $$LocalApprovalAuditLogsTableCreateCompanionBuilder,
      $$LocalApprovalAuditLogsTableUpdateCompanionBuilder,
      (
        LocalApprovalAuditLogRow,
        BaseReferences<
          _$AppDatabase,
          $LocalApprovalAuditLogsTable,
          LocalApprovalAuditLogRow
        >,
      ),
      LocalApprovalAuditLogRow,
      PrefetchHooks Function()
    >;
typedef $$MfgLocalWorkCentersTableCreateCompanionBuilder =
    MfgLocalWorkCentersCompanion Function({
      required String tenantId,
      required String id,
      required String code,
      required String name,
      Value<String> status,
      required String payload,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$MfgLocalWorkCentersTableUpdateCompanionBuilder =
    MfgLocalWorkCentersCompanion Function({
      Value<String> tenantId,
      Value<String> id,
      Value<String> code,
      Value<String> name,
      Value<String> status,
      Value<String> payload,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$MfgLocalWorkCentersTableFilterComposer
    extends Composer<_$AppDatabase, $MfgLocalWorkCentersTable> {
  $$MfgLocalWorkCentersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MfgLocalWorkCentersTableOrderingComposer
    extends Composer<_$AppDatabase, $MfgLocalWorkCentersTable> {
  $$MfgLocalWorkCentersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MfgLocalWorkCentersTableAnnotationComposer
    extends Composer<_$AppDatabase, $MfgLocalWorkCentersTable> {
  $$MfgLocalWorkCentersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$MfgLocalWorkCentersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MfgLocalWorkCentersTable,
          MfgWorkCenterRow,
          $$MfgLocalWorkCentersTableFilterComposer,
          $$MfgLocalWorkCentersTableOrderingComposer,
          $$MfgLocalWorkCentersTableAnnotationComposer,
          $$MfgLocalWorkCentersTableCreateCompanionBuilder,
          $$MfgLocalWorkCentersTableUpdateCompanionBuilder,
          (
            MfgWorkCenterRow,
            BaseReferences<
              _$AppDatabase,
              $MfgLocalWorkCentersTable,
              MfgWorkCenterRow
            >,
          ),
          MfgWorkCenterRow,
          PrefetchHooks Function()
        > {
  $$MfgLocalWorkCentersTableTableManager(
    _$AppDatabase db,
    $MfgLocalWorkCentersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MfgLocalWorkCentersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MfgLocalWorkCentersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MfgLocalWorkCentersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MfgLocalWorkCentersCompanion(
                tenantId: tenantId,
                id: id,
                code: code,
                name: name,
                status: status,
                payload: payload,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String id,
                required String code,
                required String name,
                Value<String> status = const Value.absent(),
                required String payload,
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => MfgLocalWorkCentersCompanion.insert(
                tenantId: tenantId,
                id: id,
                code: code,
                name: name,
                status: status,
                payload: payload,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MfgLocalWorkCentersTable, MfgWorkCenterRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $MfgLocalWorkCentersTable,
                    MfgWorkCenterRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MfgLocalWorkCentersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MfgLocalWorkCentersTable,
      MfgWorkCenterRow,
      $$MfgLocalWorkCentersTableFilterComposer,
      $$MfgLocalWorkCentersTableOrderingComposer,
      $$MfgLocalWorkCentersTableAnnotationComposer,
      $$MfgLocalWorkCentersTableCreateCompanionBuilder,
      $$MfgLocalWorkCentersTableUpdateCompanionBuilder,
      (
        MfgWorkCenterRow,
        BaseReferences<
          _$AppDatabase,
          $MfgLocalWorkCentersTable,
          MfgWorkCenterRow
        >,
      ),
      MfgWorkCenterRow,
      PrefetchHooks Function()
    >;
typedef $$MfgLocalMachinesTableCreateCompanionBuilder =
    MfgLocalMachinesCompanion Function({
      required String tenantId,
      required String id,
      required String code,
      required String name,
      required String workCenterId,
      Value<String> status,
      required String payload,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$MfgLocalMachinesTableUpdateCompanionBuilder =
    MfgLocalMachinesCompanion Function({
      Value<String> tenantId,
      Value<String> id,
      Value<String> code,
      Value<String> name,
      Value<String> workCenterId,
      Value<String> status,
      Value<String> payload,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$MfgLocalMachinesTableFilterComposer
    extends Composer<_$AppDatabase, $MfgLocalMachinesTable> {
  $$MfgLocalMachinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workCenterId => $composableBuilder(
    column: $table.workCenterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MfgLocalMachinesTableOrderingComposer
    extends Composer<_$AppDatabase, $MfgLocalMachinesTable> {
  $$MfgLocalMachinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workCenterId => $composableBuilder(
    column: $table.workCenterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MfgLocalMachinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MfgLocalMachinesTable> {
  $$MfgLocalMachinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get workCenterId => $composableBuilder(
    column: $table.workCenterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$MfgLocalMachinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MfgLocalMachinesTable,
          MfgMachineRow,
          $$MfgLocalMachinesTableFilterComposer,
          $$MfgLocalMachinesTableOrderingComposer,
          $$MfgLocalMachinesTableAnnotationComposer,
          $$MfgLocalMachinesTableCreateCompanionBuilder,
          $$MfgLocalMachinesTableUpdateCompanionBuilder,
          (
            MfgMachineRow,
            BaseReferences<
              _$AppDatabase,
              $MfgLocalMachinesTable,
              MfgMachineRow
            >,
          ),
          MfgMachineRow,
          PrefetchHooks Function()
        > {
  $$MfgLocalMachinesTableTableManager(
    _$AppDatabase db,
    $MfgLocalMachinesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MfgLocalMachinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MfgLocalMachinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MfgLocalMachinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> workCenterId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MfgLocalMachinesCompanion(
                tenantId: tenantId,
                id: id,
                code: code,
                name: name,
                workCenterId: workCenterId,
                status: status,
                payload: payload,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String id,
                required String code,
                required String name,
                required String workCenterId,
                Value<String> status = const Value.absent(),
                required String payload,
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => MfgLocalMachinesCompanion.insert(
                tenantId: tenantId,
                id: id,
                code: code,
                name: name,
                workCenterId: workCenterId,
                status: status,
                payload: payload,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MfgLocalMachinesTable, MfgMachineRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MfgLocalMachinesTable,
                    MfgMachineRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MfgLocalMachinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MfgLocalMachinesTable,
      MfgMachineRow,
      $$MfgLocalMachinesTableFilterComposer,
      $$MfgLocalMachinesTableOrderingComposer,
      $$MfgLocalMachinesTableAnnotationComposer,
      $$MfgLocalMachinesTableCreateCompanionBuilder,
      $$MfgLocalMachinesTableUpdateCompanionBuilder,
      (
        MfgMachineRow,
        BaseReferences<_$AppDatabase, $MfgLocalMachinesTable, MfgMachineRow>,
      ),
      MfgMachineRow,
      PrefetchHooks Function()
    >;
typedef $$MfgLocalRoutingsTableCreateCompanionBuilder =
    MfgLocalRoutingsCompanion Function({
      required String tenantId,
      required String id,
      required String routingNumber,
      required String name,
      required String revision,
      required String status,
      Value<bool> isDefault,
      required String payload,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$MfgLocalRoutingsTableUpdateCompanionBuilder =
    MfgLocalRoutingsCompanion Function({
      Value<String> tenantId,
      Value<String> id,
      Value<String> routingNumber,
      Value<String> name,
      Value<String> revision,
      Value<String> status,
      Value<bool> isDefault,
      Value<String> payload,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$MfgLocalRoutingsTableFilterComposer
    extends Composer<_$AppDatabase, $MfgLocalRoutingsTable> {
  $$MfgLocalRoutingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routingNumber => $composableBuilder(
    column: $table.routingNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MfgLocalRoutingsTableOrderingComposer
    extends Composer<_$AppDatabase, $MfgLocalRoutingsTable> {
  $$MfgLocalRoutingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routingNumber => $composableBuilder(
    column: $table.routingNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MfgLocalRoutingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MfgLocalRoutingsTable> {
  $$MfgLocalRoutingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get routingNumber => $composableBuilder(
    column: $table.routingNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$MfgLocalRoutingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MfgLocalRoutingsTable,
          MfgRoutingRow,
          $$MfgLocalRoutingsTableFilterComposer,
          $$MfgLocalRoutingsTableOrderingComposer,
          $$MfgLocalRoutingsTableAnnotationComposer,
          $$MfgLocalRoutingsTableCreateCompanionBuilder,
          $$MfgLocalRoutingsTableUpdateCompanionBuilder,
          (
            MfgRoutingRow,
            BaseReferences<
              _$AppDatabase,
              $MfgLocalRoutingsTable,
              MfgRoutingRow
            >,
          ),
          MfgRoutingRow,
          PrefetchHooks Function()
        > {
  $$MfgLocalRoutingsTableTableManager(
    _$AppDatabase db,
    $MfgLocalRoutingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MfgLocalRoutingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MfgLocalRoutingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MfgLocalRoutingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> routingNumber = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> revision = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MfgLocalRoutingsCompanion(
                tenantId: tenantId,
                id: id,
                routingNumber: routingNumber,
                name: name,
                revision: revision,
                status: status,
                isDefault: isDefault,
                payload: payload,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String id,
                required String routingNumber,
                required String name,
                required String revision,
                required String status,
                Value<bool> isDefault = const Value.absent(),
                required String payload,
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => MfgLocalRoutingsCompanion.insert(
                tenantId: tenantId,
                id: id,
                routingNumber: routingNumber,
                name: name,
                revision: revision,
                status: status,
                isDefault: isDefault,
                payload: payload,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MfgLocalRoutingsTable, MfgRoutingRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MfgLocalRoutingsTable,
                    MfgRoutingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MfgLocalRoutingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MfgLocalRoutingsTable,
      MfgRoutingRow,
      $$MfgLocalRoutingsTableFilterComposer,
      $$MfgLocalRoutingsTableOrderingComposer,
      $$MfgLocalRoutingsTableAnnotationComposer,
      $$MfgLocalRoutingsTableCreateCompanionBuilder,
      $$MfgLocalRoutingsTableUpdateCompanionBuilder,
      (
        MfgRoutingRow,
        BaseReferences<_$AppDatabase, $MfgLocalRoutingsTable, MfgRoutingRow>,
      ),
      MfgRoutingRow,
      PrefetchHooks Function()
    >;
typedef $$MfgLocalRoutingStepsTableCreateCompanionBuilder =
    MfgLocalRoutingStepsCompanion Function({
      required String tenantId,
      required String id,
      required String routingId,
      required int sequence,
      required String workCenterId,
      Value<String?> machineCenterId,
      required String payload,
      Value<int> rowid,
    });
typedef $$MfgLocalRoutingStepsTableUpdateCompanionBuilder =
    MfgLocalRoutingStepsCompanion Function({
      Value<String> tenantId,
      Value<String> id,
      Value<String> routingId,
      Value<int> sequence,
      Value<String> workCenterId,
      Value<String?> machineCenterId,
      Value<String> payload,
      Value<int> rowid,
    });

class $$MfgLocalRoutingStepsTableFilterComposer
    extends Composer<_$AppDatabase, $MfgLocalRoutingStepsTable> {
  $$MfgLocalRoutingStepsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routingId => $composableBuilder(
    column: $table.routingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workCenterId => $composableBuilder(
    column: $table.workCenterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get machineCenterId => $composableBuilder(
    column: $table.machineCenterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MfgLocalRoutingStepsTableOrderingComposer
    extends Composer<_$AppDatabase, $MfgLocalRoutingStepsTable> {
  $$MfgLocalRoutingStepsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routingId => $composableBuilder(
    column: $table.routingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workCenterId => $composableBuilder(
    column: $table.workCenterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get machineCenterId => $composableBuilder(
    column: $table.machineCenterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MfgLocalRoutingStepsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MfgLocalRoutingStepsTable> {
  $$MfgLocalRoutingStepsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get routingId =>
      $composableBuilder(column: $table.routingId, builder: (column) => column);

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get workCenterId => $composableBuilder(
    column: $table.workCenterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get machineCenterId => $composableBuilder(
    column: $table.machineCenterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$MfgLocalRoutingStepsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MfgLocalRoutingStepsTable,
          MfgRoutingStepRow,
          $$MfgLocalRoutingStepsTableFilterComposer,
          $$MfgLocalRoutingStepsTableOrderingComposer,
          $$MfgLocalRoutingStepsTableAnnotationComposer,
          $$MfgLocalRoutingStepsTableCreateCompanionBuilder,
          $$MfgLocalRoutingStepsTableUpdateCompanionBuilder,
          (
            MfgRoutingStepRow,
            BaseReferences<
              _$AppDatabase,
              $MfgLocalRoutingStepsTable,
              MfgRoutingStepRow
            >,
          ),
          MfgRoutingStepRow,
          PrefetchHooks Function()
        > {
  $$MfgLocalRoutingStepsTableTableManager(
    _$AppDatabase db,
    $MfgLocalRoutingStepsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MfgLocalRoutingStepsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MfgLocalRoutingStepsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MfgLocalRoutingStepsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> routingId = const Value.absent(),
                Value<int> sequence = const Value.absent(),
                Value<String> workCenterId = const Value.absent(),
                Value<String?> machineCenterId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MfgLocalRoutingStepsCompanion(
                tenantId: tenantId,
                id: id,
                routingId: routingId,
                sequence: sequence,
                workCenterId: workCenterId,
                machineCenterId: machineCenterId,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String id,
                required String routingId,
                required int sequence,
                required String workCenterId,
                Value<String?> machineCenterId = const Value.absent(),
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => MfgLocalRoutingStepsCompanion.insert(
                tenantId: tenantId,
                id: id,
                routingId: routingId,
                sequence: sequence,
                workCenterId: workCenterId,
                machineCenterId: machineCenterId,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MfgLocalRoutingStepsTable, MfgRoutingStepRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $MfgLocalRoutingStepsTable,
                    MfgRoutingStepRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MfgLocalRoutingStepsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MfgLocalRoutingStepsTable,
      MfgRoutingStepRow,
      $$MfgLocalRoutingStepsTableFilterComposer,
      $$MfgLocalRoutingStepsTableOrderingComposer,
      $$MfgLocalRoutingStepsTableAnnotationComposer,
      $$MfgLocalRoutingStepsTableCreateCompanionBuilder,
      $$MfgLocalRoutingStepsTableUpdateCompanionBuilder,
      (
        MfgRoutingStepRow,
        BaseReferences<
          _$AppDatabase,
          $MfgLocalRoutingStepsTable,
          MfgRoutingStepRow
        >,
      ),
      MfgRoutingStepRow,
      PrefetchHooks Function()
    >;
typedef $$MfgLocalOeeSummariesTableCreateCompanionBuilder =
    MfgLocalOeeSummariesCompanion Function({
      required String tenantId,
      required String scopeKey,
      required String workCenterId,
      Value<String?> machineCenterId,
      required DateTime fromAt,
      required DateTime toAt,
      required String payload,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$MfgLocalOeeSummariesTableUpdateCompanionBuilder =
    MfgLocalOeeSummariesCompanion Function({
      Value<String> tenantId,
      Value<String> scopeKey,
      Value<String> workCenterId,
      Value<String?> machineCenterId,
      Value<DateTime> fromAt,
      Value<DateTime> toAt,
      Value<String> payload,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$MfgLocalOeeSummariesTableFilterComposer
    extends Composer<_$AppDatabase, $MfgLocalOeeSummariesTable> {
  $$MfgLocalOeeSummariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workCenterId => $composableBuilder(
    column: $table.workCenterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get machineCenterId => $composableBuilder(
    column: $table.machineCenterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fromAt => $composableBuilder(
    column: $table.fromAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get toAt => $composableBuilder(
    column: $table.toAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MfgLocalOeeSummariesTableOrderingComposer
    extends Composer<_$AppDatabase, $MfgLocalOeeSummariesTable> {
  $$MfgLocalOeeSummariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeKey => $composableBuilder(
    column: $table.scopeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workCenterId => $composableBuilder(
    column: $table.workCenterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get machineCenterId => $composableBuilder(
    column: $table.machineCenterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fromAt => $composableBuilder(
    column: $table.fromAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get toAt => $composableBuilder(
    column: $table.toAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MfgLocalOeeSummariesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MfgLocalOeeSummariesTable> {
  $$MfgLocalOeeSummariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get scopeKey =>
      $composableBuilder(column: $table.scopeKey, builder: (column) => column);

  GeneratedColumn<String> get workCenterId => $composableBuilder(
    column: $table.workCenterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get machineCenterId => $composableBuilder(
    column: $table.machineCenterId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fromAt =>
      $composableBuilder(column: $table.fromAt, builder: (column) => column);

  GeneratedColumn<DateTime> get toAt =>
      $composableBuilder(column: $table.toAt, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$MfgLocalOeeSummariesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MfgLocalOeeSummariesTable,
          MfgOeeSummaryRow,
          $$MfgLocalOeeSummariesTableFilterComposer,
          $$MfgLocalOeeSummariesTableOrderingComposer,
          $$MfgLocalOeeSummariesTableAnnotationComposer,
          $$MfgLocalOeeSummariesTableCreateCompanionBuilder,
          $$MfgLocalOeeSummariesTableUpdateCompanionBuilder,
          (
            MfgOeeSummaryRow,
            BaseReferences<
              _$AppDatabase,
              $MfgLocalOeeSummariesTable,
              MfgOeeSummaryRow
            >,
          ),
          MfgOeeSummaryRow,
          PrefetchHooks Function()
        > {
  $$MfgLocalOeeSummariesTableTableManager(
    _$AppDatabase db,
    $MfgLocalOeeSummariesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MfgLocalOeeSummariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MfgLocalOeeSummariesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MfgLocalOeeSummariesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> scopeKey = const Value.absent(),
                Value<String> workCenterId = const Value.absent(),
                Value<String?> machineCenterId = const Value.absent(),
                Value<DateTime> fromAt = const Value.absent(),
                Value<DateTime> toAt = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MfgLocalOeeSummariesCompanion(
                tenantId: tenantId,
                scopeKey: scopeKey,
                workCenterId: workCenterId,
                machineCenterId: machineCenterId,
                fromAt: fromAt,
                toAt: toAt,
                payload: payload,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String scopeKey,
                required String workCenterId,
                Value<String?> machineCenterId = const Value.absent(),
                required DateTime fromAt,
                required DateTime toAt,
                required String payload,
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => MfgLocalOeeSummariesCompanion.insert(
                tenantId: tenantId,
                scopeKey: scopeKey,
                workCenterId: workCenterId,
                machineCenterId: machineCenterId,
                fromAt: fromAt,
                toAt: toAt,
                payload: payload,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MfgLocalOeeSummariesTable, MfgOeeSummaryRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $MfgLocalOeeSummariesTable,
                    MfgOeeSummaryRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MfgLocalOeeSummariesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MfgLocalOeeSummariesTable,
      MfgOeeSummaryRow,
      $$MfgLocalOeeSummariesTableFilterComposer,
      $$MfgLocalOeeSummariesTableOrderingComposer,
      $$MfgLocalOeeSummariesTableAnnotationComposer,
      $$MfgLocalOeeSummariesTableCreateCompanionBuilder,
      $$MfgLocalOeeSummariesTableUpdateCompanionBuilder,
      (
        MfgOeeSummaryRow,
        BaseReferences<
          _$AppDatabase,
          $MfgLocalOeeSummariesTable,
          MfgOeeSummaryRow
        >,
      ),
      MfgOeeSummaryRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EntityRecordsTableTableManager get entityRecords =>
      $$EntityRecordsTableTableManager(_db, _db.entityRecords);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$SyncCursorsTableTableManager get syncCursors =>
      $$SyncCursorsTableTableManager(_db, _db.syncCursors);
  $$TranslationsTableTableManager get translations =>
      $$TranslationsTableTableManager(_db, _db.translations);
  $$CopilotConversationsTableTableManager get copilotConversations =>
      $$CopilotConversationsTableTableManager(_db, _db.copilotConversations);
  $$CopilotMessagesTableTableManager get copilotMessages =>
      $$CopilotMessagesTableTableManager(_db, _db.copilotMessages);
  $$AuditQueueEntriesTableTableManager get auditQueueEntries =>
      $$AuditQueueEntriesTableTableManager(_db, _db.auditQueueEntries);
  $$DssExecutiveSnapshotsTableTableManager get dssExecutiveSnapshots =>
      $$DssExecutiveSnapshotsTableTableManager(_db, _db.dssExecutiveSnapshots);
  $$PermissionSnapshotsTableTableManager get permissionSnapshots =>
      $$PermissionSnapshotsTableTableManager(_db, _db.permissionSnapshots);
  $$LocalPurchaseRequisitionsTableTableManager get localPurchaseRequisitions =>
      $$LocalPurchaseRequisitionsTableTableManager(
        _db,
        _db.localPurchaseRequisitions,
      );
  $$LocalPurchaseRequisitionLinesTableTableManager
  get localPurchaseRequisitionLines =>
      $$LocalPurchaseRequisitionLinesTableTableManager(
        _db,
        _db.localPurchaseRequisitionLines,
      );
  $$LocalPendingApprovalsTableTableManager get localPendingApprovals =>
      $$LocalPendingApprovalsTableTableManager(_db, _db.localPendingApprovals);
  $$LocalApprovalAuditLogsTableTableManager get localApprovalAuditLogs =>
      $$LocalApprovalAuditLogsTableTableManager(
        _db,
        _db.localApprovalAuditLogs,
      );
  $$MfgLocalWorkCentersTableTableManager get mfgLocalWorkCenters =>
      $$MfgLocalWorkCentersTableTableManager(_db, _db.mfgLocalWorkCenters);
  $$MfgLocalMachinesTableTableManager get mfgLocalMachines =>
      $$MfgLocalMachinesTableTableManager(_db, _db.mfgLocalMachines);
  $$MfgLocalRoutingsTableTableManager get mfgLocalRoutings =>
      $$MfgLocalRoutingsTableTableManager(_db, _db.mfgLocalRoutings);
  $$MfgLocalRoutingStepsTableTableManager get mfgLocalRoutingSteps =>
      $$MfgLocalRoutingStepsTableTableManager(_db, _db.mfgLocalRoutingSteps);
  $$MfgLocalOeeSummariesTableTableManager get mfgLocalOeeSummaries =>
      $$MfgLocalOeeSummariesTableTableManager(_db, _db.mfgLocalOeeSummaries);
}
