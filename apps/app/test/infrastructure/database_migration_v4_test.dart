import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/persistence/repositories/drift_planned_lesson_repository.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('SQLite Migration Tests (Version 3 to 4)', () {
    test(
      'deve executar onCreate criando todas as tabelas na versão 4',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        expect(db.schemaVersion, equals(4));

        // Insere estrutura básica
        await db
            .into(db.academicYearsTable)
            .insert(
              AcademicYearsTableCompanion.insert(
                id: 'ay-v4',
                year: 2026,
                title: 'Ano Letivo 2026',
                startDate: DateTime.utc(2026, 2, 2),
                endDate: DateTime.utc(2026, 12, 18),
                createdAt: DateTime.now(),
              ),
            );

        await db
            .into(db.classroomsTable)
            .insert(
              ClassroomsTableCompanion.insert(
                id: 'c-v4',
                academicYearId: 'ay-v4',
                name: '6º Ano A',
                gradeLevel: '6º Ano',
                shift: 'morning',
                createdAt: DateTime.now(),
              ),
            );

        await db
            .into(db.subjectsTable)
            .insert(
              SubjectsTableCompanion.insert(
                id: 's-v4',
                name: 'Matemática',
                colorHex: '#2196F3',
                createdAt: DateTime.now(),
              ),
            );

        await db
            .into(db.classroomSubjectsTable)
            .insert(
              ClassroomSubjectsTableCompanion.insert(
                id: 'cs-v4',
                classroomId: 'c-v4',
                subjectId: 's-v4',
                weeklyLessons: 4,
                createdAt: DateTime.now(),
              ),
            );

        await db
            .into(db.courseContentsTable)
            .insert(
              CourseContentsTableCompanion.insert(
                id: 'cnt-v4',
                classroomSubjectId: 'cs-v4',
                title: 'Números Primos',
                orderIndex: 1,
                origin: 'manual',
                createdAt: DateTime.now(),
              ),
            );

        final repo = DriftPlannedLessonRepository(db);

        // Salva aula planejada associada ao conteúdo
        final lesson = PlannedLesson(
          id: 'l-v4-1',
          classroomSubjectId: 'cs-v4',
          date: DateTime.utc(2026, 2, 2),
          orderInDay: 1,
          contentIds: ['cnt-v4'],
          status: LessonExecutionStatus.planned,
        );

        await repo.save(lesson);

        // Recupera e confirma que contentIds foram persistidos e restaurados
        final retrieved = await repo.findById('l-v4-1');
        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals('l-v4-1'));
        expect(retrieved.contentIds, equals(['cnt-v4']));

        // Atualiza a aula alterando os contentIds
        final updatedLesson = lesson.copyWith(contentIds: []);
        await repo.save(updatedLesson);

        final retrievedUpdated = await repo.findById('l-v4-1');
        expect(retrievedUpdated!.contentIds, isEmpty);

        await db.close();
      },
    );

    test('deve aplicar onUpgrade de v3 para v4 criando lessonContentAllocationsTable preservando dados', () async {
      final rawDb = NativeDatabase.memory();
      final v3Db = AppDatabase.forTesting(rawDb);

      final migrator = v3Db.createMigrator();
      // Cria tabelas existentes até v3
      await migrator.createTable(v3Db.academicYearsTable);
      await migrator.createTable(v3Db.subjectsTable);
      await migrator.createTable(v3Db.classroomsTable);
      await migrator.createTable(v3Db.classroomSubjectsTable);
      await migrator.createTable(v3Db.plannedLessonsTable);
      await migrator.createTable(v3Db.schoolCalendarEventsTable);
      await migrator.createTable(v3Db.scheduleSlotsTable);
      await migrator.createTable(v3Db.curriculumCompetenciesTable);
      await migrator.createTable(v3Db.courseContentsTable);
      await migrator.createTable(v3Db.contentPrerequisitesTable);

      // Insere aula no estado v3
      await v3Db
          .into(v3Db.academicYearsTable)
          .insert(
            AcademicYearsTableCompanion.insert(
              id: 'ay-v3',
              year: 2026,
              title: 'Ano Letivo v3',
              startDate: DateTime.utc(2026, 2, 2),
              endDate: DateTime.utc(2026, 12, 18),
              createdAt: DateTime.now(),
            ),
          );

      await v3Db
          .into(v3Db.classroomsTable)
          .insert(
            ClassroomsTableCompanion.insert(
              id: 'c-v3',
              academicYearId: 'ay-v3',
              name: '7º Ano B',
              gradeLevel: '7º Ano',
              shift: 'morning',
              createdAt: DateTime.now(),
            ),
          );

      await v3Db
          .into(v3Db.subjectsTable)
          .insert(
            SubjectsTableCompanion.insert(
              id: 's-v3',
              name: 'Ciências',
              colorHex: '#4CAF50',
              createdAt: DateTime.now(),
            ),
          );

      await v3Db
          .into(v3Db.classroomSubjectsTable)
          .insert(
            ClassroomSubjectsTableCompanion.insert(
              id: 'cs-v3',
              classroomId: 'c-v3',
              subjectId: 's-v3',
              weeklyLessons: 3,
              createdAt: DateTime.now(),
            ),
          );

      await v3Db
          .into(v3Db.plannedLessonsTable)
          .insert(
            PlannedLessonsTableCompanion.insert(
              id: 'l-v3-1',
              classroomSubjectId: 'cs-v3',
              lessonDate: DateTime.utc(2026, 2, 2),
              orderInDay: 1,
              status: LessonExecutionStatus.planned.name,
              createdAt: DateTime.now(),
            ),
          );

      // Executa migração de 3 para 4
      await v3Db.migration.onUpgrade(migrator, 3, 4);

      // Verifica que aula pré-existente de v3 foi preservada
      final repo = DriftPlannedLessonRepository(v3Db);
      final lesson = await repo.findById('l-v3-1');
      expect(lesson, isNotNull);
      expect(lesson!.id, equals('l-v3-1'));
      expect(lesson.contentIds, isEmpty);

      // Insere conteúdo e associa a uma nova aula no schema v4
      await v3Db
          .into(v3Db.courseContentsTable)
          .insert(
            CourseContentsTableCompanion.insert(
              id: 'cnt-v4-new',
              classroomSubjectId: 'cs-v3',
              title: 'Células e Tecidos',
              orderIndex: 1,
              origin: 'manual',
              createdAt: DateTime.now(),
            ),
          );

      final newLesson = PlannedLesson(
        id: 'l-v4-2',
        classroomSubjectId: 'cs-v3',
        date: DateTime.utc(2026, 2, 9),
        orderInDay: 1,
        contentIds: ['cnt-v4-new'],
      );

      await repo.save(newLesson);

      final retrievedNew = await repo.findById('l-v4-2');
      expect(retrievedNew, isNotNull);
      expect(retrievedNew!.contentIds, equals(['cnt-v4-new']));

      await v3Db.close();
    });

    test('respeita integridade referencial: foreign keys ativadas impedem deleção acidental de conteúdo em uso', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());

      // Ativa explicitamente foreign keys
      await db.customStatement('PRAGMA foreign_keys = ON;');

      // Setup
      await db
          .into(db.academicYearsTable)
          .insert(
            AcademicYearsTableCompanion.insert(
              id: 'ay-fk',
              year: 2026,
              title: 'Ano FK',
              startDate: DateTime.utc(2026, 2, 2),
              endDate: DateTime.utc(2026, 12, 18),
              createdAt: DateTime.now(),
            ),
          );

      await db
          .into(db.classroomsTable)
          .insert(
            ClassroomsTableCompanion.insert(
              id: 'c-fk',
              academicYearId: 'ay-fk',
              name: '8º Ano',
              gradeLevel: '8º Ano',
              shift: 'morning',
              createdAt: DateTime.now(),
            ),
          );

      await db
          .into(db.subjectsTable)
          .insert(
            SubjectsTableCompanion.insert(
              id: 's-fk',
              name: 'História',
              colorHex: '#FF9800',
              createdAt: DateTime.now(),
            ),
          );

      await db
          .into(db.classroomSubjectsTable)
          .insert(
            ClassroomSubjectsTableCompanion.insert(
              id: 'cs-fk',
              classroomId: 'c-fk',
              subjectId: 's-fk',
              weeklyLessons: 2,
              createdAt: DateTime.now(),
            ),
          );

      await db
          .into(db.courseContentsTable)
          .insert(
            CourseContentsTableCompanion.insert(
              id: 'cnt-fk',
              classroomSubjectId: 'cs-fk',
              title: 'Revolução Industrial',
              orderIndex: 1,
              origin: 'manual',
              createdAt: DateTime.now(),
            ),
          );

      final repo = DriftPlannedLessonRepository(db);
      await repo.save(
        PlannedLesson(
          id: 'l-fk-1',
          classroomSubjectId: 'cs-fk',
          date: DateTime.utc(2026, 2, 2),
          orderInDay: 1,
          contentIds: ['cnt-fk'],
        ),
      );

      // Tentar deletar o conteúdo que está associado à aula deve falhar por restrição de FK
      expect(
        () async => (db.delete(
          db.courseContentsTable,
        )..where((tbl) => tbl.id.equals('cnt-fk'))).go(),
        throwsA(isA<SqliteException>()),
      );

      // Deletar a aula não-histórica deve ter sucesso e remover a alocação em cascata
      await repo.delete('l-fk-1');

      // Agora que a aula foi removida, o conteúdo pode ser deletado sem erro
      final deletedCount = await (db.delete(
        db.courseContentsTable,
      )..where((tbl) => tbl.id.equals('cnt-fk'))).go();
      expect(deletedCount, equals(1));

      await db.close();
    });
  });
}
