import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/models/schedule_slot.dart';
import 'package:app/domain/models/school_calendar_event.dart';
import 'package:app/domain/services/calendar_calculation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SchoolCalendarEvent Domain Model', () {
    test('deve validar quando data de término for igual ou posterior à data de início', () {
      final singleDayEvent = SchoolCalendarEvent(
        id: 'ev-1',
        academicYearId: 'ay-2026',
        title: 'Feriado Tiradentes',
        startDate: DateTime(2026, 4, 21),
        endDate: DateTime(2026, 4, 21),
      );

      final multiDayEvent = SchoolCalendarEvent(
        id: 'ev-2',
        academicYearId: 'ay-2026',
        title: 'Recesso Escolar Julho',
        startDate: DateTime(2026, 7, 10),
        endDate: DateTime(2026, 7, 25),
        type: SchoolEventType.recess,
      );

      expect(singleDayEvent.isValidPeriod(), isTrue);
      expect(multiDayEvent.isValidPeriod(), isTrue);
    });

    test('deve invalidar quando data final for anterior à data inicial', () {
      final invalidEvent = SchoolCalendarEvent(
        id: 'ev-err',
        academicYearId: 'ay-2026',
        title: 'Evento Inválido',
        startDate: DateTime(2026, 5, 10),
        endDate: DateTime(2026, 5, 8),
      );

      expect(invalidEvent.isValidPeriod(), isFalse);
    });

    test('deve verificar corretamente se uma data cai dentro do intervalo do evento', () {
      final recess = SchoolCalendarEvent(
        id: 'ev-recess',
        academicYearId: 'ay-2026',
        title: 'Recesso de Julho',
        startDate: DateTime(2026, 7, 6),
        endDate: DateTime(2026, 7, 10),
        type: SchoolEventType.recess,
      );

      expect(recess.coversDate(DateTime(2026, 7, 6)), isTrue);
      expect(recess.coversDate(DateTime(2026, 7, 8)), isTrue);
      expect(recess.coversDate(DateTime(2026, 7, 10)), isTrue);
      expect(recess.coversDate(DateTime(2026, 7, 5)), isFalse);
      expect(recess.coversDate(DateTime(2026, 7, 11)), isFalse);
    });
  });

  group('CalendarCalculationService Deterministic Tests', () {
    const service = CalendarCalculationService();

    test(
      'deve calcular dias letivos regulares desconsiderando finais de semana',
      () {
        // 1 semana: de segunda-feira (02/02/2026) até domingo (08/02/2026)
        final academicYear = AcademicYear(
          id: 'ay-1',
          year: 2026,
          title: 'Semana Teste',
          startDate: DateTime(2026, 2, 2), // Segunda
          endDate: DateTime(2026, 2, 8), // Domingo
          totalMandatoryDays: 5,
        );

        final result = service.calculateTeachingDays(
          academicYear: academicYear,
        );

        // Deve ter exatamente 5 dias letivos (segunda a sexta)
        expect(result.totalTeachingDays, equals(5));
        expect(result.isTargetMet, isTrue);
        expect(result.missingDays, equals(0));
        expect(result.teachingDays.first, equals(DateTime(2026, 2, 2)));
        expect(result.teachingDays.last, equals(DateTime(2026, 2, 6)));
      },
    );

    test('deve descontar feriados e recessos que afetam as aulas', () {
      // Período de 02/02/2026 (Segunda) a 06/02/2026 (Sexta) = 5 dias letivos
      // Inserimos um feriado na Quarta-feira (04/02/2026)
      final academicYear = AcademicYear(
        id: 'ay-1',
        year: 2026,
        title: 'Semana com Feriado',
        startDate: DateTime(2026, 2, 2),
        endDate: DateTime(2026, 2, 6),
        totalMandatoryDays: 5,
      );

      final holiday = SchoolCalendarEvent(
        id: 'h-1',
        academicYearId: 'ay-1',
        title: 'Feriado Municipal',
        startDate: DateTime(2026, 2, 4),
        endDate: DateTime(2026, 2, 4),
        affectsClasses: true,
      );

      final result = service.calculateTeachingDays(
        academicYear: academicYear,
        events: [holiday],
      );

      // 5 dias - 1 feriado = 4 dias letivos
      expect(result.totalTeachingDays, equals(4));
      expect(result.isTargetMet, isFalse);
      expect(result.missingDays, equals(1));
      expect(result.teachingDays.contains(DateTime(2026, 2, 4)), isFalse);
    });

    test('não deve descontar em duplicidade feriados e recessos coincidentes ou sobrepostos', () {
      // 02/02/2026 (Segunda) a 06/02/2026 (Sexta)
      // Dois eventos no mesmo dia 04/02/2026 (Quarta): um recesso e um feriado coincidente
      final academicYear = AcademicYear(
        id: 'ay-1',
        year: 2026,
        title: 'Semana com Eventos Coincidentes',
        startDate: DateTime(2026, 2, 2),
        endDate: DateTime(2026, 2, 6),
        totalMandatoryDays: 4,
      );

      final holiday = SchoolCalendarEvent(
        id: 'h-1',
        academicYearId: 'ay-1',
        title: 'Feriado Municipal',
        startDate: DateTime(2026, 2, 4),
        endDate: DateTime(2026, 2, 4),
        affectsClasses: true,
      );

      final recess = SchoolCalendarEvent(
        id: 'r-1',
        academicYearId: 'ay-1',
        title: 'Recesso Escolar',
        startDate: DateTime(2026, 2, 4),
        endDate: DateTime(2026, 2, 4),
        affectsClasses: true,
      );

      final result = service.calculateTeachingDays(
        academicYear: academicYear,
        events: [holiday, recess],
      );

      // Deve descontar apenas 1 dia e não 2
      expect(result.totalTeachingDays, equals(4));
      expect(result.isTargetMet, isTrue);
    });

    test('não deve descontar eventos que não afetam as aulas (affectsClasses == false)', () {
      final academicYear = AcademicYear(
        id: 'ay-1',
        year: 2026,
        title: 'Semana Teste',
        startDate: DateTime(2026, 2, 2),
        endDate: DateTime(2026, 2, 6),
        totalMandatoryDays: 5,
      );

      final event = SchoolCalendarEvent(
        id: 'ev-comemorativo',
        academicYearId: 'ay-1',
        title: 'Dia do Livro (Comemorativo com aula regular)',
        startDate: DateTime(2026, 2, 3),
        endDate: DateTime(2026, 2, 3),
        affectsClasses: false,
      );

      final result = service.calculateTeachingDays(
        academicYear: academicYear,
        events: [event],
      );

      expect(result.totalTeachingDays, equals(5));
      expect(result.teachingDays.contains(DateTime(2026, 2, 3)), isTrue);
    });

    test('deve calcular a quantidade exata de aulas de uma disciplina com base na grade semanal', () {
      // 2 semanas: 02/02/2026 a 13/02/2026 (10 dias úteis, 2 segundas, 2 terças, etc.)
      final academicYear = AcademicYear(
        id: 'ay-1',
        year: 2026,
        title: 'Duas Semanas',
        startDate: DateTime(2026, 2, 2),
        endDate: DateTime(2026, 2, 13),
      );

      final calcResult = service.calculateTeachingDays(
        academicYear: academicYear,
      );

      // Disciplina tem: 2 aulas na Segunda-feira (weekday: 1) e 1 aula na Quarta-feira (weekday: 3)
      // Em 2 semanas = 2*2 + 2*1 = 6 aulas
      final slots = [
        const ScheduleSlot(
          id: 's-1',
          classroomSubjectId: 'cs-mat',
          weekday: 1, // Segunda
          orderIndex: 1,
        ),
        const ScheduleSlot(
          id: 's-2',
          classroomSubjectId: 'cs-mat',
          weekday: 1, // Segunda
          orderIndex: 2,
        ),
        const ScheduleSlot(
          id: 's-3',
          classroomSubjectId: 'cs-mat',
          weekday: 3, // Quarta
          orderIndex: 3,
        ),
      ];

      final totalSubjectLessons = service.calculateSubjectLessonCount(
        teachingDays: calcResult.teachingDays,
        subjectSlots: slots,
      );

      expect(totalSubjectLessons, equals(6));
    });

    test('deve detectar conflitos de horário na grade semanal da turma', () {
      final slotsWithConflict = [
        const ScheduleSlot(
          id: 's-1',
          classroomSubjectId: 'cs-mat',
          weekday: 1, // Segunda
          orderIndex: 1,
        ),
        const ScheduleSlot(
          id: 's-2',
          classroomSubjectId: 'cs-port',
          weekday: 1, // Segunda (mesmo horário e mesmo dia!)
          orderIndex: 1,
        ),
      ];

      final conflicts = service.validateScheduleConflicts(slotsWithConflict);
      expect(conflicts.length, equals(1));
      expect(conflicts.first, contains('Segunda-feira, 1ª aula'));
    });
  });
}
