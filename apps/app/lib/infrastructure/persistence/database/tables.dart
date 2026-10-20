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
  DateTimeColumn get updatedAt => dateTime().nullable()();

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
  DateTimeColumn get updatedAt => dateTime().nullable()();

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
  DateTimeColumn get updatedAt => dateTime().nullable()();

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
  DateTimeColumn get updatedAt => dateTime().nullable()();

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
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {classroomSubjectId, lessonDate, orderInDay},
  ];
}

/// Tabela de Eventos, Feriados e Recessos do Calendário Escolar.
class SchoolCalendarEventsTable extends Table {
  TextColumn get id => text()();
  TextColumn get academicYearId =>
      text().references(AcademicYearsTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get startDate => text().map(const CalendarDateConverter())();
  TextColumn get endDate => text().map(const CalendarDateConverter())();
  TextColumn get type => text()();
  BoolColumn get affectsClasses =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabela de Grade Semanal de Aulas (Slots de Horários por Turma-Disciplina).
class ScheduleSlotsTable extends Table {
  TextColumn get id => text()();
  TextColumn get classroomSubjectId => text().references(
    ClassroomSubjectsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get weekday => integer()();
  IntColumn get orderIndex => integer()();
  TextColumn get startTime => text().nullable()();
  TextColumn get endTime => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {classroomSubjectId, weekday, orderIndex},
  ];
}

/// Tabela de Competências e Habilidades Curriculares Oficiais (BNCC / Diretrizes).
class CurriculumCompetenciesTable extends Table {
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get description => text()();
  TextColumn get thematicUnit => text()();
  TextColumn get knowledgeObject => text().nullable()();
  TextColumn get stage => text()();
  TextColumn get gradeLevel => text()();
  TextColumn get subjectName => text()();
  TextColumn get sourceName => text()();
  TextColumn get sourceVersion => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {code},
  ];
}

/// Tabela de Conteúdos Programáticos planejados pelo professor.
class CourseContentsTable extends Table {
  TextColumn get id => text()();
  TextColumn get classroomSubjectId => text().references(
    ClassroomSubjectsTable,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get thematicUnit => text().nullable()();
  IntColumn get estimatedLessons => integer().withDefault(const Constant(1))();
  IntColumn get orderIndex => integer()();
  BoolColumn get isMandatory => boolean().withDefault(const Constant(true))();
  TextColumn get curriculumCompetencyId => text().nullable().references(
    CurriculumCompetenciesTable,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get origin => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabela associativa de pré-requisitos entre conteúdos programáticos.
class ContentPrerequisitesTable extends Table {
  @ReferenceName('requiredPrerequisites')
  TextColumn get contentId => text().references(
    CourseContentsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  @ReferenceName('prerequisiteFor')
  TextColumn get prerequisiteContentId => text().references(
    CourseContentsTable,
    #id,
    onDelete: KeyAction.restrict,
  )();

  @override
  Set<Column> get primaryKey => {contentId, prerequisiteContentId};
}

/// Tabela associativa entre Aulas Planejadas e Conteúdos Programáticos.
class LessonContentAllocationsTable extends Table {
  @ReferenceName('lessonAllocations')
  TextColumn get lessonId => text().references(
    PlannedLessonsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  @ReferenceName('contentLessons')
  TextColumn get contentId => text().references(
    CourseContentsTable,
    #id,
    onDelete: KeyAction.restrict,
  )();

  IntColumn get orderIndex => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {lessonId, contentId};
}

/// Tabela de Registros Históricos de Execução de Aulas (Diário de Classe - Schema v5).
class LessonExecutionRecordsTable extends Table {
  TextColumn get id => text()();

  /// Vínculo direto à aula planejada correspondente.
  /// onDelete: KeyAction.restrict impede categoricamente a exclusão da aula planejada
  /// caso ela possua um registro histórico registrado no banco.
  TextColumn get plannedLessonId => text().references(
    PlannedLessonsTable,
    #id,
    onDelete: KeyAction.restrict,
  )();

  /// Vínculo direto à disciplina e turma correspondente.
  /// onDelete: KeyAction.restrict protege a disciplina da turma contra exclusão acidental.
  TextColumn get classroomSubjectId => text().references(
    ClassroomSubjectsTable,
    #id,
    onDelete: KeyAction.restrict,
  )();

  /// Data de realização fática normalizada sem fuso horário.
  TextColumn get executionDate => text().map(const CalendarDateConverter())();

  /// Status de realização (completed, partiallyCompleted, notHeld).
  TextColumn get status => text()();

  /// Motivo padronizado para aula não realizada.
  TextColumn get cancellationReason => text().nullable()();

  /// Detalhes adicionais da justificativa de não realização.
  TextColumn get cancellationDetails => text().nullable()();

  /// Anotações pedagógicas do docente sobre a aula.
  TextColumn get pedagogicalNotes => text().nullable()();

  /// Indicador de necessidade de continuidade pedagógica.
  BoolColumn get needsFollowUp =>
      boolean().withDefault(const Constant(false))();

  /// Detalhes da continuidade a retomar em aulas futuras.
  TextColumn get followUpNotes => text().nullable()();

  /// Timestamp da criação original do registro.
  DateTimeColumn get recordedAt => dateTime()();

  /// Timestamp da última retificação do registro.
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    // Garante que cada aula planejada pode possuir no máximo um registro de execução
    {plannedLessonId},
  ];
}

/// Tabela associativa entre Registro de Execução e Conteúdos Efetivamente Ministrados (Schema v5).
class ExecutionContentAllocationsTable extends Table {
  @ReferenceName('executionAllocations')
  TextColumn get recordId => text().references(
    LessonExecutionRecordsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  @ReferenceName('executedLessonsForContent')
  TextColumn get contentId => text().references(
    CourseContentsTable,
    #id,
    onDelete: KeyAction.restrict,
  )();

  IntColumn get orderIndex => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {recordId, contentId};
}

/// Tabela de Estado e Controle de Sincronização Local (Schema v6).
class SyncStateTable extends Table {
  TextColumn get id => text().withDefault(const Constant('default'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  TextColumn get lastSyncStatus => text().withDefault(const Constant('idle'))();
  TextColumn get lastSyncError => text().nullable()();
  TextColumn get serverCursor => text().nullable()();
  TextColumn get deviceId => text()();
  TextColumn get accountEmail => text().nullable()();
  IntColumn get localRevision => integer().withDefault(const Constant(0))();
  IntColumn get accountEpoch => integer().withDefault(const Constant(1))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabela de Lápides de Exclusão para Sincronização (Schema v6).
class SyncTombstonesTable extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operationId => text()();
  DateTimeColumn get deletedAt => dateTime()();
  IntColumn get localRevision => integer()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {entityType, entityId},
  ];
}

/// Tabela de Fila de Saída Transacional (Outbox) para Sincronização (Schema v6).
class SyncOutboxTable extends Table {
  TextColumn get operationId => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payloadJson => text().nullable()();
  IntColumn get localRevision => integer()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {operationId};
}
