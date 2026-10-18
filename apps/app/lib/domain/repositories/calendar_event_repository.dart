import 'package:app/domain/models/school_calendar_event.dart';

/// Contrato de repositório de domínio para persistência de eventos e feriados escolares.
abstract interface class CalendarEventRepository {
  Future<void> save(SchoolCalendarEvent event);
  Future<SchoolCalendarEvent?> findById(String id);
  Future<List<SchoolCalendarEvent>> getByAcademicYear(String academicYearId);
  Future<void> delete(String id);
}
