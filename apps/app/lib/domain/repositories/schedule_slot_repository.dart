import 'package:app/domain/models/schedule_slot.dart';

/// Contrato de repositório de domínio para persistência da grade semanal de aulas.
abstract interface class ScheduleSlotRepository {
  Future<void> saveSlots(String classroomSubjectId, List<ScheduleSlot> slots);
  Future<List<ScheduleSlot>> getByClassroomSubject(String classroomSubjectId);
  Future<List<ScheduleSlot>> getByClassroom(String classroomId);
  Future<void> delete(String id);
}
