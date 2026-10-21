import 'package:app/domain/repositories/planned_lesson_repository.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/sync/models/change_dto.dart';
import 'package:app/infrastructure/sync/models/snapshot_response_dto.dart';
import 'package:app/infrastructure/sync/models/sync_entity_type.dart';
import 'package:app/infrastructure/sync/orchestrator/sync_staging_handler.dart';
import 'package:app/infrastructure/sync/outbox/sync_outbox_item.dart';
import 'package:app/infrastructure/sync/outbox/sync_outbox_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SyncOutboxRepository outboxRepo;
  late SyncStagingHandler stagingHandler;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    outboxRepo = SyncOutboxRepository(db);
    stagingHandler = SyncStagingHandler(db);
    // Garante foreign keys ativas nos testes
    await db.customStatement('PRAGMA foreign_keys = ON;');
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncStagingHandler — Ausência de Eco na Outbox e Preservação Local', () {
    test(
      'ingestão de deltas remotos NÃO gera novas operações na Outbox',
      () async {
        // Enfileira uma operação local previamente existente
        final localOp = await outboxRepo.enqueueOperation(
          entityType: SyncEntityType.subject,
          entityId: 'sub-local',
          operation: SyncMutationType.insert,
          payload: {'name': 'Local'},
        );

        // Aplica delta remoto de INSERT
        final change = ChangeDto(
          serverSeq: '1',
          changeLogId: '101',
          entityType: SyncEntityType.academicYear,
          entityId: 'ay-remote-1',
          mutationType: 'INSERT',
          payload: {
            'id': 'ay-remote-1',
            'year': 2026,
            'title': 'Ano 2026 Remoto',
            'start_date': '2026-02-01',
            'end_date': '2026-12-15',
            'total_mandatory_days': 200,
            'created_at': '2026-01-10T10:00:00.000Z',
          },
          deviceId: 'other-device',
          createdAt: DateTime.utc(2026, 1, 10, 10),
        );

        await stagingHandler.applyChange(change);

        // O ano letivo deve ter sido persistido no banco
        final row = await (db.select(
          db.academicYearsTable,
        )..where((tbl) => tbl.id.equals('ay-remote-1'))).getSingleOrNull();
        expect(row, isNotNull);
        expect(row!.title, equals('Ano 2026 Remoto'));

        // A Outbox deve conter ESTRITAMENTE a operação local original (SEM ECO)
        final allOps = await outboxRepo.getAllOperations();
        expect(allOps.length, equals(1));
        expect(allOps.first.operationId, equals(localOp.operationId));

        // Nenhuma lápide deve ter sido gerada
        final tombstones = await outboxRepo.getTombstones();
        expect(tombstones, isEmpty);
      },
    );
  });

  group(
    'SyncStagingHandler — Ingestão de Deltas de Pull (INSERT, UPDATE, DELETE)',
    () {
      test(
        'aplica INSERT, UPDATE e DELETE em cadeia respeitando integridade',
        () async {
          // 1. INSERT de Ano Letivo e Disciplina
          await stagingHandler.applyChanges([
            ChangeDto(
              serverSeq: '1',
              changeLogId: '1',
              entityType: SyncEntityType.academicYear,
              entityId: 'ay-1',
              mutationType: 'INSERT',
              payload: {
                'id': 'ay-1',
                'year': 2026,
                'title': 'Ano 2026',
                'start_date': '2026-02-01',
                'end_date': '2026-12-10',
              },
              deviceId: 'dev-1',
              createdAt: DateTime.utc(2026, 1, 1),
            ),
            ChangeDto(
              serverSeq: '2',
              changeLogId: '2',
              entityType: SyncEntityType.subject,
              entityId: 'sub-1',
              mutationType: 'INSERT',
              payload: {
                'id': 'sub-1',
                'name': 'Matemática',
                'color_hex': '#FF0000',
              },
              deviceId: 'dev-1',
              createdAt: DateTime.utc(2026, 1, 1),
            ),
          ]);

          var sub = await (db.select(
            db.subjectsTable,
          )..where((tbl) => tbl.id.equals('sub-1'))).getSingle();
          expect(sub.name, equals('Matemática'));
          expect(sub.colorHex, equals('#FF0000'));

          // 2. UPDATE da Disciplina
          await stagingHandler.applyChange(
            ChangeDto(
              serverSeq: '3',
              changeLogId: '3',
              entityType: SyncEntityType.subject,
              entityId: 'sub-1',
              mutationType: 'UPDATE',
              payload: {
                'id': 'sub-1',
                'name': 'Matemática Avançada',
                'color_hex': '#00FF00',
                'updated_at': '2026-01-05T12:00:00.000Z',
              },
              deviceId: 'dev-2',
              createdAt: DateTime.utc(2026, 1, 5),
            ),
          );

          sub = await (db.select(
            db.subjectsTable,
          )..where((tbl) => tbl.id.equals('sub-1'))).getSingle();
          expect(sub.name, equals('Matemática Avançada'));
          expect(sub.colorHex, equals('#00FF00'));

          // 3. DELETE da Disciplina
          await stagingHandler.applyChange(
            ChangeDto(
              serverSeq: '4',
              changeLogId: '4',
              entityType: SyncEntityType.subject,
              entityId: 'sub-1',
              mutationType: 'DELETE',
              payload: null,
              deviceId: 'dev-2',
              createdAt: DateTime.utc(2026, 1, 6),
            ),
          );

          final deletedSub = await (db.select(
            db.subjectsTable,
          )..where((tbl) => tbl.id.equals('sub-1'))).getSingleOrNull();
          expect(deletedSub, isNull);

          // Confirma ausência total de poluição na outbox
          expect(await outboxRepo.getAllOperations(), isEmpty);
        },
      );

      test('trata entidades associativas com chaves compostas', () async {
        // Cria a hierarquia base
        await stagingHandler.applyChanges([
          ChangeDto(
            serverSeq: '1',
            changeLogId: '1',
            entityType: SyncEntityType.academicYear,
            entityId: 'ay-assoc',
            mutationType: 'INSERT',
            payload: {
              'id': 'ay-assoc',
              'year': 2026,
              'title': '2026',
              'start_date': '2026-02-01',
              'end_date': '2026-12-01',
            },
            deviceId: 'd1',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
          ChangeDto(
            serverSeq: '2',
            changeLogId: '2',
            entityType: SyncEntityType.classroom,
            entityId: 'c-assoc',
            mutationType: 'INSERT',
            payload: {
              'id': 'c-assoc',
              'academic_year_id': 'ay-assoc',
              'name': '7A',
              'grade_level': '7',
              'shift': 'morning',
            },
            deviceId: 'd1',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
          ChangeDto(
            serverSeq: '3',
            changeLogId: '3',
            entityType: SyncEntityType.subject,
            entityId: 'sub-assoc',
            mutationType: 'INSERT',
            payload: {
              'id': 'sub-assoc',
              'name': 'Geografia',
              'color_hex': '#2196F3',
            },
            deviceId: 'd1',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
          ChangeDto(
            serverSeq: '4',
            changeLogId: '4',
            entityType: SyncEntityType.classroomSubject,
            entityId: 'cs-assoc',
            mutationType: 'INSERT',
            payload: {
              'id': 'cs-assoc',
              'classroom_id': 'c-assoc',
              'subject_id': 'sub-assoc',
              'weekly_lessons': 3,
            },
            deviceId: 'd1',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
          ChangeDto(
            serverSeq: '5',
            changeLogId: '5',
            entityType: SyncEntityType.courseContent,
            entityId: 'cc-1',
            mutationType: 'INSERT',
            payload: {
              'id': 'cc-1',
              'classroom_subject_id': 'cs-assoc',
              'title': 'Relevo',
              'order_index': 0,
            },
            deviceId: 'd1',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
          ChangeDto(
            serverSeq: '6',
            changeLogId: '6',
            entityType: SyncEntityType.courseContent,
            entityId: 'cc-2',
            mutationType: 'INSERT',
            payload: {
              'id': 'cc-2',
              'classroom_subject_id': 'cs-assoc',
              'title': 'Climatologia',
              'order_index': 1,
            },
            deviceId: 'd1',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        ]);

        // INSERT de content_prerequisite (composta)
        await stagingHandler.applyChange(
          ChangeDto(
            serverSeq: '7',
            changeLogId: '7',
            entityType: SyncEntityType.contentPrerequisite,
            entityId: 'cc-2:cc-1',
            mutationType: 'INSERT',
            payload: {'content_id': 'cc-2', 'prerequisite_content_id': 'cc-1'},
            deviceId: 'd1',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );

        var prereqs =
            await (db.select(db.contentPrerequisitesTable)..where(
                  (tbl) =>
                      tbl.contentId.equals('cc-2') &
                      tbl.prerequisiteContentId.equals('cc-1'),
                ))
                .get();
        expect(prereqs.length, equals(1));

        // DELETE de content_prerequisite por entityId composto
        await stagingHandler.applyChange(
          ChangeDto(
            serverSeq: '8',
            changeLogId: '8',
            entityType: SyncEntityType.contentPrerequisite,
            entityId: 'cc-2:cc-1',
            mutationType: 'DELETE',
            payload: null,
            deviceId: 'd1',
            createdAt: DateTime.utc(2026, 1, 2),
          ),
        );

        prereqs =
            await (db.select(db.contentPrerequisitesTable)..where(
                  (tbl) =>
                      tbl.contentId.equals('cc-2') &
                      tbl.prerequisiteContentId.equals('cc-1'),
                ))
                .get();
        expect(prereqs, isEmpty);
      });
    },
  );

  group('SyncStagingHandler — Preservação de Histórico Docente', () {
    test(
      'rejeita exclusão remota de aula planejada que possui registro fático',
      () async {
        // Monta cenário com aula e registro de execução realizado
        await stagingHandler.applyChanges([
          ChangeDto(
            serverSeq: '1',
            changeLogId: '1',
            entityType: SyncEntityType.academicYear,
            entityId: 'ay-hist',
            mutationType: 'INSERT',
            payload: {
              'id': 'ay-hist',
              'year': 2026,
              'title': '2026',
              'start_date': '2026-02-01',
              'end_date': '2026-12-01',
            },
            deviceId: 'd1',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
          ChangeDto(
            serverSeq: '2',
            changeLogId: '2',
            entityType: SyncEntityType.classroom,
            entityId: 'c-hist',
            mutationType: 'INSERT',
            payload: {
              'id': 'c-hist',
              'academic_year_id': 'ay-hist',
              'name': '9B',
              'grade_level': '9',
              'shift': 'morning',
            },
            deviceId: 'd1',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
          ChangeDto(
            serverSeq: '3',
            changeLogId: '3',
            entityType: SyncEntityType.subject,
            entityId: 'sub-hist',
            mutationType: 'INSERT',
            payload: {
              'id': 'sub-hist',
              'name': 'Química',
              'color_hex': '#9C27B0',
            },
            deviceId: 'd1',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
          ChangeDto(
            serverSeq: '4',
            changeLogId: '4',
            entityType: SyncEntityType.classroomSubject,
            entityId: 'cs-hist',
            mutationType: 'INSERT',
            payload: {
              'id': 'cs-hist',
              'classroom_id': 'c-hist',
              'subject_id': 'sub-hist',
              'weekly_lessons': 2,
            },
            deviceId: 'd1',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
          ChangeDto(
            serverSeq: '5',
            changeLogId: '5',
            entityType: SyncEntityType.plannedLesson,
            entityId: 'pl-hist-1',
            mutationType: 'INSERT',
            payload: {
              'id': 'pl-hist-1',
              'classroom_subject_id': 'cs-hist',
              'lesson_date': '2026-03-10',
              'order_in_day': 1,
              'status': 'completed',
            },
            deviceId: 'd1',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
          ChangeDto(
            serverSeq: '6',
            changeLogId: '6',
            entityType: SyncEntityType.lessonExecutionRecord,
            entityId: 'rec-hist-1',
            mutationType: 'INSERT',
            payload: {
              'id': 'rec-hist-1',
              'planned_lesson_id': 'pl-hist-1',
              'classroom_subject_id': 'cs-hist',
              'execution_date': '2026-03-10',
              'status': 'completed',
              'pedagogical_notes': 'Experimento de cinética química.',
              'recorded_at': '2026-03-10T11:00:00.000Z',
            },
            deviceId: 'd1',
            createdAt: DateTime.utc(2026, 3, 10),
          ),
        ]);

        // Tentativa de DELETE da PlannedLesson com execução vinculada
        final deleteLessonChange = ChangeDto(
          serverSeq: '7',
          changeLogId: '7',
          entityType: SyncEntityType.plannedLesson,
          entityId: 'pl-hist-1',
          mutationType: 'DELETE',
          payload: null,
          deviceId: 'd2',
          createdAt: DateTime.utc(2026, 3, 11),
        );

        expect(
          () => stagingHandler.applyChange(deleteLessonChange),
          throwsA(isA<LessonExecutionProtectedException>()),
        );

        // Tentativa de DELETE do LessonExecutionRecord
        final deleteRecordChange = ChangeDto(
          serverSeq: '8',
          changeLogId: '8',
          entityType: SyncEntityType.lessonExecutionRecord,
          entityId: 'rec-hist-1',
          mutationType: 'DELETE',
          payload: null,
          deviceId: 'd2',
          createdAt: DateTime.utc(2026, 3, 11),
        );

        expect(
          () => stagingHandler.applyChange(deleteRecordChange),
          throwsA(isA<LessonExecutionProtectedException>()),
        );

        // Confirma que tanto a aula quanto o registro permanecem intactos
        final lesson = await (db.select(
          db.plannedLessonsTable,
        )..where((tbl) => tbl.id.equals('pl-hist-1'))).getSingleOrNull();
        final record = await (db.select(
          db.lessonExecutionRecordsTable,
        )..where((tbl) => tbl.id.equals('rec-hist-1'))).getSingleOrNull();

        expect(lesson, isNotNull);
        expect(record, isNotNull);
      },
    );
  });

  group('SyncStagingHandler — Ingestão de Snapshot e Rollback Atômico', () {
    test(
      'ingere snapshot completo das 13 coleções em ordem topológica',
      () async {
        final snapshot = SnapshotEntitiesDto(
          academicYears: [
            {
              'id': 'ay-snap',
              'year': 2026,
              'title': '2026 Snapshot',
              'start_date': '2026-02-01',
              'end_date': '2026-12-15',
              'total_mandatory_days': 200,
            },
          ],
          subjects: [
            {'id': 'sub-snap', 'name': 'Biologia', 'color_hex': '#4CAF50'},
          ],
          classrooms: [
            {
              'id': 'c-snap',
              'academic_year_id': 'ay-snap',
              'name': '1A',
              'grade_level': '1EM',
              'shift': 'morning',
            },
          ],
          classroomSubjects: [
            {
              'id': 'cs-snap',
              'classroom_id': 'c-snap',
              'subject_id': 'sub-snap',
              'weekly_lessons': 2,
            },
          ],
          schoolCalendarEvents: [
            {
              'id': 'ev-snap',
              'academic_year_id': 'ay-snap',
              'title': 'Carnaval',
              'start_date': '2026-02-16',
              'end_date': '2026-02-18',
              'type': 'holiday',
              'affects_classes': true,
            },
          ],
          scheduleSlots: [
            {
              'id': 'sl-snap',
              'classroom_subject_id': 'cs-snap',
              'weekday': 2,
              'order_index': 1,
              'start_time': '07:30',
              'end_time': '08:20',
            },
          ],
          curriculumCompetencies: [
            {
              'id': 'comp-snap',
              'code': 'EM13CNT201',
              'description': 'Analisar transformações químicas',
              'thematic_unit': 'Matéria e Energia',
              'stage': 'Ensino Médio',
              'grade_level': '1EM',
              'subject_name': 'Biologia',
              'source_name': 'BNCC',
              'source_version': '1.0',
            },
          ],
          courseContents: [
            {
              'id': 'cc-snap-1',
              'classroom_subject_id': 'cs-snap',
              'title': 'Citologia',
              'order_index': 0,
              'curriculum_competency_id': 'comp-snap',
              'is_mandatory': true,
            },
            {
              'id': 'cc-snap-2',
              'classroom_subject_id': 'cs-snap',
              'title': 'Genética',
              'order_index': 1,
              'is_mandatory': true,
            },
          ],
          contentPrerequisites: [
            {'content_id': 'cc-snap-2', 'prerequisite_content_id': 'cc-snap-1'},
          ],
          plannedLessons: [
            {
              'id': 'pl-snap-1',
              'classroom_subject_id': 'cs-snap',
              'lesson_date': '2026-03-03',
              'order_in_day': 1,
              'status': 'completed',
            },
          ],
          lessonContentAllocations: [
            {
              'lesson_id': 'pl-snap-1',
              'content_id': 'cc-snap-1',
              'order_index': 1,
            },
          ],
          lessonExecutionRecords: [
            {
              'id': 'rec-snap-1',
              'planned_lesson_id': 'pl-snap-1',
              'classroom_subject_id': 'cs-snap',
              'execution_date': '2026-03-03',
              'status': 'completed',
              'pedagogical_notes': 'Aula prática em laboratório.',
              'recorded_at': '2026-03-03T10:00:00.000Z',
            },
          ],
          executionContentAllocations: [
            {
              'record_id': 'rec-snap-1',
              'content_id': 'cc-snap-1',
              'order_index': 1,
            },
          ],
        );

        await stagingHandler.applySnapshot(snapshot);

        // Valida que cada entidade das 13 coleções foi persistida
        expect(
          (await db.select(db.academicYearsTable).get()).length,
          equals(1),
        );
        expect((await db.select(db.subjectsTable).get()).length, equals(1));
        expect((await db.select(db.classroomsTable).get()).length, equals(1));
        expect(
          (await db.select(db.classroomSubjectsTable).get()).length,
          equals(1),
        );
        expect(
          (await db.select(db.schoolCalendarEventsTable).get()).length,
          equals(1),
        );
        expect(
          (await db.select(db.scheduleSlotsTable).get()).length,
          equals(1),
        );
        expect(
          (await db.select(db.curriculumCompetenciesTable).get()).length,
          equals(1),
        );
        expect(
          (await db.select(db.courseContentsTable).get()).length,
          equals(2),
        );
        expect(
          (await db.select(db.contentPrerequisitesTable).get()).length,
          equals(1),
        );
        expect(
          (await db.select(db.plannedLessonsTable).get()).length,
          equals(1),
        );
        expect(
          (await db.select(db.lessonContentAllocationsTable).get()).length,
          equals(1),
        );
        expect(
          (await db.select(db.lessonExecutionRecordsTable).get()).length,
          equals(1),
        );
        expect(
          (await db.select(db.executionContentAllocationsTable).get()).length,
          equals(1),
        );

        // A outbox deve permanecer 100% vazia
        expect(await outboxRepo.getAllOperations(), isEmpty);
      },
    );

    test('falha durante snapshot dispara rollback integral sem deixar dados parciais', () async {
      final corruptSnapshot = SnapshotEntitiesDto(
        academicYears: [
          {
            'id': 'ay-valid',
            'year': 2026,
            'title': 'Ano Válido',
            'start_date': '2026-02-01',
            'end_date': '2026-12-01',
          },
        ],
        subjects: [
          {
            // Campo id obrigatório ausente para forçar erro em tempo de execução
            'name': 'Física sem ID',
          },
        ],
      );

      expect(
        () => stagingHandler.applySnapshot(corruptSnapshot),
        throwsA(isA<FormatException>()),
      );

      // Garante que o Ano Letivo anterior NÃO permaneceu gravado (rollback atômico)
      final years = await db.select(db.academicYearsTable).get();
      expect(years, isEmpty);

      final subjects = await db.select(db.subjectsTable).get();
      expect(subjects, isEmpty);
    });
  });

  group('SyncStagingHandler — Tratamento de Erros e Payloads Inválidos', () {
    test('payload nulo ou vazio em INSERT gera FormatException', () async {
      final invalidChange = ChangeDto(
        serverSeq: '1',
        changeLogId: '1',
        entityType: SyncEntityType.subject,
        entityId: 'sub-err',
        mutationType: 'INSERT',
        payload: null,
        deviceId: 'd1',
        createdAt: DateTime.utc(2026, 1, 1),
      );

      expect(
        () => stagingHandler.applyChange(invalidChange),
        throwsA(isA<FormatException>()),
      );
    });

    test('entidade com tipo desconhecido gera UnsupportedError', () async {
      final unknownChange = ChangeDto(
        serverSeq: '1',
        changeLogId: '1',
        entityType: 'unknown_entity_type',
        entityId: 'id-err',
        mutationType: 'INSERT',
        payload: {'id': 'id-err'},
        deviceId: 'd1',
        createdAt: DateTime.utc(2026, 1, 1),
      );

      expect(
        () => stagingHandler.applyChange(unknownChange),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test(
      'data inválida gera FormatException com diagnóstico descritivo',
      () async {
        final invalidDateChange = ChangeDto(
          serverSeq: '1',
          changeLogId: '1',
          entityType: SyncEntityType.academicYear,
          entityId: 'ay-bad-date',
          mutationType: 'INSERT',
          payload: {
            'id': 'ay-bad-date',
            'year': 2026,
            'title': 'Ano Data Inválida',
            'start_date': 'DATA_CORROMPIDA_123',
            'end_date': '2026-12-01',
          },
          deviceId: 'd1',
          createdAt: DateTime.utc(2026, 1, 1),
        );

        expect(
          () => stagingHandler.applyChange(invalidDateChange),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Formato de data inválido'),
            ),
          ),
        );
      },
    );
  });
}
