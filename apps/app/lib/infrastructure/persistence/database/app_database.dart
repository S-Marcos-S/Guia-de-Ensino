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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// Construtor para testes em memória ou arquivo direto
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
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
