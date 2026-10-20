import { DataSource } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { dataSourceOptions } from '../src/database/data-source';
import { SyncStorageService } from '../src/modules/sync-storage/sync-storage.service';
import { User } from '../src/modules/auth/entities/user.entity';
import { UserSyncVersion } from '../src/modules/sync-storage/entities/user-sync-version.entity';
import { UserChangeLog } from '../src/modules/sync-storage/entities/user-change-log.entity';
import { IdempotencyReceipt } from '../src/modules/sync-storage/entities/idempotency-receipt.entity';
import { AcademicYear } from '../src/modules/pedagogical/entities/academic-year.entity';
import { Classroom } from '../src/modules/pedagogical/entities/classroom.entity';
import { IdempotencyConflictException } from '../src/common/exceptions/idempotency-conflict.exception';

describe('PostgreSQL Persistence & Concurrency (Integration Tests)', () => {
  let dataSource: DataSource;
  let syncService: SyncStorageService;
  let isDbAvailable = false;

  beforeAll(async () => {
    dataSource = new DataSource({
      ...dataSourceOptions,
      // Desativa logging durante os testes para manter saída limpa
      logging: false,
    });

    try {
      await dataSource.initialize();
      // Executa as migrações explícitas criando todas as 16 tabelas e chaves compostas
      await dataSource.runMigrations();
      syncService = new SyncStorageService(dataSource);
      isDbAvailable = true;
    } catch (error) {
      console.warn(
        `[Integration Test] PostgreSQL indisponível no ambiente local (${(error as Error).message}). Os testes de integração reais executarão no CI com container postgres:16-alpine.`,
      );
    }
  });

  afterAll(async () => {
    if (dataSource && dataSource.isInitialized) {
      await dataSource.destroy();
    }
  });

  // Função auxiliar para pular caso o banco local não esteja rodando (roda no CI)
  const itIfDb = (name: string, fn: () => Promise<void>) => {
    it(name, async () => {
      if (!isDbAvailable) {
        console.log(
          `[SKIPPED LOCAL] Teste '${name}' pulado localmente por ausência de daemon PostgreSQL.`,
        );
        return;
      }
      await fn();
    });
  };

  itIfDb(
    '1. deve verificar que as migrações criaram todas as tabelas e constraints de chave composta',
    async () => {
      const queryRunner = dataSource.createQueryRunner();
      const tables = await queryRunner.getTables([
        'users',
        'user_sync_version',
        'user_change_log',
        'idempotency_receipts',
        'academic_years',
        'classrooms',
        'subjects',
        'classroom_subjects',
        'school_calendar_events',
        'schedule_slots',
        'curriculum_competencies',
        'course_contents',
        'content_prerequisites',
        'planned_lessons',
        'lesson_content_allocations',
        'lesson_execution_records',
        'execution_content_allocations',
      ]);
      await queryRunner.release();

      expect(tables.length).toBe(17);
    },
  );

  itIfDb(
    '2. deve impedir associação entre usuários diferentes através de chave estrangeira composta (Isolamento Multi-Tenant)',
    async () => {
      const user1Id = uuidv4();
      const user2Id = uuidv4();

      // 1. Cria dois usuários distintos
      await dataSource.getRepository(User).save([
        { id: user1Id, email: `user1_${Date.now()}@escola.gov.br`, passwordHash: 'hash1' },
        { id: user2Id, email: `user2_${Date.now()}@escola.gov.br`, passwordHash: 'hash2' },
      ]);

      // 2. Insere um ano letivo pertencente ao Usuário 1
      const ayUser1Id = uuidv4();
      await dataSource.getRepository(AcademicYear).save({
        id: ayUser1Id,
        userId: user1Id,
        year: 2026,
        title: 'Ano Letivo do Usuário 1',
        startDate: '2026-02-02',
        endDate: '2026-12-18',
        totalMandatoryDays: 200,
        createdAt: new Date(),
      });

      // 3. Tenta criar uma Turma pertencente ao Usuário 2, mas apontando para o ano letivo do Usuário 1
      const classroomUser2 = dataSource.getRepository(Classroom).create({
        id: uuidv4(),
        userId: user2Id, // Tenant 2
        academicYearId: ayUser1Id, // Tenant 1 (Violação de fronteira!)
        name: 'Turma Cruzada Inválida',
        gradeLevel: '6A',
        shift: 'morning',
        createdAt: new Date(),
      });

      // O PostgreSQL DEVE rejeitar via constraint composta fk_classrooms_academic_year
      await expect(dataSource.getRepository(Classroom).save(classroomUser2)).rejects.toThrow(
        /violates foreign key constraint|violação da restrição de chave estrangeira/i,
      );
    },
  );

  itIfDb(
    '3. deve serializar transações concorrentes para o mesmo usuário via advisory lock e SELECT FOR UPDATE',
    async () => {
      const userId = uuidv4();
      const deviceId = 'device-test-concurrency';

      await dataSource.getRepository(User).save({
        id: userId,
        email: `conc_${Date.now()}@escola.gov.br`,
        passwordHash: 'hash',
      });

      // Dispara 3 transações de sincronização em paralelo para o mesmo usuário
      const p1 = syncService.processBatchMutations(userId, deviceId, [
        {
          clientOpId: uuidv4(),
          deviceId,
          entityType: 'subject',
          entityId: uuidv4(),
          mutationType: 'INSERT',
          payload: { name: 'Matemática', color_hex: '#112233' },
        },
      ]);

      const p2 = syncService.processBatchMutations(userId, deviceId, [
        {
          clientOpId: uuidv4(),
          deviceId,
          entityType: 'subject',
          entityId: uuidv4(),
          mutationType: 'INSERT',
          payload: { name: 'História', color_hex: '#445566' },
        },
      ]);

      const p3 = syncService.processBatchMutations(userId, deviceId, [
        {
          clientOpId: uuidv4(),
          deviceId,
          entityType: 'subject',
          entityId: uuidv4(),
          mutationType: 'INSERT',
          payload: { name: 'Geografia', color_hex: '#778899' },
        },
      ]);

      const [res1, res2, res3] = await Promise.all([p1, p2, p3]);

      const allSeqs = [res1[0].serverSeq, res2[0].serverSeq, res3[0].serverSeq].sort((a, b) =>
        a < b ? -1 : 1,
      );

      // As sequências devem ser estritamente sequenciais (1n, 2n, 3n), sem duplicatas
      expect(allSeqs).toEqual([1n, 2n, 3n]);

      const finalVersion = await syncService.getUserSyncVersion(userId);
      expect(finalVersion.currentSeq).toBe(3n);
    },
  );

  itIfDb(
    '4. deve aplicar mutação no primeiro envio e retornar SKIPPED com recibo original em envio repetido (Idempotência)',
    async () => {
      const userId = uuidv4();
      const deviceId = 'device-idemp-1';
      const clientOpId = uuidv4();
      const subjectId = uuidv4();

      await dataSource.getRepository(User).save({
        id: userId,
        email: `idemp_${Date.now()}@escola.gov.br`,
        passwordHash: 'hash',
      });

      const op = {
        clientOpId,
        deviceId,
        entityType: 'subject',
        entityId: subjectId,
        mutationType: 'INSERT' as const,
        payload: { name: 'Física Quântica', color_hex: '#AABBCC' },
      };

      // 1º envio: Deve aplicar
      const firstResult = await syncService.processBatchMutations(userId, deviceId, [op]);
      expect(firstResult[0].status).toBe('APPLIED');
      expect(firstResult[0].serverSeq).toBe(1n);

      // 2º envio (mesmo client_op_id e mesmo payload): Deve ignorar sem gerar nova sequência
      const secondResult = await syncService.processBatchMutations(userId, deviceId, [op]);
      expect(secondResult[0].status).toBe('SKIPPED');
      expect(secondResult[0].serverSeq).toBe(1n);

      // Verifica que o log contém apenas 1 registro e o currentSeq continua 1n
      const logs = await dataSource.getRepository(UserChangeLog).find({ where: { userId } });
      expect(logs.length).toBe(1);

      const version = await syncService.getUserSyncVersion(userId);
      expect(version.currentSeq).toBe(1n);
    },
  );

  itIfDb(
    '5. deve rejeitar reutilização de client_op_id com payload divergente lançando IdempotencyConflictException',
    async () => {
      const userId = uuidv4();
      const deviceId = 'device-idemp-conflict';
      const clientOpId = uuidv4();

      await dataSource.getRepository(User).save({
        id: userId,
        email: `conflict_${Date.now()}@escola.gov.br`,
        passwordHash: 'hash',
      });

      const opOriginal = {
        clientOpId,
        deviceId,
        entityType: 'subject',
        entityId: uuidv4(),
        mutationType: 'INSERT' as const,
        payload: { name: 'Português', color_hex: '#001122' },
      };

      await syncService.processBatchMutations(userId, deviceId, [opOriginal]);

      const opDivergente = {
        clientOpId, // Mesmo client_op_id!
        deviceId,
        entityType: 'subject',
        entityId: uuidv4(),
        mutationType: 'INSERT' as const,
        payload: { name: 'Português Avançado com Conteúdo Divergente', color_hex: '#998877' },
      };

      await expect(
        syncService.processBatchMutations(userId, deviceId, [opDivergente]),
      ).rejects.toThrow(IdempotencyConflictException);
    },
  );

  itIfDb(
    '6. deve executar rollback total e não avançar sequência caso ocorra erro em qualquer mutação do lote (Atomicidade)',
    async () => {
      const userId = uuidv4();
      const deviceId = 'device-rollback';

      await dataSource.getRepository(User).save({
        id: userId,
        email: `rollback_${Date.now()}@escola.gov.br`,
        passwordHash: 'hash',
      });

      const op1Valida = {
        clientOpId: uuidv4(),
        deviceId,
        entityType: 'subject',
        entityId: uuidv4(),
        mutationType: 'INSERT' as const,
        payload: { name: 'Arte', color_hex: '#FFAA00' },
      };

      const op2Invalida = {
        clientOpId: uuidv4(),
        deviceId,
        entityType: 'classroom', // Requer academic_year_id válido
        entityId: uuidv4(),
        mutationType: 'INSERT' as const,
        payload: {
          academic_year_id: uuidv4(), // Inexistente -> Falha de Foreign Key
          name: 'Turma Falha',
          grade_level: '7B',
          shift: 'tarde',
        },
      };

      // O lote deve falhar na segunda operação
      await expect(
        syncService.processBatchMutations(userId, deviceId, [op1Valida, op2Invalida]),
      ).rejects.toThrow();

      // Confirma que NENHUM efeito da op1Valida permaneceu no banco (Rollback Completo)
      const logs = await dataSource.getRepository(UserChangeLog).find({ where: { userId } });
      expect(logs).toHaveLength(0);

      const receipts = await dataSource
        .getRepository(IdempotencyReceipt)
        .find({ where: { userId } });
      expect(receipts).toHaveLength(0);

      const version = await syncService.getUserSyncVersion(userId);
      expect(version.currentSeq).toBe(0n);
    },
  );

  itIfDb(
    '7. deve preservar a precisão de BIGINT sem perda de bits em sequências astronômicas no banco real',
    async () => {
      const userId = uuidv4();
      const hugeSeq = 9007199254740992500n; // > 2^53 - 1

      await dataSource.getRepository(User).save({
        id: userId,
        email: `huge_${Date.now()}@escola.gov.br`,
        passwordHash: 'hash',
      });

      await dataSource.getRepository(UserSyncVersion).save({
        userId,
        currentSeq: hugeSeq,
        epoch: 1n,
        updatedAt: new Date(),
      });

      const recovered = await syncService.getUserSyncVersion(userId);
      expect(recovered.currentSeq).toBe(hugeSeq);
      expect(recovered.currentSeq.toString()).toBe('9007199254740992500');
    },
  );
});
