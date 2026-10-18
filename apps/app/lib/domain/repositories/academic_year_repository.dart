import 'package:app/domain/models/academic_year.dart';

/// Contrato de repositório de domínio para persistência de Anos Letivos.
abstract interface class AcademicYearRepository {
  Future<void> save(AcademicYear academicYear);
  Future<AcademicYear?> findById(String id);
  Future<AcademicYear?> findByYear(int year);
  Future<List<AcademicYear>> getAll();
  Future<void> delete(String id);
}
