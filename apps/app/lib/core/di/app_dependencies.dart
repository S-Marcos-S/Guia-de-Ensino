import 'package:app/domain/repositories/academic_year_repository.dart';
import 'package:app/domain/repositories/calendar_event_repository.dart';
import 'package:app/domain/repositories/classroom_repository.dart';
import 'package:app/domain/repositories/course_content_repository.dart';
import 'package:app/domain/repositories/curriculum_competency_repository.dart';
import 'package:app/domain/repositories/lesson_execution_repository.dart';
import 'package:app/domain/repositories/planned_lesson_repository.dart';
import 'package:app/domain/repositories/schedule_slot_repository.dart';
import 'package:app/domain/repositories/subject_repository.dart';
import 'package:app/domain/services/calendar_calculation_service.dart';
import 'package:app/domain/services/curriculum_integrity_service.dart';
import 'package:app/domain/services/planning_engine_service.dart';
import 'package:app/domain/usecases/generate_schedule_plan_usecase.dart';
import 'package:app/domain/usecases/get_classroom_subject_progress_usecase.dart';
import 'package:app/domain/usecases/get_pending_lessons_usecase.dart';
import 'package:app/domain/usecases/record_lesson_execution_usecase.dart';
import 'package:app/infrastructure/curriculum/curriculum_seed_loader.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/persistence/repositories/drift_academic_year_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_calendar_event_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_classroom_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_course_content_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_curriculum_competency_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_lesson_execution_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_planned_lesson_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_schedule_slot_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_subject_repository.dart';
import 'package:flutter/widgets.dart';

/// Contêiner de dependências e repositórios da aplicação.
class AppDependencies {
  AppDependencies({
    required this.database,
    AcademicYearRepository? academicYearRepository,
    SubjectRepository? subjectRepository,
    ClassroomRepository? classroomRepository,
    CalendarEventRepository? calendarEventRepository,
    ScheduleSlotRepository? scheduleSlotRepository,
    PlannedLessonRepository? plannedLessonRepository,
    LessonExecutionRepository? lessonExecutionRepository,
    CalendarCalculationService? calendarCalculationService,
    CurriculumCompetencyRepository? curriculumCompetencyRepository,
    CourseContentRepository? courseContentRepository,
    CurriculumIntegrityService? curriculumIntegrityService,
    CurriculumSeedLoader? curriculumSeedLoader,
    PlanningEngineService? planningEngineService,
    GenerateSchedulePlanUseCase? generateSchedulePlanUseCase,
    RecordLessonExecutionUseCase? recordLessonExecutionUseCase,
    GetClassroomSubjectProgressUseCase? getClassroomSubjectProgressUseCase,
    GetPendingLessonsUseCase? getPendingLessonsUseCase,
  }) : academicYearRepository =
           academicYearRepository ?? DriftAcademicYearRepository(database),
       subjectRepository =
           subjectRepository ?? DriftSubjectRepository(database),
       classroomRepository =
           classroomRepository ?? DriftClassroomRepository(database),
       calendarEventRepository =
           calendarEventRepository ?? DriftCalendarEventRepository(database),
       scheduleSlotRepository =
           scheduleSlotRepository ?? DriftScheduleSlotRepository(database),
       plannedLessonRepository =
           plannedLessonRepository ?? DriftPlannedLessonRepository(database),
       lessonExecutionRepository =
           lessonExecutionRepository ??
           DriftLessonExecutionRepository(database),
       calendarCalculationService =
           calendarCalculationService ?? const CalendarCalculationService(),
       curriculumCompetencyRepository =
           curriculumCompetencyRepository ??
           DriftCurriculumCompetencyRepository(database),
       courseContentRepository =
           courseContentRepository ?? DriftCourseContentRepository(database),
       curriculumIntegrityService =
           curriculumIntegrityService ?? const CurriculumIntegrityService(),
       curriculumSeedLoader =
           curriculumSeedLoader ??
           CurriculumSeedLoader(
             repository:
                 curriculumCompetencyRepository ??
                 DriftCurriculumCompetencyRepository(database),
           ),
       planningEngineService =
           planningEngineService ??
           PlanningEngineService(
             curriculumIntegrityService:
                 curriculumIntegrityService ??
                 const CurriculumIntegrityService(),
           ),
       generateSchedulePlanUseCase =
           generateSchedulePlanUseCase ??
           GenerateSchedulePlanUseCase(
             planningEngineService:
                 planningEngineService ??
                 PlanningEngineService(
                   curriculumIntegrityService:
                       curriculumIntegrityService ??
                       const CurriculumIntegrityService(),
                 ),
             calendarCalculationService:
                 calendarCalculationService ??
                 const CalendarCalculationService(),
             academicYearRepository:
                 academicYearRepository ??
                 DriftAcademicYearRepository(database),
             classroomRepository:
                 classroomRepository ?? DriftClassroomRepository(database),
             calendarEventRepository:
                 calendarEventRepository ??
                 DriftCalendarEventRepository(database),
             scheduleSlotRepository:
                 scheduleSlotRepository ??
                 DriftScheduleSlotRepository(database),
             courseContentRepository:
                 courseContentRepository ??
                 DriftCourseContentRepository(database),
             plannedLessonRepository:
                 plannedLessonRepository ??
                 DriftPlannedLessonRepository(database),
           ),
       recordLessonExecutionUseCase =
           recordLessonExecutionUseCase ??
           RecordLessonExecutionUseCase(
             lessonExecutionRepository:
                 lessonExecutionRepository ??
                 DriftLessonExecutionRepository(database),
             plannedLessonRepository:
                 plannedLessonRepository ??
                 DriftPlannedLessonRepository(database),
           ),
       getClassroomSubjectProgressUseCase =
           getClassroomSubjectProgressUseCase ??
           GetClassroomSubjectProgressUseCase(
             plannedLessonRepository:
                 plannedLessonRepository ??
                 DriftPlannedLessonRepository(database),
             lessonExecutionRepository:
                 lessonExecutionRepository ??
                 DriftLessonExecutionRepository(database),
             courseContentRepository:
                 courseContentRepository ??
                 DriftCourseContentRepository(database),
           ),
       getPendingLessonsUseCase =
           getPendingLessonsUseCase ??
           GetPendingLessonsUseCase(
             plannedLessonRepository:
                 plannedLessonRepository ??
                 DriftPlannedLessonRepository(database),
             lessonExecutionRepository:
                 lessonExecutionRepository ??
                 DriftLessonExecutionRepository(database),
           );

  final AppDatabase database;
  final AcademicYearRepository academicYearRepository;
  final SubjectRepository subjectRepository;
  final ClassroomRepository classroomRepository;
  final CalendarEventRepository calendarEventRepository;
  final ScheduleSlotRepository scheduleSlotRepository;
  final PlannedLessonRepository plannedLessonRepository;
  final LessonExecutionRepository lessonExecutionRepository;
  final CalendarCalculationService calendarCalculationService;
  final CurriculumCompetencyRepository curriculumCompetencyRepository;
  final CourseContentRepository courseContentRepository;
  final CurriculumIntegrityService curriculumIntegrityService;
  final CurriculumSeedLoader curriculumSeedLoader;
  final PlanningEngineService planningEngineService;
  final GenerateSchedulePlanUseCase generateSchedulePlanUseCase;
  final RecordLessonExecutionUseCase recordLessonExecutionUseCase;
  final GetClassroomSubjectProgressUseCase getClassroomSubjectProgressUseCase;
  final GetPendingLessonsUseCase getPendingLessonsUseCase;
}

/// Provedor de dependências via InheritedWidget para a árvore de widgets.
class AppDependencyScope extends InheritedWidget {
  const AppDependencyScope({
    super.key,
    required this.dependencies,
    required super.child,
  });

  final AppDependencies dependencies;

  static AppDependencies of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppDependencyScope>();
    assert(scope != null, 'Nenhum AppDependencyScope encontrado no contexto.');
    return scope!.dependencies;
  }

  @override
  bool updateShouldNotify(AppDependencyScope oldWidget) {
    return dependencies != oldWidget.dependencies;
  }
}
