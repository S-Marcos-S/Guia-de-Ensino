import 'dart:convert';

import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/models/classroom.dart';
import 'package:app/domain/models/course_content.dart';
import 'package:app/domain/models/lesson_execution_record.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/models/schedule_slot.dart';
import 'package:app/domain/models/school_calendar_event.dart';
import 'package:app/domain/models/subject.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/persistence/repositories/drift_academic_year_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_calendar_event_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_classroom_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_course_content_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_lesson_execution_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_planned_lesson_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_schedule_slot_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_subject_repository.dart';
import 'package:app/infrastructure/sync/models/sync_entity_type.dart';
import 'package:app/infrastructure/sync/outbox/sync_outbox_item.dart';
import 'package:app/infrastructure/sync/outbox/sync_outbox_repository.dart';
import 'package:app/infrastructure/sync/outbox/sync_payload_serializer.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SyncOutboxRepository outboxRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    outboxRepo = SyncOutboxRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncOutboxItem e Modelos de Outbox', () {
    test('valida estados permitidos do SyncOutboxStatus', () {
      expect(SyncOutboxStatus.isValid('pending'), isTrue);
      expect(SyncOutboxStatus.isValid('sending'), isTrue);
      expect(SyncOutboxStatus.isValid('failed'), isTrue);
      expect(SyncOutboxStatus.isValid('unknown'), isFalse);
    });

    test('SyncOutboxItem converte corretamente para SyncOperationDto', () {
      final now = DateTime.utc(2026, 3, 1, 10, 0, 0);
      final item = SyncOutboxItem(
        operationId: 'op-123',
        entityType: SyncEntityType.academicYear,
        entityId: 'ay-2026',
        operation: SyncMutationType.insert,
        payloadJson: jsonEncode({'id': 'ay-2026', 'year': 2026}),
        localRevision: 1,
        status: SyncOutboxStatus.pending,
        createdAt: now,
      );

      final dto = item.toDto();
      expect(dto.clientOpId, equals('op-123'));
      expect(dto.entityType, equals('academic_year'));
      expect(dto.entityId, equals('ay-2026'));
      expect(dto.mutationType, equals('INSERT'));
      expect(dto.payload, isNotNull);
      expect(dto.payload!['year'], equals(2026));
      expect(dto.clientCreatedAt, equals(now));
    });

    test('SyncOutboxItem payloadMap lida com json nulo ou vazio', () {
      final item = SyncOutboxItem(
        operationId: 'op-del',
        entityType: SyncEntityType.academicYear,
        entityId: 'ay-2026',
        operation: SyncMutationType.delete,
        payloadJson: null,
        localRevision: 2,
        createdAt: DateTime.utc(2026, 3, 1),
      );

      expect(item.payloadMap, isNull);
      final dto = item.toDto();
      expect(dto.payload, isNull);
    });

    test('SyncTombstoneItem igualdade e hashCode', () {
      final now = DateTime.utc(2026, 3, 1);
      final t1 = SyncTombstoneItem(
        id: 't-1',
        entityType: SyncEntityType.subject,
        entityId: 'sub-1',
        operationId: 'op-1',
        deletedAt: now,
        localRevision: 5,
        synced: false,
      );
      final t2 = SyncTombstoneItem(
        id: 't-1',
        entityType: SyncEntityType.subject,
        entityId: 'sub-1',
        operationId: 'op-1',
        deletedAt: now,
        localRevision: 5,
        synced: false,
      );

      expect(t1, equals(t2));
      expect(t1.hashCode, equals(t2.hashCode));
    });
  });

  group('SyncPayloadSerializer', () {
    test('formata datas e horas corretamente', () {
      final date = DateTime.utc(2026, 2, 5, 8, 30);
      expect(SyncPayloadSerializer.formatDate(date), equals('2026-02-05'));
      expect(
        SyncPayloadSerializer.formatDateTime(date),
        equals('2026-02-05T08:30:00.000Z'),
      );
    });

    test('serializa AcademicYear com snake_case e datas', () {
      final ay = AcademicYear(
        id: 'ay-2026',
        year: 2026,
        title: 'Ano 2026',
        startDate: DateTime.utc(2026, 2, 1),
        endDate: DateTime.utc(2026, 12, 15),
        totalMandatoryDays: 200,
      );
      final payload = SyncPayloadSerializer.academicYear(ay);
      expect(payload['id'], equals('ay-2026'));
      expect(payload['year'], equals(2026));
      expect(payload['start_date'], equals('2026-02-01'));
      expect(payload['end_date'], equals('2026-12-15'));
      expect(payload['total_mandatory_days'], equals(200));
    });

    test('serializa Classroom e ClassroomSubjectConfig', () {
      const c = Classroom(
        id: 'c-1',
        academicYearId: 'ay-2026',
        name: 'Turma 6A',
        gradeLevel: '6',
        shift: ClassroomShift.morning,
        subjectConfigs: <ClassroomSubjectConfig>[],
      );
      final payload = SyncPayloadSerializer.classroom(c);
      expect(payload['grade_level'], equals('6'));
      expect(payload['shift'], equals('morning'));

      const cfg = ClassroomSubjectConfig(
        id: 'cs-1',
        classroomId: 'c-1',
        subjectId: 's-1',
        weeklyLessons: 4,
      );
      final cfgPayload = SyncPayloadSerializer.classroomSubject(
        cfg,
        classroomId: 'c-1',
      );
      expect(cfgPayload['classroom_id'], equals('c-1'));
      expect(cfgPayload['subject_id'], equals('s-1'));
      expect(cfgPayload['weekly_lessons'], equals(4));
    });

    test('serializa associativas com campos canônicos', () {
      final prereq = SyncPayloadSerializer.contentPrerequisite(
        contentId: 'c-2',
        prerequisiteContentId: 'c-1',
      );
      expect(prereq['content_id'], equals('c-2'));
      expect(prereq['prerequisite_content_id'], equals('c-1'));

      final alloc = SyncPayloadSerializer.lessonContentAllocation(
        lessonId: 'l-1',
        contentId: 'c-1',
        orderIndex: 1,
      );
      expect(alloc['lesson_id'], equals('l-1'));
      expect(alloc['order_index'], equals(1));
    });
  });

  group('SyncOutboxRepository — Métodos Fundamentais', () {
    test('getOrCreateSyncState inicializa registro único padrão', () async {
      final state = await outboxRepo.getOrCreateSyncState(
        deviceId: 'dev-test-123',
      );
      expect(state.id, equals('default'));
      expect(state.deviceId, equals('dev-test-123'));
      expect(state.localRevision, equals(0));
      expect(state.accountEpoch, equals(1));
      expect(state.lastSyncStatus, equals('idle'));
      expect(state.serverCursor, isNull);

      final sameState = await outboxRepo.getOrCreateSyncState();
      expect(sameState.deviceId, equals('dev-test-123'));
    });

    test('getNextLocalRevision incrementa monotonicamente', () async {
      final rev1 = await outboxRepo.getNextLocalRevision();
      final rev2 = await outboxRepo.getNextLocalRevision();
      final rev3 = await outboxRepo.getNextLocalRevision();

      expect(rev1, equals(1));
      expect(rev2, equals(2));
      expect(rev3, equals(3));

      final current = await outboxRepo.getCurrentLocalRevision();
      expect(current, equals(3));
    });

    test('enqueueOperation grava registro pending com payload', () async {
      final item = await outboxRepo.enqueueOperation(
        entityType: SyncEntityType.subject,
        entityId: 'sub-mat',
        operation: SyncMutationType.insert,
        payload: {'id': 'sub-mat', 'name': 'Matemática'},
      );

      expect(item.entityType, equals('subject'));
      expect(item.entityId, equals('sub-mat'));
      expect(item.operation, equals('INSERT'));
      expect(item.status, equals(SyncOutboxStatus.pending));
      expect(item.localRevision, equals(1));
      expect(item.payloadMap!['name'], equals('Matemática'));

      final pending = await outboxRepo.getPendingOperations();
      expect(pending.length, equals(1));
      expect(pending.first.operationId, equals(item.operationId));
    });

    test('enqueueDelete registra exclusão na outbox e tombstone', () async {
      final op = await outboxRepo.enqueueDelete(
        entityType: SyncEntityType.subject,
        entityId: 'sub-mat',
      );

      expect(op.operation, equals(SyncMutationType.delete));
      expect(op.payloadJson, isNull);

      final tombstones = await outboxRepo.getTombstones();
      expect(tombstones.length, equals(1));
      expect(tombstones.first.entityType, equals('subject'));
      expect(tombstones.first.entityId, equals('sub-mat'));
      expect(tombstones.first.operationId, equals(op.operationId));
      expect(tombstones.first.synced, isFalse);

      await outboxRepo.markTombstonesSynced([tombstones.first.id]);
      final unsynced = await outboxRepo.getTombstones(synced: false);
      expect(unsynced, isEmpty);
      final synced = await outboxRepo.getTombstones(synced: true);
      expect(synced.length, equals(1));
    });

    test(
      'getPendingOperations retorna itens em ordem FIFO de revisão',
      () async {
        await outboxRepo.enqueueOperation(
          entityType: SyncEntityType.subject,
          entityId: 'sub-1',
          operation: SyncMutationType.insert,
        );
        await outboxRepo.enqueueOperation(
          entityType: SyncEntityType.subject,
          entityId: 'sub-2',
          operation: SyncMutationType.insert,
        );
        await outboxRepo.enqueueOperation(
          entityType: SyncEntityType.subject,
          entityId: 'sub-3',
          operation: SyncMutationType.insert,
        );

        final pending = await outboxRepo.getPendingOperations();
        expect(pending.length, equals(3));
        expect(pending[0].entityId, equals('sub-1'));
        expect(pending[0].localRevision, equals(1));
        expect(pending[1].entityId, equals('sub-2'));
        expect(pending[1].localRevision, equals(2));
        expect(pending[2].entityId, equals('sub-3'));
        expect(pending[2].localRevision, equals(3));
      },
    );

    test('updateStatus e removeOperations gerenciam ciclo de vida', () async {
      final op1 = await outboxRepo.enqueueOperation(
        entityType: SyncEntityType.subject,
        entityId: 'sub-1',
        operation: SyncMutationType.insert,
      );
      final op2 = await outboxRepo.enqueueOperation(
        entityType: SyncEntityType.subject,
        entityId: 'sub-2',
        operation: SyncMutationType.insert,
      );

      await outboxRepo.updateStatus([
        op1.operationId,
      ], SyncOutboxStatus.sending);
      var pending = await outboxRepo.getPendingOperations();
      expect(pending.length, equals(1));
      expect(pending.first.operationId, equals(op2.operationId));

      await outboxRepo.removeOperations([op1.operationId]);
      final all = await outboxRepo.getAllOperations();
      expect(all.length, equals(1));
      expect(all.first.operationId, equals(op2.operationId));
    });

    test(
      'resetSendingToPending reverte operações travadas em sending',
      () async {
        final op = await outboxRepo.enqueueOperation(
          entityType: SyncEntityType.subject,
          entityId: 'sub-crash',
          operation: SyncMutationType.insert,
        );

        await outboxRepo.updateStatus([
          op.operationId,
        ], SyncOutboxStatus.sending);
        expect(await outboxRepo.getPendingOperations(), isEmpty);

        final resetCount = await outboxRepo.resetSendingToPending();
        expect(resetCount, equals(1));

        final pending = await outboxRepo.getPendingOperations();
        expect(pending.length, equals(1));
        expect(pending.first.operationId, equals(op.operationId));
      },
    );

    test('updateSyncSuccess e updateSyncFailure atualizam metadados', () async {
      await outboxRepo.getOrCreateSyncState();

      await outboxRepo.updateSyncSuccess(serverCursor: 'cur-100');
      var state = await outboxRepo.getOrCreateSyncState();
      expect(state.serverCursor, equals('cur-100'));
      expect(state.lastSyncStatus, equals('idle'));
      expect(state.lastSyncError, isNull);
      expect(state.lastSyncedAt, isNotNull);

      await outboxRepo.updateSyncFailure('Network timeout');
      state = await outboxRepo.getOrCreateSyncState();
      expect(state.lastSyncStatus, equals('error'));
      expect(state.lastSyncError, equals('Network timeout'));
      expect(state.serverCursor, equals('cur-100'));
    });
  });

  group('Repositórios Transacionais — Atomicidade e Enfileiramento', () {
    test('DriftAcademicYearRepository enfileira INSERT e UPDATE', () async {
      final repo = DriftAcademicYearRepository(db, outboxRepo);
      final ay = AcademicYear(
        id: 'ay-trans-1',
        year: 2026,
        title: 'Ano 2026',
        startDate: DateTime.utc(2026, 2, 1),
        endDate: DateTime.utc(2026, 12, 15),
        totalMandatoryDays: 200,
      );

      // INSERT
      await repo.save(ay);
      var pending = await outboxRepo.getPendingOperations();
      expect(pending.length, equals(1));
      expect(pending.first.entityType, equals('academic_year'));
      expect(pending.first.operation, equals('INSERT'));
      expect(pending.first.payloadMap!['year'], equals(2026));

      // UPDATE
      final updatedAy = AcademicYear(
        id: 'ay-trans-1',
        year: 2026,
        title: 'Ano 2026 Atualizado',
        startDate: DateTime.utc(2026, 2, 1),
        endDate: DateTime.utc(2026, 12, 15),
        totalMandatoryDays: 201,
      );
      await repo.save(updatedAy);
      pending = await outboxRepo.getPendingOperations();
      expect(pending.length, equals(2));
      expect(pending.last.operation, equals('UPDATE'));
      expect(pending.last.payloadMap!['title'], equals('Ano 2026 Atualizado'));

      // DELETE
      await repo.delete('ay-trans-1');
      pending = await outboxRepo.getPendingOperations();
      expect(pending.length, equals(3));
      expect(pending.last.operation, equals('DELETE'));

      final tombstones = await outboxRepo.getTombstones();
      expect(tombstones.length, equals(1));
      expect(tombstones.first.entityId, equals('ay-trans-1'));
    });

    test(
      'DriftSubjectRepository enfileira mutações e DELETE gera tombstone',
      () async {
        final repo = DriftSubjectRepository(db, outboxRepo);
        const sub = Subject(
          id: 'sub-hist',
          name: 'História',
          colorHex: '#E91E63',
        );

        await repo.save(sub);
        var pending = await outboxRepo.getPendingOperations();
        expect(pending.length, equals(1));
        expect(pending.first.entityType, equals('subject'));
        expect(pending.first.operation, equals('INSERT'));

        await repo.delete('sub-hist');
        pending = await outboxRepo.getPendingOperations();
        expect(pending.length, equals(2));
        expect(pending.last.operation, equals('DELETE'));

        final tombstones = await outboxRepo.getTombstones();
        expect(tombstones.length, equals(1));
        expect(tombstones.first.entityId, equals('sub-hist'));
      },
    );

    test('DriftClassroomRepository sincroniza classroom e classroom_subject atomicamente', () async {
      final ayRepo = DriftAcademicYearRepository(db, outboxRepo);
      final subRepo = DriftSubjectRepository(db, outboxRepo);
      final repo = DriftClassroomRepository(db, outboxRepo);

      await ayRepo.save(
        AcademicYear(
          id: 'ay-1',
          year: 2026,
          title: '2026',
          startDate: DateTime.utc(2026, 2, 1),
          endDate: DateTime.utc(2026, 12, 1),
          totalMandatoryDays: 200,
        ),
      );
      await subRepo.save(
        const Subject(id: 'sub-1', name: 'Matemática', colorHex: '#123456'),
      );
      await subRepo.save(
        const Subject(id: 'sub-2', name: 'Português', colorHex: '#654321'),
      );

      // Limpa outbox para isolar testes da turma
      await outboxRepo.removeOperations(
        (await outboxRepo.getAllOperations())
            .map((SyncOutboxItem o) => o.operationId)
            .toList(),
      );

      const classroom = Classroom(
        id: 'c-101',
        academicYearId: 'ay-1',
        name: 'Turma 7B',
        gradeLevel: '7',
        shift: ClassroomShift.afternoon,
        subjectConfigs: [
          ClassroomSubjectConfig(
            id: 'cs-101',
            classroomId: 'c-101',
            subjectId: 'sub-1',
            weeklyLessons: 4,
          ),
          ClassroomSubjectConfig(
            id: 'cs-102',
            classroomId: 'c-101',
            subjectId: 'sub-2',
            weeklyLessons: 5,
          ),
        ],
      );

      await repo.save(classroom);
      var pending = await outboxRepo.getPendingOperations();
      // 1 classroom INSERT + 2 classroom_subject INSERT = 3 operações
      expect(pending.length, equals(3));
      expect(pending[0].entityType, equals('classroom'));
      expect(pending[1].entityType, equals('classroom_subject'));
      expect(pending[2].entityType, equals('classroom_subject'));

      // Atualiza removendo cs-102
      const updatedClassroom = Classroom(
        id: 'c-101',
        academicYearId: 'ay-1',
        name: 'Turma 7B',
        gradeLevel: '7',
        shift: ClassroomShift.afternoon,
        subjectConfigs: [
          ClassroomSubjectConfig(
            id: 'cs-101',
            classroomId: 'c-101',
            subjectId: 'sub-1',
            weeklyLessons: 4,
          ),
        ],
      );
      await repo.save(updatedClassroom);
      pending = await outboxRepo.getPendingOperations();
      // Anteriores 3 + (1 classroom UPDATE + 1 cs-102 DELETE + 1 cs-101 UPDATE) = 6 operações
      expect(pending.length, equals(6));
      expect(pending[3].operation, equals('UPDATE'));
      expect(pending[4].operation, equals('DELETE'));
      expect(pending[4].entityId, equals('cs-102'));
    });

    test('DriftCalendarEventRepository enfileira eventos escolares', () async {
      final ayRepo = DriftAcademicYearRepository(db, outboxRepo);
      final repo = DriftCalendarEventRepository(db, outboxRepo);

      await ayRepo.save(
        AcademicYear(
          id: 'ay-cal',
          year: 2026,
          title: '2026',
          startDate: DateTime.utc(2026, 2, 1),
          endDate: DateTime.utc(2026, 12, 1),
          totalMandatoryDays: 200,
        ),
      );

      final event = SchoolCalendarEvent(
        id: 'ev-1',
        academicYearId: 'ay-cal',
        title: 'Feriado Tiradentes',
        startDate: DateTime.utc(2026, 4, 21),
        endDate: DateTime.utc(2026, 4, 21),
        type: SchoolEventType.holiday,
        affectsClasses: true,
      );

      await repo.save(event);
      final pending = await outboxRepo.getPendingOperations();
      final evOp = pending.firstWhere(
        (SyncOutboxItem p) => p.entityType == 'school_calendar_event',
      );
      expect(evOp.operation, equals('INSERT'));
      expect(evOp.payloadMap!['title'], equals('Feriado Tiradentes'));

      await repo.delete('ev-1');
      final all = await outboxRepo.getAllOperations();
      expect(all.last.operation, equals('DELETE'));
      expect(all.last.entityType, equals('school_calendar_event'));
    });

    test('DriftScheduleSlotRepository enfileira substituição de slots com tombstones', () async {
      final ayRepo = DriftAcademicYearRepository(db, outboxRepo);
      final subRepo = DriftSubjectRepository(db, outboxRepo);
      final classroomRepo = DriftClassroomRepository(db, outboxRepo);
      final repo = DriftScheduleSlotRepository(db, outboxRepo);

      await ayRepo.save(
        AcademicYear(
          id: 'ay-slot',
          year: 2026,
          title: '2026',
          startDate: DateTime.utc(2026, 2, 1),
          endDate: DateTime.utc(2026, 12, 1),
          totalMandatoryDays: 200,
        ),
      );
      await subRepo.save(
        const Subject(id: 'sub-slot', name: 'Arte', colorHex: '#FF5722'),
      );
      await classroomRepo.save(
        const Classroom(
          id: 'c-slot',
          academicYearId: 'ay-slot',
          name: '6B',
          gradeLevel: '6',
          shift: ClassroomShift.morning,
          subjectConfigs: [
            ClassroomSubjectConfig(
              id: 'cs-slot',
              classroomId: 'c-slot',
              subjectId: 'sub-slot',
              weeklyLessons: 2,
            ),
          ],
        ),
      );

      await outboxRepo.removeOperations(
        (await outboxRepo.getAllOperations())
            .map((SyncOutboxItem o) => o.operationId)
            .toList(),
      );

      const slot1 = ScheduleSlot(
        id: 'sl-1',
        classroomSubjectId: 'cs-slot',
        weekday: 2,
        orderIndex: 1,
      );
      const slot2 = ScheduleSlot(
        id: 'sl-2',
        classroomSubjectId: 'cs-slot',
        weekday: 4,
        orderIndex: 2,
      );
      await repo.saveSlots('cs-slot', [slot1, slot2]);

      var pending = await outboxRepo.getPendingOperations();
      expect(pending.length, equals(2));
      expect(pending[0].entityType, equals('schedule_slot'));
      expect(pending[1].entityType, equals('schedule_slot'));

      // Substitui por slot1 e slot3 (removendo slot2)
      const slot3 = ScheduleSlot(
        id: 'sl-3',
        classroomSubjectId: 'cs-slot',
        weekday: 5,
        orderIndex: 1,
      );
      await repo.saveSlots('cs-slot', [slot1, slot3]);

      pending = await outboxRepo.getPendingOperations();
      // Anteriores 2 + (1 DELETE sl-2 + 1 UPDATE sl-1 + 1 INSERT sl-3) = 5
      expect(pending.length, equals(5));
      expect(pending[2].operation, equals('DELETE'));
      expect(pending[2].entityId, equals('sl-2'));
      expect(pending[3].operation, equals('UPDATE'));
      expect(pending[3].entityId, equals('sl-1'));
      expect(pending[4].operation, equals('INSERT'));
      expect(pending[4].entityId, equals('sl-3'));
    });

    test(
      'DriftCourseContentRepository enfileira conteúdos e pré-requisitos',
      () async {
        final ayRepo = DriftAcademicYearRepository(db, outboxRepo);
        final subRepo = DriftSubjectRepository(db, outboxRepo);
        final classroomRepo = DriftClassroomRepository(db, outboxRepo);
        final repo = DriftCourseContentRepository(db, outboxRepo);

        await ayRepo.save(
          AcademicYear(
            id: 'ay-cc',
            year: 2026,
            title: '2026',
            startDate: DateTime.utc(2026, 2, 1),
            endDate: DateTime.utc(2026, 12, 1),
            totalMandatoryDays: 200,
          ),
        );
        await subRepo.save(
          const Subject(id: 'sub-cc', name: 'Ciências', colorHex: '#4CAF50'),
        );
        await classroomRepo.save(
          const Classroom(
            id: 'c-cc',
            academicYearId: 'ay-cc',
            name: '8A',
            gradeLevel: '8',
            shift: ClassroomShift.morning,
            subjectConfigs: [
              ClassroomSubjectConfig(
                id: 'cs-cc',
                classroomId: 'c-cc',
                subjectId: 'sub-cc',
                weeklyLessons: 3,
              ),
            ],
          ),
        );

        await outboxRepo.removeOperations(
          (await outboxRepo.getAllOperations())
              .map((SyncOutboxItem o) => o.operationId)
              .toList(),
        );

        const c1 = CourseContent(
          id: 'cc-1',
          classroomSubjectId: 'cs-cc',
          title: 'Célula Animal',
          orderIndex: 0,
          origin: ContentOrigin.manual,
          estimatedLessons: 2,
        );
        await repo.save(c1);

        const c2 = CourseContent(
          id: 'cc-2',
          classroomSubjectId: 'cs-cc',
          title: 'Divisão Celular',
          orderIndex: 1,
          origin: ContentOrigin.manual,
          estimatedLessons: 3,
          prerequisiteIds: ['cc-1'],
        );
        await repo.save(c2);

        var pending = await outboxRepo.getPendingOperations();
        // c1: 1 INSERT course_content
        // c2: 1 INSERT course_content + 1 INSERT content_prerequisite
        expect(pending.length, equals(3));
        expect(pending[0].entityType, equals('course_content'));
        expect(pending[1].entityType, equals('course_content'));
        expect(pending[2].entityType, equals('content_prerequisite'));
        expect(pending[2].entityId, equals('cc-2:cc-1'));

        // Reorder
        await repo.reorder('cs-cc', ['cc-2', 'cc-1']);
        pending = await outboxRepo.getPendingOperations();
        expect(pending.length, equals(5));
        expect(pending[3].operation, equals('UPDATE'));
        expect(pending[3].payloadMap!['order_index'], equals(0));
        expect(pending[4].operation, equals('UPDATE'));
        expect(pending[4].payloadMap!['order_index'], equals(1));
      },
    );

    test(
      'DriftPlannedLessonRepository enfileira aulas e alocações de conteúdo',
      () async {
        final ayRepo = DriftAcademicYearRepository(db, outboxRepo);
        final subRepo = DriftSubjectRepository(db, outboxRepo);
        final classroomRepo = DriftClassroomRepository(db, outboxRepo);
        final contentRepo = DriftCourseContentRepository(db, outboxRepo);
        final repo = DriftPlannedLessonRepository(db, outboxRepo);

        await ayRepo.save(
          AcademicYear(
            id: 'ay-pl',
            year: 2026,
            title: '2026',
            startDate: DateTime.utc(2026, 2, 1),
            endDate: DateTime.utc(2026, 12, 1),
            totalMandatoryDays: 200,
          ),
        );
        await subRepo.save(
          const Subject(id: 'sub-pl', name: 'Geografia', colorHex: '#795548'),
        );
        await classroomRepo.save(
          const Classroom(
            id: 'c-pl',
            academicYearId: 'ay-pl',
            name: '9A',
            gradeLevel: '9',
            shift: ClassroomShift.morning,
            subjectConfigs: [
              ClassroomSubjectConfig(
                id: 'cs-pl',
                classroomId: 'c-pl',
                subjectId: 'sub-pl',
                weeklyLessons: 2,
              ),
            ],
          ),
        );
        await contentRepo.save(
          const CourseContent(
            id: 'cnt-1',
            classroomSubjectId: 'cs-pl',
            title: 'Climas do Brasil',
            orderIndex: 0,
            origin: ContentOrigin.manual,
          ),
        );

        await outboxRepo.removeOperations(
          (await outboxRepo.getAllOperations())
              .map((SyncOutboxItem o) => o.operationId)
              .toList(),
        );

        final lesson = PlannedLesson(
          id: 'pl-10',
          classroomSubjectId: 'cs-pl',
          date: DateTime.utc(2026, 3, 10),
          orderInDay: 1,
          contentIds: const ['cnt-1'],
          status: LessonExecutionStatus.planned,
        );

        await repo.save(lesson);

        var pending = await outboxRepo.getPendingOperations();
        // 1 planned_lesson INSERT + 1 lesson_content_allocation INSERT
        expect(pending.length, equals(2));
        expect(pending[0].entityType, equals('planned_lesson'));
        expect(pending[1].entityType, equals('lesson_content_allocation'));
        expect(pending[1].entityId, equals('pl-10:cnt-1'));

        await repo.delete('pl-10');
        pending = await outboxRepo.getPendingOperations();
        // Anteriores 2 + (1 DELETE lesson_content_allocation + 1 DELETE planned_lesson) = 4
        expect(pending.length, equals(4));
        expect(pending[2].operation, equals('DELETE'));
        expect(pending[3].operation, equals('DELETE'));
        expect(pending[3].entityType, equals('planned_lesson'));
      },
    );

    test('DriftLessonExecutionRepository enfileira registro, alocações e status da aula planejada', () async {
      final ayRepo = DriftAcademicYearRepository(db, outboxRepo);
      final subRepo = DriftSubjectRepository(db, outboxRepo);
      final classroomRepo = DriftClassroomRepository(db, outboxRepo);
      final contentRepo = DriftCourseContentRepository(db, outboxRepo);
      final lessonRepo = DriftPlannedLessonRepository(db, outboxRepo);
      final repo = DriftLessonExecutionRepository(db, outboxRepo);

      await ayRepo.save(
        AcademicYear(
          id: 'ay-exec',
          year: 2026,
          title: '2026',
          startDate: DateTime.utc(2026, 2, 1),
          endDate: DateTime.utc(2026, 12, 1),
          totalMandatoryDays: 200,
        ),
      );
      await subRepo.save(
        const Subject(id: 'sub-exec', name: 'Física', colorHex: '#00BCD4'),
      );
      await classroomRepo.save(
        const Classroom(
          id: 'c-exec',
          academicYearId: 'ay-exec',
          name: '1EM',
          gradeLevel: '1EM',
          shift: ClassroomShift.morning,
          subjectConfigs: [
            ClassroomSubjectConfig(
              id: 'cs-exec',
              classroomId: 'c-exec',
              subjectId: 'sub-exec',
              weeklyLessons: 2,
            ),
          ],
        ),
      );
      await contentRepo.save(
        const CourseContent(
          id: 'cnt-exec-1',
          classroomSubjectId: 'cs-exec',
          title: 'Cinemática Escalar',
          orderIndex: 0,
          origin: ContentOrigin.manual,
        ),
      );
      await lessonRepo.save(
        PlannedLesson(
          id: 'pl-exec-1',
          classroomSubjectId: 'cs-exec',
          date: DateTime.utc(2026, 3, 12),
          orderInDay: 1,
          contentIds: const ['cnt-exec-1'],
          status: LessonExecutionStatus.planned,
        ),
      );

      await outboxRepo.removeOperations(
        (await outboxRepo.getAllOperations())
            .map((SyncOutboxItem o) => o.operationId)
            .toList(),
      );

      final record = LessonExecutionRecord(
        id: 'rec-1',
        plannedLessonId: 'pl-exec-1',
        classroomSubjectId: 'cs-exec',
        executionDate: DateTime.utc(2026, 3, 12),
        status: LessonExecutionStatus.completed,
        actualContentIds: const ['cnt-exec-1'],
        recordedAt: DateTime.utc(2026, 3, 12, 11, 0),
        pedagogicalNotes:
            'Aula ministrada com excelente participação dos alunos.',
      );

      await repo.save(record);

      final pending = await outboxRepo.getPendingOperations();
      // 1 INSERT lesson_execution_record
      // 1 INSERT execution_content_allocation
      // 1 UPDATE planned_lesson (para refletir o novo status completed)
      expect(pending.length, equals(3));
      expect(pending[0].entityType, equals('lesson_execution_record'));
      expect(pending[0].operation, equals('INSERT'));
      expect(pending[0].payloadMap!['status'], equals('completed'));

      expect(pending[1].entityType, equals('execution_content_allocation'));
      expect(pending[1].operation, equals('INSERT'));
      expect(pending[1].entityId, equals('rec-1:cnt-exec-1'));

      expect(pending[2].entityType, equals('planned_lesson'));
      expect(pending[2].operation, equals('UPDATE'));
      expect(pending[2].payloadMap!['status'], equals('completed'));
    });

    test('Rollback transacional: erro aborta persistência e enfileiramento na outbox', () async {
      final repo = DriftAcademicYearRepository(db, outboxRepo);

      try {
        await db.transaction(() async {
          await repo.save(
            AcademicYear(
              id: 'ay-rollback',
              year: 2030,
              title: 'Ano Rollback',
              startDate: DateTime.utc(2030, 2, 1),
              endDate: DateTime.utc(2030, 12, 1),
              totalMandatoryDays: 200,
            ),
          );
          // Força uma falha dentro da transação
          throw Exception('Simulação de falha catastrófica');
        });
      } catch (_) {
        // Exceção esperada
      }

      // Garante que o Ano Letivo NÃO foi persistido
      final foundYear = await repo.findById('ay-rollback');
      expect(foundYear, isNull);

      // Garante que a Outbox NÃO registrou nenhuma operação
      final allOutbox = await outboxRepo.getAllOperations();
      final hasRollbackItem = allOutbox.any(
        (SyncOutboxItem o) => o.entityId == 'ay-rollback',
      );
      expect(hasRollbackItem, isFalse);
    });
  });
}
