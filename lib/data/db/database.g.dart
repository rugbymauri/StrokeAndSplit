// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TemplatesTable extends Templates
    with TableInfo<$TemplatesTable, TemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplatesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
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
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TemplatesTable createAlias(String alias) {
    return $TemplatesTable(attachedDatabase, alias);
  }
}

class TemplateRow extends DataClass implements Insertable<TemplateRow> {
  final int id;
  final String name;
  final DateTime createdAt;
  const TemplateRow({
    required this.id,
    required this.name,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TemplatesCompanion toCompanion(bool nullToAbsent) {
    return TemplatesCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory TemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TemplateRow copyWith({int? id, String? name, DateTime? createdAt}) =>
      TemplateRow(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
      );
  TemplateRow copyWithCompanion(TemplatesCompanion data) {
    return TemplateRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class TemplatesCompanion extends UpdateCompanion<TemplateRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  const TemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TemplatesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required DateTime createdAt,
  }) : name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<TemplateRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TemplatesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
  }) {
    return TemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CoursesTable extends Courses with TableInfo<$CoursesTable, CourseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoursesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CourseAxis, String> axis =
      GeneratedColumn<String>(
        'axis',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CourseAxis>($CoursesTable.$converteraxis);
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
  List<GeneratedColumn> get $columns => [id, name, axis, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'courses';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CourseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      axis: $CoursesTable.$converteraxis.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}axis'],
        )!,
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $CoursesTable createAlias(String alias) {
    return $CoursesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CourseAxis, String, String> $converteraxis =
      const EnumNameConverter<CourseAxis>(CourseAxis.values);
}

class CourseRow extends DataClass implements Insertable<CourseRow> {
  final int id;
  final String name;
  final CourseAxis axis;

  /// Courses are only marked as deleted, as sessions keep pointing to them.
  final DateTime? deletedAt;
  const CourseRow({
    required this.id,
    required this.name,
    required this.axis,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['axis'] = Variable<String>($CoursesTable.$converteraxis.toSql(axis));
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  CoursesCompanion toCompanion(bool nullToAbsent) {
    return CoursesCompanion(
      id: Value(id),
      name: Value(name),
      axis: Value(axis),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory CourseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      axis: $CoursesTable.$converteraxis.fromJson(
        serializer.fromJson<String>(json['axis']),
      ),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'axis': serializer.toJson<String>(
        $CoursesTable.$converteraxis.toJson(axis),
      ),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  CourseRow copyWith({
    int? id,
    String? name,
    CourseAxis? axis,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => CourseRow(
    id: id ?? this.id,
    name: name ?? this.name,
    axis: axis ?? this.axis,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  CourseRow copyWithCompanion(CoursesCompanion data) {
    return CourseRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      axis: data.axis.present ? data.axis.value : this.axis,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('axis: $axis, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, axis, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.axis == this.axis &&
          other.deletedAt == this.deletedAt);
}

class CoursesCompanion extends UpdateCompanion<CourseRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<CourseAxis> axis;
  final Value<DateTime?> deletedAt;
  const CoursesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.axis = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  CoursesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required CourseAxis axis,
    this.deletedAt = const Value.absent(),
  }) : name = Value(name),
       axis = Value(axis);
  static Insertable<CourseRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? axis,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (axis != null) 'axis': axis,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  CoursesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<CourseAxis>? axis,
    Value<DateTime?>? deletedAt,
  }) {
    return CoursesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      axis: axis ?? this.axis,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (axis.present) {
      map['axis'] = Variable<String>(
        $CoursesTable.$converteraxis.toSql(axis.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoursesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('axis: $axis, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $CourseVersionsTable extends CourseVersions
    with TableInfo<$CourseVersionsTable, CourseVersionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CourseVersionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<int> courseId = GeneratedColumn<int>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES courses (id)',
    ),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lengthMeta = const VerificationMeta('length');
  @override
  late final GeneratedColumn<int> length = GeneratedColumn<int>(
    'length',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    id,
    courseId,
    version,
    length,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseVersionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('length')) {
      context.handle(
        _lengthMeta,
        length.isAcceptableOrUnknown(data['length']!, _lengthMeta),
      );
    } else if (isInserting) {
      context.missing(_lengthMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CourseVersionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseVersionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}course_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      length: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}length'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CourseVersionsTable createAlias(String alias) {
    return $CourseVersionsTable(attachedDatabase, alias);
  }
}

class CourseVersionRow extends DataClass
    implements Insertable<CourseVersionRow> {
  final int id;
  final int courseId;
  final int version;

  /// In metres or seconds, depending on the axis of the course.
  final int length;
  final DateTime createdAt;
  const CourseVersionRow({
    required this.id,
    required this.courseId,
    required this.version,
    required this.length,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['course_id'] = Variable<int>(courseId);
    map['version'] = Variable<int>(version);
    map['length'] = Variable<int>(length);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CourseVersionsCompanion toCompanion(bool nullToAbsent) {
    return CourseVersionsCompanion(
      id: Value(id),
      courseId: Value(courseId),
      version: Value(version),
      length: Value(length),
      createdAt: Value(createdAt),
    );
  }

  factory CourseVersionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseVersionRow(
      id: serializer.fromJson<int>(json['id']),
      courseId: serializer.fromJson<int>(json['courseId']),
      version: serializer.fromJson<int>(json['version']),
      length: serializer.fromJson<int>(json['length']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'courseId': serializer.toJson<int>(courseId),
      'version': serializer.toJson<int>(version),
      'length': serializer.toJson<int>(length),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CourseVersionRow copyWith({
    int? id,
    int? courseId,
    int? version,
    int? length,
    DateTime? createdAt,
  }) => CourseVersionRow(
    id: id ?? this.id,
    courseId: courseId ?? this.courseId,
    version: version ?? this.version,
    length: length ?? this.length,
    createdAt: createdAt ?? this.createdAt,
  );
  CourseVersionRow copyWithCompanion(CourseVersionsCompanion data) {
    return CourseVersionRow(
      id: data.id.present ? data.id.value : this.id,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      version: data.version.present ? data.version.value : this.version,
      length: data.length.present ? data.length.value : this.length,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseVersionRow(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('version: $version, ')
          ..write('length: $length, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, courseId, version, length, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseVersionRow &&
          other.id == this.id &&
          other.courseId == this.courseId &&
          other.version == this.version &&
          other.length == this.length &&
          other.createdAt == this.createdAt);
}

class CourseVersionsCompanion extends UpdateCompanion<CourseVersionRow> {
  final Value<int> id;
  final Value<int> courseId;
  final Value<int> version;
  final Value<int> length;
  final Value<DateTime> createdAt;
  const CourseVersionsCompanion({
    this.id = const Value.absent(),
    this.courseId = const Value.absent(),
    this.version = const Value.absent(),
    this.length = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CourseVersionsCompanion.insert({
    this.id = const Value.absent(),
    required int courseId,
    required int version,
    required int length,
    required DateTime createdAt,
  }) : courseId = Value(courseId),
       version = Value(version),
       length = Value(length),
       createdAt = Value(createdAt);
  static Insertable<CourseVersionRow> custom({
    Expression<int>? id,
    Expression<int>? courseId,
    Expression<int>? version,
    Expression<int>? length,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (courseId != null) 'course_id': courseId,
      if (version != null) 'version': version,
      if (length != null) 'length': length,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CourseVersionsCompanion copyWith({
    Value<int>? id,
    Value<int>? courseId,
    Value<int>? version,
    Value<int>? length,
    Value<DateTime>? createdAt,
  }) {
    return CourseVersionsCompanion(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      version: version ?? this.version,
      length: length ?? this.length,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<int>(courseId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (length.present) {
      map['length'] = Variable<int>(length.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CourseVersionsCompanion(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('version: $version, ')
          ..write('length: $length, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

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
  @override
  late final GeneratedColumnWithTypeConverter<ErgProtocol, String> protocol =
      GeneratedColumn<String>(
        'protocol',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pm5'),
      ).withConverter<ErgProtocol>($SessionsTable.$converterprotocol);
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
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<int> templateId = GeneratedColumn<int>(
    'template_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES templates (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _templateNameMeta = const VerificationMeta(
    'templateName',
  );
  @override
  late final GeneratedColumn<String> templateName = GeneratedColumn<String>(
    'template_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _courseVersionIdMeta = const VerificationMeta(
    'courseVersionId',
  );
  @override
  late final GeneratedColumn<int> courseVersionId = GeneratedColumn<int>(
    'course_version_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES course_versions (id)',
    ),
  );
  static const VerificationMeta _plannedLapsMeta = const VerificationMeta(
    'plannedLaps',
  );
  @override
  late final GeneratedColumn<int> plannedLaps = GeneratedColumn<int>(
    'planned_laps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _importedMeta = const VerificationMeta(
    'imported',
  );
  @override
  late final GeneratedColumn<bool> imported = GeneratedColumn<bool>(
    'imported',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("imported" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _averageHeartRateMeta = const VerificationMeta(
    'averageHeartRate',
  );
  @override
  late final GeneratedColumn<int> averageHeartRate = GeneratedColumn<int>(
    'average_heart_rate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxHeartRateMeta = const VerificationMeta(
    'maxHeartRate',
  );
  @override
  late final GeneratedColumn<int> maxHeartRate = GeneratedColumn<int>(
    'max_heart_rate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rmssdMsMeta = const VerificationMeta(
    'rmssdMs',
  );
  @override
  late final GeneratedColumn<int> rmssdMs = GeneratedColumn<int>(
    'rmssd_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pauseCountMeta = const VerificationMeta(
    'pauseCount',
  );
  @override
  late final GeneratedColumn<int> pauseCount = GeneratedColumn<int>(
    'pause_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pausedMsMeta = const VerificationMeta(
    'pausedMs',
  );
  @override
  late final GeneratedColumn<int> pausedMs = GeneratedColumn<int>(
    'paused_ms',
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
    protocol,
    durationMs,
    distanceDm,
    averagePaceCs,
    averageWatts,
    averageStrokeRate,
    strokeCount,
    templateId,
    templateName,
    courseVersionId,
    plannedLaps,
    imported,
    averageHeartRate,
    maxHeartRate,
    rmssdMs,
    pauseCount,
    pausedMs,
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
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    }
    if (data.containsKey('template_name')) {
      context.handle(
        _templateNameMeta,
        templateName.isAcceptableOrUnknown(
          data['template_name']!,
          _templateNameMeta,
        ),
      );
    }
    if (data.containsKey('course_version_id')) {
      context.handle(
        _courseVersionIdMeta,
        courseVersionId.isAcceptableOrUnknown(
          data['course_version_id']!,
          _courseVersionIdMeta,
        ),
      );
    }
    if (data.containsKey('planned_laps')) {
      context.handle(
        _plannedLapsMeta,
        plannedLaps.isAcceptableOrUnknown(
          data['planned_laps']!,
          _plannedLapsMeta,
        ),
      );
    }
    if (data.containsKey('imported')) {
      context.handle(
        _importedMeta,
        imported.isAcceptableOrUnknown(data['imported']!, _importedMeta),
      );
    }
    if (data.containsKey('average_heart_rate')) {
      context.handle(
        _averageHeartRateMeta,
        averageHeartRate.isAcceptableOrUnknown(
          data['average_heart_rate']!,
          _averageHeartRateMeta,
        ),
      );
    }
    if (data.containsKey('max_heart_rate')) {
      context.handle(
        _maxHeartRateMeta,
        maxHeartRate.isAcceptableOrUnknown(
          data['max_heart_rate']!,
          _maxHeartRateMeta,
        ),
      );
    }
    if (data.containsKey('rmssd_ms')) {
      context.handle(
        _rmssdMsMeta,
        rmssdMs.isAcceptableOrUnknown(data['rmssd_ms']!, _rmssdMsMeta),
      );
    }
    if (data.containsKey('pause_count')) {
      context.handle(
        _pauseCountMeta,
        pauseCount.isAcceptableOrUnknown(data['pause_count']!, _pauseCountMeta),
      );
    }
    if (data.containsKey('paused_ms')) {
      context.handle(
        _pausedMsMeta,
        pausedMs.isAcceptableOrUnknown(data['paused_ms']!, _pausedMsMeta),
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
      protocol: $SessionsTable.$converterprotocol.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}protocol'],
        )!,
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
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_id'],
      ),
      templateName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_name'],
      ),
      courseVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}course_version_id'],
      ),
      plannedLaps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_laps'],
      ),
      imported: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}imported'],
      )!,
      averageHeartRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}average_heart_rate'],
      ),
      maxHeartRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_heart_rate'],
      ),
      rmssdMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rmssd_ms'],
      ),
      pauseCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pause_count'],
      )!,
      pausedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paused_ms'],
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
  static JsonTypeConverter2<ErgProtocol, String, String> $converterprotocol =
      const EnumNameConverter<ErgProtocol>(ErgProtocol.values);
}

class SessionRow extends DataClass implements Insertable<SessionRow> {
  final int id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final SessionStatus status;
  final ErgSourceKind source;
  final String? deviceName;

  /// Protocol of the raw packets; sessions before schema 4 are PM5 sessions.
  final ErgProtocol protocol;
  final int durationMs;
  final int distanceDm;
  final int? averagePaceCs;
  final int? averageWatts;
  final double? averageStrokeRate;
  final int strokeCount;
  final int? templateId;

  /// The template name at the time, kept when the template is deleted.
  final String? templateName;
  final int? courseVersionId;

  /// Null for an open number of laps.
  final int? plannedLaps;

  /// Set by the import; imported sessions count in no ranking (Change
  /// statistics, Design D3). Sessions before schema 5 count as recorded here.
  final bool imported;
  final int? averageHeartRate;
  final int? maxHeartRate;
  final int? rmssdMs;
  final int pauseCount;
  final int pausedMs;
  const SessionRow({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.status,
    required this.source,
    this.deviceName,
    required this.protocol,
    required this.durationMs,
    required this.distanceDm,
    this.averagePaceCs,
    this.averageWatts,
    this.averageStrokeRate,
    required this.strokeCount,
    this.templateId,
    this.templateName,
    this.courseVersionId,
    this.plannedLaps,
    required this.imported,
    this.averageHeartRate,
    this.maxHeartRate,
    this.rmssdMs,
    required this.pauseCount,
    required this.pausedMs,
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
    {
      map['protocol'] = Variable<String>(
        $SessionsTable.$converterprotocol.toSql(protocol),
      );
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
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<int>(templateId);
    }
    if (!nullToAbsent || templateName != null) {
      map['template_name'] = Variable<String>(templateName);
    }
    if (!nullToAbsent || courseVersionId != null) {
      map['course_version_id'] = Variable<int>(courseVersionId);
    }
    if (!nullToAbsent || plannedLaps != null) {
      map['planned_laps'] = Variable<int>(plannedLaps);
    }
    map['imported'] = Variable<bool>(imported);
    if (!nullToAbsent || averageHeartRate != null) {
      map['average_heart_rate'] = Variable<int>(averageHeartRate);
    }
    if (!nullToAbsent || maxHeartRate != null) {
      map['max_heart_rate'] = Variable<int>(maxHeartRate);
    }
    if (!nullToAbsent || rmssdMs != null) {
      map['rmssd_ms'] = Variable<int>(rmssdMs);
    }
    map['pause_count'] = Variable<int>(pauseCount);
    map['paused_ms'] = Variable<int>(pausedMs);
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
      protocol: Value(protocol),
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
      templateId: templateId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateId),
      templateName: templateName == null && nullToAbsent
          ? const Value.absent()
          : Value(templateName),
      courseVersionId: courseVersionId == null && nullToAbsent
          ? const Value.absent()
          : Value(courseVersionId),
      plannedLaps: plannedLaps == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedLaps),
      imported: Value(imported),
      averageHeartRate: averageHeartRate == null && nullToAbsent
          ? const Value.absent()
          : Value(averageHeartRate),
      maxHeartRate: maxHeartRate == null && nullToAbsent
          ? const Value.absent()
          : Value(maxHeartRate),
      rmssdMs: rmssdMs == null && nullToAbsent
          ? const Value.absent()
          : Value(rmssdMs),
      pauseCount: Value(pauseCount),
      pausedMs: Value(pausedMs),
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
      protocol: $SessionsTable.$converterprotocol.fromJson(
        serializer.fromJson<String>(json['protocol']),
      ),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      distanceDm: serializer.fromJson<int>(json['distanceDm']),
      averagePaceCs: serializer.fromJson<int?>(json['averagePaceCs']),
      averageWatts: serializer.fromJson<int?>(json['averageWatts']),
      averageStrokeRate: serializer.fromJson<double?>(
        json['averageStrokeRate'],
      ),
      strokeCount: serializer.fromJson<int>(json['strokeCount']),
      templateId: serializer.fromJson<int?>(json['templateId']),
      templateName: serializer.fromJson<String?>(json['templateName']),
      courseVersionId: serializer.fromJson<int?>(json['courseVersionId']),
      plannedLaps: serializer.fromJson<int?>(json['plannedLaps']),
      imported: serializer.fromJson<bool>(json['imported']),
      averageHeartRate: serializer.fromJson<int?>(json['averageHeartRate']),
      maxHeartRate: serializer.fromJson<int?>(json['maxHeartRate']),
      rmssdMs: serializer.fromJson<int?>(json['rmssdMs']),
      pauseCount: serializer.fromJson<int>(json['pauseCount']),
      pausedMs: serializer.fromJson<int>(json['pausedMs']),
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
      'protocol': serializer.toJson<String>(
        $SessionsTable.$converterprotocol.toJson(protocol),
      ),
      'durationMs': serializer.toJson<int>(durationMs),
      'distanceDm': serializer.toJson<int>(distanceDm),
      'averagePaceCs': serializer.toJson<int?>(averagePaceCs),
      'averageWatts': serializer.toJson<int?>(averageWatts),
      'averageStrokeRate': serializer.toJson<double?>(averageStrokeRate),
      'strokeCount': serializer.toJson<int>(strokeCount),
      'templateId': serializer.toJson<int?>(templateId),
      'templateName': serializer.toJson<String?>(templateName),
      'courseVersionId': serializer.toJson<int?>(courseVersionId),
      'plannedLaps': serializer.toJson<int?>(plannedLaps),
      'imported': serializer.toJson<bool>(imported),
      'averageHeartRate': serializer.toJson<int?>(averageHeartRate),
      'maxHeartRate': serializer.toJson<int?>(maxHeartRate),
      'rmssdMs': serializer.toJson<int?>(rmssdMs),
      'pauseCount': serializer.toJson<int>(pauseCount),
      'pausedMs': serializer.toJson<int>(pausedMs),
    };
  }

  SessionRow copyWith({
    int? id,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    SessionStatus? status,
    ErgSourceKind? source,
    Value<String?> deviceName = const Value.absent(),
    ErgProtocol? protocol,
    int? durationMs,
    int? distanceDm,
    Value<int?> averagePaceCs = const Value.absent(),
    Value<int?> averageWatts = const Value.absent(),
    Value<double?> averageStrokeRate = const Value.absent(),
    int? strokeCount,
    Value<int?> templateId = const Value.absent(),
    Value<String?> templateName = const Value.absent(),
    Value<int?> courseVersionId = const Value.absent(),
    Value<int?> plannedLaps = const Value.absent(),
    bool? imported,
    Value<int?> averageHeartRate = const Value.absent(),
    Value<int?> maxHeartRate = const Value.absent(),
    Value<int?> rmssdMs = const Value.absent(),
    int? pauseCount,
    int? pausedMs,
  }) => SessionRow(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    status: status ?? this.status,
    source: source ?? this.source,
    deviceName: deviceName.present ? deviceName.value : this.deviceName,
    protocol: protocol ?? this.protocol,
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
    templateId: templateId.present ? templateId.value : this.templateId,
    templateName: templateName.present ? templateName.value : this.templateName,
    courseVersionId: courseVersionId.present
        ? courseVersionId.value
        : this.courseVersionId,
    plannedLaps: plannedLaps.present ? plannedLaps.value : this.plannedLaps,
    imported: imported ?? this.imported,
    averageHeartRate: averageHeartRate.present
        ? averageHeartRate.value
        : this.averageHeartRate,
    maxHeartRate: maxHeartRate.present ? maxHeartRate.value : this.maxHeartRate,
    rmssdMs: rmssdMs.present ? rmssdMs.value : this.rmssdMs,
    pauseCount: pauseCount ?? this.pauseCount,
    pausedMs: pausedMs ?? this.pausedMs,
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
      protocol: data.protocol.present ? data.protocol.value : this.protocol,
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
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      templateName: data.templateName.present
          ? data.templateName.value
          : this.templateName,
      courseVersionId: data.courseVersionId.present
          ? data.courseVersionId.value
          : this.courseVersionId,
      plannedLaps: data.plannedLaps.present
          ? data.plannedLaps.value
          : this.plannedLaps,
      imported: data.imported.present ? data.imported.value : this.imported,
      averageHeartRate: data.averageHeartRate.present
          ? data.averageHeartRate.value
          : this.averageHeartRate,
      maxHeartRate: data.maxHeartRate.present
          ? data.maxHeartRate.value
          : this.maxHeartRate,
      rmssdMs: data.rmssdMs.present ? data.rmssdMs.value : this.rmssdMs,
      pauseCount: data.pauseCount.present
          ? data.pauseCount.value
          : this.pauseCount,
      pausedMs: data.pausedMs.present ? data.pausedMs.value : this.pausedMs,
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
          ..write('protocol: $protocol, ')
          ..write('durationMs: $durationMs, ')
          ..write('distanceDm: $distanceDm, ')
          ..write('averagePaceCs: $averagePaceCs, ')
          ..write('averageWatts: $averageWatts, ')
          ..write('averageStrokeRate: $averageStrokeRate, ')
          ..write('strokeCount: $strokeCount, ')
          ..write('templateId: $templateId, ')
          ..write('templateName: $templateName, ')
          ..write('courseVersionId: $courseVersionId, ')
          ..write('plannedLaps: $plannedLaps, ')
          ..write('imported: $imported, ')
          ..write('averageHeartRate: $averageHeartRate, ')
          ..write('maxHeartRate: $maxHeartRate, ')
          ..write('rmssdMs: $rmssdMs, ')
          ..write('pauseCount: $pauseCount, ')
          ..write('pausedMs: $pausedMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    startedAt,
    endedAt,
    status,
    source,
    deviceName,
    protocol,
    durationMs,
    distanceDm,
    averagePaceCs,
    averageWatts,
    averageStrokeRate,
    strokeCount,
    templateId,
    templateName,
    courseVersionId,
    plannedLaps,
    imported,
    averageHeartRate,
    maxHeartRate,
    rmssdMs,
    pauseCount,
    pausedMs,
  ]);
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
          other.protocol == this.protocol &&
          other.durationMs == this.durationMs &&
          other.distanceDm == this.distanceDm &&
          other.averagePaceCs == this.averagePaceCs &&
          other.averageWatts == this.averageWatts &&
          other.averageStrokeRate == this.averageStrokeRate &&
          other.strokeCount == this.strokeCount &&
          other.templateId == this.templateId &&
          other.templateName == this.templateName &&
          other.courseVersionId == this.courseVersionId &&
          other.plannedLaps == this.plannedLaps &&
          other.imported == this.imported &&
          other.averageHeartRate == this.averageHeartRate &&
          other.maxHeartRate == this.maxHeartRate &&
          other.rmssdMs == this.rmssdMs &&
          other.pauseCount == this.pauseCount &&
          other.pausedMs == this.pausedMs);
}

class SessionsCompanion extends UpdateCompanion<SessionRow> {
  final Value<int> id;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<SessionStatus> status;
  final Value<ErgSourceKind> source;
  final Value<String?> deviceName;
  final Value<ErgProtocol> protocol;
  final Value<int> durationMs;
  final Value<int> distanceDm;
  final Value<int?> averagePaceCs;
  final Value<int?> averageWatts;
  final Value<double?> averageStrokeRate;
  final Value<int> strokeCount;
  final Value<int?> templateId;
  final Value<String?> templateName;
  final Value<int?> courseVersionId;
  final Value<int?> plannedLaps;
  final Value<bool> imported;
  final Value<int?> averageHeartRate;
  final Value<int?> maxHeartRate;
  final Value<int?> rmssdMs;
  final Value<int> pauseCount;
  final Value<int> pausedMs;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.source = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.protocol = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.distanceDm = const Value.absent(),
    this.averagePaceCs = const Value.absent(),
    this.averageWatts = const Value.absent(),
    this.averageStrokeRate = const Value.absent(),
    this.strokeCount = const Value.absent(),
    this.templateId = const Value.absent(),
    this.templateName = const Value.absent(),
    this.courseVersionId = const Value.absent(),
    this.plannedLaps = const Value.absent(),
    this.imported = const Value.absent(),
    this.averageHeartRate = const Value.absent(),
    this.maxHeartRate = const Value.absent(),
    this.rmssdMs = const Value.absent(),
    this.pauseCount = const Value.absent(),
    this.pausedMs = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    required SessionStatus status,
    required ErgSourceKind source,
    this.deviceName = const Value.absent(),
    this.protocol = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.distanceDm = const Value.absent(),
    this.averagePaceCs = const Value.absent(),
    this.averageWatts = const Value.absent(),
    this.averageStrokeRate = const Value.absent(),
    this.strokeCount = const Value.absent(),
    this.templateId = const Value.absent(),
    this.templateName = const Value.absent(),
    this.courseVersionId = const Value.absent(),
    this.plannedLaps = const Value.absent(),
    this.imported = const Value.absent(),
    this.averageHeartRate = const Value.absent(),
    this.maxHeartRate = const Value.absent(),
    this.rmssdMs = const Value.absent(),
    this.pauseCount = const Value.absent(),
    this.pausedMs = const Value.absent(),
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
    Expression<String>? protocol,
    Expression<int>? durationMs,
    Expression<int>? distanceDm,
    Expression<int>? averagePaceCs,
    Expression<int>? averageWatts,
    Expression<double>? averageStrokeRate,
    Expression<int>? strokeCount,
    Expression<int>? templateId,
    Expression<String>? templateName,
    Expression<int>? courseVersionId,
    Expression<int>? plannedLaps,
    Expression<bool>? imported,
    Expression<int>? averageHeartRate,
    Expression<int>? maxHeartRate,
    Expression<int>? rmssdMs,
    Expression<int>? pauseCount,
    Expression<int>? pausedMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (status != null) 'status': status,
      if (source != null) 'source': source,
      if (deviceName != null) 'device_name': deviceName,
      if (protocol != null) 'protocol': protocol,
      if (durationMs != null) 'duration_ms': durationMs,
      if (distanceDm != null) 'distance_dm': distanceDm,
      if (averagePaceCs != null) 'average_pace_cs': averagePaceCs,
      if (averageWatts != null) 'average_watts': averageWatts,
      if (averageStrokeRate != null) 'average_stroke_rate': averageStrokeRate,
      if (strokeCount != null) 'stroke_count': strokeCount,
      if (templateId != null) 'template_id': templateId,
      if (templateName != null) 'template_name': templateName,
      if (courseVersionId != null) 'course_version_id': courseVersionId,
      if (plannedLaps != null) 'planned_laps': plannedLaps,
      if (imported != null) 'imported': imported,
      if (averageHeartRate != null) 'average_heart_rate': averageHeartRate,
      if (maxHeartRate != null) 'max_heart_rate': maxHeartRate,
      if (rmssdMs != null) 'rmssd_ms': rmssdMs,
      if (pauseCount != null) 'pause_count': pauseCount,
      if (pausedMs != null) 'paused_ms': pausedMs,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<SessionStatus>? status,
    Value<ErgSourceKind>? source,
    Value<String?>? deviceName,
    Value<ErgProtocol>? protocol,
    Value<int>? durationMs,
    Value<int>? distanceDm,
    Value<int?>? averagePaceCs,
    Value<int?>? averageWatts,
    Value<double?>? averageStrokeRate,
    Value<int>? strokeCount,
    Value<int?>? templateId,
    Value<String?>? templateName,
    Value<int?>? courseVersionId,
    Value<int?>? plannedLaps,
    Value<bool>? imported,
    Value<int?>? averageHeartRate,
    Value<int?>? maxHeartRate,
    Value<int?>? rmssdMs,
    Value<int>? pauseCount,
    Value<int>? pausedMs,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      source: source ?? this.source,
      deviceName: deviceName ?? this.deviceName,
      protocol: protocol ?? this.protocol,
      durationMs: durationMs ?? this.durationMs,
      distanceDm: distanceDm ?? this.distanceDm,
      averagePaceCs: averagePaceCs ?? this.averagePaceCs,
      averageWatts: averageWatts ?? this.averageWatts,
      averageStrokeRate: averageStrokeRate ?? this.averageStrokeRate,
      strokeCount: strokeCount ?? this.strokeCount,
      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
      courseVersionId: courseVersionId ?? this.courseVersionId,
      plannedLaps: plannedLaps ?? this.plannedLaps,
      imported: imported ?? this.imported,
      averageHeartRate: averageHeartRate ?? this.averageHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      rmssdMs: rmssdMs ?? this.rmssdMs,
      pauseCount: pauseCount ?? this.pauseCount,
      pausedMs: pausedMs ?? this.pausedMs,
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
    if (protocol.present) {
      map['protocol'] = Variable<String>(
        $SessionsTable.$converterprotocol.toSql(protocol.value),
      );
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
    if (templateId.present) {
      map['template_id'] = Variable<int>(templateId.value);
    }
    if (templateName.present) {
      map['template_name'] = Variable<String>(templateName.value);
    }
    if (courseVersionId.present) {
      map['course_version_id'] = Variable<int>(courseVersionId.value);
    }
    if (plannedLaps.present) {
      map['planned_laps'] = Variable<int>(plannedLaps.value);
    }
    if (imported.present) {
      map['imported'] = Variable<bool>(imported.value);
    }
    if (averageHeartRate.present) {
      map['average_heart_rate'] = Variable<int>(averageHeartRate.value);
    }
    if (maxHeartRate.present) {
      map['max_heart_rate'] = Variable<int>(maxHeartRate.value);
    }
    if (rmssdMs.present) {
      map['rmssd_ms'] = Variable<int>(rmssdMs.value);
    }
    if (pauseCount.present) {
      map['pause_count'] = Variable<int>(pauseCount.value);
    }
    if (pausedMs.present) {
      map['paused_ms'] = Variable<int>(pausedMs.value);
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
          ..write('protocol: $protocol, ')
          ..write('durationMs: $durationMs, ')
          ..write('distanceDm: $distanceDm, ')
          ..write('averagePaceCs: $averagePaceCs, ')
          ..write('averageWatts: $averageWatts, ')
          ..write('averageStrokeRate: $averageStrokeRate, ')
          ..write('strokeCount: $strokeCount, ')
          ..write('templateId: $templateId, ')
          ..write('templateName: $templateName, ')
          ..write('courseVersionId: $courseVersionId, ')
          ..write('plannedLaps: $plannedLaps, ')
          ..write('imported: $imported, ')
          ..write('averageHeartRate: $averageHeartRate, ')
          ..write('maxHeartRate: $maxHeartRate, ')
          ..write('rmssdMs: $rmssdMs, ')
          ..write('pauseCount: $pauseCount, ')
          ..write('pausedMs: $pausedMs')
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
  static const VerificationMeta _wallMsMeta = const VerificationMeta('wallMs');
  @override
  late final GeneratedColumn<int> wallMs = GeneratedColumn<int>(
    'wall_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMsMeta = const VerificationMeta(
    'activeMs',
  );
  @override
  late final GeneratedColumn<int> activeMs = GeneratedColumn<int>(
    'active_ms',
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
    wallMs,
    activeMs,
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
    if (data.containsKey('wall_ms')) {
      context.handle(
        _wallMsMeta,
        wallMs.isAcceptableOrUnknown(data['wall_ms']!, _wallMsMeta),
      );
    }
    if (data.containsKey('active_ms')) {
      context.handle(
        _activeMsMeta,
        activeMs.isAcceptableOrUnknown(data['active_ms']!, _activeMsMeta),
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
      wallMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wall_ms'],
      ),
      activeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_ms'],
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

  /// Wall-clock time since the first notification; keeps running while the
  /// PM5 pauses its clock. Null for sessions recorded before schema 2.
  final int? wallMs;

  /// Session time: the wall-clock time without the pauses of the session
  /// (Change auto-pause, Design D2). Null for sessions recorded before
  /// schema 7, which had no pauses; their session time is [wallMs].
  final int? activeMs;
  const SampleRow({
    required this.sessionId,
    required this.tMs,
    required this.distanceDm,
    this.paceCs,
    this.watts,
    this.strokeRate,
    this.heartRate,
    this.calories,
    this.wallMs,
    this.activeMs,
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
    if (!nullToAbsent || wallMs != null) {
      map['wall_ms'] = Variable<int>(wallMs);
    }
    if (!nullToAbsent || activeMs != null) {
      map['active_ms'] = Variable<int>(activeMs);
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
      wallMs: wallMs == null && nullToAbsent
          ? const Value.absent()
          : Value(wallMs),
      activeMs: activeMs == null && nullToAbsent
          ? const Value.absent()
          : Value(activeMs),
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
      wallMs: serializer.fromJson<int?>(json['wallMs']),
      activeMs: serializer.fromJson<int?>(json['activeMs']),
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
      'wallMs': serializer.toJson<int?>(wallMs),
      'activeMs': serializer.toJson<int?>(activeMs),
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
    Value<int?> wallMs = const Value.absent(),
    Value<int?> activeMs = const Value.absent(),
  }) => SampleRow(
    sessionId: sessionId ?? this.sessionId,
    tMs: tMs ?? this.tMs,
    distanceDm: distanceDm ?? this.distanceDm,
    paceCs: paceCs.present ? paceCs.value : this.paceCs,
    watts: watts.present ? watts.value : this.watts,
    strokeRate: strokeRate.present ? strokeRate.value : this.strokeRate,
    heartRate: heartRate.present ? heartRate.value : this.heartRate,
    calories: calories.present ? calories.value : this.calories,
    wallMs: wallMs.present ? wallMs.value : this.wallMs,
    activeMs: activeMs.present ? activeMs.value : this.activeMs,
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
      wallMs: data.wallMs.present ? data.wallMs.value : this.wallMs,
      activeMs: data.activeMs.present ? data.activeMs.value : this.activeMs,
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
          ..write('calories: $calories, ')
          ..write('wallMs: $wallMs, ')
          ..write('activeMs: $activeMs')
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
    wallMs,
    activeMs,
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
          other.calories == this.calories &&
          other.wallMs == this.wallMs &&
          other.activeMs == this.activeMs);
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
  final Value<int?> wallMs;
  final Value<int?> activeMs;
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
    this.wallMs = const Value.absent(),
    this.activeMs = const Value.absent(),
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
    this.wallMs = const Value.absent(),
    this.activeMs = const Value.absent(),
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
    Expression<int>? wallMs,
    Expression<int>? activeMs,
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
      if (wallMs != null) 'wall_ms': wallMs,
      if (activeMs != null) 'active_ms': activeMs,
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
    Value<int?>? wallMs,
    Value<int?>? activeMs,
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
      wallMs: wallMs ?? this.wallMs,
      activeMs: activeMs ?? this.activeMs,
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
    if (wallMs.present) {
      map['wall_ms'] = Variable<int>(wallMs.value);
    }
    if (activeMs.present) {
      map['active_ms'] = Variable<int>(activeMs.value);
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
          ..write('wallMs: $wallMs, ')
          ..write('activeMs: $activeMs, ')
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
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _driveTimeMsMeta = const VerificationMeta(
    'driveTimeMs',
  );
  @override
  late final GeneratedColumn<int> driveTimeMs = GeneratedColumn<int>(
    'drive_time_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recoveryTimeMsMeta = const VerificationMeta(
    'recoveryTimeMs',
  );
  @override
  late final GeneratedColumn<int> recoveryTimeMs = GeneratedColumn<int>(
    'recovery_time_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _peakForceNewtonsMeta = const VerificationMeta(
    'peakForceNewtons',
  );
  @override
  late final GeneratedColumn<double> peakForceNewtons = GeneratedColumn<double>(
    'peak_force_newtons',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _averageForceNewtonsMeta =
      const VerificationMeta('averageForceNewtons');
  @override
  late final GeneratedColumn<double> averageForceNewtons =
      GeneratedColumn<double>(
        'average_force_newtons',
        aliasedName,
        true,
        type: DriftSqlType.double,
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
    }
    if (data.containsKey('drive_time_ms')) {
      context.handle(
        _driveTimeMsMeta,
        driveTimeMs.isAcceptableOrUnknown(
          data['drive_time_ms']!,
          _driveTimeMsMeta,
        ),
      );
    }
    if (data.containsKey('recovery_time_ms')) {
      context.handle(
        _recoveryTimeMsMeta,
        recoveryTimeMs.isAcceptableOrUnknown(
          data['recovery_time_ms']!,
          _recoveryTimeMsMeta,
        ),
      );
    }
    if (data.containsKey('peak_force_newtons')) {
      context.handle(
        _peakForceNewtonsMeta,
        peakForceNewtons.isAcceptableOrUnknown(
          data['peak_force_newtons']!,
          _peakForceNewtonsMeta,
        ),
      );
    }
    if (data.containsKey('average_force_newtons')) {
      context.handle(
        _averageForceNewtonsMeta,
        averageForceNewtons.isAcceptableOrUnknown(
          data['average_force_newtons']!,
          _averageForceNewtonsMeta,
        ),
      );
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
      ),
      driveTimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}drive_time_ms'],
      ),
      recoveryTimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recovery_time_ms'],
      ),
      peakForceNewtons: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}peak_force_newtons'],
      ),
      averageForceNewtons: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_force_newtons'],
      ),
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
  final double? driveLengthMeters;
  final int? driveTimeMs;
  final int? recoveryTimeMs;
  final double? peakForceNewtons;
  final double? averageForceNewtons;
  final int? watts;
  const StrokeRow({
    required this.sessionId,
    required this.tMs,
    required this.distanceDm,
    required this.strokeNumber,
    this.driveLengthMeters,
    this.driveTimeMs,
    this.recoveryTimeMs,
    this.peakForceNewtons,
    this.averageForceNewtons,
    this.watts,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<int>(sessionId);
    map['t_ms'] = Variable<int>(tMs);
    map['distance_dm'] = Variable<int>(distanceDm);
    map['stroke_number'] = Variable<int>(strokeNumber);
    if (!nullToAbsent || driveLengthMeters != null) {
      map['drive_length_meters'] = Variable<double>(driveLengthMeters);
    }
    if (!nullToAbsent || driveTimeMs != null) {
      map['drive_time_ms'] = Variable<int>(driveTimeMs);
    }
    if (!nullToAbsent || recoveryTimeMs != null) {
      map['recovery_time_ms'] = Variable<int>(recoveryTimeMs);
    }
    if (!nullToAbsent || peakForceNewtons != null) {
      map['peak_force_newtons'] = Variable<double>(peakForceNewtons);
    }
    if (!nullToAbsent || averageForceNewtons != null) {
      map['average_force_newtons'] = Variable<double>(averageForceNewtons);
    }
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
      driveLengthMeters: driveLengthMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(driveLengthMeters),
      driveTimeMs: driveTimeMs == null && nullToAbsent
          ? const Value.absent()
          : Value(driveTimeMs),
      recoveryTimeMs: recoveryTimeMs == null && nullToAbsent
          ? const Value.absent()
          : Value(recoveryTimeMs),
      peakForceNewtons: peakForceNewtons == null && nullToAbsent
          ? const Value.absent()
          : Value(peakForceNewtons),
      averageForceNewtons: averageForceNewtons == null && nullToAbsent
          ? const Value.absent()
          : Value(averageForceNewtons),
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
      driveLengthMeters: serializer.fromJson<double?>(
        json['driveLengthMeters'],
      ),
      driveTimeMs: serializer.fromJson<int?>(json['driveTimeMs']),
      recoveryTimeMs: serializer.fromJson<int?>(json['recoveryTimeMs']),
      peakForceNewtons: serializer.fromJson<double?>(json['peakForceNewtons']),
      averageForceNewtons: serializer.fromJson<double?>(
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
      'driveLengthMeters': serializer.toJson<double?>(driveLengthMeters),
      'driveTimeMs': serializer.toJson<int?>(driveTimeMs),
      'recoveryTimeMs': serializer.toJson<int?>(recoveryTimeMs),
      'peakForceNewtons': serializer.toJson<double?>(peakForceNewtons),
      'averageForceNewtons': serializer.toJson<double?>(averageForceNewtons),
      'watts': serializer.toJson<int?>(watts),
    };
  }

  StrokeRow copyWith({
    int? sessionId,
    int? tMs,
    int? distanceDm,
    int? strokeNumber,
    Value<double?> driveLengthMeters = const Value.absent(),
    Value<int?> driveTimeMs = const Value.absent(),
    Value<int?> recoveryTimeMs = const Value.absent(),
    Value<double?> peakForceNewtons = const Value.absent(),
    Value<double?> averageForceNewtons = const Value.absent(),
    Value<int?> watts = const Value.absent(),
  }) => StrokeRow(
    sessionId: sessionId ?? this.sessionId,
    tMs: tMs ?? this.tMs,
    distanceDm: distanceDm ?? this.distanceDm,
    strokeNumber: strokeNumber ?? this.strokeNumber,
    driveLengthMeters: driveLengthMeters.present
        ? driveLengthMeters.value
        : this.driveLengthMeters,
    driveTimeMs: driveTimeMs.present ? driveTimeMs.value : this.driveTimeMs,
    recoveryTimeMs: recoveryTimeMs.present
        ? recoveryTimeMs.value
        : this.recoveryTimeMs,
    peakForceNewtons: peakForceNewtons.present
        ? peakForceNewtons.value
        : this.peakForceNewtons,
    averageForceNewtons: averageForceNewtons.present
        ? averageForceNewtons.value
        : this.averageForceNewtons,
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
  final Value<double?> driveLengthMeters;
  final Value<int?> driveTimeMs;
  final Value<int?> recoveryTimeMs;
  final Value<double?> peakForceNewtons;
  final Value<double?> averageForceNewtons;
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
    this.driveLengthMeters = const Value.absent(),
    this.driveTimeMs = const Value.absent(),
    this.recoveryTimeMs = const Value.absent(),
    this.peakForceNewtons = const Value.absent(),
    this.averageForceNewtons = const Value.absent(),
    this.watts = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       tMs = Value(tMs),
       distanceDm = Value(distanceDm),
       strokeNumber = Value(strokeNumber);
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
    Value<double?>? driveLengthMeters,
    Value<int?>? driveTimeMs,
    Value<int?>? recoveryTimeMs,
    Value<double?>? peakForceNewtons,
    Value<double?>? averageForceNewtons,
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

class $ZonesTable extends Zones with TableInfo<$ZonesTable, ZoneRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ZonesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CourseAxis, String> axis =
      GeneratedColumn<String>(
        'axis',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CourseAxis>($ZonesTable.$converteraxis);
  static const VerificationMeta _lengthMeta = const VerificationMeta('length');
  @override
  late final GeneratedColumn<int> length = GeneratedColumn<int>(
    'length',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paceFastCsMeta = const VerificationMeta(
    'paceFastCs',
  );
  @override
  late final GeneratedColumn<int> paceFastCs = GeneratedColumn<int>(
    'pace_fast_cs',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paceSlowCsMeta = const VerificationMeta(
    'paceSlowCs',
  );
  @override
  late final GeneratedColumn<int> paceSlowCs = GeneratedColumn<int>(
    'pace_slow_cs',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spmMinMeta = const VerificationMeta('spmMin');
  @override
  late final GeneratedColumn<int> spmMin = GeneratedColumn<int>(
    'spm_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spmMaxMeta = const VerificationMeta('spmMax');
  @override
  late final GeneratedColumn<int> spmMax = GeneratedColumn<int>(
    'spm_max',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
    id,
    name,
    axis,
    length,
    paceFastCs,
    paceSlowCs,
    spmMin,
    spmMax,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'zones';
  @override
  VerificationContext validateIntegrity(
    Insertable<ZoneRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('length')) {
      context.handle(
        _lengthMeta,
        length.isAcceptableOrUnknown(data['length']!, _lengthMeta),
      );
    } else if (isInserting) {
      context.missing(_lengthMeta);
    }
    if (data.containsKey('pace_fast_cs')) {
      context.handle(
        _paceFastCsMeta,
        paceFastCs.isAcceptableOrUnknown(
          data['pace_fast_cs']!,
          _paceFastCsMeta,
        ),
      );
    }
    if (data.containsKey('pace_slow_cs')) {
      context.handle(
        _paceSlowCsMeta,
        paceSlowCs.isAcceptableOrUnknown(
          data['pace_slow_cs']!,
          _paceSlowCsMeta,
        ),
      );
    }
    if (data.containsKey('spm_min')) {
      context.handle(
        _spmMinMeta,
        spmMin.isAcceptableOrUnknown(data['spm_min']!, _spmMinMeta),
      );
    }
    if (data.containsKey('spm_max')) {
      context.handle(
        _spmMaxMeta,
        spmMax.isAcceptableOrUnknown(data['spm_max']!, _spmMaxMeta),
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ZoneRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ZoneRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      axis: $ZonesTable.$converteraxis.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}axis'],
        )!,
      ),
      length: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}length'],
      )!,
      paceFastCs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pace_fast_cs'],
      ),
      paceSlowCs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pace_slow_cs'],
      ),
      spmMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}spm_min'],
      ),
      spmMax: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}spm_max'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ZonesTable createAlias(String alias) {
    return $ZonesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CourseAxis, String, String> $converteraxis =
      const EnumNameConverter<CourseAxis>(CourseAxis.values);
}

class ZoneRow extends DataClass implements Insertable<ZoneRow> {
  final int id;
  final String name;
  final CourseAxis axis;

  /// In metres or seconds, depending on [axis].
  final int length;
  final int? paceFastCs;
  final int? paceSlowCs;
  final int? spmMin;
  final int? spmMax;

  /// Zones are only marked as deleted, as course versions keep their name.
  final DateTime? deletedAt;
  const ZoneRow({
    required this.id,
    required this.name,
    required this.axis,
    required this.length,
    this.paceFastCs,
    this.paceSlowCs,
    this.spmMin,
    this.spmMax,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['axis'] = Variable<String>($ZonesTable.$converteraxis.toSql(axis));
    }
    map['length'] = Variable<int>(length);
    if (!nullToAbsent || paceFastCs != null) {
      map['pace_fast_cs'] = Variable<int>(paceFastCs);
    }
    if (!nullToAbsent || paceSlowCs != null) {
      map['pace_slow_cs'] = Variable<int>(paceSlowCs);
    }
    if (!nullToAbsent || spmMin != null) {
      map['spm_min'] = Variable<int>(spmMin);
    }
    if (!nullToAbsent || spmMax != null) {
      map['spm_max'] = Variable<int>(spmMax);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ZonesCompanion toCompanion(bool nullToAbsent) {
    return ZonesCompanion(
      id: Value(id),
      name: Value(name),
      axis: Value(axis),
      length: Value(length),
      paceFastCs: paceFastCs == null && nullToAbsent
          ? const Value.absent()
          : Value(paceFastCs),
      paceSlowCs: paceSlowCs == null && nullToAbsent
          ? const Value.absent()
          : Value(paceSlowCs),
      spmMin: spmMin == null && nullToAbsent
          ? const Value.absent()
          : Value(spmMin),
      spmMax: spmMax == null && nullToAbsent
          ? const Value.absent()
          : Value(spmMax),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory ZoneRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ZoneRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      axis: $ZonesTable.$converteraxis.fromJson(
        serializer.fromJson<String>(json['axis']),
      ),
      length: serializer.fromJson<int>(json['length']),
      paceFastCs: serializer.fromJson<int?>(json['paceFastCs']),
      paceSlowCs: serializer.fromJson<int?>(json['paceSlowCs']),
      spmMin: serializer.fromJson<int?>(json['spmMin']),
      spmMax: serializer.fromJson<int?>(json['spmMax']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'axis': serializer.toJson<String>(
        $ZonesTable.$converteraxis.toJson(axis),
      ),
      'length': serializer.toJson<int>(length),
      'paceFastCs': serializer.toJson<int?>(paceFastCs),
      'paceSlowCs': serializer.toJson<int?>(paceSlowCs),
      'spmMin': serializer.toJson<int?>(spmMin),
      'spmMax': serializer.toJson<int?>(spmMax),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  ZoneRow copyWith({
    int? id,
    String? name,
    CourseAxis? axis,
    int? length,
    Value<int?> paceFastCs = const Value.absent(),
    Value<int?> paceSlowCs = const Value.absent(),
    Value<int?> spmMin = const Value.absent(),
    Value<int?> spmMax = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => ZoneRow(
    id: id ?? this.id,
    name: name ?? this.name,
    axis: axis ?? this.axis,
    length: length ?? this.length,
    paceFastCs: paceFastCs.present ? paceFastCs.value : this.paceFastCs,
    paceSlowCs: paceSlowCs.present ? paceSlowCs.value : this.paceSlowCs,
    spmMin: spmMin.present ? spmMin.value : this.spmMin,
    spmMax: spmMax.present ? spmMax.value : this.spmMax,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  ZoneRow copyWithCompanion(ZonesCompanion data) {
    return ZoneRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      axis: data.axis.present ? data.axis.value : this.axis,
      length: data.length.present ? data.length.value : this.length,
      paceFastCs: data.paceFastCs.present
          ? data.paceFastCs.value
          : this.paceFastCs,
      paceSlowCs: data.paceSlowCs.present
          ? data.paceSlowCs.value
          : this.paceSlowCs,
      spmMin: data.spmMin.present ? data.spmMin.value : this.spmMin,
      spmMax: data.spmMax.present ? data.spmMax.value : this.spmMax,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ZoneRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('axis: $axis, ')
          ..write('length: $length, ')
          ..write('paceFastCs: $paceFastCs, ')
          ..write('paceSlowCs: $paceSlowCs, ')
          ..write('spmMin: $spmMin, ')
          ..write('spmMax: $spmMax, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    axis,
    length,
    paceFastCs,
    paceSlowCs,
    spmMin,
    spmMax,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ZoneRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.axis == this.axis &&
          other.length == this.length &&
          other.paceFastCs == this.paceFastCs &&
          other.paceSlowCs == this.paceSlowCs &&
          other.spmMin == this.spmMin &&
          other.spmMax == this.spmMax &&
          other.deletedAt == this.deletedAt);
}

class ZonesCompanion extends UpdateCompanion<ZoneRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<CourseAxis> axis;
  final Value<int> length;
  final Value<int?> paceFastCs;
  final Value<int?> paceSlowCs;
  final Value<int?> spmMin;
  final Value<int?> spmMax;
  final Value<DateTime?> deletedAt;
  const ZonesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.axis = const Value.absent(),
    this.length = const Value.absent(),
    this.paceFastCs = const Value.absent(),
    this.paceSlowCs = const Value.absent(),
    this.spmMin = const Value.absent(),
    this.spmMax = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  ZonesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required CourseAxis axis,
    required int length,
    this.paceFastCs = const Value.absent(),
    this.paceSlowCs = const Value.absent(),
    this.spmMin = const Value.absent(),
    this.spmMax = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : name = Value(name),
       axis = Value(axis),
       length = Value(length);
  static Insertable<ZoneRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? axis,
    Expression<int>? length,
    Expression<int>? paceFastCs,
    Expression<int>? paceSlowCs,
    Expression<int>? spmMin,
    Expression<int>? spmMax,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (axis != null) 'axis': axis,
      if (length != null) 'length': length,
      if (paceFastCs != null) 'pace_fast_cs': paceFastCs,
      if (paceSlowCs != null) 'pace_slow_cs': paceSlowCs,
      if (spmMin != null) 'spm_min': spmMin,
      if (spmMax != null) 'spm_max': spmMax,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  ZonesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<CourseAxis>? axis,
    Value<int>? length,
    Value<int?>? paceFastCs,
    Value<int?>? paceSlowCs,
    Value<int?>? spmMin,
    Value<int?>? spmMax,
    Value<DateTime?>? deletedAt,
  }) {
    return ZonesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      axis: axis ?? this.axis,
      length: length ?? this.length,
      paceFastCs: paceFastCs ?? this.paceFastCs,
      paceSlowCs: paceSlowCs ?? this.paceSlowCs,
      spmMin: spmMin ?? this.spmMin,
      spmMax: spmMax ?? this.spmMax,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (axis.present) {
      map['axis'] = Variable<String>(
        $ZonesTable.$converteraxis.toSql(axis.value),
      );
    }
    if (length.present) {
      map['length'] = Variable<int>(length.value);
    }
    if (paceFastCs.present) {
      map['pace_fast_cs'] = Variable<int>(paceFastCs.value);
    }
    if (paceSlowCs.present) {
      map['pace_slow_cs'] = Variable<int>(paceSlowCs.value);
    }
    if (spmMin.present) {
      map['spm_min'] = Variable<int>(spmMin.value);
    }
    if (spmMax.present) {
      map['spm_max'] = Variable<int>(spmMax.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ZonesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('axis: $axis, ')
          ..write('length: $length, ')
          ..write('paceFastCs: $paceFastCs, ')
          ..write('paceSlowCs: $paceSlowCs, ')
          ..write('spmMin: $spmMin, ')
          ..write('spmMax: $spmMax, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $CourseSegmentsTable extends CourseSegments
    with TableInfo<$CourseSegmentsTable, CourseSegmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CourseSegmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _versionIdMeta = const VerificationMeta(
    'versionId',
  );
  @override
  late final GeneratedColumn<int> versionId = GeneratedColumn<int>(
    'version_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES course_versions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lengthMeta = const VerificationMeta('length');
  @override
  late final GeneratedColumn<int> length = GeneratedColumn<int>(
    'length',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paceFastCsMeta = const VerificationMeta(
    'paceFastCs',
  );
  @override
  late final GeneratedColumn<int> paceFastCs = GeneratedColumn<int>(
    'pace_fast_cs',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paceSlowCsMeta = const VerificationMeta(
    'paceSlowCs',
  );
  @override
  late final GeneratedColumn<int> paceSlowCs = GeneratedColumn<int>(
    'pace_slow_cs',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spmMinMeta = const VerificationMeta('spmMin');
  @override
  late final GeneratedColumn<int> spmMin = GeneratedColumn<int>(
    'spm_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spmMaxMeta = const VerificationMeta('spmMax');
  @override
  late final GeneratedColumn<int> spmMax = GeneratedColumn<int>(
    'spm_max',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _zoneIdMeta = const VerificationMeta('zoneId');
  @override
  late final GeneratedColumn<int> zoneId = GeneratedColumn<int>(
    'zone_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES zones (id)',
    ),
  );
  static const VerificationMeta _zoneNameMeta = const VerificationMeta(
    'zoneName',
  );
  @override
  late final GeneratedColumn<String> zoneName = GeneratedColumn<String>(
    'zone_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    versionId,
    position,
    length,
    paceFastCs,
    paceSlowCs,
    spmMin,
    spmMax,
    zoneId,
    zoneName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course_segments';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseSegmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('version_id')) {
      context.handle(
        _versionIdMeta,
        versionId.isAcceptableOrUnknown(data['version_id']!, _versionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_versionIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('length')) {
      context.handle(
        _lengthMeta,
        length.isAcceptableOrUnknown(data['length']!, _lengthMeta),
      );
    } else if (isInserting) {
      context.missing(_lengthMeta);
    }
    if (data.containsKey('pace_fast_cs')) {
      context.handle(
        _paceFastCsMeta,
        paceFastCs.isAcceptableOrUnknown(
          data['pace_fast_cs']!,
          _paceFastCsMeta,
        ),
      );
    }
    if (data.containsKey('pace_slow_cs')) {
      context.handle(
        _paceSlowCsMeta,
        paceSlowCs.isAcceptableOrUnknown(
          data['pace_slow_cs']!,
          _paceSlowCsMeta,
        ),
      );
    }
    if (data.containsKey('spm_min')) {
      context.handle(
        _spmMinMeta,
        spmMin.isAcceptableOrUnknown(data['spm_min']!, _spmMinMeta),
      );
    }
    if (data.containsKey('spm_max')) {
      context.handle(
        _spmMaxMeta,
        spmMax.isAcceptableOrUnknown(data['spm_max']!, _spmMaxMeta),
      );
    }
    if (data.containsKey('zone_id')) {
      context.handle(
        _zoneIdMeta,
        zoneId.isAcceptableOrUnknown(data['zone_id']!, _zoneIdMeta),
      );
    }
    if (data.containsKey('zone_name')) {
      context.handle(
        _zoneNameMeta,
        zoneName.isAcceptableOrUnknown(data['zone_name']!, _zoneNameMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {versionId, position};
  @override
  CourseSegmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseSegmentRow(
      versionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      length: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}length'],
      )!,
      paceFastCs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pace_fast_cs'],
      ),
      paceSlowCs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pace_slow_cs'],
      ),
      spmMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}spm_min'],
      ),
      spmMax: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}spm_max'],
      ),
      zoneId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}zone_id'],
      ),
      zoneName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zone_name'],
      ),
    );
  }

  @override
  $CourseSegmentsTable createAlias(String alias) {
    return $CourseSegmentsTable(attachedDatabase, alias);
  }
}

class CourseSegmentRow extends DataClass
    implements Insertable<CourseSegmentRow> {
  final int versionId;
  final int position;

  /// In the unit of the course length.
  final int length;
  final int? paceFastCs;
  final int? paceSlowCs;
  final int? spmMin;
  final int? spmMax;

  /// The placed zone; null for a free gap and in versions from before zones
  /// that were already rowed.
  final int? zoneId;

  /// The name of the zone when the version was stored.
  final String? zoneName;
  const CourseSegmentRow({
    required this.versionId,
    required this.position,
    required this.length,
    this.paceFastCs,
    this.paceSlowCs,
    this.spmMin,
    this.spmMax,
    this.zoneId,
    this.zoneName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['version_id'] = Variable<int>(versionId);
    map['position'] = Variable<int>(position);
    map['length'] = Variable<int>(length);
    if (!nullToAbsent || paceFastCs != null) {
      map['pace_fast_cs'] = Variable<int>(paceFastCs);
    }
    if (!nullToAbsent || paceSlowCs != null) {
      map['pace_slow_cs'] = Variable<int>(paceSlowCs);
    }
    if (!nullToAbsent || spmMin != null) {
      map['spm_min'] = Variable<int>(spmMin);
    }
    if (!nullToAbsent || spmMax != null) {
      map['spm_max'] = Variable<int>(spmMax);
    }
    if (!nullToAbsent || zoneId != null) {
      map['zone_id'] = Variable<int>(zoneId);
    }
    if (!nullToAbsent || zoneName != null) {
      map['zone_name'] = Variable<String>(zoneName);
    }
    return map;
  }

  CourseSegmentsCompanion toCompanion(bool nullToAbsent) {
    return CourseSegmentsCompanion(
      versionId: Value(versionId),
      position: Value(position),
      length: Value(length),
      paceFastCs: paceFastCs == null && nullToAbsent
          ? const Value.absent()
          : Value(paceFastCs),
      paceSlowCs: paceSlowCs == null && nullToAbsent
          ? const Value.absent()
          : Value(paceSlowCs),
      spmMin: spmMin == null && nullToAbsent
          ? const Value.absent()
          : Value(spmMin),
      spmMax: spmMax == null && nullToAbsent
          ? const Value.absent()
          : Value(spmMax),
      zoneId: zoneId == null && nullToAbsent
          ? const Value.absent()
          : Value(zoneId),
      zoneName: zoneName == null && nullToAbsent
          ? const Value.absent()
          : Value(zoneName),
    );
  }

  factory CourseSegmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseSegmentRow(
      versionId: serializer.fromJson<int>(json['versionId']),
      position: serializer.fromJson<int>(json['position']),
      length: serializer.fromJson<int>(json['length']),
      paceFastCs: serializer.fromJson<int?>(json['paceFastCs']),
      paceSlowCs: serializer.fromJson<int?>(json['paceSlowCs']),
      spmMin: serializer.fromJson<int?>(json['spmMin']),
      spmMax: serializer.fromJson<int?>(json['spmMax']),
      zoneId: serializer.fromJson<int?>(json['zoneId']),
      zoneName: serializer.fromJson<String?>(json['zoneName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'versionId': serializer.toJson<int>(versionId),
      'position': serializer.toJson<int>(position),
      'length': serializer.toJson<int>(length),
      'paceFastCs': serializer.toJson<int?>(paceFastCs),
      'paceSlowCs': serializer.toJson<int?>(paceSlowCs),
      'spmMin': serializer.toJson<int?>(spmMin),
      'spmMax': serializer.toJson<int?>(spmMax),
      'zoneId': serializer.toJson<int?>(zoneId),
      'zoneName': serializer.toJson<String?>(zoneName),
    };
  }

  CourseSegmentRow copyWith({
    int? versionId,
    int? position,
    int? length,
    Value<int?> paceFastCs = const Value.absent(),
    Value<int?> paceSlowCs = const Value.absent(),
    Value<int?> spmMin = const Value.absent(),
    Value<int?> spmMax = const Value.absent(),
    Value<int?> zoneId = const Value.absent(),
    Value<String?> zoneName = const Value.absent(),
  }) => CourseSegmentRow(
    versionId: versionId ?? this.versionId,
    position: position ?? this.position,
    length: length ?? this.length,
    paceFastCs: paceFastCs.present ? paceFastCs.value : this.paceFastCs,
    paceSlowCs: paceSlowCs.present ? paceSlowCs.value : this.paceSlowCs,
    spmMin: spmMin.present ? spmMin.value : this.spmMin,
    spmMax: spmMax.present ? spmMax.value : this.spmMax,
    zoneId: zoneId.present ? zoneId.value : this.zoneId,
    zoneName: zoneName.present ? zoneName.value : this.zoneName,
  );
  CourseSegmentRow copyWithCompanion(CourseSegmentsCompanion data) {
    return CourseSegmentRow(
      versionId: data.versionId.present ? data.versionId.value : this.versionId,
      position: data.position.present ? data.position.value : this.position,
      length: data.length.present ? data.length.value : this.length,
      paceFastCs: data.paceFastCs.present
          ? data.paceFastCs.value
          : this.paceFastCs,
      paceSlowCs: data.paceSlowCs.present
          ? data.paceSlowCs.value
          : this.paceSlowCs,
      spmMin: data.spmMin.present ? data.spmMin.value : this.spmMin,
      spmMax: data.spmMax.present ? data.spmMax.value : this.spmMax,
      zoneId: data.zoneId.present ? data.zoneId.value : this.zoneId,
      zoneName: data.zoneName.present ? data.zoneName.value : this.zoneName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseSegmentRow(')
          ..write('versionId: $versionId, ')
          ..write('position: $position, ')
          ..write('length: $length, ')
          ..write('paceFastCs: $paceFastCs, ')
          ..write('paceSlowCs: $paceSlowCs, ')
          ..write('spmMin: $spmMin, ')
          ..write('spmMax: $spmMax, ')
          ..write('zoneId: $zoneId, ')
          ..write('zoneName: $zoneName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    versionId,
    position,
    length,
    paceFastCs,
    paceSlowCs,
    spmMin,
    spmMax,
    zoneId,
    zoneName,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseSegmentRow &&
          other.versionId == this.versionId &&
          other.position == this.position &&
          other.length == this.length &&
          other.paceFastCs == this.paceFastCs &&
          other.paceSlowCs == this.paceSlowCs &&
          other.spmMin == this.spmMin &&
          other.spmMax == this.spmMax &&
          other.zoneId == this.zoneId &&
          other.zoneName == this.zoneName);
}

class CourseSegmentsCompanion extends UpdateCompanion<CourseSegmentRow> {
  final Value<int> versionId;
  final Value<int> position;
  final Value<int> length;
  final Value<int?> paceFastCs;
  final Value<int?> paceSlowCs;
  final Value<int?> spmMin;
  final Value<int?> spmMax;
  final Value<int?> zoneId;
  final Value<String?> zoneName;
  final Value<int> rowid;
  const CourseSegmentsCompanion({
    this.versionId = const Value.absent(),
    this.position = const Value.absent(),
    this.length = const Value.absent(),
    this.paceFastCs = const Value.absent(),
    this.paceSlowCs = const Value.absent(),
    this.spmMin = const Value.absent(),
    this.spmMax = const Value.absent(),
    this.zoneId = const Value.absent(),
    this.zoneName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CourseSegmentsCompanion.insert({
    required int versionId,
    required int position,
    required int length,
    this.paceFastCs = const Value.absent(),
    this.paceSlowCs = const Value.absent(),
    this.spmMin = const Value.absent(),
    this.spmMax = const Value.absent(),
    this.zoneId = const Value.absent(),
    this.zoneName = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : versionId = Value(versionId),
       position = Value(position),
       length = Value(length);
  static Insertable<CourseSegmentRow> custom({
    Expression<int>? versionId,
    Expression<int>? position,
    Expression<int>? length,
    Expression<int>? paceFastCs,
    Expression<int>? paceSlowCs,
    Expression<int>? spmMin,
    Expression<int>? spmMax,
    Expression<int>? zoneId,
    Expression<String>? zoneName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (versionId != null) 'version_id': versionId,
      if (position != null) 'position': position,
      if (length != null) 'length': length,
      if (paceFastCs != null) 'pace_fast_cs': paceFastCs,
      if (paceSlowCs != null) 'pace_slow_cs': paceSlowCs,
      if (spmMin != null) 'spm_min': spmMin,
      if (spmMax != null) 'spm_max': spmMax,
      if (zoneId != null) 'zone_id': zoneId,
      if (zoneName != null) 'zone_name': zoneName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CourseSegmentsCompanion copyWith({
    Value<int>? versionId,
    Value<int>? position,
    Value<int>? length,
    Value<int?>? paceFastCs,
    Value<int?>? paceSlowCs,
    Value<int?>? spmMin,
    Value<int?>? spmMax,
    Value<int?>? zoneId,
    Value<String?>? zoneName,
    Value<int>? rowid,
  }) {
    return CourseSegmentsCompanion(
      versionId: versionId ?? this.versionId,
      position: position ?? this.position,
      length: length ?? this.length,
      paceFastCs: paceFastCs ?? this.paceFastCs,
      paceSlowCs: paceSlowCs ?? this.paceSlowCs,
      spmMin: spmMin ?? this.spmMin,
      spmMax: spmMax ?? this.spmMax,
      zoneId: zoneId ?? this.zoneId,
      zoneName: zoneName ?? this.zoneName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (versionId.present) {
      map['version_id'] = Variable<int>(versionId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (length.present) {
      map['length'] = Variable<int>(length.value);
    }
    if (paceFastCs.present) {
      map['pace_fast_cs'] = Variable<int>(paceFastCs.value);
    }
    if (paceSlowCs.present) {
      map['pace_slow_cs'] = Variable<int>(paceSlowCs.value);
    }
    if (spmMin.present) {
      map['spm_min'] = Variable<int>(spmMin.value);
    }
    if (spmMax.present) {
      map['spm_max'] = Variable<int>(spmMax.value);
    }
    if (zoneId.present) {
      map['zone_id'] = Variable<int>(zoneId.value);
    }
    if (zoneName.present) {
      map['zone_name'] = Variable<String>(zoneName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CourseSegmentsCompanion(')
          ..write('versionId: $versionId, ')
          ..write('position: $position, ')
          ..write('length: $length, ')
          ..write('paceFastCs: $paceFastCs, ')
          ..write('paceSlowCs: $paceSlowCs, ')
          ..write('spmMin: $spmMin, ')
          ..write('spmMax: $spmMax, ')
          ..write('zoneId: $zoneId, ')
          ..write('zoneName: $zoneName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TemplateBlocksTable extends TemplateBlocks
    with TableInfo<$TemplateBlocksTable, TemplateBlockRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplateBlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<int> templateId = GeneratedColumn<int>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES templates (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<int> courseId = GeneratedColumn<int>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES courses (id)',
    ),
  );
  static const VerificationMeta _lapsMeta = const VerificationMeta('laps');
  @override
  late final GeneratedColumn<int> laps = GeneratedColumn<int>(
    'laps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [templateId, position, courseId, laps];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'template_blocks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateBlockRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('laps')) {
      context.handle(
        _lapsMeta,
        laps.isAcceptableOrUnknown(data['laps']!, _lapsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {templateId, position};
  @override
  TemplateBlockRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateBlockRow(
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}course_id'],
      )!,
      laps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}laps'],
      ),
    );
  }

  @override
  $TemplateBlocksTable createAlias(String alias) {
    return $TemplateBlocksTable(attachedDatabase, alias);
  }
}

class TemplateBlockRow extends DataClass
    implements Insertable<TemplateBlockRow> {
  final int templateId;
  final int position;
  final int courseId;

  /// Null means open: laps follow until the session is stopped.
  final int? laps;
  const TemplateBlockRow({
    required this.templateId,
    required this.position,
    required this.courseId,
    this.laps,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['template_id'] = Variable<int>(templateId);
    map['position'] = Variable<int>(position);
    map['course_id'] = Variable<int>(courseId);
    if (!nullToAbsent || laps != null) {
      map['laps'] = Variable<int>(laps);
    }
    return map;
  }

  TemplateBlocksCompanion toCompanion(bool nullToAbsent) {
    return TemplateBlocksCompanion(
      templateId: Value(templateId),
      position: Value(position),
      courseId: Value(courseId),
      laps: laps == null && nullToAbsent ? const Value.absent() : Value(laps),
    );
  }

  factory TemplateBlockRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateBlockRow(
      templateId: serializer.fromJson<int>(json['templateId']),
      position: serializer.fromJson<int>(json['position']),
      courseId: serializer.fromJson<int>(json['courseId']),
      laps: serializer.fromJson<int?>(json['laps']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'templateId': serializer.toJson<int>(templateId),
      'position': serializer.toJson<int>(position),
      'courseId': serializer.toJson<int>(courseId),
      'laps': serializer.toJson<int?>(laps),
    };
  }

  TemplateBlockRow copyWith({
    int? templateId,
    int? position,
    int? courseId,
    Value<int?> laps = const Value.absent(),
  }) => TemplateBlockRow(
    templateId: templateId ?? this.templateId,
    position: position ?? this.position,
    courseId: courseId ?? this.courseId,
    laps: laps.present ? laps.value : this.laps,
  );
  TemplateBlockRow copyWithCompanion(TemplateBlocksCompanion data) {
    return TemplateBlockRow(
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      position: data.position.present ? data.position.value : this.position,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      laps: data.laps.present ? data.laps.value : this.laps,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateBlockRow(')
          ..write('templateId: $templateId, ')
          ..write('position: $position, ')
          ..write('courseId: $courseId, ')
          ..write('laps: $laps')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(templateId, position, courseId, laps);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateBlockRow &&
          other.templateId == this.templateId &&
          other.position == this.position &&
          other.courseId == this.courseId &&
          other.laps == this.laps);
}

class TemplateBlocksCompanion extends UpdateCompanion<TemplateBlockRow> {
  final Value<int> templateId;
  final Value<int> position;
  final Value<int> courseId;
  final Value<int?> laps;
  final Value<int> rowid;
  const TemplateBlocksCompanion({
    this.templateId = const Value.absent(),
    this.position = const Value.absent(),
    this.courseId = const Value.absent(),
    this.laps = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplateBlocksCompanion.insert({
    required int templateId,
    required int position,
    required int courseId,
    this.laps = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : templateId = Value(templateId),
       position = Value(position),
       courseId = Value(courseId);
  static Insertable<TemplateBlockRow> custom({
    Expression<int>? templateId,
    Expression<int>? position,
    Expression<int>? courseId,
    Expression<int>? laps,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (templateId != null) 'template_id': templateId,
      if (position != null) 'position': position,
      if (courseId != null) 'course_id': courseId,
      if (laps != null) 'laps': laps,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplateBlocksCompanion copyWith({
    Value<int>? templateId,
    Value<int>? position,
    Value<int>? courseId,
    Value<int?>? laps,
    Value<int>? rowid,
  }) {
    return TemplateBlocksCompanion(
      templateId: templateId ?? this.templateId,
      position: position ?? this.position,
      courseId: courseId ?? this.courseId,
      laps: laps ?? this.laps,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (templateId.present) {
      map['template_id'] = Variable<int>(templateId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<int>(courseId.value);
    }
    if (laps.present) {
      map['laps'] = Variable<int>(laps.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplateBlocksCompanion(')
          ..write('templateId: $templateId, ')
          ..write('position: $position, ')
          ..write('courseId: $courseId, ')
          ..write('laps: $laps, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LapsTable extends Laps with TableInfo<$LapsTable, LapRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LapsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _lapNoMeta = const VerificationMeta('lapNo');
  @override
  late final GeneratedColumn<int> lapNo = GeneratedColumn<int>(
    'lap_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startWallMsMeta = const VerificationMeta(
    'startWallMs',
  );
  @override
  late final GeneratedColumn<int> startWallMs = GeneratedColumn<int>(
    'start_wall_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endWallMsMeta = const VerificationMeta(
    'endWallMs',
  );
  @override
  late final GeneratedColumn<int> endWallMs = GeneratedColumn<int>(
    'end_wall_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDistanceDmMeta = const VerificationMeta(
    'startDistanceDm',
  );
  @override
  late final GeneratedColumn<int> startDistanceDm = GeneratedColumn<int>(
    'start_distance_dm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDistanceDmMeta = const VerificationMeta(
    'endDistanceDm',
  );
  @override
  late final GeneratedColumn<int> endDistanceDm = GeneratedColumn<int>(
    'end_distance_dm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completeMeta = const VerificationMeta(
    'complete',
  );
  @override
  late final GeneratedColumn<bool> complete = GeneratedColumn<bool>(
    'complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("complete" IN (0, 1))',
    ),
  );
  static const VerificationMeta _inZoneShareMeta = const VerificationMeta(
    'inZoneShare',
  );
  @override
  late final GeneratedColumn<double> inZoneShare = GeneratedColumn<double>(
    'in_zone_share',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    lapNo,
    startWallMs,
    endWallMs,
    startDistanceDm,
    endDistanceDm,
    complete,
    inZoneShare,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'laps';
  @override
  VerificationContext validateIntegrity(
    Insertable<LapRow> instance, {
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
    if (data.containsKey('lap_no')) {
      context.handle(
        _lapNoMeta,
        lapNo.isAcceptableOrUnknown(data['lap_no']!, _lapNoMeta),
      );
    } else if (isInserting) {
      context.missing(_lapNoMeta);
    }
    if (data.containsKey('start_wall_ms')) {
      context.handle(
        _startWallMsMeta,
        startWallMs.isAcceptableOrUnknown(
          data['start_wall_ms']!,
          _startWallMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startWallMsMeta);
    }
    if (data.containsKey('end_wall_ms')) {
      context.handle(
        _endWallMsMeta,
        endWallMs.isAcceptableOrUnknown(data['end_wall_ms']!, _endWallMsMeta),
      );
    } else if (isInserting) {
      context.missing(_endWallMsMeta);
    }
    if (data.containsKey('start_distance_dm')) {
      context.handle(
        _startDistanceDmMeta,
        startDistanceDm.isAcceptableOrUnknown(
          data['start_distance_dm']!,
          _startDistanceDmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startDistanceDmMeta);
    }
    if (data.containsKey('end_distance_dm')) {
      context.handle(
        _endDistanceDmMeta,
        endDistanceDm.isAcceptableOrUnknown(
          data['end_distance_dm']!,
          _endDistanceDmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_endDistanceDmMeta);
    }
    if (data.containsKey('complete')) {
      context.handle(
        _completeMeta,
        complete.isAcceptableOrUnknown(data['complete']!, _completeMeta),
      );
    } else if (isInserting) {
      context.missing(_completeMeta);
    }
    if (data.containsKey('in_zone_share')) {
      context.handle(
        _inZoneShareMeta,
        inZoneShare.isAcceptableOrUnknown(
          data['in_zone_share']!,
          _inZoneShareMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, lapNo};
  @override
  LapRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LapRow(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      lapNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lap_no'],
      )!,
      startWallMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_wall_ms'],
      )!,
      endWallMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_wall_ms'],
      )!,
      startDistanceDm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_distance_dm'],
      )!,
      endDistanceDm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_distance_dm'],
      )!,
      complete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}complete'],
      )!,
      inZoneShare: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}in_zone_share'],
      ),
    );
  }

  @override
  $LapsTable createAlias(String alias) {
    return $LapsTable(attachedDatabase, alias);
  }
}

class LapRow extends DataClass implements Insertable<LapRow> {
  final int sessionId;

  /// Starting at 1.
  final int lapNo;
  final int startWallMs;
  final int endWallMs;
  final int startDistanceDm;
  final int endDistanceDm;

  /// False for a lap that was started but not finished.
  final bool complete;

  /// Share of time within the bands, 0 to 1; null without bands.
  final double? inZoneShare;
  const LapRow({
    required this.sessionId,
    required this.lapNo,
    required this.startWallMs,
    required this.endWallMs,
    required this.startDistanceDm,
    required this.endDistanceDm,
    required this.complete,
    this.inZoneShare,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<int>(sessionId);
    map['lap_no'] = Variable<int>(lapNo);
    map['start_wall_ms'] = Variable<int>(startWallMs);
    map['end_wall_ms'] = Variable<int>(endWallMs);
    map['start_distance_dm'] = Variable<int>(startDistanceDm);
    map['end_distance_dm'] = Variable<int>(endDistanceDm);
    map['complete'] = Variable<bool>(complete);
    if (!nullToAbsent || inZoneShare != null) {
      map['in_zone_share'] = Variable<double>(inZoneShare);
    }
    return map;
  }

  LapsCompanion toCompanion(bool nullToAbsent) {
    return LapsCompanion(
      sessionId: Value(sessionId),
      lapNo: Value(lapNo),
      startWallMs: Value(startWallMs),
      endWallMs: Value(endWallMs),
      startDistanceDm: Value(startDistanceDm),
      endDistanceDm: Value(endDistanceDm),
      complete: Value(complete),
      inZoneShare: inZoneShare == null && nullToAbsent
          ? const Value.absent()
          : Value(inZoneShare),
    );
  }

  factory LapRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LapRow(
      sessionId: serializer.fromJson<int>(json['sessionId']),
      lapNo: serializer.fromJson<int>(json['lapNo']),
      startWallMs: serializer.fromJson<int>(json['startWallMs']),
      endWallMs: serializer.fromJson<int>(json['endWallMs']),
      startDistanceDm: serializer.fromJson<int>(json['startDistanceDm']),
      endDistanceDm: serializer.fromJson<int>(json['endDistanceDm']),
      complete: serializer.fromJson<bool>(json['complete']),
      inZoneShare: serializer.fromJson<double?>(json['inZoneShare']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<int>(sessionId),
      'lapNo': serializer.toJson<int>(lapNo),
      'startWallMs': serializer.toJson<int>(startWallMs),
      'endWallMs': serializer.toJson<int>(endWallMs),
      'startDistanceDm': serializer.toJson<int>(startDistanceDm),
      'endDistanceDm': serializer.toJson<int>(endDistanceDm),
      'complete': serializer.toJson<bool>(complete),
      'inZoneShare': serializer.toJson<double?>(inZoneShare),
    };
  }

  LapRow copyWith({
    int? sessionId,
    int? lapNo,
    int? startWallMs,
    int? endWallMs,
    int? startDistanceDm,
    int? endDistanceDm,
    bool? complete,
    Value<double?> inZoneShare = const Value.absent(),
  }) => LapRow(
    sessionId: sessionId ?? this.sessionId,
    lapNo: lapNo ?? this.lapNo,
    startWallMs: startWallMs ?? this.startWallMs,
    endWallMs: endWallMs ?? this.endWallMs,
    startDistanceDm: startDistanceDm ?? this.startDistanceDm,
    endDistanceDm: endDistanceDm ?? this.endDistanceDm,
    complete: complete ?? this.complete,
    inZoneShare: inZoneShare.present ? inZoneShare.value : this.inZoneShare,
  );
  LapRow copyWithCompanion(LapsCompanion data) {
    return LapRow(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      lapNo: data.lapNo.present ? data.lapNo.value : this.lapNo,
      startWallMs: data.startWallMs.present
          ? data.startWallMs.value
          : this.startWallMs,
      endWallMs: data.endWallMs.present ? data.endWallMs.value : this.endWallMs,
      startDistanceDm: data.startDistanceDm.present
          ? data.startDistanceDm.value
          : this.startDistanceDm,
      endDistanceDm: data.endDistanceDm.present
          ? data.endDistanceDm.value
          : this.endDistanceDm,
      complete: data.complete.present ? data.complete.value : this.complete,
      inZoneShare: data.inZoneShare.present
          ? data.inZoneShare.value
          : this.inZoneShare,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LapRow(')
          ..write('sessionId: $sessionId, ')
          ..write('lapNo: $lapNo, ')
          ..write('startWallMs: $startWallMs, ')
          ..write('endWallMs: $endWallMs, ')
          ..write('startDistanceDm: $startDistanceDm, ')
          ..write('endDistanceDm: $endDistanceDm, ')
          ..write('complete: $complete, ')
          ..write('inZoneShare: $inZoneShare')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    lapNo,
    startWallMs,
    endWallMs,
    startDistanceDm,
    endDistanceDm,
    complete,
    inZoneShare,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LapRow &&
          other.sessionId == this.sessionId &&
          other.lapNo == this.lapNo &&
          other.startWallMs == this.startWallMs &&
          other.endWallMs == this.endWallMs &&
          other.startDistanceDm == this.startDistanceDm &&
          other.endDistanceDm == this.endDistanceDm &&
          other.complete == this.complete &&
          other.inZoneShare == this.inZoneShare);
}

class LapsCompanion extends UpdateCompanion<LapRow> {
  final Value<int> sessionId;
  final Value<int> lapNo;
  final Value<int> startWallMs;
  final Value<int> endWallMs;
  final Value<int> startDistanceDm;
  final Value<int> endDistanceDm;
  final Value<bool> complete;
  final Value<double?> inZoneShare;
  final Value<int> rowid;
  const LapsCompanion({
    this.sessionId = const Value.absent(),
    this.lapNo = const Value.absent(),
    this.startWallMs = const Value.absent(),
    this.endWallMs = const Value.absent(),
    this.startDistanceDm = const Value.absent(),
    this.endDistanceDm = const Value.absent(),
    this.complete = const Value.absent(),
    this.inZoneShare = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LapsCompanion.insert({
    required int sessionId,
    required int lapNo,
    required int startWallMs,
    required int endWallMs,
    required int startDistanceDm,
    required int endDistanceDm,
    required bool complete,
    this.inZoneShare = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       lapNo = Value(lapNo),
       startWallMs = Value(startWallMs),
       endWallMs = Value(endWallMs),
       startDistanceDm = Value(startDistanceDm),
       endDistanceDm = Value(endDistanceDm),
       complete = Value(complete);
  static Insertable<LapRow> custom({
    Expression<int>? sessionId,
    Expression<int>? lapNo,
    Expression<int>? startWallMs,
    Expression<int>? endWallMs,
    Expression<int>? startDistanceDm,
    Expression<int>? endDistanceDm,
    Expression<bool>? complete,
    Expression<double>? inZoneShare,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (lapNo != null) 'lap_no': lapNo,
      if (startWallMs != null) 'start_wall_ms': startWallMs,
      if (endWallMs != null) 'end_wall_ms': endWallMs,
      if (startDistanceDm != null) 'start_distance_dm': startDistanceDm,
      if (endDistanceDm != null) 'end_distance_dm': endDistanceDm,
      if (complete != null) 'complete': complete,
      if (inZoneShare != null) 'in_zone_share': inZoneShare,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LapsCompanion copyWith({
    Value<int>? sessionId,
    Value<int>? lapNo,
    Value<int>? startWallMs,
    Value<int>? endWallMs,
    Value<int>? startDistanceDm,
    Value<int>? endDistanceDm,
    Value<bool>? complete,
    Value<double?>? inZoneShare,
    Value<int>? rowid,
  }) {
    return LapsCompanion(
      sessionId: sessionId ?? this.sessionId,
      lapNo: lapNo ?? this.lapNo,
      startWallMs: startWallMs ?? this.startWallMs,
      endWallMs: endWallMs ?? this.endWallMs,
      startDistanceDm: startDistanceDm ?? this.startDistanceDm,
      endDistanceDm: endDistanceDm ?? this.endDistanceDm,
      complete: complete ?? this.complete,
      inZoneShare: inZoneShare ?? this.inZoneShare,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (lapNo.present) {
      map['lap_no'] = Variable<int>(lapNo.value);
    }
    if (startWallMs.present) {
      map['start_wall_ms'] = Variable<int>(startWallMs.value);
    }
    if (endWallMs.present) {
      map['end_wall_ms'] = Variable<int>(endWallMs.value);
    }
    if (startDistanceDm.present) {
      map['start_distance_dm'] = Variable<int>(startDistanceDm.value);
    }
    if (endDistanceDm.present) {
      map['end_distance_dm'] = Variable<int>(endDistanceDm.value);
    }
    if (complete.present) {
      map['complete'] = Variable<bool>(complete.value);
    }
    if (inZoneShare.present) {
      map['in_zone_share'] = Variable<double>(inZoneShare.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LapsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('lapNo: $lapNo, ')
          ..write('startWallMs: $startWallMs, ')
          ..write('endWallMs: $endWallMs, ')
          ..write('startDistanceDm: $startDistanceDm, ')
          ..write('endDistanceDm: $endDistanceDm, ')
          ..write('complete: $complete, ')
          ..write('inZoneShare: $inZoneShare, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LapSegmentsTable extends LapSegments
    with TableInfo<$LapSegmentsTable, LapSegmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LapSegmentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _lapNoMeta = const VerificationMeta('lapNo');
  @override
  late final GeneratedColumn<int> lapNo = GeneratedColumn<int>(
    'lap_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _inZoneShareMeta = const VerificationMeta(
    'inZoneShare',
  );
  @override
  late final GeneratedColumn<double> inZoneShare = GeneratedColumn<double>(
    'in_zone_share',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    lapNo,
    position,
    durationMs,
    distanceDm,
    inZoneShare,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lap_segments';
  @override
  VerificationContext validateIntegrity(
    Insertable<LapSegmentRow> instance, {
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
    if (data.containsKey('lap_no')) {
      context.handle(
        _lapNoMeta,
        lapNo.isAcceptableOrUnknown(data['lap_no']!, _lapNoMeta),
      );
    } else if (isInserting) {
      context.missing(_lapNoMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('distance_dm')) {
      context.handle(
        _distanceDmMeta,
        distanceDm.isAcceptableOrUnknown(data['distance_dm']!, _distanceDmMeta),
      );
    } else if (isInserting) {
      context.missing(_distanceDmMeta);
    }
    if (data.containsKey('in_zone_share')) {
      context.handle(
        _inZoneShareMeta,
        inZoneShare.isAcceptableOrUnknown(
          data['in_zone_share']!,
          _inZoneShareMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, lapNo, position};
  @override
  LapSegmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LapSegmentRow(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      lapNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lap_no'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      distanceDm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distance_dm'],
      )!,
      inZoneShare: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}in_zone_share'],
      ),
    );
  }

  @override
  $LapSegmentsTable createAlias(String alias) {
    return $LapSegmentsTable(attachedDatabase, alias);
  }
}

class LapSegmentRow extends DataClass implements Insertable<LapSegmentRow> {
  final int sessionId;
  final int lapNo;
  final int position;
  final int durationMs;
  final int distanceDm;
  final double? inZoneShare;
  const LapSegmentRow({
    required this.sessionId,
    required this.lapNo,
    required this.position,
    required this.durationMs,
    required this.distanceDm,
    this.inZoneShare,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<int>(sessionId);
    map['lap_no'] = Variable<int>(lapNo);
    map['position'] = Variable<int>(position);
    map['duration_ms'] = Variable<int>(durationMs);
    map['distance_dm'] = Variable<int>(distanceDm);
    if (!nullToAbsent || inZoneShare != null) {
      map['in_zone_share'] = Variable<double>(inZoneShare);
    }
    return map;
  }

  LapSegmentsCompanion toCompanion(bool nullToAbsent) {
    return LapSegmentsCompanion(
      sessionId: Value(sessionId),
      lapNo: Value(lapNo),
      position: Value(position),
      durationMs: Value(durationMs),
      distanceDm: Value(distanceDm),
      inZoneShare: inZoneShare == null && nullToAbsent
          ? const Value.absent()
          : Value(inZoneShare),
    );
  }

  factory LapSegmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LapSegmentRow(
      sessionId: serializer.fromJson<int>(json['sessionId']),
      lapNo: serializer.fromJson<int>(json['lapNo']),
      position: serializer.fromJson<int>(json['position']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      distanceDm: serializer.fromJson<int>(json['distanceDm']),
      inZoneShare: serializer.fromJson<double?>(json['inZoneShare']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<int>(sessionId),
      'lapNo': serializer.toJson<int>(lapNo),
      'position': serializer.toJson<int>(position),
      'durationMs': serializer.toJson<int>(durationMs),
      'distanceDm': serializer.toJson<int>(distanceDm),
      'inZoneShare': serializer.toJson<double?>(inZoneShare),
    };
  }

  LapSegmentRow copyWith({
    int? sessionId,
    int? lapNo,
    int? position,
    int? durationMs,
    int? distanceDm,
    Value<double?> inZoneShare = const Value.absent(),
  }) => LapSegmentRow(
    sessionId: sessionId ?? this.sessionId,
    lapNo: lapNo ?? this.lapNo,
    position: position ?? this.position,
    durationMs: durationMs ?? this.durationMs,
    distanceDm: distanceDm ?? this.distanceDm,
    inZoneShare: inZoneShare.present ? inZoneShare.value : this.inZoneShare,
  );
  LapSegmentRow copyWithCompanion(LapSegmentsCompanion data) {
    return LapSegmentRow(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      lapNo: data.lapNo.present ? data.lapNo.value : this.lapNo,
      position: data.position.present ? data.position.value : this.position,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      distanceDm: data.distanceDm.present
          ? data.distanceDm.value
          : this.distanceDm,
      inZoneShare: data.inZoneShare.present
          ? data.inZoneShare.value
          : this.inZoneShare,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LapSegmentRow(')
          ..write('sessionId: $sessionId, ')
          ..write('lapNo: $lapNo, ')
          ..write('position: $position, ')
          ..write('durationMs: $durationMs, ')
          ..write('distanceDm: $distanceDm, ')
          ..write('inZoneShare: $inZoneShare')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    lapNo,
    position,
    durationMs,
    distanceDm,
    inZoneShare,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LapSegmentRow &&
          other.sessionId == this.sessionId &&
          other.lapNo == this.lapNo &&
          other.position == this.position &&
          other.durationMs == this.durationMs &&
          other.distanceDm == this.distanceDm &&
          other.inZoneShare == this.inZoneShare);
}

class LapSegmentsCompanion extends UpdateCompanion<LapSegmentRow> {
  final Value<int> sessionId;
  final Value<int> lapNo;
  final Value<int> position;
  final Value<int> durationMs;
  final Value<int> distanceDm;
  final Value<double?> inZoneShare;
  final Value<int> rowid;
  const LapSegmentsCompanion({
    this.sessionId = const Value.absent(),
    this.lapNo = const Value.absent(),
    this.position = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.distanceDm = const Value.absent(),
    this.inZoneShare = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LapSegmentsCompanion.insert({
    required int sessionId,
    required int lapNo,
    required int position,
    required int durationMs,
    required int distanceDm,
    this.inZoneShare = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       lapNo = Value(lapNo),
       position = Value(position),
       durationMs = Value(durationMs),
       distanceDm = Value(distanceDm);
  static Insertable<LapSegmentRow> custom({
    Expression<int>? sessionId,
    Expression<int>? lapNo,
    Expression<int>? position,
    Expression<int>? durationMs,
    Expression<int>? distanceDm,
    Expression<double>? inZoneShare,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (lapNo != null) 'lap_no': lapNo,
      if (position != null) 'position': position,
      if (durationMs != null) 'duration_ms': durationMs,
      if (distanceDm != null) 'distance_dm': distanceDm,
      if (inZoneShare != null) 'in_zone_share': inZoneShare,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LapSegmentsCompanion copyWith({
    Value<int>? sessionId,
    Value<int>? lapNo,
    Value<int>? position,
    Value<int>? durationMs,
    Value<int>? distanceDm,
    Value<double?>? inZoneShare,
    Value<int>? rowid,
  }) {
    return LapSegmentsCompanion(
      sessionId: sessionId ?? this.sessionId,
      lapNo: lapNo ?? this.lapNo,
      position: position ?? this.position,
      durationMs: durationMs ?? this.durationMs,
      distanceDm: distanceDm ?? this.distanceDm,
      inZoneShare: inZoneShare ?? this.inZoneShare,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (lapNo.present) {
      map['lap_no'] = Variable<int>(lapNo.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (distanceDm.present) {
      map['distance_dm'] = Variable<int>(distanceDm.value);
    }
    if (inZoneShare.present) {
      map['in_zone_share'] = Variable<double>(inZoneShare.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LapSegmentsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('lapNo: $lapNo, ')
          ..write('position: $position, ')
          ..write('durationMs: $durationMs, ')
          ..write('distanceDm: $distanceDm, ')
          ..write('inZoneShare: $inZoneShare, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RrIntervalsTable extends RrIntervals
    with TableInfo<$RrIntervalsTable, RrIntervalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RrIntervalsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _rrMsMeta = const VerificationMeta('rrMs');
  @override
  late final GeneratedColumn<int> rrMs = GeneratedColumn<int>(
    'rr_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [sessionId, tMs, rrMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rr_intervals';
  @override
  VerificationContext validateIntegrity(
    Insertable<RrIntervalRow> instance, {
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
    if (data.containsKey('rr_ms')) {
      context.handle(
        _rrMsMeta,
        rrMs.isAcceptableOrUnknown(data['rr_ms']!, _rrMsMeta),
      );
    } else if (isInserting) {
      context.missing(_rrMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  RrIntervalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RrIntervalRow(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      tMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}t_ms'],
      )!,
      rrMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rr_ms'],
      )!,
    );
  }

  @override
  $RrIntervalsTable createAlias(String alias) {
    return $RrIntervalsTable(attachedDatabase, alias);
  }
}

class RrIntervalRow extends DataClass implements Insertable<RrIntervalRow> {
  final int sessionId;
  final int tMs;
  final int rrMs;
  const RrIntervalRow({
    required this.sessionId,
    required this.tMs,
    required this.rrMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<int>(sessionId);
    map['t_ms'] = Variable<int>(tMs);
    map['rr_ms'] = Variable<int>(rrMs);
    return map;
  }

  RrIntervalsCompanion toCompanion(bool nullToAbsent) {
    return RrIntervalsCompanion(
      sessionId: Value(sessionId),
      tMs: Value(tMs),
      rrMs: Value(rrMs),
    );
  }

  factory RrIntervalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RrIntervalRow(
      sessionId: serializer.fromJson<int>(json['sessionId']),
      tMs: serializer.fromJson<int>(json['tMs']),
      rrMs: serializer.fromJson<int>(json['rrMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<int>(sessionId),
      'tMs': serializer.toJson<int>(tMs),
      'rrMs': serializer.toJson<int>(rrMs),
    };
  }

  RrIntervalRow copyWith({int? sessionId, int? tMs, int? rrMs}) =>
      RrIntervalRow(
        sessionId: sessionId ?? this.sessionId,
        tMs: tMs ?? this.tMs,
        rrMs: rrMs ?? this.rrMs,
      );
  RrIntervalRow copyWithCompanion(RrIntervalsCompanion data) {
    return RrIntervalRow(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      tMs: data.tMs.present ? data.tMs.value : this.tMs,
      rrMs: data.rrMs.present ? data.rrMs.value : this.rrMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RrIntervalRow(')
          ..write('sessionId: $sessionId, ')
          ..write('tMs: $tMs, ')
          ..write('rrMs: $rrMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sessionId, tMs, rrMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RrIntervalRow &&
          other.sessionId == this.sessionId &&
          other.tMs == this.tMs &&
          other.rrMs == this.rrMs);
}

class RrIntervalsCompanion extends UpdateCompanion<RrIntervalRow> {
  final Value<int> sessionId;
  final Value<int> tMs;
  final Value<int> rrMs;
  final Value<int> rowid;
  const RrIntervalsCompanion({
    this.sessionId = const Value.absent(),
    this.tMs = const Value.absent(),
    this.rrMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RrIntervalsCompanion.insert({
    required int sessionId,
    required int tMs,
    required int rrMs,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       tMs = Value(tMs),
       rrMs = Value(rrMs);
  static Insertable<RrIntervalRow> custom({
    Expression<int>? sessionId,
    Expression<int>? tMs,
    Expression<int>? rrMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (tMs != null) 't_ms': tMs,
      if (rrMs != null) 'rr_ms': rrMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RrIntervalsCompanion copyWith({
    Value<int>? sessionId,
    Value<int>? tMs,
    Value<int>? rrMs,
    Value<int>? rowid,
  }) {
    return RrIntervalsCompanion(
      sessionId: sessionId ?? this.sessionId,
      tMs: tMs ?? this.tMs,
      rrMs: rrMs ?? this.rrMs,
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
    if (rrMs.present) {
      map['rr_ms'] = Variable<int>(rrMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RrIntervalsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('tMs: $tMs, ')
          ..write('rrMs: $rrMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PausesTable extends Pauses with TableInfo<$PausesTable, PauseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PausesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _startWallMsMeta = const VerificationMeta(
    'startWallMs',
  );
  @override
  late final GeneratedColumn<int> startWallMs = GeneratedColumn<int>(
    'start_wall_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endWallMsMeta = const VerificationMeta(
    'endWallMs',
  );
  @override
  late final GeneratedColumn<int> endWallMs = GeneratedColumn<int>(
    'end_wall_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [sessionId, startWallMs, endWallMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pauses';
  @override
  VerificationContext validateIntegrity(
    Insertable<PauseRow> instance, {
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
    if (data.containsKey('start_wall_ms')) {
      context.handle(
        _startWallMsMeta,
        startWallMs.isAcceptableOrUnknown(
          data['start_wall_ms']!,
          _startWallMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startWallMsMeta);
    }
    if (data.containsKey('end_wall_ms')) {
      context.handle(
        _endWallMsMeta,
        endWallMs.isAcceptableOrUnknown(data['end_wall_ms']!, _endWallMsMeta),
      );
    } else if (isInserting) {
      context.missing(_endWallMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, startWallMs};
  @override
  PauseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PauseRow(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      startWallMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_wall_ms'],
      )!,
      endWallMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_wall_ms'],
      )!,
    );
  }

  @override
  $PausesTable createAlias(String alias) {
    return $PausesTable(attachedDatabase, alias);
  }
}

class PauseRow extends DataClass implements Insertable<PauseRow> {
  final int sessionId;
  final int startWallMs;
  final int endWallMs;
  const PauseRow({
    required this.sessionId,
    required this.startWallMs,
    required this.endWallMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<int>(sessionId);
    map['start_wall_ms'] = Variable<int>(startWallMs);
    map['end_wall_ms'] = Variable<int>(endWallMs);
    return map;
  }

  PausesCompanion toCompanion(bool nullToAbsent) {
    return PausesCompanion(
      sessionId: Value(sessionId),
      startWallMs: Value(startWallMs),
      endWallMs: Value(endWallMs),
    );
  }

  factory PauseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PauseRow(
      sessionId: serializer.fromJson<int>(json['sessionId']),
      startWallMs: serializer.fromJson<int>(json['startWallMs']),
      endWallMs: serializer.fromJson<int>(json['endWallMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<int>(sessionId),
      'startWallMs': serializer.toJson<int>(startWallMs),
      'endWallMs': serializer.toJson<int>(endWallMs),
    };
  }

  PauseRow copyWith({int? sessionId, int? startWallMs, int? endWallMs}) =>
      PauseRow(
        sessionId: sessionId ?? this.sessionId,
        startWallMs: startWallMs ?? this.startWallMs,
        endWallMs: endWallMs ?? this.endWallMs,
      );
  PauseRow copyWithCompanion(PausesCompanion data) {
    return PauseRow(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      startWallMs: data.startWallMs.present
          ? data.startWallMs.value
          : this.startWallMs,
      endWallMs: data.endWallMs.present ? data.endWallMs.value : this.endWallMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PauseRow(')
          ..write('sessionId: $sessionId, ')
          ..write('startWallMs: $startWallMs, ')
          ..write('endWallMs: $endWallMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sessionId, startWallMs, endWallMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PauseRow &&
          other.sessionId == this.sessionId &&
          other.startWallMs == this.startWallMs &&
          other.endWallMs == this.endWallMs);
}

class PausesCompanion extends UpdateCompanion<PauseRow> {
  final Value<int> sessionId;
  final Value<int> startWallMs;
  final Value<int> endWallMs;
  final Value<int> rowid;
  const PausesCompanion({
    this.sessionId = const Value.absent(),
    this.startWallMs = const Value.absent(),
    this.endWallMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PausesCompanion.insert({
    required int sessionId,
    required int startWallMs,
    required int endWallMs,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       startWallMs = Value(startWallMs),
       endWallMs = Value(endWallMs);
  static Insertable<PauseRow> custom({
    Expression<int>? sessionId,
    Expression<int>? startWallMs,
    Expression<int>? endWallMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (startWallMs != null) 'start_wall_ms': startWallMs,
      if (endWallMs != null) 'end_wall_ms': endWallMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PausesCompanion copyWith({
    Value<int>? sessionId,
    Value<int>? startWallMs,
    Value<int>? endWallMs,
    Value<int>? rowid,
  }) {
    return PausesCompanion(
      sessionId: sessionId ?? this.sessionId,
      startWallMs: startWallMs ?? this.startWallMs,
      endWallMs: endWallMs ?? this.endWallMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (startWallMs.present) {
      map['start_wall_ms'] = Variable<int>(startWallMs.value);
    }
    if (endWallMs.present) {
      map['end_wall_ms'] = Variable<int>(endWallMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PausesCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('startWallMs: $startWallMs, ')
          ..write('endWallMs: $endWallMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TemplatesTable templates = $TemplatesTable(this);
  late final $CoursesTable courses = $CoursesTable(this);
  late final $CourseVersionsTable courseVersions = $CourseVersionsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $SamplesTable samples = $SamplesTable(this);
  late final $StrokesTable strokes = $StrokesTable(this);
  late final $RawPacketsTable rawPackets = $RawPacketsTable(this);
  late final $ZonesTable zones = $ZonesTable(this);
  late final $CourseSegmentsTable courseSegments = $CourseSegmentsTable(this);
  late final $TemplateBlocksTable templateBlocks = $TemplateBlocksTable(this);
  late final $LapsTable laps = $LapsTable(this);
  late final $LapSegmentsTable lapSegments = $LapSegmentsTable(this);
  late final $RrIntervalsTable rrIntervals = $RrIntervalsTable(this);
  late final $PausesTable pauses = $PausesTable(this);
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
  late final Index courseVersionsCourse = Index(
    'course_versions_course',
    'CREATE INDEX course_versions_course ON course_versions (course_id, version)',
  );
  late final Index rrIntervalsSessionTime = Index(
    'rr_intervals_session_time',
    'CREATE INDEX rr_intervals_session_time ON rr_intervals (session_id, t_ms)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    templates,
    courses,
    courseVersions,
    sessions,
    samples,
    strokes,
    rawPackets,
    zones,
    courseSegments,
    templateBlocks,
    laps,
    lapSegments,
    rrIntervals,
    pauses,
    samplesSessionTime,
    strokesSessionTime,
    rawPacketsSessionTime,
    courseVersionsCourse,
    rrIntervalsSessionTime,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'templates',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sessions', kind: UpdateKind.update)],
    ),
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
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'course_versions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('course_segments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'templates',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('template_blocks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('laps', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lap_segments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('rr_intervals', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('pauses', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$TemplatesTableCreateCompanionBuilder = TemplatesCompanion Function({
  Value<int> id,
  required String name,
  required DateTime createdAt,
});
typedef $$TemplatesTableUpdateCompanionBuilder = TemplatesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<DateTime> createdAt,
});

final class $$TemplatesTableReferences
    extends BaseReferences<_$AppDatabase, $TemplatesTable, TemplateRow> {
  $$TemplatesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SessionsTable, List<SessionRow>>
  _sessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessions,
    aliasName: 'templates__id__sessions__template_id',
  );

  $$SessionsTableProcessedTableManager get sessionsRefs {
    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.templateId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TemplateBlocksTable, List<TemplateBlockRow>>
  _templateBlocksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.templateBlocks,
    aliasName: 'templates__id__template_blocks__template_id',
  );

  $$TemplateBlocksTableProcessedTableManager get templateBlocksRefs {
    final manager = $$TemplateBlocksTableTableManager(
      $_db,
      $_db.templateBlocks,
    ).filter((f) => f.templateId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_templateBlocksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sessionsRefs(
    Expression<bool> Function($$SessionsTableFilterComposer f) f,
  ) {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.templateId,
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
    return f(composer);
  }

  Expression<bool> templateBlocksRefs(
    Expression<bool> Function($$TemplateBlocksTableFilterComposer f) f,
  ) {
    final $$TemplateBlocksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateBlocks,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateBlocksTableFilterComposer(
            $db: $db,
            $table: $db.templateBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> sessionsRefs<T extends Object>(
    Expression<T> Function($$SessionsTableAnnotationComposer a) f,
  ) {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.templateId,
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
    return f(composer);
  }

  Expression<T> templateBlocksRefs<T extends Object>(
    Expression<T> Function($$TemplateBlocksTableAnnotationComposer a) f,
  ) {
    final $$TemplateBlocksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateBlocks,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateBlocksTableAnnotationComposer(
            $db: $db,
            $table: $db.templateBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplatesTable,
          TemplateRow,
          $$TemplatesTableFilterComposer,
          $$TemplatesTableOrderingComposer,
          $$TemplatesTableAnnotationComposer,
          $$TemplatesTableCreateCompanionBuilder,
          $$TemplatesTableUpdateCompanionBuilder,
          (TemplateRow, $$TemplatesTableReferences),
          TemplateRow,
          PrefetchHooks Function({bool sessionsRefs, bool templateBlocksRefs})
        > {
  $$TemplatesTableTableManager(_$AppDatabase db, $TemplatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) => TemplatesCompanion(id: id, name: name, createdAt: createdAt),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required DateTime createdAt,
              }) => TemplatesCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TemplatesTable, TemplateRow>(table),
                  $$TemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sessionsRefs = false, templateBlocksRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sessionsRefs) db.sessions,
                    if (templateBlocksRefs) db.templateBlocks,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sessionsRefs)
                        await $_getPrefetchedDataByColumns<
                          TemplateRow,
                          $TemplatesTable,
                          SessionRow,
                          $SessionsTable
                        >(
                          currentTable: table,
                          referencedTable: $$TemplatesTableReferences
                              ._sessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TemplatesTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'template_id',
                          typedResults: items,
                        ),
                      if (templateBlocksRefs)
                        await $_getPrefetchedDataByColumns<
                          TemplateRow,
                          $TemplatesTable,
                          TemplateBlockRow,
                          $TemplateBlocksTable
                        >(
                          currentTable: table,
                          referencedTable: $$TemplatesTableReferences
                              ._templateBlocksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TemplatesTableReferences(
                                db,
                                table,
                                p0,
                              ).templateBlocksRefs,
                          currentColumn: 'id',
                          referencedColumn: 'template_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplatesTable,
      TemplateRow,
      $$TemplatesTableFilterComposer,
      $$TemplatesTableOrderingComposer,
      $$TemplatesTableAnnotationComposer,
      $$TemplatesTableCreateCompanionBuilder,
      $$TemplatesTableUpdateCompanionBuilder,
      (TemplateRow, $$TemplatesTableReferences),
      TemplateRow,
      PrefetchHooks Function({bool sessionsRefs, bool templateBlocksRefs})
    >;
typedef $$CoursesTableCreateCompanionBuilder = CoursesCompanion Function({
  Value<int> id,
  required String name,
  required CourseAxis axis,
  Value<DateTime?> deletedAt,
});
typedef $$CoursesTableUpdateCompanionBuilder = CoursesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<CourseAxis> axis,
  Value<DateTime?> deletedAt,
});

final class $$CoursesTableReferences
    extends BaseReferences<_$AppDatabase, $CoursesTable, CourseRow> {
  $$CoursesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CourseVersionsTable, List<CourseVersionRow>>
  _courseVersionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.courseVersions,
    aliasName: 'courses__id__course_versions__course_id',
  );

  $$CourseVersionsTableProcessedTableManager get courseVersionsRefs {
    final manager = $$CourseVersionsTableTableManager(
      $_db,
      $_db.courseVersions,
    ).filter((f) => f.courseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_courseVersionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TemplateBlocksTable, List<TemplateBlockRow>>
  _templateBlocksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.templateBlocks,
    aliasName: 'courses__id__template_blocks__course_id',
  );

  $$TemplateBlocksTableProcessedTableManager get templateBlocksRefs {
    final manager = $$TemplateBlocksTableTableManager(
      $_db,
      $_db.templateBlocks,
    ).filter((f) => f.courseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_templateBlocksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CoursesTableFilterComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CourseAxis, CourseAxis, String> get axis =>
      $composableBuilder(
        column: $table.axis,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> courseVersionsRefs(
    Expression<bool> Function($$CourseVersionsTableFilterComposer f) f,
  ) {
    final $$CourseVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseVersions,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseVersionsTableFilterComposer(
            $db: $db,
            $table: $db.courseVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> templateBlocksRefs(
    Expression<bool> Function($$TemplateBlocksTableFilterComposer f) f,
  ) {
    final $$TemplateBlocksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateBlocks,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateBlocksTableFilterComposer(
            $db: $db,
            $table: $db.templateBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CoursesTableOrderingComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get axis => $composableBuilder(
    column: $table.axis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CoursesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CourseAxis, String> get axis =>
      $composableBuilder(column: $table.axis, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> courseVersionsRefs<T extends Object>(
    Expression<T> Function($$CourseVersionsTableAnnotationComposer a) f,
  ) {
    final $$CourseVersionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseVersions,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseVersionsTableAnnotationComposer(
            $db: $db,
            $table: $db.courseVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> templateBlocksRefs<T extends Object>(
    Expression<T> Function($$TemplateBlocksTableAnnotationComposer a) f,
  ) {
    final $$TemplateBlocksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateBlocks,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateBlocksTableAnnotationComposer(
            $db: $db,
            $table: $db.templateBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CoursesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoursesTable,
          CourseRow,
          $$CoursesTableFilterComposer,
          $$CoursesTableOrderingComposer,
          $$CoursesTableAnnotationComposer,
          $$CoursesTableCreateCompanionBuilder,
          $$CoursesTableUpdateCompanionBuilder,
          (CourseRow, $$CoursesTableReferences),
          CourseRow,
          PrefetchHooks Function({
            bool courseVersionsRefs,
            bool templateBlocksRefs,
          })
        > {
  $$CoursesTableTableManager(_$AppDatabase db, $CoursesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoursesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoursesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoursesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<CourseAxis> axis = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => CoursesCompanion(
                id: id,
                name: name,
                axis: axis,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required CourseAxis axis,
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => CoursesCompanion.insert(
                id: id,
                name: name,
                axis: axis,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CoursesTable, CourseRow>(table),
                  $$CoursesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({courseVersionsRefs = false, templateBlocksRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (courseVersionsRefs) db.courseVersions,
                    if (templateBlocksRefs) db.templateBlocks,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (courseVersionsRefs)
                        await $_getPrefetchedDataByColumns<
                          CourseRow,
                          $CoursesTable,
                          CourseVersionRow,
                          $CourseVersionsTable
                        >(
                          currentTable: table,
                          referencedTable: $$CoursesTableReferences
                              ._courseVersionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoursesTableReferences(
                                db,
                                table,
                                p0,
                              ).courseVersionsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'course_id',
                          typedResults: items,
                        ),
                      if (templateBlocksRefs)
                        await $_getPrefetchedDataByColumns<
                          CourseRow,
                          $CoursesTable,
                          TemplateBlockRow,
                          $TemplateBlocksTable
                        >(
                          currentTable: table,
                          referencedTable: $$CoursesTableReferences
                              ._templateBlocksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoursesTableReferences(
                                db,
                                table,
                                p0,
                              ).templateBlocksRefs,
                          currentColumn: 'id',
                          referencedColumn: 'course_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CoursesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoursesTable,
      CourseRow,
      $$CoursesTableFilterComposer,
      $$CoursesTableOrderingComposer,
      $$CoursesTableAnnotationComposer,
      $$CoursesTableCreateCompanionBuilder,
      $$CoursesTableUpdateCompanionBuilder,
      (CourseRow, $$CoursesTableReferences),
      CourseRow,
      PrefetchHooks Function({bool courseVersionsRefs, bool templateBlocksRefs})
    >;
typedef $$CourseVersionsTableCreateCompanionBuilder =
    CourseVersionsCompanion Function({
      Value<int> id,
      required int courseId,
      required int version,
      required int length,
      required DateTime createdAt,
    });
typedef $$CourseVersionsTableUpdateCompanionBuilder =
    CourseVersionsCompanion Function({
      Value<int> id,
      Value<int> courseId,
      Value<int> version,
      Value<int> length,
      Value<DateTime> createdAt,
    });

final class $$CourseVersionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $CourseVersionsTable, CourseVersionRow> {
  $$CourseVersionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CoursesTable _courseIdTable(_$AppDatabase db) =>
      db.courses.createAlias('course_versions__course_id__courses__id');

  $$CoursesTableProcessedTableManager get courseId {
    final $_column = $_itemColumn<int>('course_id')!;

    final manager = $$CoursesTableTableManager(
      $_db,
      $_db.courses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SessionsTable, List<SessionRow>>
  _sessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessions,
    aliasName: 'course_versions__id__sessions__course_version_id',
  );

  $$SessionsTableProcessedTableManager get sessionsRefs {
    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.courseVersionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CourseSegmentsTable, List<CourseSegmentRow>>
  _courseSegmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.courseSegments,
    aliasName: 'course_versions__id__course_segments__version_id',
  );

  $$CourseSegmentsTableProcessedTableManager get courseSegmentsRefs {
    final manager = $$CourseSegmentsTableTableManager(
      $_db,
      $_db.courseSegments,
    ).filter((f) => f.versionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_courseSegmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CourseVersionsTableFilterComposer
    extends Composer<_$AppDatabase, $CourseVersionsTable> {
  $$CourseVersionsTableFilterComposer({
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

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get length => $composableBuilder(
    column: $table.length,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CoursesTableFilterComposer get courseId {
    final $$CoursesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableFilterComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> sessionsRefs(
    Expression<bool> Function($$SessionsTableFilterComposer f) f,
  ) {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.courseVersionId,
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
    return f(composer);
  }

  Expression<bool> courseSegmentsRefs(
    Expression<bool> Function($$CourseSegmentsTableFilterComposer f) f,
  ) {
    final $$CourseSegmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseSegments,
      getReferencedColumn: (t) => t.versionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseSegmentsTableFilterComposer(
            $db: $db,
            $table: $db.courseSegments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CourseVersionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CourseVersionsTable> {
  $$CourseVersionsTableOrderingComposer({
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

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get length => $composableBuilder(
    column: $table.length,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CoursesTableOrderingComposer get courseId {
    final $$CoursesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableOrderingComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseVersionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CourseVersionsTable> {
  $$CourseVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get length =>
      $composableBuilder(column: $table.length, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CoursesTableAnnotationComposer get courseId {
    final $$CoursesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableAnnotationComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> sessionsRefs<T extends Object>(
    Expression<T> Function($$SessionsTableAnnotationComposer a) f,
  ) {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.courseVersionId,
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
    return f(composer);
  }

  Expression<T> courseSegmentsRefs<T extends Object>(
    Expression<T> Function($$CourseSegmentsTableAnnotationComposer a) f,
  ) {
    final $$CourseSegmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseSegments,
      getReferencedColumn: (t) => t.versionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseSegmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.courseSegments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CourseVersionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CourseVersionsTable,
          CourseVersionRow,
          $$CourseVersionsTableFilterComposer,
          $$CourseVersionsTableOrderingComposer,
          $$CourseVersionsTableAnnotationComposer,
          $$CourseVersionsTableCreateCompanionBuilder,
          $$CourseVersionsTableUpdateCompanionBuilder,
          (CourseVersionRow, $$CourseVersionsTableReferences),
          CourseVersionRow,
          PrefetchHooks Function({
            bool courseId,
            bool sessionsRefs,
            bool courseSegmentsRefs,
          })
        > {
  $$CourseVersionsTableTableManager(
    _$AppDatabase db,
    $CourseVersionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CourseVersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CourseVersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CourseVersionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> courseId = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> length = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CourseVersionsCompanion(
                id: id,
                courseId: courseId,
                version: version,
                length: length,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int courseId,
                required int version,
                required int length,
                required DateTime createdAt,
              }) => CourseVersionsCompanion.insert(
                id: id,
                courseId: courseId,
                version: version,
                length: length,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CourseVersionsTable, CourseVersionRow>(table),
                  $$CourseVersionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                courseId = false,
                sessionsRefs = false,
                courseSegmentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sessionsRefs) db.sessions,
                    if (courseSegmentsRefs) db.courseSegments,
                  ],
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
                        if (courseId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.courseId,
                            referencedTable: $$CourseVersionsTableReferences
                                ._courseIdTable(db),
                            referencedColumn: $$CourseVersionsTableReferences
                                ._courseIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sessionsRefs)
                        await $_getPrefetchedDataByColumns<
                          CourseVersionRow,
                          $CourseVersionsTable,
                          SessionRow,
                          $SessionsTable
                        >(
                          currentTable: table,
                          referencedTable: $$CourseVersionsTableReferences
                              ._sessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CourseVersionsTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'course_version_id',
                          typedResults: items,
                        ),
                      if (courseSegmentsRefs)
                        await $_getPrefetchedDataByColumns<
                          CourseVersionRow,
                          $CourseVersionsTable,
                          CourseSegmentRow,
                          $CourseSegmentsTable
                        >(
                          currentTable: table,
                          referencedTable: $$CourseVersionsTableReferences
                              ._courseSegmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CourseVersionsTableReferences(
                                db,
                                table,
                                p0,
                              ).courseSegmentsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'version_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CourseVersionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CourseVersionsTable,
      CourseVersionRow,
      $$CourseVersionsTableFilterComposer,
      $$CourseVersionsTableOrderingComposer,
      $$CourseVersionsTableAnnotationComposer,
      $$CourseVersionsTableCreateCompanionBuilder,
      $$CourseVersionsTableUpdateCompanionBuilder,
      (CourseVersionRow, $$CourseVersionsTableReferences),
      CourseVersionRow,
      PrefetchHooks Function({
        bool courseId,
        bool sessionsRefs,
        bool courseSegmentsRefs,
      })
    >;
typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  required DateTime startedAt,
  Value<DateTime?> endedAt,
  required SessionStatus status,
  required ErgSourceKind source,
  Value<String?> deviceName,
  Value<ErgProtocol> protocol,
  Value<int> durationMs,
  Value<int> distanceDm,
  Value<int?> averagePaceCs,
  Value<int?> averageWatts,
  Value<double?> averageStrokeRate,
  Value<int> strokeCount,
  Value<int?> templateId,
  Value<String?> templateName,
  Value<int?> courseVersionId,
  Value<int?> plannedLaps,
  Value<bool> imported,
  Value<int?> averageHeartRate,
  Value<int?> maxHeartRate,
  Value<int?> rmssdMs,
  Value<int> pauseCount,
  Value<int> pausedMs,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  Value<SessionStatus> status,
  Value<ErgSourceKind> source,
  Value<String?> deviceName,
  Value<ErgProtocol> protocol,
  Value<int> durationMs,
  Value<int> distanceDm,
  Value<int?> averagePaceCs,
  Value<int?> averageWatts,
  Value<double?> averageStrokeRate,
  Value<int> strokeCount,
  Value<int?> templateId,
  Value<String?> templateName,
  Value<int?> courseVersionId,
  Value<int?> plannedLaps,
  Value<bool> imported,
  Value<int?> averageHeartRate,
  Value<int?> maxHeartRate,
  Value<int?> rmssdMs,
  Value<int> pauseCount,
  Value<int> pausedMs,
});

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, SessionRow> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TemplatesTable _templateIdTable(_$AppDatabase db) =>
      db.templates.createAlias('sessions__template_id__templates__id');

  $$TemplatesTableProcessedTableManager? get templateId {
    final $_column = $_itemColumn<int>('template_id');
    if ($_column == null) return null;
    final manager = $$TemplatesTableTableManager(
      $_db,
      $_db.templates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CourseVersionsTable _courseVersionIdTable(_$AppDatabase db) => db
      .courseVersions
      .createAlias('sessions__course_version_id__course_versions__id');

  $$CourseVersionsTableProcessedTableManager? get courseVersionId {
    final $_column = $_itemColumn<int>('course_version_id');
    if ($_column == null) return null;
    final manager = $$CourseVersionsTableTableManager(
      $_db,
      $_db.courseVersions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseVersionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

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

  static MultiTypedResultKey<$LapsTable, List<LapRow>> _lapsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.laps,
    aliasName: 'sessions__id__laps__session_id',
  );

  $$LapsTableProcessedTableManager get lapsRefs {
    final manager = $$LapsTableTableManager(
      $_db,
      $_db.laps,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_lapsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LapSegmentsTable, List<LapSegmentRow>>
  _lapSegmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.lapSegments,
    aliasName: 'sessions__id__lap_segments__session_id',
  );

  $$LapSegmentsTableProcessedTableManager get lapSegmentsRefs {
    final manager = $$LapSegmentsTableTableManager(
      $_db,
      $_db.lapSegments,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_lapSegmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RrIntervalsTable, List<RrIntervalRow>>
  _rrIntervalsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.rrIntervals,
    aliasName: 'sessions__id__rr_intervals__session_id',
  );

  $$RrIntervalsTableProcessedTableManager get rrIntervalsRefs {
    final manager = $$RrIntervalsTableTableManager(
      $_db,
      $_db.rrIntervals,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_rrIntervalsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PausesTable, List<PauseRow>> _pausesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.pauses,
    aliasName: 'sessions__id__pauses__session_id',
  );

  $$PausesTableProcessedTableManager get pausesRefs {
    final manager = $$PausesTableTableManager(
      $_db,
      $_db.pauses,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_pausesRefsTable($_db));
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

  ColumnWithTypeConverterFilters<ErgProtocol, ErgProtocol, String>
  get protocol => $composableBuilder(
    column: $table.protocol,
    builder: (column) => ColumnWithTypeConverterFilters(column),
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

  ColumnFilters<String> get templateName => $composableBuilder(
    column: $table.templateName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedLaps => $composableBuilder(
    column: $table.plannedLaps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get imported => $composableBuilder(
    column: $table.imported,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get averageHeartRate => $composableBuilder(
    column: $table.averageHeartRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxHeartRate => $composableBuilder(
    column: $table.maxHeartRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rmssdMs => $composableBuilder(
    column: $table.rmssdMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pauseCount => $composableBuilder(
    column: $table.pauseCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pausedMs => $composableBuilder(
    column: $table.pausedMs,
    builder: (column) => ColumnFilters(column),
  );

  $$TemplatesTableFilterComposer get templateId {
    final $$TemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplatesTableFilterComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CourseVersionsTableFilterComposer get courseVersionId {
    final $$CourseVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseVersionId,
      referencedTable: $db.courseVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseVersionsTableFilterComposer(
            $db: $db,
            $table: $db.courseVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

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

  Expression<bool> lapsRefs(
    Expression<bool> Function($$LapsTableFilterComposer f) f,
  ) {
    final $$LapsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.laps,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LapsTableFilterComposer(
            $db: $db,
            $table: $db.laps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> lapSegmentsRefs(
    Expression<bool> Function($$LapSegmentsTableFilterComposer f) f,
  ) {
    final $$LapSegmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lapSegments,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LapSegmentsTableFilterComposer(
            $db: $db,
            $table: $db.lapSegments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> rrIntervalsRefs(
    Expression<bool> Function($$RrIntervalsTableFilterComposer f) f,
  ) {
    final $$RrIntervalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rrIntervals,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RrIntervalsTableFilterComposer(
            $db: $db,
            $table: $db.rrIntervals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pausesRefs(
    Expression<bool> Function($$PausesTableFilterComposer f) f,
  ) {
    final $$PausesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pauses,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PausesTableFilterComposer(
            $db: $db,
            $table: $db.pauses,
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

  ColumnOrderings<String> get protocol => $composableBuilder(
    column: $table.protocol,
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

  ColumnOrderings<String> get templateName => $composableBuilder(
    column: $table.templateName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedLaps => $composableBuilder(
    column: $table.plannedLaps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get imported => $composableBuilder(
    column: $table.imported,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get averageHeartRate => $composableBuilder(
    column: $table.averageHeartRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxHeartRate => $composableBuilder(
    column: $table.maxHeartRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rmssdMs => $composableBuilder(
    column: $table.rmssdMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pauseCount => $composableBuilder(
    column: $table.pauseCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pausedMs => $composableBuilder(
    column: $table.pausedMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$TemplatesTableOrderingComposer get templateId {
    final $$TemplatesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplatesTableOrderingComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CourseVersionsTableOrderingComposer get courseVersionId {
    final $$CourseVersionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseVersionId,
      referencedTable: $db.courseVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseVersionsTableOrderingComposer(
            $db: $db,
            $table: $db.courseVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  GeneratedColumnWithTypeConverter<ErgProtocol, String> get protocol =>
      $composableBuilder(column: $table.protocol, builder: (column) => column);

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

  GeneratedColumn<String> get templateName => $composableBuilder(
    column: $table.templateName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get plannedLaps => $composableBuilder(
    column: $table.plannedLaps,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get imported =>
      $composableBuilder(column: $table.imported, builder: (column) => column);

  GeneratedColumn<int> get averageHeartRate => $composableBuilder(
    column: $table.averageHeartRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxHeartRate => $composableBuilder(
    column: $table.maxHeartRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rmssdMs =>
      $composableBuilder(column: $table.rmssdMs, builder: (column) => column);

  GeneratedColumn<int> get pauseCount => $composableBuilder(
    column: $table.pauseCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pausedMs =>
      $composableBuilder(column: $table.pausedMs, builder: (column) => column);

  $$TemplatesTableAnnotationComposer get templateId {
    final $$TemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CourseVersionsTableAnnotationComposer get courseVersionId {
    final $$CourseVersionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseVersionId,
      referencedTable: $db.courseVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseVersionsTableAnnotationComposer(
            $db: $db,
            $table: $db.courseVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

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

  Expression<T> lapsRefs<T extends Object>(
    Expression<T> Function($$LapsTableAnnotationComposer a) f,
  ) {
    final $$LapsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.laps,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LapsTableAnnotationComposer(
            $db: $db,
            $table: $db.laps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> lapSegmentsRefs<T extends Object>(
    Expression<T> Function($$LapSegmentsTableAnnotationComposer a) f,
  ) {
    final $$LapSegmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lapSegments,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LapSegmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.lapSegments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> rrIntervalsRefs<T extends Object>(
    Expression<T> Function($$RrIntervalsTableAnnotationComposer a) f,
  ) {
    final $$RrIntervalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rrIntervals,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RrIntervalsTableAnnotationComposer(
            $db: $db,
            $table: $db.rrIntervals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pausesRefs<T extends Object>(
    Expression<T> Function($$PausesTableAnnotationComposer a) f,
  ) {
    final $$PausesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pauses,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PausesTableAnnotationComposer(
            $db: $db,
            $table: $db.pauses,
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
            bool templateId,
            bool courseVersionId,
            bool samplesRefs,
            bool strokesRefs,
            bool rawPacketsRefs,
            bool lapsRefs,
            bool lapSegmentsRefs,
            bool rrIntervalsRefs,
            bool pausesRefs,
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
                Value<ErgProtocol> protocol = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int> distanceDm = const Value.absent(),
                Value<int?> averagePaceCs = const Value.absent(),
                Value<int?> averageWatts = const Value.absent(),
                Value<double?> averageStrokeRate = const Value.absent(),
                Value<int> strokeCount = const Value.absent(),
                Value<int?> templateId = const Value.absent(),
                Value<String?> templateName = const Value.absent(),
                Value<int?> courseVersionId = const Value.absent(),
                Value<int?> plannedLaps = const Value.absent(),
                Value<bool> imported = const Value.absent(),
                Value<int?> averageHeartRate = const Value.absent(),
                Value<int?> maxHeartRate = const Value.absent(),
                Value<int?> rmssdMs = const Value.absent(),
                Value<int> pauseCount = const Value.absent(),
                Value<int> pausedMs = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                status: status,
                source: source,
                deviceName: deviceName,
                protocol: protocol,
                durationMs: durationMs,
                distanceDm: distanceDm,
                averagePaceCs: averagePaceCs,
                averageWatts: averageWatts,
                averageStrokeRate: averageStrokeRate,
                strokeCount: strokeCount,
                templateId: templateId,
                templateName: templateName,
                courseVersionId: courseVersionId,
                plannedLaps: plannedLaps,
                imported: imported,
                averageHeartRate: averageHeartRate,
                maxHeartRate: maxHeartRate,
                rmssdMs: rmssdMs,
                pauseCount: pauseCount,
                pausedMs: pausedMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                required SessionStatus status,
                required ErgSourceKind source,
                Value<String?> deviceName = const Value.absent(),
                Value<ErgProtocol> protocol = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int> distanceDm = const Value.absent(),
                Value<int?> averagePaceCs = const Value.absent(),
                Value<int?> averageWatts = const Value.absent(),
                Value<double?> averageStrokeRate = const Value.absent(),
                Value<int> strokeCount = const Value.absent(),
                Value<int?> templateId = const Value.absent(),
                Value<String?> templateName = const Value.absent(),
                Value<int?> courseVersionId = const Value.absent(),
                Value<int?> plannedLaps = const Value.absent(),
                Value<bool> imported = const Value.absent(),
                Value<int?> averageHeartRate = const Value.absent(),
                Value<int?> maxHeartRate = const Value.absent(),
                Value<int?> rmssdMs = const Value.absent(),
                Value<int> pauseCount = const Value.absent(),
                Value<int> pausedMs = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                status: status,
                source: source,
                deviceName: deviceName,
                protocol: protocol,
                durationMs: durationMs,
                distanceDm: distanceDm,
                averagePaceCs: averagePaceCs,
                averageWatts: averageWatts,
                averageStrokeRate: averageStrokeRate,
                strokeCount: strokeCount,
                templateId: templateId,
                templateName: templateName,
                courseVersionId: courseVersionId,
                plannedLaps: plannedLaps,
                imported: imported,
                averageHeartRate: averageHeartRate,
                maxHeartRate: maxHeartRate,
                rmssdMs: rmssdMs,
                pauseCount: pauseCount,
                pausedMs: pausedMs,
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
                templateId = false,
                courseVersionId = false,
                samplesRefs = false,
                strokesRefs = false,
                rawPacketsRefs = false,
                lapsRefs = false,
                lapSegmentsRefs = false,
                rrIntervalsRefs = false,
                pausesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (samplesRefs) db.samples,
                    if (strokesRefs) db.strokes,
                    if (rawPacketsRefs) db.rawPackets,
                    if (lapsRefs) db.laps,
                    if (lapSegmentsRefs) db.lapSegments,
                    if (rrIntervalsRefs) db.rrIntervals,
                    if (pausesRefs) db.pauses,
                  ],
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
                        if (templateId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.templateId,
                            referencedTable: $$SessionsTableReferences
                                ._templateIdTable(db),
                            referencedColumn: $$SessionsTableReferences
                                ._templateIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (courseVersionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.courseVersionId,
                            referencedTable: $$SessionsTableReferences
                                ._courseVersionIdTable(db),
                            referencedColumn: $$SessionsTableReferences
                                ._courseVersionIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (samplesRefs)
                        await $_getPrefetchedDataByColumns<
                          SessionRow,
                          $SessionsTable,
                          SampleRow,
                          $SamplesTable
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
                          currentColumn: 'id',
                          referencedColumn: 'session_id',
                          typedResults: items,
                        ),
                      if (strokesRefs)
                        await $_getPrefetchedDataByColumns<
                          SessionRow,
                          $SessionsTable,
                          StrokeRow,
                          $StrokesTable
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
                          currentColumn: 'id',
                          referencedColumn: 'session_id',
                          typedResults: items,
                        ),
                      if (rawPacketsRefs)
                        await $_getPrefetchedDataByColumns<
                          SessionRow,
                          $SessionsTable,
                          RawPacketRow,
                          $RawPacketsTable
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
                          currentColumn: 'id',
                          referencedColumn: 'session_id',
                          typedResults: items,
                        ),
                      if (lapsRefs)
                        await $_getPrefetchedDataByColumns<
                          SessionRow,
                          $SessionsTable,
                          LapRow,
                          $LapsTable
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._lapsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(db, table, p0).lapsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'session_id',
                          typedResults: items,
                        ),
                      if (lapSegmentsRefs)
                        await $_getPrefetchedDataByColumns<
                          SessionRow,
                          $SessionsTable,
                          LapSegmentRow,
                          $LapSegmentsTable
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._lapSegmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).lapSegmentsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'session_id',
                          typedResults: items,
                        ),
                      if (rrIntervalsRefs)
                        await $_getPrefetchedDataByColumns<
                          SessionRow,
                          $SessionsTable,
                          RrIntervalRow,
                          $RrIntervalsTable
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._rrIntervalsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).rrIntervalsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'session_id',
                          typedResults: items,
                        ),
                      if (pausesRefs)
                        await $_getPrefetchedDataByColumns<
                          SessionRow,
                          $SessionsTable,
                          PauseRow,
                          $PausesTable
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._pausesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).pausesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'session_id',
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
        bool templateId,
        bool courseVersionId,
        bool samplesRefs,
        bool strokesRefs,
        bool rawPacketsRefs,
        bool lapsRefs,
        bool lapSegmentsRefs,
        bool rrIntervalsRefs,
        bool pausesRefs,
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
  Value<int?> wallMs,
  Value<int?> activeMs,
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
  Value<int?> wallMs,
  Value<int?> activeMs,
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

  ColumnFilters<int> get wallMs => $composableBuilder(
    column: $table.wallMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activeMs => $composableBuilder(
    column: $table.activeMs,
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

  ColumnOrderings<int> get wallMs => $composableBuilder(
    column: $table.wallMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activeMs => $composableBuilder(
    column: $table.activeMs,
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

  GeneratedColumn<int> get wallMs =>
      $composableBuilder(column: $table.wallMs, builder: (column) => column);

  GeneratedColumn<int> get activeMs =>
      $composableBuilder(column: $table.activeMs, builder: (column) => column);

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
                Value<int?> wallMs = const Value.absent(),
                Value<int?> activeMs = const Value.absent(),
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
                wallMs: wallMs,
                activeMs: activeMs,
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
                Value<int?> wallMs = const Value.absent(),
                Value<int?> activeMs = const Value.absent(),
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
                wallMs: wallMs,
                activeMs: activeMs,
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
  Value<double?> driveLengthMeters,
  Value<int?> driveTimeMs,
  Value<int?> recoveryTimeMs,
  Value<double?> peakForceNewtons,
  Value<double?> averageForceNewtons,
  Value<int?> watts,
  Value<int> rowid,
});
typedef $$StrokesTableUpdateCompanionBuilder = StrokesCompanion Function({
  Value<int> sessionId,
  Value<int> tMs,
  Value<int> distanceDm,
  Value<int> strokeNumber,
  Value<double?> driveLengthMeters,
  Value<int?> driveTimeMs,
  Value<int?> recoveryTimeMs,
  Value<double?> peakForceNewtons,
  Value<double?> averageForceNewtons,
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
                Value<double?> driveLengthMeters = const Value.absent(),
                Value<int?> driveTimeMs = const Value.absent(),
                Value<int?> recoveryTimeMs = const Value.absent(),
                Value<double?> peakForceNewtons = const Value.absent(),
                Value<double?> averageForceNewtons = const Value.absent(),
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
                Value<double?> driveLengthMeters = const Value.absent(),
                Value<int?> driveTimeMs = const Value.absent(),
                Value<int?> recoveryTimeMs = const Value.absent(),
                Value<double?> peakForceNewtons = const Value.absent(),
                Value<double?> averageForceNewtons = const Value.absent(),
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
typedef $$ZonesTableCreateCompanionBuilder = ZonesCompanion Function({
  Value<int> id,
  required String name,
  required CourseAxis axis,
  required int length,
  Value<int?> paceFastCs,
  Value<int?> paceSlowCs,
  Value<int?> spmMin,
  Value<int?> spmMax,
  Value<DateTime?> deletedAt,
});
typedef $$ZonesTableUpdateCompanionBuilder = ZonesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<CourseAxis> axis,
  Value<int> length,
  Value<int?> paceFastCs,
  Value<int?> paceSlowCs,
  Value<int?> spmMin,
  Value<int?> spmMax,
  Value<DateTime?> deletedAt,
});

final class $$ZonesTableReferences
    extends BaseReferences<_$AppDatabase, $ZonesTable, ZoneRow> {
  $$ZonesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CourseSegmentsTable, List<CourseSegmentRow>>
  _courseSegmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.courseSegments,
    aliasName: 'zones__id__course_segments__zone_id',
  );

  $$CourseSegmentsTableProcessedTableManager get courseSegmentsRefs {
    final manager = $$CourseSegmentsTableTableManager(
      $_db,
      $_db.courseSegments,
    ).filter((f) => f.zoneId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_courseSegmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ZonesTableFilterComposer extends Composer<_$AppDatabase, $ZonesTable> {
  $$ZonesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CourseAxis, CourseAxis, String> get axis =>
      $composableBuilder(
        column: $table.axis,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get length => $composableBuilder(
    column: $table.length,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paceFastCs => $composableBuilder(
    column: $table.paceFastCs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paceSlowCs => $composableBuilder(
    column: $table.paceSlowCs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get spmMin => $composableBuilder(
    column: $table.spmMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get spmMax => $composableBuilder(
    column: $table.spmMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> courseSegmentsRefs(
    Expression<bool> Function($$CourseSegmentsTableFilterComposer f) f,
  ) {
    final $$CourseSegmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseSegments,
      getReferencedColumn: (t) => t.zoneId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseSegmentsTableFilterComposer(
            $db: $db,
            $table: $db.courseSegments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ZonesTableOrderingComposer
    extends Composer<_$AppDatabase, $ZonesTable> {
  $$ZonesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get axis => $composableBuilder(
    column: $table.axis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get length => $composableBuilder(
    column: $table.length,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paceFastCs => $composableBuilder(
    column: $table.paceFastCs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paceSlowCs => $composableBuilder(
    column: $table.paceSlowCs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get spmMin => $composableBuilder(
    column: $table.spmMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get spmMax => $composableBuilder(
    column: $table.spmMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ZonesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ZonesTable> {
  $$ZonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CourseAxis, String> get axis =>
      $composableBuilder(column: $table.axis, builder: (column) => column);

  GeneratedColumn<int> get length =>
      $composableBuilder(column: $table.length, builder: (column) => column);

  GeneratedColumn<int> get paceFastCs => $composableBuilder(
    column: $table.paceFastCs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paceSlowCs => $composableBuilder(
    column: $table.paceSlowCs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get spmMin =>
      $composableBuilder(column: $table.spmMin, builder: (column) => column);

  GeneratedColumn<int> get spmMax =>
      $composableBuilder(column: $table.spmMax, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> courseSegmentsRefs<T extends Object>(
    Expression<T> Function($$CourseSegmentsTableAnnotationComposer a) f,
  ) {
    final $$CourseSegmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseSegments,
      getReferencedColumn: (t) => t.zoneId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseSegmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.courseSegments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ZonesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ZonesTable,
          ZoneRow,
          $$ZonesTableFilterComposer,
          $$ZonesTableOrderingComposer,
          $$ZonesTableAnnotationComposer,
          $$ZonesTableCreateCompanionBuilder,
          $$ZonesTableUpdateCompanionBuilder,
          (ZoneRow, $$ZonesTableReferences),
          ZoneRow,
          PrefetchHooks Function({bool courseSegmentsRefs})
        > {
  $$ZonesTableTableManager(_$AppDatabase db, $ZonesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ZonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ZonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ZonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<CourseAxis> axis = const Value.absent(),
                Value<int> length = const Value.absent(),
                Value<int?> paceFastCs = const Value.absent(),
                Value<int?> paceSlowCs = const Value.absent(),
                Value<int?> spmMin = const Value.absent(),
                Value<int?> spmMax = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => ZonesCompanion(
                id: id,
                name: name,
                axis: axis,
                length: length,
                paceFastCs: paceFastCs,
                paceSlowCs: paceSlowCs,
                spmMin: spmMin,
                spmMax: spmMax,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required CourseAxis axis,
                required int length,
                Value<int?> paceFastCs = const Value.absent(),
                Value<int?> paceSlowCs = const Value.absent(),
                Value<int?> spmMin = const Value.absent(),
                Value<int?> spmMax = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
              }) => ZonesCompanion.insert(
                id: id,
                name: name,
                axis: axis,
                length: length,
                paceFastCs: paceFastCs,
                paceSlowCs: paceSlowCs,
                spmMin: spmMin,
                spmMax: spmMax,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ZonesTable, ZoneRow>(table),
                  $$ZonesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({courseSegmentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (courseSegmentsRefs) db.courseSegments,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (courseSegmentsRefs)
                    await $_getPrefetchedDataByColumns<
                      ZoneRow,
                      $ZonesTable,
                      CourseSegmentRow,
                      $CourseSegmentsTable
                    >(
                      currentTable: table,
                      referencedTable: $$ZonesTableReferences
                          ._courseSegmentsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ZonesTableReferences(
                        db,
                        table,
                        p0,
                      ).courseSegmentsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'zone_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ZonesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ZonesTable,
      ZoneRow,
      $$ZonesTableFilterComposer,
      $$ZonesTableOrderingComposer,
      $$ZonesTableAnnotationComposer,
      $$ZonesTableCreateCompanionBuilder,
      $$ZonesTableUpdateCompanionBuilder,
      (ZoneRow, $$ZonesTableReferences),
      ZoneRow,
      PrefetchHooks Function({bool courseSegmentsRefs})
    >;
typedef $$CourseSegmentsTableCreateCompanionBuilder =
    CourseSegmentsCompanion Function({
      required int versionId,
      required int position,
      required int length,
      Value<int?> paceFastCs,
      Value<int?> paceSlowCs,
      Value<int?> spmMin,
      Value<int?> spmMax,
      Value<int?> zoneId,
      Value<String?> zoneName,
      Value<int> rowid,
    });
typedef $$CourseSegmentsTableUpdateCompanionBuilder =
    CourseSegmentsCompanion Function({
      Value<int> versionId,
      Value<int> position,
      Value<int> length,
      Value<int?> paceFastCs,
      Value<int?> paceSlowCs,
      Value<int?> spmMin,
      Value<int?> spmMax,
      Value<int?> zoneId,
      Value<String?> zoneName,
      Value<int> rowid,
    });

final class $$CourseSegmentsTableReferences
    extends
        BaseReferences<_$AppDatabase, $CourseSegmentsTable, CourseSegmentRow> {
  $$CourseSegmentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CourseVersionsTable _versionIdTable(_$AppDatabase db) => db
      .courseVersions
      .createAlias('course_segments__version_id__course_versions__id');

  $$CourseVersionsTableProcessedTableManager get versionId {
    final $_column = $_itemColumn<int>('version_id')!;

    final manager = $$CourseVersionsTableTableManager(
      $_db,
      $_db.courseVersions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_versionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ZonesTable _zoneIdTable(_$AppDatabase db) =>
      db.zones.createAlias('course_segments__zone_id__zones__id');

  $$ZonesTableProcessedTableManager? get zoneId {
    final $_column = $_itemColumn<int>('zone_id');
    if ($_column == null) return null;
    final manager = $$ZonesTableTableManager(
      $_db,
      $_db.zones,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_zoneIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CourseSegmentsTableFilterComposer
    extends Composer<_$AppDatabase, $CourseSegmentsTable> {
  $$CourseSegmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get length => $composableBuilder(
    column: $table.length,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paceFastCs => $composableBuilder(
    column: $table.paceFastCs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paceSlowCs => $composableBuilder(
    column: $table.paceSlowCs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get spmMin => $composableBuilder(
    column: $table.spmMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get spmMax => $composableBuilder(
    column: $table.spmMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zoneName => $composableBuilder(
    column: $table.zoneName,
    builder: (column) => ColumnFilters(column),
  );

  $$CourseVersionsTableFilterComposer get versionId {
    final $$CourseVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.versionId,
      referencedTable: $db.courseVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseVersionsTableFilterComposer(
            $db: $db,
            $table: $db.courseVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ZonesTableFilterComposer get zoneId {
    final $$ZonesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.zoneId,
      referencedTable: $db.zones,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ZonesTableFilterComposer(
            $db: $db,
            $table: $db.zones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseSegmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $CourseSegmentsTable> {
  $$CourseSegmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get length => $composableBuilder(
    column: $table.length,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paceFastCs => $composableBuilder(
    column: $table.paceFastCs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paceSlowCs => $composableBuilder(
    column: $table.paceSlowCs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get spmMin => $composableBuilder(
    column: $table.spmMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get spmMax => $composableBuilder(
    column: $table.spmMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zoneName => $composableBuilder(
    column: $table.zoneName,
    builder: (column) => ColumnOrderings(column),
  );

  $$CourseVersionsTableOrderingComposer get versionId {
    final $$CourseVersionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.versionId,
      referencedTable: $db.courseVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseVersionsTableOrderingComposer(
            $db: $db,
            $table: $db.courseVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ZonesTableOrderingComposer get zoneId {
    final $$ZonesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.zoneId,
      referencedTable: $db.zones,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ZonesTableOrderingComposer(
            $db: $db,
            $table: $db.zones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseSegmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CourseSegmentsTable> {
  $$CourseSegmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get length =>
      $composableBuilder(column: $table.length, builder: (column) => column);

  GeneratedColumn<int> get paceFastCs => $composableBuilder(
    column: $table.paceFastCs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paceSlowCs => $composableBuilder(
    column: $table.paceSlowCs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get spmMin =>
      $composableBuilder(column: $table.spmMin, builder: (column) => column);

  GeneratedColumn<int> get spmMax =>
      $composableBuilder(column: $table.spmMax, builder: (column) => column);

  GeneratedColumn<String> get zoneName =>
      $composableBuilder(column: $table.zoneName, builder: (column) => column);

  $$CourseVersionsTableAnnotationComposer get versionId {
    final $$CourseVersionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.versionId,
      referencedTable: $db.courseVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseVersionsTableAnnotationComposer(
            $db: $db,
            $table: $db.courseVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ZonesTableAnnotationComposer get zoneId {
    final $$ZonesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.zoneId,
      referencedTable: $db.zones,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ZonesTableAnnotationComposer(
            $db: $db,
            $table: $db.zones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CourseSegmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CourseSegmentsTable,
          CourseSegmentRow,
          $$CourseSegmentsTableFilterComposer,
          $$CourseSegmentsTableOrderingComposer,
          $$CourseSegmentsTableAnnotationComposer,
          $$CourseSegmentsTableCreateCompanionBuilder,
          $$CourseSegmentsTableUpdateCompanionBuilder,
          (CourseSegmentRow, $$CourseSegmentsTableReferences),
          CourseSegmentRow,
          PrefetchHooks Function({bool versionId, bool zoneId})
        > {
  $$CourseSegmentsTableTableManager(
    _$AppDatabase db,
    $CourseSegmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CourseSegmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CourseSegmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CourseSegmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> versionId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> length = const Value.absent(),
                Value<int?> paceFastCs = const Value.absent(),
                Value<int?> paceSlowCs = const Value.absent(),
                Value<int?> spmMin = const Value.absent(),
                Value<int?> spmMax = const Value.absent(),
                Value<int?> zoneId = const Value.absent(),
                Value<String?> zoneName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourseSegmentsCompanion(
                versionId: versionId,
                position: position,
                length: length,
                paceFastCs: paceFastCs,
                paceSlowCs: paceSlowCs,
                spmMin: spmMin,
                spmMax: spmMax,
                zoneId: zoneId,
                zoneName: zoneName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int versionId,
                required int position,
                required int length,
                Value<int?> paceFastCs = const Value.absent(),
                Value<int?> paceSlowCs = const Value.absent(),
                Value<int?> spmMin = const Value.absent(),
                Value<int?> spmMax = const Value.absent(),
                Value<int?> zoneId = const Value.absent(),
                Value<String?> zoneName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourseSegmentsCompanion.insert(
                versionId: versionId,
                position: position,
                length: length,
                paceFastCs: paceFastCs,
                paceSlowCs: paceSlowCs,
                spmMin: spmMin,
                spmMax: spmMax,
                zoneId: zoneId,
                zoneName: zoneName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CourseSegmentsTable, CourseSegmentRow>(table),
                  $$CourseSegmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({versionId = false, zoneId = false}) {
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
                    if (versionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.versionId,
                        referencedTable: $$CourseSegmentsTableReferences
                            ._versionIdTable(db),
                        referencedColumn: $$CourseSegmentsTableReferences
                            ._versionIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (zoneId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.zoneId,
                        referencedTable: $$CourseSegmentsTableReferences
                            ._zoneIdTable(db),
                        referencedColumn: $$CourseSegmentsTableReferences
                            ._zoneIdTable(db)
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

typedef $$CourseSegmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CourseSegmentsTable,
      CourseSegmentRow,
      $$CourseSegmentsTableFilterComposer,
      $$CourseSegmentsTableOrderingComposer,
      $$CourseSegmentsTableAnnotationComposer,
      $$CourseSegmentsTableCreateCompanionBuilder,
      $$CourseSegmentsTableUpdateCompanionBuilder,
      (CourseSegmentRow, $$CourseSegmentsTableReferences),
      CourseSegmentRow,
      PrefetchHooks Function({bool versionId, bool zoneId})
    >;
typedef $$TemplateBlocksTableCreateCompanionBuilder =
    TemplateBlocksCompanion Function({
      required int templateId,
      required int position,
      required int courseId,
      Value<int?> laps,
      Value<int> rowid,
    });
typedef $$TemplateBlocksTableUpdateCompanionBuilder =
    TemplateBlocksCompanion Function({
      Value<int> templateId,
      Value<int> position,
      Value<int> courseId,
      Value<int?> laps,
      Value<int> rowid,
    });

final class $$TemplateBlocksTableReferences
    extends
        BaseReferences<_$AppDatabase, $TemplateBlocksTable, TemplateBlockRow> {
  $$TemplateBlocksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TemplatesTable _templateIdTable(_$AppDatabase db) =>
      db.templates.createAlias('template_blocks__template_id__templates__id');

  $$TemplatesTableProcessedTableManager get templateId {
    final $_column = $_itemColumn<int>('template_id')!;

    final manager = $$TemplatesTableTableManager(
      $_db,
      $_db.templates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CoursesTable _courseIdTable(_$AppDatabase db) =>
      db.courses.createAlias('template_blocks__course_id__courses__id');

  $$CoursesTableProcessedTableManager get courseId {
    final $_column = $_itemColumn<int>('course_id')!;

    final manager = $$CoursesTableTableManager(
      $_db,
      $_db.courses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TemplateBlocksTableFilterComposer
    extends Composer<_$AppDatabase, $TemplateBlocksTable> {
  $$TemplateBlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get laps => $composableBuilder(
    column: $table.laps,
    builder: (column) => ColumnFilters(column),
  );

  $$TemplatesTableFilterComposer get templateId {
    final $$TemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplatesTableFilterComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CoursesTableFilterComposer get courseId {
    final $$CoursesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableFilterComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplateBlocksTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplateBlocksTable> {
  $$TemplateBlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get laps => $composableBuilder(
    column: $table.laps,
    builder: (column) => ColumnOrderings(column),
  );

  $$TemplatesTableOrderingComposer get templateId {
    final $$TemplatesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplatesTableOrderingComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CoursesTableOrderingComposer get courseId {
    final $$CoursesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableOrderingComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplateBlocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplateBlocksTable> {
  $$TemplateBlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get laps =>
      $composableBuilder(column: $table.laps, builder: (column) => column);

  $$TemplatesTableAnnotationComposer get templateId {
    final $$TemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CoursesTableAnnotationComposer get courseId {
    final $$CoursesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableAnnotationComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplateBlocksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplateBlocksTable,
          TemplateBlockRow,
          $$TemplateBlocksTableFilterComposer,
          $$TemplateBlocksTableOrderingComposer,
          $$TemplateBlocksTableAnnotationComposer,
          $$TemplateBlocksTableCreateCompanionBuilder,
          $$TemplateBlocksTableUpdateCompanionBuilder,
          (TemplateBlockRow, $$TemplateBlocksTableReferences),
          TemplateBlockRow,
          PrefetchHooks Function({bool templateId, bool courseId})
        > {
  $$TemplateBlocksTableTableManager(
    _$AppDatabase db,
    $TemplateBlocksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplateBlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplateBlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplateBlocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> templateId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> courseId = const Value.absent(),
                Value<int?> laps = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplateBlocksCompanion(
                templateId: templateId,
                position: position,
                courseId: courseId,
                laps: laps,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int templateId,
                required int position,
                required int courseId,
                Value<int?> laps = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplateBlocksCompanion.insert(
                templateId: templateId,
                position: position,
                courseId: courseId,
                laps: laps,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TemplateBlocksTable, TemplateBlockRow>(table),
                  $$TemplateBlocksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({templateId = false, courseId = false}) {
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
                    if (templateId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.templateId,
                        referencedTable: $$TemplateBlocksTableReferences
                            ._templateIdTable(db),
                        referencedColumn: $$TemplateBlocksTableReferences
                            ._templateIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (courseId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.courseId,
                        referencedTable: $$TemplateBlocksTableReferences
                            ._courseIdTable(db),
                        referencedColumn: $$TemplateBlocksTableReferences
                            ._courseIdTable(db)
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

typedef $$TemplateBlocksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplateBlocksTable,
      TemplateBlockRow,
      $$TemplateBlocksTableFilterComposer,
      $$TemplateBlocksTableOrderingComposer,
      $$TemplateBlocksTableAnnotationComposer,
      $$TemplateBlocksTableCreateCompanionBuilder,
      $$TemplateBlocksTableUpdateCompanionBuilder,
      (TemplateBlockRow, $$TemplateBlocksTableReferences),
      TemplateBlockRow,
      PrefetchHooks Function({bool templateId, bool courseId})
    >;
typedef $$LapsTableCreateCompanionBuilder = LapsCompanion Function({
  required int sessionId,
  required int lapNo,
  required int startWallMs,
  required int endWallMs,
  required int startDistanceDm,
  required int endDistanceDm,
  required bool complete,
  Value<double?> inZoneShare,
  Value<int> rowid,
});
typedef $$LapsTableUpdateCompanionBuilder = LapsCompanion Function({
  Value<int> sessionId,
  Value<int> lapNo,
  Value<int> startWallMs,
  Value<int> endWallMs,
  Value<int> startDistanceDm,
  Value<int> endDistanceDm,
  Value<bool> complete,
  Value<double?> inZoneShare,
  Value<int> rowid,
});

final class $$LapsTableReferences
    extends BaseReferences<_$AppDatabase, $LapsTable, LapRow> {
  $$LapsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('laps__session_id__sessions__id');

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

class $$LapsTableFilterComposer extends Composer<_$AppDatabase, $LapsTable> {
  $$LapsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get lapNo => $composableBuilder(
    column: $table.lapNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startWallMs => $composableBuilder(
    column: $table.startWallMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endWallMs => $composableBuilder(
    column: $table.endWallMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startDistanceDm => $composableBuilder(
    column: $table.startDistanceDm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endDistanceDm => $composableBuilder(
    column: $table.endDistanceDm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get complete => $composableBuilder(
    column: $table.complete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get inZoneShare => $composableBuilder(
    column: $table.inZoneShare,
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

class $$LapsTableOrderingComposer extends Composer<_$AppDatabase, $LapsTable> {
  $$LapsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get lapNo => $composableBuilder(
    column: $table.lapNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startWallMs => $composableBuilder(
    column: $table.startWallMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endWallMs => $composableBuilder(
    column: $table.endWallMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startDistanceDm => $composableBuilder(
    column: $table.startDistanceDm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endDistanceDm => $composableBuilder(
    column: $table.endDistanceDm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get complete => $composableBuilder(
    column: $table.complete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get inZoneShare => $composableBuilder(
    column: $table.inZoneShare,
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

class $$LapsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LapsTable> {
  $$LapsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get lapNo =>
      $composableBuilder(column: $table.lapNo, builder: (column) => column);

  GeneratedColumn<int> get startWallMs => $composableBuilder(
    column: $table.startWallMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endWallMs =>
      $composableBuilder(column: $table.endWallMs, builder: (column) => column);

  GeneratedColumn<int> get startDistanceDm => $composableBuilder(
    column: $table.startDistanceDm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endDistanceDm => $composableBuilder(
    column: $table.endDistanceDm,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get complete =>
      $composableBuilder(column: $table.complete, builder: (column) => column);

  GeneratedColumn<double> get inZoneShare => $composableBuilder(
    column: $table.inZoneShare,
    builder: (column) => column,
  );

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

class $$LapsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LapsTable,
          LapRow,
          $$LapsTableFilterComposer,
          $$LapsTableOrderingComposer,
          $$LapsTableAnnotationComposer,
          $$LapsTableCreateCompanionBuilder,
          $$LapsTableUpdateCompanionBuilder,
          (LapRow, $$LapsTableReferences),
          LapRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$LapsTableTableManager(_$AppDatabase db, $LapsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LapsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LapsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LapsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sessionId = const Value.absent(),
                Value<int> lapNo = const Value.absent(),
                Value<int> startWallMs = const Value.absent(),
                Value<int> endWallMs = const Value.absent(),
                Value<int> startDistanceDm = const Value.absent(),
                Value<int> endDistanceDm = const Value.absent(),
                Value<bool> complete = const Value.absent(),
                Value<double?> inZoneShare = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LapsCompanion(
                sessionId: sessionId,
                lapNo: lapNo,
                startWallMs: startWallMs,
                endWallMs: endWallMs,
                startDistanceDm: startDistanceDm,
                endDistanceDm: endDistanceDm,
                complete: complete,
                inZoneShare: inZoneShare,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sessionId,
                required int lapNo,
                required int startWallMs,
                required int endWallMs,
                required int startDistanceDm,
                required int endDistanceDm,
                required bool complete,
                Value<double?> inZoneShare = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LapsCompanion.insert(
                sessionId: sessionId,
                lapNo: lapNo,
                startWallMs: startWallMs,
                endWallMs: endWallMs,
                startDistanceDm: startDistanceDm,
                endDistanceDm: endDistanceDm,
                complete: complete,
                inZoneShare: inZoneShare,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LapsTable, LapRow>(table),
                  $$LapsTableReferences(db, table, e),
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
                        referencedTable: $$LapsTableReferences._sessionIdTable(
                          db,
                        ),
                        referencedColumn: $$LapsTableReferences
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

typedef $$LapsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LapsTable,
      LapRow,
      $$LapsTableFilterComposer,
      $$LapsTableOrderingComposer,
      $$LapsTableAnnotationComposer,
      $$LapsTableCreateCompanionBuilder,
      $$LapsTableUpdateCompanionBuilder,
      (LapRow, $$LapsTableReferences),
      LapRow,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$LapSegmentsTableCreateCompanionBuilder =
    LapSegmentsCompanion Function({
      required int sessionId,
      required int lapNo,
      required int position,
      required int durationMs,
      required int distanceDm,
      Value<double?> inZoneShare,
      Value<int> rowid,
    });
typedef $$LapSegmentsTableUpdateCompanionBuilder =
    LapSegmentsCompanion Function({
      Value<int> sessionId,
      Value<int> lapNo,
      Value<int> position,
      Value<int> durationMs,
      Value<int> distanceDm,
      Value<double?> inZoneShare,
      Value<int> rowid,
    });

final class $$LapSegmentsTableReferences
    extends BaseReferences<_$AppDatabase, $LapSegmentsTable, LapSegmentRow> {
  $$LapSegmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('lap_segments__session_id__sessions__id');

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

class $$LapSegmentsTableFilterComposer
    extends Composer<_$AppDatabase, $LapSegmentsTable> {
  $$LapSegmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get lapNo => $composableBuilder(
    column: $table.lapNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
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

  ColumnFilters<double> get inZoneShare => $composableBuilder(
    column: $table.inZoneShare,
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

class $$LapSegmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $LapSegmentsTable> {
  $$LapSegmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get lapNo => $composableBuilder(
    column: $table.lapNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
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

  ColumnOrderings<double> get inZoneShare => $composableBuilder(
    column: $table.inZoneShare,
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

class $$LapSegmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LapSegmentsTable> {
  $$LapSegmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get lapNo =>
      $composableBuilder(column: $table.lapNo, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get distanceDm => $composableBuilder(
    column: $table.distanceDm,
    builder: (column) => column,
  );

  GeneratedColumn<double> get inZoneShare => $composableBuilder(
    column: $table.inZoneShare,
    builder: (column) => column,
  );

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

class $$LapSegmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LapSegmentsTable,
          LapSegmentRow,
          $$LapSegmentsTableFilterComposer,
          $$LapSegmentsTableOrderingComposer,
          $$LapSegmentsTableAnnotationComposer,
          $$LapSegmentsTableCreateCompanionBuilder,
          $$LapSegmentsTableUpdateCompanionBuilder,
          (LapSegmentRow, $$LapSegmentsTableReferences),
          LapSegmentRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$LapSegmentsTableTableManager(_$AppDatabase db, $LapSegmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LapSegmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LapSegmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LapSegmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sessionId = const Value.absent(),
                Value<int> lapNo = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int> distanceDm = const Value.absent(),
                Value<double?> inZoneShare = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LapSegmentsCompanion(
                sessionId: sessionId,
                lapNo: lapNo,
                position: position,
                durationMs: durationMs,
                distanceDm: distanceDm,
                inZoneShare: inZoneShare,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sessionId,
                required int lapNo,
                required int position,
                required int durationMs,
                required int distanceDm,
                Value<double?> inZoneShare = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LapSegmentsCompanion.insert(
                sessionId: sessionId,
                lapNo: lapNo,
                position: position,
                durationMs: durationMs,
                distanceDm: distanceDm,
                inZoneShare: inZoneShare,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LapSegmentsTable, LapSegmentRow>(table),
                  $$LapSegmentsTableReferences(db, table, e),
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
                        referencedTable: $$LapSegmentsTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$LapSegmentsTableReferences
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

typedef $$LapSegmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LapSegmentsTable,
      LapSegmentRow,
      $$LapSegmentsTableFilterComposer,
      $$LapSegmentsTableOrderingComposer,
      $$LapSegmentsTableAnnotationComposer,
      $$LapSegmentsTableCreateCompanionBuilder,
      $$LapSegmentsTableUpdateCompanionBuilder,
      (LapSegmentRow, $$LapSegmentsTableReferences),
      LapSegmentRow,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$RrIntervalsTableCreateCompanionBuilder =
    RrIntervalsCompanion Function({
      required int sessionId,
      required int tMs,
      required int rrMs,
      Value<int> rowid,
    });
typedef $$RrIntervalsTableUpdateCompanionBuilder =
    RrIntervalsCompanion Function({
      Value<int> sessionId,
      Value<int> tMs,
      Value<int> rrMs,
      Value<int> rowid,
    });

final class $$RrIntervalsTableReferences
    extends BaseReferences<_$AppDatabase, $RrIntervalsTable, RrIntervalRow> {
  $$RrIntervalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('rr_intervals__session_id__sessions__id');

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

class $$RrIntervalsTableFilterComposer
    extends Composer<_$AppDatabase, $RrIntervalsTable> {
  $$RrIntervalsTableFilterComposer({
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

  ColumnFilters<int> get rrMs => $composableBuilder(
    column: $table.rrMs,
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

class $$RrIntervalsTableOrderingComposer
    extends Composer<_$AppDatabase, $RrIntervalsTable> {
  $$RrIntervalsTableOrderingComposer({
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

  ColumnOrderings<int> get rrMs => $composableBuilder(
    column: $table.rrMs,
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

class $$RrIntervalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RrIntervalsTable> {
  $$RrIntervalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get tMs =>
      $composableBuilder(column: $table.tMs, builder: (column) => column);

  GeneratedColumn<int> get rrMs =>
      $composableBuilder(column: $table.rrMs, builder: (column) => column);

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

class $$RrIntervalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RrIntervalsTable,
          RrIntervalRow,
          $$RrIntervalsTableFilterComposer,
          $$RrIntervalsTableOrderingComposer,
          $$RrIntervalsTableAnnotationComposer,
          $$RrIntervalsTableCreateCompanionBuilder,
          $$RrIntervalsTableUpdateCompanionBuilder,
          (RrIntervalRow, $$RrIntervalsTableReferences),
          RrIntervalRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$RrIntervalsTableTableManager(_$AppDatabase db, $RrIntervalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RrIntervalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RrIntervalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RrIntervalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sessionId = const Value.absent(),
                Value<int> tMs = const Value.absent(),
                Value<int> rrMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RrIntervalsCompanion(
                sessionId: sessionId,
                tMs: tMs,
                rrMs: rrMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sessionId,
                required int tMs,
                required int rrMs,
                Value<int> rowid = const Value.absent(),
              }) => RrIntervalsCompanion.insert(
                sessionId: sessionId,
                tMs: tMs,
                rrMs: rrMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RrIntervalsTable, RrIntervalRow>(table),
                  $$RrIntervalsTableReferences(db, table, e),
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
                        referencedTable: $$RrIntervalsTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$RrIntervalsTableReferences
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

typedef $$RrIntervalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RrIntervalsTable,
      RrIntervalRow,
      $$RrIntervalsTableFilterComposer,
      $$RrIntervalsTableOrderingComposer,
      $$RrIntervalsTableAnnotationComposer,
      $$RrIntervalsTableCreateCompanionBuilder,
      $$RrIntervalsTableUpdateCompanionBuilder,
      (RrIntervalRow, $$RrIntervalsTableReferences),
      RrIntervalRow,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$PausesTableCreateCompanionBuilder = PausesCompanion Function({
  required int sessionId,
  required int startWallMs,
  required int endWallMs,
  Value<int> rowid,
});
typedef $$PausesTableUpdateCompanionBuilder = PausesCompanion Function({
  Value<int> sessionId,
  Value<int> startWallMs,
  Value<int> endWallMs,
  Value<int> rowid,
});

final class $$PausesTableReferences
    extends BaseReferences<_$AppDatabase, $PausesTable, PauseRow> {
  $$PausesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('pauses__session_id__sessions__id');

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

class $$PausesTableFilterComposer
    extends Composer<_$AppDatabase, $PausesTable> {
  $$PausesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get startWallMs => $composableBuilder(
    column: $table.startWallMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endWallMs => $composableBuilder(
    column: $table.endWallMs,
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

class $$PausesTableOrderingComposer
    extends Composer<_$AppDatabase, $PausesTable> {
  $$PausesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get startWallMs => $composableBuilder(
    column: $table.startWallMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endWallMs => $composableBuilder(
    column: $table.endWallMs,
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

class $$PausesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PausesTable> {
  $$PausesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get startWallMs => $composableBuilder(
    column: $table.startWallMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endWallMs =>
      $composableBuilder(column: $table.endWallMs, builder: (column) => column);

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

class $$PausesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PausesTable,
          PauseRow,
          $$PausesTableFilterComposer,
          $$PausesTableOrderingComposer,
          $$PausesTableAnnotationComposer,
          $$PausesTableCreateCompanionBuilder,
          $$PausesTableUpdateCompanionBuilder,
          (PauseRow, $$PausesTableReferences),
          PauseRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$PausesTableTableManager(_$AppDatabase db, $PausesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PausesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PausesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PausesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sessionId = const Value.absent(),
                Value<int> startWallMs = const Value.absent(),
                Value<int> endWallMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PausesCompanion(
                sessionId: sessionId,
                startWallMs: startWallMs,
                endWallMs: endWallMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sessionId,
                required int startWallMs,
                required int endWallMs,
                Value<int> rowid = const Value.absent(),
              }) => PausesCompanion.insert(
                sessionId: sessionId,
                startWallMs: startWallMs,
                endWallMs: endWallMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PausesTable, PauseRow>(table),
                  $$PausesTableReferences(db, table, e),
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
                        referencedTable: $$PausesTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$PausesTableReferences
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

typedef $$PausesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PausesTable,
      PauseRow,
      $$PausesTableFilterComposer,
      $$PausesTableOrderingComposer,
      $$PausesTableAnnotationComposer,
      $$PausesTableCreateCompanionBuilder,
      $$PausesTableUpdateCompanionBuilder,
      (PauseRow, $$PausesTableReferences),
      PauseRow,
      PrefetchHooks Function({bool sessionId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TemplatesTableTableManager get templates =>
      $$TemplatesTableTableManager(_db, _db.templates);
  $$CoursesTableTableManager get courses =>
      $$CoursesTableTableManager(_db, _db.courses);
  $$CourseVersionsTableTableManager get courseVersions =>
      $$CourseVersionsTableTableManager(_db, _db.courseVersions);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$SamplesTableTableManager get samples =>
      $$SamplesTableTableManager(_db, _db.samples);
  $$StrokesTableTableManager get strokes =>
      $$StrokesTableTableManager(_db, _db.strokes);
  $$RawPacketsTableTableManager get rawPackets =>
      $$RawPacketsTableTableManager(_db, _db.rawPackets);
  $$ZonesTableTableManager get zones =>
      $$ZonesTableTableManager(_db, _db.zones);
  $$CourseSegmentsTableTableManager get courseSegments =>
      $$CourseSegmentsTableTableManager(_db, _db.courseSegments);
  $$TemplateBlocksTableTableManager get templateBlocks =>
      $$TemplateBlocksTableTableManager(_db, _db.templateBlocks);
  $$LapsTableTableManager get laps => $$LapsTableTableManager(_db, _db.laps);
  $$LapSegmentsTableTableManager get lapSegments =>
      $$LapSegmentsTableTableManager(_db, _db.lapSegments);
  $$RrIntervalsTableTableManager get rrIntervals =>
      $$RrIntervalsTableTableManager(_db, _db.rrIntervals);
  $$PausesTableTableManager get pauses =>
      $$PausesTableTableManager(_db, _db.pauses);
}
