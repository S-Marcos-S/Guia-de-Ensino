import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/models/course_content.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/models/planning_engine_contracts.dart';
import 'package:app/domain/models/schedule_slot.dart';
import 'package:app/domain/models/school_calendar_event.dart';
import 'package:app/domain/services/calendar_calculation_service.dart';
import 'package:app/domain/services/planning_engine_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = PlanningEngineService();
  const csId = 'cs-123';

  // Helper para criar slots de horário
  ScheduleSlot makeSlot(String id, int weekday, int orderIndex) {
    return ScheduleSlot(
      id: id,
      classroomSubjectId: csId,
      weekday: weekday,
      orderIndex: orderIndex,
    );
  }

  // Helper para criar conteúdos
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

  group('PlanningEngineService - Validações Iniciais', () {
    test('falha quando data inicial é posterior à data final', () {
      final request = PlanningEngineRequest(
        classroomSubjectId: csId,
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 5, 1),
        teachingDays: [DateTime(2026, 5, 15)],
        scheduleSlots: [makeSlot('s1', 1, 1)],
        contents: [makeContent(id: 'c1', title: 'A')],
      );

      final result = service.generatePlan(request);

      expect(result.isSuccessful, isFalse);
      expect(result.conflicts.length, 1);
      expect(
        result.conflicts.first.type,
        PlanningConflictType.invalidConfiguration,
      );
    });

    test('falha quando não há slots de horário na grade semanal', () {
      final request = PlanningEngineRequest(
        classroomSubjectId: csId,
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 28),
        teachingDays: [DateTime(2026, 2, 2)],
        scheduleSlots: const [],
        contents: [makeContent(id: 'c1', title: 'A')],
      );

      final result = service.generatePlan(request);

      expect(result.isSuccessful, isFalse);
      expect(result.conflicts.length, 1);
      expect(
        result.conflicts.first.type,
        PlanningConflictType.scheduleMismatch,
      );
    });

    test(
      'falha quando grade semanal contém slots duplicados no mesmo dia e ordem',
      () {
        final request = PlanningEngineRequest(
          classroomSubjectId: csId,
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 2, 28),
          teachingDays: [DateTime(2026, 2, 2)],
          scheduleSlots: [
            makeSlot('s1', 1, 1),
            makeSlot('s2', 1, 1), // Conflito: mesma 1ª aula na segunda
          ],
          contents: [makeContent(id: 'c1', title: 'A')],
        );

        final result = service.generatePlan(request);

        expect(result.isSuccessful, isFalse);
        expect(
          result.conflicts.first.type,
          PlanningConflictType.scheduleMismatch,
        );
      },
    );

    test('detecta dependência circular entre conteúdos e retorna conflito estruturado', () {
      final c1 = makeContent(
        id: 'c1',
        title: 'Álgebra',
        prerequisiteIds: ['c2'],
      );
      final c2 = makeContent(
        id: 'c2',
        title: 'Geometria',
        prerequisiteIds: ['c1'],
      );

      final request = PlanningEngineRequest(
        classroomSubjectId: csId,
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 28),
        teachingDays: [DateTime(2026, 2, 2)],
        scheduleSlots: [makeSlot('s1', 1, 1)],
        contents: [c1, c2],
      );

      final result = service.generatePlan(request);

      expect(result.isSuccessful, isFalse);
      expect(
        result.conflicts.first.type,
        PlanningConflictType.circularPrerequisite,
      );
      expect(
        result.conflicts.first.affectedContentIds,
        containsAll(['c1', 'c2']),
      );
    });
  });

  group('PlanningEngineService - Distribuição Simples e Múltiplos Slots', () {
    test('distribui múltiplos conteúdos em aulas de um slot semanal', () {
      // Segundas-feiras: 2, 9, 16, 23 de fevereiro de 2026
      final teachingDays = [
        DateTime(2026, 2, 2),
        DateTime(2026, 2, 9),
        DateTime(2026, 2, 16),
        DateTime(2026, 2, 23),
      ];

      final contents = [
        makeContent(
          id: 'c1',
          title: 'Introdução',
          estimatedLessons: 2,
          orderIndex: 1,
        ),
        makeContent(
          id: 'c2',
          title: 'Aprofundamento',
          estimatedLessons: 2,
          orderIndex: 2,
        ),
      ];

      final request = PlanningEngineRequest(
        classroomSubjectId: csId,
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 28),
        teachingDays: teachingDays,
        scheduleSlots: [makeSlot('s1', 1, 1)], // 1ª aula da segunda
        contents: contents,
      );

      final result = service.generatePlan(request);

      expect(result.isSuccessful, isTrue);
      expect(result.conflicts, isEmpty);
      expect(result.availableLessonOccurrences, 4);
      expect(result.usedLessonOccurrences, 4);
      expect(result.plannedLessons.length, 4);

      // c1 deve ocupar 02/02 e 09/02
      expect(result.plannedLessons[0].lesson.date, DateTime(2026, 2, 2));
      expect(result.plannedLessons[0].contentIds, ['c1']);
      expect(result.plannedLessons[1].lesson.date, DateTime(2026, 2, 9));
      expect(result.plannedLessons[1].contentIds, ['c1']);

      // c2 deve ocupar 16/02 e 23/02
      expect(result.plannedLessons[2].lesson.date, DateTime(2026, 2, 16));
      expect(result.plannedLessons[2].contentIds, ['c2']);
      expect(result.plannedLessons[3].lesson.date, DateTime(2026, 2, 23));
      expect(result.plannedLessons[3].contentIds, ['c2']);

      expect(result.fullyAllocatedContents.length, 2);
      expect(result.unallocatedContents, isEmpty);
      expect(result.lessonDeficit, 0);
    });

    test('distribui respeitando múltiplos slots no mesmo dia (ex: 2 aulas na segunda)', () {
      final teachingDays = [
        DateTime(2026, 2, 2), // Segunda
      ];

      final contents = [
        makeContent(
          id: 'c1',
          title: 'Parte 1',
          estimatedLessons: 1,
          orderIndex: 1,
        ),
        makeContent(
          id: 'c2',
          title: 'Parte 2',
          estimatedLessons: 1,
          orderIndex: 2,
        ),
      ];

      final request = PlanningEngineRequest(
        classroomSubjectId: csId,
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 28),
        teachingDays: teachingDays,
        scheduleSlots: [
          makeSlot('s1', 1, 1), // 1ª aula
          makeSlot('s2', 1, 2), // 2ª aula
        ],
        contents: contents,
      );

      final result = service.generatePlan(request);

      expect(result.isSuccessful, isTrue);
      expect(result.availableLessonOccurrences, 2);
      expect(result.plannedLessons.length, 2);

      expect(result.plannedLessons[0].lesson.date, DateTime(2026, 2, 2));
      expect(result.plannedLessons[0].lesson.orderInDay, 1);
      expect(result.plannedLessons[0].contentIds, ['c1']);

      expect(result.plannedLessons[1].lesson.date, DateTime(2026, 2, 2));
      expect(result.plannedLessons[1].lesson.orderInDay, 2);
      expect(result.plannedLessons[1].contentIds, ['c2']);
    });
  });

  group('PlanningEngineService - Respeito ao Calendário e Intervalo', () {
    test('ignora datas letivas fora do intervalo [startDate, endDate]', () {
      final teachingDays = [
        DateTime(2026, 1, 26), // Antes de startDate
        DateTime(2026, 2, 2), // Dentro
        DateTime(2026, 3, 2), // Depois de endDate
      ];

      final contents = [
        makeContent(id: 'c1', title: 'Único', estimatedLessons: 1),
      ];

      final request = PlanningEngineRequest(
        classroomSubjectId: csId,
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 28),
        teachingDays: teachingDays,
        scheduleSlots: [makeSlot('s1', 1, 1)],
        contents: contents,
      );

      final result = service.generatePlan(request);

      expect(result.availableLessonOccurrences, 1);
      expect(result.plannedLessons.length, 1);
      expect(result.plannedLessons.first.lesson.date, DateTime(2026, 2, 2));
    });

    test('integra com CalendarCalculationService excluindo feriados que afetam aulas', () {
      const calendarService = CalendarCalculationService();
      final year = AcademicYear(
        id: 'ay1',
        year: 2026,
        title: 'Ano 2026',
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 15),
        totalMandatoryDays: 10,
      );

      // Duas segundas-feiras no período: 02/02 e 09/02.
      // Adicionamos um feriado em 09/02 (Carnaval) que afeta aulas.
      final holiday = SchoolCalendarEvent(
        id: 'ev-carnaval',
        academicYearId: 'ay1',
        title: 'Carnaval',
        startDate: DateTime(2026, 2, 9),
        endDate: DateTime(2026, 2, 9),
        type: SchoolEventType.holiday,
        affectsClasses: true,
      );

      // Evento comemorativo em 02/02 que NÃO afeta aulas
      final celebration = SchoolCalendarEvent(
        id: 'ev-comemora',
        academicYearId: 'ay1',
        title: 'Dia Especial',
        startDate: DateTime(2026, 2, 2),
        endDate: DateTime(2026, 2, 2),
        type: SchoolEventType.pedagogicalMeeting,
        affectsClasses: false,
      );

      final calResult = calendarService.calculateTeachingDays(
        academicYear: year,
        events: [holiday, celebration],
      );

      final request = PlanningEngineRequest(
        classroomSubjectId: csId,
        startDate: year.startDate,
        endDate: year.endDate,
        teachingDays: calResult.teachingDays,
        scheduleSlots: [makeSlot('s1', 1, 1)], // Segundas-feiras
        contents: [
          makeContent(id: 'c1', title: 'Aula Única', estimatedLessons: 1),
        ],
      );

      final result = service.generatePlan(request);

      // 09/02 foi cancelado pelo feriado, sobrando apenas 02/02
      expect(result.availableLessonOccurrences, 1);
      expect(result.plannedLessons.length, 1);
      expect(result.plannedLessons.first.lesson.date, DateTime(2026, 2, 2));
    });
  });

  group('PlanningEngineService - Pré-requisitos e Ordenação Topológica', () {
    test('aloca pré-requisito antes do dependente mesmo se orderIndex for invertido', () {
      // Conteúdo B tem orderIndex 1, mas depende de A que tem orderIndex 5
      final contentB = makeContent(
        id: 'cB',
        title: 'Função Afim',
        orderIndex: 1,
        prerequisiteIds: ['cA'],
      );
      final contentA = makeContent(
        id: 'cA',
        title: 'Equação de 1º Grau',
        orderIndex: 5,
        prerequisiteIds: const [],
      );

      final request = PlanningEngineRequest(
        classroomSubjectId: csId,
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 28),
        teachingDays: [DateTime(2026, 2, 2), DateTime(2026, 2, 9)],
        scheduleSlots: [makeSlot('s1', 1, 1)],
        contents: [contentB, contentA],
        strategy: PlanningStrategy.pedagogicalSequence,
      );

      final result = service.generatePlan(request);

      expect(result.isSuccessful, isTrue);
      // cA deve ser ministrado em 02/02 e cB em 09/02
      expect(result.plannedLessons[0].contentIds, ['cA']);
      expect(result.plannedLessons[1].contentIds, ['cB']);
    });

    test('prioriza obrigatórios na estratégia mandatoryFirst quando não há dependência', () {
      final optional = makeContent(
        id: 'cOpt',
        title: 'História da Matemática',
        orderIndex: 1,
        isMandatory: false,
      );
      final mandatory = makeContent(
        id: 'cMand',
        title: 'Frações',
        orderIndex: 2,
        isMandatory: true,
      );

      final request = PlanningEngineRequest(
        classroomSubjectId: csId,
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 28),
        teachingDays: [DateTime(2026, 2, 2), DateTime(2026, 2, 9)],
        scheduleSlots: [makeSlot('s1', 1, 1)],
        contents: [optional, mandatory],
        strategy: PlanningStrategy.mandatoryFirst,
      );

      final result = service.generatePlan(request);

      expect(result.plannedLessons[0].contentIds, ['cMand']);
      expect(result.plannedLessons[1].contentIds, ['cOpt']);
    });
  });

  group(
    'PlanningEngineService - Capacidade Insuficiente e Déficit Explícito',
    () {
      test(
        'não descarta conteúdos silenciosamente e aponta déficit com precisão',
        () {
          // 2 aulas disponíveis, mas conteúdos exigem 4 aulas
          final teachingDays = [DateTime(2026, 2, 2), DateTime(2026, 2, 9)];

          final contents = [
            makeContent(
              id: 'c1',
              title: 'Geometria Espacial',
              estimatedLessons: 2,
              orderIndex: 1,
            ),
            makeContent(
              id: 'c2',
              title: 'Trigonometria',
              estimatedLessons: 2,
              orderIndex: 2,
            ),
          ];

          final request = PlanningEngineRequest(
            classroomSubjectId: csId,
            startDate: DateTime(2026, 2, 1),
            endDate: DateTime(2026, 2, 28),
            teachingDays: teachingDays,
            scheduleSlots: [makeSlot('s1', 1, 1)],
            contents: contents,
          );

          final result = service.generatePlan(request);

          expect(result.isSuccessful, isFalse);
          expect(result.availableLessonOccurrences, 2);
          expect(result.usedLessonOccurrences, 2);
          expect(result.lessonDeficit, 2);

          // c1 foi totalmente alocado (2 aulas)
          final statusC1 = result.contentAllocations.firstWhere(
            (s) => s.content.id == 'c1',
          );
          expect(statusC1.isFullyAllocated, isTrue);
          expect(statusC1.allocatedLessons, 2);

          // c2 não foi alocado por falta de capacidade (0 aulas)
          final statusC2 = result.contentAllocations.firstWhere(
            (s) => s.content.id == 'c2',
          );
          expect(statusC2.isFullyAllocated, isFalse);
          expect(statusC2.allocatedLessons, 0);
          expect(
            statusC2.reasonNotFullyAllocated,
            contains('Capacidade letiva esgotada'),
          );

          // Conflito de insuficiência registrado explicitamente
          final capacityConflicts = result.conflicts
              .where((c) => c.type == PlanningConflictType.insufficientCapacity)
              .toList();
          expect(capacityConflicts.isNotEmpty, isTrue);
          expect(capacityConflicts.first.affectedContentIds, contains('c2'));
        },
      );
    },
  );

  group('PlanningEngineService - Preservação Sagrada de Histórico', () {
    test('preserva integralmente aulas concluídas, parciais e bloqueadas', () {
      // Calendário com 3 segundas
      final teachingDays = [
        DateTime(2026, 2, 2),
        DateTime(2026, 2, 9),
        DateTime(2026, 2, 16),
      ];

      // Aula histórica realizada em 02/02 cobrindo 'c1'
      final historicalLesson = PlannedLesson(
        id: 'hist-01',
        classroomSubjectId: csId,
        date: DateTime.utc(2026, 2, 2),
        orderInDay: 1,
        contentIds: ['c1'],
        status: LessonExecutionStatus.completed,
      );

      // Aula futura em 09/02 bloqueada pelo professor com notas especiais
      final lockedLesson = PlannedLesson(
        id: 'locked-01',
        classroomSubjectId: csId,
        date: DateTime.utc(2026, 2, 9),
        orderInDay: 1,
        contentIds: ['c2'],
        status: LessonExecutionStatus.planned,
        isLocked: true,
        notes: 'Avaliação Diagnóstica Travada',
      );

      // Aula anterior puramente planejada em 16/02 (sem execução e sem trava)
      final replaceableLesson = PlannedLesson(
        id: 'repl-01',
        classroomSubjectId: csId,
        date: DateTime.utc(2026, 2, 16),
        orderInDay: 1,
        contentIds: ['old-content'],
        status: LessonExecutionStatus.planned,
        isLocked: false,
      );

      final contents = [
        makeContent(
          id: 'c1',
          title: 'Introdução',
          estimatedLessons: 1,
          orderIndex: 1,
        ),
        makeContent(
          id: 'c2',
          title: 'Avaliação',
          estimatedLessons: 1,
          orderIndex: 2,
        ),
        makeContent(
          id: 'c3',
          title: 'Novo Conteúdo',
          estimatedLessons: 1,
          orderIndex: 3,
        ),
      ];

      final request = PlanningEngineRequest(
        classroomSubjectId: csId,
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 28),
        teachingDays: teachingDays,
        scheduleSlots: [makeSlot('s1', 1, 1)],
        contents: contents,
        existingLessons: [historicalLesson, lockedLesson, replaceableLesson],
      );

      final result = service.generatePlan(request);

      expect(result.isSuccessful, isTrue);
      expect(result.preservedLessons.length, 2);
      expect(result.plannedLessons.length, 3);

      // Aula 1: histórica preservada
      final alloc1 = result.plannedLessons[0];
      expect(alloc1.isPreservedFromHistory, isTrue);
      expect(alloc1.lesson.id, 'hist-01');
      expect(alloc1.lesson.status, LessonExecutionStatus.completed);

      // Aula 2: travada preservada
      final alloc2 = result.plannedLessons[1];
      expect(alloc2.isPreservedFromHistory, isTrue);
      expect(alloc2.lesson.id, 'locked-01');
      expect(alloc2.lesson.isLocked, isTrue);
      expect(alloc2.lesson.notes, 'Avaliação Diagnóstica Travada');

      // Aula 3: nova aula gerada para c3 no slot vago de 16/02
      final alloc3 = result.plannedLessons[2];
      expect(alloc3.isPreservedFromHistory, isFalse);
      expect(alloc3.contentIds, ['c3']);
      expect(alloc3.lesson.date, DateTime(2026, 2, 16));
      expect(
        alloc3.lesson.id,
        isNot('repl-01'),
      ); // Substituiu a antiga planejada

      // Todos os 3 conteúdos estão 100% cobertos
      expect(result.fullyAllocatedContents.length, 3);
    });
  });

  group('PlanningEngineService - Determinismo Estrito', () {
    test(
      'duas chamadas com as mesmas entradas geram exatamente o mesmo resultado',
      () {
        final teachingDays = List.generate(
          10,
          (i) => DateTime(2026, 2, 2).add(Duration(days: i * 7)),
        );

        final contents = [
          makeContent(
            id: 'c1',
            title: 'Teoria dos Conjuntos',
            estimatedLessons: 3,
            orderIndex: 1,
          ),
          makeContent(
            id: 'c2',
            title: 'Relações',
            estimatedLessons: 2,
            orderIndex: 2,
            prerequisiteIds: ['c1'],
          ),
          makeContent(
            id: 'c3',
            title: 'Funções',
            estimatedLessons: 4,
            orderIndex: 3,
            prerequisiteIds: ['c2'],
          ),
        ];

        final request = PlanningEngineRequest(
          classroomSubjectId: csId,
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 5, 30),
          teachingDays: teachingDays,
          scheduleSlots: [makeSlot('s1', 1, 1)],
          contents: contents,
        );

        final resultA = service.generatePlan(request);
        final resultB = service.generatePlan(request);

        expect(resultA.isSuccessful, resultB.isSuccessful);
        expect(
          resultA.availableLessonOccurrences,
          resultB.availableLessonOccurrences,
        );
        expect(resultA.usedLessonOccurrences, resultB.usedLessonOccurrences);
        expect(resultA.plannedLessons.length, resultB.plannedLessons.length);

        for (var i = 0; i < resultA.plannedLessons.length; i++) {
          final lessonA = resultA.plannedLessons[i].lesson;
          final lessonB = resultB.plannedLessons[i].lesson;

          expect(lessonA.id, lessonB.id);
          expect(lessonA.date, lessonB.date);
          expect(lessonA.orderInDay, lessonB.orderInDay);
          expect(lessonA.contentIds, lessonB.contentIds);
          expect(lessonA.status, lessonB.status);
          expect(lessonA.isLocked, lessonB.isLocked);
        }
      },
    );
  });
}
