import 'dart:math';

import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/models/course_content.dart';
import 'package:app/domain/models/lesson_execution_record.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/models/planning_engine_contracts.dart';
import 'package:app/domain/models/replanning_models.dart';
import 'package:app/domain/models/schedule_slot.dart';
import 'package:app/domain/services/planning_engine_service.dart';

/// Motor determinístico de replanejamento automático de aulas.
///
/// Responsável por:
/// 1. Analisar divergências fáticas entre o cronograma planejado e os registros do diário docente.
/// 2. Calcular o saldo pedagógico restante de cada conteúdo, respeitando aulas ministradas,
///    aulas parciais e continuidades pedagógicas (sem presumir conclusão indevida).
/// 3. Preservar sagradamente aulas com fatos históricos registrados e aulas travadas pelo professor.
/// 4. Replanejar deterministicamente as aulas futuras livres mantendo a ordenação curricular.
/// 5. Gerar comparativo explicável "Antes vs. Depois" para homologação pelo professor.
class ReplanningEngineService {
  const ReplanningEngineService({
    this.planningEngineService = const PlanningEngineService(),
  });

  final PlanningEngineService planningEngineService;

  /// Detecta deterministicamente a existência de atraso ou divergência fática no cronograma.
  ///
  /// Quando os parâmetros de calendário ([academicYear], [teachingDays] e [scheduleSlots]) são fornecidos,
  /// o método realiza também a verificação antecipada de déficit de capacidade curricular frente
  /// ao encerramento do ano letivo, mesmo que ainda não tenha ocorrido falta ou atraso passado.
  ScheduleDelayDetectionResult detectDelay({
    required String classroomSubjectId,
    required List<PlannedLesson> plannedLessons,
    required List<LessonExecutionRecord> executionRecords,
    required List<CourseContent> courseContents,
    required DateTime referenceDate,
    AcademicYear? academicYear,
    List<DateTime>? teachingDays,
    List<ScheduleSlot>? scheduleSlots,
  }) {
    final refCivil = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );

    final recordMap = {for (final r in executionRecords) r.plannedLessonId: r};

    var notHeldCount = 0;
    var partiallyCompletedPendingCount = 0;
    var pastUnrecordedCount = 0;
    final delayReasons = <String>[];

    // Mapeamento de contagem de aulas concluídas faticamente por conteúdo
    final completedCountPerContent = <String, int>{};
    final followUpContentIds = <String>{};

    for (final lesson in plannedLessons) {
      final lessonDateCivil = DateTime(
        lesson.date.year,
        lesson.date.month,
        lesson.date.day,
      );

      final record = recordMap[lesson.id];

      if (record != null) {
        if (record.status == LessonExecutionStatus.notHeld) {
          notHeldCount++;
          final reasonLabel =
              record.cancellationReason?.label ?? 'Motivo não informado';
          final formattedDate = _formatDate(lessonDateCivil);
          delayReasons.add(
            'Aula cancelada em $formattedDate ($reasonLabel). Conteúdo previsto não ministrado.',
          );
        } else if (record.status == LessonExecutionStatus.partiallyCompleted) {
          if (record.needsFollowUp) {
            partiallyCompletedPendingCount++;
            final formattedDate = _formatDate(lessonDateCivil);
            final notes = record.followUpNotes?.trim();
            final details = notes != null && notes.isNotEmpty
                ? ': \'$notes\''
                : '';
            delayReasons.add(
              'Aula de $formattedDate realizada parcialmente com continuidade pendente$details.',
            );
            followUpContentIds.addAll(record.actualContentIds);
          }
          // Aulas parciais não incrementam completedCountPerContent (salvaguarda 1)
        } else if (record.status == LessonExecutionStatus.completed) {
          for (final cid in record.actualContentIds.toSet()) {
            completedCountPerContent[cid] =
                (completedCountPerContent[cid] ?? 0) + 1;
          }
        }
      } else {
        // Aula sem registro formal de execução
        if (lessonDateCivil.isBefore(refCivil)) {
          pastUnrecordedCount++;
          final formattedDate = _formatDate(lessonDateCivil);
          delayReasons.add(
            'Aula de $formattedDate em data passada sem apontamento no diário.',
          );
        }
      }
    }

    // Verifica se algum conteúdo previsto até a data de corte está com déficit fático
    var delayedContentsCount = 0;
    for (final content in courseContents) {
      final completed = completedCountPerContent[content.id] ?? 0;
      final hasFollowUp = followUpContentIds.contains(content.id);

      // Aulas planejadas para este conteúdo até a data de referência
      final plannedPastForContent = plannedLessons.where((l) {
        final d = DateTime(l.date.year, l.date.month, l.date.day);
        return d.isBefore(refCivil) && l.contentIds.contains(content.id);
      }).length;

      if (plannedPastForContent > completed || hasFollowUp) {
        delayedContentsCount++;
      }
    }

    // Análise antecipada de capacidade se calendário e grade forem fornecidos
    var capacityDeficit = 0;
    var viabilityStatus = CurricularViabilityStatus.viable;
    var hasCapacityDeficit = false;

    if (academicYear != null && teachingDays != null && scheduleSlots != null) {
      final capacityAnalysis = analyzeCurricularCapacity(
        classroomSubjectId: classroomSubjectId,
        referenceDate: refCivil,
        academicYear: academicYear,
        teachingDays: teachingDays,
        scheduleSlots: scheduleSlots,
        contents: courseContents,
        existingLessons: plannedLessons,
        executionRecords: executionRecords,
      );

      capacityDeficit = capacityAnalysis.capacityDeficit;
      viabilityStatus = capacityAnalysis.viabilityStatus;

      if (capacityDeficit > 0) {
        hasCapacityDeficit = true;
        final endDateStr = _formatDate(academicYear.endDate);
        delayReasons.add(
          'Déficit de capacidade curricular antecipado: faltam $capacityDeficit aula(s) para cobrir a demanda até o encerramento do ano letivo ($endDateStr).',
        );
      } else if (viabilityStatus == CurricularViabilityStatus.atRisk) {
        delayReasons.add(
          'Alerta de risco curricular: a margem de segurança de vagas até o fim do ano é nula.',
        );
      }
    }

    final hasDelay =
        notHeldCount > 0 ||
        partiallyCompletedPendingCount > 0 ||
        delayedContentsCount > 0 ||
        pastUnrecordedCount > 0 ||
        hasCapacityDeficit;

    final String summary;
    if (!hasDelay) {
      summary = 'Cronograma em dia. Nenhuma divergência fática ou aula cancelada identificada.';
    } else {
      final parts = <String>[];
      if (notHeldCount > 0) parts.add('$notHeldCount aula(s) cancelada(s)');
      if (partiallyCompletedPendingCount > 0) {
        parts.add(
          '$partiallyCompletedPendingCount aula(s) com continuidade pendente',
        );
      }
      if (pastUnrecordedCount > 0) {
        parts.add('$pastUnrecordedCount aula(s) passada(s) sem registro');
      }
      if (hasCapacityDeficit) {
        parts.add('déficit curricular antecipado de $capacityDeficit aula(s)');
      }
      summary =
          'Atraso/Risco detectado no cronograma: ${parts.join(', ')}. Replanejamento recomendado.';
    }

    return ScheduleDelayDetectionResult(
      classroomSubjectId: classroomSubjectId,
      referenceDate: refCivil,
      hasDelay: hasDelay,
      notHeldCount: notHeldCount,
      partiallyCompletedPendingCount: partiallyCompletedPendingCount,
      pastUnrecordedCount: pastUnrecordedCount,
      delayedContentsCount: delayedContentsCount,
      delayReasons: delayReasons,
      summaryMessage: summary,
      capacityDeficit: capacityDeficit,
      viabilityStatus: viabilityStatus,
      hasCapacityDeficit: hasCapacityDeficit,
    );
  }

  /// Gera deterministicamente a proposta de replanejamento das aulas futuras.
  ReplanningProposal generateProposal({
    required String classroomSubjectId,
    required DateTime referenceDate,
    required AcademicYear academicYear,
    required List<DateTime> teachingDays,
    required List<ScheduleSlot> scheduleSlots,
    required List<CourseContent> contents,
    required List<PlannedLesson> existingLessons,
    required List<LessonExecutionRecord> executionRecords,
    Map<String, int>? customEstimatedLessonsPerContent,
    PlanningStrategy strategy = PlanningStrategy.pedagogicalSequence,
  }) {
    final refCivil = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );

    final recordMap = {for (final r in executionRecords) r.plannedLessonId: r};
    final contentTitleMap = {for (final c in contents) c.id: c.title};

    // Filtro estrito: considerar somente aulas da turma/disciplina em replanejamento
    final subjectExistingLessons = existingLessons
        .where((l) => l.classroomSubjectId == classroomSubjectId)
        .toList();

    // 1. Identificar aulas preservadas (históricas e bloqueadas)
    final preservedLessons = <PlannedLesson>[];
    final preservedIds = <String>{};
    final completedCountPerContent = <String, int>{};
    final followUpContentIds = <String>{};

    for (final lesson in subjectExistingLessons) {
      final record = recordMap[lesson.id];
      final isHistoric = record != null || lesson.hasExecutionRecord;
      final isLocked = lesson.isLocked;

      if (isHistoric || isLocked) {
        final preservedLesson =
            (record != null && lesson.status == LessonExecutionStatus.planned)
            ? lesson.copyWith(status: record.status)
            : lesson;
        preservedLessons.add(preservedLesson);
        preservedIds.add(lesson.id);

        if (record != null) {
          if (record.status == LessonExecutionStatus.completed) {
            for (final cid in record.actualContentIds.toSet()) {
              completedCountPerContent[cid] =
                  (completedCountPerContent[cid] ?? 0) + 1;
            }
          } else if (record.status ==
              LessonExecutionStatus.partiallyCompleted) {
            if (record.needsFollowUp) {
              followUpContentIds.addAll(record.actualContentIds);
            }
          }
        }
      }
    }

    // 2. Contabilização pedagógica precisa do saldo restante de conteúdos (Salvaguarda 1)
    final pendingContents = <CourseContent>[];
    final remainingLessonsPerContent = <String, int>{};

    for (final content in contents) {
      final customEst = customEstimatedLessonsPerContent?[content.id];
      final estimated = customEst ?? content.estimatedLessons;
      final completed = completedCountPerContent[content.id] ?? 0;
      var remaining = max(0, estimated - completed);

      // Se todas as aulas previstas foram ministradas, mas há solicitação de continuidade
      if (remaining == 0 && followUpContentIds.contains(content.id)) {
        remaining = 1; // 1 aula de consolidação pedagógica
      }

      remainingLessonsPerContent[content.id] = remaining;

      if (remaining > 0) {
        // Carga informada ao motor de planejamento:
        // Como o PlanningEngineService deduz de content.estimatedLessons a quantidade alreadyPreserved
        // (aulas concluídas e aulas bloqueadas), a carga informada deve ser: remaining + completed.
        // Assim: needed = max(0, (remaining + completed) - completed) = remaining.
        final effectiveEstimated = remaining + completed;
        pendingContents.add(
          content.copyWith(estimatedLessons: effectiveEstimated),
        );
      }
    }

    // 3. Montar a requisição para o PlanningEngineService
    final normalizedStart = DateTime(
      academicYear.startDate.year,
      academicYear.startDate.month,
      academicYear.startDate.day,
    );
    final normalizedEnd = DateTime(
      academicYear.endDate.year,
      academicYear.endDate.month,
      academicYear.endDate.day,
    );

    final engineRequest = PlanningEngineRequest(
      classroomSubjectId: classroomSubjectId,
      startDate: normalizedStart,
      endDate: normalizedEnd,
      teachingDays: teachingDays,
      scheduleSlots: scheduleSlots,
      contents: pendingContents,
      existingLessons: preservedLessons,
      strategy: strategy,
    );

    final planningResult = planningEngineService.generatePlan(engineRequest);

    // 4. Mapear o cronograma vigente para o comparativo "Antes vs. Depois"
    final sortedExisting = List<PlannedLesson>.from(subjectExistingLessons)
      ..sort((a, b) {
        final dComp = a.date.compareTo(b.date);
        if (dComp != 0) return dComp;
        return a.orderInDay.compareTo(b.orderInDay);
      });

    final sortedProposed =
        List<PlannedLessonAllocation>.from(planningResult.plannedLessons)
          ..sort((a, b) {
            final dComp = a.lesson.date.compareTo(b.lesson.date);
            if (dComp != 0) return dComp;
            return a.lesson.orderInDay.compareTo(b.lesson.orderInDay);
          });

    final shifts = <LessonReplanningShift>[];
    final explanations = <String>[];

    // Mapeamento das aulas existentes puramente planejadas
    final existingFuturePlanned = sortedExisting
        .where((l) => !preservedIds.contains(l.id))
        .toList();

    // Mapeamento das novas aulas propostas
    final proposedNewAllocations = sortedProposed
        .where((a) => !preservedIds.contains(a.lesson.id))
        .toList();

    var affectedCount = 0;
    var unaffectedCount = 0;

    // A) Processar aulas preservadas históricas e bloqueadas
    for (final lesson in preservedLessons) {
      final record = recordMap[lesson.id];
      final isHistoric = record != null || lesson.hasExecutionRecord;
      final titles = lesson.contentIds
          .map((id) => contentTitleMap[id] ?? id)
          .toList();

      final String reason;
      if (isHistoric) {
        final statusDesc = record?.status.name ?? lesson.status.name;
        reason = 'Preservada: registro histórico factual ($statusDesc).';
      } else {
        reason = 'Preservada: aula protegida por bloqueio manual.';
      }

      shifts.add(
        LessonReplanningShift(
          plannedLessonId: lesson.id,
          originalDate: lesson.date,
          originalOrderInDay: lesson.orderInDay,
          originalContentIds: lesson.contentIds,
          originalContentTitles: titles,
          proposedDate: lesson.date,
          proposedOrderInDay: lesson.orderInDay,
          proposedContentIds: lesson.contentIds,
          proposedContentTitles: titles,
          shiftType: LessonReplanningShiftType.unchanged,
          reason: reason,
          isPreservedHistoric: isHistoric,
          isLocked: lesson.isLocked,
        ),
      );
    }

    // B) Comparar aulas futuras (existentes vs. propostas)
    final maxFuture = max(
      existingFuturePlanned.length,
      proposedNewAllocations.length,
    );

    for (var i = 0; i < maxFuture; i++) {
      final oldLesson = i < existingFuturePlanned.length
          ? existingFuturePlanned[i]
          : null;
      final newAlloc = i < proposedNewAllocations.length
          ? proposedNewAllocations[i]
          : null;

      if (oldLesson != null && newAlloc != null) {
        final newLesson = newAlloc.lesson;
        final oldTitles = oldLesson.contentIds
            .map((id) => contentTitleMap[id] ?? id)
            .toList();
        final newTitles = newLesson.contentIds
            .map((id) => contentTitleMap[id] ?? id)
            .toList();

        final dateChanged =
            oldLesson.date.year != newLesson.date.year ||
            oldLesson.date.month != newLesson.date.month ||
            oldLesson.date.day != newLesson.date.day ||
            oldLesson.orderInDay != newLesson.orderInDay;

        final contentChanged = !_listsEqual(
          oldLesson.contentIds,
          newLesson.contentIds,
        );

        final LessonReplanningShiftType shiftType;
        final String reason;

        if (!dateChanged && !contentChanged) {
          shiftType = LessonReplanningShiftType.unchanged;
          reason = 'Aula mantida na data e sequência curricular originais.';
          unaffectedCount++;
        } else if (dateChanged && !contentChanged) {
          shiftType = LessonReplanningShiftType.rescheduledDate;
          final fromStr = _formatDate(oldLesson.date);
          final toStr = _formatDate(newLesson.date);
          reason =
              'Data reprogramada de $fromStr para $toStr devido ao remanejamento do calendário.';
          affectedCount++;
        } else if (!dateChanged && contentChanged) {
          shiftType = LessonReplanningShiftType.reallocatedContent;
          reason = 'Conteúdo atualizado para atender à sequência pedagógica de pré-requisitos.';
          affectedCount++;
        } else {
          shiftType = LessonReplanningShiftType.rescheduledDateAndContent;
          final fromStr = _formatDate(oldLesson.date);
          final toStr = _formatDate(newLesson.date);
          reason =
              'Data e conteúdo reprogramados ($fromStr -> $toStr) para acomodar reposição curricular.';
          affectedCount++;
        }

        shifts.add(
          LessonReplanningShift(
            plannedLessonId: newLesson.id,
            originalDate: oldLesson.date,
            originalOrderInDay: oldLesson.orderInDay,
            originalContentIds: oldLesson.contentIds,
            originalContentTitles: oldTitles,
            proposedDate: newLesson.date,
            proposedOrderInDay: newLesson.orderInDay,
            proposedContentIds: newLesson.contentIds,
            proposedContentTitles: newTitles,
            shiftType: shiftType,
            reason: reason,
          ),
        );
      } else if (oldLesson == null && newAlloc != null) {
        // Nova aula necessária
        final newLesson = newAlloc.lesson;
        final newTitles = newLesson.contentIds
            .map((id) => contentTitleMap[id] ?? id)
            .toList();
        final toStr = _formatDate(newLesson.date);

        affectedCount++;
        shifts.add(
          LessonReplanningShift(
            plannedLessonId: newLesson.id,
            originalDate: newLesson.date,
            originalOrderInDay: newLesson.orderInDay,
            originalContentIds: const [],
            originalContentTitles: const [],
            proposedDate: newLesson.date,
            proposedOrderInDay: newLesson.orderInDay,
            proposedContentIds: newLesson.contentIds,
            proposedContentTitles: newTitles,
            shiftType: LessonReplanningShiftType.newlyAdded,
            reason:
                'Nova aula adicionada em $toStr para cobrir reposição de conteúdo.',
          ),
        );
      } else if (oldLesson != null && newAlloc == null) {
        // Aula liberada
        final oldTitles = oldLesson.contentIds
            .map((id) => contentTitleMap[id] ?? id)
            .toList();
        final fromStr = _formatDate(oldLesson.date);

        affectedCount++;
        shifts.add(
          LessonReplanningShift(
            plannedLessonId: oldLesson.id,
            originalDate: oldLesson.date,
            originalOrderInDay: oldLesson.orderInDay,
            originalContentIds: oldLesson.contentIds,
            originalContentTitles: oldTitles,
            proposedDate: oldLesson.date,
            proposedOrderInDay: oldLesson.orderInDay,
            proposedContentIds: const [],
            proposedContentTitles: const [],
            shiftType: LessonReplanningShiftType.removed,
            reason:
                'Aula em $fromStr liberada: conteúdos curriculares já foram concluídos.',
          ),
        );
      }
    }

    // Ordenar shifts cronologicamente
    shifts.sort((a, b) {
      final dComp = a.proposedDate.compareTo(b.proposedDate);
      if (dComp != 0) return dComp;
      return a.proposedOrderInDay.compareTo(b.proposedOrderInDay);
    });

    // 5. Análise de Viabilidade Curricular, Ritmo de Ensino e Cenários de Recuperação
    final capacityAnalysis = analyzeCurricularCapacity(
      classroomSubjectId: classroomSubjectId,
      referenceDate: refCivil,
      academicYear: academicYear,
      teachingDays: teachingDays,
      scheduleSlots: scheduleSlots,
      contents: contents,
      existingLessons: existingLessons,
      executionRecords: executionRecords,
    );

    final paceAnalysis = analyzeTeachingPace(
      contents: contents,
      executionRecords: executionRecords,
      totalRemainingDemandLessons: capacityAnalysis.totalRemainingDemandLessons,
    );

    final recoveryScenarios = generateRecoveryScenarios(
      classroomSubjectId: classroomSubjectId,
      referenceDate: refCivil,
      academicYear: academicYear,
      teachingDays: teachingDays,
      scheduleSlots: scheduleSlots,
      contents: contents,
      existingLessons: existingLessons,
      executionRecords: executionRecords,
      strategy: strategy,
    );

    if (capacityAnalysis.capacityDeficit > 0) {
      explanations.add(
        'Alerta de Viabilidade: Déficit de ${capacityAnalysis.capacityDeficit} aula(s). O currículo completo transborda o término do ano letivo.',
      );
    } else if (capacityAnalysis.viabilityStatus ==
        CurricularViabilityStatus.atRisk) {
      explanations.add(
        'Atenção: Margem de segurança de vagas é zero. Qualquer nova falta gerará déficit.',
      );
    }

    final isIdentical = affectedCount == 0;

    if (isIdentical) {
      explanations.add(
        'Nenhuma alteração necessária: o cronograma vigente já atende integralmente à carga horária e ao progresso das aulas.',
      );
    } else {
      explanations.add(
        'Foram reprogramadas $affectedCount aula(s) futuras para absorver o atraso e garantir a cobertura curricular.',
      );
      if (planningResult.lessonDeficit > 0) {
        explanations.add(
          'Atenção: capacidade letiva insuficiente. Déficit de ${planningResult.lessonDeficit} aula(s).',
        );
      }
    }

    final sourcePlannedIds = subjectExistingLessons.map((l) => l.id).toSet();
    final sourceExecutionIds = executionRecords.map((r) => r.id).toSet();

    return ReplanningProposal(
      classroomSubjectId: classroomSubjectId,
      generatedAt: DateTime.now().toUtc(),
      referenceDate: refCivil,
      sourcePlannedLessonIds: sourcePlannedIds,
      sourceExecutionRecordIds: sourceExecutionIds,
      planningResult: planningResult,
      shifts: shifts,
      preservedHistoricLessonsCount: preservedLessons
          .where((l) => recordMap.containsKey(l.id) || l.hasExecutionRecord)
          .length,
      preservedLockedLessonsCount: preservedLessons
          .where((l) => l.isLocked && !recordMap.containsKey(l.id))
          .length,
      affectedFutureLessonsCount: affectedCount,
      unaffectedFutureLessonsCount: unaffectedCount,
      isIdenticalToCurrentPlan: isIdentical,
      explanations: explanations,
      capacityAnalysis: capacityAnalysis,
      paceAnalysis: paceAnalysis,
      recoveryScenarios: recoveryScenarios,
    );
  }

  /// Analisa deterministicamente a viabilidade curricular e a capacidade restante de aulas
  /// até o encerramento do ano letivo.
  CurricularCapacityAnalysis analyzeCurricularCapacity({
    required String classroomSubjectId,
    required DateTime referenceDate,
    required AcademicYear academicYear,
    required List<DateTime> teachingDays,
    required List<ScheduleSlot> scheduleSlots,
    required List<CourseContent> contents,
    required List<PlannedLesson> existingLessons,
    required List<LessonExecutionRecord> executionRecords,
    Map<String, int>? customEstimatedLessonsPerContent,
    bool onlyMandatory = false,
  }) {
    final refCivil = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    final normalizedStart = DateTime(
      academicYear.startDate.year,
      academicYear.startDate.month,
      academicYear.startDate.day,
    );
    final normalizedEnd = DateTime(
      academicYear.endDate.year,
      academicYear.endDate.month,
      academicYear.endDate.day,
    );

    // 1. Organizar horários semanais por dia da semana
    final slotsByWeekday = <int, List<int>>{};
    for (final slot in scheduleSlots) {
      slotsByWeekday.putIfAbsent(slot.weekday, () => []).add(slot.orderIndex);
    }
    for (final list in slotsByWeekday.values) {
      list.sort();
    }

    // 2. Mapear dias letivos válidos no intervalo do ano letivo
    final validTeachingDays =
        teachingDays
            .map((d) => DateTime(d.year, d.month, d.day))
            .where(
              (d) => !d.isBefore(normalizedStart) && !d.isAfter(normalizedEnd),
            )
            .toSet()
            .toList()
          ..sort();

    // 3. Gerar todas as vagas possíveis no calendário escolar
    final allSlots = <_LessonSlot>[];
    for (final day in validTeachingDays) {
      final orders = slotsByWeekday[day.weekday] ?? const [];
      for (final order in orders) {
        allSlots.add(_LessonSlot(date: day, orderInDay: order));
      }
    }
    allSlots.sort();

    // 4. Mapear slots ocupados por fatos históricos ou aulas bloqueadas
    final recordMap = {for (final r in executionRecords) r.plannedLessonId: r};
    final occupiedSlots = <_LessonSlot, PlannedLesson>{};
    final completedCountPerContent = <String, int>{};
    final followUpContentIds = <String>{};
    var lockedFutureLessonsCount = 0;

    final subjectExistingLessons = existingLessons
        .where((l) => l.classroomSubjectId == classroomSubjectId)
        .toList();

    for (final lesson in subjectExistingLessons) {
      final lessonDate = DateTime(
        lesson.date.year,
        lesson.date.month,
        lesson.date.day,
      );
      final record = recordMap[lesson.id];
      final isHistoric = record != null || lesson.hasExecutionRecord;
      final isLocked = lesson.isLocked;

      if (isHistoric || isLocked) {
        final slot = _LessonSlot(
          date: lessonDate,
          orderInDay: lesson.orderInDay,
        );
        occupiedSlots[slot] = lesson;

        if (isLocked && !lessonDate.isBefore(refCivil)) {
          lockedFutureLessonsCount++;
        }

        if (record != null) {
          if (record.status == LessonExecutionStatus.completed) {
            for (final cid in record.actualContentIds.toSet()) {
              completedCountPerContent[cid] =
                  (completedCountPerContent[cid] ?? 0) + 1;
            }
          } else if (record.status ==
              LessonExecutionStatus.partiallyCompleted) {
            if (record.needsFollowUp) {
              followUpContentIds.addAll(record.actualContentIds);
            }
          }
        }
      }
    }

    // 5. Vagas futuras válidas e livres (capacidade restante real)
    final futureAvailableSlots = allSlots
        .where(
          (s) => !s.date.isBefore(refCivil) && !occupiedSlots.containsKey(s),
        )
        .toList();
    final totalFutureAvailableSlots = futureAvailableSlots.length;

    // 6. Demanda pedagógica restante por conteúdo
    var totalRemainingDemand = 0;
    var mandatoryRemainingDemand = 0;
    var optionalRemainingDemand = 0;
    final neededPerContent = <String, int>{};

    for (final content in contents) {
      if (onlyMandatory && !content.isMandatory) {
        neededPerContent[content.id] = 0;
        continue;
      }

      final customEst = customEstimatedLessonsPerContent?[content.id];
      final estimated = customEst ?? content.estimatedLessons;
      final completed = completedCountPerContent[content.id] ?? 0;
      var remaining = max(0, estimated - completed);

      if (remaining == 0 && followUpContentIds.contains(content.id)) {
        remaining = 1;
      }

      neededPerContent[content.id] = remaining;
      totalRemainingDemand += remaining;
      if (content.isMandatory) {
        mandatoryRemainingDemand += remaining;
      } else {
        optionalRemainingDemand += remaining;
      }
    }

    // 7. Cálculos de Déficit e Margem de Segurança
    final capacityDeficit = max(
      0,
      totalRemainingDemand - totalFutureAvailableSlots,
    );
    final mandatoryCapacityDeficit = max(
      0,
      mandatoryRemainingDemand - totalFutureAvailableSlots,
    );
    final safetyMarginLessons = max(
      0,
      totalFutureAvailableSlots - totalRemainingDemand,
    );

    // 8. Classificação Categórica da Viabilidade
    final CurricularViabilityStatus viabilityStatus;
    if (scheduleSlots.isEmpty ||
        (validTeachingDays.isEmpty && totalRemainingDemand > 0)) {
      viabilityStatus = CurricularViabilityStatus.indeterminate;
    } else if (mandatoryCapacityDeficit > 0) {
      viabilityStatus = CurricularViabilityStatus.unfeasible;
    } else if (capacityDeficit > 0) {
      viabilityStatus = CurricularViabilityStatus.viableWithAdjustments;
    } else if (safetyMarginLessons == 0) {
      viabilityStatus = CurricularViabilityStatus.atRisk;
    } else {
      viabilityStatus = CurricularViabilityStatus.viable;
    }

    // 9. Projeção de Data de Término e Transbordo do Ano Letivo
    final DateTime? estimatedCompletionDate;
    final bool overflowsAcademicYear;

    if (totalRemainingDemand == 0) {
      estimatedCompletionDate = refCivil;
      overflowsAcademicYear = false;
    } else if (totalRemainingDemand <= totalFutureAvailableSlots) {
      estimatedCompletionDate =
          futureAvailableSlots[totalRemainingDemand - 1].date;
      overflowsAcademicYear = false;
    } else {
      // Capacidade insuficiente: data estimada transborda o término do ano letivo
      overflowsAcademicYear = true;
      final slotsPerWeek = max(1, scheduleSlots.length);
      final extraWeeks = (capacityDeficit / slotsPerWeek).ceil();
      estimatedCompletionDate = normalizedEnd.add(
        Duration(days: extraWeeks * 7),
      );
    }

    // 10. Mapeamento detalhado dos Conteúdos em Risco
    final sortedContents = _topologicalSort(contents);
    var slotPointer = 0;
    final contentsAtRisk = <ContentViabilityRisk>[];
    final riskByContentId = <String, bool>{};

    for (final content in sortedContents) {
      final needed = neededPerContent[content.id] ?? 0;
      final allocatable = min(
        needed,
        max(0, futureAvailableSlots.length - slotPointer),
      );
      slotPointer += allocatable;
      final missing = needed - allocatable;

      final hasPrereqRisk = content.prerequisiteIds.any(
        (pid) => riskByContentId[pid] == true,
      );

      final isAtRisk = missing > 0 || hasPrereqRisk;
      riskByContentId[content.id] = isAtRisk;

      final String riskReason;
      if (missing > 0) {
        riskReason =
            'Capacidade letiva esgotada: faltam $missing aula(s) para completar a estimativa de $needed aula(s).';
      } else if (hasPrereqRisk) {
        riskReason = 'Alocação comprometida: pré-requisito curricular em risco de não conclusão.';
      } else {
        riskReason = 'Alocação garantida nas vagas livres disponíveis.';
      }

      contentsAtRisk.add(
        ContentViabilityRisk(
          content: content,
          requiredLessons: needed,
          allocatedLessons: allocatable,
          missingLessons: missing,
          isAtRisk: isAtRisk,
          riskReason: riskReason,
          hasPrerequisiteRisk: hasPrereqRisk,
        ),
      );
    }

    // 11. Restrições e Limitações Estruturadas
    final limitingConstraints = <String>[];
    limitingConstraints.add(
      'Término oficial do ano letivo em ${_formatDate(normalizedEnd)}.',
    );
    limitingConstraints.add(
      '${scheduleSlots.length} aula(s) semanal(is) configurada(s) na grade.',
    );
    if (lockedFutureLessonsCount > 0) {
      limitingConstraints.add(
        '$lockedFutureLessonsCount aula(s) futura(s) travada(s) pelo professor para compromissos fixos.',
      );
    }
    if (capacityDeficit > 0) {
      limitingConstraints.add(
        'Déficit de $capacityDeficit aula(s) em relação às $totalFutureAvailableSlots vaga(s) livres restantes.',
      );
    } else if (safetyMarginLessons == 0) {
      limitingConstraints.add(
        'Margem de segurança nula (capacidade exatamente igual à demanda restante).',
      );
    } else {
      limitingConstraints.add(
        'Margem de segurança de $safetyMarginLessons aula(s) de folga no calendário.',
      );
    }

    // 12. Mensagem consolidada explicativa
    final String summary;
    switch (viabilityStatus) {
      case CurricularViabilityStatus.viable:
        summary =
            'Currículo viável. Restam $totalFutureAvailableSlots vaga(s) para uma demanda de $totalRemainingDemand aula(s) (margem de $safetyMarginLessons aula(s)). Conclusão estimada em ${_formatDate(estimatedCompletionDate)}.';
        break;
      case CurricularViabilityStatus.atRisk:
        summary =
            'Currículo em risco de insuficiência: margem de folga zero ($totalFutureAvailableSlots vaga(s) para $totalRemainingDemand aula(s)). Qualquer imprevisto criará déficit imediato.';
        break;
      case CurricularViabilityStatus.viableWithAdjustments:
        summary =
            'Viável com priorização: conteúdos obrigatórios cabem nas vagas disponíveis ($mandatoryRemainingDemand aula(s)), mas faltam $capacityDeficit aula(s) para conteúdos opcionais/complementares.';
        break;
      case CurricularViabilityStatus.unfeasible:
        summary =
            'Planejamento inviável: faltam $mandatoryCapacityDeficit aula(s) obrigatória(s) ($capacityDeficit no total). Conclusão estimada transborda o ano letivo para ${_formatDate(estimatedCompletionDate)}.';
        break;
      case CurricularViabilityStatus.indeterminate:
        summary = 'Não foi possível projetar a viabilidade: grade horária semanal ou calendário letivo insuficientes.';
        break;
    }

    return CurricularCapacityAnalysis(
      classroomSubjectId: classroomSubjectId,
      referenceDate: refCivil,
      academicYearEndDate: normalizedEnd,
      totalFutureAvailableSlots: totalFutureAvailableSlots,
      totalRemainingDemandLessons: totalRemainingDemand,
      mandatoryRemainingDemandLessons: mandatoryRemainingDemand,
      optionalRemainingDemandLessons: optionalRemainingDemand,
      capacityDeficit: capacityDeficit,
      mandatoryCapacityDeficit: mandatoryCapacityDeficit,
      safetyMarginLessons: safetyMarginLessons,
      viabilityStatus: viabilityStatus,
      estimatedCompletionDate: estimatedCompletionDate,
      overflowsAcademicYear: overflowsAcademicYear,
      contentsAtRisk: contentsAtRisk,
      limitingConstraints: limitingConstraints,
      summaryMessage: summary,
    );
  }

  /// Analisa o ritmo real de ensino com base nos apontamentos do diário docente.
  TeachingPaceAnalysis analyzeTeachingPace({
    required List<CourseContent> contents,
    required List<LessonExecutionRecord> executionRecords,
    required int totalRemainingDemandLessons,
  }) {
    final recordMap = <String, List<LessonExecutionRecord>>{};
    for (final record in executionRecords) {
      for (final cid in record.actualContentIds.toSet()) {
        recordMap.putIfAbsent(cid, () => []).add(record);
      }
    }

    var totalStarted = 0;
    var totalLessonsSpent = 0;
    var totalEstimated = 0;

    for (final content in contents) {
      final records = recordMap[content.id] ?? const [];
      final effectiveRecords = records
          .where(
            (r) =>
                r.status == LessonExecutionStatus.completed ||
                r.status == LessonExecutionStatus.partiallyCompleted,
          )
          .toList();

      if (effectiveRecords.isNotEmpty) {
        totalStarted++;
        totalLessonsSpent += effectiveRecords.length;
        totalEstimated += content.estimatedLessons;
      }
    }

    final bool hasData = totalStarted > 0 && totalEstimated > 0;
    final double paceRatio = hasData
        ? (totalLessonsSpent / totalEstimated)
        : 1.0;
    final int projectedAdditional = hasData && paceRatio > 1.0
        ? ((totalRemainingDemandLessons * (paceRatio - 1.0)).round())
        : 0;

    const methodology =
        'Compara as aulas efetivamente ministradas para conteúdos já iniciados '
        'com as respectivas durações estimadas originalmente. A razão observada '
        'é projetada proporcionalmente sobre os conteúdos pendentes.';

    const limitations =
        'Esta estimativa assume homogeneidade na complexidade dos conteúdos e não '
        'substitui a avaliação pedagógica individualizada do professor.';

    return TeachingPaceAnalysis(
      totalStartedContents: totalStarted,
      totalLessonsSpentOnStartedContents: totalLessonsSpent,
      totalEstimatedLessonsForStartedContents: totalEstimated,
      observedPaceRatio: paceRatio,
      hasSufficientHistoricalData: hasData,
      projectedAdditionalLessonsIfPaceMaintained: projectedAdditional,
      methodologyExplanation: methodology,
      limitationsExplanation: limitations,
    );
  }

  /// Gera cenários comparáveis de recuperação curricular para análise do professor.
  List<RecoveryScenario> generateRecoveryScenarios({
    required String classroomSubjectId,
    required DateTime referenceDate,
    required AcademicYear academicYear,
    required List<DateTime> teachingDays,
    required List<ScheduleSlot> scheduleSlots,
    required List<CourseContent> contents,
    required List<PlannedLesson> existingLessons,
    required List<LessonExecutionRecord> executionRecords,
    Map<String, int>? customEstimatedLessonsPerContent,
    PlanningStrategy strategy = PlanningStrategy.pedagogicalSequence,
  }) {
    final scenarios = <RecoveryScenario>[];

    // Cenário A — Planejamento Vigente
    final baselineCapacity = analyzeCurricularCapacity(
      classroomSubjectId: classroomSubjectId,
      referenceDate: referenceDate,
      academicYear: academicYear,
      teachingDays: teachingDays,
      scheduleSlots: scheduleSlots,
      contents: contents,
      existingLessons: existingLessons,
      executionRecords: executionRecords,
    );

    final baselineUnallocated = baselineCapacity.contentsAtRisk
        .where((r) => r.missingLessons > 0)
        .map((r) => r.content.title)
        .toList();

    scenarios.add(
      RecoveryScenario(
        type: RecoveryScenarioType.baseline,
        title: 'Cenário A — Planejamento Vigente',
        description: 'Distribui os conteúdos pendentes mantendo rigorosamente as estimativas pedagógicas atuais.',
        hypothesis: 'Considera o calendário escolar aprovado, a grade horária semanal e as estimativas originais sem alterações.',
        capacityAnalysis: baselineCapacity,
        proposedAllocations: const [],
        extraLessonsNeeded: baselineCapacity.capacityDeficit,
        unallocatedContentTitles: baselineUnallocated,
        canBeAppliedDirectly: true,
      ),
    );

    // Cenário B — Capacidade Adicional
    final additionalNeeded = baselineCapacity.capacityDeficit;
    final String addHypothesis;
    if (additionalNeeded > 0) {
      addHypothesis =
          'Adição de $additionalNeeded aula(s) de reforço/reposição em dias letivos extras ou contraturno escolar.';
    } else {
      addHypothesis = 'A capacidade atual já é suficiente. Não há necessidade de aulas extras.';
    }

    scenarios.add(
      RecoveryScenario(
        type: RecoveryScenarioType.additionalCapacity,
        title: 'Cenário B — Capacidade Adicional',
        description: 'Projeta o volume de aulas extras de reposição necessário para zerar o déficit curricular.',
        hypothesis: addHypothesis,
        capacityAnalysis: baselineCapacity,
        proposedAllocations: const [],
        extraLessonsNeeded: additionalNeeded,
        unallocatedContentTitles: const [],
        canBeAppliedDirectly: false,
      ),
    );

    // Cenário C — Priorização de Conteúdos Obrigatórios
    final essentialCapacity = analyzeCurricularCapacity(
      classroomSubjectId: classroomSubjectId,
      referenceDate: referenceDate,
      academicYear: academicYear,
      teachingDays: teachingDays,
      scheduleSlots: scheduleSlots,
      contents: contents,
      existingLessons: existingLessons,
      executionRecords: executionRecords,
      onlyMandatory: true,
    );

    final optionalUnallocated = contents
        .where((c) => !c.isMandatory)
        .map((c) => c.title)
        .toList();

    scenarios.add(
      RecoveryScenario(
        type: RecoveryScenarioType.essentialPriority,
        title: 'Cenário C — Priorização de Obrigatórios',
        description: 'Prioriza integralmente os conteúdos e habilidades essenciais, postergando itens opcionais e complementares.',
        hypothesis:
            'Garante o cumprimento dos conteúdos obrigatórios (${essentialCapacity.mandatoryRemainingDemandLessons} aula(s)) dentro das vagas letivas disponíveis.',
        capacityAnalysis: essentialCapacity,
        proposedAllocations: const [],
        extraLessonsNeeded: essentialCapacity.mandatoryCapacityDeficit,
        unallocatedContentTitles: optionalUnallocated,
        canBeAppliedDirectly: true,
      ),
    );

    // Cenário D — Revisão das Estimativas Pedagógicas
    if (customEstimatedLessonsPerContent != null &&
        customEstimatedLessonsPerContent.isNotEmpty) {
      final customCapacity = analyzeCurricularCapacity(
        classroomSubjectId: classroomSubjectId,
        referenceDate: referenceDate,
        academicYear: academicYear,
        teachingDays: teachingDays,
        scheduleSlots: scheduleSlots,
        contents: contents,
        existingLessons: existingLessons,
        executionRecords: executionRecords,
        customEstimatedLessonsPerContent: customEstimatedLessonsPerContent,
      );

      final customUnallocated = customCapacity.contentsAtRisk
          .where((r) => r.missingLessons > 0)
          .map((r) => r.content.title)
          .toList();

      scenarios.add(
        RecoveryScenario(
          type: RecoveryScenarioType.customEstimates,
          title: 'Cenário D — Estimativas Revisadas',
          description: 'Simula o impacto de durações pedagógicas revisadas e compactadas informadas pelo professor.',
          hypothesis: 'Aplica estimativas personalizadas sem alterar os registros permanentes até aprovação docente.',
          capacityAnalysis: customCapacity,
          proposedAllocations: const [],
          extraLessonsNeeded: customCapacity.capacityDeficit,
          unallocatedContentTitles: customUnallocated,
          canBeAppliedDirectly: true,
        ),
      );
    }

    return scenarios;
  }

  /// Ordenação topológica estrita para projeção e alocação.
  List<CourseContent> _topologicalSort(List<CourseContent> contents) {
    if (contents.isEmpty) return const [];
    final contentMap = {for (final c in contents) c.id: c};
    final inDegree = <String, int>{for (final c in contents) c.id: 0};
    final adjacency = <String, List<String>>{
      for (final c in contents) c.id: [],
    };

    for (final content in contents) {
      for (final prereqId in content.prerequisiteIds) {
        if (contentMap.containsKey(prereqId)) {
          adjacency[prereqId]!.add(content.id);
          inDegree[content.id] = (inDegree[content.id] ?? 0) + 1;
        }
      }
    }

    final available = contents.where((c) => inDegree[c.id] == 0).toList();
    final result = <CourseContent>[];

    while (available.isNotEmpty) {
      available.sort((a, b) {
        if (a.isMandatory != b.isMandatory) {
          return a.isMandatory ? -1 : 1;
        }
        final orderComp = a.orderIndex.compareTo(b.orderIndex);
        if (orderComp != 0) return orderComp;
        return a.title.compareTo(b.title);
      });

      final current = available.removeAt(0);
      result.add(current);

      for (final neighborId in adjacency[current.id] ?? const <String>[]) {
        inDegree[neighborId] = (inDegree[neighborId] ?? 1) - 1;
        if (inDegree[neighborId] == 0) {
          final neighbor = contentMap[neighborId];
          if (neighbor != null) {
            available.add(neighbor);
          }
        }
      }
    }

    if (result.length < contents.length) {
      final includedIds = result.map((c) => c.id).toSet();
      final remaining =
          contents.where((c) => !includedIds.contains(c.id)).toList()
            ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      result.addAll(remaining);
    }

    return result;
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString().padLeft(4, '0');
    return '$day/$month/$year';
  }
}

/// Representação interna de uma vaga de aula no calendário semanal da disciplina.
class _LessonSlot implements Comparable<_LessonSlot> {
  const _LessonSlot({required this.date, required this.orderInDay});

  final DateTime date;
  final int orderInDay;

  @override
  int compareTo(_LessonSlot other) {
    final dateComp = date.compareTo(other.date);
    if (dateComp != 0) return dateComp;
    return orderInDay.compareTo(other.orderInDay);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _LessonSlot &&
          other.date.year == date.year &&
          other.date.month == date.month &&
          other.date.day == date.day &&
          other.orderInDay == orderInDay;

  @override
  int get hashCode => Object.hash(date.year, date.month, date.day, orderInDay);
}
