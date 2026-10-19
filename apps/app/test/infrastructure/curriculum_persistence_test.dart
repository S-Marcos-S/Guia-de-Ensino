import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/models/classroom.dart';
import 'package:app/domain/models/course_content.dart';
import 'package:app/domain/models/curriculum_competency.dart';
import 'package:app/domain/models/subject.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/persistence/repositories/drift_academic_year_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_classroom_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_course_content_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_curriculum_competency_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_subject_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late DriftAcademicYearRepository academicYearRepo;
  late DriftSubjectRepository subjectRepo;
  late DriftClassroomRepository classroomRepo;
  late DriftCurriculumCompetencyRepository competencyRepo;
  late DriftCourseContentRepository courseContentRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    academicYearRepo = DriftAcademicYearRepository(db);
    subjectRepo = DriftSubjectRepository(db);
    classroomRepo = DriftClassroomRepository(db);
    competencyRepo = DriftCurriculumCompetencyRepository(db);
    courseContentRepo = DriftCourseContentRepository(db);

    // Cria dados base necessários para os vínculos de turma e disciplina
    await academicYearRepo.save(
      AcademicYear(
        id: 'ay-2026',
        year: 2026,
        title: 'Ano Letivo 2026',
        startDate: DateTime.utc(2026, 2, 2),
        endDate: DateTime.utc(2026, 12, 18),
      ),
    );

    await subjectRepo.save(const Subject(id: 'sub-mat', name: 'Matemática'));

    await classroomRepo.save(
      const Classroom(
        id: 'class-9a',
        academicYearId: 'ay-2026',
        name: '9º Ano A',
        gradeLevel: '9º ano',
        subjectConfigs: [
          ClassroomSubjectConfig(
            id: 'cs-mat-9a',
            classroomId: 'class-9a',
            subjectId: 'sub-mat',
            weeklyLessons: 4,
          ),
        ],
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('CurriculumCompetency Persistence Tests', () {
    test(
      'deve salvar, buscar por código e listar competências da base curricular',
      () async {
        const comp1 = CurriculumCompetency(
          id: 'c-ef06ma01',
          code: 'EF06MA01',
          description: 'Comparar e ordenar números racionais',
          thematicUnit: 'Números',
          stage: 'Ensino Fundamental',
          gradeLevel: '6º ano',
          subjectName: 'Matemática',
          sourceName: 'BNCC MEC',
          sourceVersion: 'Resolução CNE/CP 2/2017',
        );
        const comp2 = CurriculumCompetency(
          id: 'c-em13mat101',
          code: 'EM13MAT101',
          description: 'Interpretar taxas e variações',
          thematicUnit: 'Álgebra',
          stage: 'Ensino Médio',
          gradeLevel: '1º ao 3º ano',
          subjectName: 'Matemática',
          sourceName: 'BNCC MEC',
          sourceVersion: 'Resolução CNE/CP 4/2018',
        );

        await competencyRepo.saveAll([comp1, comp2]);

        final total = await competencyRepo.count();
        expect(total, equals(2));

        final byCode = await competencyRepo.findByCode('ef06ma01');
        expect(byCode, isNotNull);
        expect(byCode!.code, equals('EF06MA01'));
        expect(byCode.thematicUnit, equals('Números'));

        final searchResults = await competencyRepo.search(query: 'taxas');
        expect(searchResults.length, equals(1));
        expect(searchResults.first.code, equals('EM13MAT101'));
      },
    );
  });

  group('CourseContent Persistence & Reordering Tests', () {
    test(
      'deve salvar conteúdos personalizados e vincular opcionalmente à BNCC',
      () async {
        const comp = CurriculumCompetency(
          id: 'c-ef06ma01',
          code: 'EF06MA01',
          description: 'Comparar e ordenar números racionais',
          thematicUnit: 'Números',
          stage: 'Ensino Fundamental',
          gradeLevel: '6º ano',
          subjectName: 'Matemática',
          sourceName: 'BNCC MEC',
          sourceVersion: 'Resolução CNE/CP 2/2017',
        );
        await competencyRepo.save(comp);

        const content1 = CourseContent(
          id: 'cnt-1',
          classroomSubjectId: 'cs-mat-9a',
          title: 'Frações e Números Decimais',
          description: 'Introdução e conversão de frações',
          thematicUnit: 'Números',
          estimatedLessons: 4,
          orderIndex: 1,
          isMandatory: true,
          curriculumCompetencyId: 'c-ef06ma01',
          origin: ContentOrigin.officialCurriculumImport,
        );

        const content2 = CourseContent(
          id: 'cnt-2',
          classroomSubjectId: 'cs-mat-9a',
          title: 'Operações com Frações',
          description: 'Soma e subtração com denominadores diferentes',
          thematicUnit: 'Números',
          estimatedLessons: 3,
          orderIndex: 2,
          isMandatory: true,
          origin: ContentOrigin.manual,
          prerequisiteIds: ['cnt-1'],
        );

        await courseContentRepo.save(content1);
        await courseContentRepo.save(content2);

        final contents = await courseContentRepo.getByClassroomSubject(
          'cs-mat-9a',
        );
        expect(contents.length, equals(2));
        expect(contents.first.id, equals('cnt-1'));
        expect(contents.first.curriculumCompetencyId, equals('c-ef06ma01'));
        expect(
          contents.first.origin,
          equals(ContentOrigin.officialCurriculumImport),
        );

        expect(contents.last.id, equals('cnt-2'));
        expect(contents.last.curriculumCompetencyId, isNull);
        expect(contents.last.origin, equals(ContentOrigin.manual));
        expect(contents.last.prerequisiteIds, contains('cnt-1'));
      },
    );

    test('deve reordenar a sequência de conteúdos de uma disciplina', () async {
      const content1 = CourseContent(
        id: 'cnt-a',
        classroomSubjectId: 'cs-mat-9a',
        title: 'Conteúdo A',
        estimatedLessons: 2,
        orderIndex: 1,
      );
      const content2 = CourseContent(
        id: 'cnt-b',
        classroomSubjectId: 'cs-mat-9a',
        title: 'Conteúdo B',
        estimatedLessons: 2,
        orderIndex: 2,
      );

      await courseContentRepo.save(content1);
      await courseContentRepo.save(content2);

      // Reordena colocando B antes de A
      await courseContentRepo.reorder('cs-mat-9a', ['cnt-b', 'cnt-a']);

      final reordered = await courseContentRepo.getByClassroomSubject(
        'cs-mat-9a',
      );
      expect(reordered.first.id, equals('cnt-b'));
      expect(reordered.last.id, equals('cnt-a'));
    });

    test('deve excluir conteúdo e limpar pré-requisitos vinculados', () async {
      const content1 = CourseContent(
        id: 'cnt-x',
        classroomSubjectId: 'cs-mat-9a',
        title: 'Conteúdo X',
        estimatedLessons: 2,
        orderIndex: 1,
      );
      const content2 = CourseContent(
        id: 'cnt-y',
        classroomSubjectId: 'cs-mat-9a',
        title: 'Conteúdo Y',
        estimatedLessons: 2,
        orderIndex: 2,
        prerequisiteIds: ['cnt-x'],
      );

      await courseContentRepo.save(content1);
      await courseContentRepo.save(content2);

      await courseContentRepo.delete('cnt-x');

      final remaining = await courseContentRepo.getByClassroomSubject(
        'cs-mat-9a',
      );
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals('cnt-y'));
      expect(remaining.first.prerequisiteIds, isEmpty);
    });
  });
}
