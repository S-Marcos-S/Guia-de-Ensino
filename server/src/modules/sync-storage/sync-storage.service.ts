import { Injectable, Logger } from '@nestjs/common';
import { DataSource, EntityManager } from 'typeorm';
import * as crypto from 'crypto';
import { UserSyncVersion } from './entities/user-sync-version.entity';
import { UserChangeLog, MutationType } from './entities/user-change-log.entity';
import { IdempotencyReceipt, IdempotencyStatus } from './entities/idempotency-receipt.entity';
import { IdempotencyConflictException } from '../../common/exceptions/idempotency-conflict.exception';

export interface SyncOperationInput {
  clientOpId: string;
  deviceId: string;
  entityType: string;
  entityId: string;
  mutationType: MutationType;
  payload: Record<string, unknown> | null;
}

export interface SyncOperationResult {
  clientOpId: string;
  serverSeq: bigint;
  status: IdempotencyStatus;
  appliedAt: Date;
}

/**
 * Serviço central de persistência e orquestração transacional de sincronização.
 *
 * Garante:
 * 1. Serialização de concorrência por usuário via advisory lock + SELECT FOR UPDATE.
 * 2. Inicialização concorrencial segura de user_sync_version.
 * 3. Preservação estrita de precisão BIGINT nativa (sem conversões para Number).
 * 4. Idempotência antecipada com rejeição estrita de payloads divergentes para o mesmo client_op_id.
 * 5. Rollback atômico em bloco de dados, log, recibos e sequência.
 *
 * Semântica de Sequência:
 * - A sequência (server_seq) é estritamente monotônica e sequencial por usuário (user_id).
 * - Cada operação efetivamente aplicada incrementa server_seq em exatamente 1n.
 * - Operações duplicadas reconhecidas por idempotência preservam seu server_seq original e
 *   não avançam a sequência do usuário.
 * - Em caso de rollback da transação, o estado da sequência retorna intacto ao valor inicial,
 *   garantindo ausência de gaps ou vazamentos de sequências fantasmas não confirmadas.
 */
@Injectable()
export class SyncStorageService {
  private readonly logger = new Logger(SyncStorageService.name);

  constructor(private readonly dataSource: DataSource) {}

  /**
   * Executa uma operação transacional isolada com lock exclusivo por usuário.
   */
  async executeUserTransaction<T>(
    userId: string,
    operation: (
      manager: EntityManager,
      currentSeq: bigint,
    ) => Promise<{ result: T; newSeq: bigint }>,
  ): Promise<T> {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction('READ COMMITTED');

    try {
      // 1. Advisory lock exclusivo por usuário a nível de transação no PostgreSQL
      // Garante serialização estrita mesmo antes de tocar na tabela de sincronização
      await queryRunner.query('SELECT pg_advisory_xact_lock(hashtext($1))', [
        `user_sync_lock:${userId}`,
      ]);

      // 2. Inicialização segura e concorrencial de user_sync_version (ON CONFLICT DO NOTHING)
      await queryRunner.query(
        `INSERT INTO user_sync_version (user_id, current_seq, epoch, updated_at)
         VALUES ($1, 0, 1, NOW())
         ON CONFLICT (user_id) DO NOTHING;`,
        [userId],
      );

      // 3. Bloqueio pessimista de linha com SELECT FOR UPDATE
      const syncVersion = await queryRunner.manager
        .createQueryBuilder(UserSyncVersion, 'usv')
        .setLock('pessimistic_write')
        .where('usv.user_id = :userId', { userId })
        .getOneOrFail();

      const currentSeq = syncVersion.currentSeq;

      // 4. Executa a lógica de negócio dentro da transação protegida
      const { result, newSeq } = await operation(queryRunner.manager, currentSeq);

      // 5. Atualiza a sequência caso tenha havido mutações aplicadas
      if (newSeq > currentSeq) {
        await queryRunner.manager.update(
          UserSyncVersion,
          { userId },
          {
            currentSeq: newSeq,
            updatedAt: new Date(),
          },
        );
      }

      // 6. Confirmação atômica em bloco
      await queryRunner.commitTransaction();
      return result;
    } catch (error) {
      // 7. Rollback total de todas as operações, logs, recibos e sequência
      await queryRunner.rollbackTransaction();
      this.logger.error(
        `[SyncStorage] Transação do usuário ${userId} abortada: ${(error as Error).message}`,
      );
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  /**
   * Processa um lote de mutações com verificação antecipada de idempotência,
   * atribuição centralizada de sequências e gravação no log de auditoria.
   */
  async processBatchMutations(
    userId: string,
    deviceId: string,
    operations: SyncOperationInput[],
  ): Promise<SyncOperationResult[]> {
    return this.executeUserTransaction(userId, async (manager, startSeq) => {
      let currentSeq = startSeq;
      const results: SyncOperationResult[] = [];

      for (const op of operations) {
        const payloadHash = this.computePayloadHash(op.payload);

        // 1. Verificação de Idempotência ANTES de qualquer efeito colateral
        const existingReceipt = await manager.findOne(IdempotencyReceipt, {
          where: {
            userId,
            deviceId: op.deviceId,
            clientOpId: op.clientOpId,
          },
        });

        if (existingReceipt) {
          // Rejeita reutilização de client_op_id com conteúdo diferente
          if (existingReceipt.payloadHash !== payloadHash) {
            throw new IdempotencyConflictException(op.clientOpId);
          }

          // Retorna o recibo original com status SKIPPED sem gerar nova sequência
          results.push({
            clientOpId: op.clientOpId,
            serverSeq: existingReceipt.serverSeq,
            status: 'SKIPPED',
            appliedAt: existingReceipt.appliedAt,
          });
          continue;
        }

        // 2. Reserva a próxima sequência centralizada com precisão BIGINT (seq + 1n)
        currentSeq = currentSeq + 1n;

        // 3. Aplica a mutação relacional na tabela de negócio correspondente
        await this.applyEntityMutation(manager, userId, op);

        // 4. Grava o evento imutável no log de alterações (user_change_log)
        const logEntry = manager.create(UserChangeLog, {
          userId,
          serverSeq: currentSeq,
          entityType: op.entityType,
          entityId: op.entityId,
          mutationType: op.mutationType,
          payload: op.payload,
          deviceId: op.deviceId,
          createdAt: new Date(),
        });
        await manager.save(UserChangeLog, logEntry);

        // 5. Grava o recibo de idempotência
        const appliedAt = new Date();
        const receipt = manager.create(IdempotencyReceipt, {
          userId,
          deviceId: op.deviceId,
          clientOpId: op.clientOpId,
          serverSeq: currentSeq,
          status: 'APPLIED',
          payloadHash,
          appliedAt,
        });
        await manager.save(IdempotencyReceipt, receipt);

        results.push({
          clientOpId: op.clientOpId,
          serverSeq: currentSeq,
          status: 'APPLIED',
          appliedAt,
        });
      }

      return { result: results, newSeq: currentSeq };
    });
  }

  /**
   * Consulta a versão e sequência atual do usuário.
   */
  async getUserSyncVersion(userId: string): Promise<{ currentSeq: bigint; epoch: bigint }> {
    const version = await this.dataSource.getRepository(UserSyncVersion).findOne({
      where: { userId },
    });

    if (!version) {
      return { currentSeq: 0n, epoch: 1n };
    }

    return {
      currentSeq: version.currentSeq,
      epoch: version.epoch,
    };
  }

  /**
   * Calcula o hash SHA-256 canônico do payload para validação de idempotência.
   */
  computePayloadHash(payload: Record<string, unknown> | null): string {
    if (!payload) {
      return crypto.createHash('sha256').update('').digest('hex');
    }
    // Ordena as chaves do objeto para gerar um hash estável e determinístico
    const canonicalJson = JSON.stringify(payload, Object.keys(payload).sort());
    return crypto.createHash('sha256').update(canonicalJson).digest('hex');
  }

  /**
   * Aplica a mutação direta na tabela de negócio, respeitando o isolamento por user_id.
   */
  private async applyEntityMutation(
    manager: EntityManager,
    userId: string,
    op: SyncOperationInput,
  ): Promise<void> {
    const tableName = this.resolveTableName(op.entityType);

    if (op.mutationType === 'DELETE') {
      await manager.query(`DELETE FROM ${tableName} WHERE id = $1 AND user_id = $2;`, [
        op.entityId,
        userId,
      ]);
      return;
    }

    if (!op.payload) {
      return;
    }

    // Garante que o user_id do registro seja obrigatoriamente o usuário autenticado
    const recordData = {
      ...op.payload,
      id: op.entityId,
      user_id: userId,
    };

    const keys = Object.keys(recordData);
    const values = Object.values(recordData);
    const placeholders = keys.map((_, i) => `$${i + 1}`).join(', ');
    const updateSet = keys
      .filter((k) => k !== 'id' && k !== 'user_id' && k !== 'created_at')
      .map((k) => `${k} = EXCLUDED.${k}`)
      .join(', ');

    const sql = `
      INSERT INTO ${tableName} (${keys.join(', ')})
      VALUES (${placeholders})
      ON CONFLICT (id, user_id) DO UPDATE
      SET ${updateSet.length > 0 ? updateSet : 'updated_at = NOW()'};
    `;

    await manager.query(sql, values);
  }

  private resolveTableName(entityType: string): string {
    const mapping: Record<string, string> = {
      academic_year: 'academic_years',
      classroom: 'classrooms',
      subject: 'subjects',
      classroom_subject: 'classroom_subjects',
      school_calendar_event: 'school_calendar_events',
      schedule_slot: 'schedule_slots',
      curriculum_competency: 'curriculum_competencies',
      course_content: 'course_contents',
      content_prerequisite: 'content_prerequisites',
      planned_lesson: 'planned_lessons',
      lesson_content_allocation: 'lesson_content_allocations',
      lesson_execution_record: 'lesson_execution_records',
      execution_content_allocation: 'execution_content_allocations',
    };

    const table = mapping[entityType];
    if (!table) {
      throw new Error(`Tipo de entidade desconhecido para sincronização: '${entityType}'`);
    }
    return table;
  }
}
