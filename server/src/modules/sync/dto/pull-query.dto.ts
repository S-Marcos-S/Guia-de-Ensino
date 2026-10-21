import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class PullQueryDto {
  @IsOptional()
  @IsString({ message: "cursor deve ser uma string no formato '<serverSeq>:<id>'." })
  cursor?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt({ message: 'limit deve ser um número inteiro.' })
  @Min(1, { message: 'limit deve ser no mínimo 1.' })
  @Max(500, { message: 'limit não pode exceder 500 registros por página.' })
  limit?: number = 100;

  @IsOptional()
  @IsString({ message: 'excludeDeviceId deve ser uma string identificadora do dispositivo.' })
  excludeDeviceId?: string;

  @IsOptional()
  @IsString({ message: 'clientEpoch deve ser uma string numérica representando a época.' })
  clientEpoch?: string;
}
