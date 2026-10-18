import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/models/classroom.dart';
import 'package:app/domain/models/planned_lesson.dart';
import 'package:app/domain/models/subject.dart';
import 'package:app/domain/repositories/planned_lesson_repository.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/persistence/repositories/drift_academic_year_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_classroom_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_planned_lesson_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_subject_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftAcademicYearRepository academicYearRepo;
  late DriftSubjectRepository subjectRepo;
  late DriftClassroomRepository classroomRepo;
  late DriftPlannedLessonRepository lessonRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    academicYearRepo = DriftAcademicYearRepository(db);
    subjectRepo = DriftSubjectRepository(db);
    classroomRepo = DriftClassroomRepository(db);
    lessonRepo = DriftPlannedLessonRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift Repositories Tests', () {
    test(
      'deve salvar e recuperar Ano Letivo preservando datas exatas',
      () async {
        final academicYear = AcademicYear(
          id: 'ay-2026',
          year: 2026,
          title: 'Ano Letivo 2026',
          startDate: DateTime.utc(2026, 2, 2),
          endDate: DateTime.utc(2026, 12, 18),
          totalMandatoryDays: 200,
        );

        await academicYearRepo.save(academicYear);

        final found = await academicYearRepo.findById('ay-2026');
        expect(found, isNotNull);
        expect(found!.year, equals(2026));
        expect(found.title, equals('Ano Letivo 2026'));
        expect(found.startDate, equals(DateTime.utc(2026, 2, 2)));
        expect(found.endDate, equals(DateTime.utc(2026, 12, 18)));
      },
    );

    test(
      'deve salvar Disciplinas e permitir busca por nome e listagem',
      () async {
        const math = Subject(
          id: 'subj-mat',
          name: 'Matemática',
          colorHex: '#1E3A8A',
        );
        const history = Subject(
          id: 'subj-his',
          name: 'História',
          colorHex: '#D97706',
        );

        await subjectRepo.save(math);
        await subjectRepo.save(history);

        final foundMath = await subjectRepo.findByName('Matemática');
        expect(foundMath, isNotNull);
        expect(foundMath!.colorHex, equals('#1E3A8A'));

        final all = await subjectRepo.getAll();
        expect(all.length, equals(2));
      },
    );

    test('deve salvar Turma com vínculos de disciplinas e cargas horárias específicas', () async {
      // 1. Setup do ano letivo e disciplinas
      await academicYearRepo.save(
        AcademicYear(
          id: 'ay-2026',
          year: 2026,
          title: '2026',
          startDate: DateTime.utc(2026, 2, 2),
          endDate: DateTime.utc(2026, 12, 18),
        ),
      );

      await subjectRepo.save(const Subject(id: 'subj-mat', name: 'Matemática'));
      await subjectRepo.save(
        const Subject(id: 'subj-port', name: 'Língua Portuguesa'),
      );

      // 2. Turma com 4 aulas de Matemática e 5 aulas de Português
      const turma9A = Classroom(
        id: 'class-9a',
        academicYearId: 'ay-2026',
        name: '9º Ano A',
        gradeLevel: '9º Ano EF',
        shift: ClassroomShift.morning,
        subjectConfigs: [
          ClassroomSubjectConfig(
            id: 'cs-9a-mat',
            classroomId: 'class-9a',
            subjectId: 'subj-mat',
            weeklyLessons: 4,
          ),
          ClassroomSubjectConfig(
            id: 'cs-9a-port',
            classroomId: 'class-9a',
            subjectId: 'subj-port',
            weeklyLessons: 5,
          ),
        ],
      );

      await classroomRepo.save(turma9A);

      final found = await classroomRepo.findById('class-9a');
      expect(found, isNotNull);
      expect(found!.name, equals('9º Ano A'));
      expect(found.subjectConfigs.length, equals(2));

      final matConfig = found.subjectConfigs.firstWhere(
        (c) => c.subjectId == 'subj-mat',
      );
      expect(matConfig.weeklyLessons, equals(4));

      final portConfig = found.subjectConfigs.firstWhere(
        (c) => c.subjectId == 'subj-port',
      );
      expect(portConfig.weeklyLessons, equals(5));
    });

    test('deve permitir excluir aula prevista, mas bloquear exclusão de aula com histórico de execução', () async {
      // Setup de dependências relacionais
      await academicYearRepo.save(
        AcademicYear(
          id: 'ay-2026',
          year: 2026,
          title: '2026',
          startDate: DateTime.utc(2026, 2, 2),
          endDate: DateTime.utc(2026, 12, 18),
        ),
      );
      await subjectRepo.save(const Subject(id: 'subj-mat', name: 'Matemática'));
      await classroomRepo.save(
        const Classroom(
          id: 'class-9a',
          academicYearId: 'ay-2026',
          name: '9º Ano A',
          gradeLevel: '9º Ano',
          subjectConfigs: [
            ClassroomSubjectConfig(
              id: 'cs-9a-mat',
              classroomId: 'class-9a',
              subjectId: 'subj-mat',
              weeklyLessons: 4,
            ),
          ],
        ),
      );

      // 1. Aula puramente prevista (pode ser excluída)
      final plannedLesson = PlannedLesson(
        id: 'lesson-planned',
        classroomSubjectId: 'cs-9a-mat',
        date: DateTime.utc(2026, 3, 10),
        orderInDay: 1,
        status: LessonExecutionStatus.planned,
      );
      await lessonRepo.save(plannedLesson);
      expect(await lessonRepo.findById('lesson-planned'), isNotNull);

      await lessonRepo.delete('lesson-planned');
      expect(await lessonRepo.findById('lesson-planned'), isNull);

      // 2. Aula realizada com histórico (NUNCA pode ser excluída)
      final completedLesson = PlannedLesson(
        id: 'lesson-completed',
        classroomSubjectId: 'cs-9a-mat',
        date: DateTime.utc(2026, 3, 11),
        orderInDay: 1,
        status: LessonExecutionStatus.completed,
        notes: 'Conteúdo de frações ministrado integralmente.',
      );
      await lessonRepo.save(completedLesson);

      expect(
        () => lessonRepo.delete('lesson-completed'),
        throwsA(isA<LessonExecutionProtectedException>()),
      );

      // Confirma que a aula permanece intacta no banco
      final stillExists = await lessonRepo.findById('lesson-completed');
      expect(stillExists, isNotNull);
      expect(stillExists!.status, equals(LessonExecutionStatus.completed));
    });
  });
}
