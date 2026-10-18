import 'dart:io';

import 'package:app/domain/models/academic_year.dart';
import 'package:app/domain/models/classroom.dart';
import 'package:app/domain/models/schedule_slot.dart';
import 'package:app/domain/models/school_calendar_event.dart';
import 'package:app/domain/models/subject.dart';
import 'package:app/infrastructure/persistence/database/app_database.dart';
import 'package:app/infrastructure/persistence/repositories/drift_academic_year_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_calendar_event_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_classroom_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_schedule_slot_repository.dart';
import 'package:app/infrastructure/persistence/repositories/drift_subject_repository.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late DriftAcademicYearRepository academicYearRepo;
  late DriftSubjectRepository subjectRepo;
  late DriftClassroomRepository classroomRepo;
  late DriftCalendarEventRepository calendarEventRepo;
  late DriftScheduleSlotRepository scheduleSlotRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    academicYearRepo = DriftAcademicYearRepository(db);
    subjectRepo = DriftSubjectRepository(db);
    classroomRepo = DriftClassroomRepository(db);
    calendarEventRepo = DriftCalendarEventRepository(db);
    scheduleSlotRepo = DriftScheduleSlotRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Calendar Events and Schedule Slots Persistence Tests', () {
    test(
      'deve salvar e consultar eventos e feriados escolares por ano letivo',
      () async {
        final academicYear = AcademicYear(
          id: 'ay-2026',
          year: 2026,
          title: 'Ano Letivo 2026',
          startDate: DateTime(2026, 2, 2),
          endDate: DateTime(2026, 12, 18),
        );
        await academicYearRepo.save(academicYear);

        final holiday = SchoolCalendarEvent(
          id: 'ev-tiradentes',
          academicYearId: 'ay-2026',
          title: 'Feriado de Tiradentes',
          startDate: DateTime(2026, 4, 21),
          endDate: DateTime(2026, 4, 21),
          type: SchoolEventType.holiday,
          affectsClasses: true,
        );

        final recess = SchoolCalendarEvent(
          id: 'ev-recesso-julho',
          academicYearId: 'ay-2026',
          title: 'Recesso Escolar de Julho',
          startDate: DateTime(2026, 7, 6),
          endDate: DateTime(2026, 7, 17),
          type: SchoolEventType.recess,
          affectsClasses: true,
        );

        await calendarEventRepo.save(holiday);
        await calendarEventRepo.save(recess);

        final events = await calendarEventRepo.getByAcademicYear('ay-2026');
        expect(events.length, equals(2));
        expect(events.first.id, equals('ev-tiradentes'));
        expect(events.first.title, equals('Feriado de Tiradentes'));
        expect(events.first.type, equals(SchoolEventType.holiday));

        expect(events.last.id, equals('ev-recesso-julho'));
        expect(events.last.type, equals(SchoolEventType.recess));

        // Teste de exclusão de evento
        await calendarEventRepo.delete('ev-tiradentes');
        final remaining = await calendarEventRepo.getByAcademicYear('ay-2026');
        expect(remaining.length, equals(1));
        expect(remaining.first.id, equals('ev-recesso-julho'));
      },
    );

    test('deve salvar e consultar slots da grade semanal vinculados a turma e disciplina', () async {
      final academicYear = AcademicYear(
        id: 'ay-2026',
        year: 2026,
        title: 'Ano Letivo 2026',
        startDate: DateTime(2026, 2, 2),
        endDate: DateTime(2026, 12, 18),
      );
      await academicYearRepo.save(academicYear);

      const math = Subject(
        id: 'sub-mat',
        name: 'Matemática',
        colorHex: '#1E3A8A',
      );
      await subjectRepo.save(math);

      const configId = 'cs-config-9a-mat';
      const classroom = Classroom(
        id: 'cls-9a',
        academicYearId: 'ay-2026',
        name: '9º Ano A',
        gradeLevel: '9º Ano',
        subjectConfigs: [
          ClassroomSubjectConfig(
            id: configId,
            classroomId: 'cls-9a',
            subjectId: 'sub-mat',
            weeklyLessons: 4,
          ),
        ],
      );
      await classroomRepo.save(classroom);

      // Cria 4 slots na semana para Matemática (2 na Segunda, 2 na Quarta)
      final slots = [
        const ScheduleSlot(
          id: 'slot-1',
          classroomSubjectId: configId,
          weekday: 1, // Segunda
          orderIndex: 1,
          startTime: '07:30',
          endTime: '08:20',
        ),
        const ScheduleSlot(
          id: 'slot-2',
          classroomSubjectId: configId,
          weekday: 1, // Segunda
          orderIndex: 2,
          startTime: '08:20',
          endTime: '09:10',
        ),
        const ScheduleSlot(
          id: 'slot-3',
          classroomSubjectId: configId,
          weekday: 3, // Quarta
          orderIndex: 1,
          startTime: '07:30',
          endTime: '08:20',
        ),
        const ScheduleSlot(
          id: 'slot-4',
          classroomSubjectId: configId,
          weekday: 3, // Quarta
          orderIndex: 2,
          startTime: '08:20',
          endTime: '09:10',
        ),
      ];

      await scheduleSlotRepo.saveSlots(configId, slots);

      final fetchedByConfig = await scheduleSlotRepo.getByClassroomSubject(
        configId,
      );
      expect(fetchedByConfig.length, equals(4));
      expect(fetchedByConfig[0].weekday, equals(1));
      expect(fetchedByConfig[0].orderIndex, equals(1));
      expect(fetchedByConfig[0].startTime, equals('07:30'));

      // Consulta agregada por turma (via join com ClassroomSubjectsTable)
      final fetchedByClassroom = await scheduleSlotRepo.getByClassroom(
        'cls-9a',
      );
      expect(fetchedByClassroom.length, equals(4));
    });

    test('deve persistir eventos e slots em disco e recuperá-los após fechar e reabrir o banco', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'guia_etapa3_test_',
      );
      final dbFile = File('${tempDir.path}/persistence_disk_etapa3.sqlite');

      try {
        // Conexão 1: Gravar dados
        final db1 = AppDatabase.forTesting(NativeDatabase(dbFile));
        final yearRepo1 = DriftAcademicYearRepository(db1);
        final subRepo1 = DriftSubjectRepository(db1);
        final classRepo1 = DriftClassroomRepository(db1);
        final eventRepo1 = DriftCalendarEventRepository(db1);
        final slotRepo1 = DriftScheduleSlotRepository(db1);

        await yearRepo1.save(
          AcademicYear(
            id: 'ay-disk-2026',
            year: 2026,
            title: 'Ano Teste Disco',
            startDate: DateTime(2026, 2, 2),
            endDate: DateTime(2026, 12, 18),
            totalMandatoryDays: 200,
          ),
        );

        await eventRepo1.save(
          SchoolCalendarEvent(
            id: 'ev-disk-holiday',
            academicYearId: 'ay-disk-2026',
            title: 'Feriado Independência',
            startDate: DateTime(2026, 9, 7),
            endDate: DateTime(2026, 9, 7),
            type: SchoolEventType.holiday,
            affectsClasses: true,
          ),
        );

        await subRepo1.save(
          const Subject(id: 'sub-hist', name: 'História', colorHex: '#B45309'),
        );

        await classRepo1.save(
          const Classroom(
            id: 'cls-disk-8a',
            academicYearId: 'ay-disk-2026',
            name: '8º Ano A',
            gradeLevel: '8º Ano',
            subjectConfigs: [
              ClassroomSubjectConfig(
                id: 'cs-disk-hist-8a',
                classroomId: 'cls-disk-8a',
                subjectId: 'sub-hist',
                weeklyLessons: 2,
              ),
            ],
          ),
        );

        await slotRepo1.saveSlots('cs-disk-hist-8a', [
          const ScheduleSlot(
            id: 'slot-disk-1',
            classroomSubjectId: 'cs-disk-hist-8a',
            weekday: 2, // Terça
            orderIndex: 3,
            startTime: '09:30',
            endTime: '10:20',
          ),
        ]);

        await db1.close();

        // Conexão 2: Reabertura do mesmo arquivo físico no disco
        final db2 = AppDatabase.forTesting(NativeDatabase(dbFile));
        final eventRepo2 = DriftCalendarEventRepository(db2);
        final slotRepo2 = DriftScheduleSlotRepository(db2);
        final classRepo2 = DriftClassroomRepository(db2);

        final events = await eventRepo2.getByAcademicYear('ay-disk-2026');
        expect(events.length, equals(1));
        expect(events.first.id, equals('ev-disk-holiday'));
        expect(events.first.title, equals('Feriado Independência'));
        expect(events.first.startDate, equals(DateTime.utc(2026, 9, 7)));

        final classrooms = await classRepo2.getByAcademicYear('ay-disk-2026');
        expect(classrooms.length, equals(1));
        expect(classrooms.first.subjectConfigs.length, equals(1));

        final slots = await slotRepo2.getByClassroom('cls-disk-8a');
        expect(slots.length, equals(1));
        expect(slots.first.id, equals('slot-disk-1'));
        expect(slots.first.weekday, equals(2));
        expect(slots.first.orderIndex, equals(3));
        expect(slots.first.startTime, equals('09:30'));

        await db2.close();
      } finally {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        try {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        } catch (_) {
          // Ignora se o SO mantiver lock transitório no arquivo temporário
        }
      }
    });
  });
}
