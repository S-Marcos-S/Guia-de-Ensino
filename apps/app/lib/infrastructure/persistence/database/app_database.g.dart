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

class $SchoolCalendarEventsTableTable extends SchoolCalendarEventsTable
    with
        TableInfo<
          $SchoolCalendarEventsTableTable,
          SchoolCalendarEventsTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchoolCalendarEventsTableTable(this.attachedDatabase, [this._alias]);
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
      'REFERENCES academic_years_table (id) ON DELETE CASCADE',
    ),
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
      ).withConverter<DateTime>(
        $SchoolCalendarEventsTableTable.$converterstartDate,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> endDate =
      GeneratedColumn<String>(
        'end_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DateTime>(
        $SchoolCalendarEventsTableTable.$converterendDate,
      );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _affectsClassesMeta = const VerificationMeta(
    'affectsClasses',
  );
  @override
  late final GeneratedColumn<bool> affectsClasses = GeneratedColumn<bool>(
    'affects_classes',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("affects_classes" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    title,
    startDate,
    endDate,
    type,
    affectsClasses,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'school_calendar_events_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SchoolCalendarEventsTableData> instance, {
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
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('affects_classes')) {
      context.handle(
        _affectsClassesMeta,
        affectsClasses.isAcceptableOrUnknown(
          data['affects_classes']!,
          _affectsClassesMeta,
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
  SchoolCalendarEventsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SchoolCalendarEventsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      academicYearId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}academic_year_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      startDate: $SchoolCalendarEventsTableTable.$converterstartDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}start_date'],
        )!,
      ),
      endDate: $SchoolCalendarEventsTableTable.$converterendDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}end_date'],
        )!,
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      affectsClasses: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}affects_classes'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SchoolCalendarEventsTableTable createAlias(String alias) {
    return $SchoolCalendarEventsTableTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $converterstartDate =
      const CalendarDateConverter();
  static TypeConverter<DateTime, String> $converterendDate =
      const CalendarDateConverter();
}

class SchoolCalendarEventsTableData extends DataClass
    implements Insertable<SchoolCalendarEventsTableData> {
  final String id;
  final String academicYearId;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String type;
  final bool affectsClasses;
  final DateTime createdAt;
  const SchoolCalendarEventsTableData({
    required this.id,
    required this.academicYearId,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.affectsClasses,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['academic_year_id'] = Variable<String>(academicYearId);
    map['title'] = Variable<String>(title);
    {
      map['start_date'] = Variable<String>(
        $SchoolCalendarEventsTableTable.$converterstartDate.toSql(startDate),
      );
    }
    {
      map['end_date'] = Variable<String>(
        $SchoolCalendarEventsTableTable.$converterendDate.toSql(endDate),
      );
    }
    map['type'] = Variable<String>(type);
    map['affects_classes'] = Variable<bool>(affectsClasses);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SchoolCalendarEventsTableCompanion toCompanion(bool nullToAbsent) {
    return SchoolCalendarEventsTableCompanion(
      id: Value(id),
      academicYearId: Value(academicYearId),
      title: Value(title),
      startDate: Value(startDate),
      endDate: Value(endDate),
      type: Value(type),
      affectsClasses: Value(affectsClasses),
      createdAt: Value(createdAt),
    );
  }

  factory SchoolCalendarEventsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SchoolCalendarEventsTableData(
      id: serializer.fromJson<String>(json['id']),
      academicYearId: serializer.fromJson<String>(json['academicYearId']),
      title: serializer.fromJson<String>(json['title']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime>(json['endDate']),
      type: serializer.fromJson<String>(json['type']),
      affectsClasses: serializer.fromJson<bool>(json['affectsClasses']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'academicYearId': serializer.toJson<String>(academicYearId),
      'title': serializer.toJson<String>(title),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime>(endDate),
      'type': serializer.toJson<String>(type),
      'affectsClasses': serializer.toJson<bool>(affectsClasses),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SchoolCalendarEventsTableData copyWith({
    String? id,
    String? academicYearId,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    bool? affectsClasses,
    DateTime? createdAt,
  }) => SchoolCalendarEventsTableData(
    id: id ?? this.id,
    academicYearId: academicYearId ?? this.academicYearId,
    title: title ?? this.title,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    type: type ?? this.type,
    affectsClasses: affectsClasses ?? this.affectsClasses,
    createdAt: createdAt ?? this.createdAt,
  );
  SchoolCalendarEventsTableData copyWithCompanion(
    SchoolCalendarEventsTableCompanion data,
  ) {
    return SchoolCalendarEventsTableData(
      id: data.id.present ? data.id.value : this.id,
      academicYearId: data.academicYearId.present
          ? data.academicYearId.value
          : this.academicYearId,
      title: data.title.present ? data.title.value : this.title,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      type: data.type.present ? data.type.value : this.type,
      affectsClasses: data.affectsClasses.present
          ? data.affectsClasses.value
          : this.affectsClasses,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SchoolCalendarEventsTableData(')
          ..write('id: $id, ')
          ..write('academicYearId: $academicYearId, ')
          ..write('title: $title, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('type: $type, ')
          ..write('affectsClasses: $affectsClasses, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    academicYearId,
    title,
    startDate,
    endDate,
    type,
    affectsClasses,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SchoolCalendarEventsTableData &&
          other.id == this.id &&
          other.academicYearId == this.academicYearId &&
          other.title == this.title &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.type == this.type &&
          other.affectsClasses == this.affectsClasses &&
          other.createdAt == this.createdAt);
}

class SchoolCalendarEventsTableCompanion
    extends UpdateCompanion<SchoolCalendarEventsTableData> {
  final Value<String> id;
  final Value<String> academicYearId;
  final Value<String> title;
  final Value<DateTime> startDate;
  final Value<DateTime> endDate;
  final Value<String> type;
  final Value<bool> affectsClasses;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SchoolCalendarEventsTableCompanion({
    this.id = const Value.absent(),
    this.academicYearId = const Value.absent(),
    this.title = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.type = const Value.absent(),
    this.affectsClasses = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SchoolCalendarEventsTableCompanion.insert({
    required String id,
    required String academicYearId,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required String type,
    this.affectsClasses = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       academicYearId = Value(academicYearId),
       title = Value(title),
       startDate = Value(startDate),
       endDate = Value(endDate),
       type = Value(type),
       createdAt = Value(createdAt);
  static Insertable<SchoolCalendarEventsTableData> custom({
    Expression<String>? id,
    Expression<String>? academicYearId,
    Expression<String>? title,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<String>? type,
    Expression<bool>? affectsClasses,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (academicYearId != null) 'academic_year_id': academicYearId,
      if (title != null) 'title': title,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (type != null) 'type': type,
      if (affectsClasses != null) 'affects_classes': affectsClasses,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SchoolCalendarEventsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? academicYearId,
    Value<String>? title,
    Value<DateTime>? startDate,
    Value<DateTime>? endDate,
    Value<String>? type,
    Value<bool>? affectsClasses,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SchoolCalendarEventsTableCompanion(
      id: id ?? this.id,
      academicYearId: academicYearId ?? this.academicYearId,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      affectsClasses: affectsClasses ?? this.affectsClasses,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(
        $SchoolCalendarEventsTableTable.$converterstartDate.toSql(
          startDate.value,
        ),
      );
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(
        $SchoolCalendarEventsTableTable.$converterendDate.toSql(endDate.value),
      );
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (affectsClasses.present) {
      map['affects_classes'] = Variable<bool>(affectsClasses.value);
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
    return (StringBuffer('SchoolCalendarEventsTableCompanion(')
          ..write('id: $id, ')
          ..write('academicYearId: $academicYearId, ')
          ..write('title: $title, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('type: $type, ')
          ..write('affectsClasses: $affectsClasses, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScheduleSlotsTableTable extends ScheduleSlotsTable
    with TableInfo<$ScheduleSlotsTableTable, ScheduleSlotsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduleSlotsTableTable(this.attachedDatabase, [this._alias]);
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
          'REFERENCES classroom_subjects_table (id) ON DELETE CASCADE',
        ),
      );
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
    'weekday',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
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
    weekday,
    orderIndex,
    startTime,
    endTime,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedule_slots_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScheduleSlotsTableData> instance, {
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
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    } else if (isInserting) {
      context.missing(_weekdayMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
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
    {classroomSubjectId, weekday, orderIndex},
  ];
  @override
  ScheduleSlotsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduleSlotsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      classroomSubjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}classroom_subject_id'],
      )!,
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      ),
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ScheduleSlotsTableTable createAlias(String alias) {
    return $ScheduleSlotsTableTable(attachedDatabase, alias);
  }
}

class ScheduleSlotsTableData extends DataClass
    implements Insertable<ScheduleSlotsTableData> {
  final String id;
  final String classroomSubjectId;
  final int weekday;
  final int orderIndex;
  final String? startTime;
  final String? endTime;
  final DateTime createdAt;
  const ScheduleSlotsTableData({
    required this.id,
    required this.classroomSubjectId,
    required this.weekday,
    required this.orderIndex,
    this.startTime,
    this.endTime,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['classroom_subject_id'] = Variable<String>(classroomSubjectId);
    map['weekday'] = Variable<int>(weekday);
    map['order_index'] = Variable<int>(orderIndex);
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<String>(startTime);
    }
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<String>(endTime);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ScheduleSlotsTableCompanion toCompanion(bool nullToAbsent) {
    return ScheduleSlotsTableCompanion(
      id: Value(id),
      classroomSubjectId: Value(classroomSubjectId),
      weekday: Value(weekday),
      orderIndex: Value(orderIndex),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      createdAt: Value(createdAt),
    );
  }

  factory ScheduleSlotsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduleSlotsTableData(
      id: serializer.fromJson<String>(json['id']),
      classroomSubjectId: serializer.fromJson<String>(
        json['classroomSubjectId'],
      ),
      weekday: serializer.fromJson<int>(json['weekday']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      startTime: serializer.fromJson<String?>(json['startTime']),
      endTime: serializer.fromJson<String?>(json['endTime']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'classroomSubjectId': serializer.toJson<String>(classroomSubjectId),
      'weekday': serializer.toJson<int>(weekday),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'startTime': serializer.toJson<String?>(startTime),
      'endTime': serializer.toJson<String?>(endTime),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ScheduleSlotsTableData copyWith({
    String? id,
    String? classroomSubjectId,
    int? weekday,
    int? orderIndex,
    Value<String?> startTime = const Value.absent(),
    Value<String?> endTime = const Value.absent(),
    DateTime? createdAt,
  }) => ScheduleSlotsTableData(
    id: id ?? this.id,
    classroomSubjectId: classroomSubjectId ?? this.classroomSubjectId,
    weekday: weekday ?? this.weekday,
    orderIndex: orderIndex ?? this.orderIndex,
    startTime: startTime.present ? startTime.value : this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    createdAt: createdAt ?? this.createdAt,
  );
  ScheduleSlotsTableData copyWithCompanion(ScheduleSlotsTableCompanion data) {
    return ScheduleSlotsTableData(
      id: data.id.present ? data.id.value : this.id,
      classroomSubjectId: data.classroomSubjectId.present
          ? data.classroomSubjectId.value
          : this.classroomSubjectId,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleSlotsTableData(')
          ..write('id: $id, ')
          ..write('classroomSubjectId: $classroomSubjectId, ')
          ..write('weekday: $weekday, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    classroomSubjectId,
    weekday,
    orderIndex,
    startTime,
    endTime,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduleSlotsTableData &&
          other.id == this.id &&
          other.classroomSubjectId == this.classroomSubjectId &&
          other.weekday == this.weekday &&
          other.orderIndex == this.orderIndex &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.createdAt == this.createdAt);
}

class ScheduleSlotsTableCompanion
    extends UpdateCompanion<ScheduleSlotsTableData> {
  final Value<String> id;
  final Value<String> classroomSubjectId;
  final Value<int> weekday;
  final Value<int> orderIndex;
  final Value<String?> startTime;
  final Value<String?> endTime;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ScheduleSlotsTableCompanion({
    this.id = const Value.absent(),
    this.classroomSubjectId = const Value.absent(),
    this.weekday = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScheduleSlotsTableCompanion.insert({
    required String id,
    required String classroomSubjectId,
    required int weekday,
    required int orderIndex,
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       classroomSubjectId = Value(classroomSubjectId),
       weekday = Value(weekday),
       orderIndex = Value(orderIndex),
       createdAt = Value(createdAt);
  static Insertable<ScheduleSlotsTableData> custom({
    Expression<String>? id,
    Expression<String>? classroomSubjectId,
    Expression<int>? weekday,
    Expression<int>? orderIndex,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (classroomSubjectId != null)
        'classroom_subject_id': classroomSubjectId,
      if (weekday != null) 'weekday': weekday,
      if (orderIndex != null) 'order_index': orderIndex,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScheduleSlotsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? classroomSubjectId,
    Value<int>? weekday,
    Value<int>? orderIndex,
    Value<String?>? startTime,
    Value<String?>? endTime,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ScheduleSlotsTableCompanion(
      id: id ?? this.id,
      classroomSubjectId: classroomSubjectId ?? this.classroomSubjectId,
      weekday: weekday ?? this.weekday,
      orderIndex: orderIndex ?? this.orderIndex,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
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
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
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
    return (StringBuffer('ScheduleSlotsTableCompanion(')
          ..write('id: $id, ')
          ..write('classroomSubjectId: $classroomSubjectId, ')
          ..write('weekday: $weekday, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CurriculumCompetenciesTableTable extends CurriculumCompetenciesTable
    with
        TableInfo<
          $CurriculumCompetenciesTableTable,
          CurriculumCompetenciesTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CurriculumCompetenciesTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _thematicUnitMeta = const VerificationMeta(
    'thematicUnit',
  );
  @override
  late final GeneratedColumn<String> thematicUnit = GeneratedColumn<String>(
    'thematic_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _knowledgeObjectMeta = const VerificationMeta(
    'knowledgeObject',
  );
  @override
  late final GeneratedColumn<String> knowledgeObject = GeneratedColumn<String>(
    'knowledge_object',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<String> stage = GeneratedColumn<String>(
    'stage',
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
  static const VerificationMeta _subjectNameMeta = const VerificationMeta(
    'subjectName',
  );
  @override
  late final GeneratedColumn<String> subjectName = GeneratedColumn<String>(
    'subject_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceNameMeta = const VerificationMeta(
    'sourceName',
  );
  @override
  late final GeneratedColumn<String> sourceName = GeneratedColumn<String>(
    'source_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceVersionMeta = const VerificationMeta(
    'sourceVersion',
  );
  @override
  late final GeneratedColumn<String> sourceVersion = GeneratedColumn<String>(
    'source_version',
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
    code,
    description,
    thematicUnit,
    knowledgeObject,
    stage,
    gradeLevel,
    subjectName,
    sourceName,
    sourceVersion,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'curriculum_competencies_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<CurriculumCompetenciesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    if (data.containsKey('thematic_unit')) {
      context.handle(
        _thematicUnitMeta,
        thematicUnit.isAcceptableOrUnknown(
          data['thematic_unit']!,
          _thematicUnitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_thematicUnitMeta);
    }
    if (data.containsKey('knowledge_object')) {
      context.handle(
        _knowledgeObjectMeta,
        knowledgeObject.isAcceptableOrUnknown(
          data['knowledge_object']!,
          _knowledgeObjectMeta,
        ),
      );
    }
    if (data.containsKey('stage')) {
      context.handle(
        _stageMeta,
        stage.isAcceptableOrUnknown(data['stage']!, _stageMeta),
      );
    } else if (isInserting) {
      context.missing(_stageMeta);
    }
    if (data.containsKey('grade_level')) {
      context.handle(
        _gradeLevelMeta,
        gradeLevel.isAcceptableOrUnknown(data['grade_level']!, _gradeLevelMeta),
      );
    } else if (isInserting) {
      context.missing(_gradeLevelMeta);
    }
    if (data.containsKey('subject_name')) {
      context.handle(
        _subjectNameMeta,
        subjectName.isAcceptableOrUnknown(
          data['subject_name']!,
          _subjectNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subjectNameMeta);
    }
    if (data.containsKey('source_name')) {
      context.handle(
        _sourceNameMeta,
        sourceName.isAcceptableOrUnknown(data['source_name']!, _sourceNameMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceNameMeta);
    }
    if (data.containsKey('source_version')) {
      context.handle(
        _sourceVersionMeta,
        sourceVersion.isAcceptableOrUnknown(
          data['source_version']!,
          _sourceVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceVersionMeta);
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
    {code},
  ];
  @override
  CurriculumCompetenciesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CurriculumCompetenciesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      thematicUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thematic_unit'],
      )!,
      knowledgeObject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}knowledge_object'],
      ),
      stage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stage'],
      )!,
      gradeLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grade_level'],
      )!,
      subjectName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_name'],
      )!,
      sourceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_name'],
      )!,
      sourceVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CurriculumCompetenciesTableTable createAlias(String alias) {
    return $CurriculumCompetenciesTableTable(attachedDatabase, alias);
  }
}

class CurriculumCompetenciesTableData extends DataClass
    implements Insertable<CurriculumCompetenciesTableData> {
  final String id;
  final String code;
  final String description;
  final String thematicUnit;
  final String? knowledgeObject;
  final String stage;
  final String gradeLevel;
  final String subjectName;
  final String sourceName;
  final String sourceVersion;
  final DateTime createdAt;
  const CurriculumCompetenciesTableData({
    required this.id,
    required this.code,
    required this.description,
    required this.thematicUnit,
    this.knowledgeObject,
    required this.stage,
    required this.gradeLevel,
    required this.subjectName,
    required this.sourceName,
    required this.sourceVersion,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['description'] = Variable<String>(description);
    map['thematic_unit'] = Variable<String>(thematicUnit);
    if (!nullToAbsent || knowledgeObject != null) {
      map['knowledge_object'] = Variable<String>(knowledgeObject);
    }
    map['stage'] = Variable<String>(stage);
    map['grade_level'] = Variable<String>(gradeLevel);
    map['subject_name'] = Variable<String>(subjectName);
    map['source_name'] = Variable<String>(sourceName);
    map['source_version'] = Variable<String>(sourceVersion);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CurriculumCompetenciesTableCompanion toCompanion(bool nullToAbsent) {
    return CurriculumCompetenciesTableCompanion(
      id: Value(id),
      code: Value(code),
      description: Value(description),
      thematicUnit: Value(thematicUnit),
      knowledgeObject: knowledgeObject == null && nullToAbsent
          ? const Value.absent()
          : Value(knowledgeObject),
      stage: Value(stage),
      gradeLevel: Value(gradeLevel),
      subjectName: Value(subjectName),
      sourceName: Value(sourceName),
      sourceVersion: Value(sourceVersion),
      createdAt: Value(createdAt),
    );
  }

  factory CurriculumCompetenciesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CurriculumCompetenciesTableData(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      description: serializer.fromJson<String>(json['description']),
      thematicUnit: serializer.fromJson<String>(json['thematicUnit']),
      knowledgeObject: serializer.fromJson<String?>(json['knowledgeObject']),
      stage: serializer.fromJson<String>(json['stage']),
      gradeLevel: serializer.fromJson<String>(json['gradeLevel']),
      subjectName: serializer.fromJson<String>(json['subjectName']),
      sourceName: serializer.fromJson<String>(json['sourceName']),
      sourceVersion: serializer.fromJson<String>(json['sourceVersion']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'description': serializer.toJson<String>(description),
      'thematicUnit': serializer.toJson<String>(thematicUnit),
      'knowledgeObject': serializer.toJson<String?>(knowledgeObject),
      'stage': serializer.toJson<String>(stage),
      'gradeLevel': serializer.toJson<String>(gradeLevel),
      'subjectName': serializer.toJson<String>(subjectName),
      'sourceName': serializer.toJson<String>(sourceName),
      'sourceVersion': serializer.toJson<String>(sourceVersion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CurriculumCompetenciesTableData copyWith({
    String? id,
    String? code,
    String? description,
    String? thematicUnit,
    Value<String?> knowledgeObject = const Value.absent(),
    String? stage,
    String? gradeLevel,
    String? subjectName,
    String? sourceName,
    String? sourceVersion,
    DateTime? createdAt,
  }) => CurriculumCompetenciesTableData(
    id: id ?? this.id,
    code: code ?? this.code,
    description: description ?? this.description,
    thematicUnit: thematicUnit ?? this.thematicUnit,
    knowledgeObject: knowledgeObject.present
        ? knowledgeObject.value
        : this.knowledgeObject,
    stage: stage ?? this.stage,
    gradeLevel: gradeLevel ?? this.gradeLevel,
    subjectName: subjectName ?? this.subjectName,
    sourceName: sourceName ?? this.sourceName,
    sourceVersion: sourceVersion ?? this.sourceVersion,
    createdAt: createdAt ?? this.createdAt,
  );
  CurriculumCompetenciesTableData copyWithCompanion(
    CurriculumCompetenciesTableCompanion data,
  ) {
    return CurriculumCompetenciesTableData(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      description: data.description.present
          ? data.description.value
          : this.description,
      thematicUnit: data.thematicUnit.present
          ? data.thematicUnit.value
          : this.thematicUnit,
      knowledgeObject: data.knowledgeObject.present
          ? data.knowledgeObject.value
          : this.knowledgeObject,
      stage: data.stage.present ? data.stage.value : this.stage,
      gradeLevel: data.gradeLevel.present
          ? data.gradeLevel.value
          : this.gradeLevel,
      subjectName: data.subjectName.present
          ? data.subjectName.value
          : this.subjectName,
      sourceName: data.sourceName.present
          ? data.sourceName.value
          : this.sourceName,
      sourceVersion: data.sourceVersion.present
          ? data.sourceVersion.value
          : this.sourceVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CurriculumCompetenciesTableData(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('description: $description, ')
          ..write('thematicUnit: $thematicUnit, ')
          ..write('knowledgeObject: $knowledgeObject, ')
          ..write('stage: $stage, ')
          ..write('gradeLevel: $gradeLevel, ')
          ..write('subjectName: $subjectName, ')
          ..write('sourceName: $sourceName, ')
          ..write('sourceVersion: $sourceVersion, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    code,
    description,
    thematicUnit,
    knowledgeObject,
    stage,
    gradeLevel,
    subjectName,
    sourceName,
    sourceVersion,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CurriculumCompetenciesTableData &&
          other.id == this.id &&
          other.code == this.code &&
          other.description == this.description &&
          other.thematicUnit == this.thematicUnit &&
          other.knowledgeObject == this.knowledgeObject &&
          other.stage == this.stage &&
          other.gradeLevel == this.gradeLevel &&
          other.subjectName == this.subjectName &&
          other.sourceName == this.sourceName &&
          other.sourceVersion == this.sourceVersion &&
          other.createdAt == this.createdAt);
}

class CurriculumCompetenciesTableCompanion
    extends UpdateCompanion<CurriculumCompetenciesTableData> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> description;
  final Value<String> thematicUnit;
  final Value<String?> knowledgeObject;
  final Value<String> stage;
  final Value<String> gradeLevel;
  final Value<String> subjectName;
  final Value<String> sourceName;
  final Value<String> sourceVersion;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CurriculumCompetenciesTableCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.description = const Value.absent(),
    this.thematicUnit = const Value.absent(),
    this.knowledgeObject = const Value.absent(),
    this.stage = const Value.absent(),
    this.gradeLevel = const Value.absent(),
    this.subjectName = const Value.absent(),
    this.sourceName = const Value.absent(),
    this.sourceVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CurriculumCompetenciesTableCompanion.insert({
    required String id,
    required String code,
    required String description,
    required String thematicUnit,
    this.knowledgeObject = const Value.absent(),
    required String stage,
    required String gradeLevel,
    required String subjectName,
    required String sourceName,
    required String sourceVersion,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       code = Value(code),
       description = Value(description),
       thematicUnit = Value(thematicUnit),
       stage = Value(stage),
       gradeLevel = Value(gradeLevel),
       subjectName = Value(subjectName),
       sourceName = Value(sourceName),
       sourceVersion = Value(sourceVersion),
       createdAt = Value(createdAt);
  static Insertable<CurriculumCompetenciesTableData> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? description,
    Expression<String>? thematicUnit,
    Expression<String>? knowledgeObject,
    Expression<String>? stage,
    Expression<String>? gradeLevel,
    Expression<String>? subjectName,
    Expression<String>? sourceName,
    Expression<String>? sourceVersion,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (description != null) 'description': description,
      if (thematicUnit != null) 'thematic_unit': thematicUnit,
      if (knowledgeObject != null) 'knowledge_object': knowledgeObject,
      if (stage != null) 'stage': stage,
      if (gradeLevel != null) 'grade_level': gradeLevel,
      if (subjectName != null) 'subject_name': subjectName,
      if (sourceName != null) 'source_name': sourceName,
      if (sourceVersion != null) 'source_version': sourceVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CurriculumCompetenciesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<String>? description,
    Value<String>? thematicUnit,
    Value<String?>? knowledgeObject,
    Value<String>? stage,
    Value<String>? gradeLevel,
    Value<String>? subjectName,
    Value<String>? sourceName,
    Value<String>? sourceVersion,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CurriculumCompetenciesTableCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      thematicUnit: thematicUnit ?? this.thematicUnit,
      knowledgeObject: knowledgeObject ?? this.knowledgeObject,
      stage: stage ?? this.stage,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      subjectName: subjectName ?? this.subjectName,
      sourceName: sourceName ?? this.sourceName,
      sourceVersion: sourceVersion ?? this.sourceVersion,
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
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (thematicUnit.present) {
      map['thematic_unit'] = Variable<String>(thematicUnit.value);
    }
    if (knowledgeObject.present) {
      map['knowledge_object'] = Variable<String>(knowledgeObject.value);
    }
    if (stage.present) {
      map['stage'] = Variable<String>(stage.value);
    }
    if (gradeLevel.present) {
      map['grade_level'] = Variable<String>(gradeLevel.value);
    }
    if (subjectName.present) {
      map['subject_name'] = Variable<String>(subjectName.value);
    }
    if (sourceName.present) {
      map['source_name'] = Variable<String>(sourceName.value);
    }
    if (sourceVersion.present) {
      map['source_version'] = Variable<String>(sourceVersion.value);
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
    return (StringBuffer('CurriculumCompetenciesTableCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('description: $description, ')
          ..write('thematicUnit: $thematicUnit, ')
          ..write('knowledgeObject: $knowledgeObject, ')
          ..write('stage: $stage, ')
          ..write('gradeLevel: $gradeLevel, ')
          ..write('subjectName: $subjectName, ')
          ..write('sourceName: $sourceName, ')
          ..write('sourceVersion: $sourceVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CourseContentsTableTable extends CourseContentsTable
    with TableInfo<$CourseContentsTableTable, CourseContentsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CourseContentsTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thematicUnitMeta = const VerificationMeta(
    'thematicUnit',
  );
  @override
  late final GeneratedColumn<String> thematicUnit = GeneratedColumn<String>(
    'thematic_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estimatedLessonsMeta = const VerificationMeta(
    'estimatedLessons',
  );
  @override
  late final GeneratedColumn<int> estimatedLessons = GeneratedColumn<int>(
    'estimated_lessons',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isMandatoryMeta = const VerificationMeta(
    'isMandatory',
  );
  @override
  late final GeneratedColumn<bool> isMandatory = GeneratedColumn<bool>(
    'is_mandatory',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_mandatory" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _curriculumCompetencyIdMeta =
      const VerificationMeta('curriculumCompetencyId');
  @override
  late final GeneratedColumn<String> curriculumCompetencyId =
      GeneratedColumn<String>(
        'curriculum_competency_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES curriculum_competencies_table (id) ON DELETE SET NULL',
        ),
      );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
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
    classroomSubjectId,
    title,
    description,
    thematicUnit,
    estimatedLessons,
    orderIndex,
    isMandatory,
    curriculumCompetencyId,
    origin,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course_contents_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseContentsTableData> instance, {
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
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('thematic_unit')) {
      context.handle(
        _thematicUnitMeta,
        thematicUnit.isAcceptableOrUnknown(
          data['thematic_unit']!,
          _thematicUnitMeta,
        ),
      );
    }
    if (data.containsKey('estimated_lessons')) {
      context.handle(
        _estimatedLessonsMeta,
        estimatedLessons.isAcceptableOrUnknown(
          data['estimated_lessons']!,
          _estimatedLessonsMeta,
        ),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('is_mandatory')) {
      context.handle(
        _isMandatoryMeta,
        isMandatory.isAcceptableOrUnknown(
          data['is_mandatory']!,
          _isMandatoryMeta,
        ),
      );
    }
    if (data.containsKey('curriculum_competency_id')) {
      context.handle(
        _curriculumCompetencyIdMeta,
        curriculumCompetencyId.isAcceptableOrUnknown(
          data['curriculum_competency_id']!,
          _curriculumCompetencyIdMeta,
        ),
      );
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
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
  CourseContentsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseContentsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      classroomSubjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}classroom_subject_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      thematicUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thematic_unit'],
      ),
      estimatedLessons: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimated_lessons'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      isMandatory: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_mandatory'],
      )!,
      curriculumCompetencyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}curriculum_competency_id'],
      ),
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CourseContentsTableTable createAlias(String alias) {
    return $CourseContentsTableTable(attachedDatabase, alias);
  }
}

class CourseContentsTableData extends DataClass
    implements Insertable<CourseContentsTableData> {
  final String id;
  final String classroomSubjectId;
  final String title;
  final String? description;
  final String? thematicUnit;
  final int estimatedLessons;
  final int orderIndex;
  final bool isMandatory;
  final String? curriculumCompetencyId;
  final String origin;
  final DateTime createdAt;
  const CourseContentsTableData({
    required this.id,
    required this.classroomSubjectId,
    required this.title,
    this.description,
    this.thematicUnit,
    required this.estimatedLessons,
    required this.orderIndex,
    required this.isMandatory,
    this.curriculumCompetencyId,
    required this.origin,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['classroom_subject_id'] = Variable<String>(classroomSubjectId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || thematicUnit != null) {
      map['thematic_unit'] = Variable<String>(thematicUnit);
    }
    map['estimated_lessons'] = Variable<int>(estimatedLessons);
    map['order_index'] = Variable<int>(orderIndex);
    map['is_mandatory'] = Variable<bool>(isMandatory);
    if (!nullToAbsent || curriculumCompetencyId != null) {
      map['curriculum_competency_id'] = Variable<String>(
        curriculumCompetencyId,
      );
    }
    map['origin'] = Variable<String>(origin);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CourseContentsTableCompanion toCompanion(bool nullToAbsent) {
    return CourseContentsTableCompanion(
      id: Value(id),
      classroomSubjectId: Value(classroomSubjectId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      thematicUnit: thematicUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(thematicUnit),
      estimatedLessons: Value(estimatedLessons),
      orderIndex: Value(orderIndex),
      isMandatory: Value(isMandatory),
      curriculumCompetencyId: curriculumCompetencyId == null && nullToAbsent
          ? const Value.absent()
          : Value(curriculumCompetencyId),
      origin: Value(origin),
      createdAt: Value(createdAt),
    );
  }

  factory CourseContentsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseContentsTableData(
      id: serializer.fromJson<String>(json['id']),
      classroomSubjectId: serializer.fromJson<String>(
        json['classroomSubjectId'],
      ),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      thematicUnit: serializer.fromJson<String?>(json['thematicUnit']),
      estimatedLessons: serializer.fromJson<int>(json['estimatedLessons']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      isMandatory: serializer.fromJson<bool>(json['isMandatory']),
      curriculumCompetencyId: serializer.fromJson<String?>(
        json['curriculumCompetencyId'],
      ),
      origin: serializer.fromJson<String>(json['origin']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'classroomSubjectId': serializer.toJson<String>(classroomSubjectId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'thematicUnit': serializer.toJson<String?>(thematicUnit),
      'estimatedLessons': serializer.toJson<int>(estimatedLessons),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'isMandatory': serializer.toJson<bool>(isMandatory),
      'curriculumCompetencyId': serializer.toJson<String?>(
        curriculumCompetencyId,
      ),
      'origin': serializer.toJson<String>(origin),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CourseContentsTableData copyWith({
    String? id,
    String? classroomSubjectId,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<String?> thematicUnit = const Value.absent(),
    int? estimatedLessons,
    int? orderIndex,
    bool? isMandatory,
    Value<String?> curriculumCompetencyId = const Value.absent(),
    String? origin,
    DateTime? createdAt,
  }) => CourseContentsTableData(
    id: id ?? this.id,
    classroomSubjectId: classroomSubjectId ?? this.classroomSubjectId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    thematicUnit: thematicUnit.present ? thematicUnit.value : this.thematicUnit,
    estimatedLessons: estimatedLessons ?? this.estimatedLessons,
    orderIndex: orderIndex ?? this.orderIndex,
    isMandatory: isMandatory ?? this.isMandatory,
    curriculumCompetencyId: curriculumCompetencyId.present
        ? curriculumCompetencyId.value
        : this.curriculumCompetencyId,
    origin: origin ?? this.origin,
    createdAt: createdAt ?? this.createdAt,
  );
  CourseContentsTableData copyWithCompanion(CourseContentsTableCompanion data) {
    return CourseContentsTableData(
      id: data.id.present ? data.id.value : this.id,
      classroomSubjectId: data.classroomSubjectId.present
          ? data.classroomSubjectId.value
          : this.classroomSubjectId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      thematicUnit: data.thematicUnit.present
          ? data.thematicUnit.value
          : this.thematicUnit,
      estimatedLessons: data.estimatedLessons.present
          ? data.estimatedLessons.value
          : this.estimatedLessons,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      isMandatory: data.isMandatory.present
          ? data.isMandatory.value
          : this.isMandatory,
      curriculumCompetencyId: data.curriculumCompetencyId.present
          ? data.curriculumCompetencyId.value
          : this.curriculumCompetencyId,
      origin: data.origin.present ? data.origin.value : this.origin,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseContentsTableData(')
          ..write('id: $id, ')
          ..write('classroomSubjectId: $classroomSubjectId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('thematicUnit: $thematicUnit, ')
          ..write('estimatedLessons: $estimatedLessons, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('isMandatory: $isMandatory, ')
          ..write('curriculumCompetencyId: $curriculumCompetencyId, ')
          ..write('origin: $origin, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    classroomSubjectId,
    title,
    description,
    thematicUnit,
    estimatedLessons,
    orderIndex,
    isMandatory,
    curriculumCompetencyId,
    origin,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseContentsTableData &&
          other.id == this.id &&
          other.classroomSubjectId == this.classroomSubjectId &&
          other.title == this.title &&
          other.description == this.description &&
          other.thematicUnit == this.thematicUnit &&
          other.estimatedLessons == this.estimatedLessons &&
          other.orderIndex == this.orderIndex &&
          other.isMandatory == this.isMandatory &&
          other.curriculumCompetencyId == this.curriculumCompetencyId &&
          other.origin == this.origin &&
          other.createdAt == this.createdAt);
}

class CourseContentsTableCompanion
    extends UpdateCompanion<CourseContentsTableData> {
  final Value<String> id;
  final Value<String> classroomSubjectId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> thematicUnit;
  final Value<int> estimatedLessons;
  final Value<int> orderIndex;
  final Value<bool> isMandatory;
  final Value<String?> curriculumCompetencyId;
  final Value<String> origin;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CourseContentsTableCompanion({
    this.id = const Value.absent(),
    this.classroomSubjectId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.thematicUnit = const Value.absent(),
    this.estimatedLessons = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.isMandatory = const Value.absent(),
    this.curriculumCompetencyId = const Value.absent(),
    this.origin = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CourseContentsTableCompanion.insert({
    required String id,
    required String classroomSubjectId,
    required String title,
    this.description = const Value.absent(),
    this.thematicUnit = const Value.absent(),
    this.estimatedLessons = const Value.absent(),
    required int orderIndex,
    this.isMandatory = const Value.absent(),
    this.curriculumCompetencyId = const Value.absent(),
    required String origin,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       classroomSubjectId = Value(classroomSubjectId),
       title = Value(title),
       orderIndex = Value(orderIndex),
       origin = Value(origin),
       createdAt = Value(createdAt);
  static Insertable<CourseContentsTableData> custom({
    Expression<String>? id,
    Expression<String>? classroomSubjectId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? thematicUnit,
    Expression<int>? estimatedLessons,
    Expression<int>? orderIndex,
    Expression<bool>? isMandatory,
    Expression<String>? curriculumCompetencyId,
    Expression<String>? origin,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (classroomSubjectId != null)
        'classroom_subject_id': classroomSubjectId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (thematicUnit != null) 'thematic_unit': thematicUnit,
      if (estimatedLessons != null) 'estimated_lessons': estimatedLessons,
      if (orderIndex != null) 'order_index': orderIndex,
      if (isMandatory != null) 'is_mandatory': isMandatory,
      if (curriculumCompetencyId != null)
        'curriculum_competency_id': curriculumCompetencyId,
      if (origin != null) 'origin': origin,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CourseContentsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? classroomSubjectId,
    Value<String>? title,
    Value<String?>? description,
    Value<String?>? thematicUnit,
    Value<int>? estimatedLessons,
    Value<int>? orderIndex,
    Value<bool>? isMandatory,
    Value<String?>? curriculumCompetencyId,
    Value<String>? origin,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CourseContentsTableCompanion(
      id: id ?? this.id,
      classroomSubjectId: classroomSubjectId ?? this.classroomSubjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      thematicUnit: thematicUnit ?? this.thematicUnit,
      estimatedLessons: estimatedLessons ?? this.estimatedLessons,
      orderIndex: orderIndex ?? this.orderIndex,
      isMandatory: isMandatory ?? this.isMandatory,
      curriculumCompetencyId:
          curriculumCompetencyId ?? this.curriculumCompetencyId,
      origin: origin ?? this.origin,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (thematicUnit.present) {
      map['thematic_unit'] = Variable<String>(thematicUnit.value);
    }
    if (estimatedLessons.present) {
      map['estimated_lessons'] = Variable<int>(estimatedLessons.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (isMandatory.present) {
      map['is_mandatory'] = Variable<bool>(isMandatory.value);
    }
    if (curriculumCompetencyId.present) {
      map['curriculum_competency_id'] = Variable<String>(
        curriculumCompetencyId.value,
      );
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
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
    return (StringBuffer('CourseContentsTableCompanion(')
          ..write('id: $id, ')
          ..write('classroomSubjectId: $classroomSubjectId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('thematicUnit: $thematicUnit, ')
          ..write('estimatedLessons: $estimatedLessons, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('isMandatory: $isMandatory, ')
          ..write('curriculumCompetencyId: $curriculumCompetencyId, ')
          ..write('origin: $origin, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContentPrerequisitesTableTable extends ContentPrerequisitesTable
    with
        TableInfo<
          $ContentPrerequisitesTableTable,
          ContentPrerequisitesTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentPrerequisitesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _contentIdMeta = const VerificationMeta(
    'contentId',
  );
  @override
  late final GeneratedColumn<String> contentId = GeneratedColumn<String>(
    'content_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES course_contents_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _prerequisiteContentIdMeta =
      const VerificationMeta('prerequisiteContentId');
  @override
  late final GeneratedColumn<String> prerequisiteContentId =
      GeneratedColumn<String>(
        'prerequisite_content_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES course_contents_table (id) ON DELETE RESTRICT',
        ),
      );
  @override
  List<GeneratedColumn> get $columns => [contentId, prerequisiteContentId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'content_prerequisites_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContentPrerequisitesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('content_id')) {
      context.handle(
        _contentIdMeta,
        contentId.isAcceptableOrUnknown(data['content_id']!, _contentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contentIdMeta);
    }
    if (data.containsKey('prerequisite_content_id')) {
      context.handle(
        _prerequisiteContentIdMeta,
        prerequisiteContentId.isAcceptableOrUnknown(
          data['prerequisite_content_id']!,
          _prerequisiteContentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_prerequisiteContentIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {contentId, prerequisiteContentId};
  @override
  ContentPrerequisitesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentPrerequisitesTableData(
      contentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_id'],
      )!,
      prerequisiteContentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prerequisite_content_id'],
      )!,
    );
  }

  @override
  $ContentPrerequisitesTableTable createAlias(String alias) {
    return $ContentPrerequisitesTableTable(attachedDatabase, alias);
  }
}

class ContentPrerequisitesTableData extends DataClass
    implements Insertable<ContentPrerequisitesTableData> {
  final String contentId;
  final String prerequisiteContentId;
  const ContentPrerequisitesTableData({
    required this.contentId,
    required this.prerequisiteContentId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['content_id'] = Variable<String>(contentId);
    map['prerequisite_content_id'] = Variable<String>(prerequisiteContentId);
    return map;
  }

  ContentPrerequisitesTableCompanion toCompanion(bool nullToAbsent) {
    return ContentPrerequisitesTableCompanion(
      contentId: Value(contentId),
      prerequisiteContentId: Value(prerequisiteContentId),
    );
  }

  factory ContentPrerequisitesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentPrerequisitesTableData(
      contentId: serializer.fromJson<String>(json['contentId']),
      prerequisiteContentId: serializer.fromJson<String>(
        json['prerequisiteContentId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contentId': serializer.toJson<String>(contentId),
      'prerequisiteContentId': serializer.toJson<String>(prerequisiteContentId),
    };
  }

  ContentPrerequisitesTableData copyWith({
    String? contentId,
    String? prerequisiteContentId,
  }) => ContentPrerequisitesTableData(
    contentId: contentId ?? this.contentId,
    prerequisiteContentId: prerequisiteContentId ?? this.prerequisiteContentId,
  );
  ContentPrerequisitesTableData copyWithCompanion(
    ContentPrerequisitesTableCompanion data,
  ) {
    return ContentPrerequisitesTableData(
      contentId: data.contentId.present ? data.contentId.value : this.contentId,
      prerequisiteContentId: data.prerequisiteContentId.present
          ? data.prerequisiteContentId.value
          : this.prerequisiteContentId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentPrerequisitesTableData(')
          ..write('contentId: $contentId, ')
          ..write('prerequisiteContentId: $prerequisiteContentId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(contentId, prerequisiteContentId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentPrerequisitesTableData &&
          other.contentId == this.contentId &&
          other.prerequisiteContentId == this.prerequisiteContentId);
}

class ContentPrerequisitesTableCompanion
    extends UpdateCompanion<ContentPrerequisitesTableData> {
  final Value<String> contentId;
  final Value<String> prerequisiteContentId;
  final Value<int> rowid;
  const ContentPrerequisitesTableCompanion({
    this.contentId = const Value.absent(),
    this.prerequisiteContentId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContentPrerequisitesTableCompanion.insert({
    required String contentId,
    required String prerequisiteContentId,
    this.rowid = const Value.absent(),
  }) : contentId = Value(contentId),
       prerequisiteContentId = Value(prerequisiteContentId);
  static Insertable<ContentPrerequisitesTableData> custom({
    Expression<String>? contentId,
    Expression<String>? prerequisiteContentId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (contentId != null) 'content_id': contentId,
      if (prerequisiteContentId != null)
        'prerequisite_content_id': prerequisiteContentId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContentPrerequisitesTableCompanion copyWith({
    Value<String>? contentId,
    Value<String>? prerequisiteContentId,
    Value<int>? rowid,
  }) {
    return ContentPrerequisitesTableCompanion(
      contentId: contentId ?? this.contentId,
      prerequisiteContentId:
          prerequisiteContentId ?? this.prerequisiteContentId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (contentId.present) {
      map['content_id'] = Variable<String>(contentId.value);
    }
    if (prerequisiteContentId.present) {
      map['prerequisite_content_id'] = Variable<String>(
        prerequisiteContentId.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContentPrerequisitesTableCompanion(')
          ..write('contentId: $contentId, ')
          ..write('prerequisiteContentId: $prerequisiteContentId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LessonContentAllocationsTableTable extends LessonContentAllocationsTable
    with
        TableInfo<
          $LessonContentAllocationsTableTable,
          LessonContentAllocationsTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonContentAllocationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
    'lesson_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES planned_lessons_table (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _contentIdMeta = const VerificationMeta(
    'contentId',
  );
  @override
  late final GeneratedColumn<String> contentId = GeneratedColumn<String>(
    'content_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES course_contents_table (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [lessonId, contentId, orderIndex];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lesson_content_allocations_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LessonContentAllocationsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('content_id')) {
      context.handle(
        _contentIdMeta,
        contentId.isAcceptableOrUnknown(data['content_id']!, _contentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contentIdMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lessonId, contentId};
  @override
  LessonContentAllocationsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonContentAllocationsTableData(
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_id'],
      )!,
      contentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_id'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
    );
  }

  @override
  $LessonContentAllocationsTableTable createAlias(String alias) {
    return $LessonContentAllocationsTableTable(attachedDatabase, alias);
  }
}

class LessonContentAllocationsTableData extends DataClass
    implements Insertable<LessonContentAllocationsTableData> {
  final String lessonId;
  final String contentId;
  final int orderIndex;
  const LessonContentAllocationsTableData({
    required this.lessonId,
    required this.contentId,
    required this.orderIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lesson_id'] = Variable<String>(lessonId);
    map['content_id'] = Variable<String>(contentId);
    map['order_index'] = Variable<int>(orderIndex);
    return map;
  }

  LessonContentAllocationsTableCompanion toCompanion(bool nullToAbsent) {
    return LessonContentAllocationsTableCompanion(
      lessonId: Value(lessonId),
      contentId: Value(contentId),
      orderIndex: Value(orderIndex),
    );
  }

  factory LessonContentAllocationsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonContentAllocationsTableData(
      lessonId: serializer.fromJson<String>(json['lessonId']),
      contentId: serializer.fromJson<String>(json['contentId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lessonId': serializer.toJson<String>(lessonId),
      'contentId': serializer.toJson<String>(contentId),
      'orderIndex': serializer.toJson<int>(orderIndex),
    };
  }

  LessonContentAllocationsTableData copyWith({
    String? lessonId,
    String? contentId,
    int? orderIndex,
  }) => LessonContentAllocationsTableData(
    lessonId: lessonId ?? this.lessonId,
    contentId: contentId ?? this.contentId,
    orderIndex: orderIndex ?? this.orderIndex,
  );
  LessonContentAllocationsTableData copyWithCompanion(
    LessonContentAllocationsTableCompanion data,
  ) {
    return LessonContentAllocationsTableData(
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      contentId: data.contentId.present ? data.contentId.value : this.contentId,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonContentAllocationsTableData(')
          ..write('lessonId: $lessonId, ')
          ..write('contentId: $contentId, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(lessonId, contentId, orderIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonContentAllocationsTableData &&
          other.lessonId == this.lessonId &&
          other.contentId == this.contentId &&
          other.orderIndex == this.orderIndex);
}

class LessonContentAllocationsTableCompanion
    extends UpdateCompanion<LessonContentAllocationsTableData> {
  final Value<String> lessonId;
  final Value<String> contentId;
  final Value<int> orderIndex;
  final Value<int> rowid;
  const LessonContentAllocationsTableCompanion({
    this.lessonId = const Value.absent(),
    this.contentId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LessonContentAllocationsTableCompanion.insert({
    required String lessonId,
    required String contentId,
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : lessonId = Value(lessonId),
       contentId = Value(contentId);
  static Insertable<LessonContentAllocationsTableData> custom({
    Expression<String>? lessonId,
    Expression<String>? contentId,
    Expression<int>? orderIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lessonId != null) 'lesson_id': lessonId,
      if (contentId != null) 'content_id': contentId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LessonContentAllocationsTableCompanion copyWith({
    Value<String>? lessonId,
    Value<String>? contentId,
    Value<int>? orderIndex,
    Value<int>? rowid,
  }) {
    return LessonContentAllocationsTableCompanion(
      lessonId: lessonId ?? this.lessonId,
      contentId: contentId ?? this.contentId,
      orderIndex: orderIndex ?? this.orderIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (contentId.present) {
      map['content_id'] = Variable<String>(contentId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonContentAllocationsTableCompanion(')
          ..write('lessonId: $lessonId, ')
          ..write('contentId: $contentId, ')
          ..write('orderIndex: $orderIndex, ')
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
  late final $SchoolCalendarEventsTableTable schoolCalendarEventsTable =
      $SchoolCalendarEventsTableTable(this);
  late final $ScheduleSlotsTableTable scheduleSlotsTable =
      $ScheduleSlotsTableTable(this);
  late final $CurriculumCompetenciesTableTable curriculumCompetenciesTable =
      $CurriculumCompetenciesTableTable(this);
  late final $CourseContentsTableTable courseContentsTable =
      $CourseContentsTableTable(this);
  late final $ContentPrerequisitesTableTable contentPrerequisitesTable =
      $ContentPrerequisitesTableTable(this);
  late final $LessonContentAllocationsTableTable lessonContentAllocationsTable =
      $LessonContentAllocationsTableTable(this);
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
    schoolCalendarEventsTable,
    scheduleSlotsTable,
    curriculumCompetenciesTable,
    courseContentsTable,
    contentPrerequisitesTable,
    lessonContentAllocationsTable,
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
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'academic_years_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('school_calendar_events_table', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'classroom_subjects_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('schedule_slots_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'curriculum_competencies_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('course_contents_table', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'course_contents_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('content_prerequisites_table', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'planned_lessons_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate(
          'lesson_content_allocations_table',
          kind: UpdateKind.delete,
        ),
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

  static MultiTypedResultKey<
    $SchoolCalendarEventsTableTable,
    List<SchoolCalendarEventsTableData>
  >
  _schoolCalendarEventsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.schoolCalendarEventsTable,
        aliasName: 'academic_years_table__id__school_calendar_events_table__academic_year_id',
      );

  $$SchoolCalendarEventsTableTableProcessedTableManager
  get schoolCalendarEventsTableRefs {
    final manager = $$SchoolCalendarEventsTableTableTableManager(
      $_db,
      $_db.schoolCalendarEventsTable,
    ).filter((f) => f.academicYearId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _schoolCalendarEventsTableRefsTable($_db),
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

  Expression<bool> schoolCalendarEventsTableRefs(
    Expression<bool> Function($$SchoolCalendarEventsTableTableFilterComposer f)
    f,
  ) {
    final $$SchoolCalendarEventsTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.schoolCalendarEventsTable,
          getReferencedColumn: (t) => t.academicYearId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SchoolCalendarEventsTableTableFilterComposer(
                $db: $db,
                $table: $db.schoolCalendarEventsTable,
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

  Expression<T> schoolCalendarEventsTableRefs<T extends Object>(
    Expression<T> Function($$SchoolCalendarEventsTableTableAnnotationComposer a)
    f,
  ) {
    final $$SchoolCalendarEventsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.schoolCalendarEventsTable,
          getReferencedColumn: (t) => t.academicYearId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SchoolCalendarEventsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.schoolCalendarEventsTable,
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
          PrefetchHooks Function({
            bool classroomsTableRefs,
            bool schoolCalendarEventsTableRefs,
          })
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
          prefetchHooksCallback:
              ({
                classroomsTableRefs = false,
                schoolCalendarEventsTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (classroomsTableRefs) db.classroomsTable,
                    if (schoolCalendarEventsTableRefs)
                      db.schoolCalendarEventsTable,
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
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.academicYearId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (schoolCalendarEventsTableRefs)
                        await $_getPrefetchedData<
                          AcademicYearsTableData,
                          $AcademicYearsTableTable,
                          SchoolCalendarEventsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$AcademicYearsTableTableReferences
                              ._schoolCalendarEventsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AcademicYearsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).schoolCalendarEventsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
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
      PrefetchHooks Function({
        bool classroomsTableRefs,
        bool schoolCalendarEventsTableRefs,
      })
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

  static MultiTypedResultKey<
    $ScheduleSlotsTableTable,
    List<ScheduleSlotsTableData>
  >
  _scheduleSlotsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.scheduleSlotsTable,
        aliasName: 'classroom_subjects_table__id__schedule_slots_table__classroom_subject_id',
      );

  $$ScheduleSlotsTableTableProcessedTableManager get scheduleSlotsTableRefs {
    final manager =
        $$ScheduleSlotsTableTableTableManager(
          $_db,
          $_db.scheduleSlotsTable,
        ).filter(
          (f) => f.classroomSubjectId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _scheduleSlotsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $CourseContentsTableTable,
    List<CourseContentsTableData>
  >
  _courseContentsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.courseContentsTable,
        aliasName: 'classroom_subjects_table__id__course_contents_table__classroom_subject_id',
      );

  $$CourseContentsTableTableProcessedTableManager get courseContentsTableRefs {
    final manager =
        $$CourseContentsTableTableTableManager(
          $_db,
          $_db.courseContentsTable,
        ).filter(
          (f) => f.classroomSubjectId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _courseContentsTableRefsTable($_db),
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

  Expression<bool> scheduleSlotsTableRefs(
    Expression<bool> Function($$ScheduleSlotsTableTableFilterComposer f) f,
  ) {
    final $$ScheduleSlotsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scheduleSlotsTable,
      getReferencedColumn: (t) => t.classroomSubjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScheduleSlotsTableTableFilterComposer(
            $db: $db,
            $table: $db.scheduleSlotsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> courseContentsTableRefs(
    Expression<bool> Function($$CourseContentsTableTableFilterComposer f) f,
  ) {
    final $$CourseContentsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseContentsTable,
      getReferencedColumn: (t) => t.classroomSubjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseContentsTableTableFilterComposer(
            $db: $db,
            $table: $db.courseContentsTable,
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

  Expression<T> scheduleSlotsTableRefs<T extends Object>(
    Expression<T> Function($$ScheduleSlotsTableTableAnnotationComposer a) f,
  ) {
    final $$ScheduleSlotsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.scheduleSlotsTable,
          getReferencedColumn: (t) => t.classroomSubjectId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ScheduleSlotsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.scheduleSlotsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> courseContentsTableRefs<T extends Object>(
    Expression<T> Function($$CourseContentsTableTableAnnotationComposer a) f,
  ) {
    final $$CourseContentsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.courseContentsTable,
          getReferencedColumn: (t) => t.classroomSubjectId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CourseContentsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.courseContentsTable,
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
            bool scheduleSlotsTableRefs,
            bool courseContentsTableRefs,
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
                scheduleSlotsTableRefs = false,
                courseContentsTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (plannedLessonsTableRefs) db.plannedLessonsTable,
                    if (scheduleSlotsTableRefs) db.scheduleSlotsTable,
                    if (courseContentsTableRefs) db.courseContentsTable,
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
                      if (scheduleSlotsTableRefs)
                        await $_getPrefetchedData<
                          ClassroomSubjectsTableData,
                          $ClassroomSubjectsTableTable,
                          ScheduleSlotsTableData
                        >(
                          currentTable: table,
                          referencedTable:
                              $$ClassroomSubjectsTableTableReferences
                                  ._scheduleSlotsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClassroomSubjectsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).scheduleSlotsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.classroomSubjectId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (courseContentsTableRefs)
                        await $_getPrefetchedData<
                          ClassroomSubjectsTableData,
                          $ClassroomSubjectsTableTable,
                          CourseContentsTableData
                        >(
                          currentTable: table,
                          referencedTable:
                              $$ClassroomSubjectsTableTableReferences
                                  ._courseContentsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClassroomSubjectsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).courseContentsTableRefs,
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
        bool scheduleSlotsTableRefs,
        bool courseContentsTableRefs,
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

  static MultiTypedResultKey<
    $LessonContentAllocationsTableTable,
    List<LessonContentAllocationsTableData>
  >
  _lessonAllocationsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.lessonContentAllocationsTable,
    aliasName: 'planned_lessons_table__id__lesson_content_allocations_table__lesson_id',
  );

  $$LessonContentAllocationsTableTableProcessedTableManager
  get lessonAllocations {
    final manager = $$LessonContentAllocationsTableTableTableManager(
      $_db,
      $_db.lessonContentAllocationsTable,
    ).filter((f) => f.lessonId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_lessonAllocationsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
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

  Expression<bool> lessonAllocations(
    Expression<bool> Function(
      $$LessonContentAllocationsTableTableFilterComposer f,
    )
    f,
  ) {
    final $$LessonContentAllocationsTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.lessonContentAllocationsTable,
          getReferencedColumn: (t) => t.lessonId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LessonContentAllocationsTableTableFilterComposer(
                $db: $db,
                $table: $db.lessonContentAllocationsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
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

  Expression<T> lessonAllocations<T extends Object>(
    Expression<T> Function(
      $$LessonContentAllocationsTableTableAnnotationComposer a,
    )
    f,
  ) {
    final $$LessonContentAllocationsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.lessonContentAllocationsTable,
          getReferencedColumn: (t) => t.lessonId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LessonContentAllocationsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.lessonContentAllocationsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
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
          PrefetchHooks Function({
            bool classroomSubjectId,
            bool lessonAllocations,
          })
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
          prefetchHooksCallback:
              ({classroomSubjectId = false, lessonAllocations = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (lessonAllocations) db.lessonContentAllocationsTable,
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
                        if (classroomSubjectId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.classroomSubjectId,
                            referencedTable:
                                $$PlannedLessonsTableTableReferences
                                    ._classroomSubjectIdTable(db),
                            referencedColumn:
                                $$PlannedLessonsTableTableReferences
                                    ._classroomSubjectIdTable(db)
                                    .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (lessonAllocations)
                        await $_getPrefetchedData<
                          PlannedLessonsTableData,
                          $PlannedLessonsTableTable,
                          LessonContentAllocationsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$PlannedLessonsTableTableReferences
                              ._lessonAllocationsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlannedLessonsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).lessonAllocations,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.lessonId == item.id,
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
      PrefetchHooks Function({bool classroomSubjectId, bool lessonAllocations})
    >;
typedef $$SchoolCalendarEventsTableTableCreateCompanionBuilder =
    SchoolCalendarEventsTableCompanion Function({
      required String id,
      required String academicYearId,
      required String title,
      required DateTime startDate,
      required DateTime endDate,
      required String type,
      Value<bool> affectsClasses,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$SchoolCalendarEventsTableTableUpdateCompanionBuilder =
    SchoolCalendarEventsTableCompanion Function({
      Value<String> id,
      Value<String> academicYearId,
      Value<String> title,
      Value<DateTime> startDate,
      Value<DateTime> endDate,
      Value<String> type,
      Value<bool> affectsClasses,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$SchoolCalendarEventsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SchoolCalendarEventsTableTable,
          SchoolCalendarEventsTableData
        > {
  $$SchoolCalendarEventsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AcademicYearsTableTable _academicYearIdTable(
    _$AppDatabase db,
  ) => db.academicYearsTable.createAlias(
    'school_calendar_events_table__academic_year_id__academic_years_table__id',
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
}

class $$SchoolCalendarEventsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SchoolCalendarEventsTableTable> {
  $$SchoolCalendarEventsTableTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get affectsClasses => $composableBuilder(
    column: $table.affectsClasses,
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
}

class $$SchoolCalendarEventsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SchoolCalendarEventsTableTable> {
  $$SchoolCalendarEventsTableTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get affectsClasses => $composableBuilder(
    column: $table.affectsClasses,
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

class $$SchoolCalendarEventsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SchoolCalendarEventsTableTable> {
  $$SchoolCalendarEventsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<bool> get affectsClasses => $composableBuilder(
    column: $table.affectsClasses,
    builder: (column) => column,
  );

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
}

class $$SchoolCalendarEventsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SchoolCalendarEventsTableTable,
          SchoolCalendarEventsTableData,
          $$SchoolCalendarEventsTableTableFilterComposer,
          $$SchoolCalendarEventsTableTableOrderingComposer,
          $$SchoolCalendarEventsTableTableAnnotationComposer,
          $$SchoolCalendarEventsTableTableCreateCompanionBuilder,
          $$SchoolCalendarEventsTableTableUpdateCompanionBuilder,
          (
            SchoolCalendarEventsTableData,
            $$SchoolCalendarEventsTableTableReferences,
          ),
          SchoolCalendarEventsTableData,
          PrefetchHooks Function({bool academicYearId})
        > {
  $$SchoolCalendarEventsTableTableTableManager(
    _$AppDatabase db,
    $SchoolCalendarEventsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SchoolCalendarEventsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SchoolCalendarEventsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SchoolCalendarEventsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> academicYearId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime> endDate = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<bool> affectsClasses = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SchoolCalendarEventsTableCompanion(
                id: id,
                academicYearId: academicYearId,
                title: title,
                startDate: startDate,
                endDate: endDate,
                type: type,
                affectsClasses: affectsClasses,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String academicYearId,
                required String title,
                required DateTime startDate,
                required DateTime endDate,
                required String type,
                Value<bool> affectsClasses = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SchoolCalendarEventsTableCompanion.insert(
                id: id,
                academicYearId: academicYearId,
                title: title,
                startDate: startDate,
                endDate: endDate,
                type: type,
                affectsClasses: affectsClasses,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $SchoolCalendarEventsTableTable,
                    SchoolCalendarEventsTableData
                  >(table),
                  $$SchoolCalendarEventsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({academicYearId = false}) {
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
                    if (academicYearId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.academicYearId,
                        referencedTable:
                            $$SchoolCalendarEventsTableTableReferences
                                ._academicYearIdTable(db),
                        referencedColumn:
                            $$SchoolCalendarEventsTableTableReferences
                                ._academicYearIdTable(db)
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

typedef $$SchoolCalendarEventsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SchoolCalendarEventsTableTable,
      SchoolCalendarEventsTableData,
      $$SchoolCalendarEventsTableTableFilterComposer,
      $$SchoolCalendarEventsTableTableOrderingComposer,
      $$SchoolCalendarEventsTableTableAnnotationComposer,
      $$SchoolCalendarEventsTableTableCreateCompanionBuilder,
      $$SchoolCalendarEventsTableTableUpdateCompanionBuilder,
      (
        SchoolCalendarEventsTableData,
        $$SchoolCalendarEventsTableTableReferences,
      ),
      SchoolCalendarEventsTableData,
      PrefetchHooks Function({bool academicYearId})
    >;
typedef $$ScheduleSlotsTableTableCreateCompanionBuilder =
    ScheduleSlotsTableCompanion Function({
      required String id,
      required String classroomSubjectId,
      required int weekday,
      required int orderIndex,
      Value<String?> startTime,
      Value<String?> endTime,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ScheduleSlotsTableTableUpdateCompanionBuilder =
    ScheduleSlotsTableCompanion Function({
      Value<String> id,
      Value<String> classroomSubjectId,
      Value<int> weekday,
      Value<int> orderIndex,
      Value<String?> startTime,
      Value<String?> endTime,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ScheduleSlotsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ScheduleSlotsTableTable,
          ScheduleSlotsTableData
        > {
  $$ScheduleSlotsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ClassroomSubjectsTableTable _classroomSubjectIdTable(
    _$AppDatabase db,
  ) => db.classroomSubjectsTable.createAlias(
    'schedule_slots_table__classroom_subject_id__classroom_subjects_table__id',
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

class $$ScheduleSlotsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ScheduleSlotsTableTable> {
  $$ScheduleSlotsTableTableFilterComposer({
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

  ColumnFilters<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endTime => $composableBuilder(
    column: $table.endTime,
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

class $$ScheduleSlotsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ScheduleSlotsTableTable> {
  $$ScheduleSlotsTableTableOrderingComposer({
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

  ColumnOrderings<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endTime => $composableBuilder(
    column: $table.endTime,
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

class $$ScheduleSlotsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScheduleSlotsTableTable> {
  $$ScheduleSlotsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

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

class $$ScheduleSlotsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScheduleSlotsTableTable,
          ScheduleSlotsTableData,
          $$ScheduleSlotsTableTableFilterComposer,
          $$ScheduleSlotsTableTableOrderingComposer,
          $$ScheduleSlotsTableTableAnnotationComposer,
          $$ScheduleSlotsTableTableCreateCompanionBuilder,
          $$ScheduleSlotsTableTableUpdateCompanionBuilder,
          (ScheduleSlotsTableData, $$ScheduleSlotsTableTableReferences),
          ScheduleSlotsTableData,
          PrefetchHooks Function({bool classroomSubjectId})
        > {
  $$ScheduleSlotsTableTableTableManager(
    _$AppDatabase db,
    $ScheduleSlotsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduleSlotsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScheduleSlotsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScheduleSlotsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> classroomSubjectId = const Value.absent(),
                Value<int> weekday = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<String?> startTime = const Value.absent(),
                Value<String?> endTime = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScheduleSlotsTableCompanion(
                id: id,
                classroomSubjectId: classroomSubjectId,
                weekday: weekday,
                orderIndex: orderIndex,
                startTime: startTime,
                endTime: endTime,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String classroomSubjectId,
                required int weekday,
                required int orderIndex,
                Value<String?> startTime = const Value.absent(),
                Value<String?> endTime = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ScheduleSlotsTableCompanion.insert(
                id: id,
                classroomSubjectId: classroomSubjectId,
                weekday: weekday,
                orderIndex: orderIndex,
                startTime: startTime,
                endTime: endTime,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScheduleSlotsTableTable, ScheduleSlotsTableData>(
                    table,
                  ),
                  $$ScheduleSlotsTableTableReferences(db, table, e),
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
                        referencedTable: $$ScheduleSlotsTableTableReferences
                            ._classroomSubjectIdTable(db),
                        referencedColumn: $$ScheduleSlotsTableTableReferences
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

typedef $$ScheduleSlotsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScheduleSlotsTableTable,
      ScheduleSlotsTableData,
      $$ScheduleSlotsTableTableFilterComposer,
      $$ScheduleSlotsTableTableOrderingComposer,
      $$ScheduleSlotsTableTableAnnotationComposer,
      $$ScheduleSlotsTableTableCreateCompanionBuilder,
      $$ScheduleSlotsTableTableUpdateCompanionBuilder,
      (ScheduleSlotsTableData, $$ScheduleSlotsTableTableReferences),
      ScheduleSlotsTableData,
      PrefetchHooks Function({bool classroomSubjectId})
    >;
typedef $$CurriculumCompetenciesTableTableCreateCompanionBuilder =
    CurriculumCompetenciesTableCompanion Function({
      required String id,
      required String code,
      required String description,
      required String thematicUnit,
      Value<String?> knowledgeObject,
      required String stage,
      required String gradeLevel,
      required String subjectName,
      required String sourceName,
      required String sourceVersion,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$CurriculumCompetenciesTableTableUpdateCompanionBuilder =
    CurriculumCompetenciesTableCompanion Function({
      Value<String> id,
      Value<String> code,
      Value<String> description,
      Value<String> thematicUnit,
      Value<String?> knowledgeObject,
      Value<String> stage,
      Value<String> gradeLevel,
      Value<String> subjectName,
      Value<String> sourceName,
      Value<String> sourceVersion,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$CurriculumCompetenciesTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CurriculumCompetenciesTableTable,
          CurriculumCompetenciesTableData
        > {
  $$CurriculumCompetenciesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $CourseContentsTableTable,
    List<CourseContentsTableData>
  >
  _courseContentsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.courseContentsTable,
        aliasName: 'curriculum_competencies_table__id__course_contents_table__curriculum_competency_id',
      );

  $$CourseContentsTableTableProcessedTableManager get courseContentsTableRefs {
    final manager =
        $$CourseContentsTableTableTableManager(
          $_db,
          $_db.courseContentsTable,
        ).filter(
          (f) => f.curriculumCompetencyId.id.sqlEquals(
            $_itemColumn<String>('id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _courseContentsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CurriculumCompetenciesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CurriculumCompetenciesTableTable> {
  $$CurriculumCompetenciesTableTableFilterComposer({
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

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thematicUnit => $composableBuilder(
    column: $table.thematicUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get knowledgeObject => $composableBuilder(
    column: $table.knowledgeObject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gradeLevel => $composableBuilder(
    column: $table.gradeLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectName => $composableBuilder(
    column: $table.subjectName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceVersion => $composableBuilder(
    column: $table.sourceVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> courseContentsTableRefs(
    Expression<bool> Function($$CourseContentsTableTableFilterComposer f) f,
  ) {
    final $$CourseContentsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.courseContentsTable,
      getReferencedColumn: (t) => t.curriculumCompetencyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseContentsTableTableFilterComposer(
            $db: $db,
            $table: $db.courseContentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CurriculumCompetenciesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CurriculumCompetenciesTableTable> {
  $$CurriculumCompetenciesTableTableOrderingComposer({
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

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thematicUnit => $composableBuilder(
    column: $table.thematicUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get knowledgeObject => $composableBuilder(
    column: $table.knowledgeObject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gradeLevel => $composableBuilder(
    column: $table.gradeLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectName => $composableBuilder(
    column: $table.subjectName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceVersion => $composableBuilder(
    column: $table.sourceVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CurriculumCompetenciesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CurriculumCompetenciesTableTable> {
  $$CurriculumCompetenciesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thematicUnit => $composableBuilder(
    column: $table.thematicUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get knowledgeObject => $composableBuilder(
    column: $table.knowledgeObject,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumn<String> get gradeLevel => $composableBuilder(
    column: $table.gradeLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subjectName => $composableBuilder(
    column: $table.subjectName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceVersion => $composableBuilder(
    column: $table.sourceVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> courseContentsTableRefs<T extends Object>(
    Expression<T> Function($$CourseContentsTableTableAnnotationComposer a) f,
  ) {
    final $$CourseContentsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.courseContentsTable,
          getReferencedColumn: (t) => t.curriculumCompetencyId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CourseContentsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.courseContentsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CurriculumCompetenciesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CurriculumCompetenciesTableTable,
          CurriculumCompetenciesTableData,
          $$CurriculumCompetenciesTableTableFilterComposer,
          $$CurriculumCompetenciesTableTableOrderingComposer,
          $$CurriculumCompetenciesTableTableAnnotationComposer,
          $$CurriculumCompetenciesTableTableCreateCompanionBuilder,
          $$CurriculumCompetenciesTableTableUpdateCompanionBuilder,
          (
            CurriculumCompetenciesTableData,
            $$CurriculumCompetenciesTableTableReferences,
          ),
          CurriculumCompetenciesTableData,
          PrefetchHooks Function({bool courseContentsTableRefs})
        > {
  $$CurriculumCompetenciesTableTableTableManager(
    _$AppDatabase db,
    $CurriculumCompetenciesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CurriculumCompetenciesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CurriculumCompetenciesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CurriculumCompetenciesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> thematicUnit = const Value.absent(),
                Value<String?> knowledgeObject = const Value.absent(),
                Value<String> stage = const Value.absent(),
                Value<String> gradeLevel = const Value.absent(),
                Value<String> subjectName = const Value.absent(),
                Value<String> sourceName = const Value.absent(),
                Value<String> sourceVersion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CurriculumCompetenciesTableCompanion(
                id: id,
                code: code,
                description: description,
                thematicUnit: thematicUnit,
                knowledgeObject: knowledgeObject,
                stage: stage,
                gradeLevel: gradeLevel,
                subjectName: subjectName,
                sourceName: sourceName,
                sourceVersion: sourceVersion,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String code,
                required String description,
                required String thematicUnit,
                Value<String?> knowledgeObject = const Value.absent(),
                required String stage,
                required String gradeLevel,
                required String subjectName,
                required String sourceName,
                required String sourceVersion,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CurriculumCompetenciesTableCompanion.insert(
                id: id,
                code: code,
                description: description,
                thematicUnit: thematicUnit,
                knowledgeObject: knowledgeObject,
                stage: stage,
                gradeLevel: gradeLevel,
                subjectName: subjectName,
                sourceName: sourceName,
                sourceVersion: sourceVersion,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $CurriculumCompetenciesTableTable,
                    CurriculumCompetenciesTableData
                  >(table),
                  $$CurriculumCompetenciesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({courseContentsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (courseContentsTableRefs) db.courseContentsTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (courseContentsTableRefs)
                    await $_getPrefetchedData<
                      CurriculumCompetenciesTableData,
                      $CurriculumCompetenciesTableTable,
                      CourseContentsTableData
                    >(
                      currentTable: table,
                      referencedTable:
                          $$CurriculumCompetenciesTableTableReferences
                              ._courseContentsTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CurriculumCompetenciesTableTableReferences(
                            db,
                            table,
                            p0,
                          ).courseContentsTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.curriculumCompetencyId == item.id,
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

typedef $$CurriculumCompetenciesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CurriculumCompetenciesTableTable,
      CurriculumCompetenciesTableData,
      $$CurriculumCompetenciesTableTableFilterComposer,
      $$CurriculumCompetenciesTableTableOrderingComposer,
      $$CurriculumCompetenciesTableTableAnnotationComposer,
      $$CurriculumCompetenciesTableTableCreateCompanionBuilder,
      $$CurriculumCompetenciesTableTableUpdateCompanionBuilder,
      (
        CurriculumCompetenciesTableData,
        $$CurriculumCompetenciesTableTableReferences,
      ),
      CurriculumCompetenciesTableData,
      PrefetchHooks Function({bool courseContentsTableRefs})
    >;
typedef $$CourseContentsTableTableCreateCompanionBuilder =
    CourseContentsTableCompanion Function({
      required String id,
      required String classroomSubjectId,
      required String title,
      Value<String?> description,
      Value<String?> thematicUnit,
      Value<int> estimatedLessons,
      required int orderIndex,
      Value<bool> isMandatory,
      Value<String?> curriculumCompetencyId,
      required String origin,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$CourseContentsTableTableUpdateCompanionBuilder =
    CourseContentsTableCompanion Function({
      Value<String> id,
      Value<String> classroomSubjectId,
      Value<String> title,
      Value<String?> description,
      Value<String?> thematicUnit,
      Value<int> estimatedLessons,
      Value<int> orderIndex,
      Value<bool> isMandatory,
      Value<String?> curriculumCompetencyId,
      Value<String> origin,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$CourseContentsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CourseContentsTableTable,
          CourseContentsTableData
        > {
  $$CourseContentsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ClassroomSubjectsTableTable _classroomSubjectIdTable(
    _$AppDatabase db,
  ) => db.classroomSubjectsTable.createAlias(
    'course_contents_table__classroom_subject_id__classroom_subjects_table__id',
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

  static $CurriculumCompetenciesTableTable _curriculumCompetencyIdTable(
    _$AppDatabase db,
  ) => db.curriculumCompetenciesTable.createAlias(
    'course_contents_table__curriculum_competency_id__curriculum_competencies_table__id',
  );

  $$CurriculumCompetenciesTableTableProcessedTableManager?
  get curriculumCompetencyId {
    final $_column = $_itemColumn<String>('curriculum_competency_id');
    if ($_column == null) return null;
    final manager = $$CurriculumCompetenciesTableTableTableManager(
      $_db,
      $_db.curriculumCompetenciesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _curriculumCompetencyIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $ContentPrerequisitesTableTable,
    List<ContentPrerequisitesTableData>
  >
  _requiredPrerequisitesTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.contentPrerequisitesTable,
    aliasName:
        'course_contents_table__id__content_prerequisites_table__content_id',
  );

  $$ContentPrerequisitesTableTableProcessedTableManager
  get requiredPrerequisites {
    final manager = $$ContentPrerequisitesTableTableTableManager(
      $_db,
      $_db.contentPrerequisitesTable,
    ).filter((f) => f.contentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _requiredPrerequisitesTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ContentPrerequisitesTableTable,
    List<ContentPrerequisitesTableData>
  >
  _prerequisiteForTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.contentPrerequisitesTable,
    aliasName: 'course_contents_table__id__content_prerequisites_table__prerequisite_content_id',
  );

  $$ContentPrerequisitesTableTableProcessedTableManager get prerequisiteFor {
    final manager =
        $$ContentPrerequisitesTableTableTableManager(
          $_db,
          $_db.contentPrerequisitesTable,
        ).filter(
          (f) =>
              f.prerequisiteContentId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_prerequisiteForTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $LessonContentAllocationsTableTable,
    List<LessonContentAllocationsTableData>
  >
  _contentLessonsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.lessonContentAllocationsTable,
    aliasName: 'course_contents_table__id__lesson_content_allocations_table__content_id',
  );

  $$LessonContentAllocationsTableTableProcessedTableManager get contentLessons {
    final manager = $$LessonContentAllocationsTableTableTableManager(
      $_db,
      $_db.lessonContentAllocationsTable,
    ).filter((f) => f.contentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_contentLessonsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CourseContentsTableTableFilterComposer
    extends Composer<_$AppDatabase, $CourseContentsTableTable> {
  $$CourseContentsTableTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thematicUnit => $composableBuilder(
    column: $table.thematicUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimatedLessons => $composableBuilder(
    column: $table.estimatedLessons,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMandatory => $composableBuilder(
    column: $table.isMandatory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
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

  $$CurriculumCompetenciesTableTableFilterComposer get curriculumCompetencyId {
    final $$CurriculumCompetenciesTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.curriculumCompetencyId,
          referencedTable: $db.curriculumCompetenciesTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CurriculumCompetenciesTableTableFilterComposer(
                $db: $db,
                $table: $db.curriculumCompetenciesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<bool> requiredPrerequisites(
    Expression<bool> Function($$ContentPrerequisitesTableTableFilterComposer f)
    f,
  ) {
    final $$ContentPrerequisitesTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contentPrerequisitesTable,
          getReferencedColumn: (t) => t.contentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContentPrerequisitesTableTableFilterComposer(
                $db: $db,
                $table: $db.contentPrerequisitesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> prerequisiteFor(
    Expression<bool> Function($$ContentPrerequisitesTableTableFilterComposer f)
    f,
  ) {
    final $$ContentPrerequisitesTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contentPrerequisitesTable,
          getReferencedColumn: (t) => t.prerequisiteContentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContentPrerequisitesTableTableFilterComposer(
                $db: $db,
                $table: $db.contentPrerequisitesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> contentLessons(
    Expression<bool> Function(
      $$LessonContentAllocationsTableTableFilterComposer f,
    )
    f,
  ) {
    final $$LessonContentAllocationsTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.lessonContentAllocationsTable,
          getReferencedColumn: (t) => t.contentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LessonContentAllocationsTableTableFilterComposer(
                $db: $db,
                $table: $db.lessonContentAllocationsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CourseContentsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CourseContentsTableTable> {
  $$CourseContentsTableTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thematicUnit => $composableBuilder(
    column: $table.thematicUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimatedLessons => $composableBuilder(
    column: $table.estimatedLessons,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMandatory => $composableBuilder(
    column: $table.isMandatory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
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

  $$CurriculumCompetenciesTableTableOrderingComposer
  get curriculumCompetencyId {
    final $$CurriculumCompetenciesTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.curriculumCompetencyId,
          referencedTable: $db.curriculumCompetenciesTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CurriculumCompetenciesTableTableOrderingComposer(
                $db: $db,
                $table: $db.curriculumCompetenciesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$CourseContentsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CourseContentsTableTable> {
  $$CourseContentsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thematicUnit => $composableBuilder(
    column: $table.thematicUnit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get estimatedLessons => $composableBuilder(
    column: $table.estimatedLessons,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isMandatory => $composableBuilder(
    column: $table.isMandatory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

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

  $$CurriculumCompetenciesTableTableAnnotationComposer
  get curriculumCompetencyId {
    final $$CurriculumCompetenciesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.curriculumCompetencyId,
          referencedTable: $db.curriculumCompetenciesTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CurriculumCompetenciesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.curriculumCompetenciesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> requiredPrerequisites<T extends Object>(
    Expression<T> Function($$ContentPrerequisitesTableTableAnnotationComposer a)
    f,
  ) {
    final $$ContentPrerequisitesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contentPrerequisitesTable,
          getReferencedColumn: (t) => t.contentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContentPrerequisitesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.contentPrerequisitesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> prerequisiteFor<T extends Object>(
    Expression<T> Function($$ContentPrerequisitesTableTableAnnotationComposer a)
    f,
  ) {
    final $$ContentPrerequisitesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.contentPrerequisitesTable,
          getReferencedColumn: (t) => t.prerequisiteContentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ContentPrerequisitesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.contentPrerequisitesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> contentLessons<T extends Object>(
    Expression<T> Function(
      $$LessonContentAllocationsTableTableAnnotationComposer a,
    )
    f,
  ) {
    final $$LessonContentAllocationsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.lessonContentAllocationsTable,
          getReferencedColumn: (t) => t.contentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LessonContentAllocationsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.lessonContentAllocationsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CourseContentsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CourseContentsTableTable,
          CourseContentsTableData,
          $$CourseContentsTableTableFilterComposer,
          $$CourseContentsTableTableOrderingComposer,
          $$CourseContentsTableTableAnnotationComposer,
          $$CourseContentsTableTableCreateCompanionBuilder,
          $$CourseContentsTableTableUpdateCompanionBuilder,
          (CourseContentsTableData, $$CourseContentsTableTableReferences),
          CourseContentsTableData,
          PrefetchHooks Function({
            bool classroomSubjectId,
            bool curriculumCompetencyId,
            bool requiredPrerequisites,
            bool prerequisiteFor,
            bool contentLessons,
          })
        > {
  $$CourseContentsTableTableTableManager(
    _$AppDatabase db,
    $CourseContentsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CourseContentsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CourseContentsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CourseContentsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> classroomSubjectId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> thematicUnit = const Value.absent(),
                Value<int> estimatedLessons = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<bool> isMandatory = const Value.absent(),
                Value<String?> curriculumCompetencyId = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourseContentsTableCompanion(
                id: id,
                classroomSubjectId: classroomSubjectId,
                title: title,
                description: description,
                thematicUnit: thematicUnit,
                estimatedLessons: estimatedLessons,
                orderIndex: orderIndex,
                isMandatory: isMandatory,
                curriculumCompetencyId: curriculumCompetencyId,
                origin: origin,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String classroomSubjectId,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String?> thematicUnit = const Value.absent(),
                Value<int> estimatedLessons = const Value.absent(),
                required int orderIndex,
                Value<bool> isMandatory = const Value.absent(),
                Value<String?> curriculumCompetencyId = const Value.absent(),
                required String origin,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CourseContentsTableCompanion.insert(
                id: id,
                classroomSubjectId: classroomSubjectId,
                title: title,
                description: description,
                thematicUnit: thematicUnit,
                estimatedLessons: estimatedLessons,
                orderIndex: orderIndex,
                isMandatory: isMandatory,
                curriculumCompetencyId: curriculumCompetencyId,
                origin: origin,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $CourseContentsTableTable,
                    CourseContentsTableData
                  >(table),
                  $$CourseContentsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                classroomSubjectId = false,
                curriculumCompetencyId = false,
                requiredPrerequisites = false,
                prerequisiteFor = false,
                contentLessons = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (requiredPrerequisites) db.contentPrerequisitesTable,
                    if (prerequisiteFor) db.contentPrerequisitesTable,
                    if (contentLessons) db.lessonContentAllocationsTable,
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
                        if (classroomSubjectId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.classroomSubjectId,
                            referencedTable:
                                $$CourseContentsTableTableReferences
                                    ._classroomSubjectIdTable(db),
                            referencedColumn:
                                $$CourseContentsTableTableReferences
                                    ._classroomSubjectIdTable(db)
                                    .id,
                          ) as T;
                        }
                        if (curriculumCompetencyId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.curriculumCompetencyId,
                            referencedTable:
                                $$CourseContentsTableTableReferences
                                    ._curriculumCompetencyIdTable(db),
                            referencedColumn:
                                $$CourseContentsTableTableReferences
                                    ._curriculumCompetencyIdTable(db)
                                    .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (requiredPrerequisites)
                        await $_getPrefetchedData<
                          CourseContentsTableData,
                          $CourseContentsTableTable,
                          ContentPrerequisitesTableData
                        >(
                          currentTable: table,
                          referencedTable: $$CourseContentsTableTableReferences
                              ._requiredPrerequisitesTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CourseContentsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).requiredPrerequisites,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (prerequisiteFor)
                        await $_getPrefetchedData<
                          CourseContentsTableData,
                          $CourseContentsTableTable,
                          ContentPrerequisitesTableData
                        >(
                          currentTable: table,
                          referencedTable: $$CourseContentsTableTableReferences
                              ._prerequisiteForTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CourseContentsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).prerequisiteFor,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.prerequisiteContentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (contentLessons)
                        await $_getPrefetchedData<
                          CourseContentsTableData,
                          $CourseContentsTableTable,
                          LessonContentAllocationsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$CourseContentsTableTableReferences
                              ._contentLessonsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CourseContentsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).contentLessons,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contentId == item.id,
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

typedef $$CourseContentsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CourseContentsTableTable,
      CourseContentsTableData,
      $$CourseContentsTableTableFilterComposer,
      $$CourseContentsTableTableOrderingComposer,
      $$CourseContentsTableTableAnnotationComposer,
      $$CourseContentsTableTableCreateCompanionBuilder,
      $$CourseContentsTableTableUpdateCompanionBuilder,
      (CourseContentsTableData, $$CourseContentsTableTableReferences),
      CourseContentsTableData,
      PrefetchHooks Function({
        bool classroomSubjectId,
        bool curriculumCompetencyId,
        bool requiredPrerequisites,
        bool prerequisiteFor,
        bool contentLessons,
      })
    >;
typedef $$ContentPrerequisitesTableTableCreateCompanionBuilder =
    ContentPrerequisitesTableCompanion Function({
      required String contentId,
      required String prerequisiteContentId,
      Value<int> rowid,
    });
typedef $$ContentPrerequisitesTableTableUpdateCompanionBuilder =
    ContentPrerequisitesTableCompanion Function({
      Value<String> contentId,
      Value<String> prerequisiteContentId,
      Value<int> rowid,
    });

final class $$ContentPrerequisitesTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ContentPrerequisitesTableTable,
          ContentPrerequisitesTableData
        > {
  $$ContentPrerequisitesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CourseContentsTableTable _contentIdTable(_$AppDatabase db) =>
      db.courseContentsTable.createAlias(
        'content_prerequisites_table__content_id__course_contents_table__id',
      );

  $$CourseContentsTableTableProcessedTableManager get contentId {
    final $_column = $_itemColumn<String>('content_id')!;

    final manager = $$CourseContentsTableTableTableManager(
      $_db,
      $_db.courseContentsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CourseContentsTableTable _prerequisiteContentIdTable(
    _$AppDatabase db,
  ) => db.courseContentsTable.createAlias(
    'content_prerequisites_table__prerequisite_content_id__course_contents_table__id',
  );

  $$CourseContentsTableTableProcessedTableManager get prerequisiteContentId {
    final $_column = $_itemColumn<String>('prerequisite_content_id')!;

    final manager = $$CourseContentsTableTableTableManager(
      $_db,
      $_db.courseContentsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _prerequisiteContentIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ContentPrerequisitesTableTableFilterComposer
    extends Composer<_$AppDatabase, $ContentPrerequisitesTableTable> {
  $$ContentPrerequisitesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CourseContentsTableTableFilterComposer get contentId {
    final $$CourseContentsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contentId,
      referencedTable: $db.courseContentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseContentsTableTableFilterComposer(
            $db: $db,
            $table: $db.courseContentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CourseContentsTableTableFilterComposer get prerequisiteContentId {
    final $$CourseContentsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.prerequisiteContentId,
      referencedTable: $db.courseContentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseContentsTableTableFilterComposer(
            $db: $db,
            $table: $db.courseContentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContentPrerequisitesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ContentPrerequisitesTableTable> {
  $$ContentPrerequisitesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CourseContentsTableTableOrderingComposer get contentId {
    final $$CourseContentsTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.contentId,
          referencedTable: $db.courseContentsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CourseContentsTableTableOrderingComposer(
                $db: $db,
                $table: $db.courseContentsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$CourseContentsTableTableOrderingComposer get prerequisiteContentId {
    final $$CourseContentsTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.prerequisiteContentId,
          referencedTable: $db.courseContentsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CourseContentsTableTableOrderingComposer(
                $db: $db,
                $table: $db.courseContentsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ContentPrerequisitesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContentPrerequisitesTableTable> {
  $$ContentPrerequisitesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CourseContentsTableTableAnnotationComposer get contentId {
    final $$CourseContentsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.contentId,
          referencedTable: $db.courseContentsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CourseContentsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.courseContentsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$CourseContentsTableTableAnnotationComposer get prerequisiteContentId {
    final $$CourseContentsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.prerequisiteContentId,
          referencedTable: $db.courseContentsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CourseContentsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.courseContentsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ContentPrerequisitesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContentPrerequisitesTableTable,
          ContentPrerequisitesTableData,
          $$ContentPrerequisitesTableTableFilterComposer,
          $$ContentPrerequisitesTableTableOrderingComposer,
          $$ContentPrerequisitesTableTableAnnotationComposer,
          $$ContentPrerequisitesTableTableCreateCompanionBuilder,
          $$ContentPrerequisitesTableTableUpdateCompanionBuilder,
          (
            ContentPrerequisitesTableData,
            $$ContentPrerequisitesTableTableReferences,
          ),
          ContentPrerequisitesTableData,
          PrefetchHooks Function({bool contentId, bool prerequisiteContentId})
        > {
  $$ContentPrerequisitesTableTableTableManager(
    _$AppDatabase db,
    $ContentPrerequisitesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContentPrerequisitesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ContentPrerequisitesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ContentPrerequisitesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> contentId = const Value.absent(),
                Value<String> prerequisiteContentId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentPrerequisitesTableCompanion(
                contentId: contentId,
                prerequisiteContentId: prerequisiteContentId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String contentId,
                required String prerequisiteContentId,
                Value<int> rowid = const Value.absent(),
              }) => ContentPrerequisitesTableCompanion.insert(
                contentId: contentId,
                prerequisiteContentId: prerequisiteContentId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ContentPrerequisitesTableTable,
                    ContentPrerequisitesTableData
                  >(table),
                  $$ContentPrerequisitesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({contentId = false, prerequisiteContentId = false}) {
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
                        if (contentId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.contentId,
                            referencedTable:
                                $$ContentPrerequisitesTableTableReferences
                                    ._contentIdTable(db),
                            referencedColumn:
                                $$ContentPrerequisitesTableTableReferences
                                    ._contentIdTable(db)
                                    .id,
                          ) as T;
                        }
                        if (prerequisiteContentId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.prerequisiteContentId,
                            referencedTable:
                                $$ContentPrerequisitesTableTableReferences
                                    ._prerequisiteContentIdTable(db),
                            referencedColumn:
                                $$ContentPrerequisitesTableTableReferences
                                    ._prerequisiteContentIdTable(db)
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

typedef $$ContentPrerequisitesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContentPrerequisitesTableTable,
      ContentPrerequisitesTableData,
      $$ContentPrerequisitesTableTableFilterComposer,
      $$ContentPrerequisitesTableTableOrderingComposer,
      $$ContentPrerequisitesTableTableAnnotationComposer,
      $$ContentPrerequisitesTableTableCreateCompanionBuilder,
      $$ContentPrerequisitesTableTableUpdateCompanionBuilder,
      (
        ContentPrerequisitesTableData,
        $$ContentPrerequisitesTableTableReferences,
      ),
      ContentPrerequisitesTableData,
      PrefetchHooks Function({bool contentId, bool prerequisiteContentId})
    >;
typedef $$LessonContentAllocationsTableTableCreateCompanionBuilder =
    LessonContentAllocationsTableCompanion Function({
      required String lessonId,
      required String contentId,
      Value<int> orderIndex,
      Value<int> rowid,
    });
typedef $$LessonContentAllocationsTableTableUpdateCompanionBuilder =
    LessonContentAllocationsTableCompanion Function({
      Value<String> lessonId,
      Value<String> contentId,
      Value<int> orderIndex,
      Value<int> rowid,
    });

final class $$LessonContentAllocationsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LessonContentAllocationsTableTable,
          LessonContentAllocationsTableData
        > {
  $$LessonContentAllocationsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlannedLessonsTableTable _lessonIdTable(
    _$AppDatabase db,
  ) => db.plannedLessonsTable.createAlias(
    'lesson_content_allocations_table__lesson_id__planned_lessons_table__id',
  );

  $$PlannedLessonsTableTableProcessedTableManager get lessonId {
    final $_column = $_itemColumn<String>('lesson_id')!;

    final manager = $$PlannedLessonsTableTableTableManager(
      $_db,
      $_db.plannedLessonsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lessonIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CourseContentsTableTable _contentIdTable(
    _$AppDatabase db,
  ) => db.courseContentsTable.createAlias(
    'lesson_content_allocations_table__content_id__course_contents_table__id',
  );

  $$CourseContentsTableTableProcessedTableManager get contentId {
    final $_column = $_itemColumn<String>('content_id')!;

    final manager = $$CourseContentsTableTableTableManager(
      $_db,
      $_db.courseContentsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LessonContentAllocationsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LessonContentAllocationsTableTable> {
  $$LessonContentAllocationsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  $$PlannedLessonsTableTableFilterComposer get lessonId {
    final $$PlannedLessonsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lessonId,
      referencedTable: $db.plannedLessonsTable,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  $$CourseContentsTableTableFilterComposer get contentId {
    final $$CourseContentsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contentId,
      referencedTable: $db.courseContentsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CourseContentsTableTableFilterComposer(
            $db: $db,
            $table: $db.courseContentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LessonContentAllocationsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LessonContentAllocationsTableTable> {
  $$LessonContentAllocationsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlannedLessonsTableTableOrderingComposer get lessonId {
    final $$PlannedLessonsTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.lessonId,
          referencedTable: $db.plannedLessonsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PlannedLessonsTableTableOrderingComposer(
                $db: $db,
                $table: $db.plannedLessonsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$CourseContentsTableTableOrderingComposer get contentId {
    final $$CourseContentsTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.contentId,
          referencedTable: $db.courseContentsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CourseContentsTableTableOrderingComposer(
                $db: $db,
                $table: $db.courseContentsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$LessonContentAllocationsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LessonContentAllocationsTableTable> {
  $$LessonContentAllocationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  $$PlannedLessonsTableTableAnnotationComposer get lessonId {
    final $$PlannedLessonsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.lessonId,
          referencedTable: $db.plannedLessonsTable,
          getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  $$CourseContentsTableTableAnnotationComposer get contentId {
    final $$CourseContentsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.contentId,
          referencedTable: $db.courseContentsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CourseContentsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.courseContentsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$LessonContentAllocationsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LessonContentAllocationsTableTable,
          LessonContentAllocationsTableData,
          $$LessonContentAllocationsTableTableFilterComposer,
          $$LessonContentAllocationsTableTableOrderingComposer,
          $$LessonContentAllocationsTableTableAnnotationComposer,
          $$LessonContentAllocationsTableTableCreateCompanionBuilder,
          $$LessonContentAllocationsTableTableUpdateCompanionBuilder,
          (
            LessonContentAllocationsTableData,
            $$LessonContentAllocationsTableTableReferences,
          ),
          LessonContentAllocationsTableData,
          PrefetchHooks Function({bool lessonId, bool contentId})
        > {
  $$LessonContentAllocationsTableTableTableManager(
    _$AppDatabase db,
    $LessonContentAllocationsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonContentAllocationsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LessonContentAllocationsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LessonContentAllocationsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> lessonId = const Value.absent(),
                Value<String> contentId = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LessonContentAllocationsTableCompanion(
                lessonId: lessonId,
                contentId: contentId,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String lessonId,
                required String contentId,
                Value<int> orderIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LessonContentAllocationsTableCompanion.insert(
                lessonId: lessonId,
                contentId: contentId,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $LessonContentAllocationsTableTable,
                    LessonContentAllocationsTableData
                  >(table),
                  $$LessonContentAllocationsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({lessonId = false, contentId = false}) {
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
                    if (lessonId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.lessonId,
                        referencedTable:
                            $$LessonContentAllocationsTableTableReferences
                                ._lessonIdTable(db),
                        referencedColumn:
                            $$LessonContentAllocationsTableTableReferences
                                ._lessonIdTable(db)
                                .id,
                      ) as T;
                    }
                    if (contentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.contentId,
                        referencedTable:
                            $$LessonContentAllocationsTableTableReferences
                                ._contentIdTable(db),
                        referencedColumn:
                            $$LessonContentAllocationsTableTableReferences
                                ._contentIdTable(db)
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

typedef $$LessonContentAllocationsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LessonContentAllocationsTableTable,
      LessonContentAllocationsTableData,
      $$LessonContentAllocationsTableTableFilterComposer,
      $$LessonContentAllocationsTableTableOrderingComposer,
      $$LessonContentAllocationsTableTableAnnotationComposer,
      $$LessonContentAllocationsTableTableCreateCompanionBuilder,
      $$LessonContentAllocationsTableTableUpdateCompanionBuilder,
      (
        LessonContentAllocationsTableData,
        $$LessonContentAllocationsTableTableReferences,
      ),
      LessonContentAllocationsTableData,
      PrefetchHooks Function({bool lessonId, bool contentId})
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
  $$SchoolCalendarEventsTableTableTableManager get schoolCalendarEventsTable =>
      $$SchoolCalendarEventsTableTableTableManager(
        _db,
        _db.schoolCalendarEventsTable,
      );
  $$ScheduleSlotsTableTableTableManager get scheduleSlotsTable =>
      $$ScheduleSlotsTableTableTableManager(_db, _db.scheduleSlotsTable);
  $$CurriculumCompetenciesTableTableTableManager
  get curriculumCompetenciesTable =>
      $$CurriculumCompetenciesTableTableTableManager(
        _db,
        _db.curriculumCompetenciesTable,
      );
  $$CourseContentsTableTableTableManager get courseContentsTable =>
      $$CourseContentsTableTableTableManager(_db, _db.courseContentsTable);
  $$ContentPrerequisitesTableTableTableManager get contentPrerequisitesTable =>
      $$ContentPrerequisitesTableTableTableManager(
        _db,
        _db.contentPrerequisitesTable,
      );
  $$LessonContentAllocationsTableTableTableManager
  get lessonContentAllocationsTable =>
      $$LessonContentAllocationsTableTableTableManager(
        _db,
        _db.lessonContentAllocationsTable,
      );
}
