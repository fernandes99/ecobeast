import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsBoolean,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
} from 'class-validator';

export const INVALID_QUEST = 'Missão inválida.';
export const INVALID_DIRECTION = 'Use "up" ou "down".';
export const INVALID_REQUIRED =
  'Informe nulo (todas) ou um número maior que 0.';

export class QuestEditorTileDto {
  @ApiProperty({ example: 4 })
  q: number;

  @ApiProperty({ example: -2 })
  r: number;
}

export class QuestEditorBodyDto {
  @ApiProperty({ description: 'O NPC que dá a missão (`npcs`).', example: 6 })
  @IsInt({ message: INVALID_QUEST })
  npc_id: number;

  @ApiProperty({ description: 'O tipo, de 1 a 9 (`quest_types`).', example: 1 })
  @IsInt({ message: INVALID_QUEST })
  quest_type_id: number;

  @ApiPropertyOptional({
    description:
      'A quantidade (tipos 1, 2, 7 e 8), a porcentagem (3) ou os minutos (6).',
    type: 'integer',
    nullable: true,
    example: 3,
  })
  @IsOptional()
  @IsInt({ message: INVALID_QUEST })
  amount?: number | null;

  @ApiPropertyOptional({ type: 'integer', nullable: true, example: 15 })
  @IsOptional()
  @IsInt({ message: INVALID_QUEST })
  species_id?: number | null;

  @ApiPropertyOptional({
    description: 'O NPC alvo (tipos 5 e 9; no 9, um Domador da ilha).',
    type: 'integer',
    nullable: true,
    example: 7,
  })
  @IsOptional()
  @IsInt({ message: INVALID_QUEST })
  target_npc_id?: number | null;

  @ApiPropertyOptional({
    description: 'O item do "Encontre X item" (tipo 10, auralis/09).',
    type: 'integer',
    nullable: true,
  })
  @IsOptional()
  @IsInt({ message: INVALID_QUEST })
  target_item_id?: number | null;

  @ApiPropertyOptional({ type: String, nullable: true, example: 'o Farol' })
  @IsOptional()
  @IsString({ message: INVALID_QUEST })
  place_name?: string | null;

  @ApiPropertyOptional({
    description: 'O título no lugar do que sai do tipo.',
    type: String,
    nullable: true,
  })
  @IsOptional()
  @IsString({ message: INVALID_QUEST })
  title?: string | null;

  @ApiPropertyOptional({ example: 50 })
  @IsOptional()
  @IsInt({ message: INVALID_QUEST })
  coins?: number;

  @ApiPropertyOptional({ type: 'integer', nullable: true, example: 1 })
  @IsOptional()
  @IsInt({ message: INVALID_QUEST })
  item_id?: number | null;

  @ApiPropertyOptional({ type: 'integer', nullable: true, example: 2 })
  @IsOptional()
  @IsInt({ message: INVALID_QUEST })
  item_quantity?: number | null;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean({ message: INVALID_QUEST })
  counts_for_unlock?: boolean;

  @ApiPropertyOptional({
    description: 'Os hexágonos do lugar (tipo 4), do rascunho da ilha.',
    type: () => [QuestEditorTileDto],
  })
  @IsOptional()
  @IsArray({ message: INVALID_QUEST })
  tiles?: QuestEditorTileDto[];
}

export class QuestMoveBodyDto {
  @ApiProperty({ enum: ['up', 'down'] })
  @IsIn(['up', 'down'], { message: INVALID_DIRECTION })
  direction: 'up' | 'down';
}

export class QuestRequiredBodyDto {
  @ApiProperty({
    description:
      'Quantas missões que contam abrem a seguinte; nulo pede todas.',
    type: 'integer',
    nullable: true,
    example: 2,
  })
  @IsOptional()
  @IsInt({ message: INVALID_REQUIRED })
  required_quests: number | null;
}

export class QuestTypeDto {
  @ApiProperty({ example: 1 })
  id: number;

  @ApiProperty({ example: 'capture_any' })
  slug: string;

  @ApiProperty({ example: 'Capture N Ecobeasts' })
  name: string;

  @ApiProperty()
  description: string;
}

export class QuestEditorDto {
  @ApiProperty({ example: 3 })
  id: number;

  @ApiProperty({ example: 6 })
  npc_id: number;

  @ApiProperty({ description: 'A ordem na fila do NPC.', example: 1 })
  position: number;

  @ApiProperty({ example: 1 })
  quest_type_id: number;

  @ApiProperty({ type: 'integer', nullable: true })
  amount: number | null;

  @ApiProperty({ type: 'integer', nullable: true })
  species_id: number | null;

  @ApiProperty({ type: 'integer', nullable: true })
  target_npc_id: number | null;

  @ApiProperty({ type: 'integer', nullable: true })
  target_item_id: number | null;

  @ApiProperty({ type: String, nullable: true })
  place_name: string | null;

  @ApiProperty({ type: String, nullable: true })
  title: string | null;

  @ApiProperty({ example: 50 })
  coins: number;

  @ApiProperty({ type: 'integer', nullable: true })
  item_id: number | null;

  @ApiProperty({ type: 'integer', nullable: true })
  item_quantity: number | null;

  @ApiProperty({ example: true })
  counts_for_unlock: boolean;

  @ApiProperty({ type: () => [QuestEditorTileDto] })
  tiles: QuestEditorTileDto[];

  @ApiProperty({
    description: 'O título que o jogador vê.',
    example: 'Capture 3 Ecobeasts',
  })
  display_title: string;
}

export class QuestsEditorResponseDto {
  @ApiProperty({
    description:
      'Quantas missões que contam abrem a seguinte; nulo pede todas.',
    type: 'integer',
    nullable: true,
  })
  required_quests: number | null;

  @ApiProperty({ type: () => [QuestTypeDto] })
  types: QuestTypeDto[];

  @ApiProperty({
    description: 'Em ordem de NPC e de posição na fila.',
    type: () => [QuestEditorDto],
  })
  quests: QuestEditorDto[];
}
