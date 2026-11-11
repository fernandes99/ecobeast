import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsIn,
  IsInt,
  IsObject,
  IsOptional,
  IsString,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';
import { BIOMES, TERRAIN_SHAPES } from '../domain/exploration/map-generator.js';
import type {
  Biome,
  TerrainShape,
} from '../domain/exploration/map-generator.js';
import { MapTileDto } from '../exploration/exploration.dto.js';

/** O rascunho de uma ilha e as respostas do editor (.specs/map-editor/architecture.md, "Contrato"). */

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

  @ApiProperty({ enum: TERRAIN_SHAPES, example: 'flat' })
  @IsIn(TERRAIN_SHAPES, {
    message: `shape precisa ser ${TERRAIN_SHAPES.join(', ')}.`,
  })
  shape: TerrainShape;

  @ApiProperty({
    description: 'Qual sprite usar: de 1 a 6 em `flat`, de 1 a 3 nas outras.',
    example: 2,
  })
  @IsInt(integer('variant'))
  variant: number;

  @ApiPropertyOptional({
    description:
      'A `key` da área do hexágono. Sem ela, o hexágono não tem área.',
    example: 1,
  })
  @IsOptional()
  @IsInt(integer('area'))
  area?: number;
}

export class DraftBuildingDto {
  @ApiProperty({ description: 'Id em `building_types`.', example: 1 })
  @IsInt(integer('building_type_id'))
  building_type_id: number;

  @ApiProperty({ type: [EditorHexDto], description: 'Os hexágonos dela.' })
  @IsArray(list('tiles'))
  @ValidateNested({ each: true })
  @Type(() => EditorHexDto)
  tiles: EditorHexDto[];
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

  @ApiProperty({ type: [DraftBuildingDto] })
  @IsArray(list('buildings'))
  @ValidateNested({ each: true })
  @Type(() => DraftBuildingDto)
  buildings: DraftBuildingDto[];

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
