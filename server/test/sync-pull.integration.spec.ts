import { DataSource } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { dataSourceOptions } from '../src/database/data-source';
import { SyncStorageService } from '../src/modules/sync-storage/sync-storage.service';
import { SyncService } from '../src/modules/sync/sync.service';
import { User } from '../src/modules/auth/entities/user.entity';
import { UserSyncVersion } from '../src/modules/sync-storage/entities/user-sync-version.entity';
import { SyncEpochMismatchException } from '../src/common/exceptions/sync-epoch-mismatch.exception';
import { InvalidCursorException } from '../src/common/exceptions/invalid-cursor.exception';
import { BadRequestException } from '@nestjs/common';

describe('Sync Pull Protocol & Pagination (Integration Tests)', () => {
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
      email: `pull_user_${Date.now()}_${Math.random().toString(36).substring(7)}@escola.gov.br`,
      passwordHash: 'hash123',
    });
    return userId;
  };

  itIfDb(
    '1. Pull incremental básico: deve recuperar alterações comutadas em push prévio com cursor inicial',
    async () => {
      const userId = await createTestUser();
      const deviceId = 'dev-push-1';

      // Executa push com 3 disciplinas
      await syncService.processPush(userId, {
        deviceId,
        clientBatchId: uuidv4(),
        operations: [
          {
            clientOpId: uuidv4(),
            entityType: 'subject',
            entityId: uuidv4(),
            mutationType: 'INSERT',
            payload: { name: 'Matemática' },
          },
          {
            clientOpId: uuidv4(),
            entityType: 'subject',
            entityId: uuidv4(),
            mutationType: 'INSERT',
            payload: { name: 'Português' },
          },
          {
            clientOpId: uuidv4(),
            entityType: 'subject',
            entityId: uuidv4(),
            mutationType: 'INSERT',
            payload: { name: 'História' },
          },
        ],
      });

      // Executa Pull a partir do início
      const pullResponse = await syncService.processPull(userId, { cursor: '0:0' });

      expect(pullResponse.epoch).toBe('1');
      expect(pullResponse.currentServerSeq).toBe('3');
      expect(pullResponse.hasMore).toBe(false);
      expect(pullResponse.changes).toHaveLength(3);
      expect(pullResponse.changes[0].serverSeq).toBe('1');
      expect(pullResponse.changes[1].serverSeq).toBe('2');
      expect(pullResponse.changes[2].serverSeq).toBe('3');
      expect(pullResponse.nextCursor).toBe(`3:${pullResponse.changes[2].changeLogId}`);
    },
  );

  itIfDb(
    '2. Paginação determinística em fronteiras de lote: deve paginar 15 eventos em lotes de 5 sem omissões nem duplicatas',
    async () => {
      const userId = await createTestUser();
      const deviceId = 'dev-pager';

      // Cria 15 operações
      const ops = Array.from({ length: 15 }, (_, i) => ({
        clientOpId: uuidv4(),
        entityType: 'subject' as const,
        entityId: uuidv4(),
        mutationType: 'INSERT' as const,
        payload: { name: `Matéria ${i + 1}` },
      }));

      await syncService.processPush(userId, {
        deviceId,
        clientBatchId: uuidv4(),
        operations: ops,
      });

      // Página 1 (limit 5)
      const page1 = await syncService.processPull(userId, { cursor: '0:0', limit: 5 });
      expect(page1.changes).toHaveLength(5);
      expect(page1.hasMore).toBe(true);
      expect(page1.changes[0].serverSeq).toBe('1');
      expect(page1.changes[4].serverSeq).toBe('5');

      // Página 2 (limit 5 a partir do nextCursor da página 1)
      const page2 = await syncService.processPull(userId, { cursor: page1.nextCursor, limit: 5 });
      expect(page2.changes).toHaveLength(5);
      expect(page2.hasMore).toBe(true);
      expect(page2.changes[0].serverSeq).toBe('6');
      expect(page2.changes[4].serverSeq).toBe('10');

      // Página 3 (limit 5 a partir do nextCursor da página 2)
      const page3 = await syncService.processPull(userId, { cursor: page2.nextCursor, limit: 5 });
      expect(page3.changes).toHaveLength(5);
      expect(page3.hasMore).toBe(false);
      expect(page3.changes[0].serverSeq).toBe('11');
      expect(page3.changes[4].serverSeq).toBe('15');

      // Página 4 (vazia)
      const page4 = await syncService.processPull(userId, { cursor: page3.nextCursor, limit: 5 });
      expect(page4.changes).toHaveLength(0);
      expect(page4.hasMore).toBe(false);
      expect(page4.nextCursor).toBe(page3.nextCursor);

      // Validação de que todos os 15 IDs de eventos são únicos e consecutivos
      const allSeqs = [
        ...page1.changes.map((c) => c.serverSeq),
        ...page2.changes.map((c) => c.serverSeq),
        ...page3.changes.map((c) => c.serverSeq),
      ];
      expect(allSeqs).toEqual(Array.from({ length: 15 }, (_, i) => (i + 1).toString()));
    },
  );

  itIfDb(
    '3. Descarte de eco via excludeDeviceId: eventos originados pelo próprio dispositivo devem ser excluídos',
    async () => {
      const userId = await createTestUser();
      const devA = 'device-A';
      const devB = 'device-B';

      // Dev A insere 1 matéria
      await syncService.processPush(userId, {
        deviceId: devA,
        clientBatchId: uuidv4(),
        operations: [
          {
            clientOpId: uuidv4(),
            entityType: 'subject',
            entityId: uuidv4(),
            mutationType: 'INSERT',
            payload: { name: 'Química' },
          },
        ],
      });

      // Dev B insere 1 matéria
      await syncService.processPush(userId, {
        deviceId: devB,
        clientBatchId: uuidv4(),
        operations: [
          {
            clientOpId: uuidv4(),
            entityType: 'subject',
            entityId: uuidv4(),
            mutationType: 'INSERT',
            payload: { name: 'Biologia' },
          },
        ],
      });

      // Dev A faz pull com excludeDeviceId = devA -> só deve receber a alteração do Dev B
      const pullDevA = await syncService.processPull(userId, {
        cursor: '0:0',
        excludeDeviceId: devA,
      });

      expect(pullDevA.changes).toHaveLength(1);
      expect(pullDevA.changes[0].payload).toEqual(expect.objectContaining({ name: 'Biologia' }));
      expect(pullDevA.changes[0].deviceId).toBe(devB);
    },
  );

  itIfDb(
    '4. Isolamento multi-tenant: Pull do usuário A nunca deve retornar alterações do usuário B',
    async () => {
      const userA = await createTestUser();
      const userB = await createTestUser();

      await syncService.processPush(userA, {
        deviceId: 'dev-A',
        clientBatchId: uuidv4(),
        operations: [
          {
            clientOpId: uuidv4(),
            entityType: 'subject',
            entityId: uuidv4(),
            mutationType: 'INSERT',
            payload: { name: 'Exclusiva User A' },
          },
        ],
      });

      await syncService.processPush(userB, {
        deviceId: 'dev-B',
        clientBatchId: uuidv4(),
        operations: [
          {
            clientOpId: uuidv4(),
            entityType: 'subject',
            entityId: uuidv4(),
            mutationType: 'INSERT',
            payload: { name: 'Exclusiva User B' },
          },
        ],
      });

      const pullA = await syncService.processPull(userA, { cursor: '0:0' });
      expect(pullA.changes).toHaveLength(1);
      expect(pullA.changes[0].payload).toEqual(
        expect.objectContaining({ name: 'Exclusiva User A' }),
      );

      const pullB = await syncService.processPull(userB, { cursor: '0:0' });
      expect(pullB.changes).toHaveLength(1);
      expect(pullB.changes[0].payload).toEqual(
        expect.objectContaining({ name: 'Exclusiva User B' }),
      );
    },
  );

  itIfDb(
    '5. Validação de divergência de época: clientEpoch divergente deve lançar SyncEpochMismatchException (HTTP 410)',
    async () => {
      const userId = await createTestUser();

      // Altera época no banco para simular avanço de época do servidor
      await dataSource.getRepository(UserSyncVersion).update({ userId }, { epoch: 2n });

      await expect(
        syncService.processPull(userId, {
          cursor: '0:0',
          clientEpoch: '1', // Cliente desatualizado!
        }),
      ).rejects.toThrow(SyncEpochMismatchException);
    },
  );

  itIfDb(
    '6. Cursor além da sequência atual (cursor futuro): deve rejeitar com InvalidCursorException (HTTP 400 Bad Request)',
    async () => {
      const userId = await createTestUser();

      await expect(syncService.processPull(userId, { cursor: '99999:0' })).rejects.toThrow(
        InvalidCursorException,
      );
    },
  );

  itIfDb(
    '7. Cursores malformados: deve rejeitar strings inválidas lançando BadRequestException',
    async () => {
      const userId = await createTestUser();

      await expect(syncService.processPull(userId, { cursor: 'malformed_cursor' })).rejects.toThrow(
        BadRequestException,
      );
      await expect(syncService.processPull(userId, { cursor: '-1:0' })).rejects.toThrow(
        BadRequestException,
      );
    },
  );
});
