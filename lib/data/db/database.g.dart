// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SessionsTable extends Sessions
    with TableInfo<$SessionsTable, SessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SessionStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SessionStatus>($SessionsTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<ErgSourceKind, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ErgSourceKind>($SessionsTable.$convertersource);
  static const VerificationMeta _deviceNameMeta = const VerificationMeta(
    'deviceName',
  );
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
    'device_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _distanceDmMeta = const VerificationMeta(
    'distanceDm',
  );
  @override
  late final GeneratedColumn<int> distanceDm = GeneratedColumn<int>(
    'distance_dm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _averagePaceCsMeta = const VerificationMeta(
    'averagePaceCs',
  );
  @override
  late final GeneratedColumn<int> averagePaceCs = GeneratedColumn<int>(
    'average_pace_cs',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _averageWattsMeta = const VerificationMeta(
    'averageWatts',
  );
  @override
  late final GeneratedColumn<int> averageWatts = GeneratedColumn<int>(
    'average_watts',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _averageStrokeRateMeta = const VerificationMeta(
    'averageStrokeRate',
  );
  @override
  late final GeneratedColumn<double> averageStrokeRate =
      GeneratedColumn<double>(
        'average_stroke_rate',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _strokeCountMeta = const VerificationMeta(
    'strokeCount',
  );
  @override
  late final GeneratedColumn<int> strokeCount = GeneratedColumn<int>(
    'stroke_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    endedAt,
    status,
    source,
    deviceName,
    durationMs,
    distanceDm,
    averagePaceCs,
    averageWatts,
    averageStrokeRate,
    strokeCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('device_name')) {
      context.handle(
        _deviceNameMeta,
        deviceName.isAcceptableOrUnknown(data['device_name']!, _deviceNameMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('distance_dm')) {
      context.handle(
        _distanceDmMeta,
        distanceDm.isAcceptableOrUnknown(data['distance_dm']!, _distanceDmMeta),
      );
    }
    if (data.containsKey('average_pace_cs')) {
      context.handle(
        _averagePaceCsMeta,
        averagePaceCs.isAcceptableOrUnknown(
          data['average_pace_cs']!,
          _averagePaceCsMeta,
        ),
      );
    }
    if (data.containsKey('average_watts')) {
      context.handle(
        _averageWattsMeta,
        averageWatts.isAcceptableOrUnknown(
          data['average_watts']!,
          _averageWattsMeta,
        ),
      );
    }
    if (data.containsKey('average_stroke_rate')) {
      context.handle(
        _averageStrokeRateMeta,
        averageStrokeRate.isAcceptableOrUnknown(
          data['average_stroke_rate']!,
          _averageStrokeRateMeta,
        ),
      );
    }
    if (data.containsKey('stroke_count')) {
      context.handle(
        _strokeCountMeta,
        strokeCount.isAcceptableOrUnknown(
          data['stroke_count']!,
          _strokeCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      status: $SessionsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      source: $SessionsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      deviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_name'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      distanceDm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distance_dm'],
      )!,
      averagePaceCs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}average_pace_cs'],
      ),
      averageWatts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}average_watts'],
      ),
      averageStrokeRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_stroke_rate'],
      ),
      strokeCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stroke_count'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SessionStatus, String, String> $converterstatus =
      const EnumNameConverter<SessionStatus>(SessionStatus.values);
  static JsonTypeConverter2<ErgSourceKind, String, String> $convertersource =
      const EnumNameConverter<ErgSourceKind>(ErgSourceKind.values);
}

class SessionRow extends DataClass implements Insertable<SessionRow> {
  final int id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final SessionStatus status;
  final ErgSourceKind source;
  final String? deviceName;
  final int durationMs;
  final int distanceDm;
  final int? averagePaceCs;
  final int? averageWatts;
  final double? averageStrokeRate;
  final int strokeCount;
  const SessionRow({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.status,
    required this.source,
    this.deviceName,
    required this.durationMs,
    required this.distanceDm,
    this.averagePaceCs,
    this.averageWatts,
    this.averageStrokeRate,
    required this.strokeCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    {
      map['status'] = Variable<String>(
        $SessionsTable.$converterstatus.toSql(status),
      );
    }
    {
      map['source'] = Variable<String>(
        $SessionsTable.$convertersource.toSql(source),
      );
    }
    if (!nullToAbsent || deviceName != null) {
      map['device_name'] = Variable<String>(deviceName);
    }
    map['duration_ms'] = Variable<int>(durationMs);
    map['distance_dm'] = Variable<int>(distanceDm);
    if (!nullToAbsent || averagePaceCs != null) {
      map['average_pace_cs'] = Variable<int>(averagePaceCs);
    }
    if (!nullToAbsent || averageWatts != null) {
      map['average_watts'] = Variable<int>(averageWatts);
    }
    if (!nullToAbsent || averageStrokeRate != null) {
      map['average_stroke_rate'] = Variable<double>(averageStrokeRate);
    }
    map['stroke_count'] = Variable<int>(strokeCount);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      status: Value(status),
      source: Value(source),
      deviceName: deviceName == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceName),
      durationMs: Value(durationMs),
      distanceDm: Value(distanceDm),
      averagePaceCs: averagePaceCs == null && nullToAbsent
          ? const Value.absent()
          : Value(averagePaceCs),
      averageWatts: averageWatts == null && nullToAbsent
          ? const Value.absent()
          : Value(averageWatts),
      averageStrokeRate: averageStrokeRate == null && nullToAbsent
          ? const Value.absent()
          : Value(averageStrokeRate),
      strokeCount: Value(strokeCount),
    );
  }

  factory SessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRow(
      id: serializer.fromJson<int>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      status: $SessionsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      source: $SessionsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      deviceName: serializer.fromJson<String?>(json['deviceName']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      distanceDm: serializer.fromJson<int>(json['distanceDm']),
      averagePaceCs: serializer.fromJson<int?>(json['averagePaceCs']),
      averageWatts: serializer.fromJson<int?>(json['averageWatts']),
      averageStrokeRate: serializer.fromJson<double?>(
        json['averageStrokeRate'],
      ),
      strokeCount: serializer.fromJson<int>(json['strokeCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'status': serializer.toJson<String>(
        $SessionsTable.$converterstatus.toJson(status),
      ),
      'source': serializer.toJson<String>(
        $SessionsTable.$convertersource.toJson(source),
      ),
      'deviceName': serializer.toJson<String?>(deviceName),
      'durationMs': serializer.toJson<int>(durationMs),
      'distanceDm': serializer.toJson<int>(distanceDm),
      'averagePaceCs': serializer.toJson<int?>(averagePaceCs),
      'averageWatts': serializer.toJson<int?>(averageWatts),
      'averageStrokeRate': serializer.toJson<double?>(averageStrokeRate),
      'strokeCount': serializer.toJson<int>(strokeCount),
    };
  }

  SessionRow copyWith({
    int? id,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    SessionStatus? status,
    ErgSourceKind? source,
    Value<String?> deviceName = const Value.absent(),
    int? durationMs,
    int? distanceDm,
    Value<int?> averagePaceCs = const Value.absent(),
    Value<int?> averageWatts = const Value.absent(),
    Value<double?> averageStrokeRate = const Value.absent(),
    int? strokeCount,
  }) => SessionRow(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    status: status ?? this.status,
    source: source ?? this.source,
    deviceName: deviceName.present ? deviceName.value : this.deviceName,
    durationMs: durationMs ?? this.durationMs,
    distanceDm: distanceDm ?? this.distanceDm,
    averagePaceCs: averagePaceCs.present
        ? averagePaceCs.value
        : this.averagePaceCs,
    averageWatts: averageWatts.present ? averageWatts.value : this.averageWatts,
    averageStrokeRate: averageStrokeRate.present
        ? averageStrokeRate.value
        : this.averageStrokeRate,
    strokeCount: strokeCount ?? this.strokeCount,
  );
  SessionRow copyWithCompanion(SessionsCompanion data) {
    return SessionRow(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      status: data.status.present ? data.status.value : this.status,
      source: data.source.present ? data.source.value : this.source,
      deviceName: data.deviceName.present
          ? data.deviceName.value
          : this.deviceName,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      distanceDm: data.distanceDm.present
          ? data.distanceDm.value
          : this.distanceDm,
      averagePaceCs: data.averagePaceCs.present
          ? data.averagePaceCs.value
          : this.averagePaceCs,
      averageWatts: data.averageWatts.present
          ? data.averageWatts.value
          : this.averageWatts,
      averageStrokeRate: data.averageStrokeRate.present
          ? data.averageStrokeRate.value
          : this.averageStrokeRate,
      strokeCount: data.strokeCount.present
          ? data.strokeCount.value
          : this.strokeCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRow(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('deviceName: $deviceName, ')
          ..write('durationMs: $durationMs, ')
          ..write('distanceDm: $distanceDm, ')
          ..write('averagePaceCs: $averagePaceCs, ')
          ..write('averageWatts: $averageWatts, ')
          ..write('averageStrokeRate: $averageStrokeRate, ')
          ..write('strokeCount: $strokeCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startedAt,
    endedAt,
    status,
    source,
    deviceName,
    durationMs,
    distanceDm,
    averagePaceCs,
    averageWatts,
    averageStrokeRate,
    strokeCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRow &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.status == this.status &&
          other.source == this.source &&
          other.deviceName == this.deviceName &&
          other.durationMs == this.durationMs &&
          other.distanceDm == this.distanceDm &&
          other.averagePaceCs == this.averagePaceCs &&
          other.averageWatts == this.averageWatts &&
          other.averageStrokeRate == this.averageStrokeRate &&
          other.strokeCount == this.strokeCount);
}

class SessionsCompanion extends UpdateCompanion<SessionRow> {
  final Value<int> id;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<SessionStatus> status;
  final Value<ErgSourceKind> source;
  final Value<String?> deviceName;
  final Value<int> durationMs;
  final Value<int> distanceDm;
  final Value<int?> averagePaceCs;
  final Value<int?> averageWatts;
  final Value<double?> averageStrokeRate;
  final Value<int> strokeCount;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.source = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.distanceDm = const Value.absent(),
    this.averagePaceCs = const Value.absent(),
    this.averageWatts = const Value.absent(),
    this.averageStrokeRate = const Value.absent(),
    this.strokeCount = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    required SessionStatus status,
    required ErgSourceKind source,
    this.deviceName = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.distanceDm = const Value.absent(),
    this.averagePaceCs = const Value.absent(),
    this.averageWatts = const Value.absent(),
    this.averageStrokeRate = const Value.absent(),
    this.strokeCount = const Value.absent(),
  }) : startedAt = Value(startedAt),
       status = Value(status),
       source = Value(source);
  static Insertable<SessionRow> custom({
    Expression<int>? id,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? status,
    Expression<String>? source,
    Expression<String>? deviceName,
    Expression<int>? durationMs,
    Expression<int>? distanceDm,
    Expression<int>? averagePaceCs,
    Expression<int>? averageWatts,
    Expression<double>? averageStrokeRate,
    Expression<int>? strokeCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (status != null) 'status': status,
      if (source != null) 'source': source,
      if (deviceName != null) 'device_name': deviceName,
      if (durationMs != null) 'duration_ms': durationMs,
      if (distanceDm != null) 'distance_dm': distanceDm,
      if (averagePaceCs != null) 'average_pace_cs': averagePaceCs,
      if (averageWatts != null) 'average_watts': averageWatts,
      if (averageStrokeRate != null) 'average_stroke_rate': averageStrokeRate,
      if (strokeCount != null) 'stroke_count': strokeCount,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<SessionStatus>? status,
    Value<ErgSourceKind>? source,
    Value<String?>? deviceName,
    Value<int>? durationMs,
    Value<int>? distanceDm,
    Value<int?>? averagePaceCs,
    Value<int?>? averageWatts,
    Value<double?>? averageStrokeRate,
    Value<int>? strokeCount,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      source: source ?? this.source,
      deviceName: deviceName ?? this.deviceName,
      durationMs: durationMs ?? this.durationMs,
      distanceDm: distanceDm ?? this.distanceDm,
      averagePaceCs: averagePaceCs ?? this.averagePaceCs,
      averageWatts: averageWatts ?? this.averageWatts,
      averageStrokeRate: averageStrokeRate ?? this.averageStrokeRate,
      strokeCount: strokeCount ?? this.strokeCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $SessionsTable.$converterstatus.toSql(status.value),
      );
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $SessionsTable.$convertersource.toSql(source.value),
      );
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (distanceDm.present) {
      map['distance_dm'] = Variable<int>(distanceDm.value);
    }
    if (averagePaceCs.present) {
      map['average_pace_cs'] = Variable<int>(averagePaceCs.value);
    }
    if (averageWatts.present) {
      map['average_watts'] = Variable<int>(averageWatts.value);
    }
    if (averageStrokeRate.present) {
      map['average_stroke_rate'] = Variable<double>(averageStrokeRate.value);
    }
    if (strokeCount.present) {
      map['stroke_count'] = Variable<int>(strokeCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('deviceName: $deviceName, ')
          ..write('durationMs: $durationMs, ')
          ..write('distanceDm: $distanceDm, ')
          ..write('averagePaceCs: $averagePaceCs, ')
          ..write('averageWatts: $averageWatts, ')
          ..write('averageStrokeRate: $averageStrokeRate, ')
          ..write('strokeCount: $strokeCount')
          ..write(')'))
        .toString();
  }
}

class $SamplesTable extends Samples with TableInfo<$SamplesTable, SampleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tMsMeta = const VerificationMeta('tMs');
  @override
  late final GeneratedColumn<int> tMs = GeneratedColumn<int>(
    't_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceDmMeta = const VerificationMeta(
    'distanceDm',
  );
  @override
  late final GeneratedColumn<int> distanceDm = GeneratedColumn<int>(
    'distance_dm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paceCsMeta = const VerificationMeta('paceCs');
  @override
  late final GeneratedColumn<int> paceCs = GeneratedColumn<int>(
    'pace_cs',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wattsMeta = const VerificationMeta('watts');
  @override
  late final GeneratedColumn<int> watts = GeneratedColumn<int>(
    'watts',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _strokeRateMeta = const VerificationMeta(
    'strokeRate',
  );
  @override
  late final GeneratedColumn<int> strokeRate = GeneratedColumn<int>(
    'stroke_rate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heartRateMeta = const VerificationMeta(
    'heartRate',
  );
  @override
  late final GeneratedColumn<int> heartRate = GeneratedColumn<int>(
    'heart_rate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<int> calories = GeneratedColumn<int>(
    'calories',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    tMs,
    distanceDm,
    paceCs,
    watts,
    strokeRate,
    heartRate,
    calories,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<SampleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('t_ms')) {
      context.handle(
        _tMsMeta,
        tMs.isAcceptableOrUnknown(data['t_ms']!, _tMsMeta),
      );
    } else if (isInserting) {
      context.missing(_tMsMeta);
    }
    if (data.containsKey('distance_dm')) {
      context.handle(
        _distanceDmMeta,
        distanceDm.isAcceptableOrUnknown(data['distance_dm']!, _distanceDmMeta),
      );
    } else if (isInserting) {
      context.missing(_distanceDmMeta);
    }
    if (data.containsKey('pace_cs')) {
      context.handle(
        _paceCsMeta,
        paceCs.isAcceptableOrUnknown(data['pace_cs']!, _paceCsMeta),
      );
    }
    if (data.containsKey('watts')) {
      context.handle(
        _wattsMeta,
        watts.isAcceptableOrUnknown(data['watts']!, _wattsMeta),
      );
    }
    if (data.containsKey('stroke_rate')) {
      context.handle(
        _strokeRateMeta,
        strokeRate.isAcceptableOrUnknown(data['stroke_rate']!, _strokeRateMeta),
      );
    }
    if (data.containsKey('heart_rate')) {
      context.handle(
        _heartRateMeta,
        heartRate.isAcceptableOrUnknown(data['heart_rate']!, _heartRateMeta),
      );
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  SampleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SampleRow(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      tMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}t_ms'],
      )!,
      distanceDm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distance_dm'],
      )!,
      paceCs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pace_cs'],
      ),
      watts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}watts'],
      ),
      strokeRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stroke_rate'],
      ),
      heartRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}heart_rate'],
      ),
      calories: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calories'],
      ),
    );
  }

  @override
  $SamplesTable createAlias(String alias) {
    return $SamplesTable(attachedDatabase, alias);
  }
}

class SampleRow extends DataClass implements Insertable<SampleRow> {
  final int sessionId;
  final int tMs;
  final int distanceDm;
  final int? paceCs;
  final int? watts;
  final int? strokeRate;
  final int? heartRate;
  final int? calories;
  const SampleRow({
    required this.sessionId,
    required this.tMs,
    required this.distanceDm,
    this.paceCs,
    this.watts,
    this.strokeRate,
    this.heartRate,
    this.calories,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<int>(sessionId);
    map['t_ms'] = Variable<int>(tMs);
    map['distance_dm'] = Variable<int>(distanceDm);
    if (!nullToAbsent || paceCs != null) {
      map['pace_cs'] = Variable<int>(paceCs);
    }
    if (!nullToAbsent || watts != null) {
      map['watts'] = Variable<int>(watts);
    }
    if (!nullToAbsent || strokeRate != null) {
      map['stroke_rate'] = Variable<int>(strokeRate);
    }
    if (!nullToAbsent || heartRate != null) {
      map['heart_rate'] = Variable<int>(heartRate);
    }
    if (!nullToAbsent || calories != null) {
      map['calories'] = Variable<int>(calories);
    }
    return map;
  }

  SamplesCompanion toCompanion(bool nullToAbsent) {
    return SamplesCompanion(
      sessionId: Value(sessionId),
      tMs: Value(tMs),
      distanceDm: Value(distanceDm),
      paceCs: paceCs == null && nullToAbsent
          ? const Value.absent()
          : Value(paceCs),
      watts: watts == null && nullToAbsent
          ? const Value.absent()
          : Value(watts),
      strokeRate: strokeRate == null && nullToAbsent
          ? const Value.absent()
          : Value(strokeRate),
      heartRate: heartRate == null && nullToAbsent
          ? const Value.absent()
          : Value(heartRate),
      calories: calories == null && nullToAbsent
          ? const Value.absent()
          : Value(calories),
    );
  }

  factory SampleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SampleRow(
      sessionId: serializer.fromJson<int>(json['sessionId']),
      tMs: serializer.fromJson<int>(json['tMs']),
      distanceDm: serializer.fromJson<int>(json['distanceDm']),
      paceCs: serializer.fromJson<int?>(json['paceCs']),
      watts: serializer.fromJson<int?>(json['watts']),
      strokeRate: serializer.fromJson<int?>(json['strokeRate']),
      heartRate: serializer.fromJson<int?>(json['heartRate']),
      calories: serializer.fromJson<int?>(json['calories']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<int>(sessionId),
      'tMs': serializer.toJson<int>(tMs),
      'distanceDm': serializer.toJson<int>(distanceDm),
      'paceCs': serializer.toJson<int?>(paceCs),
      'watts': serializer.toJson<int?>(watts),
      'strokeRate': serializer.toJson<int?>(strokeRate),
      'heartRate': serializer.toJson<int?>(heartRate),
      'calories': serializer.toJson<int?>(calories),
    };
  }

  SampleRow copyWith({
    int? sessionId,
    int? tMs,
    int? distanceDm,
    Value<int?> paceCs = const Value.absent(),
    Value<int?> watts = const Value.absent(),
    Value<int?> strokeRate = const Value.absent(),
    Value<int?> heartRate = const Value.absent(),
    Value<int?> calories = const Value.absent(),
  }) => SampleRow(
    sessionId: sessionId ?? this.sessionId,
    tMs: tMs ?? this.tMs,
    distanceDm: distanceDm ?? this.distanceDm,
    paceCs: paceCs.present ? paceCs.value : this.paceCs,
    watts: watts.present ? watts.value : this.watts,
    strokeRate: strokeRate.present ? strokeRate.value : this.strokeRate,
    heartRate: heartRate.present ? heartRate.value : this.heartRate,
    calories: calories.present ? calories.value : this.calories,
  );
  SampleRow copyWithCompanion(SamplesCompanion data) {
    return SampleRow(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      tMs: data.tMs.present ? data.tMs.value : this.tMs,
      distanceDm: data.distanceDm.present
          ? data.distanceDm.value
          : this.distanceDm,
      paceCs: data.paceCs.present ? data.paceCs.value : this.paceCs,
      watts: data.watts.present ? data.watts.value : this.watts,
      strokeRate: data.strokeRate.present
          ? data.strokeRate.value
          : this.strokeRate,
      heartRate: data.heartRate.present ? data.heartRate.value : this.heartRate,
      calories: data.calories.present ? data.calories.value : this.calories,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SampleRow(')
          ..write('sessionId: $sessionId, ')
          ..write('tMs: $tMs, ')
          ..write('distanceDm: $distanceDm, ')
          ..write('paceCs: $paceCs, ')
          ..write('watts: $watts, ')
          ..write('strokeRate: $strokeRate, ')
          ..write('heartRate: $heartRate, ')
          ..write('calories: $calories')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    tMs,
    distanceDm,
    paceCs,
    watts,
    strokeRate,
    heartRate,
    calories,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SampleRow &&
          other.sessionId == this.sessionId &&
          other.tMs == this.tMs &&
          other.distanceDm == this.distanceDm &&
          other.paceCs == this.paceCs &&
          other.watts == this.watts &&
          other.strokeRate == this.strokeRate &&
          other.heartRate == this.heartRate &&
          other.calories == this.calories);
}

class SamplesCompanion extends UpdateCompanion<SampleRow> {
  final Value<int> sessionId;
  final Value<int> tMs;
  final Value<int> distanceDm;
  final Value<int?> paceCs;
  final Value<int?> watts;
  final Value<int?> strokeRate;
  final Value<int?> heartRate;
  final Value<int?> calories;
  final Value<int> rowid;
  const SamplesCompanion({
    this.sessionId = const Value.absent(),
    this.tMs = const Value.absent(),
    this.distanceDm = const Value.absent(),
    this.paceCs = const Value.absent(),
    this.watts = const Value.absent(),
    this.strokeRate = const Value.absent(),
    this.heartRate = const Value.absent(),
    this.calories = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SamplesCompanion.insert({
    required int sessionId,
    required int tMs,
    required int distanceDm,
    this.paceCs = const Value.absent(),
    this.watts = const Value.absent(),
    this.strokeRate = const Value.absent(),
    this.heartRate = const Value.absent(),
    this.calories = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       tMs = Value(tMs),
       distanceDm = Value(distanceDm);
  static Insertable<SampleRow> custom({
    Expression<int>? sessionId,
    Expression<int>? tMs,
    Expression<int>? distanceDm,
    Expression<int>? paceCs,
    Expression<int>? watts,
    Expression<int>? strokeRate,
    Expression<int>? heartRate,
    Expression<int>? calories,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (tMs != null) 't_ms': tMs,
      if (distanceDm != null) 'distance_dm': distanceDm,
      if (paceCs != null) 'pace_cs': paceCs,
      if (watts != null) 'watts': watts,
      if (strokeRate != null) 'stroke_rate': strokeRate,
      if (heartRate != null) 'heart_rate': heartRate,
      if (calories != null) 'calories': calories,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SamplesCompanion copyWith({
    Value<int>? sessionId,
    Value<int>? tMs,
    Value<int>? distanceDm,
    Value<int?>? paceCs,
    Value<int?>? watts,
    Value<int?>? strokeRate,
    Value<int?>? heartRate,
    Value<int?>? calories,
    Value<int>? rowid,
  }) {
    return SamplesCompanion(
      sessionId: sessionId ?? this.sessionId,
      tMs: tMs ?? this.tMs,
      distanceDm: distanceDm ?? this.distanceDm,
      paceCs: paceCs ?? this.paceCs,
      watts: watts ?? this.watts,
      strokeRate: strokeRate ?? this.strokeRate,
      heartRate: heartRate ?? this.heartRate,
      calories: calories ?? this.calories,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (tMs.present) {
      map['t_ms'] = Variable<int>(tMs.value);
    }
    if (distanceDm.present) {
      map['distance_dm'] = Variable<int>(distanceDm.value);
    }
    if (paceCs.present) {
      map['pace_cs'] = Variable<int>(paceCs.value);
    }
    if (watts.present) {
      map['watts'] = Variable<int>(watts.value);
    }
    if (strokeRate.present) {
      map['stroke_rate'] = Variable<int>(strokeRate.value);
    }
    if (heartRate.present) {
      map['heart_rate'] = Variable<int>(heartRate.value);
    }
    if (calories.present) {
      map['calories'] = Variable<int>(calories.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SamplesCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('tMs: $tMs, ')
          ..write('distanceDm: $distanceDm, ')
          ..write('paceCs: $paceCs, ')
          ..write('watts: $watts, ')
          ..write('strokeRate: $strokeRate, ')
          ..write('heartRate: $heartRate, ')
          ..write('calories: $calories, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StrokesTable extends Strokes with TableInfo<$StrokesTable, StrokeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StrokesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tMsMeta = const VerificationMeta('tMs');
  @override
  late final GeneratedColumn<int> tMs = GeneratedColumn<int>(
    't_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceDmMeta = const VerificationMeta(
    'distanceDm',
  );
  @override
  late final GeneratedColumn<int> distanceDm = GeneratedColumn<int>(
    'distance_dm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strokeNumberMeta = const VerificationMeta(
    'strokeNumber',
  );
  @override
  late final GeneratedColumn<int> strokeNumber = GeneratedColumn<int>(
    'stroke_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _driveLengthMetersMeta = const VerificationMeta(
    'driveLengthMeters',
  );
  @override
  late final GeneratedColumn<double> driveLengthMeters =
      GeneratedColumn<double>(
        'drive_length_meters',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _driveTimeMsMeta = const VerificationMeta(
    'driveTimeMs',
  );
  @override
  late final GeneratedColumn<int> driveTimeMs = GeneratedColumn<int>(
    'drive_time_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recoveryTimeMsMeta = const VerificationMeta(
    'recoveryTimeMs',
  );
  @override
  late final GeneratedColumn<int> recoveryTimeMs = GeneratedColumn<int>(
    'recovery_time_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peakForceNewtonsMeta = const VerificationMeta(
    'peakForceNewtons',
  );
  @override
  late final GeneratedColumn<double> peakForceNewtons = GeneratedColumn<double>(
    'peak_force_newtons',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _averageForceNewtonsMeta =
      const VerificationMeta('averageForceNewtons');
  @override
  late final GeneratedColumn<double> averageForceNewtons =
      GeneratedColumn<double>(
        'average_force_newtons',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _wattsMeta = const VerificationMeta('watts');
  @override
  late final GeneratedColumn<int> watts = GeneratedColumn<int>(
    'watts',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    tMs,
    distanceDm,
    strokeNumber,
    driveLengthMeters,
    driveTimeMs,
    recoveryTimeMs,
    peakForceNewtons,
    averageForceNewtons,
    watts,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'strokes';
  @override
  VerificationContext validateIntegrity(
    Insertable<StrokeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('t_ms')) {
      context.handle(
        _tMsMeta,
        tMs.isAcceptableOrUnknown(data['t_ms']!, _tMsMeta),
      );
    } else if (isInserting) {
      context.missing(_tMsMeta);
    }
    if (data.containsKey('distance_dm')) {
      context.handle(
        _distanceDmMeta,
        distanceDm.isAcceptableOrUnknown(data['distance_dm']!, _distanceDmMeta),
      );
    } else if (isInserting) {
      context.missing(_distanceDmMeta);
    }
    if (data.containsKey('stroke_number')) {
      context.handle(
        _strokeNumberMeta,
        strokeNumber.isAcceptableOrUnknown(
          data['stroke_number']!,
          _strokeNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_strokeNumberMeta);
    }
    if (data.containsKey('drive_length_meters')) {
      context.handle(
        _driveLengthMetersMeta,
        driveLengthMeters.isAcceptableOrUnknown(
          data['drive_length_meters']!,
          _driveLengthMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_driveLengthMetersMeta);
    }
    if (data.containsKey('drive_time_ms')) {
      context.handle(
        _driveTimeMsMeta,
        driveTimeMs.isAcceptableOrUnknown(
          data['drive_time_ms']!,
          _driveTimeMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_driveTimeMsMeta);
    }
    if (data.containsKey('recovery_time_ms')) {
      context.handle(
        _recoveryTimeMsMeta,
        recoveryTimeMs.isAcceptableOrUnknown(
          data['recovery_time_ms']!,
          _recoveryTimeMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recoveryTimeMsMeta);
    }
    if (data.containsKey('peak_force_newtons')) {
      context.handle(
        _peakForceNewtonsMeta,
        peakForceNewtons.isAcceptableOrUnknown(
          data['peak_force_newtons']!,
          _peakForceNewtonsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_peakForceNewtonsMeta);
    }
    if (data.containsKey('average_force_newtons')) {
      context.handle(
        _averageForceNewtonsMeta,
        averageForceNewtons.isAcceptableOrUnknown(
          data['average_force_newtons']!,
          _averageForceNewtonsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_averageForceNewtonsMeta);
    }
    if (data.containsKey('watts')) {
      context.handle(
        _wattsMeta,
        watts.isAcceptableOrUnknown(data['watts']!, _wattsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  StrokeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StrokeRow(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      tMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}t_ms'],
      )!,
      distanceDm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distance_dm'],
      )!,
      strokeNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stroke_number'],
      )!,
      driveLengthMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}drive_length_meters'],
      )!,
      driveTimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}drive_time_ms'],
      )!,
      recoveryTimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recovery_time_ms'],
      )!,
      peakForceNewtons: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}peak_force_newtons'],
      )!,
      averageForceNewtons: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_force_newtons'],
      )!,
      watts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}watts'],
      ),
    );
  }

  @override
  $StrokesTable createAlias(String alias) {
    return $StrokesTable(attachedDatabase, alias);
  }
}

class StrokeRow extends DataClass implements Insertable<StrokeRow> {
  final int sessionId;
  final int tMs;
  final int distanceDm;
  final int strokeNumber;
  final double driveLengthMeters;
  final int driveTimeMs;
  final int recoveryTimeMs;
  final double peakForceNewtons;
  final double averageForceNewtons;
  final int? watts;
  const StrokeRow({
    required this.sessionId,
    required this.tMs,
    required this.distanceDm,
    required this.strokeNumber,
    required this.driveLengthMeters,
    required this.driveTimeMs,
    required this.recoveryTimeMs,
    required this.peakForceNewtons,
    required this.averageForceNewtons,
    this.watts,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<int>(sessionId);
    map['t_ms'] = Variable<int>(tMs);
    map['distance_dm'] = Variable<int>(distanceDm);
    map['stroke_number'] = Variable<int>(strokeNumber);
    map['drive_length_meters'] = Variable<double>(driveLengthMeters);
    map['drive_time_ms'] = Variable<int>(driveTimeMs);
    map['recovery_time_ms'] = Variable<int>(recoveryTimeMs);
    map['peak_force_newtons'] = Variable<double>(peakForceNewtons);
    map['average_force_newtons'] = Variable<double>(averageForceNewtons);
    if (!nullToAbsent || watts != null) {
      map['watts'] = Variable<int>(watts);
    }
    return map;
  }

  StrokesCompanion toCompanion(bool nullToAbsent) {
    return StrokesCompanion(
      sessionId: Value(sessionId),
      tMs: Value(tMs),
      distanceDm: Value(distanceDm),
      strokeNumber: Value(strokeNumber),
      driveLengthMeters: Value(driveLengthMeters),
      driveTimeMs: Value(driveTimeMs),
      recoveryTimeMs: Value(recoveryTimeMs),
      peakForceNewtons: Value(peakForceNewtons),
      averageForceNewtons: Value(averageForceNewtons),
      watts: watts == null && nullToAbsent
          ? const Value.absent()
          : Value(watts),
    );
  }

  factory StrokeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StrokeRow(
      sessionId: serializer.fromJson<int>(json['sessionId']),
      tMs: serializer.fromJson<int>(json['tMs']),
      distanceDm: serializer.fromJson<int>(json['distanceDm']),
      strokeNumber: serializer.fromJson<int>(json['strokeNumber']),
      driveLengthMeters: serializer.fromJson<double>(json['driveLengthMeters']),
      driveTimeMs: serializer.fromJson<int>(json['driveTimeMs']),
      recoveryTimeMs: serializer.fromJson<int>(json['recoveryTimeMs']),
      peakForceNewtons: serializer.fromJson<double>(json['peakForceNewtons']),
      averageForceNewtons: serializer.fromJson<double>(
        json['averageForceNewtons'],
      ),
      watts: serializer.fromJson<int?>(json['watts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<int>(sessionId),
      'tMs': serializer.toJson<int>(tMs),
      'distanceDm': serializer.toJson<int>(distanceDm),
      'strokeNumber': serializer.toJson<int>(strokeNumber),
      'driveLengthMeters': serializer.toJson<double>(driveLengthMeters),
      'driveTimeMs': serializer.toJson<int>(driveTimeMs),
      'recoveryTimeMs': serializer.toJson<int>(recoveryTimeMs),
      'peakForceNewtons': serializer.toJson<double>(peakForceNewtons),
      'averageForceNewtons': serializer.toJson<double>(averageForceNewtons),
      'watts': serializer.toJson<int?>(watts),
    };
  }

  StrokeRow copyWith({
    int? sessionId,
    int? tMs,
    int? distanceDm,
    int? strokeNumber,
    double? driveLengthMeters,
    int? driveTimeMs,
    int? recoveryTimeMs,
    double? peakForceNewtons,
    double? averageForceNewtons,
    Value<int?> watts = const Value.absent(),
  }) => StrokeRow(
    sessionId: sessionId ?? this.sessionId,
    tMs: tMs ?? this.tMs,
    distanceDm: distanceDm ?? this.distanceDm,
    strokeNumber: strokeNumber ?? this.strokeNumber,
    driveLengthMeters: driveLengthMeters ?? this.driveLengthMeters,
    driveTimeMs: driveTimeMs ?? this.driveTimeMs,
    recoveryTimeMs: recoveryTimeMs ?? this.recoveryTimeMs,
    peakForceNewtons: peakForceNewtons ?? this.peakForceNewtons,
    averageForceNewtons: averageForceNewtons ?? this.averageForceNewtons,
    watts: watts.present ? watts.value : this.watts,
  );
  StrokeRow copyWithCompanion(StrokesCompanion data) {
    return StrokeRow(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      tMs: data.tMs.present ? data.tMs.value : this.tMs,
      distanceDm: data.distanceDm.present
          ? data.distanceDm.value
          : this.distanceDm,
      strokeNumber: data.strokeNumber.present
          ? data.strokeNumber.value
          : this.strokeNumber,
      driveLengthMeters: data.driveLengthMeters.present
          ? data.driveLengthMeters.value
          : this.driveLengthMeters,
      driveTimeMs: data.driveTimeMs.present
          ? data.driveTimeMs.value
          : this.driveTimeMs,
      recoveryTimeMs: data.recoveryTimeMs.present
          ? data.recoveryTimeMs.value
          : this.recoveryTimeMs,
      peakForceNewtons: data.peakForceNewtons.present
          ? data.peakForceNewtons.value
          : this.peakForceNewtons,
      averageForceNewtons: data.averageForceNewtons.present
          ? data.averageForceNewtons.value
          : this.averageForceNewtons,
      watts: data.watts.present ? data.watts.value : this.watts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StrokeRow(')
          ..write('sessionId: $sessionId, ')
          ..write('tMs: $tMs, ')
          ..write('distanceDm: $distanceDm, ')
          ..write('strokeNumber: $strokeNumber, ')
          ..write('driveLengthMeters: $driveLengthMeters, ')
          ..write('driveTimeMs: $driveTimeMs, ')
          ..write('recoveryTimeMs: $recoveryTimeMs, ')
          ..write('peakForceNewtons: $peakForceNewtons, ')
          ..write('averageForceNewtons: $averageForceNewtons, ')
          ..write('watts: $watts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    tMs,
    distanceDm,
    strokeNumber,
    driveLengthMeters,
    driveTimeMs,
    recoveryTimeMs,
    peakForceNewtons,
    averageForceNewtons,
    watts,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StrokeRow &&
          other.sessionId == this.sessionId &&
          other.tMs == this.tMs &&
          other.distanceDm == this.distanceDm &&
          other.strokeNumber == this.strokeNumber &&
          other.driveLengthMeters == this.driveLengthMeters &&
          other.driveTimeMs == this.driveTimeMs &&
          other.recoveryTimeMs == this.recoveryTimeMs &&
          other.peakForceNewtons == this.peakForceNewtons &&
          other.averageForceNewtons == this.averageForceNewtons &&
          other.watts == this.watts);
}

class StrokesCompanion extends UpdateCompanion<StrokeRow> {
  final Value<int> sessionId;
  final Value<int> tMs;
  final Value<int> distanceDm;
  final Value<int> strokeNumber;
  final Value<double> driveLengthMeters;
  final Value<int> driveTimeMs;
  final Value<int> recoveryTimeMs;
  final Value<double> peakForceNewtons;
  final Value<double> averageForceNewtons;
  final Value<int?> watts;
  final Value<int> rowid;
  const StrokesCompanion({
    this.sessionId = const Value.absent(),
    this.tMs = const Value.absent(),
    this.distanceDm = const Value.absent(),
    this.strokeNumber = const Value.absent(),
    this.driveLengthMeters = const Value.absent(),
    this.driveTimeMs = const Value.absent(),
    this.recoveryTimeMs = const Value.absent(),
    this.peakForceNewtons = const Value.absent(),
    this.averageForceNewtons = const Value.absent(),
    this.watts = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StrokesCompanion.insert({
    required int sessionId,
    required int tMs,
    required int distanceDm,
    required int strokeNumber,
    required double driveLengthMeters,
    required int driveTimeMs,
    required int recoveryTimeMs,
    required double peakForceNewtons,
    required double averageForceNewtons,
    this.watts = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       tMs = Value(tMs),
       distanceDm = Value(distanceDm),
       strokeNumber = Value(strokeNumber),
       driveLengthMeters = Value(driveLengthMeters),
       driveTimeMs = Value(driveTimeMs),
       recoveryTimeMs = Value(recoveryTimeMs),
       peakForceNewtons = Value(peakForceNewtons),
       averageForceNewtons = Value(averageForceNewtons);
  static Insertable<StrokeRow> custom({
    Expression<int>? sessionId,
    Expression<int>? tMs,
    Expression<int>? distanceDm,
    Expression<int>? strokeNumber,
    Expression<double>? driveLengthMeters,
    Expression<int>? driveTimeMs,
    Expression<int>? recoveryTimeMs,
    Expression<double>? peakForceNewtons,
    Expression<double>? averageForceNewtons,
    Expression<int>? watts,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (tMs != null) 't_ms': tMs,
      if (distanceDm != null) 'distance_dm': distanceDm,
      if (strokeNumber != null) 'stroke_number': strokeNumber,
      if (driveLengthMeters != null) 'drive_length_meters': driveLengthMeters,
      if (driveTimeMs != null) 'drive_time_ms': driveTimeMs,
      if (recoveryTimeMs != null) 'recovery_time_ms': recoveryTimeMs,
      if (peakForceNewtons != null) 'peak_force_newtons': peakForceNewtons,
      if (averageForceNewtons != null)
        'average_force_newtons': averageForceNewtons,
      if (watts != null) 'watts': watts,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StrokesCompanion copyWith({
    Value<int>? sessionId,
    Value<int>? tMs,
    Value<int>? distanceDm,
    Value<int>? strokeNumber,
    Value<double>? driveLengthMeters,
    Value<int>? driveTimeMs,
    Value<int>? recoveryTimeMs,
    Value<double>? peakForceNewtons,
    Value<double>? averageForceNewtons,
    Value<int?>? watts,
    Value<int>? rowid,
  }) {
    return StrokesCompanion(
      sessionId: sessionId ?? this.sessionId,
      tMs: tMs ?? this.tMs,
      distanceDm: distanceDm ?? this.distanceDm,
      strokeNumber: strokeNumber ?? this.strokeNumber,
      driveLengthMeters: driveLengthMeters ?? this.driveLengthMeters,
      driveTimeMs: driveTimeMs ?? this.driveTimeMs,
      recoveryTimeMs: recoveryTimeMs ?? this.recoveryTimeMs,
      peakForceNewtons: peakForceNewtons ?? this.peakForceNewtons,
      averageForceNewtons: averageForceNewtons ?? this.averageForceNewtons,
      watts: watts ?? this.watts,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (tMs.present) {
      map['t_ms'] = Variable<int>(tMs.value);
    }
    if (distanceDm.present) {
      map['distance_dm'] = Variable<int>(distanceDm.value);
    }
    if (strokeNumber.present) {
      map['stroke_number'] = Variable<int>(strokeNumber.value);
    }
    if (driveLengthMeters.present) {
      map['drive_length_meters'] = Variable<double>(driveLengthMeters.value);
    }
    if (driveTimeMs.present) {
      map['drive_time_ms'] = Variable<int>(driveTimeMs.value);
    }
    if (recoveryTimeMs.present) {
      map['recovery_time_ms'] = Variable<int>(recoveryTimeMs.value);
    }
    if (peakForceNewtons.present) {
      map['peak_force_newtons'] = Variable<double>(peakForceNewtons.value);
    }
    if (averageForceNewtons.present) {
      map['average_force_newtons'] = Variable<double>(
        averageForceNewtons.value,
      );
    }
    if (watts.present) {
      map['watts'] = Variable<int>(watts.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StrokesCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('tMs: $tMs, ')
          ..write('distanceDm: $distanceDm, ')
          ..write('strokeNumber: $strokeNumber, ')
          ..write('driveLengthMeters: $driveLengthMeters, ')
          ..write('driveTimeMs: $driveTimeMs, ')
          ..write('recoveryTimeMs: $recoveryTimeMs, ')
          ..write('peakForceNewtons: $peakForceNewtons, ')
          ..write('averageForceNewtons: $averageForceNewtons, ')
          ..write('watts: $watts, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RawPacketsTable extends RawPackets
    with TableInfo<$RawPacketsTable, RawPacketRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RawPacketsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tMsMeta = const VerificationMeta('tMs');
  @override
  late final GeneratedColumn<int> tMs = GeneratedColumn<int>(
    't_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _characteristicIdMeta = const VerificationMeta(
    'characteristicId',
  );
  @override
  late final GeneratedColumn<String> characteristicId = GeneratedColumn<String>(
    'characteristic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<Uint8List> bytes = GeneratedColumn<Uint8List>(
    'bytes',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    tMs,
    characteristicId,
    bytes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'raw_packets';
  @override
  VerificationContext validateIntegrity(
    Insertable<RawPacketRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('t_ms')) {
      context.handle(
        _tMsMeta,
        tMs.isAcceptableOrUnknown(data['t_ms']!, _tMsMeta),
      );
    } else if (isInserting) {
      context.missing(_tMsMeta);
    }
    if (data.containsKey('characteristic_id')) {
      context.handle(
        _characteristicIdMeta,
        characteristicId.isAcceptableOrUnknown(
          data['characteristic_id']!,
          _characteristicIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characteristicIdMeta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  RawPacketRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RawPacketRow(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      tMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}t_ms'],
      )!,
      characteristicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}characteristic_id'],
      )!,
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}bytes'],
      )!,
    );
  }

  @override
  $RawPacketsTable createAlias(String alias) {
    return $RawPacketsTable(attachedDatabase, alias);
  }
}

class RawPacketRow extends DataClass implements Insertable<RawPacketRow> {
  final int sessionId;
  final int tMs;
  final String characteristicId;
  final Uint8List bytes;
  const RawPacketRow({
    required this.sessionId,
    required this.tMs,
    required this.characteristicId,
    required this.bytes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<int>(sessionId);
    map['t_ms'] = Variable<int>(tMs);
    map['characteristic_id'] = Variable<String>(characteristicId);
    map['bytes'] = Variable<Uint8List>(bytes);
    return map;
  }

  RawPacketsCompanion toCompanion(bool nullToAbsent) {
    return RawPacketsCompanion(
      sessionId: Value(sessionId),
      tMs: Value(tMs),
      characteristicId: Value(characteristicId),
      bytes: Value(bytes),
    );
  }

  factory RawPacketRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RawPacketRow(
      sessionId: serializer.fromJson<int>(json['sessionId']),
      tMs: serializer.fromJson<int>(json['tMs']),
      characteristicId: serializer.fromJson<String>(json['characteristicId']),
      bytes: serializer.fromJson<Uint8List>(json['bytes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<int>(sessionId),
      'tMs': serializer.toJson<int>(tMs),
      'characteristicId': serializer.toJson<String>(characteristicId),
      'bytes': serializer.toJson<Uint8List>(bytes),
    };
  }

  RawPacketRow copyWith({
    int? sessionId,
    int? tMs,
    String? characteristicId,
    Uint8List? bytes,
  }) => RawPacketRow(
    sessionId: sessionId ?? this.sessionId,
    tMs: tMs ?? this.tMs,
    characteristicId: characteristicId ?? this.characteristicId,
    bytes: bytes ?? this.bytes,
  );
  RawPacketRow copyWithCompanion(RawPacketsCompanion data) {
    return RawPacketRow(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      tMs: data.tMs.present ? data.tMs.value : this.tMs,
      characteristicId: data.characteristicId.present
          ? data.characteristicId.value
          : this.characteristicId,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RawPacketRow(')
          ..write('sessionId: $sessionId, ')
          ..write('tMs: $tMs, ')
          ..write('characteristicId: $characteristicId, ')
          ..write('bytes: $bytes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    tMs,
    characteristicId,
    $driftBlobEquality.hash(bytes),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RawPacketRow &&
          other.sessionId == this.sessionId &&
          other.tMs == this.tMs &&
          other.characteristicId == this.characteristicId &&
          $driftBlobEquality.equals(other.bytes, this.bytes));
}

class RawPacketsCompanion extends UpdateCompanion<RawPacketRow> {
  final Value<int> sessionId;
  final Value<int> tMs;
  final Value<String> characteristicId;
  final Value<Uint8List> bytes;
  final Value<int> rowid;
  const RawPacketsCompanion({
    this.sessionId = const Value.absent(),
    this.tMs = const Value.absent(),
    this.characteristicId = const Value.absent(),
    this.bytes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RawPacketsCompanion.insert({
    required int sessionId,
    required int tMs,
    required String characteristicId,
    required Uint8List bytes,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       tMs = Value(tMs),
       characteristicId = Value(characteristicId),
       bytes = Value(bytes);
  static Insertable<RawPacketRow> custom({
    Expression<int>? sessionId,
    Expression<int>? tMs,
    Expression<String>? characteristicId,
    Expression<Uint8List>? bytes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (tMs != null) 't_ms': tMs,
      if (characteristicId != null) 'characteristic_id': characteristicId,
      if (bytes != null) 'bytes': bytes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RawPacketsCompanion copyWith({
    Value<int>? sessionId,
    Value<int>? tMs,
    Value<String>? characteristicId,
    Value<Uint8List>? bytes,
    Value<int>? rowid,
  }) {
    return RawPacketsCompanion(
      sessionId: sessionId ?? this.sessionId,
      tMs: tMs ?? this.tMs,
      characteristicId: characteristicId ?? this.characteristicId,
      bytes: bytes ?? this.bytes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (tMs.present) {
      map['t_ms'] = Variable<int>(tMs.value);
    }
    if (characteristicId.present) {
      map['characteristic_id'] = Variable<String>(characteristicId.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<Uint8List>(bytes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RawPacketsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('tMs: $tMs, ')
          ..write('characteristicId: $characteristicId, ')
          ..write('bytes: $bytes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $SamplesTable samples = $SamplesTable(this);
  late final $StrokesTable strokes = $StrokesTable(this);
  late final $RawPacketsTable rawPackets = $RawPacketsTable(this);
  late final Index samplesSessionTime = Index(
    'samples_session_time',
    'CREATE INDEX samples_session_time ON samples (session_id, t_ms)',
  );
  late final Index strokesSessionTime = Index(
    'strokes_session_time',
    'CREATE INDEX strokes_session_time ON strokes (session_id, t_ms)',
  );
  late final Index rawPacketsSessionTime = Index(
    'raw_packets_session_time',
    'CREATE INDEX raw_packets_session_time ON raw_packets (session_id, t_ms)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sessions,
    samples,
    strokes,
    rawPackets,
    samplesSessionTime,
    strokesSessionTime,
    rawPacketsSessionTime,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('samples', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('strokes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('raw_packets', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  required DateTime startedAt,
  Value<DateTime?> endedAt,
  required SessionStatus status,
  required ErgSourceKind source,
  Value<String?> deviceName,
  Value<int> durationMs,
  Value<int> distanceDm,
  Value<int?> averagePaceCs,
  Value<int?> averageWatts,
  Value<double?> averageStrokeRate,
  Value<int> strokeCount,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  Value<SessionStatus> status,
  Value<ErgSourceKind> source,
  Value<String?> deviceName,
  Value<int> durationMs,
  Value<int> distanceDm,
  Value<int?> averagePaceCs,
  Value<int?> averageWatts,
  Value<double?> averageStrokeRate,
  Value<int> strokeCount,
});

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, SessionRow> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SamplesTable, List<SampleRow>> _samplesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.samples,
    aliasName: 'sessions__id__samples__session_id',
  );

  $$SamplesTableProcessedTableManager get samplesRefs {
    final manager = $$SamplesTableTableManager(
      $_db,
      $_db.samples,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_samplesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StrokesTable, List<StrokeRow>> _strokesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.strokes,
    aliasName: 'sessions__id__strokes__session_id',
  );

  $$StrokesTableProcessedTableManager get strokesRefs {
    final manager = $$StrokesTableTableManager(
      $_db,
      $_db.strokes,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_strokesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RawPacketsTable, List<RawPacketRow>>
  _rawPacketsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.rawPackets,
    aliasName: 'sessions__id__raw_packets__session_id',
  );

  $$RawPacketsTableProcessedTableManager get rawPacketsRefs {
    final manager = $$RawPacketsTableTableManager(
      $_db,
      $_db.rawPackets,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_rawPacketsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SessionStatus, SessionStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<ErgSourceKind, ErgSourceKind, String>
  get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get distanceDm => $composableBuilder(
    column: $table.distanceDm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get averagePaceCs => $composableBuilder(
    column: $table.averagePaceCs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get averageWatts => $composableBuilder(
    column: $table.averageWatts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averageStrokeRate => $composableBuilder(
    column: $table.averageStrokeRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get strokeCount => $composableBuilder(
    column: $table.strokeCount,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> samplesRefs(
    Expression<bool> Function($$SamplesTableFilterComposer f) f,
  ) {
    final $$SamplesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.samples,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SamplesTableFilterComposer(
            $db: $db,
            $table: $db.samples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> strokesRefs(
    Expression<bool> Function($$StrokesTableFilterComposer f) f,
  ) {
    final $$StrokesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.strokes,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StrokesTableFilterComposer(
            $db: $db,
            $table: $db.strokes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> rawPacketsRefs(
    Expression<bool> Function($$RawPacketsTableFilterComposer f) f,
  ) {
    final $$RawPacketsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rawPackets,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawPacketsTableFilterComposer(
            $db: $db,
            $table: $db.rawPackets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get distanceDm => $composableBuilder(
    column: $table.distanceDm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get averagePaceCs => $composableBuilder(
    column: $table.averagePaceCs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get averageWatts => $composableBuilder(
    column: $table.averageWatts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averageStrokeRate => $composableBuilder(
    column: $table.averageStrokeRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get strokeCount => $composableBuilder(
    column: $table.strokeCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SessionStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ErgSourceKind, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get distanceDm => $composableBuilder(
    column: $table.distanceDm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get averagePaceCs => $composableBuilder(
    column: $table.averagePaceCs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get averageWatts => $composableBuilder(
    column: $table.averageWatts,
    builder: (column) => column,
  );

  GeneratedColumn<double> get averageStrokeRate => $composableBuilder(
    column: $table.averageStrokeRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get strokeCount => $composableBuilder(
    column: $table.strokeCount,
    builder: (column) => column,
  );

  Expression<T> samplesRefs<T extends Object>(
    Expression<T> Function($$SamplesTableAnnotationComposer a) f,
  ) {
    final $$SamplesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.samples,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SamplesTableAnnotationComposer(
            $db: $db,
            $table: $db.samples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> strokesRefs<T extends Object>(
    Expression<T> Function($$StrokesTableAnnotationComposer a) f,
  ) {
    final $$StrokesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.strokes,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StrokesTableAnnotationComposer(
            $db: $db,
            $table: $db.strokes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> rawPacketsRefs<T extends Object>(
    Expression<T> Function($$RawPacketsTableAnnotationComposer a) f,
  ) {
    final $$RawPacketsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rawPackets,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawPacketsTableAnnotationComposer(
            $db: $db,
            $table: $db.rawPackets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          SessionRow,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (SessionRow, $$SessionsTableReferences),
          SessionRow,
          PrefetchHooks Function({
            bool samplesRefs,
            bool strokesRefs,
            bool rawPacketsRefs,
          })
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<SessionStatus> status = const Value.absent(),
                Value<ErgSourceKind> source = const Value.absent(),
                Value<String?> deviceName = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int> distanceDm = const Value.absent(),
                Value<int?> averagePaceCs = const Value.absent(),
                Value<int?> averageWatts = const Value.absent(),
                Value<double?> averageStrokeRate = const Value.absent(),
                Value<int> strokeCount = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                status: status,
                source: source,
                deviceName: deviceName,
                durationMs: durationMs,
                distanceDm: distanceDm,
                averagePaceCs: averagePaceCs,
                averageWatts: averageWatts,
                averageStrokeRate: averageStrokeRate,
                strokeCount: strokeCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                required SessionStatus status,
                required ErgSourceKind source,
                Value<String?> deviceName = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int> distanceDm = const Value.absent(),
                Value<int?> averagePaceCs = const Value.absent(),
                Value<int?> averageWatts = const Value.absent(),
                Value<double?> averageStrokeRate = const Value.absent(),
                Value<int> strokeCount = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                status: status,
                source: source,
                deviceName: deviceName,
                durationMs: durationMs,
                distanceDm: distanceDm,
                averagePaceCs: averagePaceCs,
                averageWatts: averageWatts,
                averageStrokeRate: averageStrokeRate,
                strokeCount: strokeCount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionsTable, SessionRow>(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                samplesRefs = false,
                strokesRefs = false,
                rawPacketsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (samplesRefs) db.samples,
                    if (strokesRefs) db.strokes,
                    if (rawPacketsRefs) db.rawPackets,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (samplesRefs)
                        await $_getPrefetchedData<
                          SessionRow,
                          $SessionsTable,
                          SampleRow
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._samplesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).samplesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (strokesRefs)
                        await $_getPrefetchedData<
                          SessionRow,
                          $SessionsTable,
                          StrokeRow
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._strokesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).strokesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (rawPacketsRefs)
                        await $_getPrefetchedData<
                          SessionRow,
                          $SessionsTable,
                          RawPacketRow
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._rawPacketsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).rawPacketsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      SessionRow,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (SessionRow, $$SessionsTableReferences),
      SessionRow,
      PrefetchHooks Function({
        bool samplesRefs,
        bool strokesRefs,
        bool rawPacketsRefs,
      })
    >;
typedef $$SamplesTableCreateCompanionBuilder = SamplesCompanion Function({
  required int sessionId,
  required int tMs,
  required int distanceDm,
  Value<int?> paceCs,
  Value<int?> watts,
  Value<int?> strokeRate,
  Value<int?> heartRate,
  Value<int?> calories,
  Value<int> rowid,
});
typedef $$SamplesTableUpdateCompanionBuilder = SamplesCompanion Function({
  Value<int> sessionId,
  Value<int> tMs,
  Value<int> distanceDm,
  Value<int?> paceCs,
  Value<int?> watts,
  Value<int?> strokeRate,
  Value<int?> heartRate,
  Value<int?> calories,
  Value<int> rowid,
});

final class $$SamplesTableReferences
    extends BaseReferences<_$AppDatabase, $SamplesTable, SampleRow> {
  $$SamplesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('samples__session_id__sessions__id');

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SamplesTableFilterComposer
    extends Composer<_$AppDatabase, $SamplesTable> {
  $$SamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get tMs => $composableBuilder(
    column: $table.tMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get distanceDm => $composableBuilder(
    column: $table.distanceDm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paceCs => $composableBuilder(
    column: $table.paceCs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get watts => $composableBuilder(
    column: $table.watts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get strokeRate => $composableBuilder(
    column: $table.strokeRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get heartRate => $composableBuilder(
    column: $table.heartRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $SamplesTable> {
  $$SamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get tMs => $composableBuilder(
    column: $table.tMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get distanceDm => $composableBuilder(
    column: $table.distanceDm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paceCs => $composableBuilder(
    column: $table.paceCs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get watts => $composableBuilder(
    column: $table.watts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get strokeRate => $composableBuilder(
    column: $table.strokeRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get heartRate => $composableBuilder(
    column: $table.heartRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SamplesTable> {
  $$SamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get tMs =>
      $composableBuilder(column: $table.tMs, builder: (column) => column);

  GeneratedColumn<int> get distanceDm => $composableBuilder(
    column: $table.distanceDm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paceCs =>
      $composableBuilder(column: $table.paceCs, builder: (column) => column);

  GeneratedColumn<int> get watts =>
      $composableBuilder(column: $table.watts, builder: (column) => column);

  GeneratedColumn<int> get strokeRate => $composableBuilder(
    column: $table.strokeRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get heartRate =>
      $composableBuilder(column: $table.heartRate, builder: (column) => column);

  GeneratedColumn<int> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SamplesTable,
          SampleRow,
          $$SamplesTableFilterComposer,
          $$SamplesTableOrderingComposer,
          $$SamplesTableAnnotationComposer,
          $$SamplesTableCreateCompanionBuilder,
          $$SamplesTableUpdateCompanionBuilder,
          (SampleRow, $$SamplesTableReferences),
          SampleRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$SamplesTableTableManager(_$AppDatabase db, $SamplesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sessionId = const Value.absent(),
                Value<int> tMs = const Value.absent(),
                Value<int> distanceDm = const Value.absent(),
                Value<int?> paceCs = const Value.absent(),
                Value<int?> watts = const Value.absent(),
                Value<int?> strokeRate = const Value.absent(),
                Value<int?> heartRate = const Value.absent(),
                Value<int?> calories = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SamplesCompanion(
                sessionId: sessionId,
                tMs: tMs,
                distanceDm: distanceDm,
                paceCs: paceCs,
                watts: watts,
                strokeRate: strokeRate,
                heartRate: heartRate,
                calories: calories,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sessionId,
                required int tMs,
                required int distanceDm,
                Value<int?> paceCs = const Value.absent(),
                Value<int?> watts = const Value.absent(),
                Value<int?> strokeRate = const Value.absent(),
                Value<int?> heartRate = const Value.absent(),
                Value<int?> calories = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SamplesCompanion.insert(
                sessionId: sessionId,
                tMs: tMs,
                distanceDm: distanceDm,
                paceCs: paceCs,
                watts: watts,
                strokeRate: strokeRate,
                heartRate: heartRate,
                calories: calories,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SamplesTable, SampleRow>(table),
                  $$SamplesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
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
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$SamplesTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$SamplesTableReferences
                            ._sessionIdTable(db)
                            .id,
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

typedef $$SamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SamplesTable,
      SampleRow,
      $$SamplesTableFilterComposer,
      $$SamplesTableOrderingComposer,
      $$SamplesTableAnnotationComposer,
      $$SamplesTableCreateCompanionBuilder,
      $$SamplesTableUpdateCompanionBuilder,
      (SampleRow, $$SamplesTableReferences),
      SampleRow,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$StrokesTableCreateCompanionBuilder = StrokesCompanion Function({
  required int sessionId,
  required int tMs,
  required int distanceDm,
  required int strokeNumber,
  required double driveLengthMeters,
  required int driveTimeMs,
  required int recoveryTimeMs,
  required double peakForceNewtons,
  required double averageForceNewtons,
  Value<int?> watts,
  Value<int> rowid,
});
typedef $$StrokesTableUpdateCompanionBuilder = StrokesCompanion Function({
  Value<int> sessionId,
  Value<int> tMs,
  Value<int> distanceDm,
  Value<int> strokeNumber,
  Value<double> driveLengthMeters,
  Value<int> driveTimeMs,
  Value<int> recoveryTimeMs,
  Value<double> peakForceNewtons,
  Value<double> averageForceNewtons,
  Value<int?> watts,
  Value<int> rowid,
});

final class $$StrokesTableReferences
    extends BaseReferences<_$AppDatabase, $StrokesTable, StrokeRow> {
  $$StrokesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('strokes__session_id__sessions__id');

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StrokesTableFilterComposer
    extends Composer<_$AppDatabase, $StrokesTable> {
  $$StrokesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get tMs => $composableBuilder(
    column: $table.tMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get distanceDm => $composableBuilder(
    column: $table.distanceDm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get strokeNumber => $composableBuilder(
    column: $table.strokeNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get driveLengthMeters => $composableBuilder(
    column: $table.driveLengthMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get driveTimeMs => $composableBuilder(
    column: $table.driveTimeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recoveryTimeMs => $composableBuilder(
    column: $table.recoveryTimeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get peakForceNewtons => $composableBuilder(
    column: $table.peakForceNewtons,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averageForceNewtons => $composableBuilder(
    column: $table.averageForceNewtons,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get watts => $composableBuilder(
    column: $table.watts,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StrokesTableOrderingComposer
    extends Composer<_$AppDatabase, $StrokesTable> {
  $$StrokesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get tMs => $composableBuilder(
    column: $table.tMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get distanceDm => $composableBuilder(
    column: $table.distanceDm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get strokeNumber => $composableBuilder(
    column: $table.strokeNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get driveLengthMeters => $composableBuilder(
    column: $table.driveLengthMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get driveTimeMs => $composableBuilder(
    column: $table.driveTimeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recoveryTimeMs => $composableBuilder(
    column: $table.recoveryTimeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get peakForceNewtons => $composableBuilder(
    column: $table.peakForceNewtons,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averageForceNewtons => $composableBuilder(
    column: $table.averageForceNewtons,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get watts => $composableBuilder(
    column: $table.watts,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StrokesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StrokesTable> {
  $$StrokesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get tMs =>
      $composableBuilder(column: $table.tMs, builder: (column) => column);

  GeneratedColumn<int> get distanceDm => $composableBuilder(
    column: $table.distanceDm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get strokeNumber => $composableBuilder(
    column: $table.strokeNumber,
    builder: (column) => column,
  );

  GeneratedColumn<double> get driveLengthMeters => $composableBuilder(
    column: $table.driveLengthMeters,
    builder: (column) => column,
  );

  GeneratedColumn<int> get driveTimeMs => $composableBuilder(
    column: $table.driveTimeMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recoveryTimeMs => $composableBuilder(
    column: $table.recoveryTimeMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get peakForceNewtons => $composableBuilder(
    column: $table.peakForceNewtons,
    builder: (column) => column,
  );

  GeneratedColumn<double> get averageForceNewtons => $composableBuilder(
    column: $table.averageForceNewtons,
    builder: (column) => column,
  );

  GeneratedColumn<int> get watts =>
      $composableBuilder(column: $table.watts, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StrokesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StrokesTable,
          StrokeRow,
          $$StrokesTableFilterComposer,
          $$StrokesTableOrderingComposer,
          $$StrokesTableAnnotationComposer,
          $$StrokesTableCreateCompanionBuilder,
          $$StrokesTableUpdateCompanionBuilder,
          (StrokeRow, $$StrokesTableReferences),
          StrokeRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$StrokesTableTableManager(_$AppDatabase db, $StrokesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StrokesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StrokesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StrokesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sessionId = const Value.absent(),
                Value<int> tMs = const Value.absent(),
                Value<int> distanceDm = const Value.absent(),
                Value<int> strokeNumber = const Value.absent(),
                Value<double> driveLengthMeters = const Value.absent(),
                Value<int> driveTimeMs = const Value.absent(),
                Value<int> recoveryTimeMs = const Value.absent(),
                Value<double> peakForceNewtons = const Value.absent(),
                Value<double> averageForceNewtons = const Value.absent(),
                Value<int?> watts = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StrokesCompanion(
                sessionId: sessionId,
                tMs: tMs,
                distanceDm: distanceDm,
                strokeNumber: strokeNumber,
                driveLengthMeters: driveLengthMeters,
                driveTimeMs: driveTimeMs,
                recoveryTimeMs: recoveryTimeMs,
                peakForceNewtons: peakForceNewtons,
                averageForceNewtons: averageForceNewtons,
                watts: watts,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sessionId,
                required int tMs,
                required int distanceDm,
                required int strokeNumber,
                required double driveLengthMeters,
                required int driveTimeMs,
                required int recoveryTimeMs,
                required double peakForceNewtons,
                required double averageForceNewtons,
                Value<int?> watts = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StrokesCompanion.insert(
                sessionId: sessionId,
                tMs: tMs,
                distanceDm: distanceDm,
                strokeNumber: strokeNumber,
                driveLengthMeters: driveLengthMeters,
                driveTimeMs: driveTimeMs,
                recoveryTimeMs: recoveryTimeMs,
                peakForceNewtons: peakForceNewtons,
                averageForceNewtons: averageForceNewtons,
                watts: watts,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StrokesTable, StrokeRow>(table),
                  $$StrokesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
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
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$StrokesTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$StrokesTableReferences
                            ._sessionIdTable(db)
                            .id,
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

typedef $$StrokesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StrokesTable,
      StrokeRow,
      $$StrokesTableFilterComposer,
      $$StrokesTableOrderingComposer,
      $$StrokesTableAnnotationComposer,
      $$StrokesTableCreateCompanionBuilder,
      $$StrokesTableUpdateCompanionBuilder,
      (StrokeRow, $$StrokesTableReferences),
      StrokeRow,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$RawPacketsTableCreateCompanionBuilder = RawPacketsCompanion Function({
  required int sessionId,
  required int tMs,
  required String characteristicId,
  required Uint8List bytes,
  Value<int> rowid,
});
typedef $$RawPacketsTableUpdateCompanionBuilder = RawPacketsCompanion Function({
  Value<int> sessionId,
  Value<int> tMs,
  Value<String> characteristicId,
  Value<Uint8List> bytes,
  Value<int> rowid,
});

final class $$RawPacketsTableReferences
    extends BaseReferences<_$AppDatabase, $RawPacketsTable, RawPacketRow> {
  $$RawPacketsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('raw_packets__session_id__sessions__id');

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RawPacketsTableFilterComposer
    extends Composer<_$AppDatabase, $RawPacketsTable> {
  $$RawPacketsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get tMs => $composableBuilder(
    column: $table.tMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get characteristicId => $composableBuilder(
    column: $table.characteristicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RawPacketsTableOrderingComposer
    extends Composer<_$AppDatabase, $RawPacketsTable> {
  $$RawPacketsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get tMs => $composableBuilder(
    column: $table.tMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get characteristicId => $composableBuilder(
    column: $table.characteristicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RawPacketsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RawPacketsTable> {
  $$RawPacketsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get tMs =>
      $composableBuilder(column: $table.tMs, builder: (column) => column);

  GeneratedColumn<String> get characteristicId => $composableBuilder(
    column: $table.characteristicId,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RawPacketsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RawPacketsTable,
          RawPacketRow,
          $$RawPacketsTableFilterComposer,
          $$RawPacketsTableOrderingComposer,
          $$RawPacketsTableAnnotationComposer,
          $$RawPacketsTableCreateCompanionBuilder,
          $$RawPacketsTableUpdateCompanionBuilder,
          (RawPacketRow, $$RawPacketsTableReferences),
          RawPacketRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$RawPacketsTableTableManager(_$AppDatabase db, $RawPacketsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RawPacketsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RawPacketsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RawPacketsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sessionId = const Value.absent(),
                Value<int> tMs = const Value.absent(),
                Value<String> characteristicId = const Value.absent(),
                Value<Uint8List> bytes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RawPacketsCompanion(
                sessionId: sessionId,
                tMs: tMs,
                characteristicId: characteristicId,
                bytes: bytes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sessionId,
                required int tMs,
                required String characteristicId,
                required Uint8List bytes,
                Value<int> rowid = const Value.absent(),
              }) => RawPacketsCompanion.insert(
                sessionId: sessionId,
                tMs: tMs,
                characteristicId: characteristicId,
                bytes: bytes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RawPacketsTable, RawPacketRow>(table),
                  $$RawPacketsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
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
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$RawPacketsTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$RawPacketsTableReferences
                            ._sessionIdTable(db)
                            .id,
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

typedef $$RawPacketsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RawPacketsTable,
      RawPacketRow,
      $$RawPacketsTableFilterComposer,
      $$RawPacketsTableOrderingComposer,
      $$RawPacketsTableAnnotationComposer,
      $$RawPacketsTableCreateCompanionBuilder,
      $$RawPacketsTableUpdateCompanionBuilder,
      (RawPacketRow, $$RawPacketsTableReferences),
      RawPacketRow,
      PrefetchHooks Function({bool sessionId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$SamplesTableTableManager get samples =>
      $$SamplesTableTableManager(_db, _db.samples);
  $$StrokesTableTableManager get strokes =>
      $$StrokesTableTableManager(_db, _db.strokes);
  $$RawPacketsTableTableManager get rawPackets =>
      $$RawPacketsTableTableManager(_db, _db.rawPackets);
}
