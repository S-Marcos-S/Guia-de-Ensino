import 'package:app/domain/models/academic_year.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AcademicYear Domain Model', () {
    test(
      'deve validar período escolar quando término for posterior ao início',
      () {
        final academicYear = AcademicYear(
          id: 'ay-2026',
          year: 2026,
          title: 'Ano Letivo 2026',
          startDate: DateTime(2026, 2, 2),
          endDate: DateTime(2026, 12, 18),
        );

        expect(academicYear.isValidPeriod(), isTrue);
        expect(academicYear.totalCalendarDays, greaterThan(300));
      },
    );

    test(
      'deve invalidar período escolar quando data final for anterior à inicial',
      () {
        final invalidYear = AcademicYear(
          id: 'ay-invalid',
          year: 2026,
          title: 'Ano Inválido',
          startDate: DateTime(2026, 12, 1),
          endDate: DateTime(2026, 2, 1),
        );

        expect(invalidYear.isValidPeriod(), isFalse);
      },
    );

    test('deve suportar igualdade por valor entre instâncias idênticas', () {
      final year1 = AcademicYear(
        id: 'ay-1',
        year: 2026,
        title: '2026',
        startDate: DateTime(2026, 2, 2),
        endDate: DateTime(2026, 12, 18),
      );

      final year2 = AcademicYear(
        id: 'ay-1',
        year: 2026,
        title: '2026',
        startDate: DateTime(2026, 2, 2),
        endDate: DateTime(2026, 12, 18),
      );

      expect(year1, equals(year2));
      expect(year1.hashCode, equals(year2.hashCode));
    });
  });
}
