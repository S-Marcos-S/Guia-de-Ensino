import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('SQLite Migration Tests (Version 1 to 2)', () {
    test(
      'deve executar onCreate criando todas as tabelas na versão atual',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        expect(db.schemaVersion, equals(4));

        // As novas tabelas devem aceitar inserções sem erro
        const yearId = 'ay-mig-2026';
        await db
            .into(db.academicYearsTable)
            .insert(
              AcademicYearsTableCompanion.insert(
                id: yearId,
                year: 2026,
                title: 'Ano Letivo 2026',
                startDate: DateTime.utc(2026, 2, 2),
                endDate: DateTime.utc(2026, 12, 18),
                createdAt: DateTime.now(),
              ),
            );

        await db
            .into(db.schoolCalendarEventsTable)
            .insert(
              SchoolCalendarEventsTableCompanion.insert(
                id: 'ev-mig-1',
                academicYearId: yearId,
                title: 'Feriado Migração',
                startDate: DateTime.utc(2026, 5, 1),
                endDate: DateTime.utc(2026, 5, 1),
                type: 'holiday',
                createdAt: DateTime.now(),
              ),
            );

        final events = await db.select(db.schoolCalendarEventsTable).get();
        expect(events.length, equals(1));
        expect(events.first.title, equals('Feriado Migração'));

        await db.close();
      },
    );

    test('deve aplicar onUpgrade de v1 para v2 criando novas tabelas sem afetar dados existentes', () async {
      // Simula um banco com schema versão 1 criando manualmente as tabelas da v1
      final rawDb = NativeDatabase.memory();
      final executor = rawDb;

      // Executa criação manual da v1
      final v1Db = AppDatabase.forTesting(executor);
      // Forçamos o schema customizado para testar onUpgrade
      final migrator = v1Db.createMigrator();
      await migrator.createTable(v1Db.academicYearsTable);
      await migrator.createTable(v1Db.subjectsTable);
      await migrator.createTable(v1Db.classroomsTable);
      await migrator.createTable(v1Db.classroomSubjectsTable);
      await migrator.createTable(v1Db.plannedLessonsTable);

      // Insere dado no estado v1
      await v1Db
          .into(v1Db.academicYearsTable)
          .insert(
            AcademicYearsTableCompanion.insert(
              id: 'ay-v1',
              year: 2026,
              title: 'Ano v1 Preservado',
              startDate: DateTime.utc(2026, 2, 2),
              endDate: DateTime.utc(2026, 12, 18),
              createdAt: DateTime.now(),
            ),
          );

      // Simula a migração onUpgrade de 1 para 2
      await v1Db.migration.onUpgrade(migrator, 1, 2);

      // Verifica se os dados existentes continuam intactos
      final years = await v1Db.select(v1Db.academicYearsTable).get();
      expect(years.length, equals(1));
      expect(years.first.title, equals('Ano v1 Preservado'));

      // Verifica se a nova tabela v2 foi criada e aceita dados normalmente
      await v1Db
          .into(v1Db.schoolCalendarEventsTable)
          .insert(
            SchoolCalendarEventsTableCompanion.insert(
              id: 'ev-post-migration',
              academicYearId: 'ay-v1',
              title: 'Evento Pós-Migração',
              startDate: DateTime.utc(2026, 6, 1),
              endDate: DateTime.utc(2026, 6, 1),
              type: 'recess',
              createdAt: DateTime.now(),
            ),
          );

      final events = await v1Db.select(v1Db.schoolCalendarEventsTable).get();
      expect(events.length, equals(1));
      expect(events.first.title, equals('Evento Pós-Migração'));

      await v1Db.close();
    });
  });
}
