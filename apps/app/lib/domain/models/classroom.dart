/// Representação de uma Turma escolar.
class Classroom {
  const Classroom({
    required this.id,
    required this.academicYearId,
    required this.name,
    required this.gradeLevel,
    this.shift = ClassroomShift.morning,
    this.subjectConfigs = const [],
  });

  final String id;
  final String academicYearId;
  final String name;
  final String gradeLevel;
  final ClassroomShift shift;
  final List<ClassroomSubjectConfig> subjectConfigs;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Classroom &&
        other.id == id &&
        other.academicYearId == academicYearId &&
        other.name == name &&
        other.gradeLevel == gradeLevel &&
        other.shift == shift;
  }

  @override
  int get hashCode => Object.hash(id, academicYearId, name, gradeLevel, shift);
}

enum ClassroomShift { morning, afternoon, evening, fullTime }

/// Vínculo específico entre a Turma e a Disciplina com carga horária própria.
class ClassroomSubjectConfig {
  const ClassroomSubjectConfig({
    required this.id,
    required this.classroomId,
    required this.subjectId,
    required this.weeklyLessons,
  });

  final String id;
  final String classroomId;
  final String subjectId;
  final int weeklyLessons;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassroomSubjectConfig &&
        other.id == id &&
        other.classroomId == classroomId &&
        other.subjectId == subjectId &&
        other.weeklyLessons == weeklyLessons;
  }

  @override
  int get hashCode => Object.hash(id, classroomId, subjectId, weeklyLessons);
}
