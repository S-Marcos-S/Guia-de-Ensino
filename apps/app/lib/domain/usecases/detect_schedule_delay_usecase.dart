import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/models/classroom.dart';
import 'package:app/domain/models/replanning_models.dart';
import 'package:app/domain/models/schedule_slot.dart';
import 'package:app/domain/repositories/academic_year_repository.dart';
import 'package:app/domain/repositories/calendar_event_repository.dart';
import 'package:app/domain/repositories/classroom_repository.dart';
import 'package:app/domain/repositories/course_content_repository.dart';
import 'package:app/domain/repositories/lesson_execution_repository.dart';
import 'package:app/domain/repositories/planned_lesson_repository.dart';
import 'package:app/domain/repositories/schedule_slot_repository.dart';
import 'package:app/domain/services/calendar_calculation_service.dart';
import 'package:app/domain/services/replanning_engine_service.dart';

/// Caso de uso para detectar deterministicamente se uma disciplina na turma
/// possui atrasos, divergências fáticas ou déficit antecipado de capacidade curricular.
class DetectScheduleDelayUseCase {
  const DetectScheduleDelayUseCase({
    required this.plannedLessonRepository,
    required this.lessonExecutionRepository,
    required this.courseContentRepository,
    this.classroomRepository,
    this.academicYearRepository,
    this.calendarEventRepository,
    this.calendarCalculationService = const CalendarCalculationService(),
    this.scheduleSlotRepository,
    this.replanningEngineService = const ReplanningEngineService(),
    this.clock,
  });

  final PlannedLessonRepository plannedLessonRepository;
  final LessonExecutionRepository lessonExecutionRepository;
  final CourseContentRepository courseContentRepository;
  final ClassroomRepository? classroomRepository;
  final AcademicYearRepository? academicYearRepository;
  final CalendarEventRepository? calendarEventRepository;
  final CalendarCalculationService calendarCalculationService;
  final ScheduleSlotRepository? scheduleSlotRepository;
  final ReplanningEngineService replanningEngineService;
  final DateTime Function()? clock;

  /// Executa a detecção de atraso e viabilidade para o vínculo Turma-Disciplina informado.
  Future<ScheduleDelayDetectionResult> execute({
    required String classroomSubjectId,
    DateTime? referenceDate,
  }) async {
    final plannedLessons = await plannedLessonRepository.getByClassroomSubject(
      classroomSubjectId,
    );

    final executionRecords = await lessonExecutionRepository
        .getByClassroomSubject(classroomSubjectId);

    final courseContents = await courseContentRepository.getByClassroomSubject(
      classroomSubjectId,
    );

    final refDate = referenceDate ?? (clock ?? DateTime.now)();

    AcademicYear? academicYear;
    List<DateTime>? teachingDays;
    List<ScheduleSlot>? scheduleSlots;

    if (classroomRepository != null &&
        academicYearRepository != null &&
        calendarEventRepository != null &&
        scheduleSlotRepository != null) {
      final allClassrooms = await classroomRepository!.getAll();
      Classroom? matchingClassroom;

      for (final classroom in allClassrooms) {
        if (classroom.subjectConfigs.any((c) => c.id == classroomSubjectId)) {
          matchingClassroom = classroom;
          break;
        }
      }

      if (matchingClassroom != null) {
        academicYear = await academicYearRepository!.findById(
          matchingClassroom.academicYearId,
        );

        if (academicYear != null) {
          final events = await calendarEventRepository!.getByAcademicYear(
            academicYear.id,
          );
          final calendarResult = calendarCalculationService
              .calculateTeachingDays(
                academicYear: academicYear,
                events: events,
              );
          teachingDays = calendarResult.teachingDays;

          scheduleSlots = await scheduleSlotRepository!.getByClassroomSubject(
            classroomSubjectId,
          );
        }
      }
    }

    return replanningEngineService.detectDelay(
      classroomSubjectId: classroomSubjectId,
      plannedLessons: plannedLessons,
      executionRecords: executionRecords,
      courseContents: courseContents,
      referenceDate: refDate,
      academicYear: academicYear,
      teachingDays: teachingDays,
      scheduleSlots: scheduleSlots,
    );
  }
}
