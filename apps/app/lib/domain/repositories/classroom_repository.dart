import 'package:app/domain/models/classroom.dart';

/// Contrato de repositório de domínio para persistência de Turmas e configurações.
abstract interface class ClassroomRepository {
  Future<void> save(Classroom classroom);
  Future<Classroom?> findById(String id);
  Future<List<Classroom>> getByAcademicYear(String academicYearId);
  Future<List<Classroom>> getAll();
  Future<void> delete(String id);
}
