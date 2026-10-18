import 'package:app/domain/models/classroom.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Classroom Domain Model', () {
    test('deve permitir cargas horárias diferentes para a mesma disciplina em turmas distintas', () {
      const subjectMathId = 'subj-matematica';

      // Turma 9º A com 4 aulas semanais de Matemática
      const turma9A = Classroom(
        id: 'class-9a',
        academicYearId: 'ay-2026',
        name: '9º Ano A',
        gradeLevel: '9º Ano EF',
        subjectConfigs: [
          ClassroomSubjectConfig(
            id: 'cfg-1',
            classroomId: 'class-9a',
            subjectId: subjectMathId,
            weeklyLessons: 4,
          ),
        ],
      );

      // Turma 9º B com 2 aulas semanais de Matemática
      const turma9B = Classroom(
        id: 'class-9b',
        academicYearId: 'ay-2026',
        name: '9º Ano B',
        gradeLevel: '9º Ano EF',
        subjectConfigs: [
          ClassroomSubjectConfig(
            id: 'cfg-2',
            classroomId: 'class-9b',
            subjectId: subjectMathId,
            weeklyLessons: 2,
          ),
        ],
      );

      expect(turma9A.subjectConfigs.first.weeklyLessons, equals(4));
      expect(turma9B.subjectConfigs.first.weeklyLessons, equals(2));
      expect(turma9A, isNot(equals(turma9B)));
    });
  });
}
