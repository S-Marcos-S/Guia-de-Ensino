import { Injectable, Logger } from '@nestjs/common';
import { DataSource, EntityManager } from 'typeorm';
import * as crypto from 'crypto';
import { UserSyncVersion } from './entities/user-sync-version.entity';
import { UserChangeLog, MutationType } from './entities/user-change-log.entity';
import { IdempotencyReceipt, IdempotencyStatus } from './entities/idempotency-receipt.entity';
import { IdempotencyConflictException } from '../../common/exceptions/idempotency-conflict.exception';
import { FactualIntegrityException } from '../../common/exceptions/factual-integrity.exception';

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

export interface ChangeLogRecord {
  id: bigint;
  serverSeq: bigint;
  entityType: string;
  entityId: string;
  mutationType: string;
  payload: Record<string, unknown> | null;
  deviceId: string;
  createdAt: Date;
}

export interface PullStorageResult {
  currentSeq: bigint;
  epoch: bigint;
  changes: ChangeLogRecord[];
  nextCursor: string;
  hasMore: boolean;
}

export interface SnapshotEntities {
  academic_years: Record<string, unknown>[];
  classrooms: Record<string, unknown>[];
  subjects: Record<string, unknown>[];
  classroom_subjects: Record<string, unknown>[];
  school_calendar_events: Record<string, unknown>[];
  schedule_slots: Record<string, unknown>[];
  curriculum_competencies: Record<string, unknown>[];
  course_contents: Record<string, unknown>[];
  content_prerequisites: Record<string, unknown>[];
  planned_lessons: Record<string, unknown>[];
  lesson_content_allocations: Record<string, unknown>[];
  lesson_execution_records: Record<string, unknown>[];
  execution_content_allocations: Record<string, unknown>[];
}

export interface SnapshotStorageResult {
  snapshotSeq: bigint;
  epoch: bigint;
  entities: SnapshotEntities;
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

        // 2. Validação rigorosa de integridade factual de domínio antes de qualquer efeito
        await this.validateFactualIntegrity(manager, userId, op);

        // 3. Reserva a próxima sequência centralizada com precisão BIGINT (seq + 1n)
        currentSeq = currentSeq + 1n;

        // 4. Aplica a mutação relacional na tabela de negócio correspondente
        await this.applyEntityMutation(manager, userId, op);

        // 5. Grava o evento imutável no log de alterações (user_change_log)
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

        // 6. Grava o recibo de idempotência
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
   * Consulta paginada consistente de alterações a partir de um cursor composto (server_seq, id).
   * Executa em transação de leitura isolada para assegurar que currentSeq e o lote de alterações
   * reflitam o mesmo instante temporal comutado no PostgreSQL.
   */
  async getChangesSinceCursor(
    userId: string,
    cursorSeq: bigint,
    cursorId: bigint,
    limit: number,
    excludeDeviceId?: string,
  ): Promise<PullStorageResult> {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction('READ COMMITTED');

    try {
      // 1. Consulta versão e sequência atual do usuário no mesmo snapshot
      const versionRows = await queryRunner.manager.query(
        `SELECT current_seq, epoch FROM user_sync_version WHERE user_id = $1;`,
        [userId],
      );

      const currentSeq =
        versionRows && versionRows.length > 0 ? BigInt(versionRows[0].current_seq) : 0n;
      const epoch = versionRows && versionRows.length > 0 ? BigInt(versionRows[0].epoch) : 1n;

      // 2. Consulta paginada indexada por idx_user_change_log_cursor (user_id, server_seq ASC, id ASC)
      // Utiliza construtor de tupla nativo do PostgreSQL: (server_seq, id) > ($cursorSeq, $cursorId)
      const queryParams: (string | number)[] = [
        userId,
        cursorSeq.toString(),
        cursorId.toString(),
        limit + 1,
      ];

      let deviceFilter = '';
      if (excludeDeviceId) {
        queryParams.push(excludeDeviceId);
        deviceFilter = `AND device_id != $5`;
      }

      const sql = `
        SELECT id, server_seq, entity_type, entity_id, mutation_type, payload, device_id, created_at
        FROM user_change_log
        WHERE user_id = $1
          AND (server_seq, id) > ($2, $3)
          ${deviceFilter}
        ORDER BY server_seq ASC, id ASC
        LIMIT $4;
      `;

      const rawRows: Array<{
        id: string;
        server_seq: string;
        entity_type: string;
        entity_id: string;
        mutation_type: string;
        payload: Record<string, unknown> | null;
        device_id: string;
        created_at: Date;
      }> = await queryRunner.manager.query(sql, queryParams);

      await queryRunner.commitTransaction();

      const hasMore = rawRows.length > limit;
      const pageRows = hasMore ? rawRows.slice(0, limit) : rawRows;

      const changes: ChangeLogRecord[] = pageRows.map((r) => ({
        id: BigInt(r.id),
        serverSeq: BigInt(r.server_seq),
        entityType: r.entity_type,
        entityId: r.entity_id,
        mutationType: r.mutation_type,
        payload: r.payload,
        deviceId: r.device_id,
        createdAt: new Date(r.created_at),
      }));

      const nextCursor =
        changes.length > 0
          ? `${changes[changes.length - 1].serverSeq}:${changes[changes.length - 1].id}`
          : `${cursorSeq}:${cursorId}`;

      return {
        currentSeq,
        epoch,
        changes,
        nextCursor,
        hasMore,
      };
    } catch (error) {
      await queryRunner.rollbackTransaction();
      this.logger.error(
        `[SyncStorage] Falha ao consultar alterações para usuário ${userId}: ${(error as Error).message}`,
      );
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  /**
   * Extrai o snapshot consistente de todas as 13 entidades pedagógicas do usuário.
   * Executa sob transação de leitura com nível de isolamento REPEATABLE READ.
   *
   * Invariante de consistência:
   * - No PostgreSQL, o snapshot temporal de visibilidade é fixado no momento do primeiro SELECT.
   * - O snapshotSeq é lido de user_sync_version.
   * - Qualquer mutação concorrente subsequente receberá server_seq > snapshotSeq e NÃO
   *   aparecerá neste snapshot. O cliente recuperará tais mutações via Pull com cursor `${snapshotSeq}:0`.
   * - Todas as 13 consultas filtram estritamente por WHERE user_id = $1, garantindo isolamento multi-tenant absoluto.
   */
  async getUserSnapshot(userId: string): Promise<SnapshotStorageResult> {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction('REPEATABLE READ');

    try {
      // 1. Snapshot da sequência atual e época do usuário
      const versionRows = await queryRunner.manager.query(
        `SELECT current_seq, epoch FROM user_sync_version WHERE user_id = $1;`,
        [userId],
      );

      const snapshotSeq =
        versionRows && versionRows.length > 0 ? BigInt(versionRows[0].current_seq) : 0n;
      const epoch = versionRows && versionRows.length > 0 ? BigInt(versionRows[0].epoch) : 1n;

      // 2. Extração das 13 tabelas sob a mesma transação REPEATABLE READ isolada por user_id
      const academic_years = await queryRunner.manager.query(
        `SELECT * FROM academic_years WHERE user_id = $1 ORDER BY year ASC;`,
        [userId],
      );
      const classrooms = await queryRunner.manager.query(
        `SELECT * FROM classrooms WHERE user_id = $1 ORDER BY name ASC;`,
        [userId],
      );
      const subjects = await queryRunner.manager.query(
        `SELECT * FROM subjects WHERE user_id = $1 ORDER BY name ASC;`,
        [userId],
      );
      const classroom_subjects = await queryRunner.manager.query(
        `SELECT * FROM classroom_subjects WHERE user_id = $1;`,
        [userId],
      );
      const school_calendar_events = await queryRunner.manager.query(
        `SELECT * FROM school_calendar_events WHERE user_id = $1 ORDER BY start_date ASC;`,
        [userId],
      );
      const schedule_slots = await queryRunner.manager.query(
        `SELECT * FROM schedule_slots WHERE user_id = $1 ORDER BY weekday ASC, order_index ASC;`,
        [userId],
      );
      const curriculum_competencies = await queryRunner.manager.query(
        `SELECT * FROM curriculum_competencies WHERE user_id = $1 ORDER BY code ASC;`,
        [userId],
      );
      const course_contents = await queryRunner.manager.query(
        `SELECT * FROM course_contents WHERE user_id = $1 ORDER BY order_index ASC;`,
        [userId],
      );
      const content_prerequisites = await queryRunner.manager.query(
        `SELECT * FROM content_prerequisites WHERE user_id = $1;`,
        [userId],
      );
      const planned_lessons = await queryRunner.manager.query(
        `SELECT * FROM planned_lessons WHERE user_id = $1 ORDER BY lesson_date ASC, order_in_day ASC;`,
        [userId],
      );
      const lesson_content_allocations = await queryRunner.manager.query(
        `SELECT * FROM lesson_content_allocations WHERE user_id = $1 ORDER BY order_index ASC;`,
        [userId],
      );
      const lesson_execution_records = await queryRunner.manager.query(
        `SELECT * FROM lesson_execution_records WHERE user_id = $1 ORDER BY execution_date ASC;`,
        [userId],
      );
      const execution_content_allocations = await queryRunner.manager.query(
        `SELECT * FROM execution_content_allocations WHERE user_id = $1 ORDER BY order_index ASC;`,
        [userId],
      );

      await queryRunner.commitTransaction();

      return {
        snapshotSeq,
        epoch,
        entities: {
          academic_years,
          classrooms,
          subjects,
          classroom_subjects,
          school_calendar_events,
          schedule_slots,
          curriculum_competencies,
          course_contents,
          content_prerequisites,
          planned_lessons,
          lesson_content_allocations,
          lesson_execution_records,
          execution_content_allocations,
        },
      };
    } catch (error) {
      await queryRunner.rollbackTransaction();
      this.logger.error(
        `[SyncStorage] Falha ao extrair snapshot para usuário ${userId}: ${(error as Error).message}`,
      );
      throw error;
    } finally {
      await queryRunner.release();
    }
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
   * Validações ativas de integridade factual de domínio (proteção sagrada de diários e fatos históricos).
   */
  private async validateFactualIntegrity(
    manager: EntityManager,
    userId: string,
    op: SyncOperationInput,
  ): Promise<void> {
    // 1. Proibição categórica de exclusão de LessonExecutionRecord via sincronização
    if (op.entityType === 'lesson_execution_record' && op.mutationType === 'DELETE') {
      throw new FactualIntegrityException(
        `Registros históricos de realização de aula (lesson_execution_records) não podem ser excluídos via protocolo de sincronização.`,
      );
    }

    // 2. Proibição de exclusão direta de conteúdos ministrados (ExecutionContentAllocation)
    if (op.entityType === 'execution_content_allocation' && op.mutationType === 'DELETE') {
      throw new FactualIntegrityException(
        `Conteúdos efetivamente ministrados em aula não podem ser excluídos diretamente via sincronização sem retificação docente formal.`,
      );
    }

    // 3. Não permitir exclusão de aula planejada que possua registro histórico de execução vinculado
    if (op.entityType === 'planned_lesson' && op.mutationType === 'DELETE') {
      const records = await manager.query(
        `SELECT id FROM lesson_execution_records WHERE planned_lesson_id = $1 AND user_id = $2 LIMIT 1;`,
        [op.entityId, userId],
      );
      if (records && records.length > 0) {
        throw new FactualIntegrityException(
          `A aula planejada '${op.entityId}' não pode ser excluída pois possui registro histórico fático de execução (diário de classe).`,
        );
      }
    }

    // 4. Não permitir rebaixamento ou alteração do status de aula planejada com execução vinculada
    if (op.entityType === 'planned_lesson' && op.mutationType === 'UPDATE') {
      const records = await manager.query(
        `SELECT id, status FROM lesson_execution_records WHERE planned_lesson_id = $1 AND user_id = $2 LIMIT 1;`,
        [op.entityId, userId],
      );
      if (records && records.length > 0) {
        const payloadStatus = op.payload?.status as string | undefined;
        if (
          payloadStatus &&
          payloadStatus !== 'completed' &&
          payloadStatus !== 'partiallyCompleted' &&
          payloadStatus !== 'notHeld'
        ) {
          throw new FactualIntegrityException(
            `Não é permitido alterar ou reverter o status de uma aula planejada para '${payloadStatus}' quando há registro fático de execução vinculado.`,
          );
        }
      }
    }

    // 5. Monotonicidade temporal e imutabilidade de recorded_at em LessonExecutionRecord
    if (
      op.entityType === 'lesson_execution_record' &&
      (op.mutationType === 'UPDATE' || op.mutationType === 'INSERT')
    ) {
      const existing = await manager.query(
        `SELECT recorded_at, updated_at FROM lesson_execution_records WHERE id = $1 AND user_id = $2 LIMIT 1;`,
        [op.entityId, userId],
      );
      if (existing && existing.length > 0) {
        const existingRow = existing[0];
        if (op.payload?.recorded_at) {
          const payloadRec = new Date(op.payload.recorded_at as string).getTime();
          const existingRec = new Date(existingRow.recorded_at).getTime();
          if (Math.abs(payloadRec - existingRec) > 1000) {
            throw new FactualIntegrityException(
              `A data original de realização da aula (recorded_at) é imutável.`,
            );
          }
        }

        if (op.payload?.updated_at) {
          const payloadUpd = new Date(op.payload.updated_at as string).getTime();
          const existingRec = new Date(existingRow.recorded_at).getTime();
          const existingUpd = existingRow.updated_at
            ? new Date(existingRow.updated_at).getTime()
            : existingRec;

          if (payloadUpd < existingRec || payloadUpd < existingUpd) {
            throw new FactualIntegrityException(
              `A data de retificação pedagógica (updated_at) deve ser posterior ou igual ao registro original e à retificação anterior.`,
            );
          }
        }
      }
    }
  }

  /**
   * Aplica a mutação direta na tabela de negócio, respeitando o isolamento por user_id.
   * Suporta tabelas associativas com chave primária composta e tabelas com ID simples.
   */
  private async applyEntityMutation(
    manager: EntityManager,
    userId: string,
    op: SyncOperationInput,
  ): Promise<void> {
    const tableName = this.resolveTableName(op.entityType);

    // Tratamento de DELETE para tabelas associativas e tabelas com ID simples
    if (op.mutationType === 'DELETE') {
      if (op.entityType === 'content_prerequisite') {
        const [contentId, prereqId] = op.entityId.split(':');
        const cId = (op.payload?.content_id as string) ?? contentId;
        const pId = (op.payload?.prerequisite_content_id as string) ?? prereqId;
        await manager.query(
          `DELETE FROM content_prerequisites WHERE content_id = $1 AND prerequisite_content_id = $2 AND user_id = $3;`,
          [cId, pId, userId],
        );
        return;
      }

      if (op.entityType === 'lesson_content_allocation') {
        const [lessonId, contentId] = op.entityId.split(':');
        const lId = (op.payload?.lesson_id as string) ?? lessonId;
        const cId = (op.payload?.content_id as string) ?? contentId;
        await manager.query(
          `DELETE FROM lesson_content_allocations WHERE lesson_id = $1 AND content_id = $2 AND user_id = $3;`,
          [lId, cId, userId],
        );
        return;
      }

      if (op.entityType === 'execution_content_allocation') {
        const [recordId, contentId] = op.entityId.split(':');
        const rId = (op.payload?.record_id as string) ?? recordId;
        const cId = (op.payload?.content_id as string) ?? contentId;
        await manager.query(
          `DELETE FROM execution_content_allocations WHERE record_id = $1 AND content_id = $2 AND user_id = $3;`,
          [rId, cId, userId],
        );
        return;
      }

      await manager.query(`DELETE FROM ${tableName} WHERE id = $1 AND user_id = $2;`, [
        op.entityId,
        userId,
      ]);
      return;
    }

    if (!op.payload) {
      return;
    }

    // Tratamento de INSERT/UPDATE para tabelas associativas compostas
    if (op.entityType === 'content_prerequisite') {
      const [contentId, prereqId] = op.entityId.split(':');
      const cId = (op.payload.content_id as string) ?? contentId;
      const pId = (op.payload.prerequisite_content_id as string) ?? prereqId;
      await manager.query(
        `INSERT INTO content_prerequisites (content_id, prerequisite_content_id, user_id)
         VALUES ($1, $2, $3)
         ON CONFLICT (content_id, prerequisite_content_id, user_id) DO NOTHING;`,
        [cId, pId, userId],
      );
      return;
    }

    if (op.entityType === 'lesson_content_allocation') {
      const [lessonId, contentId] = op.entityId.split(':');
      const lId = (op.payload.lesson_id as string) ?? lessonId;
      const cId = (op.payload.content_id as string) ?? contentId;
      const orderIndex = (op.payload.order_index as number) ?? 1;
      await manager.query(
        `INSERT INTO lesson_content_allocations (lesson_id, content_id, user_id, order_index)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (lesson_id, content_id, user_id) DO UPDATE
         SET order_index = EXCLUDED.order_index;`,
        [lId, cId, userId, orderIndex],
      );
      return;
    }

    if (op.entityType === 'execution_content_allocation') {
      const [recordId, contentId] = op.entityId.split(':');
      const rId = (op.payload.record_id as string) ?? recordId;
      const cId = (op.payload.content_id as string) ?? contentId;
      const orderIndex = (op.payload.order_index as number) ?? 1;
      await manager.query(
        `INSERT INTO execution_content_allocations (record_id, content_id, user_id, order_index)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (record_id, content_id, user_id) DO UPDATE
         SET order_index = EXCLUDED.order_index;`,
        [rId, cId, userId, orderIndex],
      );
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
