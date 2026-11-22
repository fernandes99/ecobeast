import { ApiProperty } from '@nestjs/swagger';
import { IsInt } from 'class-validator';
import { TamerProgressDto } from '../tamer-level/tamer-level.dto.js';
import type { QuestPlace } from './quests.service.js';

export const INVALID_TALK = 'Informe o NPC da conversa.';
export const INVALID_REACH = 'Informe o hexágono do Domador.';

export class QuestTalkBodyDto {
  @ApiProperty({
    description: 'O NPC do catálogo (`npcs`) da conversa que terminou.',
    example: 6,
  })
  @IsInt({ message: INVALID_TALK })
  npc_id: number;
}

export class QuestReachBodyDto {
  @ApiProperty({ example: 4 })
  @IsInt({ message: INVALID_REACH })
  q: number;

  @ApiProperty({ example: -2 })
  @IsInt({ message: INVALID_REACH })
  r: number;
}

export class QuestTileDto {
  @ApiProperty({ example: 4 })
  q: number;

  @ApiProperty({ example: -2 })
  r: number;
}

export class QuestPlaceDto {
  @ApiProperty({ description: 'A missão "Vá até" (`quests`).', example: 3 })
  quest_id: number;

  @ApiProperty({ description: 'O nome do lugar.', example: 'o Farol' })
  name: string;

  @ApiProperty({ type: () => [QuestTileDto] })
  tiles: QuestTileDto[];
}

export function toQuestPlaceDto({
  questId,
  name,
  tiles,
}: QuestPlace): QuestPlaceDto {
  return { quest_id: questId, name, tiles };
}

export class QuestRewardDto {
  @ApiProperty({ description: 'As moedas pagas.', example: 50 })
  coins: number;

  @ApiProperty({ type: 'integer', nullable: true, example: 1 })
  item_id: number | null;

  @ApiProperty({ type: 'integer', nullable: true, example: 2 })
  item_quantity: number | null;

  @ApiProperty({
    description: 'O XP de Domador da missão (e da ilha aberta, se abriu).',
    example: 100,
  })
  xp: number;
}

export class QuestIslandDto {
  @ApiProperty({ example: 2 })
  id: number;

  @ApiProperty({ example: 'Brisa' })
  name: string;
}

export class QuestTalkResponseDto {
  @ApiProperty({
    description:
      'As falas da missão, para a caixa de fala, depois da fala do NPC. ' +
      'Vazias quando ele não tem o que dizer.',
    type: [String],
    example: [
      'Missão cumprida: Capture 3 Ecobeasts!',
      'Nova missão: Vá até o Farol.',
    ],
  })
  lines: string[];

  @ApiProperty({
    description: 'A recompensa paga agora; nula sem entrega.',
    type: () => QuestRewardDto,
    nullable: true,
  })
  reward: QuestRewardDto | null;

  @ApiProperty({
    description: 'O XP de Domador e os níveis subidos; nulo sem entrega.',
    type: () => TamerProgressDto,
    nullable: true,
  })
  tamer_progress: TamerProgressDto | null;

  @ApiProperty({
    description: 'A ilha que a entrega abriu, por completar esta.',
    type: () => QuestIslandDto,
    nullable: true,
  })
  island_unlocked: QuestIslandDto | null;

  @ApiProperty({
    description: 'Os lugares das missões "Vá até" que faltam nesta ilha.',
    type: () => [QuestPlaceDto],
  })
  quest_places: QuestPlaceDto[];
}

export class QuestReachResponseDto {
  @ApiProperty({
    description: 'Os nomes dos lugares alcançados agora.',
    type: [String],
    example: ['o Farol'],
  })
  reached: string[];

  @ApiProperty({ type: () => [QuestPlaceDto] })
  quest_places: QuestPlaceDto[];
}
