// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AcademicYearsTableTable extends AcademicYearsTable
    with TableInfo<$AcademicYearsTableTable, AcademicYearsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AcademicYearsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> startDate =
      GeneratedColumn<String>(
        'start_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($AcademicYearsTableTable.$converterstartDate);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> endDate =
      GeneratedColumn<String>(
        'end_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($AcademicYearsTableTable.$converterendDate);
  static const VerificationMeta _totalMandatoryDaysMeta =
      const VerificationMeta('totalMandatoryDays');
  @override
  late final GeneratedColumn<int> totalMandatoryDays = GeneratedColumn<int>(
    'total_mandatory_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(200),
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
    year,
    title,
    startDate,
    endDate,
    totalMandatoryDays,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'academic_years_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AcademicYearsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('total_mandatory_days')) {
      context.handle(
        _totalMandatoryDaysMeta,
        totalMandatoryDays.isAcceptableOrUnknown(
          data['total_mandatory_days']!,
          _totalMandatoryDaysMeta,
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {year},
  ];
  @override
  AcademicYearsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AcademicYearsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      startDate: $AcademicYearsTableTable.$converterstartDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}start_date'],
        )!,
      ),
      endDate: $AcademicYearsTableTable.$converterendDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}end_date'],
        )!,
      ),
      totalMandatoryDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_mandatory_days'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AcademicYearsTableTable createAlias(String alias) {
    return $AcademicYearsTableTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $converterstartDate =
      const CalendarDateConverter();
  static TypeConverter<DateTime, String> $converterendDate =
      const CalendarDateConverter();
}

class AcademicYearsTableData extends DataClass
    implements Insertable<AcademicYearsTableData> {
  final String id;
  final int year;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final int totalMandatoryDays;
  final DateTime createdAt;
  const AcademicYearsTableData({
    required this.id,
    required this.year,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.totalMandatoryDays,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['year'] = Variable<int>(year);
    map['title'] = Variable<String>(title);
    {
      map['start_date'] = Variable<String>(
        $AcademicYearsTableTable.$converterstartDate.toSql(startDate),
      );
    }
    {
      map['end_date'] = Variable<String>(
        $AcademicYearsTableTable.$converterendDate.toSql(endDate),
      );
    }
    map['total_mandatory_days'] = Variable<int>(totalMandatoryDays);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AcademicYearsTableCompanion toCompanion(bool nullToAbsent) {
    return AcademicYearsTableCompanion(
      id: Value(id),
      year: Value(year),
      title: Value(title),
      startDate: Value(startDate),
      endDate: Value(endDate),
      totalMandatoryDays: Value(totalMandatoryDays),
      createdAt: Value(createdAt),
    );
  }

  factory AcademicYearsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AcademicYearsTableData(
      id: serializer.fromJson<String>(json['id']),
      year: serializer.fromJson<int>(json['year']),
      title: serializer.fromJson<String>(json['title']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime>(json['endDate']),
      totalMandatoryDays: serializer.fromJson<int>(json['totalMandatoryDays']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'year': serializer.toJson<int>(year),
      'title': serializer.toJson<String>(title),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime>(endDate),
      'totalMandatoryDays': serializer.toJson<int>(totalMandatoryDays),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AcademicYearsTableData copyWith({
    String? id,
    int? year,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    int? totalMandatoryDays,
    DateTime? createdAt,
  }) => AcademicYearsTableData(
    id: id ?? this.id,
    year: year ?? this.year,
    title: title ?? this.title,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    totalMandatoryDays: totalMandatoryDays ?? this.totalMandatoryDays,
    createdAt: createdAt ?? this.createdAt,
  );
  AcademicYearsTableData copyWithCompanion(AcademicYearsTableCompanion data) {
    return AcademicYearsTableData(
      id: data.id.present ? data.id.value : this.id,
      year: data.year.present ? data.year.value : this.year,
      title: data.title.present ? data.title.value : this.title,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      totalMandatoryDays: data.totalMandatoryDays.present
          ? data.totalMandatoryDays.value
          : this.totalMandatoryDays,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AcademicYearsTableData(')
          ..write('id: $id, ')
          ..write('year: $year, ')
          ..write('title: $title, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('totalMandatoryDays: $totalMandatoryDays, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    year,
    title,
    startDate,
    endDate,
    totalMandatoryDays,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AcademicYearsTableData &&
          other.id == this.id &&
          other.year == this.year &&
          other.title == this.title &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.totalMandatoryDays == this.totalMandatoryDays &&
          other.createdAt == this.createdAt);
}

class AcademicYearsTableCompanion
    extends UpdateCompanion<AcademicYearsTableData> {
  final Value<String> id;
  final Value<int> year;
  final Value<String> title;
  final Value<DateTime> startDate;
  final Value<DateTime> endDate;
  final Value<int> totalMandatoryDays;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AcademicYearsTableCompanion({
    this.id = const Value.absent(),
    this.year = const Value.absent(),
    this.title = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.totalMandatoryDays = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AcademicYearsTableCompanion.insert({
    required String id,
    required int year,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    this.totalMandatoryDays = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       year = Value(year),
       title = Value(title),
       startDate = Value(startDate),
       endDate = Value(endDate),
       createdAt = Value(createdAt);
  static Insertable<AcademicYearsTableData> custom({
    Expression<String>? id,
    Expression<int>? year,
    Expression<String>? title,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<int>? totalMandatoryDays,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (year != null) 'year': year,
      if (title != null) 'title': title,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (totalMandatoryDays != null)
        'total_mandatory_days': totalMandatoryDays,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AcademicYearsTableCompanion copyWith({
    Value<String>? id,
    Value<int>? year,
    Value<String>? title,
    Value<DateTime>? startDate,
    Value<DateTime>? endDate,
    Value<int>? totalMandatoryDays,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AcademicYearsTableCompanion(
      id: id ?? this.id,
      year: year ?? this.year,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalMandatoryDays: totalMandatoryDays ?? this.totalMandatoryDays,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(
        $AcademicYearsTableTable.$converterstartDate.toSql(startDate.value),
      );
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(
        $AcademicYearsTableTable.$converterendDate.toSql(endDate.value),
      );
    }
    if (totalMandatoryDays.present) {
      map['total_mandatory_days'] = Variable<int>(totalMandatoryDays.value);
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
    return (StringBuffer('AcademicYearsTableCompanion(')
          ..write('id: $id, ')
          ..write('year: $year, ')
          ..write('title: $title, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('totalMandatoryDays: $totalMandatoryDays, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClassroomsTableTable extends ClassroomsTable
    with TableInfo<$ClassroomsTableTable, ClassroomsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClassroomsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _academicYearIdMeta = const VerificationMeta(
    'academicYearId',
  );
  @override
  late final GeneratedColumn<String> academicYearId = GeneratedColumn<String>(
    'academic_year_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES academic_years_table (id) ON DELETE RESTRICT',
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
  static const VerificationMeta _gradeLevelMeta = const VerificationMeta(
    'gradeLevel',
  );
  @override
  late final GeneratedColumn<String> gradeLevel = GeneratedColumn<String>(
    'grade_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shiftMeta = const VerificationMeta('shift');
  @override
  late final GeneratedColumn<String> shift = GeneratedColumn<String>(
    'shift',
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
    id,
    academicYearId,
    name,
    gradeLevel,
    shift,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'classrooms_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClassroomsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('academic_year_id')) {
      context.handle(
        _academicYearIdMeta,
        academicYearId.isAcceptableOrUnknown(
          data['academic_year_id']!,
          _academicYearIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_academicYearIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('grade_level')) {
      context.handle(
        _gradeLevelMeta,
        gradeLevel.isAcceptableOrUnknown(data['grade_level']!, _gradeLevelMeta),
      );
    } else if (isInserting) {
      context.missing(_gradeLevelMeta);
    }
    if (data.containsKey('shift')) {
      context.handle(
        _shiftMeta,
        shift.isAcceptableOrUnknown(data['shift']!, _shiftMeta),
      );
    } else if (isInserting) {
      context.missing(_shiftMeta);
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {academicYearId, name},
  ];
  @override
  ClassroomsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClassroomsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      academicYearId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}academic_year_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      gradeLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grade_level'],
      )!,
      shift: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ClassroomsTableTable createAlias(String alias) {
    return $ClassroomsTableTable(attachedDatabase, alias);
  }
}

class ClassroomsTableData extends DataClass
    implements Insertable<ClassroomsTableData> {
  final String id;
  final String academicYearId;
  final String name;
  final String gradeLevel;
  final String shift;
  final DateTime createdAt;
  const ClassroomsTableData({
    required this.id,
    required this.academicYearId,
    required this.name,
    required this.gradeLevel,
    required this.shift,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['academic_year_id'] = Variable<String>(academicYearId);
    map['name'] = Variable<String>(name);
    map['grade_level'] = Variable<String>(gradeLevel);
    map['shift'] = Variable<String>(shift);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ClassroomsTableCompanion toCompanion(bool nullToAbsent) {
    return ClassroomsTableCompanion(
      id: Value(id),
      academicYearId: Value(academicYearId),
      name: Value(name),
      gradeLevel: Value(gradeLevel),
      shift: Value(shift),
      createdAt: Value(createdAt),
    );
  }

  factory ClassroomsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClassroomsTableData(
      id: serializer.fromJson<String>(json['id']),
      academicYearId: serializer.fromJson<String>(json['academicYearId']),
      name: serializer.fromJson<String>(json['name']),
      gradeLevel: serializer.fromJson<String>(json['gradeLevel']),
      shift: serializer.fromJson<String>(json['shift']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'academicYearId': serializer.toJson<String>(academicYearId),
      'name': serializer.toJson<String>(name),
      'gradeLevel': serializer.toJson<String>(gradeLevel),
      'shift': serializer.toJson<String>(shift),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ClassroomsTableData copyWith({
    String? id,
    String? academicYearId,
    String? name,
    String? gradeLevel,
    String? shift,
    DateTime? createdAt,
  }) => ClassroomsTableData(
    id: id ?? this.id,
    academicYearId: academicYearId ?? this.academicYearId,
    name: name ?? this.name,
    gradeLevel: gradeLevel ?? this.gradeLevel,
    shift: shift ?? this.shift,
    createdAt: createdAt ?? this.createdAt,
  );
  ClassroomsTableData copyWithCompanion(ClassroomsTableCompanion data) {
    return ClassroomsTableData(
      id: data.id.present ? data.id.value : this.id,
      academicYearId: data.academicYearId.present
          ? data.academicYearId.value
          : this.academicYearId,
      name: data.name.present ? data.name.value : this.name,
      gradeLevel: data.gradeLevel.present
          ? data.gradeLevel.value
          : this.gradeLevel,
      shift: data.shift.present ? data.shift.value : this.shift,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClassroomsTableData(')
          ..write('id: $id, ')
          ..write('academicYearId: $academicYearId, ')
          ..write('name: $name, ')
          ..write('gradeLevel: $gradeLevel, ')
          ..write('shift: $shift, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, academicYearId, name, gradeLevel, shift, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClassroomsTableData &&
          other.id == this.id &&
          other.academicYearId == this.academicYearId &&
          other.name == this.name &&
          other.gradeLevel == this.gradeLevel &&
          other.shift == this.shift &&
          other.createdAt == this.createdAt);
}

class ClassroomsTableCompanion extends UpdateCompanion<ClassroomsTableData> {
  final Value<String> id;
  final Value<String> academicYearId;
  final Value<String> name;
  final Value<String> gradeLevel;
  final Value<String> shift;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ClassroomsTableCompanion({
    this.id = const Value.absent(),
    this.academicYearId = const Value.absent(),
    this.name = const Value.absent(),
    this.gradeLevel = const Value.absent(),
    this.shift = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClassroomsTableCompanion.insert({
    required String id,
    required String academicYearId,
    required String name,
    required String gradeLevel,
    required String shift,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       academicYearId = Value(academicYearId),
       name = Value(name),
       gradeLevel = Value(gradeLevel),
       shift = Value(shift),
       createdAt = Value(createdAt);
  static Insertable<ClassroomsTableData> custom({
    Expression<String>? id,
    Expression<String>? academicYearId,
    Expression<String>? name,
    Expression<String>? gradeLevel,
    Expression<String>? shift,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (academicYearId != null) 'academic_year_id': academicYearId,
      if (name != null) 'name': name,
      if (gradeLevel != null) 'grade_level': gradeLevel,
      if (shift != null) 'shift': shift,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClassroomsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? academicYearId,
    Value<String>? name,
    Value<String>? gradeLevel,
    Value<String>? shift,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ClassroomsTableCompanion(
      id: id ?? this.id,
      academicYearId: academicYearId ?? this.academicYearId,
      name: name ?? this.name,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      shift: shift ?? this.shift,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (academicYearId.present) {
      map['academic_year_id'] = Variable<String>(academicYearId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (gradeLevel.present) {
      map['grade_level'] = Variable<String>(gradeLevel.value);
    }
    if (shift.present) {
      map['shift'] = Variable<String>(shift.value);
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
    return (StringBuffer('ClassroomsTableCompanion(')
          ..write('id: $id, ')
          ..write('academicYearId: $academicYearId, ')
          ..write('name: $name, ')
          ..write('gradeLevel: $gradeLevel, ')
          ..write('shift: $shift, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SubjectsTableTable extends SubjectsTable
    with TableInfo<$SubjectsTableTable, SubjectsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubjectsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
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
  List<GeneratedColumn> get $columns => [id, name, colorHex, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subjects_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubjectsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    } else if (isInserting) {
      context.missing(_colorHexMeta);
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {name},
  ];
  @override
  SubjectsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubjectsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SubjectsTableTable createAlias(String alias) {
    return $SubjectsTableTable(attachedDatabase, alias);
  }
}

class SubjectsTableData extends DataClass
    implements Insertable<SubjectsTableData> {
  final String id;
  final String name;
  final String colorHex;
  final DateTime createdAt;
  const SubjectsTableData({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['color_hex'] = Variable<String>(colorHex);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SubjectsTableCompanion toCompanion(bool nullToAbsent) {
    return SubjectsTableCompanion(
      id: Value(id),
      name: Value(name),
      colorHex: Value(colorHex),
      createdAt: Value(createdAt),
    );
  }

  factory SubjectsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubjectsTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'colorHex': serializer.toJson<String>(colorHex),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SubjectsTableData copyWith({
    String? id,
    String? name,
    String? colorHex,
    DateTime? createdAt,
  }) => SubjectsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    colorHex: colorHex ?? this.colorHex,
    createdAt: createdAt ?? this.createdAt,
  );
  SubjectsTableData copyWithCompanion(SubjectsTableCompanion data) {
    return SubjectsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubjectsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, colorHex, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubjectsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorHex == this.colorHex &&
          other.createdAt == this.createdAt);
}

class SubjectsTableCompanion extends UpdateCompanion<SubjectsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> colorHex;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SubjectsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubjectsTableCompanion.insert({
    required String id,
    required String name,
    required String colorHex,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       colorHex = Value(colorHex),
       createdAt = Value(createdAt);
  static Insertable<SubjectsTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? colorHex,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorHex != null) 'color_hex': colorHex,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubjectsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? colorHex,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SubjectsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
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
    return (StringBuffer('SubjectsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClassroomSubjectsTableTable extends ClassroomSubjectsTable
    with TableInfo<$ClassroomSubjectsTableTable, ClassroomSubjectsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClassroomSubjectsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _classroomIdMeta = const VerificationMeta(
    'classroomId',
  );
  @override
  late final GeneratedColumn<String> classroomId = GeneratedColumn<String>(
    'classroom_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES classrooms_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
    'subject_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES subjects_table (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _weeklyLessonsMeta = const VerificationMeta(
    'weeklyLessons',
  );
  @override
  late final GeneratedColumn<int> weeklyLessons = GeneratedColumn<int>(
    'weekly_lessons',
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
    classroomId,
    subjectId,
    weeklyLessons,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'classroom_subjects_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClassroomSubjectsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('classroom_id')) {
      context.handle(
        _classroomIdMeta,
        classroomId.isAcceptableOrUnknown(
          data['classroom_id']!,
          _classroomIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_classroomIdMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('weekly_lessons')) {
      context.handle(
        _weeklyLessonsMeta,
        weeklyLessons.isAcceptableOrUnknown(
          data['weekly_lessons']!,
          _weeklyLessonsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_weeklyLessonsMeta);
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {classroomId, subjectId},
  ];
  @override
  ClassroomSubjectsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClassroomSubjectsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      classroomId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}classroom_id'],
      )!,
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_id'],
      )!,
      weeklyLessons: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekly_lessons'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ClassroomSubjectsTableTable createAlias(String alias) {
    return $ClassroomSubjectsTableTable(attachedDatabase, alias);
  }
}

class ClassroomSubjectsTableData extends DataClass
    implements Insertable<ClassroomSubjectsTableData> {
  final String id;
  final String classroomId;
  final String subjectId;
  final int weeklyLessons;
  final DateTime createdAt;
  const ClassroomSubjectsTableData({
    required this.id,
    required this.classroomId,
    required this.subjectId,
    required this.weeklyLessons,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['classroom_id'] = Variable<String>(classroomId);
    map['subject_id'] = Variable<String>(subjectId);
    map['weekly_lessons'] = Variable<int>(weeklyLessons);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ClassroomSubjectsTableCompanion toCompanion(bool nullToAbsent) {
    return ClassroomSubjectsTableCompanion(
      id: Value(id),
      classroomId: Value(classroomId),
      subjectId: Value(subjectId),
      weeklyLessons: Value(weeklyLessons),
      createdAt: Value(createdAt),
    );
  }

  factory ClassroomSubjectsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClassroomSubjectsTableData(
      id: serializer.fromJson<String>(json['id']),
      classroomId: serializer.fromJson<String>(json['classroomId']),
      subjectId: serializer.fromJson<String>(json['subjectId']),
      weeklyLessons: serializer.fromJson<int>(json['weeklyLessons']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'classroomId': serializer.toJson<String>(classroomId),
      'subjectId': serializer.toJson<String>(subjectId),
      'weeklyLessons': serializer.toJson<int>(weeklyLessons),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ClassroomSubjectsTableData copyWith({
    String? id,
    String? classroomId,
    String? subjectId,
    int? weeklyLessons,
    DateTime? createdAt,
  }) => ClassroomSubjectsTableData(
    id: id ?? this.id,
    classroomId: classroomId ?? this.classroomId,
    subjectId: subjectId ?? this.subjectId,
    weeklyLessons: weeklyLessons ?? this.weeklyLessons,
    createdAt: createdAt ?? this.createdAt,
  );
  ClassroomSubjectsTableData copyWithCompanion(
    ClassroomSubjectsTableCompanion data,
  ) {
    return ClassroomSubjectsTableData(
      id: data.id.present ? data.id.value : this.id,
      classroomId: data.classroomId.present
          ? data.classroomId.value
          : this.classroomId,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      weeklyLessons: data.weeklyLessons.present
          ? data.weeklyLessons.value
          : this.weeklyLessons,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClassroomSubjectsTableData(')
          ..write('id: $id, ')
          ..write('classroomId: $classroomId, ')
          ..write('subjectId: $subjectId, ')
          ..write('weeklyLessons: $weeklyLessons, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, classroomId, subjectId, weeklyLessons, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClassroomSubjectsTableData &&
          other.id == this.id &&
          other.classroomId == this.classroomId &&
          other.subjectId == this.subjectId &&
          other.weeklyLessons == this.weeklyLessons &&
          other.createdAt == this.createdAt);
}

class ClassroomSubjectsTableCompanion
    extends UpdateCompanion<ClassroomSubjectsTableData> {
  final Value<String> id;
  final Value<String> classroomId;
  final Value<String> subjectId;
  final Value<int> weeklyLessons;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ClassroomSubjectsTableCompanion({
    this.id = const Value.absent(),
    this.classroomId = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.weeklyLessons = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClassroomSubjectsTableCompanion.insert({
    required String id,
    required String classroomId,
    required String subjectId,
    required int weeklyLessons,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       classroomId = Value(classroomId),
       subjectId = Value(subjectId),
       weeklyLessons = Value(weeklyLessons),
       createdAt = Value(createdAt);
  static Insertable<ClassroomSubjectsTableData> custom({
    Expression<String>? id,
    Expression<String>? classroomId,
    Expression<String>? subjectId,
    Expression<int>? weeklyLessons,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (classroomId != null) 'classroom_id': classroomId,
      if (subjectId != null) 'subject_id': subjectId,
      if (weeklyLessons != null) 'weekly_lessons': weeklyLessons,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClassroomSubjectsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? classroomId,
    Value<String>? subjectId,
    Value<int>? weeklyLessons,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ClassroomSubjectsTableCompanion(
      id: id ?? this.id,
      classroomId: classroomId ?? this.classroomId,
      subjectId: subjectId ?? this.subjectId,
      weeklyLessons: weeklyLessons ?? this.weeklyLessons,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (classroomId.present) {
      map['classroom_id'] = Variable<String>(classroomId.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (weeklyLessons.present) {
      map['weekly_lessons'] = Variable<int>(weeklyLessons.value);
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
    return (StringBuffer('ClassroomSubjectsTableCompanion(')
          ..write('id: $id, ')
          ..write('classroomId: $classroomId, ')
          ..write('subjectId: $subjectId, ')
          ..write('weeklyLessons: $weeklyLessons, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlannedLessonsTableTable extends PlannedLessonsTable
    with TableInfo<$PlannedLessonsTableTable, PlannedLessonsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannedLessonsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _classroomSubjectIdMeta =
      const VerificationMeta('classroomSubjectId');
  @override
  late final GeneratedColumn<String> classroomSubjectId =
      GeneratedColumn<String>(
        'classroom_subject_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES classroom_subjects_table (id) ON DELETE RESTRICT',
        ),
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> lessonDate =
      GeneratedColumn<String>(
        'lesson_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PlannedLessonsTableTable.$converterlessonDate);
  static const VerificationMeta _orderInDayMeta = const VerificationMeta(
    'orderInDay',
  );
  @override
  late final GeneratedColumn<int> orderInDay = GeneratedColumn<int>(
    'order_in_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _isLockedMeta = const VerificationMeta(
    'isLocked',
  );
  @override
  late final GeneratedColumn<bool> isLocked = GeneratedColumn<bool>(
    'is_locked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_locked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    classroomSubjectId,
    lessonDate,
    orderInDay,
    status,
    isLocked,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planned_lessons_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannedLessonsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('classroom_subject_id')) {
      context.handle(
        _classroomSubjectIdMeta,
        classroomSubjectId.isAcceptableOrUnknown(
          data['classroom_subject_id']!,
          _classroomSubjectIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_classroomSubjectIdMeta);
    }
    if (data.containsKey('order_in_day')) {
      context.handle(
        _orderInDayMeta,
        orderInDay.isAcceptableOrUnknown(
          data['order_in_day']!,
          _orderInDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_orderInDayMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('is_locked')) {
      context.handle(
        _isLockedMeta,
        isLocked.isAcceptableOrUnknown(data['is_locked']!, _isLockedMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {classroomSubjectId, lessonDate, orderInDay},
  ];
  @override
  PlannedLessonsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannedLessonsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      classroomSubjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}classroom_subject_id'],
      )!,
      lessonDate: $PlannedLessonsTableTable.$converterlessonDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}lesson_date'],
        )!,
      ),
      orderInDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_in_day'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      isLocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_locked'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PlannedLessonsTableTable createAlias(String alias) {
    return $PlannedLessonsTableTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $converterlessonDate =
      const CalendarDateConverter();
}

class PlannedLessonsTableData extends DataClass
    implements Insertable<PlannedLessonsTableData> {
  final String id;
  final String classroomSubjectId;
  final DateTime lessonDate;
  final int orderInDay;
  final String status;
  final bool isLocked;
  final String? notes;
  final DateTime createdAt;
  const PlannedLessonsTableData({
    required this.id,
    required this.classroomSubjectId,
    required this.lessonDate,
    required this.orderInDay,
    required this.status,
    required this.isLocked,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['classroom_subject_id'] = Variable<String>(classroomSubjectId);
    {
      map['lesson_date'] = Variable<String>(
        $PlannedLessonsTableTable.$converterlessonDate.toSql(lessonDate),
      );
    }
    map['order_in_day'] = Variable<int>(orderInDay);
    map['status'] = Variable<String>(status);
    map['is_locked'] = Variable<bool>(isLocked);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PlannedLessonsTableCompanion toCompanion(bool nullToAbsent) {
    return PlannedLessonsTableCompanion(
      id: Value(id),
      classroomSubjectId: Value(classroomSubjectId),
      lessonDate: Value(lessonDate),
      orderInDay: Value(orderInDay),
      status: Value(status),
      isLocked: Value(isLocked),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory PlannedLessonsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannedLessonsTableData(
      id: serializer.fromJson<String>(json['id']),
      classroomSubjectId: serializer.fromJson<String>(
        json['classroomSubjectId'],
      ),
      lessonDate: serializer.fromJson<DateTime>(json['lessonDate']),
      orderInDay: serializer.fromJson<int>(json['orderInDay']),
      status: serializer.fromJson<String>(json['status']),
      isLocked: serializer.fromJson<bool>(json['isLocked']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'classroomSubjectId': serializer.toJson<String>(classroomSubjectId),
      'lessonDate': serializer.toJson<DateTime>(lessonDate),
      'orderInDay': serializer.toJson<int>(orderInDay),
      'status': serializer.toJson<String>(status),
      'isLocked': serializer.toJson<bool>(isLocked),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PlannedLessonsTableData copyWith({
    String? id,
    String? classroomSubjectId,
    DateTime? lessonDate,
    int? orderInDay,
    String? status,
    bool? isLocked,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
  }) => PlannedLessonsTableData(
    id: id ?? this.id,
    classroomSubjectId: classroomSubjectId ?? this.classroomSubjectId,
    lessonDate: lessonDate ?? this.lessonDate,
    orderInDay: orderInDay ?? this.orderInDay,
    status: status ?? this.status,
    isLocked: isLocked ?? this.isLocked,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  PlannedLessonsTableData copyWithCompanion(PlannedLessonsTableCompanion data) {
    return PlannedLessonsTableData(
      id: data.id.present ? data.id.value : this.id,
      classroomSubjectId: data.classroomSubjectId.present
          ? data.classroomSubjectId.value
          : this.classroomSubjectId,
      lessonDate: data.lessonDate.present
          ? data.lessonDate.value
          : this.lessonDate,
      orderInDay: data.orderInDay.present
          ? data.orderInDay.value
          : this.orderInDay,
      status: data.status.present ? data.status.value : this.status,
      isLocked: data.isLocked.present ? data.isLocked.value : this.isLocked,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannedLessonsTableData(')
          ..write('id: $id, ')
          ..write('classroomSubjectId: $classroomSubjectId, ')
          ..write('lessonDate: $lessonDate, ')
          ..write('orderInDay: $orderInDay, ')
          ..write('status: $status, ')
          ..write('isLocked: $isLocked, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    classroomSubjectId,
    lessonDate,
    orderInDay,
    status,
    isLocked,
    notes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannedLessonsTableData &&
          other.id == this.id &&
          other.classroomSubjectId == this.classroomSubjectId &&
          other.lessonDate == this.lessonDate &&
          other.orderInDay == this.orderInDay &&
          other.status == this.status &&
          other.isLocked == this.isLocked &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class PlannedLessonsTableCompanion
    extends UpdateCompanion<PlannedLessonsTableData> {
  final Value<String> id;
  final Value<String> classroomSubjectId;
  final Value<DateTime> lessonDate;
  final Value<int> orderInDay;
  final Value<String> status;
  final Value<bool> isLocked;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PlannedLessonsTableCompanion({
    this.id = const Value.absent(),
    this.classroomSubjectId = const Value.absent(),
    this.lessonDate = const Value.absent(),
    this.orderInDay = const Value.absent(),
    this.status = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlannedLessonsTableCompanion.insert({
    required String id,
    required String classroomSubjectId,
    required DateTime lessonDate,
    required int orderInDay,
    required String status,
    this.isLocked = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       classroomSubjectId = Value(classroomSubjectId),
       lessonDate = Value(lessonDate),
       orderInDay = Value(orderInDay),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<PlannedLessonsTableData> custom({
    Expression<String>? id,
    Expression<String>? classroomSubjectId,
    Expression<String>? lessonDate,
    Expression<int>? orderInDay,
    Expression<String>? status,
    Expression<bool>? isLocked,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (classroomSubjectId != null)
        'classroom_subject_id': classroomSubjectId,
      if (lessonDate != null) 'lesson_date': lessonDate,
      if (orderInDay != null) 'order_in_day': orderInDay,
      if (status != null) 'status': status,
      if (isLocked != null) 'is_locked': isLocked,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlannedLessonsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? classroomSubjectId,
    Value<DateTime>? lessonDate,
    Value<int>? orderInDay,
    Value<String>? status,
    Value<bool>? isLocked,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PlannedLessonsTableCompanion(
      id: id ?? this.id,
      classroomSubjectId: classroomSubjectId ?? this.classroomSubjectId,
      lessonDate: lessonDate ?? this.lessonDate,
      orderInDay: orderInDay ?? this.orderInDay,
      status: status ?? this.status,
      isLocked: isLocked ?? this.isLocked,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (classroomSubjectId.present) {
      map['classroom_subject_id'] = Variable<String>(classroomSubjectId.value);
    }
    if (lessonDate.present) {
      map['lesson_date'] = Variable<String>(
        $PlannedLessonsTableTable.$converterlessonDate.toSql(lessonDate.value),
      );
    }
    if (orderInDay.present) {
      map['order_in_day'] = Variable<int>(orderInDay.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isLocked.present) {
      map['is_locked'] = Variable<bool>(isLocked.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
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
    return (StringBuffer('PlannedLessonsTableCompanion(')
          ..write('id: $id, ')
          ..write('classroomSubjectId: $classroomSubjectId, ')
          ..write('lessonDate: $lessonDate, ')
          ..write('orderInDay: $orderInDay, ')
          ..write('status: $status, ')
          ..write('isLocked: $isLocked, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AcademicYearsTableTable academicYearsTable =
      $AcademicYearsTableTable(this);
  late final $ClassroomsTableTable classroomsTable = $ClassroomsTableTable(
    this,
  );
  late final $SubjectsTableTable subjectsTable = $SubjectsTableTable(this);
  late final $ClassroomSubjectsTableTable classroomSubjectsTable =
      $ClassroomSubjectsTableTable(this);
  late final $PlannedLessonsTableTable plannedLessonsTable =
      $PlannedLessonsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    academicYearsTable,
    classroomsTable,
    subjectsTable,
    classroomSubjectsTable,
    plannedLessonsTable,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'classrooms_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('classroom_subjects_table', kind: UpdateKind.delete),
      ],
    ),
  ]);
}

typedef $$AcademicYearsTableTableCreateCompanionBuilder =
    AcademicYearsTableCompanion Function({
      required String id,
      required int year,
      required String title,
      required DateTime startDate,
      required DateTime endDate,
      Value<int> totalMandatoryDays,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$AcademicYearsTableTableUpdateCompanionBuilder =
    AcademicYearsTableCompanion Function({
      Value<String> id,
      Value<int> year,
      Value<String> title,
      Value<DateTime> startDate,
      Value<DateTime> endDate,
      Value<int> totalMandatoryDays,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$AcademicYearsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AcademicYearsTableTable,
          AcademicYearsTableData
        > {
  $$AcademicYearsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ClassroomsTableTable, List<ClassroomsTableData>>
  _classroomsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.classroomsTable,
    aliasName: 'academic_years_table__id__classrooms_table__academic_year_id',
  );

  $$ClassroomsTableTableProcessedTableManager get classroomsTableRefs {
    final manager = $$ClassroomsTableTableTableManager(
      $_db,
      $_db.classroomsTable,
    ).filter((f) => f.academicYearId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _classroomsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AcademicYearsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AcademicYearsTableTable> {
  $$AcademicYearsTableTableFilterComposer({
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

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get startDate =>
      $composableBuilder(
        column: $table.startDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get endDate =>
      $composableBuilder(
        column: $table.endDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get totalMandatoryDays => $composableBuilder(
    column: $table.totalMandatoryDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> classroomsTableRefs(
    Expression<bool> Function($$ClassroomsTableTableFilterComposer f) f,
  ) {
    final $$ClassroomsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.classroomsTable,
      getReferencedColumn: (t) => t.academicYearId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassroomsTableTableFilterComposer(
            $db: $db,
            $table: $db.classroomsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AcademicYearsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AcademicYearsTableTable> {
  $$AcademicYearsTableTableOrderingComposer({
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

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalMandatoryDays => $composableBuilder(
    column: $table.totalMandatoryDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AcademicYearsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AcademicYearsTableTable> {
  $$AcademicYearsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<int> get totalMandatoryDays => $composableBuilder(
    column: $table.totalMandatoryDays,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> classroomsTableRefs<T extends Object>(
    Expression<T> Function($$ClassroomsTableTableAnnotationComposer a) f,
  ) {
    final $$ClassroomsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.classroomsTable,
      getReferencedColumn: (t) => t.academicYearId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassroomsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.classroomsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AcademicYearsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AcademicYearsTableTable,
          AcademicYearsTableData,
          $$AcademicYearsTableTableFilterComposer,
          $$AcademicYearsTableTableOrderingComposer,
          $$AcademicYearsTableTableAnnotationComposer,
          $$AcademicYearsTableTableCreateCompanionBuilder,
          $$AcademicYearsTableTableUpdateCompanionBuilder,
          (AcademicYearsTableData, $$AcademicYearsTableTableReferences),
          AcademicYearsTableData,
          PrefetchHooks Function({bool classroomsTableRefs})
        > {
  $$AcademicYearsTableTableTableManager(
    _$AppDatabase db,
    $AcademicYearsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AcademicYearsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AcademicYearsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AcademicYearsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime> endDate = const Value.absent(),
                Value<int> totalMandatoryDays = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AcademicYearsTableCompanion(
                id: id,
                year: year,
                title: title,
                startDate: startDate,
                endDate: endDate,
                totalMandatoryDays: totalMandatoryDays,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int year,
                required String title,
                required DateTime startDate,
                required DateTime endDate,
                Value<int> totalMandatoryDays = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AcademicYearsTableCompanion.insert(
                id: id,
                year: year,
                title: title,
                startDate: startDate,
                endDate: endDate,
                totalMandatoryDays: totalMandatoryDays,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AcademicYearsTableTable, AcademicYearsTableData>(
                    table,
                  ),
                  $$AcademicYearsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({classroomsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (classroomsTableRefs) db.classroomsTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (classroomsTableRefs)
                    await $_getPrefetchedData<
                      AcademicYearsTableData,
                      $AcademicYearsTableTable,
                      ClassroomsTableData
                    >(
                      currentTable: table,
                      referencedTable: $$AcademicYearsTableTableReferences
                          ._classroomsTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$AcademicYearsTableTableReferences(
                            db,
                            table,
                            p0,
                          ).classroomsTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.academicYearId == item.id,
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

typedef $$AcademicYearsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AcademicYearsTableTable,
      AcademicYearsTableData,
      $$AcademicYearsTableTableFilterComposer,
      $$AcademicYearsTableTableOrderingComposer,
      $$AcademicYearsTableTableAnnotationComposer,
      $$AcademicYearsTableTableCreateCompanionBuilder,
      $$AcademicYearsTableTableUpdateCompanionBuilder,
      (AcademicYearsTableData, $$AcademicYearsTableTableReferences),
      AcademicYearsTableData,
      PrefetchHooks Function({bool classroomsTableRefs})
    >;
typedef $$ClassroomsTableTableCreateCompanionBuilder =
    ClassroomsTableCompanion Function({
      required String id,
      required String academicYearId,
      required String name,
      required String gradeLevel,
      required String shift,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ClassroomsTableTableUpdateCompanionBuilder =
    ClassroomsTableCompanion Function({
      Value<String> id,
      Value<String> academicYearId,
      Value<String> name,
      Value<String> gradeLevel,
      Value<String> shift,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ClassroomsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ClassroomsTableTable,
          ClassroomsTableData
        > {
  $$ClassroomsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AcademicYearsTableTable _academicYearIdTable(_$AppDatabase db) =>
      db.academicYearsTable.createAlias(
        'classrooms_table__academic_year_id__academic_years_table__id',
      );

  $$AcademicYearsTableTableProcessedTableManager get academicYearId {
    final $_column = $_itemColumn<String>('academic_year_id')!;

    final manager = $$AcademicYearsTableTableTableManager(
      $_db,
      $_db.academicYearsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_academicYearIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $ClassroomSubjectsTableTable,
    List<ClassroomSubjectsTableData>
  >
  _classroomSubjectsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.classroomSubjectsTable,
        aliasName:
            'classrooms_table__id__classroom_subjects_table__classroom_id',
      );

  $$ClassroomSubjectsTableTableProcessedTableManager
  get classroomSubjectsTableRefs {
    final manager = $$ClassroomSubjectsTableTableTableManager(
      $_db,
      $_db.classroomSubjectsTable,
    ).filter((f) => f.classroomId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _classroomSubjectsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ClassroomsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ClassroomsTableTable> {
  $$ClassroomsTableTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gradeLevel => $composableBuilder(
    column: $table.gradeLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shift => $composableBuilder(
    column: $table.shift,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AcademicYearsTableTableFilterComposer get academicYearId {
    final $$AcademicYearsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.academicYearId,
      referencedTable: $db.academicYearsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AcademicYearsTableTableFilterComposer(
            $db: $db,
            $table: $db.academicYearsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> classroomSubjectsTableRefs(
    Expression<bool> Function($$ClassroomSubjectsTableTableFilterComposer f) f,
  ) {
    final $$ClassroomSubjectsTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.classroomSubjectsTable,
          getReferencedColumn: (t) => t.classroomId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ClassroomSubjectsTableTableFilterComposer(
                $db: $db,
                $table: $db.classroomSubjectsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ClassroomsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ClassroomsTableTable> {
  $$ClassroomsTableTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gradeLevel => $composableBuilder(
    column: $table.gradeLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shift => $composableBuilder(
    column: $table.shift,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AcademicYearsTableTableOrderingComposer get academicYearId {
    final $$AcademicYearsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.academicYearId,
      referencedTable: $db.academicYearsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AcademicYearsTableTableOrderingComposer(
            $db: $db,
            $table: $db.academicYearsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClassroomsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClassroomsTableTable> {
  $$ClassroomsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get gradeLevel => $composableBuilder(
    column: $table.gradeLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shift =>
      $composableBuilder(column: $table.shift, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AcademicYearsTableTableAnnotationComposer get academicYearId {
    final $$AcademicYearsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.academicYearId,
          referencedTable: $db.academicYearsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AcademicYearsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.academicYearsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> classroomSubjectsTableRefs<T extends Object>(
    Expression<T> Function($$ClassroomSubjectsTableTableAnnotationComposer a) f,
  ) {
    final $$ClassroomSubjectsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.classroomSubjectsTable,
          getReferencedColumn: (t) => t.classroomId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ClassroomSubjectsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.classroomSubjectsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ClassroomsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClassroomsTableTable,
          ClassroomsTableData,
          $$ClassroomsTableTableFilterComposer,
          $$ClassroomsTableTableOrderingComposer,
          $$ClassroomsTableTableAnnotationComposer,
          $$ClassroomsTableTableCreateCompanionBuilder,
          $$ClassroomsTableTableUpdateCompanionBuilder,
          (ClassroomsTableData, $$ClassroomsTableTableReferences),
          ClassroomsTableData,
          PrefetchHooks Function({
            bool academicYearId,
            bool classroomSubjectsTableRefs,
          })
        > {
  $$ClassroomsTableTableTableManager(
    _$AppDatabase db,
    $ClassroomsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClassroomsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClassroomsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClassroomsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> academicYearId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> gradeLevel = const Value.absent(),
                Value<String> shift = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClassroomsTableCompanion(
                id: id,
                academicYearId: academicYearId,
                name: name,
                gradeLevel: gradeLevel,
                shift: shift,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String academicYearId,
                required String name,
                required String gradeLevel,
                required String shift,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ClassroomsTableCompanion.insert(
                id: id,
                academicYearId: academicYearId,
                name: name,
                gradeLevel: gradeLevel,
                shift: shift,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ClassroomsTableTable, ClassroomsTableData>(
                    table,
                  ),
                  $$ClassroomsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({academicYearId = false, classroomSubjectsTableRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (classroomSubjectsTableRefs) db.classroomSubjectsTable,
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
                        if (academicYearId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.academicYearId,
                            referencedTable: $$ClassroomsTableTableReferences
                                ._academicYearIdTable(db),
                            referencedColumn: $$ClassroomsTableTableReferences
                                ._academicYearIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (classroomSubjectsTableRefs)
                        await $_getPrefetchedData<
                          ClassroomsTableData,
                          $ClassroomsTableTable,
                          ClassroomSubjectsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$ClassroomsTableTableReferences
                              ._classroomSubjectsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClassroomsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).classroomSubjectsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.classroomId == item.id,
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

typedef $$ClassroomsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClassroomsTableTable,
      ClassroomsTableData,
      $$ClassroomsTableTableFilterComposer,
      $$ClassroomsTableTableOrderingComposer,
      $$ClassroomsTableTableAnnotationComposer,
      $$ClassroomsTableTableCreateCompanionBuilder,
      $$ClassroomsTableTableUpdateCompanionBuilder,
      (ClassroomsTableData, $$ClassroomsTableTableReferences),
      ClassroomsTableData,
      PrefetchHooks Function({
        bool academicYearId,
        bool classroomSubjectsTableRefs,
      })
    >;
typedef $$SubjectsTableTableCreateCompanionBuilder =
    SubjectsTableCompanion Function({
      required String id,
      required String name,
      required String colorHex,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$SubjectsTableTableUpdateCompanionBuilder =
    SubjectsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> colorHex,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$SubjectsTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $SubjectsTableTable, SubjectsTableData> {
  $$SubjectsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $ClassroomSubjectsTableTable,
    List<ClassroomSubjectsTableData>
  >
  _classroomSubjectsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.classroomSubjectsTable,
        aliasName: 'subjects_table__id__classroom_subjects_table__subject_id',
      );

  $$ClassroomSubjectsTableTableProcessedTableManager
  get classroomSubjectsTableRefs {
    final manager = $$ClassroomSubjectsTableTableTableManager(
      $_db,
      $_db.classroomSubjectsTable,
    ).filter((f) => f.subjectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _classroomSubjectsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SubjectsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SubjectsTableTable> {
  $$SubjectsTableTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> classroomSubjectsTableRefs(
    Expression<bool> Function($$ClassroomSubjectsTableTableFilterComposer f) f,
  ) {
    final $$ClassroomSubjectsTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.classroomSubjectsTable,
          getReferencedColumn: (t) => t.subjectId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ClassroomSubjectsTableTableFilterComposer(
                $db: $db,
                $table: $db.classroomSubjectsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SubjectsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SubjectsTableTable> {
  $$SubjectsTableTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubjectsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubjectsTableTable> {
  $$SubjectsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> classroomSubjectsTableRefs<T extends Object>(
    Expression<T> Function($$ClassroomSubjectsTableTableAnnotationComposer a) f,
  ) {
    final $$ClassroomSubjectsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.classroomSubjectsTable,
          getReferencedColumn: (t) => t.subjectId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ClassroomSubjectsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.classroomSubjectsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SubjectsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubjectsTableTable,
          SubjectsTableData,
          $$SubjectsTableTableFilterComposer,
          $$SubjectsTableTableOrderingComposer,
          $$SubjectsTableTableAnnotationComposer,
          $$SubjectsTableTableCreateCompanionBuilder,
          $$SubjectsTableTableUpdateCompanionBuilder,
          (SubjectsTableData, $$SubjectsTableTableReferences),
          SubjectsTableData,
          PrefetchHooks Function({bool classroomSubjectsTableRefs})
        > {
  $$SubjectsTableTableTableManager(_$AppDatabase db, $SubjectsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubjectsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubjectsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubjectsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubjectsTableCompanion(
                id: id,
                name: name,
                colorHex: colorHex,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String colorHex,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SubjectsTableCompanion.insert(
                id: id,
                name: name,
                colorHex: colorHex,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SubjectsTableTable, SubjectsTableData>(table),
                  $$SubjectsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({classroomSubjectsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (classroomSubjectsTableRefs) db.classroomSubjectsTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (classroomSubjectsTableRefs)
                    await $_getPrefetchedData<
                      SubjectsTableData,
                      $SubjectsTableTable,
                      ClassroomSubjectsTableData
                    >(
                      currentTable: table,
                      referencedTable: $$SubjectsTableTableReferences
                          ._classroomSubjectsTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SubjectsTableTableReferences(
                            db,
                            table,
                            p0,
                          ).classroomSubjectsTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.subjectId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SubjectsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubjectsTableTable,
      SubjectsTableData,
      $$SubjectsTableTableFilterComposer,
      $$SubjectsTableTableOrderingComposer,
      $$SubjectsTableTableAnnotationComposer,
      $$SubjectsTableTableCreateCompanionBuilder,
      $$SubjectsTableTableUpdateCompanionBuilder,
      (SubjectsTableData, $$SubjectsTableTableReferences),
      SubjectsTableData,
      PrefetchHooks Function({bool classroomSubjectsTableRefs})
    >;
typedef $$ClassroomSubjectsTableTableCreateCompanionBuilder =
    ClassroomSubjectsTableCompanion Function({
      required String id,
      required String classroomId,
      required String subjectId,
      required int weeklyLessons,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ClassroomSubjectsTableTableUpdateCompanionBuilder =
    ClassroomSubjectsTableCompanion Function({
      Value<String> id,
      Value<String> classroomId,
      Value<String> subjectId,
      Value<int> weeklyLessons,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ClassroomSubjectsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ClassroomSubjectsTableTable,
          ClassroomSubjectsTableData
        > {
  $$ClassroomSubjectsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ClassroomsTableTable _classroomIdTable(_$AppDatabase db) =>
      db.classroomsTable.createAlias(
        'classroom_subjects_table__classroom_id__classrooms_table__id',
      );

  $$ClassroomsTableTableProcessedTableManager get classroomId {
    final $_column = $_itemColumn<String>('classroom_id')!;

    final manager = $$ClassroomsTableTableTableManager(
      $_db,
      $_db.classroomsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_classroomIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SubjectsTableTable _subjectIdTable(_$AppDatabase db) => db
      .subjectsTable
      .createAlias('classroom_subjects_table__subject_id__subjects_table__id');

  $$SubjectsTableTableProcessedTableManager get subjectId {
    final $_column = $_itemColumn<String>('subject_id')!;

    final manager = $$SubjectsTableTableTableManager(
      $_db,
      $_db.subjectsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $PlannedLessonsTableTable,
    List<PlannedLessonsTableData>
  >
  _plannedLessonsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.plannedLessonsTable,
        aliasName: 'classroom_subjects_table__id__planned_lessons_table__classroom_subject_id',
      );

  $$PlannedLessonsTableTableProcessedTableManager get plannedLessonsTableRefs {
    final manager =
        $$PlannedLessonsTableTableTableManager(
          $_db,
          $_db.plannedLessonsTable,
        ).filter(
          (f) => f.classroomSubjectId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _plannedLessonsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ClassroomSubjectsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ClassroomSubjectsTableTable> {
  $$ClassroomSubjectsTableTableFilterComposer({
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

  ColumnFilters<int> get weeklyLessons => $composableBuilder(
    column: $table.weeklyLessons,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ClassroomsTableTableFilterComposer get classroomId {
    final $$ClassroomsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classroomId,
      referencedTable: $db.classroomsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassroomsTableTableFilterComposer(
            $db: $db,
            $table: $db.classroomsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SubjectsTableTableFilterComposer get subjectId {
    final $$SubjectsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjectsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableTableFilterComposer(
            $db: $db,
            $table: $db.subjectsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> plannedLessonsTableRefs(
    Expression<bool> Function($$PlannedLessonsTableTableFilterComposer f) f,
  ) {
    final $$PlannedLessonsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.plannedLessonsTable,
      getReferencedColumn: (t) => t.classroomSubjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlannedLessonsTableTableFilterComposer(
            $db: $db,
            $table: $db.plannedLessonsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ClassroomSubjectsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ClassroomSubjectsTableTable> {
  $$ClassroomSubjectsTableTableOrderingComposer({
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

  ColumnOrderings<int> get weeklyLessons => $composableBuilder(
    column: $table.weeklyLessons,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ClassroomsTableTableOrderingComposer get classroomId {
    final $$ClassroomsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classroomId,
      referencedTable: $db.classroomsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassroomsTableTableOrderingComposer(
            $db: $db,
            $table: $db.classroomsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SubjectsTableTableOrderingComposer get subjectId {
    final $$SubjectsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjectsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableTableOrderingComposer(
            $db: $db,
            $table: $db.subjectsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClassroomSubjectsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClassroomSubjectsTableTable> {
  $$ClassroomSubjectsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get weeklyLessons => $composableBuilder(
    column: $table.weeklyLessons,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ClassroomsTableTableAnnotationComposer get classroomId {
    final $$ClassroomsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classroomId,
      referencedTable: $db.classroomsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassroomsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.classroomsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SubjectsTableTableAnnotationComposer get subjectId {
    final $$SubjectsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjectsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.subjectsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> plannedLessonsTableRefs<T extends Object>(
    Expression<T> Function($$PlannedLessonsTableTableAnnotationComposer a) f,
  ) {
    final $$PlannedLessonsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.plannedLessonsTable,
          getReferencedColumn: (t) => t.classroomSubjectId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PlannedLessonsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.plannedLessonsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ClassroomSubjectsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClassroomSubjectsTableTable,
          ClassroomSubjectsTableData,
          $$ClassroomSubjectsTableTableFilterComposer,
          $$ClassroomSubjectsTableTableOrderingComposer,
          $$ClassroomSubjectsTableTableAnnotationComposer,
          $$ClassroomSubjectsTableTableCreateCompanionBuilder,
          $$ClassroomSubjectsTableTableUpdateCompanionBuilder,
          (ClassroomSubjectsTableData, $$ClassroomSubjectsTableTableReferences),
          ClassroomSubjectsTableData,
          PrefetchHooks Function({
            bool classroomId,
            bool subjectId,
            bool plannedLessonsTableRefs,
          })
        > {
  $$ClassroomSubjectsTableTableTableManager(
    _$AppDatabase db,
    $ClassroomSubjectsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClassroomSubjectsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ClassroomSubjectsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ClassroomSubjectsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> classroomId = const Value.absent(),
                Value<String> subjectId = const Value.absent(),
                Value<int> weeklyLessons = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClassroomSubjectsTableCompanion(
                id: id,
                classroomId: classroomId,
                subjectId: subjectId,
                weeklyLessons: weeklyLessons,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String classroomId,
                required String subjectId,
                required int weeklyLessons,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ClassroomSubjectsTableCompanion.insert(
                id: id,
                classroomId: classroomId,
                subjectId: subjectId,
                weeklyLessons: weeklyLessons,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ClassroomSubjectsTableTable,
                    ClassroomSubjectsTableData
                  >(table),
                  $$ClassroomSubjectsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                classroomId = false,
                subjectId = false,
                plannedLessonsTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (plannedLessonsTableRefs) db.plannedLessonsTable,
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
                        if (classroomId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.classroomId,
                            referencedTable:
                                $$ClassroomSubjectsTableTableReferences
                                    ._classroomIdTable(db),
                            referencedColumn:
                                $$ClassroomSubjectsTableTableReferences
                                    ._classroomIdTable(db)
                                    .id,
                          ) as T;
                        }
                        if (subjectId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.subjectId,
                            referencedTable:
                                $$ClassroomSubjectsTableTableReferences
                                    ._subjectIdTable(db),
                            referencedColumn:
                                $$ClassroomSubjectsTableTableReferences
                                    ._subjectIdTable(db)
                                    .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (plannedLessonsTableRefs)
                        await $_getPrefetchedData<
                          ClassroomSubjectsTableData,
                          $ClassroomSubjectsTableTable,
                          PlannedLessonsTableData
                        >(
                          currentTable: table,
                          referencedTable:
                              $$ClassroomSubjectsTableTableReferences
                                  ._plannedLessonsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClassroomSubjectsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).plannedLessonsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.classroomSubjectId == item.id,
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

typedef $$ClassroomSubjectsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClassroomSubjectsTableTable,
      ClassroomSubjectsTableData,
      $$ClassroomSubjectsTableTableFilterComposer,
      $$ClassroomSubjectsTableTableOrderingComposer,
      $$ClassroomSubjectsTableTableAnnotationComposer,
      $$ClassroomSubjectsTableTableCreateCompanionBuilder,
      $$ClassroomSubjectsTableTableUpdateCompanionBuilder,
      (ClassroomSubjectsTableData, $$ClassroomSubjectsTableTableReferences),
      ClassroomSubjectsTableData,
      PrefetchHooks Function({
        bool classroomId,
        bool subjectId,
        bool plannedLessonsTableRefs,
      })
    >;
typedef $$PlannedLessonsTableTableCreateCompanionBuilder =
    PlannedLessonsTableCompanion Function({
      required String id,
      required String classroomSubjectId,
      required DateTime lessonDate,
      required int orderInDay,
      required String status,
      Value<bool> isLocked,
      Value<String?> notes,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$PlannedLessonsTableTableUpdateCompanionBuilder =
    PlannedLessonsTableCompanion Function({
      Value<String> id,
      Value<String> classroomSubjectId,
      Value<DateTime> lessonDate,
      Value<int> orderInDay,
      Value<String> status,
      Value<bool> isLocked,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$PlannedLessonsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PlannedLessonsTableTable,
          PlannedLessonsTableData
        > {
  $$PlannedLessonsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ClassroomSubjectsTableTable _classroomSubjectIdTable(
    _$AppDatabase db,
  ) => db.classroomSubjectsTable.createAlias(
    'planned_lessons_table__classroom_subject_id__classroom_subjects_table__id',
  );

  $$ClassroomSubjectsTableTableProcessedTableManager get classroomSubjectId {
    final $_column = $_itemColumn<String>('classroom_subject_id')!;

    final manager = $$ClassroomSubjectsTableTableTableManager(
      $_db,
      $_db.classroomSubjectsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_classroomSubjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlannedLessonsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PlannedLessonsTableTable> {
  $$PlannedLessonsTableTableFilterComposer({
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

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get lessonDate =>
      $composableBuilder(
        column: $table.lessonDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get orderInDay => $composableBuilder(
    column: $table.orderInDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ClassroomSubjectsTableTableFilterComposer get classroomSubjectId {
    final $$ClassroomSubjectsTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.classroomSubjectId,
          referencedTable: $db.classroomSubjectsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ClassroomSubjectsTableTableFilterComposer(
                $db: $db,
                $table: $db.classroomSubjectsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$PlannedLessonsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PlannedLessonsTableTable> {
  $$PlannedLessonsTableTableOrderingComposer({
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

  ColumnOrderings<String> get lessonDate => $composableBuilder(
    column: $table.lessonDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderInDay => $composableBuilder(
    column: $table.orderInDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ClassroomSubjectsTableTableOrderingComposer get classroomSubjectId {
    final $$ClassroomSubjectsTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.classroomSubjectId,
          referencedTable: $db.classroomSubjectsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ClassroomSubjectsTableTableOrderingComposer(
                $db: $db,
                $table: $db.classroomSubjectsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$PlannedLessonsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlannedLessonsTableTable> {
  $$PlannedLessonsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get lessonDate =>
      $composableBuilder(
        column: $table.lessonDate,
        builder: (column) => column,
      );

  GeneratedColumn<int> get orderInDay => $composableBuilder(
    column: $table.orderInDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isLocked =>
      $composableBuilder(column: $table.isLocked, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ClassroomSubjectsTableTableAnnotationComposer get classroomSubjectId {
    final $$ClassroomSubjectsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.classroomSubjectId,
          referencedTable: $db.classroomSubjectsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ClassroomSubjectsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.classroomSubjectsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$PlannedLessonsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlannedLessonsTableTable,
          PlannedLessonsTableData,
          $$PlannedLessonsTableTableFilterComposer,
          $$PlannedLessonsTableTableOrderingComposer,
          $$PlannedLessonsTableTableAnnotationComposer,
          $$PlannedLessonsTableTableCreateCompanionBuilder,
          $$PlannedLessonsTableTableUpdateCompanionBuilder,
          (PlannedLessonsTableData, $$PlannedLessonsTableTableReferences),
          PlannedLessonsTableData,
          PrefetchHooks Function({bool classroomSubjectId})
        > {
  $$PlannedLessonsTableTableTableManager(
    _$AppDatabase db,
    $PlannedLessonsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlannedLessonsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlannedLessonsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PlannedLessonsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> classroomSubjectId = const Value.absent(),
                Value<DateTime> lessonDate = const Value.absent(),
                Value<int> orderInDay = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> isLocked = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlannedLessonsTableCompanion(
                id: id,
                classroomSubjectId: classroomSubjectId,
                lessonDate: lessonDate,
                orderInDay: orderInDay,
                status: status,
                isLocked: isLocked,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String classroomSubjectId,
                required DateTime lessonDate,
                required int orderInDay,
                required String status,
                Value<bool> isLocked = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PlannedLessonsTableCompanion.insert(
                id: id,
                classroomSubjectId: classroomSubjectId,
                lessonDate: lessonDate,
                orderInDay: orderInDay,
                status: status,
                isLocked: isLocked,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $PlannedLessonsTableTable,
                    PlannedLessonsTableData
                  >(table),
                  $$PlannedLessonsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({classroomSubjectId = false}) {
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
                    if (classroomSubjectId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.classroomSubjectId,
                        referencedTable: $$PlannedLessonsTableTableReferences
                            ._classroomSubjectIdTable(db),
                        referencedColumn: $$PlannedLessonsTableTableReferences
                            ._classroomSubjectIdTable(db)
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

typedef $$PlannedLessonsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlannedLessonsTableTable,
      PlannedLessonsTableData,
      $$PlannedLessonsTableTableFilterComposer,
      $$PlannedLessonsTableTableOrderingComposer,
      $$PlannedLessonsTableTableAnnotationComposer,
      $$PlannedLessonsTableTableCreateCompanionBuilder,
      $$PlannedLessonsTableTableUpdateCompanionBuilder,
      (PlannedLessonsTableData, $$PlannedLessonsTableTableReferences),
      PlannedLessonsTableData,
      PrefetchHooks Function({bool classroomSubjectId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AcademicYearsTableTableTableManager get academicYearsTable =>
      $$AcademicYearsTableTableTableManager(_db, _db.academicYearsTable);
  $$ClassroomsTableTableTableManager get classroomsTable =>
      $$ClassroomsTableTableTableManager(_db, _db.classroomsTable);
  $$SubjectsTableTableTableManager get subjectsTable =>
      $$SubjectsTableTableTableManager(_db, _db.subjectsTable);
  $$ClassroomSubjectsTableTableTableManager get classroomSubjectsTable =>
      $$ClassroomSubjectsTableTableTableManager(
        _db,
        _db.classroomSubjectsTable,
      );
  $$PlannedLessonsTableTableTableManager get plannedLessonsTable =>
      $$PlannedLessonsTableTableTableManager(_db, _db.plannedLessonsTable);
}
