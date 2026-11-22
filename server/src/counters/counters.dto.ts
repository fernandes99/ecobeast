import { ApiProperty } from '@nestjs/swagger';

export class PlayerCounterDto {
  @ApiProperty({
    description: 'O contador, do catálogo `counters`.',
    example: 1,
  })
  counter_id: number;

  @ApiProperty({
    description:
      'O recorte: 0 sem recorte; senão o id do Elemento, da parte do dia ou do bioma, conforme o `subject` do contador.',
    example: 0,
  })
  subject_id: number;

  @ApiProperty({ description: 'O valor contado até agora.', example: 102 })
  value: number;
}

export class CounterPartnerDto {
  @ApiProperty({ description: 'O Ecobeast do jogador.', format: 'uuid' })
  creature_uid: string;

  @ApiProperty({ description: 'A espécie dele.', example: 19 })
  species_id: number;

  @ApiProperty({ description: 'As lutas em que ele lutou.', example: 212 })
  battles: number;
}

export class CountersResponseDto {
  @ApiProperty({
    description: 'As linhas do jogador. Um contador sem linha vale 0.',
    type: () => [PlayerCounterDto],
  })
  counters: PlayerCounterDto[];

  @ApiProperty({
    description:
      'O Ecobeast do jogador com mais lutas; nulo enquanto nenhum lutou.',
    type: () => CounterPartnerDto,
    nullable: true,
  })
  partner: CounterPartnerDto | null;

  @ApiProperty({
    description: 'Quando o Domador foi criado.',
    format: 'date-time',
  })
  created_at: string;

  @ApiProperty({
    description:
      'Os biomas do catálogo onde o Domador anda (os que não são água).',
    example: 10,
  })
  walkable_biomes: number;
}
