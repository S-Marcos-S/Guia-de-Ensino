import 'package:app/domain/models/lesson_execution_record.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/repositories/lesson_execution_repository.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/persistence/repositories/drift_lesson_execution_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_planned_lesson_repository.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('SQLite Migration Tests (Version 4 to 5)', () {
    test(
      'deve executar onCreate criando todas as tabelas na versão 5',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        expect(db.schemaVersion, equals(6));

        // Cria estrutura base
        await db
            .into(db.academicYearsTable)
            .insert(
              AcademicYearsTableCompanion.insert(
                id: 'ay-v5',
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
                id: 'c-v5',
                academicYearId: 'ay-v5',
                name: '8º Ano A',
                gradeLevel: '8º Ano',
                shift: 'morning',
                createdAt: DateTime.now(),
              ),
            );

        await db
            .into(db.subjectsTable)
            .insert(
              SubjectsTableCompanion.insert(
                id: 's-v5',
                name: 'História',
                colorHex: '#FF9800',
                createdAt: DateTime.now(),
              ),
            );

        await db
            .into(db.classroomSubjectsTable)
            .insert(
              ClassroomSubjectsTableCompanion.insert(
                id: 'cs-v5',
                classroomId: 'c-v5',
                subjectId: 's-v5',
                weeklyLessons: 3,
                createdAt: DateTime.now(),
              ),
            );

        await db
            .into(db.courseContentsTable)
            .insert(
              CourseContentsTableCompanion.insert(
                id: 'cnt-v5-1',
                classroomSubjectId: 'cs-v5',
                title: 'Revolução Francesa',
                orderIndex: 1,
                origin: 'manual',
                createdAt: DateTime.now(),
              ),
            );

        await db
            .into(db.plannedLessonsTable)
            .insert(
              PlannedLessonsTableCompanion.insert(
                id: 'l-v5-1',
                classroomSubjectId: 'cs-v5',
                lessonDate: DateTime.utc(2026, 2, 3),
                orderInDay: 1,
                status: LessonExecutionStatus.planned.name,
                createdAt: DateTime.now(),
              ),
            );

        final execRepo = DriftLessonExecutionRepository(db);

        // Salva registro de execução histórico
        final record = LessonExecutionRecord(
          id: 'rec-v5-1',
          plannedLessonId: 'l-v5-1',
          classroomSubjectId: 'cs-v5',
          executionDate: DateTime.utc(2026, 2, 3),
          status: LessonExecutionStatus.completed,
          actualContentIds: ['cnt-v5-1'],
          pedagogicalNotes: 'Excelente debate sobre os ideais iluministas.',
          recordedAt: DateTime.utc(2026, 2, 3, 11, 30),
        );

        await execRepo.save(record);

        // Recupera e valida
        final retrieved = await execRepo.findById('rec-v5-1');
        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals('rec-v5-1'));
        expect(retrieved.status, equals(LessonExecutionStatus.completed));
        expect(retrieved.actualContentIds, equals(['cnt-v5-1']));
        expect(retrieved.executionDate, equals(DateTime.utc(2026, 2, 3)));

        await db.close();
      },
    );

    test(
      'deve aplicar onUpgrade de v4 para v5 preservando todos os dados legados',
      () async {
        final rawDb = NativeDatabase.memory();
        final v4Db = AppDatabase.forTesting(rawDb);

        final migrator = v4Db.createMigrator();
        // Cria tabelas existentes até v4
        await migrator.createTable(v4Db.academicYearsTable);
        await migrator.createTable(v4Db.subjectsTable);
        await migrator.createTable(v4Db.classroomsTable);
        await migrator.createTable(v4Db.classroomSubjectsTable);
        await migrator.createTable(v4Db.plannedLessonsTable);
        await migrator.createTable(v4Db.schoolCalendarEventsTable);
        await migrator.createTable(v4Db.scheduleSlotsTable);
        await migrator.createTable(v4Db.curriculumCompetenciesTable);
        await migrator.createTable(v4Db.courseContentsTable);
        await migrator.createTable(v4Db.contentPrerequisitesTable);
        await migrator.createTable(v4Db.lessonContentAllocationsTable);

        // Insere dados no estado v4
        await v4Db
            .into(v4Db.academicYearsTable)
            .insert(
              AcademicYearsTableCompanion.insert(
                id: 'ay-v4-mig',
                year: 2026,
                title: 'Ano Letivo v4 Migração',
                startDate: DateTime.utc(2026, 2, 2),
                endDate: DateTime.utc(2026, 12, 18),
                createdAt: DateTime.now(),
              ),
            );

        await v4Db
            .into(v4Db.classroomsTable)
            .insert(
              ClassroomsTableCompanion.insert(
                id: 'c-v4-mig',
                academicYearId: 'ay-v4-mig',
                name: '9º Ano A',
                gradeLevel: '9º Ano',
                shift: 'morning',
                createdAt: DateTime.now(),
              ),
            );

        await v4Db
            .into(v4Db.subjectsTable)
            .insert(
              SubjectsTableCompanion.insert(
                id: 's-v4-mig',
                name: 'Geografia',
                colorHex: '#009688',
                createdAt: DateTime.now(),
              ),
            );

        await v4Db
            .into(v4Db.classroomSubjectsTable)
            .insert(
              ClassroomSubjectsTableCompanion.insert(
                id: 'cs-v4-mig',
                classroomId: 'c-v4-mig',
                subjectId: 's-v4-mig',
                weeklyLessons: 2,
                createdAt: DateTime.now(),
              ),
            );

        await v4Db
            .into(v4Db.courseContentsTable)
            .insert(
              CourseContentsTableCompanion.insert(
                id: 'cnt-v4-mig-1',
                classroomSubjectId: 'cs-v4-mig',
                title: 'Globalização e Economia',
                orderIndex: 1,
                origin: 'manual',
                createdAt: DateTime.now(),
              ),
            );

        await v4Db
            .into(v4Db.plannedLessonsTable)
            .insert(
              PlannedLessonsTableCompanion.insert(
                id: 'l-v4-mig-1',
                classroomSubjectId: 'cs-v4-mig',
                lessonDate: DateTime.utc(2026, 2, 5),
                orderInDay: 1,
                status: LessonExecutionStatus.planned.name,
                createdAt: DateTime.now(),
              ),
            );

        await v4Db
            .into(v4Db.lessonContentAllocationsTable)
            .insert(
              LessonContentAllocationsTableCompanion.insert(
                lessonId: 'l-v4-mig-1',
                contentId: 'cnt-v4-mig-1',
                orderIndex: const Value(1),
              ),
            );

        // Executa migração de v4 para v5
        await v4Db.migration.onUpgrade(migrator, 4, 5);

        // 1. Verifica integridade dos dados pré-existentes
        final plannedRepo = DriftPlannedLessonRepository(v4Db);
        final preExistingLesson = await plannedRepo.findById('l-v4-mig-1');
        expect(preExistingLesson, isNotNull);
        expect(preExistingLesson!.id, equals('l-v4-mig-1'));
        expect(preExistingLesson.contentIds, equals(['cnt-v4-mig-1']));

        // 2. Grava registro na nova estrutura v5
        final execRepo = DriftLessonExecutionRepository(v4Db);
        final execRecord = LessonExecutionRecord(
          id: 'rec-mig-1',
          plannedLessonId: 'l-v4-mig-1',
          classroomSubjectId: 'cs-v4-mig',
          executionDate: DateTime.utc(2026, 2, 5),
          status: LessonExecutionStatus.completed,
          actualContentIds: ['cnt-v4-mig-1'],
          recordedAt: DateTime.utc(2026, 2, 5, 12, 0),
        );

        await execRepo.save(execRecord);

        final retrievedExec = await execRepo.findByPlannedLessonId(
          'l-v4-mig-1',
        );
        expect(retrievedExec, isNotNull);
        expect(retrievedExec!.id, equals('rec-mig-1'));
        expect(retrievedExec.actualContentIds, equals(['cnt-v4-mig-1']));

        await v4Db.close();
      },
    );

    test('deve suportar migrações encadeadas a partir de versões históricas v1, v2 e v3 até v5', () async {
      final rawDb = NativeDatabase.memory();
      final db = AppDatabase.forTesting(rawDb);
      final migrator = db.createMigrator();

      // Simula tabelas de v1
      await migrator.createTable(db.academicYearsTable);
      await migrator.createTable(db.subjectsTable);
      await migrator.createTable(db.classroomsTable);
      await migrator.createTable(db.classroomSubjectsTable);
      await migrator.createTable(db.plannedLessonsTable);

      // Aplica upgrade de v1 até v5
      await db.migration.onUpgrade(migrator, 1, 5);

      // Verifica que tabelas de v5 estão operacionais
      final execRows = await db.select(db.lessonExecutionRecordsTable).get();
      expect(execRows, isEmpty);

      await db.close();
    });

    test('deve atualizar registro de execução sem duplicar associações de conteúdos', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final execRepo = DriftLessonExecutionRepository(db);

      // Insere estrutura básica
      await _setupBaseEntities(db, 'cs-upd');

      // Cria dois conteúdos
      await db
          .into(db.courseContentsTable)
          .insert(
            CourseContentsTableCompanion.insert(
              id: 'cnt-u1',
              classroomSubjectId: 'cs-upd',
              title: 'Conteúdo 1',
              orderIndex: 1,
              origin: 'manual',
              createdAt: DateTime.now(),
            ),
          );
      await db
          .into(db.courseContentsTable)
          .insert(
            CourseContentsTableCompanion.insert(
              id: 'cnt-u2',
              classroomSubjectId: 'cs-upd',
              title: 'Conteúdo 2',
              orderIndex: 2,
              origin: 'manual',
              createdAt: DateTime.now(),
            ),
          );

      await db
          .into(db.plannedLessonsTable)
          .insert(
            PlannedLessonsTableCompanion.insert(
              id: 'l-upd-1',
              classroomSubjectId: 'cs-upd',
              lessonDate: DateTime.utc(2026, 3, 2),
              orderInDay: 1,
              status: LessonExecutionStatus.planned.name,
              createdAt: DateTime.now(),
            ),
          );

      // 1. Gravação inicial: apenas cnt-u1
      final recInitial = LessonExecutionRecord(
        id: 'rec-upd-1',
        plannedLessonId: 'l-upd-1',
        classroomSubjectId: 'cs-upd',
        executionDate: DateTime.utc(2026, 3, 2),
        status: LessonExecutionStatus.partiallyCompleted,
        actualContentIds: ['cnt-u1'],
        pedagogicalNotes: 'Apenas introdução.',
        recordedAt: DateTime.utc(2026, 3, 2, 10, 0),
      );
      await execRepo.save(recInitial);

      var retrieved = await execRepo.findById('rec-upd-1');
      expect(retrieved!.actualContentIds, equals(['cnt-u1']));

      // 2. Retificação: adiciona cnt-u2 e altera status para completed
      final recUpdated = recInitial.copyWith(
        status: LessonExecutionStatus.completed,
        actualContentIds: ['cnt-u1', 'cnt-u2'],
        updatedAt: DateTime.utc(2026, 3, 2, 14, 0),
        pedagogicalNotes: 'Retificado: ambos os tópicos concluídos.',
      );
      await execRepo.save(recUpdated);

      retrieved = await execRepo.findById('rec-upd-1');
      expect(retrieved!.actualContentIds, equals(['cnt-u1', 'cnt-u2']));
      expect(retrieved.status, equals(LessonExecutionStatus.completed));
      expect(retrieved.isRectified, isTrue);

      // Confirma que não há linhas orfãs na tabela de junção
      final allocRows = await (db.select(
        db.executionContentAllocationsTable,
      )..where((tbl) => tbl.recordId.equals('rec-upd-1'))).get();
      expect(allocRows.length, equals(2));

      await db.close();
    });

    test('deve garantir unicidade do registro por aula planejada', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await _setupBaseEntities(db, 'cs-unique');

      await db
          .into(db.plannedLessonsTable)
          .insert(
            PlannedLessonsTableCompanion.insert(
              id: 'l-unique-1',
              classroomSubjectId: 'cs-unique',
              lessonDate: DateTime.utc(2026, 3, 5),
              orderInDay: 1,
              status: LessonExecutionStatus.planned.name,
              createdAt: DateTime.now(),
            ),
          );

      // Insere primeiro registro
      await db
          .into(db.lessonExecutionRecordsTable)
          .insert(
            LessonExecutionRecordsTableCompanion.insert(
              id: 'rec-1',
              plannedLessonId: 'l-unique-1',
              classroomSubjectId: 'cs-unique',
              executionDate: DateTime.utc(2026, 3, 5),
              status: LessonExecutionStatus.notHeld.name,
              cancellationReason: const Value('schoolEvent'),
              recordedAt: DateTime.now(),
            ),
          );

      // Tenta inserir segundo registro com outro ID para a MESMA aula planejada
      expect(
        () async => await db
            .into(db.lessonExecutionRecordsTable)
            .insert(
              LessonExecutionRecordsTableCompanion.insert(
                id: 'rec-2',
                plannedLessonId: 'l-unique-1',
                classroomSubjectId: 'cs-unique',
                executionDate: DateTime.utc(2026, 3, 5),
                status: LessonExecutionStatus.notHeld.name,
                cancellationReason: const Value('other'),
                recordedAt: DateTime.now(),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );

      await db.close();
    });

    test('deve impedir exclusão de aula planejada que possui registro de execução (KeyAction.restrict)', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await _setupBaseEntities(db, 'cs-protect');

      await db
          .into(db.plannedLessonsTable)
          .insert(
            PlannedLessonsTableCompanion.insert(
              id: 'l-prot-1',
              classroomSubjectId: 'cs-protect',
              lessonDate: DateTime.utc(2026, 3, 6),
              orderInDay: 1,
              status: LessonExecutionStatus.completed.name,
              createdAt: DateTime.now(),
            ),
          );

      await db
          .into(db.lessonExecutionRecordsTable)
          .insert(
            LessonExecutionRecordsTableCompanion.insert(
              id: 'rec-prot-1',
              plannedLessonId: 'l-prot-1',
              classroomSubjectId: 'cs-protect',
              executionDate: DateTime.utc(2026, 3, 6),
              status: LessonExecutionStatus.completed.name,
              recordedAt: DateTime.now(),
            ),
          );

      // Tentar excluir diretamente no SQLite via DELETE deve falhar com violação de chave estrangeira
      expect(
        () async => await (db.delete(
          db.plannedLessonsTable,
        )..where((tbl) => tbl.id.equals('l-prot-1'))).go(),
        throwsA(isA<SqliteException>()),
      );

      await db.close();
    });

    test('deve impedir exclusão de conteúdo programático que foi ministrado (KeyAction.restrict)', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await _setupBaseEntities(db, 'cs-cont-prot');

      await db
          .into(db.courseContentsTable)
          .insert(
            CourseContentsTableCompanion.insert(
              id: 'cnt-prot-1',
              classroomSubjectId: 'cs-cont-prot',
              title: 'Conteúdo Protegido',
              orderIndex: 1,
              origin: 'manual',
              createdAt: DateTime.now(),
            ),
          );

      await db
          .into(db.plannedLessonsTable)
          .insert(
            PlannedLessonsTableCompanion.insert(
              id: 'l-cont-prot-1',
              classroomSubjectId: 'cs-cont-prot',
              lessonDate: DateTime.utc(2026, 3, 7),
              orderInDay: 1,
              status: LessonExecutionStatus.completed.name,
              createdAt: DateTime.now(),
            ),
          );

      final execRepo = DriftLessonExecutionRepository(db);
      final record = LessonExecutionRecord(
        id: 'rec-cont-prot',
        plannedLessonId: 'l-cont-prot-1',
        classroomSubjectId: 'cs-cont-prot',
        executionDate: DateTime.utc(2026, 3, 7),
        status: LessonExecutionStatus.completed,
        actualContentIds: ['cnt-prot-1'],
        recordedAt: DateTime.now(),
      );
      await execRepo.save(record);

      // Tentar deletar o CourseContent deve falhar no SQLite
      expect(
        () async => await (db.delete(
          db.courseContentsTable,
        )..where((tbl) => tbl.id.equals('cnt-prot-1'))).go(),
        throwsA(isA<SqliteException>()),
      );

      await db.close();
    });

    test('deve rejeitar e realizar rollback completo se validação de contexto falhar', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await _setupBaseEntities(db, 'cs-trans');

      // Cria disciplina diferente para cs-other
      await db
          .into(db.subjectsTable)
          .insert(
            SubjectsTableCompanion.insert(
              id: 's-other',
              name: 'Outra Disciplina',
              colorHex: '#3F51B5',
              createdAt: DateTime.now(),
            ),
          );

      await db
          .into(db.classroomSubjectsTable)
          .insert(
            ClassroomSubjectsTableCompanion.insert(
              id: 'cs-other',
              classroomId: 'c-base',
              subjectId: 's-other',
              weeklyLessons: 2,
              createdAt: DateTime.now(),
            ),
          );

      // Conteúdo pertence a cs-other
      await db
          .into(db.courseContentsTable)
          .insert(
            CourseContentsTableCompanion.insert(
              id: 'cnt-other',
              classroomSubjectId: 'cs-other',
              title: 'Conteúdo de outra turma',
              orderIndex: 1,
              origin: 'manual',
              createdAt: DateTime.now(),
            ),
          );

      await db
          .into(db.plannedLessonsTable)
          .insert(
            PlannedLessonsTableCompanion.insert(
              id: 'l-trans-1',
              classroomSubjectId: 'cs-trans',
              lessonDate: DateTime.utc(2026, 3, 8),
              orderInDay: 1,
              status: LessonExecutionStatus.planned.name,
              createdAt: DateTime.now(),
            ),
          );

      final execRepo = DriftLessonExecutionRepository(db);

      // Registro aponta para cs-trans, mas tenta vincular cnt-other (de cs-other)
      final invalidRecord = LessonExecutionRecord(
        id: 'rec-trans-fail',
        plannedLessonId: 'l-trans-1',
        classroomSubjectId: 'cs-trans',
        executionDate: DateTime.utc(2026, 3, 8),
        status: LessonExecutionStatus.completed,
        actualContentIds: ['cnt-other'],
        recordedAt: DateTime.now(),
      );

      expect(
        () async => await execRepo.save(invalidRecord),
        throwsA(isA<LessonExecutionIntegrityException>()),
      );

      // Verifica que o rollback ocorreu e nenhum registro foi criado
      final records = await db.select(db.lessonExecutionRecordsTable).get();
      expect(records, isEmpty);

      final allocations = await db
          .select(db.executionContentAllocationsTable)
          .get();
      expect(allocations, isEmpty);

      // PlannedLesson continua com status planned intocado
      final lesson = await (db.select(
        db.plannedLessonsTable,
      )..where((tbl) => tbl.id.equals('l-trans-1'))).getSingle();
      expect(lesson.status, equals(LessonExecutionStatus.planned.name));

      await db.close();
    });

    test(
      'deve listar registros por turma/disciplina e por intervalo de datas',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        await _setupBaseEntities(db, 'cs-list');

        // Cria duas aulas e dois registros em datas diferentes
        await db
            .into(db.plannedLessonsTable)
            .insert(
              PlannedLessonsTableCompanion.insert(
                id: 'l-list-1',
                classroomSubjectId: 'cs-list',
                lessonDate: DateTime.utc(2026, 3, 10),
                orderInDay: 1,
                status: LessonExecutionStatus.planned.name,
                createdAt: DateTime.now(),
              ),
            );

        await db
            .into(db.plannedLessonsTable)
            .insert(
              PlannedLessonsTableCompanion.insert(
                id: 'l-list-2',
                classroomSubjectId: 'cs-list',
                lessonDate: DateTime.utc(2026, 3, 17),
                orderInDay: 1,
                status: LessonExecutionStatus.planned.name,
                createdAt: DateTime.now(),
              ),
            );

        final execRepo = DriftLessonExecutionRepository(db);

        await execRepo.save(
          LessonExecutionRecord(
            id: 'rec-list-1',
            plannedLessonId: 'l-list-1',
            classroomSubjectId: 'cs-list',
            executionDate: DateTime.utc(2026, 3, 10),
            status: LessonExecutionStatus.notHeld,
            cancellationReason: LessonCancellationReason.teacherAbsence,
            recordedAt: DateTime.now(),
          ),
        );

        await execRepo.save(
          LessonExecutionRecord(
            id: 'rec-list-2',
            plannedLessonId: 'l-list-2',
            classroomSubjectId: 'cs-list',
            executionDate: DateTime.utc(2026, 3, 17),
            status: LessonExecutionStatus.partiallyCompleted,
            pedagogicalNotes: 'Aula parcial.',
            recordedAt: DateTime.now(),
          ),
        );

        // Listar todos da turma/disciplina
        final all = await execRepo.getByClassroomSubject('cs-list');
        expect(all.length, equals(2));
        expect(all[0].id, equals('rec-list-1'));
        expect(all[1].id, equals('rec-list-2'));

        // Filtrar por intervalo que inclui apenas o primeiro
        final range1 = await execRepo.getByDateRange(
          'cs-list',
          DateTime.utc(2026, 3, 9),
          DateTime.utc(2026, 3, 12),
        );
        expect(range1.length, equals(1));
        expect(range1.first.id, equals('rec-list-1'));

        // Filtrar por intervalo que inclui ambos
        final rangeBoth = await execRepo.getByDateRange(
          'cs-list',
          DateTime.utc(2026, 3, 9),
          DateTime.utc(2026, 3, 20),
        );
        expect(rangeBoth.length, equals(2));

        await db.close();
      },
    );
  });
}

Future<void> _setupBaseEntities(AppDatabase db, String csId) async {
  await db
      .into(db.academicYearsTable)
      .insert(
        AcademicYearsTableCompanion.insert(
          id: 'ay-base',
          year: 2026,
          title: 'Ano Letivo Base',
          startDate: DateTime.utc(2026, 2, 2),
          endDate: DateTime.utc(2026, 12, 18),
          createdAt: DateTime.now(),
        ),
        mode: InsertMode.insertOrIgnore,
      );

  await db
      .into(db.classroomsTable)
      .insert(
        ClassroomsTableCompanion.insert(
          id: 'c-base',
          academicYearId: 'ay-base',
          name: 'Turma Base',
          gradeLevel: 'Fundamental',
          shift: 'morning',
          createdAt: DateTime.now(),
        ),
        mode: InsertMode.insertOrIgnore,
      );

  await db
      .into(db.subjectsTable)
      .insert(
        SubjectsTableCompanion.insert(
          id: 's-base',
          name: 'Disciplina Base',
          colorHex: '#9C27B0',
          createdAt: DateTime.now(),
        ),
        mode: InsertMode.insertOrIgnore,
      );

  await db
      .into(db.classroomSubjectsTable)
      .insert(
        ClassroomSubjectsTableCompanion.insert(
          id: csId,
          classroomId: 'c-base',
          subjectId: 's-base',
          weeklyLessons: 4,
          createdAt: DateTime.now(),
        ),
        mode: InsertMode.insertOrReplace,
      );
}
