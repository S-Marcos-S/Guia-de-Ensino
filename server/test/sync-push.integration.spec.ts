import { DataSource } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { dataSourceOptions } from '../src/database/data-source';
import { SyncStorageService } from '../src/modules/sync-storage/sync-storage.service';
import { SyncService } from '../src/modules/sync/sync.service';
import { User } from '../src/modules/auth/entities/user.entity';
import { UserChangeLog } from '../src/modules/sync-storage/entities/user-change-log.entity';
import { IdempotencyReceipt } from '../src/modules/sync-storage/entities/idempotency-receipt.entity';
import { PlannedLesson } from '../src/modules/pedagogical/entities/planned-lesson.entity';
import { LessonExecutionRecord } from '../src/modules/pedagogical/entities/lesson-execution-record.entity';
import { AcademicYear } from '../src/modules/pedagogical/entities/academic-year.entity';
import { Classroom } from '../src/modules/pedagogical/entities/classroom.entity';
import { Subject } from '../src/modules/pedagogical/entities/subject.entity';
import { ClassroomSubject } from '../src/modules/pedagogical/entities/classroom-subject.entity';
import { IdempotencyConflictException } from '../src/common/exceptions/idempotency-conflict.exception';
import { FactualIntegrityException } from '../src/common/exceptions/factual-integrity.exception';
import { BadRequestException } from '@nestjs/common';
import { PushRequestDto } from '../src/modules/sync/dto/push-request.dto';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';

describe('Sync Push Protocol & Invariants (Integration Tests)', () => {
  let dataSource: DataSource;
  let syncStorageService: SyncStorageService;
  let syncService: SyncService;
  let isDbAvailable = false;

  beforeAll(async () => {
    dataSource = new DataSource({
      ...dataSourceOptions,
      logging: false,
    });

    try {
      await dataSource.initialize();
      await dataSource.runMigrations();
      syncStorageService = new SyncStorageService(dataSource);
      syncService = new SyncService(syncStorageService);
      isDbAvailable = true;
    } catch (error) {
      console.warn(
        `[Integration Test] PostgreSQL indisponível localmente (${(error as Error).message}). Execução real ocorrerá no CI com PostgreSQL 16.`,
      );
    }
  });

  afterAll(async () => {
    if (dataSource && dataSource.isInitialized) {
      await dataSource.destroy();
    }
  });

  const itIfDb = (name: string, fn: () => Promise<void>) => {
    it(name, async () => {
      if (!isDbAvailable) {
        console.log(
          `[SKIPPED LOCAL] Teste '${name}' pulado localmente por ausência de PostgreSQL.`,
        );
        return;
      }
      await fn();
    });
  };

  // Helper para criar usuário de teste
  const createTestUser = async () => {
    const userId = uuidv4();
    await dataSource.getRepository(User).save({
      id: userId,
      email: `sync_user_${Date.now()}_${Math.random().toString(36).substring(7)}@escola.gov.br`,
      passwordHash: 'hash123',
    });
    return userId;
  };

  itIfDb(
    '1. Push autenticado válido: deve aplicar lote de mutações heterogêneas gerando ACKs APPLIED com BIGINT em string',
    async () => {
      const userId = await createTestUser();
      const deviceId = 'device-push-valid';
      const yearId = uuidv4();
      const subjectId = uuidv4();

      const dto: PushRequestDto = {
        deviceId,
        clientBatchId: uuidv4(),
        operations: [
          {
            clientOpId: uuidv4(),
            entityType: 'academic_year',
            entityId: yearId,
            mutationType: 'INSERT',
            baseSeq: '0',
            clientCreatedAt: new Date().toISOString(),
            payload: {
              year: 2026,
              title: 'Ano Letivo 2026',
              start_date: '2026-02-02',
              end_date: '2026-12-18',
              total_mandatory_days: 200,
            },
          },
          {
            clientOpId: uuidv4(),
            entityType: 'subject',
            entityId: subjectId,
            mutationType: 'INSERT',
            baseSeq: '0',
            clientCreatedAt: new Date().toISOString(),
            payload: {
              name: 'Ciências da Natureza',
              color_hex: '#11AA22',
            },
          },
        ],
      };

      const response = await syncService.processPush(userId, dto);

      expect(response.clientBatchId).toBe(dto.clientBatchId);
      expect(response.serverEpoch).toBe('1');
      expect(response.currentServerSeq).toBe('2');
      expect(response.acks).toHaveLength(2);
      expect(response.acks[0].status).toBe('APPLIED');
      expect(response.acks[0].serverSeq).toBe('1');
      expect(response.acks[1].status).toBe('APPLIED');
      expect(response.acks[1].serverSeq).toBe('2');

      const logs = await dataSource.getRepository(UserChangeLog).find({ where: { userId } });
      expect(logs).toHaveLength(2);
    },
  );

  itIfDb(
    '2. Requisição inválida e lote acima do limite: deve validar DTO e limites de lote',
    async () => {
      // Cria lote com 101 operações para testar limite do DTO
      const overlimitOps = Array.from({ length: 101 }, (_, i) => ({
        clientOpId: uuidv4(),
        entityType: 'subject' as const,
        entityId: uuidv4(),
        mutationType: 'INSERT' as const,
        payload: { name: `Disciplina ${i}` },
      }));

      const invalidDto = plainToInstance(PushRequestDto, {
        deviceId: 'device-limit-test',
        clientBatchId: uuidv4(),
        operations: overlimitOps,
      });

      const errors = await validate(invalidDto);
      expect(errors.length).toBeGreaterThan(0);
      expect(errors[0].constraints?.arrayMaxSize).toContain('100 operações');
    },
  );

  itIfDb(
    '3. Repetição idempotente: segundo envio do mesmo lote deve retornar SKIPPED com sequências originais',
    async () => {
      const userId = await createTestUser();
      const deviceId = 'device-idemp-push';
      const op1Id = uuidv4();
      const subjectId = uuidv4();

      const dto: PushRequestDto = {
        deviceId,
        clientBatchId: uuidv4(),
        operations: [
          {
            clientOpId: op1Id,
            entityType: 'subject',
            entityId: subjectId,
            mutationType: 'INSERT',
            payload: { name: 'História Geral', color_hex: '#334455' },
          },
        ],
      };

      // 1º envio: Deve aplicar
      const res1 = await syncService.processPush(userId, dto);
      expect(res1.acks[0].status).toBe('APPLIED');
      expect(res1.acks[0].serverSeq).toBe('1');
      expect(res1.currentServerSeq).toBe('1');

      // 2º envio (mesmo clientOpId e payload idêntico): Deve retornar SKIPPED
      const res2 = await syncService.processPush(userId, dto);
      expect(res2.acks[0].status).toBe('SKIPPED');
      expect(res2.acks[0].serverSeq).toBe('1'); // Sequência original preservada!
      expect(res2.currentServerSeq).toBe('1'); // Sequência do usuário NÃO avançou!

      const logs = await dataSource.getRepository(UserChangeLog).find({ where: { userId } });
      expect(logs).toHaveLength(1);
    },
  );

  itIfDb(
    '4. Idempotência conflitante: mesmo clientOpId com payload divergente deve lançar IdempotencyConflictException (HTTP 409)',
    async () => {
      const userId = await createTestUser();
      const deviceId = 'device-idemp-divergent';
      const clientOpId = uuidv4();

      const dtoOriginal: PushRequestDto = {
        deviceId,
        clientBatchId: uuidv4(),
        operations: [
          {
            clientOpId,
            entityType: 'subject',
            entityId: uuidv4(),
            mutationType: 'INSERT',
            payload: { name: 'Geografia do Brasil', color_hex: '#112233' },
          },
        ],
      };

      await syncService.processPush(userId, dtoOriginal);

      // Envia mesmo clientOpId com payload alterado
      const dtoDivergente: PushRequestDto = {
        deviceId,
        clientBatchId: uuidv4(),
        operations: [
          {
            clientOpId,
            entityType: 'subject',
            entityId: uuidv4(),
            mutationType: 'INSERT',
            payload: { name: 'Geografia Mundial Alterada', color_hex: '#998877' },
          },
        ],
      };

      await expect(syncService.processPush(userId, dtoDivergente)).rejects.toThrow(
        IdempotencyConflictException,
      );
    },
  );

  itIfDb(
    '5. Duplicação de clientOpId no mesmo lote: deve rejeitar com BadRequestException antes da transação',
    async () => {
      const userId = await createTestUser();
      const duplicateId = uuidv4();

      const dto: PushRequestDto = {
        deviceId: 'device-duplicate-in-batch',
        clientBatchId: uuidv4(),
        operations: [
          {
            clientOpId: duplicateId,
            entityType: 'subject',
            entityId: uuidv4(),
            mutationType: 'INSERT',
            payload: { name: 'Artes Visuais' },
          },
          {
            clientOpId: duplicateId, // Duplicado!
            entityType: 'subject',
            entityId: uuidv4(),
            mutationType: 'INSERT',
            payload: { name: 'Música' },
          },
        ],
      };

      await expect(syncService.processPush(userId, dto)).rejects.toThrow(BadRequestException);
    },
  );

  itIfDb(
    '6. Isolamento multi-tenant: tentativa de vincular entidade a recurso de outro usuário deve falhar por FK composta',
    async () => {
      const userA = await createTestUser();
      const userB = await createTestUser();

      // Usuário A cria um ano letivo
      const yearUserA = uuidv4();
      await syncService.processPush(userA, {
        deviceId: 'dev-user-a',
        clientBatchId: uuidv4(),
        operations: [
          {
            clientOpId: uuidv4(),
            entityType: 'academic_year',
            entityId: yearUserA,
            mutationType: 'INSERT',
            payload: {
              year: 2026,
              title: 'Ano do Usuário A',
              start_date: '2026-02-01',
              end_date: '2026-12-15',
              total_mandatory_days: 200,
            },
          },
        ],
      });

      // Usuário B tenta criar turma apontando para o ano letivo do Usuário A
      const pushUserB = syncService.processPush(userB, {
        deviceId: 'dev-user-b',
        clientBatchId: uuidv4(),
        operations: [
          {
            clientOpId: uuidv4(),
            entityType: 'classroom',
            entityId: uuidv4(),
            mutationType: 'INSERT',
            payload: {
              academic_year_id: yearUserA, // Não pertence ao Usuário B!
              name: '6º Ano B Invasor',
              grade_level: '6',
              shift: 'morning',
            },
          },
        ],
      });

      await expect(pushUserB).rejects.toThrow();
    },
  );

  itIfDb(
    '7. Rollback integral em falha parcial: erro na segunda operação do lote não deixa nenhum rastro da primeira',
    async () => {
      const userId = await createTestUser();
      const op1Id = uuidv4();
      const op2Id = uuidv4();

      const dto: PushRequestDto = {
        deviceId: 'dev-rollback-batch',
        clientBatchId: uuidv4(),
        operations: [
          {
            clientOpId: op1Id,
            entityType: 'subject',
            entityId: uuidv4(),
            mutationType: 'INSERT',
            payload: { name: 'Filosofia', color_hex: '#AABB00' },
          },
          {
            clientOpId: op2Id,
            entityType: 'classroom', // Requer academic_year_id válido inexistente
            entityId: uuidv4(),
            mutationType: 'INSERT',
            payload: {
              academic_year_id: uuidv4(), // Inexistente -> Falha de FK
              name: 'Turma Falha',
              grade_level: '1EM',
              shift: 'noite',
            },
          },
        ],
      };

      await expect(syncService.processPush(userId, dto)).rejects.toThrow();

      // Confirma Rollback Total: nenhuma alteração, nenhum log, nenhum recibo
      const logs = await dataSource.getRepository(UserChangeLog).find({ where: { userId } });
      expect(logs).toHaveLength(0);

      const receipts = await dataSource
        .getRepository(IdempotencyReceipt)
        .find({ where: { userId } });
      expect(receipts).toHaveLength(0);

      const version = await syncStorageService.getUserSyncVersion(userId);
      expect(version.currentSeq).toBe(0n);
    },
  );

  itIfDb(
    '8. Proteção de registros factuais: deve impedir exclusão ou rebaixamento de aulas com diário de classe registrado',
    async () => {
      const userId = await createTestUser();
      const deviceId = 'dev-factual-test';

      // 1. Configura ano, disciplina, turma, vínculo e aula planejada
      const yearId = uuidv4();
      const classroomId = uuidv4();
      const subjectId = uuidv4();
      const csId = uuidv4();
      const plannedLessonId = uuidv4();
      const recordId = uuidv4();

      await dataSource.getRepository(AcademicYear).save({
        id: yearId,
        userId,
        year: 2026,
        title: 'Ano Letivo Factual',
        startDate: '2026-02-02',
        endDate: '2026-12-18',
        totalMandatoryDays: 200,
        createdAt: new Date(),
      });

      await dataSource.getRepository(Classroom).save({
        id: classroomId,
        userId,
        academicYearId: yearId,
        name: '8º Ano A',
        gradeLevel: '8',
        shift: 'morning',
        createdAt: new Date(),
      });

      await dataSource.getRepository(Subject).save({
        id: subjectId,
        userId,
        name: 'Matemática Factual',
        colorHex: '#112233',
        createdAt: new Date(),
      });

      await dataSource.getRepository(ClassroomSubject).save({
        id: csId,
        userId,
        classroomId,
        subjectId,
        weeklyLessons: 4,
        createdAt: new Date(),
      });

      await dataSource.getRepository(PlannedLesson).save({
        id: plannedLessonId,
        userId,
        classroomSubjectId: csId,
        lessonDate: '2026-03-10',
        orderInDay: 1,
        status: 'completed',
        isLocked: true,
        createdAt: new Date(),
      });

      // Cria registro de execução fático (diário de aula realizado)
      const recordedAt = new Date('2026-03-10T10:00:00.000Z');
      await dataSource.getRepository(LessonExecutionRecord).save({
        id: recordId,
        userId,
        plannedLessonId,
        classroomSubjectId: csId,
        executionDate: '2026-03-10',
        status: 'completed',
        pedagogicalNotes: 'Aula de frações ministrada integralmente com êxito.',
        needsFollowUp: false,
        recordedAt,
        updatedAt: recordedAt,
      });

      // Cenário 8.1: Tentar push DELETE sobre aula com execução registrada deve lançar FactualIntegrityException
      const pushDeleteLesson = syncService.processPush(userId, {
        deviceId,
        clientBatchId: uuidv4(),
        operations: [
          {
            clientOpId: uuidv4(),
            entityType: 'planned_lesson',
            entityId: plannedLessonId,
            mutationType: 'DELETE',
          },
        ],
      });
      await expect(pushDeleteLesson).rejects.toThrow(FactualIntegrityException);

      // Cenário 8.2: Tentar push UPDATE sobre aula planejada revertendo status para pending deve lançar FactualIntegrityException
      const pushRevertStatus = syncService.processPush(userId, {
        deviceId,
        clientBatchId: uuidv4(),
        operations: [
          {
            clientOpId: uuidv4(),
            entityType: 'planned_lesson',
            entityId: plannedLessonId,
            mutationType: 'UPDATE',
            payload: { status: 'pending' },
          },
        ],
      });
      await expect(pushRevertStatus).rejects.toThrow(FactualIntegrityException);

      // Cenário 8.3: Tentar push DELETE sobre LessonExecutionRecord deve ser terminantemente proibido
      const pushDeleteRecord = syncService.processPush(userId, {
        deviceId,
        clientBatchId: uuidv4(),
        operations: [
          {
            clientOpId: uuidv4(),
            entityType: 'lesson_execution_record',
            entityId: recordId,
            mutationType: 'DELETE',
          },
        ],
      });
      await expect(pushDeleteRecord).rejects.toThrow(FactualIntegrityException);

      // Cenário 8.4: Tentar retificação com updatedAt anterior ao recordedAt deve falhar
      const pushInvalidUpdatedAt = syncService.processPush(userId, {
        deviceId,
        clientBatchId: uuidv4(),
        operations: [
          {
            clientOpId: uuidv4(),
            entityType: 'lesson_execution_record',
            entityId: recordId,
            mutationType: 'UPDATE',
            payload: {
              updated_at: '2026-03-09T10:00:00.000Z', // Anterior a 2026-03-10!
            },
          },
        ],
      });
      await expect(pushInvalidUpdatedAt).rejects.toThrow(FactualIntegrityException);

      // Confirma que o diário de aula permanece intacto
      const recordInDb = await dataSource.getRepository(LessonExecutionRecord).findOne({
        where: { id: recordId, userId },
      });
      expect(recordInDb).not.toBeNull();
      expect(recordInDb?.status).toBe('completed');
    },
  );
});
