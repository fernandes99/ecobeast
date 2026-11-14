import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsInt,
  IsOptional,
  Max,
  Min,
  ValidateBy,
  ValidateIf,
} from 'class-validator';
import { INVALID_ENEMY } from '../battle/battle.dto.js';
import { ISLAND_NOT_FOUND } from '../islands/islands.service.js';

export const INVALID_TAMER = 'Domador de depuração inválido.';
import { BIOMES, MAX_HEIGHT } from '../domain/exploration/map-generator.js';
import type { Biome } from '../domain/exploration/map-generator.js';
import type {
  DraftObject,
  DraftProp,
  DraftTrail,
} from '../domain/islands/island-draft.js';

export class HexCoordDto {
  @ApiProperty({ description: 'Coluna, em coordenadas axiais.', example: 0 })
  q: number;

  @ApiProperty({ description: 'Linha, em coordenadas axiais.', example: 1 })
  r: number;
}

export class MapTileDto extends HexCoordDto {
  @ApiProperty({ enum: BIOMES, example: 'temperate' })
  biome: Biome;

  @ApiProperty({
    description: `A altura do terreno, de 0 a ${MAX_HEIGHT}, em qualquer bioma.`,
    example: 1,
  })
  height: number;

  @ApiProperty({
    description:
      'Qual sprite usar: de 1 a 3 em `hill` e `mountain`, de 1 a 6 nos outros.',
    example: 4,
  })
  variant: number;

  @ApiPropertyOptional({
    description:
      'O slug de um `ground_types` (trilha ou piso). Só aparece nas ilhas, no hexágono com chão.',
    example: 'dirt_trail',
  })
  ground?: string;

  @ApiPropertyOptional({
    description:
      'Só nas ilhas, e só `true`: o hexágono não tem as decorações naturais sorteadas do bioma.',
    example: true,
  })
  bare?: boolean;
}

export class MapCreatureDto extends HexCoordDto {
  @ApiProperty({ description: 'Este Ecobeast no mapa.', example: 1 })
  id: number;

  @ApiProperty({ description: 'Id da espécie, para o desenho.', example: 7 })
  species_id: number;
}

export class MapTamerDto extends HexCoordDto {
  @ApiProperty({ description: 'Este Domador no mapa.', example: 1 })
  id: number;

  @ApiProperty({
    description: 'Id do nome, em `npc_tamer_names`.',
    example: 4,
  })
  name_id: number;

  @ApiProperty({
    description: 'Id da fala do desafio, em `npc_tamer_greetings`.',
    example: 2,
  })
  greeting_id: number;
}

export class MapIslandDto {
  @ApiProperty({ example: 7 })
  id: number;

  @ApiProperty({
    description: 'O nome da versão publicada.',
    example: 'Ilha das Brumas',
  })
  name: string;
}

export class MapActionDto {
  @ApiProperty({ description: 'Id em `action_types`.', example: 1 })
  action_type_id: number;

  @ApiProperty({ type: [HexCoordDto] })
  tiles: HexCoordDto[];
}

export class MapObjectTileDto extends HexCoordDto {
  @ApiProperty({
    description: 'Se o Domador não atravessa este hexágono.',
    example: true,
  })
  blocks: boolean;
}

export class MapObjectDto extends HexCoordDto {
  @ApiProperty({ description: 'Id em `map_object_types`.', example: 1 })
  object_type_id: number;

  @ApiProperty({
    description: 'A variante da arte, de 1 em diante.',
    example: 1,
  })
  variant: number;

  @ApiProperty({ description: 'Se a arte está espelhada.', example: false })
  mirrored: boolean;

  @ApiProperty({ type: [MapObjectTileDto] })
  tiles: MapObjectTileDto[];
}

export class MapTrailDto {
  @ApiProperty({
    description: 'O `slug` em `ground_types`.',
    example: 'gravel_trail',
  })
  ground: string;

  @ApiProperty({ description: 'A largura, em pixels da arte.', example: 22 })
  width: number;

  @ApiProperty({
    type: [Number],
    description:
      'x0, y0, x1, y1, …, em pixels da arte, no chão plano, a partir do centro plano do hexágono (0, 0).',
    example: [12, -40, 30, -8, 31, 40],
  })
  points: number[];
}

export class MapPropDto extends HexCoordDto {
  @ApiProperty({ description: 'Id em `prop_types`.', example: 6 })
  prop_type_id: number;

  @ApiProperty({
    description: 'O pé, em pixels da arte, a partir do centro plano de (q, r).',
    example: -7,
  })
  dx: number;

  @ApiProperty({
    description: 'O pé, em pixels da arte, para baixo.',
    example: 4,
  })
  dy: number;

  @ApiProperty({
    description: 'A variante da arte, de 1 em diante.',
    example: 1,
  })
  variant: number;

  @ApiProperty({ description: 'Se a arte está espelhada.', example: false })
  mirrored: boolean;
}

export class ExplorationMapDto {
  @ApiProperty({ description: 'Reproduz o terreno.', example: 1234567 })
  seed: number;

  @ApiProperty({
    type: HexCoordDto,
    description: 'Onde o jogador começa: sempre terra plana.',
  })
  start: HexCoordDto;

  @ApiProperty({ type: [MapTileDto] })
  tiles: MapTileDto[];

  @ApiProperty({
    type: [MapCreatureDto],
    description: 'Os Ecobeasts do mapa. O nível só aparece na luta.',
  })
  creatures: MapCreatureDto[];

  @ApiProperty({
    type: [MapTamerDto],
    description:
      'Os Domadores NPC do mapa, um por hexágono. A equipe e o tamanho da ' +
      'luta só aparecem nela.',
  })
  tamers: MapTamerDto[];

  @ApiProperty({
    type: MapIslandDto,
    nullable: true,
    description: 'A ilha, ou `null` no mapa sorteado.',
  })
  island: MapIslandDto | null;

  @ApiProperty({
    type: [MapActionDto],
    description: 'As ações da ilha; vazio no mapa sorteado.',
  })
  actions: MapActionDto[];

  @ApiProperty({
    type: [MapObjectDto],
    description: 'Os objetos da ilha; vazio no mapa sorteado.',
  })
  objects: MapObjectDto[];

  @ApiProperty({
    type: [MapPropDto],
    description: 'As peças soltas da ilha, só enfeite; vazio no mapa sorteado.',
  })
  props: MapPropDto[];

  @ApiProperty({
    type: [MapTrailDto],
    description:
      'Os traços de caminho da ilha, só desenho, na ordem de desenho; vazio no mapa sorteado.',
  })
  trails: MapTrailDto[];
}

export class StartExplorationBodyDto {
  @ApiPropertyOptional({
    description:
      'A ilha publicada onde entrar. Sem ele, o servidor sorteia um mapa novo.',
    example: 7,
  })
  @IsOptional()
  // Uma conferência só: com @IsInt e @Min, "x" daria a mensagem duas vezes, numa
  // frase só, porque a validação junta as mensagens.
  @ValidateBy(
    {
      name: 'isIslandId',
      validator: {
        validate: (value: unknown) =>
          typeof value === 'number' && Number.isInteger(value) && value >= 1,
      },
    },
    { message: ISLAND_NOT_FOUND },
  )
  island_id?: number;
}

export class ExplorationResponseDto {
  @ApiProperty({ type: ExplorationMapDto })
  map: ExplorationMapDto;
}

export class DebugSpawnBodyDto {
  @ApiProperty({ description: 'Id da espécie.', example: 2 })
  @IsInt({ message: INVALID_ENEMY })
  species_id: number;

  @ApiProperty({
    description: 'Coluna do hexágono, em coordenadas axiais.',
    example: 0,
  })
  // Um erro por vez: a validação junta as mensagens numa frase só.
  @ValidateIf((body: DebugSpawnBodyDto) => Number.isInteger(body.species_id))
  @IsInt({ message: INVALID_ENEMY })
  q: number;

  @ApiProperty({
    description: 'Linha do hexágono, em coordenadas axiais.',
    example: 0,
  })
  @ValidateIf(
    (body: DebugSpawnBodyDto) =>
      Number.isInteger(body.species_id) && Number.isInteger(body.q),
  )
  @IsInt({ message: INVALID_ENEMY })
  r: number;

  @ApiPropertyOptional({
    description: 'Nível, de 1 a 100. Sem ele, a média de nível da equipe.',
    example: 16,
  })
  @IsOptional()
  @ValidateIf(
    (body: DebugSpawnBodyDto) =>
      Number.isInteger(body.species_id) &&
      Number.isInteger(body.q) &&
      Number.isInteger(body.r),
  )
  @IsInt({ message: INVALID_ENEMY })
  @Min(1, { message: INVALID_ENEMY })
  @Max(100, { message: INVALID_ENEMY })
  level?: number;
}

export class DebugSpawnResponseDto {
  @ApiProperty({ type: MapCreatureDto })
  creature: MapCreatureDto;
}

export class DebugClearResponseDto {
  @ApiProperty({
    type: [Number],
    description: 'Os ids que saíram da exploração.',
    example: [501, 502],
  })
  removed_ids: number[];

  @ApiProperty({
    type: [Number],
    description: 'Os ids dos Domadores da depuração que saíram da exploração.',
    example: [26],
  })
  removed_tamer_ids: number[];
}

export class DebugTamerBodyDto {
  @ApiProperty({
    description: 'Coluna do hexágono, em coordenadas axiais.',
    example: 0,
  })
  @IsInt({ message: INVALID_TAMER })
  q: number;

  @ApiProperty({
    description: 'Linha do hexágono, em coordenadas axiais.',
    example: 0,
  })
  // Um erro por vez: a validação junta as mensagens numa frase só.
  @ValidateIf((body: DebugTamerBodyDto) => Number.isInteger(body.q))
  @IsInt({ message: INVALID_TAMER })
  r: number;

  @ApiProperty({ description: 'O tamanho da luta: 1, 2 ou 3.', example: 3 })
  @ValidateIf(
    (body: DebugTamerBodyDto) =>
      Number.isInteger(body.q) && Number.isInteger(body.r),
  )
  @IsInt({ message: INVALID_TAMER })
  @Min(1, { message: INVALID_TAMER })
  @Max(3, { message: INVALID_TAMER })
  size: number;
}

export class DebugTamerResponseDto {
  @ApiProperty({ type: MapTamerDto })
  tamer: MapTamerDto;
}

export function toObjectDto(object: DraftObject): MapObjectDto {
  return {
    object_type_id: object.objectTypeId,
    q: object.q,
    r: object.r,
    variant: object.variant,
    mirrored: object.mirrored,
    tiles: object.tiles.map(({ q, r, blocks }) => ({ q, r, blocks })),
  };
}

export function toTrailDto({ ground, width, points }: DraftTrail): MapTrailDto {
  return { ground, width, points: [...points] };
}

export function toPropDto(prop: DraftProp): MapPropDto {
  return {
    prop_type_id: prop.propTypeId,
    q: prop.q,
    r: prop.r,
    dx: prop.dx,
    dy: prop.dy,
    variant: prop.variant,
    mirrored: prop.mirrored,
  };
}
