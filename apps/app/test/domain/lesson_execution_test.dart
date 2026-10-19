import 'package:app/domain/models/classroom_subject_progress.dart';
import 'package:app/domain/models/lesson_execution_record.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LessonExecutionRecord - Entidade de Domínio', () {
    final now = DateTime.utc(2026, 3, 10, 14, 30);
    final executionDay = DateTime(2026, 3, 10, 8, 15);

    test('deve criar um registro válido para aula realizada (completed)', () {
      final record = LessonExecutionRecord(
        id: 'rec-1',
        plannedLessonId: 'plan-1',
        classroomSubjectId: 'cs-1',
        executionDate: executionDay,
        status: LessonExecutionStatus.completed,
        actualContentIds: const ['cont-1', 'cont-2'],
        pedagogicalNotes:
            'Aula ministrada com excelente participação da turma.',
        recordedAt: now,
      );

      expect(record.id, 'rec-1');
      expect(record.plannedLessonId, 'plan-1');
      expect(record.classroomSubjectId, 'cs-1');
      expect(record.executionDate, DateTime.utc(2026, 3, 10));
      expect(record.status, LessonExecutionStatus.completed);
      expect(record.actualContentIds, ['cont-1', 'cont-2']);
      expect(record.isHeld, isTrue);
      expect(record.isRectified, isFalse);
      expect(record.needsFollowUp, isFalse);
    });

    test('deve permitir criar aula parcialmente realizada com conteúdos', () {
      final record = LessonExecutionRecord(
        id: 'rec-2',
        plannedLessonId: 'plan-2',
        classroomSubjectId: 'cs-1',
        executionDate: executionDay,
        status: LessonExecutionStatus.partiallyCompleted,
        actualContentIds: const ['cont-1'],
        needsFollowUp: true,
        followUpNotes: 'Faltou finalizar os exercícios 4 e 5 da apostila.',
        recordedAt: now,
      );

      expect(record.status, LessonExecutionStatus.partiallyCompleted);
      expect(record.isHeld, isTrue);
      expect(record.needsFollowUp, isTrue);
      expect(record.followUpNotes, contains('exercícios 4 e 5'));
    });

    test('deve permitir criar aula parcialmente realizada apenas com observação pedagógica', () {
      final record = LessonExecutionRecord(
        id: 'rec-3',
        plannedLessonId: 'plan-3',
        classroomSubjectId: 'cs-1',
        executionDate: executionDay,
        status: LessonExecutionStatus.partiallyCompleted,
        pedagogicalNotes: 'Apenas introdução do tema devido a dúvidas prévias.',
        recordedAt: now,
      );

      expect(record.status, LessonExecutionStatus.partiallyCompleted);
      expect(record.actualContentIds, isEmpty);
      expect(record.isHeld, isTrue);
    });

    test('deve permitir criar aula parcialmente realizada apenas com indicação de continuidade', () {
      final record = LessonExecutionRecord(
        id: 'rec-4',
        plannedLessonId: 'plan-4',
        classroomSubjectId: 'cs-1',
        executionDate: executionDay,
        status: LessonExecutionStatus.partiallyCompleted,
        needsFollowUp: true,
        recordedAt: now,
      );

      expect(record.status, LessonExecutionStatus.partiallyCompleted);
      expect(record.needsFollowUp, isTrue);
    });

    test('deve criar um registro válido para aula não realizada (notHeld) com motivo padronizado', () {
      final record = LessonExecutionRecord(
        id: 'rec-5',
        plannedLessonId: 'plan-5',
        classroomSubjectId: 'cs-1',
        executionDate: executionDay,
        status: LessonExecutionStatus.notHeld,
        cancellationReason: LessonCancellationReason.schoolEvent,
        cancellationDetails: 'Conselho de Classe participativo.',
        recordedAt: now,
      );

      expect(record.status, LessonExecutionStatus.notHeld);
      expect(record.isHeld, isFalse);
      expect(record.actualContentIds, isEmpty);
      expect(record.cancellationReason, LessonCancellationReason.schoolEvent);
    });

    test('deve lançar exceção ao tentar criar registro com status planned', () {
      expect(
        () => LessonExecutionRecord(
          id: 'rec-invalid',
          plannedLessonId: 'plan-1',
          classroomSubjectId: 'cs-1',
          executionDate: executionDay,
          status: LessonExecutionStatus.planned,
          recordedAt: now,
        ),
        throwsA(
          isA<LessonExecutionValidationException>().having(
            (e) => e.message,
            'message',
            contains('não pode possuir status "planned"'),
          ),
        ),
      );
    });

    test('deve lançar exceção se identificador for vazio', () {
      expect(
        () => LessonExecutionRecord(
          id: '   ',
          plannedLessonId: 'plan-1',
          classroomSubjectId: 'cs-1',
          executionDate: executionDay,
          status: LessonExecutionStatus.completed,
          recordedAt: now,
        ),
        throwsA(
          isA<LessonExecutionValidationException>().having(
            (e) => e.message,
            'message',
            contains(
              'identificador do registro de execução não pode ser vazio',
            ),
          ),
        ),
      );
    });

    test('deve lançar exceção se vínculo com aula planejada for vazio', () {
      expect(
        () => LessonExecutionRecord(
          id: 'rec-1',
          plannedLessonId: '',
          classroomSubjectId: 'cs-1',
          executionDate: executionDay,
          status: LessonExecutionStatus.completed,
          recordedAt: now,
        ),
        throwsA(
          isA<LessonExecutionValidationException>().having(
            (e) => e.message,
            'message',
            contains('vínculo com a aula planejada é obrigatório'),
          ),
        ),
      );
    });

    test('deve lançar exceção se vínculo com disciplina/turma for vazio', () {
      expect(
        () => LessonExecutionRecord(
          id: 'rec-1',
          plannedLessonId: 'plan-1',
          classroomSubjectId: '  ',
          executionDate: executionDay,
          status: LessonExecutionStatus.completed,
          recordedAt: now,
        ),
        throwsA(
          isA<LessonExecutionValidationException>().having(
            (e) => e.message,
            'message',
            contains('vínculo com a disciplina da turma é obrigatório'),
          ),
        ),
      );
    });

    test(
      'deve lançar exceção se houver IDs duplicados em actualContentIds',
      () {
        expect(
          () => LessonExecutionRecord(
            id: 'rec-1',
            plannedLessonId: 'plan-1',
            classroomSubjectId: 'cs-1',
            executionDate: executionDay,
            status: LessonExecutionStatus.completed,
            actualContentIds: const ['cont-1', 'cont-2', 'cont-1'],
            recordedAt: now,
          ),
          throwsA(
            isA<LessonExecutionValidationException>().having(
              (e) => e.message,
              'message',
              contains('referências duplicadas'),
            ),
          ),
        );
      },
    );

    test(
      'deve lançar exceção se aula não realizada possuir conteúdos ministrados',
      () {
        expect(
          () => LessonExecutionRecord(
            id: 'rec-1',
            plannedLessonId: 'plan-1',
            classroomSubjectId: 'cs-1',
            executionDate: executionDay,
            status: LessonExecutionStatus.notHeld,
            cancellationReason: LessonCancellationReason.teacherAbsence,
            actualContentIds: const ['cont-1'],
            recordedAt: now,
          ),
          throwsA(
            isA<LessonExecutionValidationException>().having(
              (e) => e.message,
              'message',
              contains('não podem conter conteúdos ministrados'),
            ),
          ),
        );
      },
    );

    test('deve lançar exceção se aula não realizada não possuir motivo', () {
      expect(
        () => LessonExecutionRecord(
          id: 'rec-1',
          plannedLessonId: 'plan-1',
          classroomSubjectId: 'cs-1',
          executionDate: executionDay,
          status: LessonExecutionStatus.notHeld,
          cancellationReason: null,
          recordedAt: now,
        ),
        throwsA(
          isA<LessonExecutionValidationException>().having(
            (e) => e.message,
            'message',
            contains('motivo padronizado'),
          ),
        ),
      );
    });

    test('deve lançar exceção se aula parcialmente realizada não tiver conteúdo, anotação ou continuidade', () {
      expect(
        () => LessonExecutionRecord(
          id: 'rec-1',
          plannedLessonId: 'plan-1',
          classroomSubjectId: 'cs-1',
          executionDate: executionDay,
          status: LessonExecutionStatus.partiallyCompleted,
          actualContentIds: const [],
          pedagogicalNotes: null,
          needsFollowUp: false,
          recordedAt: now,
        ),
        throwsA(
          isA<LessonExecutionValidationException>().having(
            (e) => e.message,
            'message',
            contains('devem conter ao menos um conteúdo ministrado'),
          ),
        ),
      );
    });

    test('deve lançar exceção se updatedAt for anterior a recordedAt', () {
      expect(
        () => LessonExecutionRecord(
          id: 'rec-1',
          plannedLessonId: 'plan-1',
          classroomSubjectId: 'cs-1',
          executionDate: executionDay,
          status: LessonExecutionStatus.completed,
          recordedAt: now,
          updatedAt: now.subtract(const Duration(minutes: 5)),
        ),
        throwsA(
          isA<LessonExecutionValidationException>().having(
            (e) => e.message,
            'message',
            contains('não pode ser anterior à data de criação'),
          ),
        ),
      );
    });

    test('deve suportar retificação via copyWith atualizando updatedAt', () {
      final original = LessonExecutionRecord(
        id: 'rec-1',
        plannedLessonId: 'plan-1',
        classroomSubjectId: 'cs-1',
        executionDate: executionDay,
        status: LessonExecutionStatus.completed,
        actualContentIds: const ['cont-1'],
        recordedAt: now,
      );

      final rectifiedAt = now.add(const Duration(hours: 2));
      final rectified = original.copyWith(
        actualContentIds: const ['cont-1', 'cont-2'],
        updatedAt: rectifiedAt,
        pedagogicalNotes: 'Retificado: conteúdo 2 também foi finalizado.',
      );

      expect(rectified.isRectified, isTrue);
      expect(rectified.actualContentIds, ['cont-1', 'cont-2']);
      expect(rectified.updatedAt, rectifiedAt);
      expect(rectified.recordedAt, now);
      expect(rectified != original, isTrue);
    });

    test('deve implementar equality e hashCode adequadamente', () {
      final rec1 = LessonExecutionRecord(
        id: 'rec-1',
        plannedLessonId: 'plan-1',
        classroomSubjectId: 'cs-1',
        executionDate: executionDay,
        status: LessonExecutionStatus.completed,
        actualContentIds: const ['cont-1'],
        recordedAt: now,
      );

      final rec2 = LessonExecutionRecord(
        id: 'rec-1',
        plannedLessonId: 'plan-1',
        classroomSubjectId: 'cs-1',
        executionDate: executionDay,
        status: LessonExecutionStatus.completed,
        actualContentIds: const ['cont-1'],
        recordedAt: now,
      );

      expect(rec1, equals(rec2));
      expect(rec1.hashCode, equals(rec2.hashCode));
    });
  });

  group('LessonCancellationReason - Extensão com textos em pt-BR', () {
    test('todos os motivos devem ter rótulo e descrição preenchidos', () {
      for (final reason in LessonCancellationReason.values) {
        expect(reason.label.trim().isNotEmpty, isTrue);
        expect(reason.description.trim().isNotEmpty, isTrue);
      }
    });
  });

  group('ClassroomSubjectProgress - Value Object', () {
    test('deve calcular métricas e taxas determinísticas corretamente', () {
      final progress = ClassroomSubjectProgress(
        classroomSubjectId: 'cs-1',
        totalLessonsPlanned: 80,
        completedLessonsCount: 30,
        partiallyCompletedLessonsCount: 10,
        notHeldLessonsCount: 5,
        pendingRecordLessonsCount: 5,
        futureLessonsCount: 30,
      );

      expect(progress.totalLessonsRecorded, 45); // 30 + 10 + 5
      expect(progress.totalLessonsEffective, 40); // 30 + 10
      expect(progress.completionRate, 40 / 80); // 0.50
      expect(progress.recordingRate, 45 / 80); // 0.5625
      expect(progress.hasPendingPastLessons, isTrue);
    });

    test('deve lidar com caso de início sem aulas realizadas', () {
      final progress = ClassroomSubjectProgress(
        classroomSubjectId: 'cs-1',
        totalLessonsPlanned: 40,
        completedLessonsCount: 0,
        partiallyCompletedLessonsCount: 0,
        notHeldLessonsCount: 0,
        pendingRecordLessonsCount: 0,
        futureLessonsCount: 40,
      );

      expect(progress.totalLessonsRecorded, 0);
      expect(progress.totalLessonsEffective, 0);
      expect(progress.completionRate, 0.0);
      expect(progress.recordingRate, 0.0);
      expect(progress.hasPendingPastLessons, isFalse);
    });

    test(
      'deve suportar totalLessonsPlanned igual a 0 sem divisão por zero',
      () {
        final progress = ClassroomSubjectProgress(
          classroomSubjectId: 'cs-1',
          totalLessonsPlanned: 0,
          completedLessonsCount: 0,
          partiallyCompletedLessonsCount: 0,
          notHeldLessonsCount: 0,
          pendingRecordLessonsCount: 0,
          futureLessonsCount: 0,
        );

        expect(progress.completionRate, 0.0);
        expect(progress.recordingRate, 0.0);
      },
    );

    test('deve lançar exceção se identificador da disciplina for vazio', () {
      expect(
        () => ClassroomSubjectProgress(
          classroomSubjectId: '',
          totalLessonsPlanned: 10,
          completedLessonsCount: 5,
          partiallyCompletedLessonsCount: 0,
          notHeldLessonsCount: 0,
          pendingRecordLessonsCount: 0,
          futureLessonsCount: 5,
        ),
        throwsA(
          isA<ClassroomSubjectProgressValidationException>().having(
            (e) => e.message,
            'message',
            contains('identificador da disciplina da turma não pode ser vazio'),
          ),
        ),
      );
    });

    test('deve lançar exceção se algum contador for negativo', () {
      expect(
        () => ClassroomSubjectProgress(
          classroomSubjectId: 'cs-1',
          totalLessonsPlanned: 10,
          completedLessonsCount: -1,
          partiallyCompletedLessonsCount: 0,
          notHeldLessonsCount: 0,
          pendingRecordLessonsCount: 0,
          futureLessonsCount: 11,
        ),
        throwsA(
          isA<ClassroomSubjectProgressValidationException>().having(
            (e) => e.message,
            'message',
            contains('pode ser negativo'),
          ),
        ),
      );
    });

    test(
      'deve lançar exceção se a soma das categorias divergir do total previsto',
      () {
        expect(
          () => ClassroomSubjectProgress(
            classroomSubjectId: 'cs-1',
            totalLessonsPlanned: 10,
            completedLessonsCount: 5,
            partiallyCompletedLessonsCount: 2,
            notHeldLessonsCount: 1,
            pendingRecordLessonsCount: 1,
            futureLessonsCount: 2, // soma: 11 != 10
          ),
          throwsA(
            isA<ClassroomSubjectProgressValidationException>().having(
              (e) => e.message,
              'message',
              contains('a soma das categorias (11) não corresponde ao total'),
            ),
          ),
        );
      },
    );

    test('deve implementar equality e hashCode adequadamente', () {
      final p1 = ClassroomSubjectProgress(
        classroomSubjectId: 'cs-1',
        totalLessonsPlanned: 10,
        completedLessonsCount: 5,
        partiallyCompletedLessonsCount: 0,
        notHeldLessonsCount: 0,
        pendingRecordLessonsCount: 0,
        futureLessonsCount: 5,
      );

      final p2 = ClassroomSubjectProgress(
        classroomSubjectId: 'cs-1',
        totalLessonsPlanned: 10,
        completedLessonsCount: 5,
        partiallyCompletedLessonsCount: 0,
        notHeldLessonsCount: 0,
        pendingRecordLessonsCount: 0,
        futureLessonsCount: 5,
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
    });
  });
}
