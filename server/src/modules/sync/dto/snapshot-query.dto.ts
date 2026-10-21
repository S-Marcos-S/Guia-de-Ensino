import { IsOptional, IsString } from 'class-validator';

export class SnapshotQueryDto {
  @IsOptional()
  @IsString()
  snapshotToken?: string;
}
