import { BadRequestException, Injectable } from '@nestjs/common';
import { SyncStorageService, SyncOperationInput } from '../sync-storage/sync-storage.service';
import { PushRequestDto } from './dto/push-request.dto';
import { PushResponseDto } from './dto/push-response.dto';
import { OperationAckDto } from './dto/operation-ack.dto';

@Injectable()
export class SyncService {
  constructor(private readonly syncStorageService: SyncStorageService) {}

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
}
