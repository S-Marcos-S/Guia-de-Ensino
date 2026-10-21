export type AckStatus = 'APPLIED' | 'SKIPPED' | 'CONFLICT';

export interface ConflictDetails {
  reason: string;
  serverVersion?: Record<string, unknown> | null;
  clientVersion?: Record<string, unknown> | null;
}

export class OperationAckDto {
  clientOpId!: string;
  status!: AckStatus;
  serverSeq!: string;
  appliedAt!: string;
  conflict!: ConflictDetails | null;
}
