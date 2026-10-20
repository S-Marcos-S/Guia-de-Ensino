import 'package:app/infrastructure/sync/models/change_dto.dart';
import 'package:app/infrastructure/sync/models/operation_ack_dto.dart';
import 'package:app/infrastructure/sync/models/pull_query_dto.dart';
import 'package:app/infrastructure/sync/models/pull_response_dto.dart';
import 'package:app/infrastructure/sync/models/push_request_dto.dart';
import 'package:app/infrastructure/sync/models/push_response_dto.dart';
import 'package:app/infrastructure/sync/models/snapshot_response_dto.dart';
import 'package:app/infrastructure/sync/models/sync_entity_type.dart';
import 'package:app/infrastructure/sync/models/sync_operation_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncEntityType & SyncMutationType & SyncAckStatus', () {
    test('deve conter as 13 entidades canônicas do protocolo', () {
      expect(SyncEntityType.all.length, equals(13));
      expect(SyncEntityType.isValid('academic_year'), isTrue);
      expect(SyncEntityType.isValid('classroom'), isTrue);
      expect(SyncEntityType.isValid('subject'), isTrue);
      expect(SyncEntityType.isValid('classroom_subject'), isTrue);
      expect(SyncEntityType.isValid('school_calendar_event'), isTrue);
      expect(SyncEntityType.isValid('schedule_slot'), isTrue);
      expect(SyncEntityType.isValid('curriculum_competency'), isTrue);
      expect(SyncEntityType.isValid('course_content'), isTrue);
      expect(SyncEntityType.isValid('content_prerequisite'), isTrue);
      expect(SyncEntityType.isValid('planned_lesson'), isTrue);
      expect(SyncEntityType.isValid('lesson_content_allocation'), isTrue);
      expect(SyncEntityType.isValid('lesson_execution_record'), isTrue);
      expect(SyncEntityType.isValid('execution_content_allocation'), isTrue);
      expect(SyncEntityType.isValid('unknown_entity'), isFalse);
    });

    test('deve conter as mutações e status válidos', () {
      expect(SyncMutationType.isValid('INSERT'), isTrue);
      expect(SyncMutationType.isValid('UPDATE'), isTrue);
      expect(SyncMutationType.isValid('DELETE'), isTrue);
      expect(SyncMutationType.isValid('PATCH'), isFalse);

      expect(SyncAckStatus.isValid('APPLIED'), isTrue);
      expect(SyncAckStatus.isValid('SKIPPED'), isTrue);
      expect(SyncAckStatus.isValid('CONFLICT'), isTrue);
      expect(SyncAckStatus.isValid('PENDING'), isFalse);
    });
  });

  group('SyncOperationDto', () {
    test(
      'deve serializar e desserializar com precisão e preservação de campos',
      () {
        final now = DateTime.utc(2026, 10, 20, 14, 30, 0);
        final op = SyncOperationDto(
          clientOpId: '11111111-1111-4111-8111-111111111111',
          entityType: 'academic_year',
          entityId: '22222222-2222-4222-8222-222222222222',
          mutationType: 'INSERT',
          baseSeq: '15',
          clientCreatedAt: now,
          payload: {
            'year': 2026,
            'title': 'Ano Letivo 2026',
            'start_date': '2026-02-02',
            'end_date': '2026-12-18',
            'total_mandatory_days': 200,
          },
        );

        final json = op.toJson();
        expect(json['clientOpId'], equals(op.clientOpId));
        expect(json['entityType'], equals('academic_year'));
        expect(json['entityId'], equals(op.entityId));
        expect(json['mutationType'], equals('INSERT'));
        expect(json['baseSeq'], equals('15'));
        expect(json['clientCreatedAt'], equals('2026-10-20T14:30:00.000Z'));
        expect((json['payload'] as Map)['year'], equals(2026));

        final restored = SyncOperationDto.fromJson(json);
        expect(restored, equals(op));
        expect(restored.payload?['title'], equals('Ano Letivo 2026'));
      },
    );

    test('deve suportar payload e campos opcionais nulos (ex: DELETE)', () {
      final op = SyncOperationDto(
        clientOpId: '33333333-3333-4333-8333-333333333333',
        entityType: 'classroom',
        entityId: '44444444-4444-4444-8444-444444444444',
        mutationType: 'DELETE',
      );

      final json = op.toJson();
      expect(json.containsKey('baseSeq'), isFalse);
      expect(json.containsKey('clientCreatedAt'), isFalse);
      expect(json.containsKey('payload'), isFalse);

      final restored = SyncOperationDto.fromJson(json);
      expect(restored.clientOpId, equals(op.clientOpId));
      expect(restored.payload, isNull);
      expect(restored.baseSeq, isNull);
    });
  });

  group('PushRequestDto', () {
    test('deve serializar envelope de Push com sucesso', () {
      final req = PushRequestDto(
        deviceId: 'dev-123',
        clientBatchId: '55555555-5555-4555-8555-555555555555',
        operations: [
          SyncOperationDto(
            clientOpId: '66666666-6666-4666-8666-666666666666',
            entityType: 'subject',
            entityId: '77777777-7777-4777-8777-777777777777',
            mutationType: 'INSERT',
            payload: {'name': 'Matemática', 'color_hex': '#1E88E5'},
          ),
        ],
      );

      req.validate();
      final json = req.toJson();
      expect(json['deviceId'], equals('dev-123'));
      expect(
        json['clientBatchId'],
        equals('55555555-5555-4555-8555-555555555555'),
      );
      expect((json['operations'] as List).length, equals(1));

      final restored = PushRequestDto.fromJson(json);
      expect(restored.deviceId, equals(req.deviceId));
      expect(
        restored.operations.first.clientOpId,
        equals('66666666-6666-4666-8666-666666666666'),
      );
    });

    test(
      'validate() deve lançar ArgumentError se lista de operações for vazia',
      () {
        final req = PushRequestDto(
          deviceId: 'dev-123',
          clientBatchId: 'batch-1',
          operations: const [],
        );

        expect(() => req.validate(), throwsArgumentError);
      },
    );

    test(
      'validate() deve lançar ArgumentError se lote exceder 100 operações',
      () {
        final ops = List.generate(
          101,
          (i) => SyncOperationDto(
            clientOpId: 'op-$i',
            entityType: 'subject',
            entityId: 'id-$i',
            mutationType: 'INSERT',
          ),
        );

        final req = PushRequestDto(
          deviceId: 'dev-123',
          clientBatchId: 'batch-1',
          operations: ops,
        );

        expect(() => req.validate(), throwsArgumentError);
      },
    );

    test('validate() deve lançar ArgumentError se houver clientOpId duplicado no mesmo lote', () {
      final req = PushRequestDto(
        deviceId: 'dev-123',
        clientBatchId: 'batch-1',
        operations: [
          SyncOperationDto(
            clientOpId: 'duplicate-op-id',
            entityType: 'subject',
            entityId: 'sub-1',
            mutationType: 'INSERT',
          ),
          SyncOperationDto(
            clientOpId: 'duplicate-op-id',
            entityType: 'subject',
            entityId: 'sub-2',
            mutationType: 'UPDATE',
          ),
        ],
      );

      expect(() => req.validate(), throwsArgumentError);
    });
  });

  group('OperationAckDto & PushResponseDto', () {
    test('deve desserializar ACKs com status APPLIED, SKIPPED e CONFLICT', () {
      final json = {
        'clientBatchId': 'batch-res-1',
        'serverEpoch': '1',
        'currentServerSeq': '42',
        'acks': [
          {
            'clientOpId': 'op-applied',
            'status': 'APPLIED',
            'serverSeq': '41',
            'appliedAt': '2026-10-20T14:35:00.000Z',
            'conflict': null,
          },
          {
            'clientOpId': 'op-skipped',
            'status': 'SKIPPED',
            'serverSeq': '38',
            'appliedAt': '2026-10-20T14:30:00.000Z',
            'conflict': null,
          },
          {
            'clientOpId': 'op-conflict',
            'status': 'CONFLICT',
            'serverSeq': '0',
            'appliedAt': '2026-10-20T14:35:01.000Z',
            'conflict': {
              'reason': 'CONCURRENT_SCHEDULE_CONFLICT',
              'serverVersion': {'status': 'completed'},
              'clientVersion': {'status': 'cancelled'},
            },
          },
        ],
      };

      final response = PushResponseDto.fromJson(json);
      expect(response.clientBatchId, equals('batch-res-1'));
      expect(response.serverEpoch, equals('1'));
      expect(response.currentServerSeq, equals('42'));
      expect(response.acks.length, equals(3));

      expect(response.acks[0].isApplied, isTrue);
      expect(response.acks[0].serverSeq, equals('41'));
      expect(response.acks[0].conflict, isNull);

      expect(response.acks[1].isSkipped, isTrue);
      expect(response.acks[1].serverSeq, equals('38'));

      expect(response.acks[2].isConflict, isTrue);
      expect(
        response.acks[2].conflict?.reason,
        equals('CONCURRENT_SCHEDULE_CONFLICT'),
      );
      expect(
        response.acks[2].conflict?.serverVersion?['status'],
        equals('completed'),
      );
    });
  });

  group('PullQueryDto & PullResponseDto & ChangeDto', () {
    test('PullQueryDto deve construir parâmetros de consulta corretamente', () {
      const q1 = PullQueryDto(
        cursor: '15:1042',
        limit: 50,
        excludeDeviceId: 'dev-mobile',
        clientEpoch: '1',
      );
      final params1 = q1.toQueryParams();
      expect(params1['cursor'], equals('15:1042'));
      expect(params1['limit'], equals('50'));
      expect(params1['excludeDeviceId'], equals('dev-mobile'));
      expect(params1['clientEpoch'], equals('1'));

      const q2 = PullQueryDto();
      final params2 = q2.toQueryParams();
      expect(params2.containsKey('cursor'), isFalse);
      expect(params2['limit'], equals('100'));
      expect(params2.containsKey('excludeDeviceId'), isFalse);
    });

    test(
      'PullResponseDto deve desserializar página de alterações com precisão',
      () {
        final json = {
          'epoch': '1',
          'currentServerSeq': '50',
          'nextCursor': '25:1080',
          'hasMore': true,
          'changes': [
            {
              'serverSeq': '25',
              'changeLogId': '1080',
              'entityType': 'planned_lesson',
              'entityId': 'lesson-10',
              'mutationType': 'UPDATE',
              'payload': {
                'id': 'lesson-10',
                'status': 'completed',
                'notes': 'Aula realizada com sucesso.',
              },
              'deviceId': 'web-client',
              'createdAt': '2026-10-20T14:40:00.000Z',
            },
          ],
        };

        final pullRes = PullResponseDto.fromJson(json);
        expect(pullRes.epoch, equals('1'));
        expect(pullRes.currentServerSeq, equals('50'));
        expect(pullRes.nextCursor, equals('25:1080'));
        expect(pullRes.hasMore, isTrue);
        expect(pullRes.changes.length, equals(1));

        final change = pullRes.changes.first;
        expect(change.serverSeq, equals('25'));
        expect(change.changeLogId, equals('1080'));
        expect(change.entityType, equals('planned_lesson'));
        expect(change.mutationType, equals('UPDATE'));
        expect(change.payload?['status'], equals('completed'));
        expect(change.deviceId, equals('web-client'));
        expect(change.createdAt, equals(DateTime.utc(2026, 10, 20, 14, 40, 0)));
      },
    );
  });

  group('SnapshotResponseDto & SnapshotEntitiesDto', () {
    test('deve desserializar snapshot consistente com as 13 coleções', () {
      final now = DateTime.now().toUtc().add(const Duration(minutes: 15));
      final json = {
        'epoch': '1',
        'snapshotSeq': '100',
        'snapshotToken': 'opaque-token-base64',
        'expiresAt': now.toIso8601String(),
        'entities': {
          'academic_years': [
            {'id': 'ay-1', 'year': 2026},
          ],
          'classrooms': [
            {'id': 'c-1', 'name': '6º Ano A'},
          ],
          'subjects': [
            {'id': 's-1', 'name': 'História'},
          ],
          'classroom_subjects': [
            {'id': 'cs-1', 'weekly_lessons': 3},
          ],
          'school_calendar_events': [
            {'id': 'ev-1', 'title': 'Feriado'},
          ],
          'schedule_slots': [
            {'id': 'sl-1', 'weekday': 1},
          ],
          'curriculum_competencies': [
            {'id': 'cc-1', 'code': 'EF06HI01'},
          ],
          'course_contents': [
            {'id': 'cnt-1', 'title': 'Introdução à História'},
          ],
          'content_prerequisites': [
            {'content_id': 'cnt-2', 'prerequisite_content_id': 'cnt-1'},
          ],
          'planned_lessons': [
            {'id': 'pl-1', 'lesson_date': '2026-02-15'},
          ],
          'lesson_content_allocations': [
            {'lesson_id': 'pl-1', 'content_id': 'cnt-1'},
          ],
          'lesson_execution_records': [
            {'id': 'rec-1', 'status': 'completed'},
          ],
          'execution_content_allocations': [
            {'record_id': 'rec-1', 'content_id': 'cnt-1'},
          ],
        },
      };

      final snapshot = SnapshotResponseDto.fromJson(json);
      expect(snapshot.epoch, equals('1'));
      expect(snapshot.snapshotSeq, equals('100'));
      expect(snapshot.snapshotToken, equals('opaque-token-base64'));
      expect(snapshot.isExpired, isFalse);

      final entities = snapshot.entities;
      expect(entities.academicYears.length, equals(1));
      expect(entities.academicYears.first['year'], equals(2026));
      expect(entities.classrooms.length, equals(1));
      expect(entities.subjects.length, equals(1));
      expect(entities.classroomSubjects.length, equals(1));
      expect(entities.schoolCalendarEvents.length, equals(1));
      expect(entities.scheduleSlots.length, equals(1));
      expect(entities.curriculumCompetencies.length, equals(1));
      expect(entities.courseContents.length, equals(1));
      expect(entities.contentPrerequisites.length, equals(1));
      expect(entities.plannedLessons.length, equals(1));
      expect(entities.lessonContentAllocations.length, equals(1));
      expect(entities.lessonExecutionRecords.length, equals(1));
      expect(entities.executionContentAllocations.length, equals(1));
    });

    test(
      'deve tratar coleções ausentes graciosamente inicializando listas vazias',
      () {
        final json = {
          'epoch': '1',
          'snapshotSeq': '10',
          'snapshotToken': 'token',
          'expiresAt': DateTime.now().toUtc().toIso8601String(),
          'entities': <String, dynamic>{},
        };

        final snapshot = SnapshotResponseDto.fromJson(json);
        expect(snapshot.entities.academicYears, isEmpty);
        expect(snapshot.entities.plannedLessons, isEmpty);
        expect(snapshot.entities.lessonExecutionRecords, isEmpty);
      },
    );
  });
}
