import { ApiProperty } from '@nestjs/swagger';

/**
 * Uma ilha na lista do jogador (islands/02). O nome não repete o
 * `IslandSummaryDto` do editor: o /docs guarda os esquemas pelo nome da classe.
 */
export class PlayerIslandDto {
  @ApiProperty({ example: 7 })
  id: number;

  @ApiProperty({
    description: 'O nome da versão publicada.',
    example: 'Ilha das Brumas',
  })
  name: string;
}

export class PlayerIslandsResponseDto {
  @ApiProperty({
    type: [PlayerIslandDto],
    description: 'As ilhas publicadas, em ordem de id.',
  })
  islands: PlayerIslandDto[];
}
