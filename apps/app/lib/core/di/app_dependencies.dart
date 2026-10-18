import 'package:app/domain/repositories/academic_year_repository.dart';
import 'package:app/domain/repositories/calendar_event_repository.dart';
import 'package:app/domain/repositories/classroom_repository.dart';
import 'package:app/domain/repositories/planned_lesson_repository.dart';
import 'package:app/domain/repositories/schedule_slot_repository.dart';
import 'package:app/domain/repositories/subject_repository.dart';
import 'package:app/domain/services/calendar_calculation_service.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/persistence/repositories/drift_academic_year_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_calendar_event_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_classroom_repository.dart';
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
    CalendarCalculationService? calendarCalculationService,
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
       calendarCalculationService =
           calendarCalculationService ?? const CalendarCalculationService();

  final AppDatabase database;
  final AcademicYearRepository academicYearRepository;
  final SubjectRepository subjectRepository;
  final ClassroomRepository classroomRepository;
  final CalendarEventRepository calendarEventRepository;
  final ScheduleSlotRepository scheduleSlotRepository;
  final PlannedLessonRepository plannedLessonRepository;
  final CalendarCalculationService calendarCalculationService;
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
