import 'dart:io';

import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/models/classroom.dart';
import 'package:app/domain/models/subject.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/persistence/repositories/drift_academic_year_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_classroom_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_subject_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('guia_de_ensino_disk_test_');
    dbFile = File(p.join(tempDir.path, 'test_persistence.sqlite'));
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Disk Persistence & Reopening Tests', () {
    test('deve persistir dados em arquivo SQLite no disco e recuperá-los intactos após fechar e reabrir', () async {
      // SESSÃO 1: Abre banco no arquivo, insere dados e fecha
      final dbSession1 = AppDatabase.forTesting(NativeDatabase(dbFile));
      final academicYearRepo1 = DriftAcademicYearRepository(dbSession1);
      final subjectRepo1 = DriftSubjectRepository(dbSession1);
      final classroomRepo1 = DriftClassroomRepository(dbSession1);

      final year = AcademicYear(
        id: 'ay-2026-disk',
        year: 2026,
        title: 'Ano Letivo 2026 Preservado',
        startDate: DateTime.utc(2026, 2, 2),
        endDate: DateTime.utc(2026, 12, 18),
        totalMandatoryDays: 200,
      );
      await academicYearRepo1.save(year);

      const math = Subject(
        id: 'subj-math-disk',
        name: 'Matemática',
        colorHex: '#1E3A8A',
      );
      await subjectRepo1.save(math);

      const turma = Classroom(
        id: 'class-disk-9a',
        academicYearId: 'ay-2026-disk',
        name: '9º Ano A - Presistido',
        gradeLevel: '9º Ano EF',
        shift: ClassroomShift.morning,
        subjectConfigs: [
          ClassroomSubjectConfig(
            id: 'cs-disk-1',
            classroomId: 'class-disk-9a',
            subjectId: 'subj-math-disk',
            weeklyLessons: 4,
          ),
        ],
      );
      await classroomRepo1.save(turma);

      // Fecha completamente a conexão do banco de dados simulando encerramento do app
      await dbSession1.close();

      // Confirma que o arquivo existe fisicamente no disco e possui tamanho > 0
      expect(dbFile.existsSync(), isTrue);
      expect(dbFile.lengthSync(), greaterThan(0));

      // SESSÃO 2: Abre uma nova instância do banco apontando para o MESMO arquivo
      final dbSession2 = AppDatabase.forTesting(NativeDatabase(dbFile));
      final academicYearRepo2 = DriftAcademicYearRepository(dbSession2);
      final classroomRepo2 = DriftClassroomRepository(dbSession2);

      // Consulta os dados gravados anteriormente
      final recoveredYear = await academicYearRepo2.findById('ay-2026-disk');
      expect(recoveredYear, isNotNull);
      expect(recoveredYear!.title, equals('Ano Letivo 2026 Preservado'));
      expect(recoveredYear.startDate, equals(DateTime.utc(2026, 2, 2)));

      final recoveredClass = await classroomRepo2.findById('class-disk-9a');
      expect(recoveredClass, isNotNull);
      expect(recoveredClass!.name, equals('9º Ano A - Presistido'));
      expect(recoveredClass.subjectConfigs.length, equals(1));
      expect(recoveredClass.subjectConfigs.first.weeklyLessons, equals(4));

      // Encerra sessão 2
      await dbSession2.close();
    });
  });
}
