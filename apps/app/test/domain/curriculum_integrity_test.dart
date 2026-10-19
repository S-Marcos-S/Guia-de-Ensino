import 'package:app/domain/models/course_content.dart';
import 'package:app/domain/services/curriculum_integrity_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = CurriculumIntegrityService();

  group('CurriculumIntegrityService Domain Tests', () {
    test('deve validar conteúdo com atributos consistentes', () {
      const validContent = CourseContent(
        id: 'c-1',
        classroomSubjectId: 'cs-mat',
        title: 'Frações e Decimais',
        estimatedLessons: 4,
        orderIndex: 1,
      );

      expect(() => service.validateContent(validContent), returnsNormally);
    });

    test(
      'deve rejeitar conteúdo com título vazio ou duração menor que 1 aula',
      () {
        const emptyTitle = CourseContent(
          id: 'c-1',
          classroomSubjectId: 'cs-mat',
          title: '   ',
          estimatedLessons: 2,
          orderIndex: 1,
        );

        const invalidLessons = CourseContent(
          id: 'c-2',
          classroomSubjectId: 'cs-mat',
          title: 'Números Primos',
          estimatedLessons: 0,
          orderIndex: 1,
        );

        expect(
          () => service.validateContent(emptyTitle),
          throwsA(isA<CurriculumValidationException>()),
        );
        expect(
          () => service.validateContent(invalidLessons),
          throwsA(isA<CurriculumValidationException>()),
        );
      },
    );

    test(
      'deve rejeitar conteúdo que declara a si mesmo como pré-requisito',
      () {
        const selfPrereq = CourseContent(
          id: 'c-1',
          classroomSubjectId: 'cs-mat',
          title: 'Geometria Espacial',
          estimatedLessons: 3,
          orderIndex: 2,
          prerequisiteIds: ['c-1'],
        );

        expect(
          () => service.validateContent(selfPrereq),
          throwsA(isA<CircularDependencyException>()),
        );
      },
    );

    test('deve aprovar grafo acíclico de dependências (sem ciclos)', () {
      // C depende de B; B depende de A; A não tem pré-requisitos
      const contentA = CourseContent(
        id: 'c-a',
        classroomSubjectId: 'cs-mat',
        title: 'Números Naturais',
        orderIndex: 1,
      );
      const contentB = CourseContent(
        id: 'c-b',
        classroomSubjectId: 'cs-mat',
        title: 'Multiplicação e Divisão',
        orderIndex: 2,
        prerequisiteIds: ['c-a'],
      );
      const contentC = CourseContent(
        id: 'c-c',
        classroomSubjectId: 'cs-mat',
        title: 'Potenciação',
        orderIndex: 3,
        prerequisiteIds: ['c-b'],
      );

      expect(
        () => service.validateNoCircularDependencies([
          contentA,
          contentB,
          contentC,
        ]),
        returnsNormally,
      );
    });

    test('deve detectar dependência circular direta (A -> B e B -> A)', () {
      const contentA = CourseContent(
        id: 'c-a',
        classroomSubjectId: 'cs-mat',
        title: 'Conteúdo A',
        orderIndex: 1,
        prerequisiteIds: ['c-b'],
      );
      const contentB = CourseContent(
        id: 'c-b',
        classroomSubjectId: 'cs-mat',
        title: 'Conteúdo B',
        orderIndex: 2,
        prerequisiteIds: ['c-a'],
      );

      expect(
        () => service.validateNoCircularDependencies([contentA, contentB]),
        throwsA(
          isA<CircularDependencyException>().having(
            (e) => e.message,
            'message',
            contains('Dependência circular'),
          ),
        ),
      );
    });

    test(
      'deve detectar dependência circular transitiva (A -> B -> C -> A)',
      () {
        const contentA = CourseContent(
          id: 'c-a',
          classroomSubjectId: 'cs-mat',
          title: 'Módulo A',
          orderIndex: 1,
          prerequisiteIds: ['c-c'],
        );
        const contentB = CourseContent(
          id: 'c-b',
          classroomSubjectId: 'cs-mat',
          title: 'Módulo B',
          orderIndex: 2,
          prerequisiteIds: ['c-a'],
        );
        const contentC = CourseContent(
          id: 'c-c',
          classroomSubjectId: 'cs-mat',
          title: 'Módulo C',
          orderIndex: 3,
          prerequisiteIds: ['c-b'],
        );

        expect(
          () => service.validateNoCircularDependencies([
            contentA,
            contentB,
            contentC,
          ]),
          throwsA(isA<CircularDependencyException>()),
        );
      },
    );
  });
}
