import { ApiProperty } from '@nestjs/swagger';
import { ValidateBy } from 'class-validator';

export class PlayerIslandDto {
  @ApiProperty({ example: 7 })
  id: number;

  @ApiProperty({
    description: 'O nome da versão publicada.',
    example: 'Ilha das Brumas',
  })
  name: string;

  @ApiProperty({
    description: 'É a casa do jogador, onde o jogo abre (no máximo uma).',
  })
  home: boolean;
}

export class PlayerIslandsResponseDto {
  @ApiProperty({
    type: [PlayerIslandDto],
    description:
      'As ilhas publicadas, em ordem de id, sem as trancadas do Arquipélago.',
  })
  islands: PlayerIslandDto[];
}

export const INVALID_DISCOVERY = 'Hexágonos descobertos inválidos.';
export const MAX_DISCOVERIES = 1000;
const MAX_COORD = 100_000;

function isCoord(value: unknown): boolean {
  return (
    typeof value === 'number' &&
    Number.isInteger(value) &&
    Math.abs(value) <= MAX_COORD
  );
}

export class DiscoveredHexDto {
  @ApiProperty({ description: 'Coluna, em coordenadas axiais.', example: 0 })
  q: number;

  @ApiProperty({ description: 'Linha, em coordenadas axiais.', example: 1 })
  r: number;
}

export class DiscoveriesBodyDto {
  @ApiProperty({
    type: [DiscoveredHexDto],
    description: `De 1 a ${MAX_DISCOVERIES} hexágonos que o Domador descobriu na ilha.`,
  })
  // Uma conferência só, para o erro sair com uma mensagem só.
  @ValidateBy(
    {
      name: 'isDiscoveryList',
      validator: {
        validate: (value: unknown) =>
          Array.isArray(value) &&
          value.length >= 1 &&
          value.length <= MAX_DISCOVERIES &&
          value.every(
            (item: unknown) =>
              typeof item === 'object' &&
              item !== null &&
              isCoord((item as DiscoveredHexDto).q) &&
              isCoord((item as DiscoveredHexDto).r),
          ),
      },
    },
    { message: INVALID_DISCOVERY },
  )
  tiles: DiscoveredHexDto[];
}

export class DiscoveriesAddedDto {
  @ApiProperty({
    description:
      'Quantos hexágonos foram gravados agora: os repetidos e os que não ' +
      'existem na versão publicada da ilha ficam de fora.',
    example: 12,
  })
  added: number;
}

export class DiscoveriesRemovedDto {
  @ApiProperty({
    description: 'Quantos hexágonos foram apagados.',
    example: 40,
  })
  removed: number;
}
