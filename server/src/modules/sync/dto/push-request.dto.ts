import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsNotEmpty,
  IsString,
  IsUUID,
  registerDecorator,
  ValidateNested,
  ValidationArguments,
  ValidationOptions,
} from 'class-validator';
import { SyncOperationDto } from './sync-operation.dto';

/**
 * Validador customizado para garantir que não existam clientOpIds duplicados dentro do mesmo lote.
 */
export function IsUniqueClientOpIds(validationOptions?: ValidationOptions) {
  return function (object: object, propertyName: string) {
    registerDecorator({
      name: 'isUniqueClientOpIds',
      target: object.constructor,
      propertyName: propertyName,
      options: validationOptions,
      validator: {
        validate(value: unknown) {
          if (!Array.isArray(value)) return true;
          const seen = new Set<string>();
          for (const item of value) {
            if (item && typeof item === 'object' && 'clientOpId' in item) {
              const opId = (item as { clientOpId: unknown }).clientOpId;
              if (typeof opId === 'string') {
                if (seen.has(opId)) {
                  return false;
                }
                seen.add(opId);
              }
            }
          }
          return true;
        },
        defaultMessage(args: ValidationArguments) {
          return `Identificadores de operação duplicados no mesmo lote: cada clientOpId deve ser estritamente único no array '${args.property}'.`;
        },
      },
    });
  };
}

export class PushRequestDto {
  @IsString({ message: 'deviceId deve ser uma string identificadora do dispositivo.' })
  @IsNotEmpty({ message: 'deviceId é obrigatório.' })
  deviceId!: string;

  @IsUUID('4', { message: 'clientBatchId deve ser um UUID v4 válido.' })
  @IsNotEmpty({ message: 'clientBatchId é obrigatório.' })
  clientBatchId!: string;

  @IsArray({ message: 'operations deve ser um array de operações de sincronização.' })
  @ArrayMinSize(1, { message: 'O lote de sincronização deve conter pelo menos 1 operação.' })
  @ArrayMaxSize(100, {
    message: 'O lote de sincronização não pode exceder o teto máximo de 100 operações.',
  })
  @IsUniqueClientOpIds()
  @ValidateNested({ each: true })
  @Type(() => SyncOperationDto)
  operations!: SyncOperationDto[];
}
