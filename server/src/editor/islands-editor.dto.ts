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
import {
  MapBridgeDto,
  MapPropDto,
  MapTileDto,
} from '../exploration/exploration.dto.js';

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

  @ApiPropertyOptional({
    description:
      'O slug da zona (`biome_zones`), do bioma do hexágono. Sem ela, ou com o slug do bioma, o hexágono fica na Comum (biome-zones/03).',
    example: 'temperate_woods',
    nullable: true,
  })
  @IsOptional()
  @IsString(text('zone'))
  zone?: string | null;
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

export class DraftBlockLineDto {
  @ApiProperty({
    description: 'Liga o último ponto ao primeiro.',
    example: true,
  })
  @IsBoolean({ message: 'closed precisa ser verdadeiro ou falso.' })
  closed: boolean;

  @ApiProperty({
    type: [Number],
    description:
      'x0, y0, x1, y1, …: de 2 a 64 pontos (3 numa fechada), em pixels da arte, no chão plano, a partir do pé da peça, sem o espelho. Cada coordenada entre −512 e 512.',
    example: [-40, -6, 40, -6, 40, 10, -40, 10],
  })
  @IsArray(list('points'))
  @IsInt({ each: true, message: 'points precisa ter só números inteiros.' })
  points: number[];
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

  @ApiPropertyOptional({
    type: [DraftBlockLineDto],
    description:
      'As linhas de bloqueio ajustadas da peça, até 8; `[]` não bloqueia. Sem o campo, valem as do tipo.',
  })
  @IsOptional()
  @IsArray(list('block'))
  @ValidateNested({ each: true })
  @Type(() => DraftBlockLineDto)
  block?: DraftBlockLineDto[] | null;

  @ApiPropertyOptional({
    description:
      'Id em `action_types`: a ação acontece quando o Domador encosta no bloqueio da peça. Até 500 peças com ação por ilha.',
    example: 1,
  })
  @IsOptional()
  @IsInt(integer('action_type_id'))
  action_type_id?: number | null;

  @ApiPropertyOptional({
    description:
      'Se a casa fica sem a fumaça da chaminé. Sem o campo, ela solta fumaça (só nos tipos que têm chaminé).',
    example: true,
  })
  @IsOptional()
  @IsBoolean({ message: 'no_smoke precisa ser verdadeiro ou falso.' })
  no_smoke?: boolean | null;

  @ApiPropertyOptional({
    description:
      'Id em `interiors`: tocar na peça abre a sala, no lugar da tela da ação. Sem o campo, a peça não tem sala.',
    example: 1,
  })
  @IsOptional()
  @IsInt(integer('interior_id'))
  interior_id?: number | null;
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

export class DraftWallDto {
  @ApiProperty({
    description: 'O `slug` em `wall_types`.',
    example: 'wood_fence',
  })
  @IsString(text('type'))
  type: string;

  @ApiProperty({
    type: [Number],
    description:
      'x0, y0, x1, y1, …: de 2 a 128 pontos, em pixels da arte, no chão plano, ' +
      'a partir do centro plano do hexágono (0, 0). Todo ponto cai num hexágono da ilha.',
    example: [12, -40, 30, -8, 31, 40],
  })
  @IsArray(list('points'))
  @IsInt({ each: true, message: 'points precisa ter só números inteiros.' })
  points: number[];
}

export class DraftBridgeDto {
  @ApiProperty({
    description: 'O `slug` em `bridge_types`.',
    example: 'wood_bridge',
  })
  @IsString(text('type'))
  type: string;

  @ApiProperty({
    type: [Number],
    description:
      'x0, y0, x1, y1: as duas pontas, em pixels da arte, no chão plano, a partir do ' +
      'centro plano do hexágono (0, 0). Cada ponta cai num hexágono da ilha que não é água, ' +
      'e elas ficam a pelo menos 16 px uma da outra.',
    example: [12, -40, 140, 20],
  })
  @IsArray(list('points'))
  @IsInt({ each: true, message: 'points precisa ter só números inteiros.' })
  points: number[];

  @ApiPropertyOptional({
    description:
      'A largura do piso, em pixels da arte, de 16 a 64. Sem o campo, 28. Ao ler, sempre vem.',
    example: 28,
  })
  @IsOptional()
  @IsInt(integer('width'))
  width?: number;
}

export class DraftNpcDto extends EditorHexDto {
  @ApiProperty({
    description: 'Id em `npcs`. (q, r) é o hexágono onde ele nasce.',
    example: 1,
  })
  @IsInt(integer('npc_id'))
  npc_id: number;

  @ApiProperty({
    description: 'Parado; com `true`, o passeio é ignorado.',
    example: false,
  })
  @IsBoolean({ message: 'still precisa ser verdadeiro ou falso.' })
  still: boolean;

  @ApiPropertyOptional({
    type: [EditorHexDto],
    description:
      'Os hexágonos do passeio, até 40, sem o de nascimento, que sempre faz parte dele. Sem o campo, o passeio fica vazio.',
  })
  @IsOptional()
  @IsArray(list('tiles'))
  @ValidateNested({ each: true })
  @Type(() => EditorHexDto)
  tiles?: EditorHexDto[];

  @ApiPropertyOptional({
    description:
      'Até 2.000 caracteres; cada parágrafo é uma fala. Vazio ou sem o campo, o NPC não fala.',
    example: 'Bem-vindo!\n\nO Refúgio fica ali.',
  })
  @IsOptional()
  @IsString(text('dialogue'))
  dialogue?: string;

  @ApiPropertyOptional({
    description:
      'Id em `action_types`, que roda depois da última fala. `null` ou sem o campo, sem ação.',
    example: 1,
    nullable: true,
    type: Number,
  })
  @IsOptional()
  @IsInt(integer('action_type_id'))
  action_type_id?: number | null;
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

  @ApiPropertyOptional({
    type: [DraftPropDto],
    description:
      'As peças soltas, só enfeite, até 20.000. Sem o campo, a ilha fica sem peças.',
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

  @ApiPropertyOptional({
    type: [DraftWallDto],
    description:
      'As paredes, que bloqueiam o Domador: cercas e a parede invisível, até 2.000, na ordem. Sem o campo, a ilha fica sem paredes.',
  })
  @IsOptional()
  @IsArray(list('walls'))
  @ValidateNested({ each: true })
  @Type(() => DraftWallDto)
  walls?: DraftWallDto[];

  @ApiPropertyOptional({
    type: [DraftBridgeDto],
    description:
      'As pontes, retas, de terra a terra, até 500, na ordem. Sem o campo, a ilha fica sem pontes.',
  })
  @IsOptional()
  @IsArray(list('bridges'))
  @ValidateNested({ each: true })
  @Type(() => DraftBridgeDto)
  bridges?: DraftBridgeDto[];

  @ApiPropertyOptional({
    type: [DraftNpcDto],
    description:
      'Os NPCs postos na ilha, até 200. Sem o campo, a ilha fica sem NPCs. Ao ler, sempre vem.',
  })
  @IsOptional()
  @IsArray(list('npcs'))
  @ValidateNested({ each: true })
  @Type(() => DraftNpcDto)
  npcs?: DraftNpcDto[];

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

  @ApiProperty({ description: 'É a casa do jogador (no máximo uma ilha).' })
  home: boolean;
}

export class IslandHomeBodyDto {
  @ApiProperty({ description: 'Liga ou desliga a casa do jogador.' })
  @IsBoolean({ message: 'home precisa ser verdadeiro ou falso.' })
  home: boolean;
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
      'Os parâmetros do gerador, em snake_case (`tile_count`, `sea_fraction`…). ' +
      'O que faltar vem do padrão. As faixas estão no GET desta rota.',
    example: { tile_count: 4000, sea_fraction: 0.3 },
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

  @ApiProperty({
    type: [MapBridgeDto],
    description:
      'As pontes de madeira dos rios que atravessam o mapa (coast-rivers/03).',
  })
  bridges: MapBridgeDto[];

  @ApiProperty({
    type: [MapPropDto],
    description:
      'As pedras gigantes das Montanhas, com a linha de bloqueio em `block` (giant-rocks/02).',
  })
  props: MapPropDto[];
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
    example: { tile_count: 10000, sea_fraction: 0.3 },
  })
  defaults: Record<string, number>;

  @ApiProperty({
    description: 'A faixa aceita de cada parâmetro, em snake_case.',
    example: { tile_count: { min: 100, max: 20000, integer: true } },
  })
  ranges: Record<string, ConfigRangeDto>;
}
