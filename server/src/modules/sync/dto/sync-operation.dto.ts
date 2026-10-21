import {
  IsIn,
  IsISO8601,
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
  IsUUID,
} from 'class-validator';

export const ALLOWED_SYNC_ENTITIES = [
  'academic_year',
  'classroom',
  'subject',
  'classroom_subject',
  'school_calendar_event',
  'schedule_slot',
  'curriculum_competency',
  'course_content',
  'content_prerequisite',
  'planned_lesson',
  'lesson_content_allocation',
  'lesson_execution_record',
  'execution_content_allocation',
] as const;

export type SyncEntityType = (typeof ALLOWED_SYNC_ENTITIES)[number];

export const ALLOWED_MUTATION_TYPES = ['INSERT', 'UPDATE', 'DELETE'] as const;
export type MutationType = (typeof ALLOWED_MUTATION_TYPES)[number];

export class SyncOperationDto {
  @IsUUID('4', { message: 'clientOpId deve ser um UUID v4 válido.' })
  @IsNotEmpty({ message: 'clientOpId é obrigatório.' })
  clientOpId!: string;

  @IsIn(ALLOWED_SYNC_ENTITIES, {
    message: (args) =>
      `Tipo de entidade '${args.value}' inválido. Entidades permitidas: ${ALLOWED_SYNC_ENTITIES.join(', ')}`,
  })
  @IsNotEmpty({ message: 'entityType é obrigatório.' })
  entityType!: SyncEntityType;

  @IsString({ message: 'entityId deve ser uma string.' })
  @IsNotEmpty({ message: 'entityId é obrigatório.' })
  entityId!: string;

  @IsIn(ALLOWED_MUTATION_TYPES, {
    message: "mutationType deve ser 'INSERT', 'UPDATE' ou 'DELETE'.",
  })
  @IsNotEmpty({ message: 'mutationType é obrigatório.' })
  mutationType!: MutationType;

  @IsOptional()
  @IsString({ message: 'baseSeq deve ser uma string numérica.' })
  baseSeq?: string;

  @IsOptional()
  @IsISO8601({ strict: true }, { message: 'clientCreatedAt deve ser uma data ISO 8601 válida.' })
  clientCreatedAt?: string;

  @IsOptional()
  @IsObject({ message: 'payload deve ser um objeto JSON válido.' })
  payload?: Record<string, unknown> | null;
}
