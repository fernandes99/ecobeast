import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsArray, ValidateNested } from 'class-validator';
import { DraftBlockLineDto } from './islands-editor.dto.js';

export class PropTypeBlocksDto {
  @ApiProperty({
    type: [DraftBlockLineDto],
    description:
      'As linhas de bloqueio padrão do tipo, até 8, na ordem; `[]` deixa o tipo sem bloqueio.',
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
