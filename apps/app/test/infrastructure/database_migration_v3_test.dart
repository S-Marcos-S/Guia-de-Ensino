import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('SQLite Migration Tests (Version 1, 2 to 3)', () {
    test(
      'deve executar onCreate criando todas as tabelas na versão 3',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        expect(db.schemaVersion, equals(4));

        // As novas tabelas v3 devem aceitar inserções sem erro
        await db
            .into(db.curriculumCompetenciesTable)
            .insert(
              CurriculumCompetenciesTableCompanion.insert(
                id: 'comp-1',
                code: 'EF06MA01',
                description: 'Comparar e ordenar números racionais',
                thematicUnit: 'Números',
                stage: 'Ensino Fundamental',
                gradeLevel: '6º ano',
                subjectName: 'Matemática',
                sourceName: 'BNCC',
                sourceVersion: 'Resolução CNE/CP 2/2017',
                createdAt: DateTime.now(),
              ),
            );

        final comps = await db.select(db.curriculumCompetenciesTable).get();
        expect(comps.length, equals(1));
        expect(comps.first.code, equals('EF06MA01'));

        await db.close();
      },
    );

    test('deve aplicar onUpgrade de v2 para v3 criando novas tabelas sem afetar dados existentes', () async {
      final rawDb = NativeDatabase.memory();
      final v2Db = AppDatabase.forTesting(rawDb);

      final migrator = v2Db.createMigrator();
      // Cria tabelas existentes até v2
      await migrator.createTable(v2Db.academicYearsTable);
      await migrator.createTable(v2Db.subjectsTable);
      await migrator.createTable(v2Db.classroomsTable);
      await migrator.createTable(v2Db.classroomSubjectsTable);
      await migrator.createTable(v2Db.plannedLessonsTable);
      await migrator.createTable(v2Db.schoolCalendarEventsTable);
      await migrator.createTable(v2Db.scheduleSlotsTable);

      // Insere dados no estado v2
      await v2Db
          .into(v2Db.academicYearsTable)
          .insert(
            AcademicYearsTableCompanion.insert(
              id: 'ay-v2',
              year: 2026,
              title: 'Ano v2 Preservado',
              startDate: DateTime.utc(2026, 2, 2),
              endDate: DateTime.utc(2026, 12, 18),
              createdAt: DateTime.now(),
            ),
          );

      // Executa a migração onUpgrade de 2 para 3
      await v2Db.migration.onUpgrade(migrator, 2, 3);

      // Verifica que dados pré-existentes de v2 continuam preservados
      final years = await v2Db.select(v2Db.academicYearsTable).get();
      expect(years.length, equals(1));
      expect(years.first.title, equals('Ano v2 Preservado'));

      // Verifica que as tabelas de v3 existem e recebem inserções
      await v2Db
          .into(v2Db.curriculumCompetenciesTable)
          .insert(
            CurriculumCompetenciesTableCompanion.insert(
              id: 'comp-v3',
              code: 'EM13MAT101',
              description: 'Interpretar taxas e variações',
              thematicUnit: 'Álgebra',
              stage: 'Ensino Médio',
              gradeLevel: '1º ao 3º ano',
              subjectName: 'Matemática',
              sourceName: 'BNCC',
              sourceVersion: 'Resolução CNE/CP 4/2018',
              createdAt: DateTime.now(),
            ),
          );

      final comps = await v2Db.select(v2Db.curriculumCompetenciesTable).get();
      expect(comps.length, equals(1));
      expect(comps.first.code, equals('EM13MAT101'));

      await v2Db.close();
    });
  });
}
