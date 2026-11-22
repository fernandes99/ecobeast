import { ApiProperty } from '@nestjs/swagger';
import { IsInt } from 'class-validator';
import type { DraftItem } from '../domain/islands/island-draft.js';

export const INVALID_PICK = 'Informe o item do chão.';

export class GroundItemDto {
  @ApiProperty({
    description: 'O item no chão, único na ilha; é o que `pick` recebe.',
    example: 81234567,
  })
  key: number;

  @ApiProperty({ description: 'Id em `items`.', example: 1 })
  item_id: number;

  @ApiProperty({ example: 4 })
  q: number;

  @ApiProperty({ example: -2 })
  r: number;

  @ApiProperty({ description: 'De 1 a 99.', example: 1 })
  quantity: number;

  @ApiProperty({
    description: 'Escondido: o jogo mostra só um brilho fraco de perto.',
    example: false,
  })
  hidden: boolean;
}

export function toGroundItemDto({
  key,
  itemId,
  q,
  r,
  quantity,
  hidden,
}: DraftItem): GroundItemDto {
  return { key, item_id: itemId, q, r, quantity, hidden };
}

export class PickGroundItemBodyDto {
  @ApiProperty({ description: 'A `key` do item no chão.', example: 81234567 })
  @IsInt({ message: INVALID_PICK })
  key: number;
}

export class PickGroundItemResponseDto {
  @ApiProperty({ description: 'Id em `items`.', example: 1 })
  item_id: number;

  @ApiProperty({ description: 'Quantos foram para a Mochila.', example: 2 })
  quantity: number;

  @ApiProperty({
    description: 'A fala da caixa de fala.',
    example: 'Você encontrou 2 Tônico Leve!',
  })
  line: string;
}
