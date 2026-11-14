import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsIn,
  IsInt,
  IsObject,
  IsOptional,
  IsString,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';
import { BIOMES, MAX_HEIGHT } from '../domain/exploration/map-generator.js';
import type { Biome } from '../domain/exploration/map-generator.js';
import { MapTileDto } from '../exploration/exploration.dto.js';

const integer = (field: string) => ({
  message: `${field} precisa ser um número inteiro.`,
});
const list = (field: string) => ({
  message: `${field} precisa ser uma lista.`,
});
const text = (field: string) => ({ message: `${field} precisa ser um texto.` });

export const ISLAND_STATUSES = ['draft', 'published', 'changed'] as const;
export type IslandStatus = (typeof ISLAND_STATUSES)[number];

export class EditorHexDto {
  @ApiProperty({ description: 'Coluna, em coordenadas axiais.', example: 0 })
  @IsInt(integer('q'))
  q: number;

  @ApiProperty({ description: 'Linha, em coordenadas axiais.', example: 0 })
  @IsInt(integer('r'))
  r: number;
}

export class DraftTileDto extends EditorHexDto {
  @ApiProperty({ enum: BIOMES, example: 'temperate' })
  @IsIn(BIOMES, {
    message: `biome precisa ser ${BIOMES.join(', ')}.`,
  })
  biome: Biome;

  @ApiProperty({
    description: `A altura do terreno, de 0 a ${MAX_HEIGHT}, em qualquer bioma.`,
    example: 1,
  })
  @IsInt(integer('height'))
  @Min(0, { message: `height vai de 0 a ${MAX_HEIGHT}.` })
  @Max(MAX_HEIGHT, { message: `height vai de 0 a ${MAX_HEIGHT}.` })
  height: number;

  @ApiProperty({
    description:
      'Qual sprite usar: de 1 a 3 em `hill` e `mountain`, de 1 a 6 nos outros.',
    example: 2,
  })
  @IsInt(integer('variant'))
  variant: number;

  @ApiPropertyOptional({
    description:
      'O slug de um `ground_types` (trilha ou piso). Sem ele, o hexágono não tem chão.',
    example: 'dirt_trail',
    nullable: true,
  })
  @IsOptional()
  @IsString(text('ground'))
  ground?: string | null;

  @ApiPropertyOptional({
    description:
      'A `key` da área do hexágono. Sem ela, o hexágono não tem área.',
    example: 1,
  })
  @IsOptional()
  @IsInt(integer('area'))
  area?: number;

  @ApiPropertyOptional({
    description:
      'Verdadeiro no hexágono sem as decorações naturais sorteadas do bioma. Sem ele, o hexágono tem as decorações.',
    example: true,
  })
  @IsOptional()
  @IsBoolean({ message: 'bare precisa ser verdadeiro ou falso.' })
  bare?: boolean;
}

export class DraftActionDto {
  @ApiProperty({ description: 'Id em `action_types`.', example: 1 })
  @IsInt(integer('action_type_id'))
  action_type_id: number;

  @ApiProperty({ type: [EditorHexDto], description: 'Os hexágonos dela.' })
  @IsArray(list('tiles'))
  @ValidateNested({ each: true })
  @Type(() => EditorHexDto)
  tiles: EditorHexDto[];
}

export class DraftObjectTileDto extends EditorHexDto {
  @ApiProperty({
    description: 'Se o Domador não atravessa este hexágono.',
    example: true,
  })
  @IsBoolean({ message: 'blocks precisa ser verdadeiro ou falso.' })
  blocks: boolean;
}

export class DraftObjectDto extends EditorHexDto {
  @ApiProperty({ description: 'Id em `map_object_types`.', example: 1 })
  @IsInt(integer('object_type_id'))
  object_type_id: number;

  @ApiProperty({
    description: 'A variante da arte, de 1 em diante.',
    example: 1,
  })
  @IsInt(integer('variant'))
  variant: number;

  @ApiProperty({
    description: 'Se a arte e o formato estão espelhados na horizontal.',
    example: false,
  })
  @IsBoolean({ message: 'mirrored precisa ser verdadeiro ou falso.' })
  mirrored: boolean;

  @ApiProperty({
    type: [DraftObjectTileDto],
    description:
      'Os hexágonos do objeto, com o de apoio (q, r) entre eles, e o bloqueio de cada um.',
  })
  @IsArray(list('tiles'))
  @ValidateNested({ each: true })
  @Type(() => DraftObjectTileDto)
  tiles: DraftObjectTileDto[];
}

export class DraftPropDto extends EditorHexDto {
  @ApiProperty({ description: 'Id em `prop_types`.', example: 6 })
  @IsInt(integer('prop_type_id'))
  prop_type_id: number;

  @ApiProperty({
    description:
      'O pé, em pixels da arte, a partir do centro plano do hexágono (q, r), ' +
      'para a direita. Precisa cair no próprio hexágono.',
    example: -7,
  })
  @IsInt(integer('dx'))
  dx: number;

  @ApiProperty({
    description:
      'O pé, em pixels da arte, para baixo. Precisa cair no próprio hexágono.',
    example: 4,
  })
  @IsInt(integer('dy'))
  dy: number;

  @ApiProperty({
    description: 'A variante da arte, de 1 a `prop_types.variants`.',
    example: 1,
  })
  @IsInt(integer('variant'))
  variant: number;

  @ApiProperty({ description: 'Se a arte está espelhada.', example: false })
  @IsBoolean({ message: 'mirrored precisa ser verdadeiro ou falso.' })
  mirrored: boolean;
}

export class DraftTrailDto {
  @ApiProperty({
    description: 'O `slug` em `ground_types`.',
    example: 'gravel_trail',
  })
  @IsString(text('ground'))
  ground: string;

  @ApiProperty({
    description: 'A largura, em pixels da arte, de 8 a 64.',
    example: 22,
  })
  @IsInt(integer('width'))
  width: number;

  @ApiProperty({
    type: [Number],
    description:
      'x0, y0, x1, y1, …: de 2 a 256 pontos, em pixels da arte, no chão plano, ' +
      'a partir do centro plano do hexágono (0, 0). Todo ponto cai num hexágono da ilha.',
    example: [12, -40, 30, -8, 31, 40],
  })
  @IsArray(list('points'))
  @IsInt({ each: true, message: 'points precisa ter só números inteiros.' })
  points: number[];
}

export class DraftAreaSpeciesDto {
  @ApiProperty({ example: 4 })
  @IsInt(integer('species_id'))
  species_id: number;

  @ApiProperty({
    description: 'Peso no sorteio da área, maior que 0.',
    example: 60,
  })
  @IsInt(integer('weight'))
  weight: number;

  @ApiProperty({ description: 'De 1 a 100.', example: 3 })
  @IsInt(integer('min_level'))
  min_level: number;

  @ApiProperty({ description: 'De 1 a 100, a partir do mínimo.', example: 6 })
  @IsInt(integer('max_level'))
  max_level: number;
}

export class DraftAreaDto {
  @ApiProperty({
    description:
      'Um número do próprio rascunho, de 1 em diante, para os hexágonos ' +
      'apontarem para a área. Ao ler, as áreas vêm numeradas de novo.',
    example: 1,
  })
  @IsInt(integer('key'))
  key: number;

  @ApiProperty({
    description: 'De 1 a 40 caracteres.',
    example: 'Bosque do norte',
  })
  @IsString(text('name'))
  name: string;

  @ApiProperty({ description: 'A cor da área no editor.', example: '#5B8C3A' })
  @IsString(text('color_hex'))
  color_hex: string;

  @ApiProperty({
    description:
      'Quantos Ecobeasts nascem na área a cada entrada na ilha, de 1 a 200.',
    example: 10,
  })
  @IsInt(integer('spawn_count'))
  spawn_count: number;

  @ApiProperty({ type: [DraftAreaSpeciesDto] })
  @IsArray(list('species'))
  @ValidateNested({ each: true })
  @Type(() => DraftAreaSpeciesDto)
  species: DraftAreaSpeciesDto[];
}

export class IslandDraftDto {
  @ApiProperty({
    description: 'De 1 a 40 caracteres.',
    example: 'Ilha das Brumas',
  })
  @IsString(text('name'))
  name: string;

  @ApiProperty({ type: EditorHexDto, description: 'A chegada.' })
  @ValidateNested()
  @Type(() => EditorHexDto)
  start: EditorHexDto;

  @ApiProperty({ type: [DraftTileDto], description: 'De 1 a 20.000.' })
  @IsArray(list('tiles'))
  @ValidateNested({ each: true })
  @Type(() => DraftTileDto)
  tiles: DraftTileDto[];

  @ApiProperty({ type: [DraftActionDto] })
  @IsArray(list('actions'))
  @ValidateNested({ each: true })
  @Type(() => DraftActionDto)
  actions: DraftActionDto[];

  @ApiProperty({ type: [DraftObjectDto] })
  @IsArray(list('objects'))
  @ValidateNested({ each: true })
  @Type(() => DraftObjectDto)
  objects: DraftObjectDto[];

  @ApiPropertyOptional({
    type: [DraftPropDto],
    description:
      'As peças soltas, só enfeite, até 6.000. Sem o campo, a ilha fica sem peças.',
  })
  @IsOptional()
  @IsArray(list('props'))
  @ValidateNested({ each: true })
  @Type(() => DraftPropDto)
  props?: DraftPropDto[];

  @ApiPropertyOptional({
    type: [DraftTrailDto],
    description:
      'Os traços de caminho, só desenho, até 500, na ordem de desenho. Sem o campo, a ilha fica sem traços.',
  })
  @IsOptional()
  @IsArray(list('trails'))
  @ValidateNested({ each: true })
  @Type(() => DraftTrailDto)
  trails?: DraftTrailDto[];

  @ApiProperty({ type: [DraftAreaDto] })
  @IsArray(list('areas'))
  @ValidateNested({ each: true })
  @Type(() => DraftAreaDto)
  areas: DraftAreaDto[];
}

export class IslandDraftResponseDto extends IslandDraftDto {
  @ApiProperty({ example: 1 })
  id: number;

  @ApiProperty({
    enum: ISLAND_STATUSES,
    description:
      '`draft`: nunca publicada; `published`: o rascunho é igual à publicada; ' +
      '`changed`: há mudanças não publicadas.',
  })
  status: IslandStatus;

  @ApiProperty({ description: 'O último salvar.' })
  updated_at: string;

  @ApiProperty({
    nullable: true,
    type: String,
    description: 'A última publicação.',
  })
  published_at: string | null;
}

export class IslandSummaryDto {
  @ApiProperty({ example: 1 })
  id: number;

  @ApiProperty({
    description: 'O nome do rascunho.',
    example: 'Ilha das Brumas',
  })
  name: string;

  @ApiProperty({ enum: ISLAND_STATUSES })
  status: IslandStatus;

  @ApiProperty()
  updated_at: string;

  @ApiProperty({ nullable: true, type: String })
  published_at: string | null;
}

export class IslandListResponseDto {
  @ApiProperty({ type: [IslandSummaryDto] })
  islands: IslandSummaryDto[];
}

export class IslandCreatedResponseDto {
  @ApiProperty({ example: 1 })
  id: number;
}

export class IslandSavedResponseDto {
  @ApiProperty({ enum: ISLAND_STATUSES })
  status: IslandStatus;

  @ApiProperty()
  updated_at: string;
}

export class IslandPublishedResponseDto {
  @ApiProperty({ enum: ISLAND_STATUSES })
  status: IslandStatus;

  @ApiProperty()
  published_at: string;
}

export class MapGeneratorBodyDto {
  @ApiProperty({ description: 'De 0 a 2³² − 1.', example: 1234567 })
  @IsInt(integer('seed'))
  @Min(0, { message: 'seed precisa ficar entre 0 e 4294967295.' })
  @Max(2 ** 32 - 1, { message: 'seed precisa ficar entre 0 e 4294967295.' })
  seed: number;

  @ApiPropertyOptional({
    description:
      'Os parâmetros do gerador, em snake_case (`tile_count`, `water_fraction`…). ' +
      'O que faltar vem do padrão. As faixas estão no GET desta rota.',
    example: { tile_count: 4000, water_fraction: 0.3 },
  })
  @IsOptional()
  @IsObject({ message: 'config precisa ser um objeto.' })
  config?: Record<string, number>;
}

export class MapGeneratorResponseDto {
  @ApiProperty({
    type: EditorHexDto,
    description: 'A terra plana mais perto de (0, 0).',
  })
  start: EditorHexDto;

  @ApiProperty({ type: [MapTileDto] })
  tiles: MapTileDto[];
}

export class ConfigRangeDto {
  @ApiProperty()
  min: number;

  @ApiProperty()
  max: number;

  @ApiProperty({ description: 'O valor precisa ser inteiro.' })
  integer: boolean;
}

export class MapGeneratorParamsResponseDto {
  @ApiProperty({
    description: 'Os parâmetros padrão, em snake_case.',
    example: { tile_count: 10000, water_fraction: 0.2 },
  })
  defaults: Record<string, number>;

  @ApiProperty({
    description: 'A faixa aceita de cada parâmetro, em snake_case.',
    example: { tile_count: { min: 100, max: 20000, integer: true } },
  })
  ranges: Record<string, ConfigRangeDto>;
}
