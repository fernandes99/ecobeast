import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsInt,
  IsObject,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';
import { INTERIOR_LAYERS } from '../domain/interiors/interior-body.js';

const integer = (field: string) => ({
  message: `${field} precisa ser um número inteiro.`,
});
const list = (field: string) => ({
  message: `${field} precisa ser uma lista.`,
});
const text = (field: string) => ({ message: `${field} precisa ser um texto.` });

export class InteriorCellDto {
  @ApiProperty({ description: 'A coluna, de 0 à largura − 1.', example: 3 })
  @IsInt(integer('x'))
  x: number;

  @ApiProperty({ description: 'A linha, de 0 à altura − 1.', example: 5 })
  @IsInt(integer('y'))
  y: number;
}

export class InteriorTileDto extends InteriorCellDto {
  @ApiProperty({ enum: INTERIOR_LAYERS, example: 'floor' })
  @IsString(text('layer'))
  layer: string;

  @ApiProperty({
    description: 'A folha do pacote: `walls_floor`, `interior` ou `doors_windows`.',
    example: 'walls_floor',
  })
  @IsString(text('sheet'))
  sheet: string;

  @ApiProperty({ description: 'A coluna do tile na folha, de 0 a 63.', example: 4 })
  @IsInt(integer('col'))
  col: number;

  @ApiProperty({ description: 'A linha do tile na folha, de 0 a 63.', example: 9 })
  @IsInt(integer('row'))
  row: number;
}

export class InteriorObjectDto extends InteriorCellDto {
  @ApiPropertyOptional({
    description: 'Na leitura, o id do objeto; no salvar, é ignorado.',
    example: 7,
  })
  @IsOptional()
  id?: number;

  @ApiProperty({ example: 'interior' })
  @IsString(text('sheet'))
  sheet: string;

  @ApiProperty({ description: 'O tile do canto de cima à esquerda na folha.', example: 0 })
  @IsInt(integer('col'))
  col: number;

  @ApiProperty({ example: 0 })
  @IsInt(integer('row'))
  row: number;

  @ApiProperty({ description: 'A largura em tiles, de 1 a 8.', example: 2 })
  @IsInt(integer('width'))
  width: number;

  @ApiProperty({ description: 'A altura em tiles, de 1 a 8.', example: 3 })
  @IsInt(integer('height'))
  height: number;
}

export class InteriorNpcDto extends InteriorCellDto {
  @ApiPropertyOptional({
    description: 'Na leitura, o id do NPC na sala; no salvar, é ignorado.',
    example: 2,
  })
  @IsOptional()
  id?: number;

  @ApiProperty({ description: 'O id em `npcs`.', example: 12 })
  @IsInt(integer('npc_id'))
  npc_id: number;

  @ApiProperty({
    description:
      'A fala, até 2.000 caracteres; uma linha em branco separa as falas. Vazio é sem fala.',
    example: 'Bem-vindo ao Refúgio!',
  })
  @IsString(text('dialogue'))
  dialogue: string;

  @ApiProperty({
    description: 'O id em `action_types`, que roda depois da última fala, ou nulo.',
    example: 1,
    nullable: true,
    type: Number,
  })
  @IsOptional()
  @IsInt(integer('action_type_id'))
  action_type_id: number | null;
}

class InteriorFieldsDto {
  @ApiProperty({ description: 'O nome, de 1 a 40 caracteres.', example: 'Refúgio' })
  @IsString(text('name'))
  name: string;

  @ApiProperty({ description: 'A largura, de 4 a 64 quadrados.', example: 26 })
  @IsInt(integer('width'))
  width: number;

  @ApiProperty({ description: 'A altura, de 4 a 64 quadrados.', example: 22 })
  @IsInt(integer('height'))
  height: number;

  @ApiProperty({
    description: 'O quadrado de chão, sem bloqueio, onde o Domador nasce e por onde sai.',
    type: InteriorCellDto,
  })
  @IsObject({ message: 'door precisa ser um objeto.' })
  @ValidateNested()
  @Type(() => InteriorCellDto)
  door: InteriorCellDto;

  @ApiProperty({ type: [InteriorTileDto] })
  @IsArray(list('tiles'))
  @ValidateNested({ each: true })
  @Type(() => InteriorTileDto)
  tiles: InteriorTileDto[];

  @ApiProperty({
    description: 'Os objetos, na ordem de desenho: um que cobre outro anterior fica por cima.',
    type: [InteriorObjectDto],
  })
  @IsArray(list('objects'))
  @ValidateNested({ each: true })
  @Type(() => InteriorObjectDto)
  objects: InteriorObjectDto[];

  @ApiProperty({
    description: 'Os quadrados bloqueados, além dos sem chão.',
    type: [InteriorCellDto],
  })
  @IsArray(list('blocks'))
  @ValidateNested({ each: true })
  @Type(() => InteriorCellDto)
  blocks: InteriorCellDto[];

  @ApiProperty({ type: [InteriorNpcDto] })
  @IsArray(list('npcs'))
  @ValidateNested({ each: true })
  @Type(() => InteriorNpcDto)
  npcs: InteriorNpcDto[];
}

/** O corpo do `PUT`: a sala inteira, com os `id` opcionais e ignorados. */
export class InteriorBodyDto extends InteriorFieldsDto {
  @ApiPropertyOptional({ description: 'Ignorado no salvar.', example: 1 })
  @IsOptional()
  id?: number;
}

export class InteriorDto extends InteriorFieldsDto {
  @ApiProperty({ example: 1 })
  id: number;
}
