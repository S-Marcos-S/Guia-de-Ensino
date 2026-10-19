import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/models/course_content.dart';
import 'package:app/domain/models/lesson_execution_record.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/models/replanning_models.dart';
import 'package:app/domain/models/schedule_slot.dart';
import 'package:app/domain/services/replanning_engine_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = ReplanningEngineService();
  const csId = 'cs-matematica-6a';

  final academicYear = AcademicYear(
    id: 'ay-2026',
    year: 2026,
    title: 'Ano Letivo 2026',
    startDate: DateTime(2026, 2, 2),
    endDate: DateTime(2026, 12, 18),
    totalMandatoryDays: 200,
  );

  ScheduleSlot makeSlot(String id, int weekday, int orderIndex) {
    return ScheduleSlot(
      id: id,
      classroomSubjectId: csId,
      weekday: weekday,
      orderIndex: orderIndex,
    );
  }

  CourseContent makeContent({
    required String id,
    required String title,
    int estimatedLessons = 1,
    int orderIndex = 1,
    bool isMandatory = true,
    List<String> prerequisiteIds = const [],
  }) {
    return CourseContent(
      id: id,
      classroomSubjectId: csId,
      title: title,
      estimatedLessons: estimatedLessons,
      orderIndex: orderIndex,
      isMandatory: isMandatory,
      prerequisiteIds: prerequisiteIds,
      origin: ContentOrigin.manual,
    );
  }

  PlannedLesson makeLesson({
    required String id,
    required DateTime date,
    int orderInDay = 1,
    List<String> contentIds = const [],
    bool isLocked = false,
  }) {
    return PlannedLesson(
      id: id,
      classroomSubjectId: csId,
      date: date,
      orderInDay: orderInDay,
      contentIds: contentIds,
      status: LessonExecutionStatus.planned,
      isLocked: isLocked,
    );
  }

  group('Curricular Viability & Capacity Management — Fase 8 Test Suite', () {
    // 1. Demanda exatamente igual à capacidade
    test('1. Demanda exatamente igual à capacidade resulta em status atRisk com margem zero', () {
      final teachingDays = List.generate(
        10,
        (i) => DateTime(
          2026,
          3,
          2,
        ).add(Duration(days: i * 7)), // 10 segundas-feiras
      );
      final slots = [makeSlot('s1', 1, 1)];
      final contents = [
        makeContent(id: 'c1', title: 'Frações', estimatedLessons: 5),
        makeContent(id: 'c2', title: 'Decimais', estimatedLessons: 5),
      ];

      final analysis = service.analyzeCurricularCapacity(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 3, 2),
        academicYear: academicYear,
        teachingDays: teachingDays,
        scheduleSlots: slots,
        contents: contents,
        existingLessons: const [],
        executionRecords: const [],
      );

      expect(analysis.totalFutureAvailableSlots, 10);
      expect(analysis.totalRemainingDemandLessons, 10);
      expect(analysis.capacityDeficit, 0);
      expect(analysis.safetyMarginLessons, 0);
      expect(analysis.viabilityStatus, CurricularViabilityStatus.atRisk);
      expect(analysis.overflowsAcademicYear, isFalse);
    });

    // 2. Demanda menor que a capacidade
    test('2. Demanda menor que a capacidade resulta em status viable com margem de folga', () {
      final teachingDays = List.generate(
        15,
        (i) => DateTime(2026, 3, 2).add(Duration(days: i * 7)),
      );
      final slots = [makeSlot('s1', 1, 1)];
      final contents = [
        makeContent(id: 'c1', title: 'Álgebra', estimatedLessons: 10),
      ];

      final analysis = service.analyzeCurricularCapacity(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 3, 2),
        academicYear: academicYear,
        teachingDays: teachingDays,
        scheduleSlots: slots,
        contents: contents,
        existingLessons: const [],
        executionRecords: const [],
      );

      expect(analysis.totalFutureAvailableSlots, 15);
      expect(analysis.totalRemainingDemandLessons, 10);
      expect(analysis.capacityDeficit, 0);
      expect(analysis.safetyMarginLessons, 5);
      expect(analysis.viabilityStatus, CurricularViabilityStatus.viable);
      expect(analysis.estimatedCompletionDate, teachingDays[9]);
    });

    // 3. Demanda superior à capacidade
    test('3. Demanda superior à capacidade resulta em deficit e unfeasible para obrigatórios', () {
      final teachingDays = List.generate(
        8,
        (i) => DateTime(2026, 3, 2).add(Duration(days: i * 7)),
      );
      final slots = [makeSlot('s1', 1, 1)];
      final contents = [
        makeContent(
          id: 'c1',
          title: 'Geometria Espacial',
          estimatedLessons: 12,
          isMandatory: true,
        ),
      ];

      final analysis = service.analyzeCurricularCapacity(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 3, 2),
        academicYear: academicYear,
        teachingDays: teachingDays,
        scheduleSlots: slots,
        contents: contents,
        existingLessons: const [],
        executionRecords: const [],
      );

      expect(analysis.totalFutureAvailableSlots, 8);
      expect(analysis.totalRemainingDemandLessons, 12);
      expect(analysis.capacityDeficit, 4);
      expect(analysis.mandatoryCapacityDeficit, 4);
      expect(analysis.viabilityStatus, CurricularViabilityStatus.unfeasible);
      expect(analysis.overflowsAcademicYear, isTrue);
    });

    // 4. Aumento da necessidade estimada de aulas sem ocorrência de faltas
    test('4. Detecção antecipada identifica déficit curricular mesmo com zero faltas', () {
      final teachingDays = List.generate(
        6,
        (i) => DateTime(2026, 3, 2).add(Duration(days: i * 7)),
      );
      final slots = [makeSlot('s1', 1, 1)];
      final contents = [
        makeContent(id: 'c1', title: 'Funções', estimatedLessons: 10),
      ];

      final result = service.detectDelay(
        classroomSubjectId: csId,
        plannedLessons: const [],
        executionRecords: const [],
        courseContents: contents,
        referenceDate: DateTime(2026, 3, 2),
        academicYear: academicYear,
        teachingDays: teachingDays,
        scheduleSlots: slots,
      );

      expect(result.notHeldCount, 0);
      expect(result.hasCapacityDeficit, isTrue);
      expect(result.capacityDeficit, 4);
      expect(result.hasDelay, isTrue);
      expect(
        result.delayReasons.any(
          (r) => r.contains('Déficit de capacidade curricular antecipado'),
        ),
        isTrue,
      );
    });

    // 5. Aulas não realizadas que também afetam a capacidade
    test('5. Aulas canceladas acumulam atraso fático e ampliam déficit de capacidade', () {
      final teachingDays = [
        DateTime(2026, 3, 2),
        DateTime(2026, 3, 9),
        DateTime(2026, 3, 16),
      ];
      final slots = [makeSlot('s1', 1, 1)];
      final contents = [
        makeContent(id: 'c1', title: 'Probabilidade', estimatedLessons: 3),
      ];
      final lesson1 = makeLesson(
        id: 'l1',
        date: DateTime(2026, 3, 2),
        contentIds: ['c1'],
      );
      final record1 = LessonExecutionRecord(
        id: 'rec1',
        plannedLessonId: 'l1',
        classroomSubjectId: csId,
        executionDate: DateTime(2026, 3, 2),
        recordedAt: DateTime(2026, 3, 2, 10),
        status: LessonExecutionStatus.notHeld,
        cancellationReason: LessonCancellationReason.teacherAbsence,
        actualContentIds: const [],
      );

      final analysis = service.analyzeCurricularCapacity(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 3, 9),
        academicYear: academicYear,
        teachingDays: teachingDays,
        scheduleSlots: slots,
        contents: contents,
        existingLessons: [lesson1],
        executionRecords: [record1],
      );

      expect(analysis.totalFutureAvailableSlots, 2); // 09/03 e 16/03
      expect(analysis.totalRemainingDemandLessons, 3); // 3 aulas necessárias
      expect(analysis.capacityDeficit, 1);
    });

    // 6. Conteúdos parcialmente ministrados
    test('6. Aula partiallyCompleted não liquida o conteúdo e preserva saldo restante', () {
      final teachingDays = [DateTime(2026, 3, 2), DateTime(2026, 3, 9)];
      final slots = [makeSlot('s1', 1, 1)];
      final contents = [
        makeContent(id: 'c1', title: 'Equações', estimatedLessons: 2),
      ];
      final lesson1 = makeLesson(
        id: 'l1',
        date: DateTime(2026, 3, 2),
        contentIds: ['c1'],
      );
      final record1 = LessonExecutionRecord(
        id: 'rec1',
        plannedLessonId: 'l1',
        classroomSubjectId: csId,
        executionDate: DateTime(2026, 3, 2),
        recordedAt: DateTime(2026, 3, 2, 10),
        status: LessonExecutionStatus.partiallyCompleted,
        actualContentIds: const ['c1'],
      );

      final analysis = service.analyzeCurricularCapacity(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 3, 9),
        academicYear: academicYear,
        teachingDays: teachingDays,
        scheduleSlots: slots,
        contents: contents,
        existingLessons: [lesson1],
        executionRecords: [record1],
      );

      // Aula parcial não incrementou completedCount (salvaguarda 1)
      expect(analysis.totalRemainingDemandLessons, 2);
    });

    // 7. Necessidades de continuidade
    test('7. needsFollowUp adiciona aula de consolidação pedagógica mesmo se carga nominal foi cumprida', () {
      final teachingDays = [DateTime(2026, 3, 2), DateTime(2026, 3, 9)];
      final slots = [makeSlot('s1', 1, 1)];
      final contents = [
        makeContent(id: 'c1', title: 'Trigonometria', estimatedLessons: 1),
      ];
      final lesson1 = makeLesson(
        id: 'l1',
        date: DateTime(2026, 3, 2),
        contentIds: ['c1'],
      );
      final record1 = LessonExecutionRecord(
        id: 'rec1',
        plannedLessonId: 'l1',
        classroomSubjectId: csId,
        executionDate: DateTime(2026, 3, 2),
        recordedAt: DateTime(2026, 3, 2, 10),
        status: LessonExecutionStatus.partiallyCompleted,
        actualContentIds: const ['c1'],
        needsFollowUp: true,
        followUpNotes: 'Dúvidas em seno e cosseno',
      );

      final analysis = service.analyzeCurricularCapacity(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 3, 9),
        academicYear: academicYear,
        teachingDays: teachingDays,
        scheduleSlots: slots,
        contents: contents,
        existingLessons: [lesson1],
        executionRecords: [record1],
      );

      expect(analysis.totalRemainingDemandLessons, 1); // 1 aula de consolidação
    });

    // 8. Conteúdos com durações estimadas diferentes
    test(
      '8. Calcula demanda heterogênea somando durações distintas com precisão',
      () {
        final teachingDays = List.generate(
          10,
          (i) => DateTime(2026, 3, 2).add(Duration(days: i * 7)),
        );
        final slots = [makeSlot('s1', 1, 1)];
        final contents = [
          makeContent(id: 'c1', title: 'Estatística', estimatedLessons: 4),
          makeContent(id: 'c2', title: 'Gráficos', estimatedLessons: 2),
          makeContent(id: 'c3', title: 'Tabelas', estimatedLessons: 1),
        ];

        final analysis = service.analyzeCurricularCapacity(
          classroomSubjectId: csId,
          referenceDate: DateTime(2026, 3, 2),
          academicYear: academicYear,
          teachingDays: teachingDays,
          scheduleSlots: slots,
          contents: contents,
          existingLessons: const [],
          executionRecords: const [],
        );

        expect(analysis.totalRemainingDemandLessons, 7); // 4 + 2 + 1
        expect(analysis.totalFutureAvailableSlots, 10);
        expect(analysis.safetyMarginLessons, 3);
      },
    );

    // 9. Aulas bloqueadas e registros factuais preservados
    test(
      '9. Aulas bloqueadas futuras ocupam vagas e reduzem capacidade livre',
      () {
        final teachingDays = [
          DateTime(2026, 3, 2),
          DateTime(2026, 3, 9),
          DateTime(2026, 3, 16),
        ];
        final slots = [makeSlot('s1', 1, 1)];
        final contents = [
          makeContent(id: 'c1', title: 'Matrizes', estimatedLessons: 2),
        ];
        // Aula bloqueada para avaliação em 09/03
        final lockedLesson = makeLesson(
          id: 'locked1',
          date: DateTime(2026, 3, 9),
          isLocked: true,
        );

        final analysis = service.analyzeCurricularCapacity(
          classroomSubjectId: csId,
          referenceDate: DateTime(2026, 3, 2),
          academicYear: academicYear,
          teachingDays: teachingDays,
          scheduleSlots: slots,
          contents: contents,
          existingLessons: [lockedLesson],
          executionRecords: const [],
        );

        expect(
          analysis.totalFutureAvailableSlots,
          2,
        ); // 3 dias - 1 bloqueado = 2 vagas livres
        expect(analysis.totalRemainingDemandLessons, 2);
        expect(analysis.safetyMarginLessons, 0);
        expect(
          analysis.limitingConstraints.any((c) => c.contains('travada(s)')),
          isTrue,
        );
      },
    );

    // 10. Feriados, recessos e término do ano letivo
    test('10. Respeita término do ano letivo e desconsidera dias fora do intervalo', () {
      final teachingDays = [
        DateTime(2026, 12, 14),
        DateTime(2026, 12, 21), // Fora do ano letivo que encerra em 18/12
      ];
      final slots = [makeSlot('s1', 1, 1)];
      final contents = [
        makeContent(id: 'c1', title: 'Revisão Final', estimatedLessons: 2),
      ];

      final analysis = service.analyzeCurricularCapacity(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 12, 14),
        academicYear: academicYear,
        teachingDays: teachingDays,
        scheduleSlots: slots,
        contents: contents,
        existingLessons: const [],
        executionRecords: const [],
      );

      expect(analysis.totalFutureAvailableSlots, 1); // Somente 14/12 é válida
      expect(analysis.capacityDeficit, 1);
      expect(analysis.overflowsAcademicYear, isTrue);
    });

    // 11. Restrições de grade horária e pré-requisitos
    test(
      '11. Conteúdo com pré-requisito não alocado herda risco de pré-requisito',
      () {
        final teachingDays = [DateTime(2026, 3, 2)];
        final slots = [makeSlot('s1', 1, 1)];
        final contents = [
          makeContent(
            id: 'c1',
            title: 'Básico',
            estimatedLessons: 2,
            orderIndex: 1,
          ),
          makeContent(
            id: 'c2',
            title: 'Avançado',
            estimatedLessons: 1,
            orderIndex: 2,
            prerequisiteIds: ['c1'],
          ),
        ];

        final analysis = service.analyzeCurricularCapacity(
          classroomSubjectId: csId,
          referenceDate: DateTime(2026, 3, 2),
          academicYear: academicYear,
          teachingDays: teachingDays,
          scheduleSlots: slots,
          contents: contents,
          existingLessons: const [],
          executionRecords: const [],
        );

        final c2Risk = analysis.contentsAtRisk.firstWhere(
          (r) => r.content.id == 'c2',
        );
        expect(c2Risk.isAtRisk, isTrue);
        expect(c2Risk.hasPrerequisiteRisk, isTrue);
      },
    );

    // 12. Dados incompletos ou insuficientes para estimativa
    test('12. Grade horária vazia resulta em status indeterminate', () {
      final analysis = service.analyzeCurricularCapacity(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 3, 2),
        academicYear: academicYear,
        teachingDays: const [],
        scheduleSlots: const [], // Grade vazia
        contents: [makeContent(id: 'c1', title: 'Intro')],
        existingLessons: const [],
        executionRecords: const [],
      );

      expect(analysis.viabilityStatus, CurricularViabilityStatus.indeterminate);
    });

    // 13. Cenários alternativos sem modificação da persistência
    test('13. generateRecoveryScenarios gera cenários puros em memória', () {
      final teachingDays = List.generate(
        5,
        (i) => DateTime(2026, 3, 2).add(Duration(days: i * 7)),
      );
      final slots = [makeSlot('s1', 1, 1)];
      final contents = [
        makeContent(
          id: 'c1',
          title: 'Obrigatório',
          estimatedLessons: 4,
          isMandatory: true,
        ),
        makeContent(
          id: 'c2',
          title: 'Opcional',
          estimatedLessons: 3,
          isMandatory: false,
        ),
      ];

      final scenarios = service.generateRecoveryScenarios(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 3, 2),
        academicYear: academicYear,
        teachingDays: teachingDays,
        scheduleSlots: slots,
        contents: contents,
        existingLessons: const [],
        executionRecords: const [],
      );

      expect(scenarios.length, greaterThanOrEqualTo(3));
      final baseline = scenarios.firstWhere(
        (s) => s.type == RecoveryScenarioType.baseline,
      );
      final additional = scenarios.firstWhere(
        (s) => s.type == RecoveryScenarioType.additionalCapacity,
      );
      final essential = scenarios.firstWhere(
        (s) => s.type == RecoveryScenarioType.essentialPriority,
      );

      expect(baseline.extraLessonsNeeded, 2); // 7 demanda - 5 vagas = 2
      expect(additional.extraLessonsNeeded, 2);
      expect(
        essential.extraLessonsNeeded,
        0,
      ); // 4 obrigatórias cabem em 5 vagas!
      expect(essential.unallocatedContentTitles, contains('Opcional'));
    });

    // 14. Determinismo ao executar novamente a projeção
    test('14. Execuções repetidas da análise de capacidade produzem resultados idênticos', () {
      final teachingDays = List.generate(
        8,
        (i) => DateTime(2026, 3, 2).add(Duration(days: i * 7)),
      );
      final slots = [makeSlot('s1', 1, 1)];
      final contents = [
        makeContent(id: 'c1', title: 'Polinômios', estimatedLessons: 6),
      ];

      final res1 = service.analyzeCurricularCapacity(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 3, 2),
        academicYear: academicYear,
        teachingDays: teachingDays,
        scheduleSlots: slots,
        contents: contents,
        existingLessons: const [],
        executionRecords: const [],
      );

      final res2 = service.analyzeCurricularCapacity(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 3, 2),
        academicYear: academicYear,
        teachingDays: teachingDays,
        scheduleSlots: slots,
        contents: contents,
        existingLessons: const [],
        executionRecords: const [],
      );

      expect(res1.capacityDeficit, res2.capacityDeficit);
      expect(res1.safetyMarginLessons, res2.safetyMarginLessons);
      expect(res1.viabilityStatus, res2.viabilityStatus);
      expect(res1.estimatedCompletionDate, res2.estimatedCompletionDate);
    });

    // 15. Identificação dos conteúdos que não cabem na capacidade restante
    test('15. Identifica com exatidão conteúdos em risco e número de aulas faltantes', () {
      final teachingDays = [DateTime(2026, 3, 2), DateTime(2026, 3, 9)];
      final slots = [makeSlot('s1', 1, 1)];
      final contents = [
        makeContent(
          id: 'c1',
          title: 'Tópico 1',
          estimatedLessons: 2,
          orderIndex: 1,
        ),
        makeContent(
          id: 'c2',
          title: 'Tópico 2',
          estimatedLessons: 2,
          orderIndex: 2,
        ),
      ];

      final analysis = service.analyzeCurricularCapacity(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 3, 2),
        academicYear: academicYear,
        teachingDays: teachingDays,
        scheduleSlots: slots,
        contents: contents,
        existingLessons: const [],
        executionRecords: const [],
      );

      final c1Risk = analysis.contentsAtRisk.firstWhere(
        (r) => r.content.id == 'c1',
      );
      final c2Risk = analysis.contentsAtRisk.firstWhere(
        (r) => r.content.id == 'c2',
      );

      expect(c1Risk.isAtRisk, isFalse);
      expect(c1Risk.allocatedLessons, 2);
      expect(c2Risk.isAtRisk, isTrue);
      expect(c2Risk.missingLessons, 2);
    });

    // 16. Atualização da projeção após novos apontamentos
    test('16. Conclusão de aulas no diário reduz demanda e atualiza projeção de viabilidade', () {
      final teachingDays = List.generate(
        5,
        (i) => DateTime(2026, 3, 2).add(Duration(days: i * 7)),
      );
      final slots = [makeSlot('s1', 1, 1)];
      final contents = [
        makeContent(id: 'c1', title: 'Conjuntos', estimatedLessons: 6),
      ];

      // Inicialmente 6 aulas para 5 vagas = déficit 1
      final before = service.analyzeCurricularCapacity(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 3, 2),
        academicYear: academicYear,
        teachingDays: teachingDays,
        scheduleSlots: slots,
        contents: contents,
        existingLessons: const [],
        executionRecords: const [],
      );
      expect(before.capacityDeficit, 1);

      // Professor aponta 2 aulas completed no passado
      final lessonPast1 = makeLesson(
        id: 'lp1',
        date: DateTime(2026, 2, 16),
        contentIds: ['c1'],
      );
      final recordPast1 = LessonExecutionRecord(
        id: 'recp1',
        plannedLessonId: 'lp1',
        classroomSubjectId: csId,
        executionDate: DateTime(2026, 2, 16),
        recordedAt: DateTime(2026, 2, 16, 10),
        status: LessonExecutionStatus.completed,
        actualContentIds: const ['c1'],
      );
      final lessonPast2 = makeLesson(
        id: 'lp2',
        date: DateTime(2026, 2, 23),
        contentIds: ['c1'],
      );
      final recordPast2 = LessonExecutionRecord(
        id: 'recp2',
        plannedLessonId: 'lp2',
        classroomSubjectId: csId,
        executionDate: DateTime(2026, 2, 23),
        recordedAt: DateTime(2026, 2, 23, 10),
        status: LessonExecutionStatus.completed,
        actualContentIds: const ['c1'],
      );

      final after = service.analyzeCurricularCapacity(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 3, 2),
        academicYear: academicYear,
        teachingDays: teachingDays,
        scheduleSlots: slots,
        contents: contents,
        existingLessons: [lessonPast1, lessonPast2],
        executionRecords: [recordPast1, recordPast2],
      );

      // Agora demanda restante = 4 aulas, que cabem nas 5 vagas futuras (folga 1)
      expect(after.totalRemainingDemandLessons, 4);
      expect(after.capacityDeficit, 0);
      expect(after.safetyMarginLessons, 1);
      expect(after.viabilityStatus, CurricularViabilityStatus.viable);
    });

    // 17. Revisão explícita das estimativas pelo professor
    test('17. Simulação com estimativas customizadas recalcula viabilidade sem alterar banco', () {
      final teachingDays = List.generate(
        5,
        (i) => DateTime(2026, 3, 2).add(Duration(days: i * 7)),
      );
      final slots = [makeSlot('s1', 1, 1)];
      final contents = [
        makeContent(id: 'c1', title: 'Logaritmos', estimatedLessons: 8),
      ];

      // Estimativa original: 8 aulas para 5 vagas -> deficit 3
      final baseline = service.analyzeCurricularCapacity(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 3, 2),
        academicYear: academicYear,
        teachingDays: teachingDays,
        scheduleSlots: slots,
        contents: contents,
        existingLessons: const [],
        executionRecords: const [],
      );
      expect(baseline.capacityDeficit, 3);

      // Professor compacta estimativa para 4 aulas na simulação
      final simulated = service.analyzeCurricularCapacity(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 3, 2),
        academicYear: academicYear,
        teachingDays: teachingDays,
        scheduleSlots: slots,
        contents: contents,
        existingLessons: const [],
        executionRecords: const [],
        customEstimatedLessonsPerContent: {'c1': 4},
      );

      expect(simulated.totalRemainingDemandLessons, 4);
      expect(simulated.capacityDeficit, 0);
      expect(simulated.safetyMarginLessons, 1);
      expect(simulated.viabilityStatus, CurricularViabilityStatus.viable);
    });

    // 18. Análise do ritmo real de ensino
    test('18. Análise do ritmo real calcula razão observada e projeta impacto de aulas', () {
      final contents = [
        makeContent(id: 'c1', title: 'Conteúdo Concluído', estimatedLessons: 2),
      ];
      final record1 = LessonExecutionRecord(
        id: 'r1',
        plannedLessonId: 'l1',
        classroomSubjectId: csId,
        executionDate: DateTime(2026, 2, 2),
        recordedAt: DateTime(2026, 2, 2, 10),
        status: LessonExecutionStatus.completed,
        actualContentIds: const ['c1'],
      );
      final record2 = LessonExecutionRecord(
        id: 'r2',
        plannedLessonId: 'l2',
        classroomSubjectId: csId,
        executionDate: DateTime(2026, 2, 9),
        recordedAt: DateTime(2026, 2, 9, 10),
        status: LessonExecutionStatus.completed,
        actualContentIds: const ['c1'],
      );
      final record3 = LessonExecutionRecord(
        id: 'r3',
        plannedLessonId: 'l3',
        classroomSubjectId: csId,
        executionDate: DateTime(2026, 2, 16),
        recordedAt: DateTime(2026, 2, 16, 10),
        status: LessonExecutionStatus.completed,
        actualContentIds: const ['c1'],
      );

      // Gastou 3 aulas para um conteúdo estimado em 2 (fator 1.5)
      final pace = service.analyzeTeachingPace(
        contents: contents,
        executionRecords: [record1, record2, record3],
        totalRemainingDemandLessons: 10,
      );

      expect(pace.hasSufficientHistoricalData, isTrue);
      expect(pace.observedPaceRatio, 1.5);
      expect(
        pace.projectedAdditionalLessonsIfPaceMaintained,
        5,
      ); // 10 * 0.5 = 5
      expect(pace.methodologyExplanation, isNotEmpty);
      expect(pace.limitationsExplanation, isNotEmpty);
    });
  });
}
