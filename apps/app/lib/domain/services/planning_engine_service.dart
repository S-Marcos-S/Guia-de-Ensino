import 'dart:math';

import 'package:app/domain/models/course_content.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/models/planning_engine_contracts.dart';
import 'package:app/domain/services/curriculum_integrity_service.dart';
import 'package:uuid/uuid.dart';

/// Assinatura para gerador de IDs de aulas planejadas.
typedef LessonIdGenerator = String Function(
  String classroomSubjectId,
  DateTime date,
  int orderInDay,
);

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

/// Motor determinístico responsável por distribuir conteúdos programáticos
/// nas datas reais de aula, respeitando calendário, grade horária, restrições
/// e preservando integralmente o histórico de aulas realizadas.
///
/// Não depende de widgets de interface, banco de dados ou IA.
class PlanningEngineService {
  const PlanningEngineService({
    this.curriculumIntegrityService = const CurriculumIntegrityService(),
    this.idGenerator,
  });

  final CurriculumIntegrityService curriculumIntegrityService;
  final LessonIdGenerator? idGenerator;

  static const _uuid = Uuid();

  /// Gera deterministicamente o planejamento de aulas para a turma e disciplina informadas.
  PlanningEngineResult generatePlan(PlanningEngineRequest request) {
    final conflicts = <PlanningConflict>[];
    final warnings = <String>[];

    // 1. Validação do intervalo de datas
    final normalizedStart = DateTime(
      request.startDate.year,
      request.startDate.month,
      request.startDate.day,
    );
    final normalizedEnd = DateTime(
      request.endDate.year,
      request.endDate.month,
      request.endDate.day,
    );

    if (normalizedStart.isAfter(normalizedEnd)) {
      conflicts.add(
        const PlanningConflict(
          type: PlanningConflictType.invalidConfiguration,
          message: 'A data de início do planejamento não pode ser posterior à data de término.',
        ),
      );
      return _buildFailedResult(request, conflicts, warnings);
    }

    // 2. Validação da grade semanal de horários
    if (request.scheduleSlots.isEmpty) {
      conflicts.add(
        const PlanningConflict(
          type: PlanningConflictType.scheduleMismatch,
          message: 'Não há horários semanais cadastrados para esta disciplina na turma.',
        ),
      );
      return _buildFailedResult(request, conflicts, warnings);
    }

    // Verifica se os slots possuem conflitos internos (mesmo dia e mesma ordem)
    final seenSlots = <String>{};
    for (final slot in request.scheduleSlots) {
      final key = '${slot.weekday}-${slot.orderIndex}';
      if (seenSlots.contains(key)) {
        conflicts.add(
          PlanningConflict(
            type: PlanningConflictType.scheduleMismatch,
            message:
                'A grade semanal contém horários duplicados para o dia ${slot.weekdayName}, aula ${slot.orderIndex}.',
          ),
        );
        return _buildFailedResult(request, conflicts, warnings);
      }
      seenSlots.add(key);
    }

    // 3. Validação de integridade curricular e dependências circulares
    try {
      curriculumIntegrityService.validateContents(request.contents);
    } on CircularDependencyException catch (e) {
      conflicts.add(
        PlanningConflict(
          type: PlanningConflictType.circularPrerequisite,
          message: e.message,
          affectedContentIds: e.cyclePath,
        ),
      );
      return _buildFailedResult(request, conflicts, warnings);
    } on CurriculumValidationException catch (e) {
      conflicts.add(
        PlanningConflict(
          type: PlanningConflictType.invalidConfiguration,
          message: e.message,
        ),
      );
      return _buildFailedResult(request, conflicts, warnings);
    }

    // 4. Mapeamento de slots por dia da semana (ordenados por orderIndex)
    final slotsByWeekday = <int, List<int>>{};
    for (final slot in request.scheduleSlots) {
      slotsByWeekday.putIfAbsent(slot.weekday, () => []).add(slot.orderIndex);
    }
    for (final list in slotsByWeekday.values) {
      list.sort();
    }

    // 5. Geração cronológica de todas as vagas de aula disponíveis
    // Filtra teachingDays dentro do intervalo normalizado
    final validTeachingDays =
        request.teachingDays
            .map((d) => DateTime(d.year, d.month, d.day))
            .where(
              (d) => !d.isBefore(normalizedStart) && !d.isAfter(normalizedEnd),
            )
            .toSet()
            .toList()
          ..sort();

    final allLessonSlots = <_LessonSlot>[];
    for (final day in validTeachingDays) {
      final orders = slotsByWeekday[day.weekday] ?? const [];
      for (final order in orders) {
        allLessonSlots.add(_LessonSlot(date: day, orderInDay: order));
      }
    }
    allLessonSlots.sort();

    final totalAvailableLessons = allLessonSlots.length;

    // 6. Separação e preservação sagrada de registros históricos e aulas bloqueadas
    final preservedLessons = <PlannedLesson>[];
    final occupiedSlots = <_LessonSlot, PlannedLesson>{};
    final preservedLessonAllocations = <PlannedLessonAllocation>[];
    final preservedLessonsPerContent = <String, int>{};
    final preservedDatesPerContent = <String, List<DateTime>>{};

    for (final existing in request.existingLessons) {
      if (existing.hasExecutionRecord || existing.isLocked) {
        final existingDate = DateTime(
          existing.date.year,
          existing.date.month,
          existing.date.day,
        );
        final slot = _LessonSlot(
          date: existingDate,
          orderInDay: existing.orderInDay,
        );

        if (occupiedSlots.containsKey(slot)) {
          conflicts.add(
            PlanningConflict(
              type: PlanningConflictType.historicalLessonConflict,
              message:
                  'Existe mais de uma aula histórica/bloqueada registrada para ${existing.date.day.toString().padLeft(2, '0')}/${existing.date.month.toString().padLeft(2, '0')}/${existing.date.year} na ordem ${existing.orderInDay}.',
              affectedDates: [existing.date],
            ),
          );
          return _buildFailedResult(request, conflicts, warnings);
        }

        occupiedSlots[slot] = existing;
        preservedLessons.add(existing);

        final reason = existing.hasExecutionRecord
            ? 'Aula com registro histórico de execução (${existing.status.name})'
            : 'Aula bloqueada pelo professor';

        preservedLessonAllocations.add(
          PlannedLessonAllocation(
            lesson: existing,
            contentIds: existing.contentIds,
            isPreservedFromHistory: true,
            explanation: reason,
          ),
        );

        final countsAsCovered =
            existing.status == LessonExecutionStatus.completed ||
            existing.isLocked;

        if (countsAsCovered) {
          for (final cid in existing.contentIds) {
            preservedLessonsPerContent[cid] =
                (preservedLessonsPerContent[cid] ?? 0) + 1;
            preservedDatesPerContent
                .putIfAbsent(cid, () => [])
                .add(existing.date);
          }
        }
      }
    }

    // 7. Determinação das vagas livres para novas aulas planejadas
    final freeSlots = allLessonSlots
        .where((slot) => !occupiedSlots.containsKey(slot))
        .toList();

    // 8. Ordenação topológica e determinística dos conteúdos
    final sortedContents = _topologicalSort(request.contents, request.strategy);

    // 9. Alocação sequencial dos conteúdos nas vagas livres
    final newAllocations = <PlannedLessonAllocation>[];
    final contentStatuses = <ContentAllocationStatus>[];
    var freeSlotIndex = 0;

    for (final content in sortedContents) {
      final required = content.estimatedLessons;
      final alreadyPreserved = preservedLessonsPerContent[content.id] ?? 0;
      final needed = max(0, required - alreadyPreserved);

      final allocatedDates = List<DateTime>.from(
        preservedDatesPerContent[content.id] ?? const [],
      );
      var allocatedForThisContent = alreadyPreserved;

      for (var i = 0; i < needed; i++) {
        if (freeSlotIndex < freeSlots.length) {
          final slot = freeSlots[freeSlotIndex++];
          final lessonId = idGenerator != null
              ? idGenerator!(
                  request.classroomSubjectId,
                  slot.date,
                  slot.orderInDay,
                )
              : _generateStableId(
                  request.classroomSubjectId,
                  slot.date,
                  slot.orderInDay,
                );

          final newLesson = PlannedLesson(
            id: lessonId,
            classroomSubjectId: request.classroomSubjectId,
            date: slot.date,
            orderInDay: slot.orderInDay,
            contentIds: [content.id],
            status: LessonExecutionStatus.planned,
            isLocked: false,
          );

          newAllocations.add(
            PlannedLessonAllocation(
              lesson: newLesson,
              contentIds: [content.id],
              isPreservedFromHistory: false,
              explanation:
                  'Alocada deterministicamente na sequência pedagógica para: "${content.title}".',
            ),
          );

          allocatedDates.add(slot.date);
          allocatedForThisContent++;
        } else {
          break;
        }
      }

      final isFullyAllocated = allocatedForThisContent >= required;
      final missing = required - allocatedForThisContent;

      String? reasonNotFullyAllocated;
      if (!isFullyAllocated) {
        reasonNotFullyAllocated =
            'Capacidade letiva esgotada: faltam $missing aula(s) para cobrir a estimativa de $required aula(s).';

        conflicts.add(
          PlanningConflict(
            type: PlanningConflictType.insufficientCapacity,
            message:
                'O conteúdo "${content.title}" (${content.isMandatory ? 'obrigatório' : 'opcional'}) necessita de $required aulas, mas apenas $allocatedForThisContent puderam ser alocadas.',
            affectedContentIds: [content.id],
            affectedDates: allocatedDates,
          ),
        );
      }

      contentStatuses.add(
        ContentAllocationStatus(
          content: content,
          allocatedLessons: allocatedForThisContent,
          requiredLessons: required,
          isFullyAllocated: isFullyAllocated,
          allocatedDates: allocatedDates,
          reasonNotFullyAllocated: reasonNotFullyAllocated,
        ),
      );
    }

    // 10. Alertas informativos adicionais
    final remainingFreeSlots = freeSlots.length - freeSlotIndex;
    if (remainingFreeSlots > 0) {
      warnings.add(
        'Restam $remainingFreeSlots aula(s) disponíveis no período letivo sem conteúdos associados.',
      );
    }

    if (totalAvailableLessons == 0 && request.contents.isNotEmpty) {
      conflicts.add(
        const PlanningConflict(
          type: PlanningConflictType.insufficientCapacity,
          message: 'Não há nenhuma aula letiva disponível no período selecionado para esta turma.',
        ),
      );
    }

    // 11. Consolidação e ordenação cronológica das aulas
    final allAllocations = [...preservedLessonAllocations, ...newAllocations]
      ..sort((a, b) {
        final dateComp = a.lesson.date.compareTo(b.lesson.date);
        if (dateComp != 0) return dateComp;
        return a.lesson.orderInDay.compareTo(b.lesson.orderInDay);
      });

    final usedLessons = allAllocations.length;
    final isSuccessful = conflicts.isEmpty;

    return PlanningEngineResult(
      classroomSubjectId: request.classroomSubjectId,
      isSuccessful: isSuccessful,
      plannedLessons: allAllocations,
      preservedLessons: preservedLessons,
      contentAllocations: contentStatuses,
      availableLessonOccurrences: totalAvailableLessons,
      usedLessonOccurrences: usedLessons,
      conflicts: conflicts,
      warnings: warnings,
    );
  }

  /// Ordenação topológica estrita com critérios determinísticos de desempate.
  List<CourseContent> _topologicalSort(
    List<CourseContent> contents,
    PlanningStrategy strategy,
  ) {
    if (contents.isEmpty) return const [];

    final contentMap = {for (final c in contents) c.id: c};
    final inDegree = <String, int>{for (final c in contents) c.id: 0};
    final dependents = <String, List<String>>{
      for (final c in contents) c.id: [],
    };

    for (final c in contents) {
      for (final prereqId in c.prerequisiteIds) {
        if (contentMap.containsKey(prereqId)) {
          dependents[prereqId]!.add(c.id);
          inDegree[c.id] = (inDegree[c.id] ?? 0) + 1;
        }
      }
    }

    int compareTieBreak(CourseContent a, CourseContent b) {
      if (strategy == PlanningStrategy.mandatoryFirst) {
        if (a.isMandatory != b.isMandatory) {
          return a.isMandatory ? -1 : 1;
        }
        final orderComp = a.orderIndex.compareTo(b.orderIndex);
        if (orderComp != 0) return orderComp;
        return a.id.compareTo(b.id);
      } else {
        // pedagogicalSequence
        final orderComp = a.orderIndex.compareTo(b.orderIndex);
        if (orderComp != 0) return orderComp;
        if (a.isMandatory != b.isMandatory) {
          return a.isMandatory ? -1 : 1;
        }
        return a.id.compareTo(b.id);
      }
    }

    final availableNodes =
        contents.where((c) => (inDegree[c.id] ?? 0) == 0).toList()
          ..sort(compareTieBreak);

    final sortedResult = <CourseContent>[];

    while (availableNodes.isNotEmpty) {
      final current = availableNodes.removeAt(0);
      sortedResult.add(current);

      final nextNodes = dependents[current.id] ?? const [];
      for (final depId in nextNodes) {
        final currentDeg = inDegree[depId]! - 1;
        inDegree[depId] = currentDeg;
        if (currentDeg == 0) {
          final depContent = contentMap[depId]!;
          availableNodes.add(depContent);
        }
      }
      availableNodes.sort(compareTieBreak);
    }

    return sortedResult;
  }

  /// Gera um UUID v5 estável e determinístico baseado na turma/disciplina, data e ordem da aula.
  String _generateStableId(
    String classroomSubjectId,
    DateTime date,
    int orderInDay,
  ) {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final name = '${classroomSubjectId}_${dateStr}_$orderInDay';
    return _uuid.v5(Namespace.url.value, name);
  }

  PlanningEngineResult _buildFailedResult(
    PlanningEngineRequest request,
    List<PlanningConflict> conflicts,
    List<String> warnings,
  ) {
    return PlanningEngineResult(
      classroomSubjectId: request.classroomSubjectId,
      isSuccessful: false,
      plannedLessons: const [],
      preservedLessons: const [],
      contentAllocations: const [],
      availableLessonOccurrences: 0,
      usedLessonOccurrences: 0,
      conflicts: conflicts,
      warnings: warnings,
    );
  }
}
