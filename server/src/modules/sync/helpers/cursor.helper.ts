import { BadRequestException } from '@nestjs/common';

export interface ParsedCursor {
  serverSeq: bigint;
  id: bigint;
}

/**
 * Analisa e valida o cursor composto no formato '<serverSeq>:<id>'.
 * Lança BadRequestException se o formato for inválido, contiver valores negativos ou não numéricos.
 */
export function parseCursor(cursor?: string): ParsedCursor {
  if (!cursor || cursor.trim() === '') {
    return { serverSeq: 0n, id: 0n };
  }

  const trimmed = cursor.trim();
  const match = trimmed.match(/^(\d+):(\d+)$/);
  if (!match) {
    throw new BadRequestException(
      `Cursor inválido: '${cursor}'. O cursor deve seguir estritamente o formato '<serverSeq>:<id>' com números inteiros não negativos.`,
    );
  }

  try {
    const serverSeq = BigInt(match[1]);
    const id = BigInt(match[2]);
    return { serverSeq, id };
  } catch {
    throw new BadRequestException(
      `Cursor inválido: '${cursor}'. Valores numéricos fora do intervalo representável.`,
    );
  }
}
