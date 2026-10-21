import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/persistence/repositories/drift_lesson_execution_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_planned_lesson_repository.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('SQLite Migration Tests (Version 5 to 6 - Schema v6)', () {
    test('deve executar onCreate criando todas as 16 tabelas e índices na versão 6', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      expect(db.schemaVersion, equals(6));

      // 1. Verifica existência de todas as 16 tabelas no sqlite_master
      final tableResult = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
          )
          .get();
      final tableNames = tableResult.map((r) => r.read<String>('name')).toSet();

      const expectedTables = {
        'academic_years_table',
        'classrooms_table',
        'subjects_table',
        'classroom_subjects_table',
        'planned_lessons_table',
        'school_calendar_events_table',
        'schedule_slots_table',
        'curriculum_competencies_table',
        'course_contents_table',
        'content_prerequisites_table',
        'lesson_content_allocations_table',
        'lesson_execution_records_table',
        'execution_content_allocations_table',
        'sync_state_table',
        'sync_tombstones_table',
        'sync_outbox_table',
      };

      for (final table in expectedTables) {
        expect(
          tableNames.contains(table),
          isTrue,
          reason: 'Tabela $table deve existir no SQLite v6',
        );
      }

      // 2. Verifica existência dos índices de sincronização
      final indexResult = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%';",
          )
          .get();
      final indexNames = indexResult.map((r) => r.read<String>('name')).toSet();

      expect(indexNames.contains('idx_sync_outbox_status'), isTrue);
      expect(indexNames.contains('idx_sync_tombstones_entity'), isTrue);

      // 3. Verifica a presença da coluna updated_at nas 8 tabelas de entidades
      const entityTables = [
        'academic_years_table',
        'classrooms_table',
        'subjects_table',
        'classroom_subjects_table',
        'planned_lessons_table',
        'school_calendar_events_table',
        'schedule_slots_table',
        'course_contents_table',
      ];

      for (final table in entityTables) {
        final pragmaResult = await db
            .customSelect("PRAGMA table_info('$table');")
            .get();
        final cols = pragmaResult.map((r) => r.read<String>('name')).toList();
        expect(
          cols.contains('updated_at'),
          isTrue,
          reason: 'Tabela $table deve possuir a coluna updated_at',
        );
      }

      // lesson_execution_records_table já possuía updated_at desde v5
      final execPragma = await db
          .customSelect("PRAGMA table_info('lesson_execution_records_table');")
          .get();
      final execCols = execPragma.map((r) => r.read<String>('name')).toList();
      expect(execCols.contains('updated_at'), isTrue);

      await db.close();
    });

    test('deve aplicar onUpgrade de v5 para v6 preservando todos os dados legados e adicionando colunas updatedAt nulas', () async {
      final rawDb = NativeDatabase.memory();
      final v5Db = AppDatabase.forTesting(rawDb);
      final migrator = v5Db.createMigrator();

      // 1. Cria as 13 tabelas usando Migrator
      await migrator.createTable(v5Db.academicYearsTable);
      await migrator.createTable(v5Db.subjectsTable);
      await migrator.createTable(v5Db.classroomsTable);
      await migrator.createTable(v5Db.classroomSubjectsTable);
      await migrator.createTable(v5Db.plannedLessonsTable);
      await migrator.createTable(v5Db.schoolCalendarEventsTable);
      await migrator.createTable(v5Db.scheduleSlotsTable);
      await migrator.createTable(v5Db.curriculumCompetenciesTable);
      await migrator.createTable(v5Db.courseContentsTable);
      await migrator.createTable(v5Db.contentPrerequisitesTable);
      await migrator.createTable(v5Db.lessonContentAllocationsTable);
      await migrator.createTable(v5Db.lessonExecutionRecordsTable);
      await migrator.createTable(v5Db.executionContentAllocationsTable);

      // Simula Schema v5 exato: remove a coluna updated_at das 8 tabelas de entidades
      for (final table in [
        'academic_years_table',
        'classrooms_table',
        'subjects_table',
        'classroom_subjects_table',
        'planned_lessons_table',
        'school_calendar_events_table',
        'schedule_slots_table',
        'course_contents_table',
      ]) {
        await v5Db.customStatement(
          'ALTER TABLE $table DROP COLUMN updated_at;',
        );
      }

      // Timestamps inteiros em segundos (padrão DateTimeColumn do Drift)
      final createdAtSec =
          DateTime.utc(2026, 1, 10, 8, 0).millisecondsSinceEpoch ~/ 1000;
      final recordedAtSec =
          DateTime.utc(2026, 2, 5, 12, 0).millisecondsSinceEpoch ~/ 1000;

      // Insere dados representativos em v5
      await v5Db.customStatement('''
          INSERT INTO academic_years_table (id, year, title, start_date, end_date, total_mandatory_days, created_at)
          VALUES ('ay-v5-legacy', 2026, 'Ano Letivo 2026', '2026-02-02', '2026-12-18', 200, $createdAtSec);
        ''');

      await v5Db.customStatement('''
          INSERT INTO classrooms_table (id, academic_year_id, name, grade_level, shift, created_at)
          VALUES ('c-v5-legacy', 'ay-v5-legacy', '7º Ano B', '7º Ano', 'morning', $createdAtSec);
        ''');

      await v5Db.customStatement('''
          INSERT INTO subjects_table (id, name, color_hex, created_at)
          VALUES ('s-v5-legacy', 'Matemática', '#2196F3', $createdAtSec);
        ''');

      await v5Db.customStatement('''
          INSERT INTO classroom_subjects_table (id, classroom_id, subject_id, weekly_lessons, created_at)
          VALUES ('cs-v5-legacy', 'c-v5-legacy', 's-v5-legacy', 5, $createdAtSec);
        ''');

      await v5Db.customStatement('''
          INSERT INTO course_contents_table (id, classroom_subject_id, title, description, order_index, is_mandatory, origin, created_at)
          VALUES ('cnt-v5-legacy', 'cs-v5-legacy', 'Números Inteiros', 'Operações fundamentais', 1, 1, 'manual', $createdAtSec);
        ''');

      await v5Db.customStatement('''
          INSERT INTO planned_lessons_table (id, classroom_subject_id, lesson_date, order_in_day, status, is_locked, notes, created_at)
          VALUES ('l-v5-legacy', 'cs-v5-legacy', '2026-02-05', 1, 'completed', 0, 'Aula inaugural', $createdAtSec);
        ''');

      await v5Db.customStatement('''
          INSERT INTO lesson_content_allocations_table (lesson_id, content_id, order_index)
          VALUES ('l-v5-legacy', 'cnt-v5-legacy', 1);
        ''');

      await v5Db.customStatement('''
          INSERT INTO school_calendar_events_table (id, academic_year_id, title, start_date, end_date, type, affects_classes, created_at)
          VALUES ('ev-v5-legacy', 'ay-v5-legacy', 'Carnaval', '2026-02-16', '2026-02-18', 'holiday', 1, $createdAtSec);
        ''');

      await v5Db.customStatement('''
          INSERT INTO schedule_slots_table (id, classroom_subject_id, weekday, order_index, start_time, end_time, created_at)
          VALUES ('sl-v5-legacy', 'cs-v5-legacy', 1, 1, '07:30', '08:20', $createdAtSec);
        ''');

      await v5Db.customStatement('''
          INSERT INTO curriculum_competencies_table (id, code, description, thematic_unit, stage, grade_level, subject_name, source_name, source_version, created_at)
          VALUES ('comp-v5-legacy', 'EF07MA01', 'Resolver problemas com inteiros', 'Números', 'Ensino Fundamental', '7º Ano', 'Matemática', 'BNCC', '1.0', $createdAtSec);
        ''');

      await v5Db.customStatement('''
          INSERT INTO lesson_execution_records_table (id, planned_lesson_id, classroom_subject_id, execution_date, status, pedagogical_notes, needs_follow_up, recorded_at, updated_at)
          VALUES ('rec-v5-legacy', 'l-v5-legacy', 'cs-v5-legacy', '2026-02-05', 'completed', 'Concluído com êxito', 0, $recordedAtSec, NULL);
        ''');

      await v5Db.customStatement('''
          INSERT INTO execution_content_allocations_table (record_id, content_id, order_index)
          VALUES ('rec-v5-legacy', 'cnt-v5-legacy', 1);
        ''');

      // Executa a migração v5 -> v6
      await v5Db.migration.onUpgrade(migrator, 5, 6);

      // 1. Verifica integridade absoluta dos dados legados pré-existentes
      final ayRows = await v5Db
          .customSelect(
            "SELECT * FROM academic_years_table WHERE id = 'ay-v5-legacy';",
          )
          .get();
      expect(ayRows.length, equals(1));
      expect(ayRows.first.read<String>('title'), equals('Ano Letivo 2026'));
      expect(ayRows.first.read<DateTime?>('updated_at'), isNull);

      final classRows = await v5Db
          .customSelect(
            "SELECT * FROM classrooms_table WHERE id = 'c-v5-legacy';",
          )
          .get();
      expect(classRows.length, equals(1));
      expect(classRows.first.read<String>('name'), equals('7º Ano B'));
      expect(classRows.first.read<DateTime?>('updated_at'), isNull);

      final subjRows = await v5Db
          .customSelect(
            "SELECT * FROM subjects_table WHERE id = 's-v5-legacy';",
          )
          .get();
      expect(subjRows.length, equals(1));
      expect(subjRows.first.read<String>('name'), equals('Matemática'));
      expect(subjRows.first.read<DateTime?>('updated_at'), isNull);

      final csRows = await v5Db
          .customSelect(
            "SELECT * FROM classroom_subjects_table WHERE id = 'cs-v5-legacy';",
          )
          .get();
      expect(csRows.length, equals(1));
      expect(csRows.first.read<int>('weekly_lessons'), equals(5));
      expect(csRows.first.read<DateTime?>('updated_at'), isNull);

      final lessonRows = await v5Db
          .customSelect(
            "SELECT * FROM planned_lessons_table WHERE id = 'l-v5-legacy';",
          )
          .get();
      expect(lessonRows.length, equals(1));
      expect(lessonRows.first.read<String>('notes'), equals('Aula inaugural'));
      expect(lessonRows.first.read<DateTime?>('updated_at'), isNull);

      final contentRows = await v5Db
          .customSelect(
            "SELECT * FROM course_contents_table WHERE id = 'cnt-v5-legacy';",
          )
          .get();
      expect(contentRows.length, equals(1));
      expect(
        contentRows.first.read<String>('title'),
        equals('Números Inteiros'),
      );
      expect(contentRows.first.read<DateTime?>('updated_at'), isNull);

      final eventRows = await v5Db
          .customSelect(
            "SELECT * FROM school_calendar_events_table WHERE id = 'ev-v5-legacy';",
          )
          .get();
      expect(eventRows.length, equals(1));
      expect(eventRows.first.read<DateTime?>('updated_at'), isNull);

      final slotRows = await v5Db
          .customSelect(
            "SELECT * FROM schedule_slots_table WHERE id = 'sl-v5-legacy';",
          )
          .get();
      expect(slotRows.length, equals(1));
      expect(slotRows.first.read<DateTime?>('updated_at'), isNull);

      // Repositórios de domínio legados continuam operacionais
      final plannedRepo = DriftPlannedLessonRepository(v5Db);
      final retrievedLesson = await plannedRepo.findById('l-v5-legacy');
      expect(retrievedLesson, isNotNull);
      expect(retrievedLesson!.id, equals('l-v5-legacy'));
      expect(retrievedLesson.contentIds, equals(['cnt-v5-legacy']));

      final execRepo = DriftLessonExecutionRepository(v5Db);
      final retrievedExec = await execRepo.findById('rec-v5-legacy');
      expect(retrievedExec, isNotNull);
      expect(retrievedExec!.id, equals('rec-v5-legacy'));
      expect(retrievedExec.actualContentIds, equals(['cnt-v5-legacy']));

      // 2. Verifica tabelas novas vazias e prontas
      final syncStateRows = await v5Db
          .customSelect('SELECT * FROM sync_state_table;')
          .get();
      expect(syncStateRows, isEmpty);

      final outboxRows = await v5Db
          .customSelect('SELECT * FROM sync_outbox_table;')
          .get();
      expect(outboxRows, isEmpty);

      final tombRows = await v5Db
          .customSelect('SELECT * FROM sync_tombstones_table;')
          .get();
      expect(tombRows, isEmpty);

      await v5Db.close();
    });

    test('deve suportar migrações encadeadas a partir de versões históricas v1 até v6', () async {
      final rawDb = NativeDatabase.memory();
      final db = AppDatabase.forTesting(rawDb);
      final migrator = db.createMigrator();

      // 1. Cria tabelas de v1 usando Migrator
      await migrator.createTable(db.academicYearsTable);
      await migrator.createTable(db.subjectsTable);
      await migrator.createTable(db.classroomsTable);
      await migrator.createTable(db.classroomSubjectsTable);
      await migrator.createTable(db.plannedLessonsTable);

      // Simula Schema v1 exato: remove a coluna updated_at das 5 tabelas
      for (final table in [
        'academic_years_table',
        'subjects_table',
        'classrooms_table',
        'classroom_subjects_table',
        'planned_lessons_table',
      ]) {
        await db.customStatement('ALTER TABLE $table DROP COLUMN updated_at;');
      }

      // Executa migração direta de v1 para v6
      await db.migration.onUpgrade(migrator, 1, 6);

      // Verifica se todas as 16 tabelas foram criadas
      final tableResult = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
          )
          .get();
      final tableNames = tableResult.map((r) => r.read<String>('name')).toSet();

      expect(tableNames.contains('school_calendar_events_table'), isTrue); // v2
      expect(tableNames.contains('course_contents_table'), isTrue); // v3
      expect(
        tableNames.contains('lesson_content_allocations_table'),
        isTrue,
      ); // v4
      expect(
        tableNames.contains('lesson_execution_records_table'),
        isTrue,
      ); // v5
      expect(tableNames.contains('sync_state_table'), isTrue); // v6
      expect(tableNames.contains('sync_tombstones_table'), isTrue); // v6
      expect(tableNames.contains('sync_outbox_table'), isTrue); // v6

      await db.close();
    });

    test(
      'deve permitir operações e validar constraints na SyncStateTable',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());

        // Insere estado inicial
        await db.customStatement('''
        INSERT INTO sync_state_table (id, device_id, local_revision, account_epoch, last_sync_status, updated_at)
        VALUES ('default', 'device-test-uuid', 0, 1, 'idle', 1768032000);
      ''');

        final rows = await db
            .customSelect(
              "SELECT * FROM sync_state_table WHERE id = 'default';",
            )
            .get();
        expect(rows.length, equals(1));
        expect(
          rows.first.read<String>('device_id'),
          equals('device-test-uuid'),
        );
        expect(rows.first.read<int>('local_revision'), equals(0));
        expect(rows.first.read<int>('account_epoch'), equals(1));
        expect(rows.first.read<String>('last_sync_status'), equals('idle'));
        expect(rows.first.read<String?>('server_cursor'), isNull);

        // Atualiza estado de sincronização
        await db.customStatement('''
        UPDATE sync_state_table
        SET local_revision = 42,
            server_cursor = 'seq-98765',
            last_sync_status = 'success',
            last_synced_at = 1768033800,
            updated_at = 1768033800
        WHERE id = 'default';
      ''');

        final updated = await db
            .customSelect(
              "SELECT * FROM sync_state_table WHERE id = 'default';",
            )
            .get();
        expect(updated.first.read<int>('local_revision'), equals(42));
        expect(
          updated.first.read<String>('server_cursor'),
          equals('seq-98765'),
        );
        expect(
          updated.first.read<String>('last_sync_status'),
          equals('success'),
        );

        // Tenta inserir linha duplicada com mesma chave primária ('default')
        expect(
          () async => await db.customStatement('''
          INSERT INTO sync_state_table (id, device_id, local_revision, account_epoch, last_sync_status, updated_at)
          VALUES ('default', 'device-duplicate', 1, 1, 'idle', 1768035600);
        '''),
          throwsA(isA<SqliteException>()),
        );

        await db.close();
      },
    );

    test(
      'deve permitir operações e validar constraints na SyncTombstonesTable',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());

        // Insere lápide para entidade excluída
        await db.customStatement('''
          INSERT INTO sync_tombstones_table (id, entity_type, entity_id, operation_id, deleted_at, local_revision, synced)
          VALUES ('tomb-1', 'classroom', 'c-deleted-10', 'op-del-10', 1768032000, 15, 0);
        ''');

        final rows = await db
            .customSelect(
              "SELECT * FROM sync_tombstones_table WHERE entity_type = 'classroom' AND entity_id = 'c-deleted-10';",
            )
            .get();
        expect(rows.length, equals(1));
        expect(rows.first.read<String>('operation_id'), equals('op-del-10'));
        expect(rows.first.read<int>('local_revision'), equals(15));
        expect(rows.first.read<bool>('synced'), isFalse);

        // Marca lápide como sincronizada
        await db.customStatement('''
          UPDATE sync_tombstones_table SET synced = 1 WHERE id = 'tomb-1';
        ''');
        final syncedRows = await db
            .customSelect(
              "SELECT synced FROM sync_tombstones_table WHERE id = 'tomb-1';",
            )
            .get();
        expect(syncedRows.first.read<bool>('synced'), isTrue);

        // Tenta inserir lápide duplicada com a mesma tupla única (entity_type, entity_id)
        expect(
          () async => await db.customStatement('''
            INSERT INTO sync_tombstones_table (id, entity_type, entity_id, operation_id, deleted_at, local_revision, synced)
            VALUES ('tomb-duplicate', 'classroom', 'c-deleted-10', 'op-del-11', 1768032300, 16, 0);
          '''),
          throwsA(isA<SqliteException>()),
        );

        await db.close();
      },
    );

    test(
      'deve permitir operações e validar FIFO/ordenacao na SyncOutboxTable',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());

        // Insere mutações na fila de saída com revisões incrementais
        await db.customStatement('''
          INSERT INTO sync_outbox_table (operation_id, entity_type, entity_id, operation, payload_json, local_revision, status, created_at)
          VALUES ('op-1', 'subject', 's-1', 'create', '{"name":"Arte"}', 1, 'pending', 1768032000);
        ''');
        await db.customStatement('''
          INSERT INTO sync_outbox_table (operation_id, entity_type, entity_id, operation, payload_json, local_revision, status, created_at)
          VALUES ('op-2', 'classroom', 'c-1', 'create', '{"name":"6A"}', 2, 'pending', 1768032060);
        ''');
        await db.customStatement('''
          INSERT INTO sync_outbox_table (operation_id, entity_type, entity_id, operation, payload_json, local_revision, status, created_at)
          VALUES ('op-3', 'subject', 's-1', 'update', '{"colorHex":"#E91E63"}', 3, 'in_flight', 1768032120);
        ''');

        // Consulta itens pendentes ordenados por local_revision ASC (ordem FIFO determinística)
        final pendingRows = await db
            .customSelect(
              "SELECT * FROM sync_outbox_table WHERE status = 'pending' ORDER BY local_revision ASC;",
            )
            .get();

        expect(pendingRows.length, equals(2));
        expect(pendingRows[0].read<String>('operation_id'), equals('op-1'));
        expect(pendingRows[1].read<String>('operation_id'), equals('op-2'));

        // Tenta inserir com mesma chave primária operation_id
        expect(
          () async => await db.customStatement('''
            INSERT INTO sync_outbox_table (operation_id, entity_type, entity_id, operation, payload_json, local_revision, status, created_at)
            VALUES ('op-1', 'subject', 's-1', 'update', '{}', 4, 'pending', 1768032300);
          '''),
          throwsA(isA<SqliteException>()),
        );

        await db.close();
      },
    );

    test('deve permitir gravacao e atualizacao de updatedAt nas 8 tabelas de entidades', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());

      const nowSec = 1768032000; // 2026-01-10 08:00:00 UTC
      const updatedSec = 1768041000; // 2026-01-10 10:30:00 UTC
      final expectedUpdated = DateTime.fromMillisecondsSinceEpoch(
        updatedSec * 1000,
        isUtc: true,
      );

      // 1. AcademicYearsTable
      await db.customStatement('''
          INSERT INTO academic_years_table (id, year, title, start_date, end_date, total_mandatory_days, created_at, updated_at)
          VALUES ('ay-upd-test', 2026, 'Ano Letivo Teste', '2026-02-02', '2026-12-18', 200, $nowSec, NULL);
        ''');
      await db.customStatement('''
          UPDATE academic_years_table SET updated_at = $updatedSec WHERE id = 'ay-upd-test';
        ''');
      var row = await db
          .customSelect(
            "SELECT updated_at FROM academic_years_table WHERE id = 'ay-upd-test';",
          )
          .getSingle();
      expect(
        row.read<DateTime?>('updated_at')?.toUtc(),
        equals(expectedUpdated),
      );

      // 2. ClassroomsTable
      await db.customStatement('''
          INSERT INTO classrooms_table (id, academic_year_id, name, grade_level, shift, created_at, updated_at)
          VALUES ('c-upd-test', 'ay-upd-test', 'Turma Teste', '6º Ano', 'morning', $nowSec, NULL);
        ''');
      await db.customStatement('''
          UPDATE classrooms_table SET updated_at = $updatedSec WHERE id = 'c-upd-test';
        ''');
      row = await db
          .customSelect(
            "SELECT updated_at FROM classrooms_table WHERE id = 'c-upd-test';",
          )
          .getSingle();
      expect(
        row.read<DateTime?>('updated_at')?.toUtc(),
        equals(expectedUpdated),
      );

      // 3. SubjectsTable
      await db.customStatement('''
          INSERT INTO subjects_table (id, name, color_hex, created_at, updated_at)
          VALUES ('s-upd-test', 'Ciências', '#4CAF50', $nowSec, NULL);
        ''');
      await db.customStatement('''
          UPDATE subjects_table SET updated_at = $updatedSec WHERE id = 's-upd-test';
        ''');
      row = await db
          .customSelect(
            "SELECT updated_at FROM subjects_table WHERE id = 's-upd-test';",
          )
          .getSingle();
      expect(
        row.read<DateTime?>('updated_at')?.toUtc(),
        equals(expectedUpdated),
      );

      // 4. ClassroomSubjectsTable
      await db.customStatement('''
          INSERT INTO classroom_subjects_table (id, classroom_id, subject_id, weekly_lessons, created_at, updated_at)
          VALUES ('cs-upd-test', 'c-upd-test', 's-upd-test', 3, $nowSec, NULL);
        ''');
      await db.customStatement('''
          UPDATE classroom_subjects_table SET updated_at = $updatedSec WHERE id = 'cs-upd-test';
        ''');
      row = await db
          .customSelect(
            "SELECT updated_at FROM classroom_subjects_table WHERE id = 'cs-upd-test';",
          )
          .getSingle();
      expect(
        row.read<DateTime?>('updated_at')?.toUtc(),
        equals(expectedUpdated),
      );

      // 5. CourseContentsTable
      await db.customStatement('''
          INSERT INTO course_contents_table (id, classroom_subject_id, title, order_index, origin, created_at, updated_at)
          VALUES ('cnt-upd-test', 'cs-upd-test', 'Células e Tecidos', 1, 'manual', $nowSec, NULL);
        ''');
      await db.customStatement('''
          UPDATE course_contents_table SET updated_at = $updatedSec WHERE id = 'cnt-upd-test';
        ''');
      row = await db
          .customSelect(
            "SELECT updated_at FROM course_contents_table WHERE id = 'cnt-upd-test';",
          )
          .getSingle();
      expect(
        row.read<DateTime?>('updated_at')?.toUtc(),
        equals(expectedUpdated),
      );

      // 6. PlannedLessonsTable
      await db.customStatement('''
          INSERT INTO planned_lessons_table (id, classroom_subject_id, lesson_date, order_in_day, status, created_at, updated_at)
          VALUES ('l-upd-test', 'cs-upd-test', '2026-03-01', 1, 'planned', $nowSec, NULL);
        ''');
      await db.customStatement('''
          UPDATE planned_lessons_table SET updated_at = $updatedSec WHERE id = 'l-upd-test';
        ''');
      row = await db
          .customSelect(
            "SELECT updated_at FROM planned_lessons_table WHERE id = 'l-upd-test';",
          )
          .getSingle();
      expect(
        row.read<DateTime?>('updated_at')?.toUtc(),
        equals(expectedUpdated),
      );

      // 7. SchoolCalendarEventsTable
      await db.customStatement('''
          INSERT INTO school_calendar_events_table (id, academic_year_id, title, start_date, end_date, type, created_at, updated_at)
          VALUES ('ev-upd-test', 'ay-upd-test', 'Feira de Ciências', '2026-05-15', '2026-05-15', 'event', $nowSec, NULL);
        ''');
      await db.customStatement('''
          UPDATE school_calendar_events_table SET updated_at = $updatedSec WHERE id = 'ev-upd-test';
        ''');
      row = await db
          .customSelect(
            "SELECT updated_at FROM school_calendar_events_table WHERE id = 'ev-upd-test';",
          )
          .getSingle();
      expect(
        row.read<DateTime?>('updated_at')?.toUtc(),
        equals(expectedUpdated),
      );

      // 8. ScheduleSlotsTable
      await db.customStatement('''
          INSERT INTO schedule_slots_table (id, classroom_subject_id, weekday, order_index, created_at, updated_at)
          VALUES ('sl-upd-test', 'cs-upd-test', 2, 1, $nowSec, NULL);
        ''');
      await db.customStatement('''
          UPDATE schedule_slots_table SET updated_at = $updatedSec WHERE id = 'sl-upd-test';
        ''');
      row = await db
          .customSelect(
            "SELECT updated_at FROM schedule_slots_table WHERE id = 'sl-upd-test';",
          )
          .getSingle();
      expect(
        row.read<DateTime?>('updated_at')?.toUtc(),
        equals(expectedUpdated),
      );

      await db.close();
    });

    test('deve preservar integridade referencial com foreign keys habilitadas no v6', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());

      const tsSec = 1768032000;

      // Insere base referencial
      await db.customStatement('''
          INSERT INTO academic_years_table (id, year, title, start_date, end_date, total_mandatory_days, created_at)
          VALUES ('ay-fk', 2026, 'Ano FK', '2026-02-02', '2026-12-18', 200, $tsSec);
        ''');
      await db.customStatement('''
          INSERT INTO classrooms_table (id, academic_year_id, name, grade_level, shift, created_at)
          VALUES ('c-fk', 'ay-fk', 'Turma FK', '8A', 'morning', $tsSec);
        ''');
      await db.customStatement('''
          INSERT INTO subjects_table (id, name, color_hex, created_at)
          VALUES ('s-fk', 'Física', '#FF5722', $tsSec);
        ''');
      await db.customStatement('''
          INSERT INTO classroom_subjects_table (id, classroom_id, subject_id, weekly_lessons, created_at)
          VALUES ('cs-fk', 'c-fk', 's-fk', 2, $tsSec);
        ''');
      await db.customStatement('''
          INSERT INTO planned_lessons_table (id, classroom_subject_id, lesson_date, order_in_day, status, created_at)
          VALUES ('l-fk', 'cs-fk', '2026-02-10', 1, 'completed', $tsSec);
        ''');
      await db.customStatement('''
          INSERT INTO lesson_execution_records_table (id, planned_lesson_id, classroom_subject_id, execution_date, status, recorded_at)
          VALUES ('rec-fk', 'l-fk', 'cs-fk', '2026-02-10', 'completed', $tsSec);
        ''');

      // 1. Tentar excluir aula planejada com registro de execução (KeyAction.restrict) deve falhar
      expect(
        () async => await db.customStatement(
          "DELETE FROM planned_lessons_table WHERE id = 'l-fk';",
        ),
        throwsA(isA<SqliteException>()),
      );

      // 2. Tentar excluir ano letivo com turma vinculada (KeyAction.restrict) deve falhar
      expect(
        () async => await db.customStatement(
          "DELETE FROM academic_years_table WHERE id = 'ay-fk';",
        ),
        throwsA(isA<SqliteException>()),
      );

      // 3. Excluir registro de execução histórico e então excluir a aula planejada deve suceder
      await db.customStatement(
        "DELETE FROM lesson_execution_records_table WHERE id = 'rec-fk';",
      );
      await db.customStatement(
        "DELETE FROM planned_lessons_table WHERE id = 'l-fk';",
      );
      final remainingLesson = await db
          .customSelect(
            "SELECT * FROM planned_lessons_table WHERE id = 'l-fk';",
          )
          .get();
      expect(remainingLesson, isEmpty);

      // 4. Cascade delete: ao excluir classroom, classroom_subject deve ser excluído em cascata
      await db.customStatement(
        "DELETE FROM classrooms_table WHERE id = 'c-fk';",
      );
      final remainingCs = await db
          .customSelect(
            "SELECT * FROM classroom_subjects_table WHERE id = 'cs-fk';",
          )
          .get();
      expect(remainingCs, isEmpty);

      await db.close();
    });
  });
}
