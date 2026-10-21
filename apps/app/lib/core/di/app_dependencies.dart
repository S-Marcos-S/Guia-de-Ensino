import 'dart:async';

import 'package:app/core/network/connectivity_service.dart';
import 'package:app/domain/models/auth_session.dart';
import 'package:app/domain/repositories/academic_year_repository.dart';
import 'package:app/domain/repositories/auth_repository.dart';
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
import 'package:app/domain/services/replanning_engine_service.dart';
import 'package:app/domain/usecases/apply_replanning_proposal_usecase.dart';
import 'package:app/domain/usecases/detect_schedule_delay_usecase.dart';
import 'package:app/domain/usecases/generate_replanning_proposal_usecase.dart';
import 'package:app/domain/usecases/generate_schedule_plan_usecase.dart';
import 'package:app/domain/usecases/get_classroom_subject_lessons_usecase.dart';
import 'package:app/domain/usecases/get_classroom_subject_progress_usecase.dart';
import 'package:app/domain/usecases/get_pending_lessons_usecase.dart';
import 'package:app/domain/usecases/record_lesson_execution_usecase.dart';
import 'package:app/infrastructure/auth/client/auth_api_client.dart';
import 'package:app/infrastructure/auth/repositories/auth_repository_impl.dart';
import 'package:app/infrastructure/auth/storage/in_memory_token_storage.dart';
import 'package:app/infrastructure/auth/storage/token_storage.dart';
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
import 'package:app/infrastructure/sync/client/sync_api_client.dart';
import 'package:app/infrastructure/sync/orchestrator/sync_orchestrator.dart';
import 'package:app/infrastructure/sync/orchestrator/sync_staging_handler.dart';
import 'package:app/infrastructure/sync/outbox/sync_outbox_repository.dart';
import 'package:app/infrastructure/sync/triggers/sync_trigger_manager.dart';
import 'package:flutter/widgets.dart';

/// Contêiner de dependências e repositórios da aplicação.
///
/// Suporta modo híbrido (offline/convidado e autenticado), gerenciando
/// reativamente a disponibilização de [SyncApiClient] e [SyncOrchestrator].
class AppDependencies extends ChangeNotifier {
  static const String defaultApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.guiadeensino.com.br',
  );

  AppDependencies({
    required this.database,
    AuthRepository? authRepository,
    String? apiBaseUrl,
    TokenStorage? tokenStorage,
    ConnectivityService? connectivityService,
    SyncTriggerManager? syncTriggerManager,
    SyncOutboxRepository? syncOutboxRepository,
    SyncApiClient? syncApiClient,
    SyncStagingHandler? syncStagingHandler,
    SyncOrchestrator? syncOrchestrator,
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
    GetClassroomSubjectLessonsUseCase? getClassroomSubjectLessonsUseCase,
    ReplanningEngineService? replanningEngineService,
    DetectScheduleDelayUseCase? detectScheduleDelayUseCase,
    GenerateReplanningProposalUseCase? generateReplanningProposalUseCase,
    ApplyReplanningProposalUseCase? applyReplanningProposalUseCase,
  }) : apiBaseUrl = apiBaseUrl ?? defaultApiBaseUrl,
       authRepository =
           authRepository ??
           AuthRepositoryImpl(
             apiClient: AuthApiClient(baseUrl: apiBaseUrl ?? defaultApiBaseUrl),
             tokenStorage: tokenStorage ?? InMemoryTokenStorage(),
           ),
       syncOutboxRepository =
           syncOutboxRepository ?? SyncOutboxRepository(database),
       connectivityService =
           connectivityService ?? InMemoryConnectivityService(true),
       syncStagingHandler = syncStagingHandler ?? SyncStagingHandler(database),
       academicYearRepository =
           academicYearRepository ??
           DriftAcademicYearRepository(
             database,
             syncOutboxRepository ?? SyncOutboxRepository(database),
           ),
       subjectRepository =
           subjectRepository ??
           DriftSubjectRepository(
             database,
             syncOutboxRepository ?? SyncOutboxRepository(database),
           ),
       classroomRepository =
           classroomRepository ??
           DriftClassroomRepository(
             database,
             syncOutboxRepository ?? SyncOutboxRepository(database),
           ),
       calendarEventRepository =
           calendarEventRepository ??
           DriftCalendarEventRepository(
             database,
             syncOutboxRepository ?? SyncOutboxRepository(database),
           ),
       scheduleSlotRepository =
           scheduleSlotRepository ??
           DriftScheduleSlotRepository(
             database,
             syncOutboxRepository ?? SyncOutboxRepository(database),
           ),
       plannedLessonRepository =
           plannedLessonRepository ??
           DriftPlannedLessonRepository(
             database,
             syncOutboxRepository ?? SyncOutboxRepository(database),
           ),
       lessonExecutionRepository =
           lessonExecutionRepository ??
           DriftLessonExecutionRepository(
             database,
             syncOutboxRepository ?? SyncOutboxRepository(database),
           ),
       calendarCalculationService =
           calendarCalculationService ?? const CalendarCalculationService(),
       curriculumCompetencyRepository =
           curriculumCompetencyRepository ??
           DriftCurriculumCompetencyRepository(database),
       courseContentRepository =
           courseContentRepository ??
           DriftCourseContentRepository(
             database,
             syncOutboxRepository ?? SyncOutboxRepository(database),
           ),
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
           ),
       getClassroomSubjectLessonsUseCase =
           getClassroomSubjectLessonsUseCase ??
           GetClassroomSubjectLessonsUseCase(
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
       replanningEngineService =
           replanningEngineService ??
           ReplanningEngineService(
             planningEngineService:
                 planningEngineService ??
                 PlanningEngineService(
                   curriculumIntegrityService:
                       curriculumIntegrityService ??
                       const CurriculumIntegrityService(),
                 ),
           ),
       detectScheduleDelayUseCase =
           detectScheduleDelayUseCase ??
           DetectScheduleDelayUseCase(
             plannedLessonRepository:
                 plannedLessonRepository ??
                 DriftPlannedLessonRepository(database),
             lessonExecutionRepository:
                 lessonExecutionRepository ??
                 DriftLessonExecutionRepository(database),
             courseContentRepository:
                 courseContentRepository ??
                 DriftCourseContentRepository(database),
             classroomRepository:
                 classroomRepository ?? DriftClassroomRepository(database),
             academicYearRepository:
                 academicYearRepository ??
                 DriftAcademicYearRepository(database),
             calendarEventRepository:
                 calendarEventRepository ??
                 DriftCalendarEventRepository(database),
             calendarCalculationService:
                 calendarCalculationService ??
                 const CalendarCalculationService(),
             scheduleSlotRepository:
                 scheduleSlotRepository ??
                 DriftScheduleSlotRepository(database),
             replanningEngineService:
                 replanningEngineService ??
                 ReplanningEngineService(
                   planningEngineService:
                       planningEngineService ??
                       PlanningEngineService(
                         curriculumIntegrityService:
                             curriculumIntegrityService ??
                             const CurriculumIntegrityService(),
                       ),
                 ),
           ),
       generateReplanningProposalUseCase =
           generateReplanningProposalUseCase ??
           GenerateReplanningProposalUseCase(
             classroomRepository:
                 classroomRepository ?? DriftClassroomRepository(database),
             academicYearRepository:
                 academicYearRepository ??
                 DriftAcademicYearRepository(database),
             calendarEventRepository:
                 calendarEventRepository ??
                 DriftCalendarEventRepository(database),
             calendarCalculationService:
                 calendarCalculationService ??
                 const CalendarCalculationService(),
             scheduleSlotRepository:
                 scheduleSlotRepository ??
                 DriftScheduleSlotRepository(database),
             courseContentRepository:
                 courseContentRepository ??
                 DriftCourseContentRepository(database),
             plannedLessonRepository:
                 plannedLessonRepository ??
                 DriftPlannedLessonRepository(database),
             lessonExecutionRepository:
                 lessonExecutionRepository ??
                 DriftLessonExecutionRepository(database),
             replanningEngineService:
                 replanningEngineService ??
                 ReplanningEngineService(
                   planningEngineService:
                       planningEngineService ??
                       PlanningEngineService(
                         curriculumIntegrityService:
                             curriculumIntegrityService ??
                             const CurriculumIntegrityService(),
                       ),
                 ),
           ),
       applyReplanningProposalUseCase =
           applyReplanningProposalUseCase ??
           ApplyReplanningProposalUseCase(
             plannedLessonRepository:
                 plannedLessonRepository ??
                 DriftPlannedLessonRepository(database),
             lessonExecutionRepository:
                 lessonExecutionRepository ??
                 DriftLessonExecutionRepository(database),
           ) {
    if (syncApiClient != null) {
      _syncApiClient = syncApiClient;
      _syncOrchestrator =
          syncOrchestrator ??
          SyncOrchestrator(
            apiClient: syncApiClient,
            outboxRepository: this.syncOutboxRepository,
            stagingHandler: this.syncStagingHandler,
          );
    } else if (this.authRepository.isAuthenticated) {
      _configureAuthenticatedSync(this.authRepository.currentSession!);
    }

    _sessionSubscription = this.authRepository.sessionStream.listen((session) {
      if (session != null) {
        _configureAuthenticatedSync(session);
      } else {
        _clearAuthenticatedSync();
      }
    });

    this.syncTriggerManager =
        syncTriggerManager ??
        SyncTriggerManager(
          orchestratorProvider: () => _syncOrchestrator,
          authRepository: this.authRepository,
          connectivityService: this.connectivityService,
          outboxRepository: this.syncOutboxRepository,
        );
  }

  void _configureAuthenticatedSync(AuthSession session) {
    _syncApiClient = SyncApiClient(
      baseUrl: apiBaseUrl,
      tokenProvider: () => authRepository.currentSession?.token,
    );
    _syncOrchestrator = SyncOrchestrator(
      apiClient: _syncApiClient!,
      outboxRepository: syncOutboxRepository,
      stagingHandler: syncStagingHandler,
    );
    notifyListeners();
  }

  void _clearAuthenticatedSync() {
    _syncApiClient?.close();
    _syncApiClient = null;
    _syncOrchestrator = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    syncTriggerManager.dispose();
    connectivityService.dispose();
    super.dispose();
  }

  final AppDatabase database;
  final AuthRepository authRepository;
  final String apiBaseUrl;
  final ConnectivityService connectivityService;
  late final SyncTriggerManager syncTriggerManager;
  final SyncOutboxRepository syncOutboxRepository;
  final SyncStagingHandler syncStagingHandler;

  SyncApiClient? _syncApiClient;
  SyncOrchestrator? _syncOrchestrator;
  StreamSubscription<AuthSession?>? _sessionSubscription;

  SyncApiClient? get syncApiClient => _syncApiClient;
  SyncOrchestrator? get syncOrchestrator => _syncOrchestrator;

  bool get isAuthenticated => authRepository.isAuthenticated;
  bool get isGuestMode => !authRepository.isAuthenticated;
  AuthSession? get currentSession => authRepository.currentSession;
  Stream<AuthSession?> get sessionStream => authRepository.sessionStream;
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
  final GetClassroomSubjectLessonsUseCase getClassroomSubjectLessonsUseCase;
  final ReplanningEngineService replanningEngineService;
  final DetectScheduleDelayUseCase detectScheduleDelayUseCase;
  final GenerateReplanningProposalUseCase generateReplanningProposalUseCase;
  final ApplyReplanningProposalUseCase applyReplanningProposalUseCase;
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
