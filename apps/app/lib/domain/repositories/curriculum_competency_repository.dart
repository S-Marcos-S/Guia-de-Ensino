import '../models/curriculum_competency.dart';

abstract class CurriculumCompetencyRepository {
  Future<void> save(CurriculumCompetency competency);
  Future<void> saveAll(List<CurriculumCompetency> competencies);
  Future<CurriculumCompetency?> findById(String id);
  Future<CurriculumCompetency?> findByCode(String code);
  Future<List<CurriculumCompetency>> getAll();
  Future<List<CurriculumCompetency>> search({
    String? query,
    String? stage,
    String? subjectName,
  });
  Future<int> count();
}
