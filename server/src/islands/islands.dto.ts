import { ApiProperty } from '@nestjs/swagger';

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
