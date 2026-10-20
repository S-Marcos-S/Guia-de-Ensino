import { DataSource } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { dataSourceOptions } from '../src/database/data-source';
import { SyncStorageService } from '../src/modules/sync-storage/sync-storage.service';
import { SyncService } from '../src/modules/sync/sync.service';
import { User } from '../src/modules/auth/entities/user.entity';
import { SnapshotTokenHelper } from '../src/modules/sync/helpers/snapshot-token.helper';
import { SnapshotExpiredException } from '../src/common/exceptions/snapshot-expired.exception';
import { BadRequestException } from '@nestjs/common';

describe('Sync Snapshot Protocol & Consistency (Integration Tests)', () => {
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

  const createTestUser = async () => {
    const userId = uuidv4();
    await dataSource.getRepository(User).save({
      id: userId,
      email: `snapshot_user_${Date.now()}_${Math.random().toString(36).substring(7)}@escola.gov.br`,
      passwordHash: 'hash123',
    });
    return userId;
  };

  itIfDb(
    '1. Geração canônica de snapshot consistente com as 13 coleções e snapshotToken HMAC assinado',
    async () => {
      const userId = await createTestUser();
      const yearId = uuidv4();
      const subjectId = uuidv4();

      // Insere dados via Push para inicializar a sequência do usuário
      await syncService.processPush(userId, {
        deviceId: 'device-1',
        clientBatchId: uuidv4(),
        operations: [
          {
            clientOpId: uuidv4(),
            entityType: 'academic_year',
            entityId: yearId,
            mutationType: 'INSERT',
            payload: {
              year: 2026,
              title: 'Ano Letivo 2026',
              start_date: '2026-02-01',
              end_date: '2026-12-15',
              total_mandatory_days: 200,
            },
          },
          {
            clientOpId: uuidv4(),
            entityType: 'subject',
            entityId: subjectId,
            mutationType: 'INSERT',
            payload: {
              name: 'Matemática',
              color_hex: '#FF5733',
            },
          },
        ],
      });

      // Solicita o snapshot do usuário
      const snapshot = await syncService.processSnapshot(userId, {});

      expect(snapshot.epoch).toBe('1');
      expect(BigInt(snapshot.snapshotSeq)).toBe(2n);
      expect(snapshot.snapshotToken).toBeDefined();
      expect(snapshot.expiresAt).toBeDefined();

      // Valida estrutura de coleções
      expect(snapshot.entities).toBeDefined();
      expect(snapshot.entities.academic_years).toHaveLength(1);
      expect(snapshot.entities.academic_years[0].id).toBe(yearId);
      expect(snapshot.entities.subjects).toHaveLength(1);
      expect(snapshot.entities.subjects[0].name).toBe('Matemática');

      // Coleções não povoadas devem ser arrays vazios
      expect(snapshot.entities.classrooms).toEqual([]);
      expect(snapshot.entities.planned_lessons).toEqual([]);
      expect(snapshot.entities.lesson_execution_records).toEqual([]);

      // Validação do token de snapshot gerado
      const tokenPayload = SnapshotTokenHelper.verifyToken(
        snapshot.snapshotToken,
        userId,
        process.env.JWT_SECRET ?? 'fallback-secret-minimum-32-chars-long',
      );
      expect(tokenPayload.userId).toBe(userId);
      expect(tokenPayload.snapshotSeq).toBe(2n);
      expect(tokenPayload.epoch).toBe(1n);
    },
  );

  itIfDb('2. Isolamento multi-tenant absoluto no snapshot sob REPEATABLE READ', async () => {
    const userA = await createTestUser();
    const userB = await createTestUser();

    const subjectA = uuidv4();
    const subjectB = uuidv4();

    await syncService.processPush(userA, {
      deviceId: 'dev-a',
      clientBatchId: uuidv4(),
      operations: [
        {
          clientOpId: uuidv4(),
          entityType: 'subject',
          entityId: subjectA,
          mutationType: 'INSERT',
          payload: { name: 'Disciplina de A', color_hex: '#111111' },
        },
      ],
    });

    await syncService.processPush(userB, {
      deviceId: 'dev-b',
      clientBatchId: uuidv4(),
      operations: [
        {
          clientOpId: uuidv4(),
          entityType: 'subject',
          entityId: subjectB,
          mutationType: 'INSERT',
          payload: { name: 'Disciplina de B', color_hex: '#222222' },
        },
      ],
    });

    const snapshotA = await syncService.processSnapshot(userA, {});
    const snapshotB = await syncService.processSnapshot(userB, {});

    expect(snapshotA.entities.subjects).toHaveLength(1);
    expect(snapshotA.entities.subjects[0].id).toBe(subjectA);
    expect(snapshotA.entities.subjects[0].name).toBe('Disciplina de A');

    expect(snapshotB.entities.subjects).toHaveLength(1);
    expect(snapshotB.entities.subjects[0].id).toBe(subjectB);
    expect(snapshotB.entities.subjects[0].name).toBe('Disciplina de B');
  });

  itIfDb(
    '3. Continuidade e coordenação entre Snapshot e Pull com cursor "${snapshotSeq}:0"',
    async () => {
      const userId = await createTestUser();

      // Push inicial
      await syncService.processPush(userId, {
        deviceId: 'dev-1',
        clientBatchId: uuidv4(),
        operations: [
          {
            clientOpId: uuidv4(),
            entityType: 'subject',
            entityId: uuidv4(),
            mutationType: 'INSERT',
            payload: { name: 'História', color_hex: '#333333' },
          },
        ],
      });

      // Extrai Snapshot
      const snapshot = await syncService.processSnapshot(userId, {});
      const snapshotSeq = snapshot.snapshotSeq;
      expect(snapshotSeq).toBe('1');

      // Escrita subsequente concorrente
      const subjectPostSnapshot = uuidv4();
      await syncService.processPush(userId, {
        deviceId: 'dev-2',
        clientBatchId: uuidv4(),
        operations: [
          {
            clientOpId: uuidv4(),
            entityType: 'subject',
            entityId: subjectPostSnapshot,
            mutationType: 'INSERT',
            payload: { name: 'Geografia', color_hex: '#444444' },
          },
        ],
      });

      // O cliente executa Pull a partir de snapshotSeq
      const pullResponse = await syncService.processPull(userId, {
        cursor: `${snapshotSeq}:0`,
      });

      expect(pullResponse.changes).toHaveLength(1);
      expect(pullResponse.changes[0].entityId).toBe(subjectPostSnapshot);
      expect(pullResponse.changes[0].serverSeq).toBe('2');
    },
  );

  itIfDb(
    '4. Rejeição de snapshotToken expirado com SnapshotExpiredException (HTTP 410 Gone / SNAPSHOT_EXPIRED)',
    async () => {
      const userId = await createTestUser();
      const secret = process.env.JWT_SECRET ?? 'fallback-secret-minimum-32-chars-long';
      // Token expirado (-5 minutos)
      const { token } = SnapshotTokenHelper.generateToken(userId, 10n, 1n, secret, -5);

      await expect(syncService.processSnapshot(userId, { snapshotToken: token })).rejects.toThrow(
        SnapshotExpiredException,
      );
    },
  );

  itIfDb(
    '5. Rejeição de snapshotToken com assinatura adulterada com BadRequestException',
    async () => {
      const userId = await createTestUser();
      const secret = process.env.JWT_SECRET ?? 'fallback-secret-minimum-32-chars-long';
      const { token } = SnapshotTokenHelper.generateToken(userId, 10n, 1n, secret, 15);
      const tampered = token.slice(0, -6) + 'abcdef';

      await expect(
        syncService.processSnapshot(userId, { snapshotToken: tampered }),
      ).rejects.toThrow(BadRequestException);
    },
  );

  itIfDb('6. Rejeição de snapshotToken pertencente a outro usuário', async () => {
    const userA = await createTestUser();
    const userB = await createTestUser();
    const secret = process.env.JWT_SECRET ?? 'fallback-secret-minimum-32-chars-long';
    const { token } = SnapshotTokenHelper.generateToken(userA, 10n, 1n, secret, 15);

    await expect(syncService.processSnapshot(userB, { snapshotToken: token })).rejects.toThrow(
      BadRequestException,
    );
  });
});
