import 'dart:io';

import 'package:app/infrastructure/persistence/converters/calendar_date_converter.dart';
import 'package:app/infrastructure/persistence/database/tables.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Banco de dados local SQLite centralizado via Drift.
@DriftDatabase(
  tables: [
    AcademicYearsTable,
    ClassroomsTable,
    SubjectsTable,
    ClassroomSubjectsTable,
    PlannedLessonsTable,
    SchoolCalendarEventsTable,
    ScheduleSlotsTable,
    CurriculumCompetenciesTable,
    CourseContentsTable,
    ContentPrerequisitesTable,
    LessonContentAllocationsTable,
    LessonExecutionRecordsTable,
    ExecutionContentAllocationsTable,
    SyncStateTable,
    SyncTombstonesTable,
    SyncOutboxTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// Construtor para testes em memória ou arquivo direto
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sync_outbox_status '
        'ON sync_outbox_table (status, local_revision);',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sync_tombstones_entity '
        'ON sync_tombstones_table (entity_type, entity_id);',
      );
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(schoolCalendarEventsTable);
        await m.createTable(scheduleSlotsTable);
      }
      if (from < 3) {
        await m.createTable(curriculumCompetenciesTable);
        await m.createTable(courseContentsTable);
        await m.createTable(contentPrerequisitesTable);
      }
      if (from < 4) {
        await m.createTable(lessonContentAllocationsTable);
      }
      if (from < 5) {
        await m.createTable(lessonExecutionRecordsTable);
        await m.createTable(executionContentAllocationsTable);
      }
      if (from < 6) {
        await m.createTable(syncStateTable);
        await m.createTable(syncTombstonesTable);
        await m.createTable(syncOutboxTable);

        await m.addColumn(academicYearsTable, academicYearsTable.updatedAt);
        await m.addColumn(classroomsTable, classroomsTable.updatedAt);
        await m.addColumn(subjectsTable, subjectsTable.updatedAt);
        await m.addColumn(
          classroomSubjectsTable,
          classroomSubjectsTable.updatedAt,
        );
        await m.addColumn(plannedLessonsTable, plannedLessonsTable.updatedAt);
        await m.addColumn(
          schoolCalendarEventsTable,
          schoolCalendarEventsTable.updatedAt,
        );
        await m.addColumn(scheduleSlotsTable, scheduleSlotsTable.updatedAt);
        await m.addColumn(courseContentsTable, courseContentsTable.updatedAt);

        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_sync_outbox_status '
          'ON sync_outbox_table (status, local_revision);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_sync_tombstones_entity '
          'ON sync_tombstones_table (entity_type, entity_id);',
        );
      }
    },
    beforeOpen: (details) async {
      // Garante estritamente a ativação da integridade referencial do SQLite
      await customStatement('PRAGMA foreign_keys = ON;');
    },
  );

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'guia_de_ensino.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
