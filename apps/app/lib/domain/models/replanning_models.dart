import 'package:app/domain/models/course_content.dart';
import 'package:app/domain/models/planning_engine_contracts.dart';

/// Tipo de alteração identificada no comparativo "Antes vs. Depois" de uma aula no replanejamento.
enum LessonReplanningShiftType {
  /// A aula manteve rigorosamente a mesma data letiva e os mesmos conteúdos curriculares.
  unchanged,

  /// A data letiva da aula foi reprogramada, mantendo o conteúdo curricular.
  rescheduledDate,

  /// A data letiva foi mantida, mas os conteúdos associados foram remanejados.
  reallocatedContent,

  /// Tanto a data letiva quanto os conteúdos foram reprogramados.
  rescheduledDateAndContent,

  /// Nova aula adicionada ao cronograma para comportar reposição pedagógica ou expansão de conteúdo.
  newlyAdded,

  /// Aula puramente prevista que foi liberada/removida do cronograma por cumprimento antecipado.
  removed,
}

/// Status categórico de viabilidade de conclusão curricular frente ao calendário letivo.
enum CurricularViabilityStatus {
  /// O planejamento é plenamente viável: a capacidade restante de vagas é maior que a demanda.
  viable,

  /// Viável apenas mediante ajustes: a demanda total excede a capacidade, mas a demanda dos
  /// conteúdos obrigatórios (essenciais) cabe nas vagas disponíveis.
  viableWithAdjustments,

  /// Em risco de insuficiência: a capacidade é exatamente igual à demanda (margem de segurança zero)
  /// ou muito estreita, vulnerável a qualquer imprevisto ou falta futura.
  atRisk,

  /// Comprovadamente inviável: mesmo priorizando conteúdos obrigatórios, a demanda curricular
  /// excede a quantidade de vagas disponíveis até o término do ano letivo.
  unfeasible,

  /// Situação indeterminada: dados insuficientes (ex: sem horários de grade cadastrados ou sem dias letivos).
  indeterminate;

  String get displayName {
    switch (this) {
      case CurricularViabilityStatus.viable:
        return 'Viável';
      case CurricularViabilityStatus.viableWithAdjustments:
        return 'Viável com Ajustes';
      case CurricularViabilityStatus.atRisk:
        return 'Em Risco';
      case CurricularViabilityStatus.unfeasible:
        return 'Inviável';
      case CurricularViabilityStatus.indeterminate:
        return 'Indeterminado';
    }
  }

  String get description {
    switch (this) {
      case CurricularViabilityStatus.viable:
        return 'A capacidade letiva restante é suficiente para atender a todos os conteúdos previstos.';
      case CurricularViabilityStatus.viableWithAdjustments:
        return 'A capacidade comporta os conteúdos obrigatórios, mas exigirá revisão ou adiantamento dos opcionais.';
      case CurricularViabilityStatus.atRisk:
        return 'A margem de segurança é nula. Qualquer aula perdida ou imprevisto criará déficit imediato.';
      case CurricularViabilityStatus.unfeasible:
        return 'A demanda curricular restante ultrapassa a capacidade de aulas até o término do ano letivo.';
      case CurricularViabilityStatus.indeterminate:
        return 'Não há informações suficientes de calendário ou grade horária para projetar a viabilidade.';
    }
  }
}

/// Diagnóstico de risco de não alocação integral de um conteúdo curricular específico.
class ContentViabilityRisk {
  const ContentViabilityRisk({
    required this.content,
    required this.requiredLessons,
    required this.allocatedLessons,
    required this.missingLessons,
    required this.isAtRisk,
    required this.riskReason,
    this.hasPrerequisiteRisk = false,
  });

  /// Conteúdo curricular analisado.
  final CourseContent content;

  /// Aulas necessárias restantes para atender integralmente ao conteúdo.
  final int requiredLessons;

  /// Aulas que puderam ser alocadas nas vagas disponíveis.
  final int allocatedLessons;

  /// Aulas faltantes que não couberam na capacidade (déficit deste conteúdo).
  final int missingLessons;

  /// Indica se o conteúdo está em risco de não ser concluído no período letivo.
  final bool isAtRisk;

  /// Motivo determinístico do risco ou da garantia de conclusão.
  final String riskReason;

  /// Indica se o risco decorre de pré-requisitos não concluídos ou bloqueados.
  final bool hasPrerequisiteRisk;
}

/// Análise determinística de capacidade e projeção de viabilidade curricular.
class CurricularCapacityAnalysis {
  const CurricularCapacityAnalysis({
    required this.classroomSubjectId,
    required this.referenceDate,
    required this.academicYearEndDate,
    required this.totalFutureAvailableSlots,
    required this.totalRemainingDemandLessons,
    required this.mandatoryRemainingDemandLessons,
    required this.optionalRemainingDemandLessons,
    required this.capacityDeficit,
    required this.mandatoryCapacityDeficit,
    required this.safetyMarginLessons,
    required this.viabilityStatus,
    required this.estimatedCompletionDate,
    required this.overflowsAcademicYear,
    required this.contentsAtRisk,
    required this.limitingConstraints,
    required this.summaryMessage,
  });

  /// Vínculo Turma-Disciplina analisado.
  final String classroomSubjectId;

  /// Data civil de referência utilizada no cálculo.
  final DateTime referenceDate;

  /// Data oficial de encerramento do Ano Letivo.
  final DateTime academicYearEndDate;

  /// Quantidade total de vagas de aula futuras válidas e livres até o término do ano letivo.
  final int totalFutureAvailableSlots;

  /// Quantidade total estimada de aulas necessárias para atender aos conteúdos pendentes.
  final int totalRemainingDemandLessons;

  /// Quantidade estimada de aulas necessárias exclusivamente para conteúdos obrigatórios.
  final int mandatoryRemainingDemandLessons;

  /// Quantidade estimada de aulas necessárias para conteúdos opcionais/complementares.
  final int optionalRemainingDemandLessons;

  /// Déficit total de capacidade (max(0, totalRemainingDemandLessons - totalFutureAvailableSlots)).
  final int capacityDeficit;

  /// Déficit de capacidade considerando apenas conteúdos obrigatórios.
  final int mandatoryCapacityDeficit;

  /// Margem de segurança de vagas excedentes (max(0, totalFutureAvailableSlots - totalRemainingDemandLessons)).
  final int safetyMarginLessons;

  /// Classificação categórica da viabilidade.
  final CurricularViabilityStatus viabilityStatus;

  /// Data prevista em que a última aula seria ministrada.
  final DateTime? estimatedCompletionDate;

  /// Indica se a demanda restante transborda a data final do calendário escolar.
  final bool overflowsAcademicYear;

  /// Lista de conteúdos curriculares que correm risco de não conclusão.
  final List<ContentViabilityRisk> contentsAtRisk;

  /// Restrições e limitações de calendário que impedem ou condicionam a conclusão.
  final List<String> limitingConstraints;

  /// Resumo didático e explicável para o professor.
  final String summaryMessage;

  /// Indica se todos os conteúdos obrigatórios podem ser concluídos no calendário vigente.
  bool get areMandatoryContentsFeasible => mandatoryCapacityDeficit == 0;
}

/// Análise do ritmo real de ensino com base nos apontamentos históricos do diário docente.
class TeachingPaceAnalysis {
  const TeachingPaceAnalysis({
    required this.totalStartedContents,
    required this.totalLessonsSpentOnStartedContents,
    required this.totalEstimatedLessonsForStartedContents,
    required this.observedPaceRatio,
    required this.hasSufficientHistoricalData,
    required this.projectedAdditionalLessonsIfPaceMaintained,
    required this.methodologyExplanation,
    required this.limitationsExplanation,
  });

  /// Quantidade de conteúdos com ao menos 1 aula apontada faticamente no diário.
  final int totalStartedContents;

  /// Total de aulas ministradas efetivamente para os conteúdos iniciados.
  final int totalLessonsSpentOnStartedContents;

  /// Total de aulas estimadas originalmente para os conteúdos iniciados.
  final int totalEstimatedLessonsForStartedContents;

  /// Fator de ritmo observado: aulas ministradas / aulas estimadas nos conteúdos iniciados.
  /// Ex: 1.5 indica que os conteúdos estão demandando 50% mais aulas do que o previsto.
  final double observedPaceRatio;

  /// Indica se há dados históricos com amostra pedagógica mínima (>= 1 conteúdo iniciado).
  final bool hasSufficientHistoricalData;

  /// Projeção determinística de aulas adicionais necessárias para os conteúdos pendentes
  /// se o ritmo observado persistir.
  final int projectedAdditionalLessonsIfPaceMaintained;

  /// Descrição clara da metodologia estatística utilizada.
  final String methodologyExplanation;

  /// Limitações explícitas (não prevê aprendizagem individual e depende de homogeneidade de conteúdo).
  final String limitationsExplanation;
}

/// Tipos de cenários de recuperação comparáveis pelo professor.
enum RecoveryScenarioType {
  /// Cenário A — Planejamento Atual (Linha de Base com estimativas vigentes).
  baseline,

  /// Cenário B — Capacidade Adicional (informa vagas extras necessárias para cobrir o déficit).
  additionalCapacity,

  /// Cenário C — Reorganização Curricular (Priorização estrita de conteúdos obrigatórios).
  essentialPriority,

  /// Cenário D — Revisão das Estimativas Pedagógicas (Simulação com durações informadas pelo professor).
  customEstimates;

  String get displayName {
    switch (this) {
      case RecoveryScenarioType.baseline:
        return 'Cenário A — Planejamento Vigente';
      case RecoveryScenarioType.additionalCapacity:
        return 'Cenário B — Capacidade Adicional';
      case RecoveryScenarioType.essentialPriority:
        return 'Cenário C — Priorização de Obrigatórios';
      case RecoveryScenarioType.customEstimates:
        return 'Cenário D — Estimativas Revisadas';
    }
  }
}

/// Cenário comparável de recuperação curricular para tomada de decisão docente.
class RecoveryScenario {
  const RecoveryScenario({
    required this.type,
    required this.title,
    required this.description,
    required this.hypothesis,
    required this.capacityAnalysis,
    required this.proposedAllocations,
    required this.extraLessonsNeeded,
    required this.unallocatedContentTitles,
    required this.canBeAppliedDirectly,
  });

  /// Categoria do cenário.
  final RecoveryScenarioType type;

  /// Título didático do cenário.
  final String title;

  /// Explicação do cenário.
  final String description;

  /// Hipóteses pedagógicas consideradas neste cenário.
  final String hypothesis;

  /// Análise de capacidade e viabilidade específica sob este cenário.
  final CurricularCapacityAnalysis capacityAnalysis;

  /// Alocações de aulas propostas sob este cenário.
  final List<PlannedLessonAllocation> proposedAllocations;

  /// Quantidade de aulas extras de reposição/reforço necessárias para zerar o déficit.
  final int extraLessonsNeeded;

  /// Títulos dos conteúdos que permaneceriam sem alocação integral neste cenário.
  final List<String> unallocatedContentTitles;

  /// Se o cenário pode ser diretamente homologado e gravado no banco de dados.
  final bool canBeAppliedDirectly;
}

/// Comparativo explicável entre o planejamento vigente e a reprogramação proposta para uma aula.
class LessonReplanningShift {
  const LessonReplanningShift({
    required this.plannedLessonId,
    required this.originalDate,
    required this.originalOrderInDay,
    required this.originalContentIds,
    required this.originalContentTitles,
    required this.proposedDate,
    required this.proposedOrderInDay,
    required this.proposedContentIds,
    required this.proposedContentTitles,
    required this.shiftType,
    required this.reason,
    this.isPreservedHistoric = false,
    this.isLocked = false,
  });

  /// Identificador estável da aula.
  final String plannedLessonId;

  /// Data letiva no planejamento vigente.
  final DateTime originalDate;

  /// Ordem da aula no dia no planejamento vigente.
  final int originalOrderInDay;

  /// IDs dos conteúdos no planejamento vigente.
  final List<String> originalContentIds;

  /// Títulos dos conteúdos no planejamento vigente.
  final List<String> originalContentTitles;

  /// Data letiva calculada na proposta de replanejamento.
  final DateTime proposedDate;

  /// Ordem da aula no dia na proposta de replanejamento.
  final int proposedOrderInDay;

  /// IDs dos conteúdos calculados na proposta.
  final List<String> proposedContentIds;

  /// Títulos dos conteúdos calculados na proposta.
  final List<String> proposedContentTitles;

  /// Classificação categórica da alteração.
  final LessonReplanningShiftType shiftType;

  /// Justificativa didática estruturada da mudança ou manutenção.
  final String reason;

  /// Indica se a aula é protegida por ser fato histórico já registrado no diário.
  final bool isPreservedHistoric;

  /// Indica se a aula é protegida por trava manual do professor (ex: avaliação).
  final bool isLocked;

  /// Indica se a aula sofreu algum deslocamento temporal de data.
  bool get hasDateChanged =>
      originalDate.year != proposedDate.year ||
      originalDate.month != proposedDate.month ||
      originalDate.day != proposedDate.day ||
      originalOrderInDay != proposedOrderInDay;

  /// Indica se houve alteração na lista de conteúdos alocados.
  bool get hasContentChanged {
    if (originalContentIds.length != proposedContentIds.length) return true;
    for (int i = 0; i < originalContentIds.length; i++) {
      if (originalContentIds[i] != proposedContentIds[i]) return true;
    }
    return false;
  }
}

/// Resultado determinístico da detecção de atrasos ou divergências no cronograma letivo.
class ScheduleDelayDetectionResult {
  const ScheduleDelayDetectionResult({
    required this.classroomSubjectId,
    required this.referenceDate,
    required this.hasDelay,
    required this.notHeldCount,
    required this.partiallyCompletedPendingCount,
    required this.pastUnrecordedCount,
    required this.delayedContentsCount,
    required this.delayReasons,
    required this.summaryMessage,
    this.capacityDeficit = 0,
    this.viabilityStatus = CurricularViabilityStatus.viable,
    this.hasCapacityDeficit = false,
  });

  /// Vínculo Turma-Disciplina analisado.
  final String classroomSubjectId;

  /// Data civil de referência utilizada no cálculo.
  final DateTime referenceDate;

  /// Indica se foi identificado atraso que demanda replanejamento das aulas futuras.
  final bool hasDelay;

  /// Quantidade de aulas passadas com apontamento fático de não realizada (`notHeld`).
  final int notHeldCount;

  /// Quantidade de aulas realizadas parcialmente com pendência de continuidade pedagógica (`needsFollowUp`).
  final int partiallyCompletedPendingCount;

  /// Quantidade de aulas em datas passadas que ainda não possuem registro no diário.
  final int pastUnrecordedCount;

  /// Quantidade de conteúdos curriculares com saldo restante de aulas em atraso.
  final int delayedContentsCount;

  /// Lista estruturada de motivos que justificam a detecção do atraso.
  final List<String> delayReasons;

  /// Mensagem didática explicativa consolidada.
  final String summaryMessage;

  /// Déficit de capacidade letiva restante em relação à demanda de conteúdos.
  final int capacityDeficit;

  /// Status projetado de viabilidade curricular.
  final CurricularViabilityStatus viabilityStatus;

  /// Indica se foi identificado déficit antecipado de capacidade curricular.
  final bool hasCapacityDeficit;
}

/// Proposta completa, determinística e auditável de replanejamento automático.
class ReplanningProposal {
  const ReplanningProposal({
    required this.classroomSubjectId,
    required this.generatedAt,
    required this.referenceDate,
    required this.sourcePlannedLessonIds,
    required this.sourceExecutionRecordIds,
    required this.planningResult,
    required this.shifts,
    required this.preservedHistoricLessonsCount,
    required this.preservedLockedLessonsCount,
    required this.affectedFutureLessonsCount,
    required this.unaffectedFutureLessonsCount,
    required this.isIdenticalToCurrentPlan,
    required this.explanations,
    this.capacityAnalysis,
    this.paceAnalysis,
    this.recoveryScenarios = const [],
  });

  /// Vínculo Turma-Disciplina objeto do replanejamento.
  final String classroomSubjectId;

  /// Timestamp da geração da proposta (utilizado para controle de concorrência e integridade).
  final DateTime generatedAt;

  /// Data civil de corte a partir da qual as aulas futuras foram recalculadas.
  final DateTime referenceDate;

  /// Conjunto dos IDs das aulas planejadas vigentes no momento do cálculo.
  final Set<String> sourcePlannedLessonIds;

  /// Conjunto dos IDs dos registros de execução fática no momento do cálculo.
  final Set<String> sourceExecutionRecordIds;

  /// Resultado do motor determinístico de planejamento com alocações e conflitos.
  final PlanningEngineResult planningResult;

  /// Comparativo explicável de cada aula ("Antes vs. Depois").
  final List<LessonReplanningShift> shifts;

  /// Quantidade de aulas com fatos históricos registrados preservadas intocadas.
  final int preservedHistoricLessonsCount;

  /// Quantidade de aulas bloqueadas preservadas intocadas.
  final int preservedLockedLessonsCount;

  /// Quantidade de aulas futuras que foram reprogramadas (data ou conteúdo).
  final int affectedFutureLessonsCount;

  /// Quantidade de aulas futuras que permaneceram idênticas.
  final int unaffectedFutureLessonsCount;

  /// Sinaliza se a proposta gerada é 100% idêntica ao cronograma vigente (sem alterações).
  final bool isIdenticalToCurrentPlan;

  /// Justificativas estruturadas do replanejamento para o professor.
  final List<String> explanations;

  /// Análise de capacidade e projeção de viabilidade curricular associada.
  final CurricularCapacityAnalysis? capacityAnalysis;

  /// Análise do ritmo real de ensino observada no histórico de execução.
  final TeachingPaceAnalysis? paceAnalysis;

  /// Cenários comparáveis de recuperação curricular.
  final List<RecoveryScenario> recoveryScenarios;

  /// Indica se há conflitos impeditivos fatais (não relacionados à capacidade).
  bool get hasFatalConflicts => planningResult.conflicts.any(
    (c) => c.type != PlanningConflictType.insufficientCapacity,
  );

  /// Déficit de aulas necessárias em relação à capacidade letiva restante.
  int get lessonDeficit => planningResult.lessonDeficit;
}

/// Exceção lançada quando se tenta homologar uma proposta de replanejamento gerada a partir
/// de um estado desatualizado da turma (ex: novos apontamentos foram lançados antes da homologação).
class OutdatedReplanningProposalException implements Exception {
  const OutdatedReplanningProposalException(this.message);

  final String message;

  @override
  String toString() => 'OutdatedReplanningProposalException: $message';
}
