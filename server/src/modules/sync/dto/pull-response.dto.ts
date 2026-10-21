import { ChangeDto } from './change.dto';

export class PullResponseDto {
  epoch!: string;
  currentServerSeq!: string;
  nextCursor!: string;
  hasMore!: boolean;
  changes!: ChangeDto[];
}
