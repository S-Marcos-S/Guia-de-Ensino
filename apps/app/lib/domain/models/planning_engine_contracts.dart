import 'course_content.dart';
import 'planned_lesson.dart';
import 'schedule_slot.dart';

/// Política ou critério de priorização para o motor de planejamento.
enum PlanningStrategy {
  /// Segue estritamente a ordem pedagógica e os pré-requisitos cadastrados
  pedagogicalSequence,

  /// Prioriza conteúdos obrigatórios antes dos opcionais
  mandatoryFirst,
}

/// Parâmetros de entrada completos para o Motor Determinístico de Planejamento.
class PlanningEngineRequest {
  const PlanningEngineRequest({
    required this.classroomSubjectId,
    required this.startDate,
    required this.endDate,
    required this.teachingDays,
    required this.scheduleSlots,
    required this.contents,
    this.existingLessons = const [],
    this.strategy = PlanningStrategy.pedagogicalSequence,
  });

  /// Identificador do vínculo Turma-Disciplina
  final String classroomSubjectId;

  /// Data inicial do período de planejamento
  final DateTime startDate;

  /// Data final do período de planejamento
  final DateTime endDate;

  /// Lista ordenada de datas letivas válidas (calculadas sem finais de semana nem feriados que cancelam aulas)
  final List<DateTime> teachingDays;

  /// Slots de horários semanais da disciplina na turma
  final List<ScheduleSlot> scheduleSlots;

  /// Conteúdos programáticos a serem alocados
  final List<CourseContent> contents;

  /// Aulas existentes e registros históricos já gravados
  final List<PlannedLesson> existingLessons;

  /// Estratégia de priorização
  final PlanningStrategy strategy;
}

/// Alocação de uma aula planejada para um ou mais conteúdos.
class PlannedLessonAllocation {
  const PlannedLessonAllocation({
    required this.lesson,
    required this.contentIds,
    required this.isPreservedFromHistory,
    this.explanation,
  });

  final PlannedLesson lesson;
  final List<String> contentIds;
  final bool isPreservedFromHistory;
  final String? explanation;
}

/// Status de alocação de um conteúdo no plano gerado.
class ContentAllocationStatus {
  const ContentAllocationStatus({
    required this.content,
    required this.allocatedLessons,
    required this.requiredLessons,
    required this.isFullyAllocated,
    this.allocatedDates = const [],
    this.reasonNotFullyAllocated,
  });

  final CourseContent content;
  final int allocatedLessons;
  final int requiredLessons;
  final bool isFullyAllocated;
  final List<DateTime> allocatedDates;
  final String? reasonNotFullyAllocated;
}

/// Tipo de conflito detectado pelo motor determinístico.
enum PlanningConflictType {
  invalidConfiguration,
  scheduleMismatch,
  circularPrerequisite,
  insufficientCapacity,
  historicalLessonConflict,
}

/// Representação estruturada de conflito ou aviso que requer decisão do professor.
class PlanningConflict {
  const PlanningConflict({
    required this.type,
    required this.message,
    this.affectedContentIds = const [],
    this.affectedDates = const [],
  });

  final PlanningConflictType type;
  final String message;
  final List<String> affectedContentIds;
  final List<DateTime> affectedDates;

  @override
  String toString() => 'PlanningConflict($type: $message)';
}

/// Resultado completo, estruturado e explicável gerado pelo Motor de Planejamento.
class PlanningEngineResult {
  const PlanningEngineResult({
    required this.classroomSubjectId,
    required this.isSuccessful,
    required this.plannedLessons,
    required this.preservedLessons,
    required this.contentAllocations,
    required this.availableLessonOccurrences,
    required this.usedLessonOccurrences,
    required this.conflicts,
    required this.warnings,
  });

  final String classroomSubjectId;

  /// Indica se o planejamento foi gerado sem conflitos impeditivos
  final bool isSuccessful;

  /// Todas as aulas resultantes (novas e preservadas)
  final List<PlannedLessonAllocation> plannedLessons;

  /// Aulas históricas/bloqueadas que foram estritamente preservadas
  final List<PlannedLesson> preservedLessons;

  /// Detalhamento de cada conteúdo e suas ocorrências reservadas
  final List<ContentAllocationStatus> contentAllocations;

  /// Total de ocorrências de aula da disciplina possíveis no calendário
  final int availableLessonOccurrences;

  /// Total de ocorrências de aula consumidas pelo plano
  final int usedLessonOccurrences;

  /// Conflitos críticos que impedem aplicação direta ou geram déficit
  final List<PlanningConflict> conflicts;

  /// Alertas informativos para revisão do professor
  final List<String> warnings;

  /// Conteúdos completamente alocados
  List<ContentAllocationStatus> get fullyAllocatedContents =>
      contentAllocations.where((c) => c.isFullyAllocated).toList();

  /// Conteúdos não alocados ou parcialmente alocados
  List<ContentAllocationStatus> get unallocatedContents =>
      contentAllocations.where((c) => !c.isFullyAllocated).toList();

  /// Déficit de aulas necessárias em relação à capacidade disponível
  int get lessonDeficit {
    final needed = contentAllocations.fold<int>(
      0,
      (sum, c) => sum + c.requiredLessons,
    );
    final diff = needed - availableLessonOccurrences;
    return diff > 0 ? diff : 0;
  }
}
