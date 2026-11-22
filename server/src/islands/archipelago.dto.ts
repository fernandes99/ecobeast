import { ApiProperty } from '@nestjs/swagger';

export class ArchipelagoIslandDto {
  @ApiProperty({
    type: Number,
    nullable: true,
    example: 1199,
    description: 'Nulo nas ilhas escondidas.',
  })
  id: number | null;

  @ApiProperty({ description: 'A posição no Arquipélago.', example: 1 })
  order: number;

  @ApiProperty({
    enum: ['open', 'next', 'hidden'],
    description:
      '`open`: aberta para entrar; `next`: a próxima a abrir, trancada; ' +
      '`hidden`: trancada, mais adiante, sem id nem nome.',
  })
  state: 'open' | 'next' | 'hidden';

  @ApiProperty({
    type: String,
    nullable: true,
    example: 'Liora',
    description: 'O nome da versão publicada; nulo nas escondidas.',
  })
  name: string | null;
}

export class ArchipelagoResponseDto {
  @ApiProperty({
    type: [ArchipelagoIslandDto],
    description: 'As ilhas publicadas do Arquipélago, em ordem.',
  })
  islands: ArchipelagoIslandDto[];
}
