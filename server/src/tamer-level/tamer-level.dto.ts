import { ApiProperty } from '@nestjs/swagger';

export class TamerLevelRewardDto {
  @ApiProperty({ description: 'O nível que o Domador alcançou.', example: 5 })
  level: number;

  @ApiProperty({ description: 'As moedas pagas pelo nível.', example: 100 })
  reward_coins: number;

  @ApiProperty({
    description: 'O item pago pelo nível, posto na Mochila.',
    type: 'integer',
    nullable: true,
    example: 1,
  })
  reward_item_id: number | null;

  @ApiProperty({ type: 'integer', nullable: true, example: 3 })
  reward_item_quantity: number | null;
}

export class TamerProgressDto {
  @ApiProperty({ description: 'O XP de Domador ganho agora.', example: 108 })
  xp_gained: number;

  @ApiProperty({ example: 4 })
  level_before: number;

  @ApiProperty({ example: 5 })
  level_after: number;

  @ApiProperty({ description: 'O XP total do Domador depois.', example: 250 })
  current_xp: number;

  @ApiProperty({
    description: 'O XP total do começo do nível atual.',
    example: 211,
  })
  level_xp: number;

  @ApiProperty({
    description: 'O XP total do próximo nível; nulo no nível máximo.',
    type: 'integer',
    nullable: true,
    example: 340,
  })
  next_level_xp: number | null;

  @ApiProperty({
    description:
      'Cada nível subido, em ordem, com a recompensa já paga. Vazio sem subir.',
    type: () => [TamerLevelRewardDto],
  })
  levels: TamerLevelRewardDto[];
}
