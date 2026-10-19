import '../models/course_content.dart';

abstract class CourseContentRepository {
  Future<void> save(CourseContent content);
  Future<void> saveAll(List<CourseContent> contents);
  Future<CourseContent?> findById(String id);
  Future<List<CourseContent>> getByClassroomSubject(String classroomSubjectId);
  Future<void> delete(String id);
  Future<void> reorder(
    String classroomSubjectId,
    List<String> orderedContentIds,
  );
  Future<List<String>> getPrerequisiteIds(String contentId);
  Future<void> setPrerequisites(String contentId, List<String> prerequisiteIds);
}
