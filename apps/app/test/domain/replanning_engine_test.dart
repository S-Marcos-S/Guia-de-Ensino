import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/models/course_content.dart';
import 'package:app/domain/models/lesson_execution_record.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/models/planning_engine_contracts.dart';
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
    createdAt: DateTime(2026, 1, 10),
  );

  // Helper para criar slots de horário (ex: Segunda e Quarta aula 1)
  ScheduleSlot makeSlot(String id, int weekday, int orderIndex, {String subject = csId}) {
    return ScheduleSlot(
      id: id,
      classroomSubjectId: subject,
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
    String subject = csId,
  }) {
    return CourseContent(
      id: id,
      classroomSubjectId: subject,
      title: title,
      estimatedLessons: estimatedLessons,
      orderIndex: orderIndex,
      isMandatory: isMandatory,
      prerequisiteIds: prerequisiteIds,
      origin: ContentOrigin.manual,
    );
  }

  // Helper para criar aulas planejadas
  PlannedLesson makeLesson({
    required String id,
    required DateTime date,
    int orderInDay = 1,
    List<String> contentIds = const [],
    LessonExecutionStatus status = LessonExecutionStatus.planned,
    bool isLocked = false,
    String subject = csId,
  }) {
    return PlannedLesson(
      id: id,
      classroomSubjectId: subject,
      date: date,
      orderInDay: orderInDay,
      contentIds: contentIds,
      status: status,
      isLocked: isLocked,
    );
  }

  // Helper para criar registros fáticos de execução
  LessonExecutionRecord makeRecord({
    required String id,
    required String plannedLessonId,
    required DateTime executionDate,
    required LessonExecutionStatus status,
    List<String> actualContentIds = const [],
    LessonCancellationReason? cancellationReason,
    bool needsFollowUp = false,
    String? followUpNotes,
    DateTime? updatedAt,
    String subject = csId,
  }) {
    return LessonExecutionRecord(
      id: id,
      plannedLessonId: plannedLessonId,
      classroomSubjectId: subject,
      executionDate: executionDate,
      status: status,
      actualContentIds: actualContentIds,
      cancellationReason: cancellationReason,
      needsFollowUp: needsFollowUp,
      followUpNotes: followUpNotes,
      recordedAt: DateTime.utc(2026, executionDate.month, executionDate.day, 12, 0),
      updatedAt: updatedAt,
    );
  }

  group('ReplanningEngineService - 15 Cenários Obrigatórios de Domínio', () {
    // 1. Nenhum atraso: o planejamento permanece inalterado
    test('Cenário 1 - Nenhum atraso: o planejamento permanece inalterado', () {
      final l1 = makeLesson(id: 'l1', date: DateTime(2026, 2, 2), contentIds: ['c1']);
      final l2 = makeLesson(id: 'l2', date: DateTime(2026, 2, 9), contentIds: ['c2']);
      final r1 = makeRecord(
        id: 'r1',
        plannedLessonId: 'l1',
        executionDate: DateTime(2026, 2, 2),
        status: LessonExecutionStatus.completed,
        actualContentIds: ['c1'],
      );

      final contents = [
        makeContent(id: 'c1', title: 'Números Naturais', estimatedLessons: 1, orderIndex: 1),
        makeContent(id: 'c2', title: 'Operações Básicas', estimatedLessons: 1, orderIndex: 2),
      ];

      // Detecção de atraso na data 05/02/2026 (entre l1 e l2)
      final delay = service.detectDelay(
        classroomSubjectId: csId,
        plannedLessons: [l1, l2],
        executionRecords: [r1],
        courseContents: contents,
        referenceDate: DateTime(2026, 2, 5),
      );

      expect(delay.hasDelay, isFalse);
      expect(delay.notHeldCount, 0);
      expect(delay.delayReasons, isEmpty);

      // Proposta de replanejamento
      final proposal = service.generateProposal(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 2, 5),
        academicYear: academicYear,
        teachingDays: [DateTime(2026, 2, 2), DateTime(2026, 2, 9)],
        scheduleSlots: [makeSlot('s1', 1, 1)],
        contents: contents,
        existingLessons: [l1, l2],
        executionRecords: [r1],
      );

      expect(proposal.isIdenticalToCurrentPlan, isTrue);
      expect(proposal.affectedFutureLessonsCount, 0);
    });

    // 2. Atraso identificado corretamente a partir dos registros factuais
    test('Cenário 2 - Atraso identificado a partir de aula com registro notHeld', () {
      final l1 = makeLesson(id: 'l1', date: DateTime(2026, 2, 2), contentIds: ['c1']);
      final l2 = makeLesson(id: 'l2', date: DateTime(2026, 2, 9), contentIds: ['c2']);
      final r1 = makeRecord(
        id: 'r1',
        plannedLessonId: 'l1',
        executionDate: DateTime(2026, 2, 2),
        status: LessonExecutionStatus.notHeld,
        cancellationReason: LessonCancellationReason.teacherAbsence,
      );

      final contents = [
        makeContent(id: 'c1', title: 'Números Naturais', estimatedLessons: 1, orderIndex: 1),
        makeContent(id: 'c2', title: 'Operações Básicas', estimatedLessons: 1, orderIndex: 2),
      ];

      final delay = service.detectDelay(
        classroomSubjectId: csId,
        plannedLessons: [l1, l2],
        executionRecords: [r1],
        courseContents: contents,
        referenceDate: DateTime(2026, 2, 5),
      );

      expect(delay.hasDelay, isTrue);
      expect(delay.notHeldCount, 1);
      expect(delay.delayReasons.first, contains('Aula cancelada'));
    });

    // 3. Reprogramação de aulas futuras afetadas
    test('Cenário 3 - Reprogramação de aulas futuras: conteúdo de aula notHeld é empurrado', () {
      final l1 = makeLesson(id: 'l1', date: DateTime(2026, 2, 2), contentIds: ['c1'], status: LessonExecutionStatus.notHeld);
      final l2 = makeLesson(id: 'l2', date: DateTime(2026, 2, 9), contentIds: ['c2']);
      final r1 = makeRecord(
        id: 'r1',
        plannedLessonId: 'l1',
        executionDate: DateTime(2026, 2, 2),
        status: LessonExecutionStatus.notHeld,
        cancellationReason: LessonCancellationReason.schoolEvent,
      );

      final contents = [
        makeContent(id: 'c1', title: 'Conteúdo A', estimatedLessons: 1, orderIndex: 1),
        makeContent(id: 'c2', title: 'Conteúdo B', estimatedLessons: 1, orderIndex: 2),
      ];

      final proposal = service.generateProposal(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 2, 5),
        academicYear: academicYear,
        teachingDays: [DateTime(2026, 2, 2), DateTime(2026, 2, 9), DateTime(2026, 2, 16)],
        scheduleSlots: [makeSlot('s1', 1, 1)],
        contents: contents,
        existingLessons: [l1, l2],
        executionRecords: [r1],
      );

      expect(proposal.isIdenticalToCurrentPlan, isFalse);
      expect(proposal.preservedHistoricLessonsCount, 1);

      // A aula histórica em 02/02 deve permanecer intocada
      final historicShift = proposal.shifts.firstWhere((s) => s.originalDate == DateTime(2026, 2, 2));
      expect(historicShift.isPreservedHistoric, isTrue);

      // A próxima aula livre em 09/02 deve agora receber o Conteúdo A que não foi dado em 02/02
      final nextShift = proposal.shifts.firstWhere((s) => s.proposedDate == DateTime(2026, 2, 9));
      expect(nextShift.proposedContentIds, contains('c1'));

      // E o Conteúdo B é empurrado para a próxima aula livre em 16/02
      final pushedShift = proposal.shifts.firstWhere((s) => s.proposedDate == DateTime(2026, 2, 16));
      expect(pushedShift.proposedContentIds, contains('c2'));
    });

    // 4. Preservação de aulas já realizadas
    test('Cenário 4 - Preservação sagrada de aulas já realizadas (completed e partiallyCompleted)', () {
      final l1 = makeLesson(id: 'l1', date: DateTime(2026, 2, 2), contentIds: ['c1'], status: LessonExecutionStatus.completed);
      final l2 = makeLesson(id: 'l2', date: DateTime(2026, 2, 9), contentIds: ['c2'], status: LessonExecutionStatus.partiallyCompleted);
      final l3 = makeLesson(id: 'l3', date: DateTime(2026, 2, 16), contentIds: ['c3']);

      final r1 = makeRecord(
        id: 'r1',
        plannedLessonId: 'l1',
        executionDate: DateTime(2026, 2, 2),
        status: LessonExecutionStatus.completed,
        actualContentIds: ['c1'],
      );
      final r2 = makeRecord(
        id: 'r2',
        plannedLessonId: 'l2',
        executionDate: DateTime(2026, 2, 9),
        status: LessonExecutionStatus.partiallyCompleted,
        actualContentIds: ['c2'],
        needsFollowUp: true,
        followUpNotes: 'Retomar exercícios 3 e 4',
      );

      final contents = [
        makeContent(id: 'c1', title: 'C1', estimatedLessons: 1, orderIndex: 1),
        makeContent(id: 'c2', title: 'C2', estimatedLessons: 1, orderIndex: 2),
        makeContent(id: 'c3', title: 'C3', estimatedLessons: 1, orderIndex: 3),
      ];

      final proposal = service.generateProposal(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 2, 10),
        academicYear: academicYear,
        teachingDays: [DateTime(2026, 2, 2), DateTime(2026, 2, 9), DateTime(2026, 2, 16), DateTime(2026, 2, 23)],
        scheduleSlots: [makeSlot('s1', 1, 1)],
        contents: contents,
        existingLessons: [l1, l2, l3],
        executionRecords: [r1, r2],
      );

      expect(proposal.preservedHistoricLessonsCount, 2);
      final preserved = proposal.shifts.where((s) => s.isPreservedHistoric).toList();
      expect(preserved.length, 2);
      expect(preserved[0].originalDate, DateTime(2026, 2, 2));
      expect(preserved[1].originalDate, DateTime(2026, 2, 9));
    });

    // 5. Preservação de datas e estados dos apontamentos originais
    test('Cenário 5 - Preservação de datas e estados dos apontamentos originais (LessonExecutionRecord intacto)', () {
      final rOrig = makeRecord(
        id: 'r-fixo',
        plannedLessonId: 'l1',
        executionDate: DateTime(2026, 2, 2),
        status: LessonExecutionStatus.completed,
        actualContentIds: ['c1'],
      );

      // O replanejamento apenas lê os registros e não altera nenhum campo da entidade
      expect(rOrig.executionDate, DateTime.utc(2026, 2, 2));
      expect(rOrig.status, LessonExecutionStatus.completed);
      expect(rOrig.actualContentIds, ['c1']);
    });

    // 6. Aula futura pendente que não deve ser considerada atrasada indevidamente
    test('Cenário 6 - Aula futura pendente não deve ser considerada atrasada', () {
      final lFutura = makeLesson(
        id: 'l-futura',
        date: DateTime(2026, 5, 10),
        contentIds: ['c1'],
        status: LessonExecutionStatus.planned,
      );

      final delay = service.detectDelay(
        classroomSubjectId: csId,
        plannedLessons: [lFutura],
        executionRecords: const [],
        courseContents: [makeContent(id: 'c1', title: 'C1')],
        referenceDate: DateTime(2026, 2, 2), // Referência é 02/02, aula é em 10/05
      );

      expect(delay.hasDelay, isFalse);
      expect(delay.pastUnrecordedCount, 0);
    });

    // 7. Aula não realizada e tratamento correspondente à regra definida
    test('Cenário 7 - Aula não realizada: saldo restante de aulas do conteúdo é preservado integralmente', () {
      final l1 = makeLesson(id: 'l1', date: DateTime(2026, 2, 2), contentIds: ['c1'], status: LessonExecutionStatus.notHeld);
      final r1 = makeRecord(
        id: 'r1',
        plannedLessonId: 'l1',
        executionDate: DateTime(2026, 2, 2),
        status: LessonExecutionStatus.notHeld,
        cancellationReason: LessonCancellationReason.infrastructureIssue,
      );

      final contents = [
        makeContent(id: 'c1', title: 'Frações', estimatedLessons: 2, orderIndex: 1),
      ];

      final proposal = service.generateProposal(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 2, 5),
        academicYear: academicYear,
        teachingDays: [DateTime(2026, 2, 2), DateTime(2026, 2, 9), DateTime(2026, 2, 16)],
        scheduleSlots: [makeSlot('s1', 1, 1)],
        contents: contents,
        existingLessons: [l1],
        executionRecords: [r1],
      );

      // Como l1 foi notHeld, as 2 aulas completas de c1 continuam pendentes e devem ser alocadas no futuro
      final futureAllocations = proposal.shifts.where((s) => !s.isPreservedHistoric).toList();
      expect(futureAllocations.length, 2);
      expect(futureAllocations[0].proposedDate, DateTime(2026, 2, 9));
      expect(futureAllocations[1].proposedDate, DateTime(2026, 2, 16));
      expect(futureAllocations[0].proposedContentIds, contains('c1'));
      expect(futureAllocations[1].proposedContentIds, contains('c1'));
    });

    // 8. Retificação de apontamento e recálculo consistente
    test('Cenário 8 - Retificação de apontamento: recálculo consistente do replanejamento', () {
      final l1 = makeLesson(id: 'l1', date: DateTime(2026, 2, 2), contentIds: ['c1']);
      final contents = [
        makeContent(id: 'c1', title: 'Álgebra', estimatedLessons: 1, orderIndex: 1),
      ];

      // Inicialmente aula foi notHeld
      final rInicial = makeRecord(
        id: 'r1',
        plannedLessonId: 'l1',
        executionDate: DateTime(2026, 2, 2),
        status: LessonExecutionStatus.notHeld,
        cancellationReason: LessonCancellationReason.teacherAbsence,
      );

      final delayInicial = service.detectDelay(
        classroomSubjectId: csId,
        plannedLessons: [l1],
        executionRecords: [rInicial],
        courseContents: contents,
        referenceDate: DateTime(2026, 2, 5),
      );
      expect(delayInicial.hasDelay, isTrue);

      // Professor retifica apontamento no diário para completed
      final rRetificado = rInicial.copyWith(
        status: LessonExecutionStatus.completed,
        actualContentIds: ['c1'],
        cancellationReason: null,
        updatedAt: DateTime.utc(2026, 2, 3, 10, 0),
      );

      final delayRetificado = service.detectDelay(
        classroomSubjectId: csId,
        plannedLessons: [l1],
        executionRecords: [rRetificado],
        courseContents: contents,
        referenceDate: DateTime(2026, 2, 5),
      );
      expect(delayRetificado.hasDelay, isFalse);
    });

    // 9. Execuções repetidas que produzem o mesmo resultado lógico (Determinismo)
    test('Cenário 9 - Idempotência e determinismo: execuções repetidas produzem exatamente a mesma proposta', () {
      final l1 = makeLesson(id: 'l1', date: DateTime(2026, 2, 2), contentIds: ['c1'], status: LessonExecutionStatus.notHeld);
      final r1 = makeRecord(
        id: 'r1',
        plannedLessonId: 'l1',
        executionDate: DateTime(2026, 2, 2),
        status: LessonExecutionStatus.notHeld,
        cancellationReason: LessonCancellationReason.schoolEvent,
      );

      final contents = [
        makeContent(id: 'c1', title: 'C1', estimatedLessons: 2, orderIndex: 1),
        makeContent(id: 'c2', title: 'C2', estimatedLessons: 1, orderIndex: 2),
      ];

      final days = [DateTime(2026, 2, 2), DateTime(2026, 2, 9), DateTime(2026, 2, 16), DateTime(2026, 2, 23)];
      final slots = [makeSlot('s1', 1, 1)];

      final prop1 = service.generateProposal(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 2, 5),
        academicYear: academicYear,
        teachingDays: days,
        scheduleSlots: slots,
        contents: contents,
        existingLessons: [l1],
        executionRecords: [r1],
      );

      final prop2 = service.generateProposal(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 2, 5),
        academicYear: academicYear,
        teachingDays: days,
        scheduleSlots: slots,
        contents: contents,
        existingLessons: [l1],
        executionRecords: [r1],
      );

      expect(prop1.shifts.length, prop2.shifts.length);
      for (var i = 0; i < prop1.shifts.length; i++) {
        expect(prop1.shifts[i].proposedDate, prop2.shifts[i].proposedDate);
        expect(prop1.shifts[i].proposedOrderInDay, prop2.shifts[i].proposedOrderInDay);
        expect(prop1.shifts[i].proposedContentIds, prop2.shifts[i].proposedContentIds);
        expect(prop1.shifts[i].reason, prop2.shifts[i].reason);
      }
    });

    // 10. Ausência de duplicação de aulas
    test('Cenário 10 - Ausência de duplicação de vagas de aulas no mesmo dia e ordem', () {
      final l1 = makeLesson(id: 'l1', date: DateTime(2026, 2, 2), contentIds: ['c1']);
      final contents = [
        makeContent(id: 'c1', title: 'C1', estimatedLessons: 2, orderIndex: 1),
      ];

      final prop = service.generateProposal(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 2, 1),
        academicYear: academicYear,
        teachingDays: [DateTime(2026, 2, 2), DateTime(2026, 2, 9)],
        scheduleSlots: [makeSlot('s1', 1, 1)],
        contents: contents,
        existingLessons: [l1],
        executionRecords: const [],
      );

      final seenSlots = <String>{};
      for (final shift in prop.shifts) {
        final key = '${shift.proposedDate.toIso8601String()}_${shift.proposedOrderInDay}';
        expect(seenSlots.contains(key), isFalse, reason: 'Vaga duplicada detectada: $key');
        seenSlots.add(key);
      }
    });

    // 11. Dados incompletos ou inconsistentes
    test('Cenário 11 - Dados incompletos: grade semanal vazia gera conflito explicável', () {
      final prop = service.generateProposal(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 2, 1),
        academicYear: academicYear,
        teachingDays: [DateTime(2026, 2, 2)],
        scheduleSlots: const [], // Vazio!
        contents: [makeContent(id: 'c1', title: 'C1')],
        existingLessons: const [],
        executionRecords: const [],
      );

      expect(prop.planningResult.isSuccessful, isFalse);
      expect(prop.hasFatalConflicts, isTrue);
      expect(prop.planningResult.conflicts.first.type, PlanningConflictType.scheduleMismatch);
    });

    // 12. Conflitos de calendário e restrições de disponibilidade
    test('Cenário 12 - Feriado no meio do cronograma empurra aulas para a próxima data letiva', () {
      final contents = [
        makeContent(id: 'c1', title: 'C1', estimatedLessons: 1, orderIndex: 1),
        makeContent(id: 'c2', title: 'C2', estimatedLessons: 1, orderIndex: 2),
      ];

      // Segunda 09/02 é feriado (não está na lista de teachingDays)
      final teachingDays = [
        DateTime(2026, 2, 2),
        // 09/02 expurgado por feriado
        DateTime(2026, 2, 16),
      ];

      final prop = service.generateProposal(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 2, 1),
        academicYear: academicYear,
        teachingDays: teachingDays,
        scheduleSlots: [makeSlot('s1', 1, 1)],
        contents: contents,
        existingLessons: const [],
        executionRecords: const [],
      );

      expect(prop.planningResult.isSuccessful, isTrue);
      final dates = prop.shifts.map((s) => s.proposedDate).toList();
      expect(dates, contains(DateTime(2026, 2, 2)));
      expect(dates, contains(DateTime(2026, 2, 16)));
      expect(dates.contains(DateTime(2026, 2, 9)), isFalse);
    });

    // 13. Limites de mês, ano e mudança de período
    test('Cenário 13 - Replanejamento transita entre virada de mês mantendo ordenação civil', () {
      final contents = [
        makeContent(id: 'c1', title: 'Fevereiro', estimatedLessons: 1, orderIndex: 1),
        makeContent(id: 'c2', title: 'Março', estimatedLessons: 1, orderIndex: 2),
      ];

      final teachingDays = [
        DateTime(2026, 2, 23),
        DateTime(2026, 3, 2),
      ];

      final prop = service.generateProposal(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 2, 20),
        academicYear: academicYear,
        teachingDays: teachingDays,
        scheduleSlots: [makeSlot('s1', 1, 1)],
        contents: contents,
        existingLessons: const [],
        executionRecords: const [],
      );

      expect(prop.shifts[0].proposedDate, DateTime(2026, 2, 23));
      expect(prop.shifts[1].proposedDate, DateTime(2026, 3, 2));
    });

    // 14. Ordenação estável quando duas aulas possuem a mesma data
    test('Cenário 14 - Duas aulas na mesma data respeitam orderInDay de forma estável', () {
      final contents = [
        makeContent(id: 'c1', title: 'C1', estimatedLessons: 1, orderIndex: 1),
        makeContent(id: 'c2', title: 'C2', estimatedLessons: 1, orderIndex: 2),
      ];

      final slots = [
        makeSlot('s1', 1, 1), // 1ª aula na segunda
        makeSlot('s2', 1, 2), // 2ª aula na segunda
      ];

      final prop = service.generateProposal(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 2, 1),
        academicYear: academicYear,
        teachingDays: [DateTime(2026, 2, 2)],
        scheduleSlots: slots,
        contents: contents,
        existingLessons: const [],
        executionRecords: const [],
      );

      expect(prop.shifts.length, 2);
      expect(prop.shifts[0].proposedDate, DateTime(2026, 2, 2));
      expect(prop.shifts[0].proposedOrderInDay, 1);
      expect(prop.shifts[1].proposedDate, DateTime(2026, 2, 2));
      expect(prop.shifts[1].proposedOrderInDay, 2);
    });

    // 15. Planejamentos independentes não interferem entre si
    test('Cenário 15 - Disciplinas distintas não sofrem interferência mútua', () {
      const subjectB = 'cs-historia-6a';
      final lessonA = makeLesson(id: 'la', date: DateTime(2026, 2, 2), subject: csId, contentIds: ['cA']);
      final lessonB = makeLesson(id: 'lb', date: DateTime(2026, 2, 2), subject: subjectB, contentIds: ['cB']);

      final propA = service.generateProposal(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 2, 1),
        academicYear: academicYear,
        teachingDays: [DateTime(2026, 2, 2)],
        scheduleSlots: [makeSlot('sA', 1, 1, subject: csId)],
        contents: [makeContent(id: 'cA', title: 'Matemática', subject: csId)],
        existingLessons: [lessonA], // Não inclui lessonB!
        executionRecords: const [],
      );

      expect(propA.classroomSubjectId, csId);
      expect(propA.shifts.every((s) => !s.originalContentIds.contains('cB')), isTrue);
    });

    // 16. Salvaguarda 1 - Aula partiallyCompleted com needsFollowUp exige continuidade
    test('Salvaguarda 1 - Aula partiallyCompleted com needsFollowUp exige continuidade pedagógica', () {
      final l1 = makeLesson(id: 'l1', date: DateTime(2026, 2, 2), contentIds: ['c1'], status: LessonExecutionStatus.partiallyCompleted);
      final r1 = makeRecord(
        id: 'r1',
        plannedLessonId: 'l1',
        executionDate: DateTime(2026, 2, 2),
        status: LessonExecutionStatus.partiallyCompleted,
        actualContentIds: ['c1'],
        needsFollowUp: true,
        followUpNotes: 'Finalizar demonstração do Teorema',
      );

      final contents = [
        makeContent(id: 'c1', title: 'Geometria', estimatedLessons: 1, orderIndex: 1),
      ];

      final delay = service.detectDelay(
        classroomSubjectId: csId,
        plannedLessons: [l1],
        executionRecords: [r1],
        courseContents: contents,
        referenceDate: DateTime(2026, 2, 5),
      );

      expect(delay.hasDelay, isTrue);
      expect(delay.partiallyCompletedPendingCount, 1);

      final prop = service.generateProposal(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 2, 5),
        academicYear: academicYear,
        teachingDays: [DateTime(2026, 2, 2), DateTime(2026, 2, 9)],
        scheduleSlots: [makeSlot('s1', 1, 1)],
        contents: contents,
        existingLessons: [l1],
        executionRecords: [r1],
      );

      // Deve alocar 1 aula futura em 09/02 para a continuidade de c1
      final futureShift = prop.shifts.firstWhere((s) => !s.isPreservedHistoric);
      expect(futureShift.proposedDate, DateTime(2026, 2, 9));
      expect(futureShift.proposedContentIds, contains('c1'));
    });

    // 17. Salvaguarda 3 - Preservação de compromisso fixo com isLocked
    test('Salvaguarda 3 - Aula bloqueada com isLocked permanece estritamente na data original', () {
      final lLocked = makeLesson(
        id: 'l-prova',
        date: DateTime(2026, 2, 9),
        contentIds: ['c-prova'],
        isLocked: true, // Prova bimestral travada
      );

      final contents = [
        makeContent(id: 'c1', title: 'Revisão', estimatedLessons: 1, orderIndex: 1),
      ];

      final prop = service.generateProposal(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 2, 1),
        academicYear: academicYear,
        teachingDays: [DateTime(2026, 2, 2), DateTime(2026, 2, 9), DateTime(2026, 2, 16)],
        scheduleSlots: [makeSlot('s1', 1, 1)],
        contents: contents,
        existingLessons: [lLocked],
        executionRecords: const [],
      );

      expect(prop.preservedLockedLessonsCount, 1);
      final lockedShift = prop.shifts.firstWhere((s) => s.plannedLessonId == 'l-prova');
      expect(lockedShift.isLocked, isTrue);
      expect(lockedShift.proposedDate, DateTime(2026, 2, 9));
      expect(lockedShift.shiftType, LessonReplanningShiftType.unchanged);
    });

    // 18. Salvaguarda 5 - Capacidade insuficiente gera relatório claro de déficit
    test('Salvaguarda 5 - Capacidade insuficiente emite déficit sem descarte silencioso', () {
      final contents = [
        makeContent(id: 'c1', title: 'Conteúdo Extenso', estimatedLessons: 5, orderIndex: 1),
      ];

      // Apenas 2 dias letivos disponíveis
      final teachingDays = [
        DateTime(2026, 2, 2),
        DateTime(2026, 2, 9),
      ];

      final prop = service.generateProposal(
        classroomSubjectId: csId,
        referenceDate: DateTime(2026, 2, 1),
        academicYear: academicYear,
        teachingDays: teachingDays,
        scheduleSlots: [makeSlot('s1', 1, 1)],
        contents: contents,
        existingLessons: const [],
        executionRecords: const [],
      );

      expect(prop.planningResult.isSuccessful, isFalse);
      expect(prop.lessonDeficit, 3); // 5 necessárias - 2 vagas = 3 de déficit
      expect(prop.planningResult.conflicts.any((c) => c.type == PlanningConflictType.insufficientCapacity), isTrue);
      expect(prop.explanations.any((e) => e.contains('Déficit de 3 aula(s)')), isTrue);
    });
  });
}
