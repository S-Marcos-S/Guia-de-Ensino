import 'package:app/domain/models/classroom.dart';
import 'package:app/domain/models/planning_engine_contracts.dart';
import 'package:app/domain/repositories/academic_year_repository.dart';
import 'package:app/domain/repositories/calendar_event_repository.dart';
import 'package:app/domain/repositories/classroom_repository.dart';
import 'package:app/domain/repositories/course_content_repository.dart';
import 'package:app/domain/repositories/planned_lesson_repository.dart';
import 'package:app/domain/repositories/schedule_slot_repository.dart';
import 'package:app/domain/services/calendar_calculation_service.dart';
import 'package:app/domain/services/planning_engine_service.dart';

/// Caso de uso responsável por orquestrar o Motor Determinístico de Planejamento,
/// agregando calendário letivo, grade semanal, conteúdos e histórico escolar,
/// e permitindo a aplicação e persistência segura do plano homologado.
class GenerateSchedulePlanUseCase {
  const GenerateSchedulePlanUseCase({
    required this.planningEngineService,
    required this.calendarCalculationService,
    required this.academicYearRepository,
    required this.classroomRepository,
    required this.calendarEventRepository,
    required this.scheduleSlotRepository,
    required this.courseContentRepository,
    required this.plannedLessonRepository,
  });

  final PlanningEngineService planningEngineService;
  final CalendarCalculationService calendarCalculationService;
  final AcademicYearRepository academicYearRepository;
  final ClassroomRepository classroomRepository;
  final CalendarEventRepository calendarEventRepository;
  final ScheduleSlotRepository scheduleSlotRepository;
  final CourseContentRepository courseContentRepository;
  final PlannedLessonRepository plannedLessonRepository;

  /// Executa o cálculo determinístico de planejamento e retorna a proposta explicável
  /// sem alterar diretamente o banco de dados (para revisão e homologação prévia).
  Future<PlanningEngineResult> execute({
    required String classroomSubjectId,
    DateTime? startDate,
    DateTime? endDate,
    PlanningStrategy strategy = PlanningStrategy.pedagogicalSequence,
  }) async {
    // 1. Identificar a Turma e a Configuração Turma-Disciplina
    final allClassrooms = await classroomRepository.getAll();
    Classroom? matchingClassroom;
    ClassroomSubjectConfig? matchingConfig;

    for (final classroom in allClassrooms) {
      for (final config in classroom.subjectConfigs) {
        if (config.id == classroomSubjectId) {
          matchingClassroom = classroom;
          matchingConfig = config;
          break;
        }
      }
      if (matchingClassroom != null) break;
    }

    if (matchingClassroom == null || matchingConfig == null) {
      return PlanningEngineResult(
        classroomSubjectId: classroomSubjectId,
        isSuccessful: false,
        plannedLessons: const [],
        preservedLessons: const [],
        contentAllocations: const [],
        availableLessonOccurrences: 0,
        usedLessonOccurrences: 0,
        conflicts: [
          const PlanningConflict(
            type: PlanningConflictType.invalidConfiguration,
            message: 'Vínculo Turma-Disciplina não encontrado no sistema.',
          ),
        ],
        warnings: const [],
      );
    }

    // 2. Carregar o Ano Letivo correspondente
    final academicYear = await academicYearRepository.findById(
      matchingClassroom.academicYearId,
    );

    if (academicYear == null) {
      return PlanningEngineResult(
        classroomSubjectId: classroomSubjectId,
        isSuccessful: false,
        plannedLessons: const [],
        preservedLessons: const [],
        contentAllocations: const [],
        availableLessonOccurrences: 0,
        usedLessonOccurrences: 0,
        conflicts: [
          const PlanningConflict(
            type: PlanningConflictType.invalidConfiguration,
            message: 'Ano Letivo associado à turma não foi encontrado.',
          ),
        ],
        warnings: const [],
      );
    }

    // 3. Carregar eventos de calendário e calcular datas letivas
    final events = await calendarEventRepository.getByAcademicYear(
      academicYear.id,
    );

    final calendarResult = calendarCalculationService.calculateTeachingDays(
      academicYear: academicYear,
      events: events,
    );

    // 4. Carregar slots de horário semanais
    final scheduleSlots = await scheduleSlotRepository.getByClassroomSubject(
      classroomSubjectId,
    );

    // 5. Carregar conteúdos cadastrados
    final contents = await courseContentRepository.getByClassroomSubject(
      classroomSubjectId,
    );

    // 6. Carregar aulas já existentes no banco
    final existingLessons = await plannedLessonRepository.getByClassroomSubject(
      classroomSubjectId,
    );

    // 7. Montar a requisição e executar o motor determinístico
    final effectiveStart = startDate ?? academicYear.startDate;
    final effectiveEnd = endDate ?? academicYear.endDate;

    final request = PlanningEngineRequest(
      classroomSubjectId: classroomSubjectId,
      startDate: effectiveStart,
      endDate: effectiveEnd,
      teachingDays: calendarResult.teachingDays,
      scheduleSlots: scheduleSlots,
      contents: contents,
      existingLessons: existingLessons,
      strategy: strategy,
    );

    return planningEngineService.generatePlan(request);
  }

  /// Aplica a proposta de planejamento no banco de dados de forma transacional e segura.
  /// Preserva integralmente qualquer aula com histórico de execução ou bloqueada.
  Future<void> applyPlan(PlanningEngineResult result) async {
    // 1. Não permite aplicar planos com conflitos impeditivos
    final fatalConflicts = result.conflicts
        .where((c) => c.type != PlanningConflictType.insufficientCapacity)
        .toList();

    if (fatalConflicts.isNotEmpty) {
      throw StateError(
        'Não é possível aplicar um plano com conflitos bloqueantes: ${fatalConflicts.map((c) => c.message).join('; ')}',
      );
    }

    // 2. Busca aulas existentes no banco
    final existingLessons = await plannedLessonRepository.getByClassroomSubject(
      result.classroomSubjectId,
    );

    // 3. Localiza aulas antigas puramente planejadas que não são históricas nem bloqueadas
    final newLessonIds = result.plannedLessons.map((l) => l.lesson.id).toSet();

    for (final oldLesson in existingLessons) {
      if (!oldLesson.hasExecutionRecord && !oldLesson.isLocked) {
        // Se a aula antiga não faz parte do novo plano, exclui com segurança
        if (!newLessonIds.contains(oldLesson.id)) {
          await plannedLessonRepository.delete(oldLesson.id);
        }
      }
    }

    // 4. Persiste todas as aulas do plano (novas e preservadas atualizadas)
    final lessonsToSave = result.plannedLessons.map((a) => a.lesson).toList();
    await plannedLessonRepository.saveAll(lessonsToSave);
  }
}
