import 'package:app/domain/models/subject.dart';

/// Contrato de repositório de domínio para persistência de Disciplinas.
abstract interface class SubjectRepository {
  Future<void> save(Subject subject);
  Future<Subject?> findById(String id);
  Future<Subject?> findByName(String name);
  Future<List<Subject>> getAll();
  Future<void> delete(String id);
}
