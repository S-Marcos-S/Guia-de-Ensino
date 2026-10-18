import 'package:app/infrastructure/persistence/converters/calendar_date_converter.dart';
import 'package:drift/drift.dart';

/// Tabela de Anos Letivos no SQLite.
class AcademicYearsTable extends Table {
  TextColumn get id => text()();
  IntColumn get year => integer()();
  TextColumn get title => text()();
  TextColumn get startDate => text().map(const CalendarDateConverter())();
  TextColumn get endDate => text().map(const CalendarDateConverter())();
  IntColumn get totalMandatoryDays =>
      integer().withDefault(const Constant(200))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {year},
  ];
}

/// Tabela de Turmas no SQLite.
class ClassroomsTable extends Table {
  TextColumn get id => text()();
  TextColumn get academicYearId => text().references(
    AcademicYearsTable,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get name => text()();
  TextColumn get gradeLevel => text()();
  TextColumn get shift => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {academicYearId, name},
  ];
}

/// Tabela de Componentes Curriculares / Disciplinas.
class SubjectsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get colorHex => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {name},
  ];
}

/// Vínculo específico entre Turma e Disciplina com carga horária individualizada.
class ClassroomSubjectsTable extends Table {
  TextColumn get id => text()();
  TextColumn get classroomId =>
      text().references(ClassroomsTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get subjectId =>
      text().references(SubjectsTable, #id, onDelete: KeyAction.restrict)();
  IntColumn get weeklyLessons => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {classroomId, subjectId},
  ];
}

/// Tabela de Aulas Planejadas e Registros de Execução no SQLite.
class PlannedLessonsTable extends Table {
  TextColumn get id => text()();
  TextColumn get classroomSubjectId => text().references(
    ClassroomSubjectsTable,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get lessonDate => text().map(const CalendarDateConverter())();
  IntColumn get orderInDay => integer()();
  TextColumn get status => text()();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {classroomSubjectId, lessonDate, orderInDay},
  ];
}
