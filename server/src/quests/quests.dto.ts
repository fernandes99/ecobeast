import { ApiProperty } from '@nestjs/swagger';
import { IsInt } from 'class-validator';
import { TamerProgressDto } from '../tamer-level/tamer-level.dto.js';
import type { DialogueStep } from '../domain/quests/quest-dialogue.js';
import type { QuestOffer, QuestPlace, TalkStage } from './quests.service.js';

export const INVALID_TALK = 'Informe o NPC da conversa.';
export const INVALID_REACH = 'Informe o hexágono do Domador.';
export const INVALID_ACCEPT = 'Informe a missão.';

const DIALOGUE_DESCRIPTION =
  'Os passos da conversa escrita: falas (`{type: "say", speaker: "npc" | "tamer" | "narration", text}`) ' +
  'e escolhas (`{type: "choice", options: [{text, outcome: "accept" | "decline" | null, steps}]}`).';

export class QuestAcceptBodyDto {
  @ApiProperty({ description: 'A missão oferecida (`quests`).', example: 3 })
  @IsInt({ message: INVALID_ACCEPT })
  quest_id: number;
}

export class QuestOfferDto {
  @ApiProperty({ example: 4 })
  quest_id: number;

  @ApiProperty({
    description: DIALOGUE_DESCRIPTION,
    type: 'array',
    items: { type: 'object', additionalProperties: true },
  })
  dialogue: DialogueStep[];

  @ApiProperty({
    description: 'A cena da história no lugar da conversa de início.',
    type: String,
    nullable: true,
  })
  offer_scene: string | null;
}

export function toQuestOfferDto(offer: QuestOffer): QuestOfferDto {
  return {
    quest_id: offer.questId,
    dialogue: offer.dialogue,
    offer_scene: offer.offerScene,
  };
}

export class QuestAcceptResponseDto {
  @ApiProperty({
    description: 'A fala da missão aceita; vazia se ela já estava aceita.',
    type: [String],
    example: ['Nova missão: Capture 3 Ecobeasts.'],
  })
  lines: string[];

  @ApiProperty({ type: () => [QuestPlaceDto] })
  quest_places: QuestPlaceDto[];
}

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
      'Em que ponto está a primeira missão não entregue do NPC: sem missão ' +
      '(`none`), para oferecer (`offer`, ainda não aceita), em andamento ' +
      '(`ongoing`) ou entregue agora (`done`).',
    enum: ['none', 'offer', 'ongoing', 'done'],
  })
  stage: TalkStage;

  @ApiProperty({ type: 'integer', nullable: true, example: 3 })
  quest_id: number | null;

  @ApiProperty({
    description: `A conversa do momento; vazia sem conversa escrita. ${DIALOGUE_DESCRIPTION}`,
    type: 'array',
    items: { type: 'object', additionalProperties: true },
  })
  dialogue: DialogueStep[];

  @ApiProperty({
    description: 'No `offer`, a cena no lugar da conversa de início.',
    type: String,
    nullable: true,
  })
  offer_scene: string | null;

  @ApiProperty({
    description: 'No `done`, a próxima missão da fila, para oferecer.',
    type: () => QuestOfferDto,
    nullable: true,
  })
  next: QuestOfferDto | null;

  @ApiProperty({
    description:
      'As falas automáticas, depois da conversa: o progresso ou a entrega.',
    type: [String],
    example: ['Missão cumprida: Capture 3 Ecobeasts!'],
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
