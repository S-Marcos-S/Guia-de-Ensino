import { OperationAckDto } from './operation-ack.dto';

export class PushResponseDto {
  clientBatchId!: string;
  serverEpoch!: string;
  currentServerSeq!: string;
  acks!: OperationAckDto[];
}
