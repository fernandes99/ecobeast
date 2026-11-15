import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsInt,
  IsOptional,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';
import { MAX_BLOCK_VARIANT } from '../domain/islands/blocked-hexes.js';
import { DraftBlockLineDto } from './islands-editor.dto.js';

const VARIANT_RANGE = `variant vai de 0 a ${MAX_BLOCK_VARIANT}.`;

export class PropTypeBlocksDto {
  @ApiPropertyOptional({
    example: 1,
    description:
      'A variante das linhas (prop-depth-blocks/02). 0, ou sem o campo, vale para as variantes sem linhas próprias.',
  })
  @IsOptional()
  @IsInt({ message: 'variant precisa ser um número inteiro.' })
  @Min(0, { message: VARIANT_RANGE })
  @Max(MAX_BLOCK_VARIANT, { message: VARIANT_RANGE })
  variant?: number;

  @ApiProperty({
    type: [DraftBlockLineDto],
    description:
      'As linhas de bloqueio padrão do tipo nessa variante, até 8, na ordem; `[]` apaga as dela (a variante 0 fica sem bloqueio, as outras voltam à 0).',
  })
  @IsArray({ message: 'blocks precisa ser uma lista.' })
  @ValidateNested({ each: true })
  @Type(() => DraftBlockLineDto)
  blocks: DraftBlockLineDto[];
}

export class BlockedStartDto {
  @ApiProperty({ example: 3 })
  island_id: number;

  @ApiProperty({ enum: ['draft', 'published'], example: 'published' })
  kind: string;

  @ApiProperty({ example: 'Vila da Fonte Azul' })
  name: string;
}

export class PropTypeBlocksSavedDto {
  @ApiProperty({ type: [DraftBlockLineDto] })
  blocks: DraftBlockLineDto[];

  @ApiProperty({
    type: [BlockedStartDto],
    description:
      'As versões de ilha com a chegada num hexágono que passou a ser bloqueado. A rota não recusa; o próximo salvar daquela ilha recusa até a chegada mudar.',
  })
  blocked_starts: BlockedStartDto[];
}
