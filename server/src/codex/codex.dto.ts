import { ApiProperty } from '@nestjs/swagger';

export class CodexEntryDto {
  @ApiProperty({
    description: 'A espécie, que é também o número no Bestiário.',
    example: 4,
  })
  species_id: number;

  @ApiProperty({
    description:
      'Se o jogador já capturou um Ecobeast dela. Falso: só viu numa luta.',
    example: false,
  })
  caught: boolean;
}

export class CodexResponseDto {
  @ApiProperty({
    description:
      'As espécies que o jogador conhece, na ordem do número. Uma espécie do catálogo fora daqui nunca foi vista.',
    type: () => [CodexEntryDto],
  })
  entries: CodexEntryDto[];
}
