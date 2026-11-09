import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, Max, Min, ValidateIf } from 'class-validator';
import { INVALID_ENEMY } from '../battle/battle.dto.js';

export const INVALID_TAMER = 'Domador de depuração inválido.';
import { BIOMES, TERRAIN_SHAPES } from '../domain/exploration/map-generator.js';
import type {
  Biome,
  TerrainShape,
} from '../domain/exploration/map-generator.js';

export class HexCoordDto {
  @ApiProperty({ description: 'Coluna, em coordenadas axiais.', example: 0 })
  q: number;

  @ApiProperty({ description: 'Linha, em coordenadas axiais.', example: 1 })
  r: number;
}

export class MapTileDto extends HexCoordDto {
  @ApiProperty({ enum: BIOMES, example: 'temperate' })
  biome: Biome;

  @ApiProperty({ enum: TERRAIN_SHAPES, example: 'flat' })
  shape: TerrainShape;

  @ApiProperty({
    description: 'Qual sprite usar: de 1 a 6 em `flat`, de 1 a 3 nas outras.',
    example: 4,
  })
  variant: number;
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
}

export class ExplorationResponseDto {
  @ApiProperty({ type: ExplorationMapDto })
  map: ExplorationMapDto;
}

/** O spawn de depuração (.specs/biome-encounters/05-debug-spawn-battle.md). */
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

/** O Domador de depuração (.specs/npc-tamers/03-tamer-api.md, RF-10). */
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
