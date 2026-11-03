import { ApiProperty } from '@nestjs/swagger';
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
}

export class ExplorationResponseDto {
  @ApiProperty({ type: ExplorationMapDto })
  map: ExplorationMapDto;
}
