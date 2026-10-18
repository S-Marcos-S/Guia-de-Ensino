import 'package:app/domain/models/planned_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlannedLesson Domain Model', () {
    test(
      'deve identificar corretamente quando aula possui registro de execução',
      () {
        final planned = PlannedLesson(
          id: 'lesson-1',
          classroomSubjectId: 'cs-1',
          date: DateTime(2026, 3, 10),
          orderInDay: 1,
          status: LessonExecutionStatus.planned,
        );

        final completed = planned.copyWith(
          status: LessonExecutionStatus.completed,
        );
        final notHeld = planned.copyWith(status: LessonExecutionStatus.notHeld);

        expect(planned.hasExecutionRecord, isFalse);
        expect(completed.hasExecutionRecord, isTrue);
        expect(notHeld.hasExecutionRecord, isTrue);
      },
    );

    test(
      'deve manter imutabilidade e permitir cópias seguras via copyWith',
      () {
        final lesson = PlannedLesson(
          id: 'lesson-1',
          classroomSubjectId: 'cs-1',
          date: DateTime(2026, 3, 10),
          orderInDay: 1,
          isLocked: false,
        );

        final locked = lesson.copyWith(isLocked: true);

        expect(lesson.isLocked, isFalse);
        expect(locked.isLocked, isTrue);
        expect(locked.id, equals(lesson.id));
      },
    );
  });
}
