import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // Banco em memória configurado com PRAGMA foreign_keys = ON via migration.beforeOpen
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('SQLite Foreign Keys & Referential Integrity Tests', () {
    test(
      'deve confirmar que PRAGMA foreign_keys está ativo no banco',
      () async {
        final result = await db
            .customSelect('PRAGMA foreign_keys;')
            .getSingle();
        final fkEnabled = result.data.values.first as int;
        expect(fkEnabled, equals(1));
      },
    );

    test(
      'deve rejeitar inserção de Turma referenciando Ano Letivo inexistente',
      () async {
        expect(() async {
          await db
              .into(db.classroomsTable)
              .insert(
                ClassroomsTableCompanion.insert(
                  id: 'class-orphan',
                  academicYearId: 'ay-inexistente',
                  name: 'Turma Órfã',
                  gradeLevel: '6º Ano EF',
                  shift: 'morning',
                  createdAt: DateTime.now().toUtc(),
                ),
              );
        }, throwsA(isA<SqliteException>()));
      },
    );

    test('deve impedir exclusão de Ano Letivo quando houver Turmas vinculadas (KeyAction.restrict)', () async {
      const yearId = 'ay-2026';

      // 1. Insere o ano letivo
      await db
          .into(db.academicYearsTable)
          .insert(
            AcademicYearsTableCompanion.insert(
              id: yearId,
              year: 2026,
              title: 'Ano Letivo 2026',
              startDate: DateTime.utc(2026, 2, 2),
              endDate: DateTime.utc(2026, 12, 18),
              createdAt: DateTime.now().toUtc(),
            ),
          );

      // 2. Insere turma vinculada ao ano letivo
      await db
          .into(db.classroomsTable)
          .insert(
            ClassroomsTableCompanion.insert(
              id: 'class-6a',
              academicYearId: yearId,
              name: '6º Ano A',
              gradeLevel: '6º Ano EF',
              shift: 'morning',
              createdAt: DateTime.now().toUtc(),
            ),
          );

      // 3. Tentar deletar o ano letivo deve falhar devido à restrição de chave estrangeira
      expect(() async {
        await (db.delete(
          db.academicYearsTable,
        )..where((tbl) => tbl.id.equals(yearId))).go();
      }, throwsA(isA<SqliteException>()));
    });

    test('deve impedir inserção de turmas com nomes duplicados no mesmo ano letivo (UniqueKey)', () async {
      const yearId = 'ay-2026-uniq';

      await db
          .into(db.academicYearsTable)
          .insert(
            AcademicYearsTableCompanion.insert(
              id: yearId,
              year: 2026,
              title: 'Ano Letivo 2026',
              startDate: DateTime.utc(2026, 2, 2),
              endDate: DateTime.utc(2026, 12, 18),
              createdAt: DateTime.now().toUtc(),
            ),
          );

      await db
          .into(db.classroomsTable)
          .insert(
            ClassroomsTableCompanion.insert(
              id: 'class-1',
              academicYearId: yearId,
              name: '9º Ano A',
              gradeLevel: '9º Ano',
              shift: 'morning',
              createdAt: DateTime.now().toUtc(),
            ),
          );

      // Inserir outra turma com mesmo nome no mesmo ano letivo deve violar unicidade
      expect(() async {
        await db
            .into(db.classroomsTable)
            .insert(
              ClassroomsTableCompanion.insert(
                id: 'class-2',
                academicYearId: yearId,
                name: '9º Ano A',
                gradeLevel: '9º Ano',
                shift: 'morning',
                createdAt: DateTime.now().toUtc(),
              ),
            );
      }, throwsA(isA<SqliteException>()));
    });
  });
}
