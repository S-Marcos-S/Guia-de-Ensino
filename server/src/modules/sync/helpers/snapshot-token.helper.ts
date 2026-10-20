import * as crypto from 'crypto';
import { BadRequestException } from '@nestjs/common';
import { SnapshotExpiredException } from '../../../common/exceptions/snapshot-expired.exception';

export interface SnapshotTokenPayload {
  userId: string;
  snapshotSeq: bigint;
  epoch: bigint;
  expiresAt: Date;
}

export class SnapshotTokenHelper {
  /**
   * Gera um token de snapshot opaco assinado com HMAC-SHA256 e TTL padrão de 15 minutos.
   * Formato decodificado: `${userId}:${snapshotSeq}:${epoch}:${expiresAtMs}:${signature}`
   */
  static generateToken(
    userId: string,
    snapshotSeq: bigint,
    epoch: bigint,
    secret: string,
    ttlMinutes = 15,
  ): { token: string; expiresAt: Date } {
    const expiresAt = new Date(Date.now() + ttlMinutes * 60 * 1000);
    const dataToSign = `${userId}:${snapshotSeq.toString()}:${epoch.toString()}:${expiresAt.getTime()}`;
    const signature = crypto.createHmac('sha256', secret).update(dataToSign).digest('hex');
    const fullPayload = `${dataToSign}:${signature}`;
    const token = Buffer.from(fullPayload, 'utf-8').toString('base64url');

    return { token, expiresAt };
  }

  /**
   * Valida a integridade, assinatura e validade temporal do token de snapshot.
   * Lança SnapshotExpiredException (410 Gone) se expirado.
   * Lança BadRequestException (400 Bad Request) se for inválido, adulterado ou de outro usuário.
   */
  static verifyToken(token: string, expectedUserId: string, secret: string): SnapshotTokenPayload {
    if (!token || typeof token !== 'string') {
      throw new BadRequestException({
        statusCode: 400,
        error: 'Bad Request',
        message: 'Token de snapshot não fornecido ou em formato inválido.',
        code: 'INVALID_SNAPSHOT_TOKEN',
      });
    }

    let decoded: string;
    try {
      // Suporta tanto base64 quanto base64url
      decoded = Buffer.from(token, 'base64url').toString('utf-8');
    } catch {
      throw new BadRequestException({
        statusCode: 400,
        error: 'Bad Request',
        message: 'Token de snapshot ilegível ou base64 malformado.',
        code: 'INVALID_SNAPSHOT_TOKEN',
      });
    }

    const parts = decoded.split(':');
    if (parts.length !== 5) {
      throw new BadRequestException({
        statusCode: 400,
        error: 'Bad Request',
        message: 'Estrutura interna do token de snapshot é inválida.',
        code: 'INVALID_SNAPSHOT_TOKEN',
      });
    }

    const [userId, snapshotSeqStr, epochStr, expiresAtMsStr, signature] = parts;

    // 1. Validação de isolamento do usuário (não permite usar token de outro tenant)
    if (userId !== expectedUserId) {
      throw new BadRequestException({
        statusCode: 400,
        error: 'Bad Request',
        message: 'Token de snapshot não pertence ao usuário autenticado.',
        code: 'INVALID_SNAPSHOT_TOKEN',
      });
    }

    // 2. Validação criptográfica da assinatura HMAC-SHA256 com timingSafeEqual
    const dataToSign = `${userId}:${snapshotSeqStr}:${epochStr}:${expiresAtMsStr}`;
    const expectedSignature = crypto.createHmac('sha256', secret).update(dataToSign).digest('hex');

    const sigBuf = Buffer.from(signature, 'hex');
    const expBuf = Buffer.from(expectedSignature, 'hex');

    if (sigBuf.length !== expBuf.length || !crypto.timingSafeEqual(sigBuf, expBuf)) {
      throw new BadRequestException({
        statusCode: 400,
        error: 'Bad Request',
        message: 'Assinatura criptográfica do token de snapshot é inválida.',
        code: 'INVALID_SNAPSHOT_TOKEN',
      });
    }

    // 3. Validação de formato numérico dos campos
    let snapshotSeq: bigint;
    let epoch: bigint;
    const expiresAtMs = Number(expiresAtMsStr);

    try {
      snapshotSeq = BigInt(snapshotSeqStr);
      epoch = BigInt(epochStr);
      if (isNaN(expiresAtMs) || expiresAtMs <= 0) {
        throw new Error();
      }
    } catch {
      throw new BadRequestException({
        statusCode: 400,
        error: 'Bad Request',
        message: 'Dados numéricos do token de snapshot são inválidos.',
        code: 'INVALID_SNAPSHOT_TOKEN',
      });
    }

    const expiresAt = new Date(expiresAtMs);

    // 4. Verificação de expiração temporal (TTL 15m) -> 410 Gone
    if (Date.now() > expiresAt.getTime()) {
      throw new SnapshotExpiredException();
    }

    return {
      userId,
      snapshotSeq,
      epoch,
      expiresAt,
    };
  }
}
