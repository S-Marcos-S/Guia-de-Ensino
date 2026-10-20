import { BadRequestException, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SyncStorageService, SyncOperationInput } from '../sync-storage/sync-storage.service';
import { PushRequestDto } from './dto/push-request.dto';
import { PushResponseDto } from './dto/push-response.dto';
import { OperationAckDto } from './dto/operation-ack.dto';
import { PullQueryDto } from './dto/pull-query.dto';
import { PullResponseDto } from './dto/pull-response.dto';
import { ChangeDto } from './dto/change.dto';
import { SnapshotQueryDto } from './dto/snapshot-query.dto';
import { SnapshotResponseDto } from './dto/snapshot-response.dto';
import { parseCursor } from './helpers/cursor.helper';
import { SnapshotTokenHelper } from './helpers/snapshot-token.helper';
import { SyncEpochMismatchException } from '../../common/exceptions/sync-epoch-mismatch.exception';
import { InvalidCursorException } from '../../common/exceptions/invalid-cursor.exception';

@Injectable()
export class SyncService {
  constructor(
    private readonly syncStorageService: SyncStorageService,
    private readonly configService?: ConfigService,
  ) {}

  /**
   * Processa o lote de sincronização enviado pelo cliente (Push).
   */
  async processPush(userId: string, dto: PushRequestDto): Promise<PushResponseDto> {
    // 1. Defesa em profundidade: validação de unicidade de clientOpId no lote
    const opIds = new Set<string>();
    for (const op of dto.operations) {
      if (opIds.has(op.clientOpId)) {
        throw new BadRequestException(
          `Identificadores de operação duplicados no mesmo lote: clientOpId '${op.clientOpId}' repetido não é permitido.`,
        );
      }
      opIds.add(op.clientOpId);
    }

    // 2. Mapeamento das operações de DTO para a camada de persistência
    const operations: SyncOperationInput[] = dto.operations.map((op) => ({
      clientOpId: op.clientOpId,
      deviceId: dto.deviceId,
      entityType: op.entityType,
      entityId: op.entityId,
      mutationType: op.mutationType,
      payload: op.payload ?? null,
    }));

    // 3. Execução do lote sob transação atômica com advisory lock e idempotência
    const results = await this.syncStorageService.processBatchMutations(
      userId,
      dto.deviceId,
      operations,
    );

    // 4. Consulta a versão e sequência atualizada do usuário
    const syncVersion = await this.syncStorageService.getUserSyncVersion(userId);

    // 5. Serialização dos ACKs com representação string de BIGINT
    const acks: OperationAckDto[] = results.map((r) => ({
      clientOpId: r.clientOpId,
      status: r.status,
      serverSeq: r.serverSeq.toString(),
      appliedAt: r.appliedAt.toISOString(),
      conflict: null,
    }));

    return {
      clientBatchId: dto.clientBatchId,
      serverEpoch: syncVersion.epoch.toString(),
      currentServerSeq: syncVersion.currentSeq.toString(),
      acks,
    };
  }

  /**
   * Consulta paginada incremental de alterações com cursor composto (Pull).
   */
  async processPull(userId: string, query: PullQueryDto): Promise<PullResponseDto> {
    // 1. Valida e analisa o cursor composto (lança InvalidCursorException se malformado ou negativo)
    const parsedCursor = parseCursor(query.cursor);

    // 2. Limite seguro: padrão 100, teto 500
    const limit = query.limit ? Math.min(Math.max(query.limit, 1), 500) : 100;

    // 3. Consulta as alterações no serviço de persistência
    const pullResult = await this.syncStorageService.getChangesSinceCursor(
      userId,
      parsedCursor.serverSeq,
      parsedCursor.id,
      limit,
      query.excludeDeviceId,
    );

    // 4. Validação de época (epoch) com retorno 410 Gone / RESYNC_REQUIRED
    if (query.clientEpoch !== undefined && query.clientEpoch !== null && query.clientEpoch !== '') {
      if (pullResult.epoch.toString() !== query.clientEpoch) {
        throw new SyncEpochMismatchException(query.clientEpoch, pullResult.epoch.toString());
      }
    }

    // 5. Gate de validação de cursor futuro: rejeita com HTTP 400 (INVALID_CURSOR)
    // se o serverSeq solicitado for estritamente superior ao currentServerSeq do servidor
    if (parsedCursor.serverSeq > pullResult.currentSeq) {
      throw new InvalidCursorException(
        `Cursor inválido: serverSeq '${parsedCursor.serverSeq.toString()}' excede a sequência atual do servidor '${pullResult.currentSeq.toString()}'.`,
        {
          requestedSeq: parsedCursor.serverSeq.toString(),
          currentServerSeq: pullResult.currentSeq.toString(),
        },
      );
    }

    // 6. Mapeia os eventos serializando BIGINT para strings decimais
    const changes: ChangeDto[] = pullResult.changes.map((c) => ({
      serverSeq: c.serverSeq.toString(),
      changeLogId: c.id.toString(),
      entityType: c.entityType,
      entityId: c.entityId,
      mutationType: c.mutationType,
      payload: c.payload,
      deviceId: c.deviceId,
      createdAt: c.createdAt.toISOString(),
    }));

    return {
      epoch: pullResult.epoch.toString(),
      currentServerSeq: pullResult.currentSeq.toString(),
      nextCursor: pullResult.nextCursor,
      hasMore: pullResult.hasMore,
      changes,
    };
  }

  /**
   * Extrai o snapshot consistente de todas as 13 coleções pedagógicas do usuário sob REPEATABLE READ.
   * Emite token opaco assinado com HMAC-SHA256 e TTL de 15 minutos.
   */
  async processSnapshot(userId: string, query: SnapshotQueryDto): Promise<SnapshotResponseDto> {
    const jwtSecret =
      this.configService?.get<string>('JWT_SECRET') ??
      process.env.JWT_SECRET ??
      'fallback-secret-minimum-32-chars-long';

    // Se o cliente forneceu um snapshotToken, valida a autenticidade e validade temporal
    if (query.snapshotToken) {
      SnapshotTokenHelper.verifyToken(query.snapshotToken, userId, jwtSecret);
    }

    // Extrai o snapshot atômico sob REPEATABLE READ
    const snapshotResult = await this.syncStorageService.getUserSnapshot(userId);

    // Gera o token assinado HMAC-SHA256 para o snapshot
    const { token, expiresAt } = SnapshotTokenHelper.generateToken(
      userId,
      snapshotResult.snapshotSeq,
      snapshotResult.epoch,
      jwtSecret,
      15, // TTL 15 minutos
    );

    return {
      epoch: snapshotResult.epoch.toString(),
      snapshotSeq: snapshotResult.snapshotSeq.toString(),
      snapshotToken: token,
      expiresAt: expiresAt.toISOString(),
      entities: snapshotResult.entities,
    };
  }
}
