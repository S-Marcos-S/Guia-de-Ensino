export class ChangeDto {
  serverSeq!: string;
  changeLogId!: string;
  entityType!: string;
  entityId!: string;
  mutationType!: string;
  payload!: Record<string, unknown> | null;
  deviceId!: string;
  createdAt!: string;
}
