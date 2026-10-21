import { ValueTransformer } from 'typeorm';

/**
 * Transformer para garantir a preservação estrita de precisão de 64 bits (BIGINT)
 * entre o PostgreSQL e o runtime JavaScript/TypeScript.
 *
 * Evita perdas de precisão ao ultrapassar Number.MAX_SAFE_INTEGER (2^53 - 1).
 */
export const bigintTransformer: ValueTransformer = {
  to: (value: bigint | string | number | null | undefined): string | null => {
    if (value === null || value === undefined) {
      return null;
    }
    return value.toString();
  },
  from: (value: string | number | null | undefined): bigint | null => {
    if (value === null || value === undefined) {
      return null;
    }
    return BigInt(value);
  },
};
