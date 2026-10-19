import 'package:app/domain/models/classroom.dart';
import 'package:app/domain/models/planning_engine_contracts.dart';
import 'package:app/domain/models/replanning_models.dart';
import 'package:app/domain/repositories/academic_year_repository.dart';
import 'package:app/domain/repositories/calendar_event_repository.dart';
import 'package:app/domain/repositories/classroom_repository.dart';
import 'package:app/domain/repositories/course_content_repository.dart';
import 'package:app/domain/repositories/lesson_execution_repository.dart';
import 'package:app/domain/repositories/planned_lesson_repository.dart';
import 'package:app/domain/repositories/schedule_slot_repository.dart';
import 'package:app/domain/services/calendar_calculation_service.dart';
import 'package:app/domain/services/replanning_engine_service.dart';

/// Caso de uso responsável por calcular deterministicamente a proposta de replanejamento
/// para uma turma e disciplina, sem persistir nenhuma alteração diretamente no banco de dados.
class GenerateReplanningProposalUseCase {
  const GenerateReplanningProposalUseCase({
    required this.classroomRepository,
    required this.academicYearRepository,
    required this.calendarEventRepository,
    required this.calendarCalculationService,
    required this.scheduleSlotRepository,
    required this.courseContentRepository,
    required this.plannedLessonRepository,
    required this.lessonExecutionRepository,
    this.replanningEngineService = const ReplanningEngineService(),
    this.clock,
  });

  final ClassroomRepository classroomRepository;
  final AcademicYearRepository academicYearRepository;
  final CalendarEventRepository calendarEventRepository;
  final CalendarCalculationService calendarCalculationService;
  final ScheduleSlotRepository scheduleSlotRepository;
  final CourseContentRepository courseContentRepository;
  final PlannedLessonRepository plannedLessonRepository;
  final LessonExecutionRepository lessonExecutionRepository;
  final ReplanningEngineService replanningEngineService;
  final DateTime Function()? clock;

  /// Executa o cálculo da proposta de replanejamento.
  Future<ReplanningProposal> execute({
    required String classroomSubjectId,
    DateTime? referenceDate,
    Map<String, int>? customEstimatedLessonsPerContent,
    PlanningStrategy strategy = PlanningStrategy.pedagogicalSequence,
  }) async {
    // 1. Localizar Turma e Configuração Turma-Disciplina
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
      throw StateError(
        'Vínculo Turma-Disciplina com ID \'$classroomSubjectId\' não encontrado.',
      );
    }

    // 2. Carregar o Ano Letivo
    final academicYear = await academicYearRepository.findById(
      matchingClassroom.academicYearId,
    );

    if (academicYear == null) {
      throw StateError(
        'Ano Letivo com ID \'${matchingClassroom.academicYearId}\' não foi encontrado.',
      );
    }

    // 3. Carregar eventos de calendário e calcular dias letivos
    final events = await calendarEventRepository.getByAcademicYear(
      academicYear.id,
    );

    final calendarResult = calendarCalculationService.calculateTeachingDays(
      academicYear: academicYear,
      events: events,
    );

    // 4. Carregar grade semanal de horários
    final scheduleSlots = await scheduleSlotRepository.getByClassroomSubject(
      classroomSubjectId,
    );

    // 5. Carregar conteúdos cadastrados
    final contents = await courseContentRepository.getByClassroomSubject(
      classroomSubjectId,
    );

    // 6. Carregar aulas planejadas vigentes e registros de execução fáticos
    final existingLessons = await plannedLessonRepository.getByClassroomSubject(
      classroomSubjectId,
    );

    final executionRecords = await lessonExecutionRepository
        .getByClassroomSubject(classroomSubjectId);

    // 7. Determinar a data de corte de referência
    final refDate = referenceDate ?? (clock ?? DateTime.now)();

    // 8. Executar o motor de replanejamento
    return replanningEngineService.generateProposal(
      classroomSubjectId: classroomSubjectId,
      referenceDate: refDate,
      academicYear: academicYear,
      teachingDays: calendarResult.teachingDays,
      scheduleSlots: scheduleSlots,
      contents: contents,
      existingLessons: existingLessons,
      executionRecords: executionRecords,
      customEstimatedLessonsPerContent: customEstimatedLessonsPerContent,
      strategy: strategy,
    );
  }
}
