import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import type { HexCoord } from '../domain/exploration/hex.js';
import {
  dialoguesFromRows,
  type DialogueStage,
  type DialogueStep,
} from '../domain/quests/quest-dialogue.js';
import {
  acceptedLine,
  type BattleQuestEvents,
  battleQuestDeltas,
  claimedLine,
  explorePercent,
  progressLine,
  QUEST_TYPES,
  questTarget,
  questTitle,
} from '../domain/quests/quests.js';
import { ExplorationStore } from '../exploration/exploration.store.js';
import type { Prisma } from '../generated/prisma/client.js';
import {
  IslandCompletionService,
  type UnlockedIsland,
} from '../islands/island-completion.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import type { TamerProgressDto } from '../tamer-level/tamer-level.dto.js';
import { TamerLevelService } from '../tamer-level/tamer-level.service.js';
import { itemQuestWrite } from './item-quests.js';

export const NOT_ON_ISLAND = 'Missões só numa ilha.';
export const NPC_NOT_HERE = 'Esse NPC não está nesta ilha.';
export const NO_EXPLORATION = 'Essa exploração acabou. Saia e entre de novo.';
export const UNREACHABLE = 'Você não chegou até aí.';
export const QUEST_NOT_FOUND = 'Missão não encontrada.';
export const QUEST_NOT_NEXT = 'Essa missão não é a da vez.';

const PUBLISHED = 'published';

export interface QuestPlace {
  questId: number;
  name: string;
  tiles: HexCoord[];
}

export interface QuestReward {
  coins: number;
  itemId: number | null;
  itemQuantity: number | null;
  xp: number;
}

/** Em que ponto está a primeira missão não entregue do NPC (auralis/10). */
export type TalkStage = 'none' | DialogueStage;

/** A oferta de uma missão: a conversa de início ou a cena. */
export interface QuestOffer {
  questId: number;
  dialogue: DialogueStep[];
  offerScene: string | null;
}

export interface TalkResult {
  stage: TalkStage;
  questId: number | null;
  /** A conversa do momento; vazia sem conversa escrita. */
  dialogue: DialogueStep[];
  offerScene: string | null;
  /** Depois da entrega, a próxima da fila, ainda não aceita. */
  next: QuestOffer | null;
  lines: string[];
  reward: QuestReward | null;
  tamerProgress: TamerProgressDto | null;
  islandUnlocked: UnlockedIsland | null;
  questPlaces: QuestPlace[];
}

export interface AcceptResult {
  lines: string[];
  questPlaces: QuestPlace[];
}

export interface ReachResult {
  reached: string[];
  questPlaces: QuestPlace[];
}

const QUEST_SELECT = {
  id: true,
  islandId: true,
  questTypeId: true,
  amount: true,
  placeName: true,
  title: true,
  coins: true,
  itemId: true,
  itemQuantity: true,
  species: { select: { name: true } },
  targetNpc: { select: { name: true } },
  targetItem: { select: { name: true } },
  offerScene: true,
  dialogue: { include: { options: true } },
} as const;

type QuestRow = Prisma.QuestGetPayload<{ select: typeof QUEST_SELECT }>;

const BATTLE_TYPES = [
  QUEST_TYPES.capture_any,
  QUEST_TYPES.defeat_any,
  QUEST_TYPES.find_species,
  QUEST_TYPES.defeat_species,
  QUEST_TYPES.defeat_tamer,
];

/** As missões das ilhas (auralis/06). */
@Injectable()
export class QuestsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly explorations: ExplorationStore,
    private readonly tamerLevel: TamerLevelService,
    private readonly completion: IslandCompletionService,
  ) {}

  /** Os lugares das missões "Vá até" aceitas e não alcançadas da ilha. */
  async places(userId: string, islandId: number): Promise<QuestPlace[]> {
    const rows = await this.prisma.playerQuest.findMany({
      where: {
        playerId: userId,
        claimedAt: null,
        progress: 0,
        quest: { islandId, questTypeId: QUEST_TYPES.reach_place },
      },
      orderBy: { questId: 'asc' },
      select: {
        quest: {
          select: {
            id: true,
            placeName: true,
            tiles: { select: { q: true, r: true } },
          },
        },
      },
    });
    return rows.map(({ quest }) => ({
      questId: quest.id,
      name: quest.placeName ?? '',
      tiles: quest.tiles,
    }));
  }

  /** As escritas do progresso da luta, para a transação do fim dela. */
  async battleWrites(
    userId: string,
    events: BattleQuestEvents,
  ): Promise<Prisma.PrismaPromise<unknown>[]> {
    const rows = await this.prisma.playerQuest.findMany({
      where: {
        playerId: userId,
        claimedAt: null,
        quest: { questTypeId: { in: BATTLE_TYPES } },
      },
      select: {
        quest: {
          select: {
            id: true,
            questTypeId: true,
            amount: true,
            speciesId: true,
            placeName: true,
            title: true,
            targetNpc: { select: { tamer: { select: { id: true } } } },
          },
        },
      },
    });
    const quests = new Map(rows.map(({ quest }) => [quest.id, quest]));
    const deltas = battleQuestDeltas(
      events,
      rows.map(({ quest }) => ({
        questId: quest.id,
        questTypeId: quest.questTypeId,
        speciesId: quest.speciesId,
        targetTamerId: quest.targetNpc?.tamer?.id ?? null,
      })),
    );
    return deltas.map(({ questId, amount }) =>
      this.addProgress(
        userId,
        questId,
        amount,
        questTarget(quests.get(questId)!),
      ),
    );
  }

  /** Os segundos do sinal de cada minuto nas missões "Fique" da ilha. */
  stayWrite(
    client: Pick<Prisma.TransactionClient, '$executeRaw'>,
    userId: string,
    islandId: number,
    seconds: number,
  ): Prisma.PrismaPromise<number> {
    return client.$executeRaw`
      UPDATE "ecobeasts"."player_quests" pq
      SET "progress" = LEAST(pq."progress" + ${seconds}, q."amount" * 60)
      FROM "ecobeasts"."quests" q
      WHERE pq."quest_id" = q."id"
        AND pq."player_id" = ${userId}::uuid
        AND pq."claimed_at" IS NULL
        AND q."quest_type_id" = ${QUEST_TYPES.stay_minutes}
        AND q."island_id" = ${islandId}`;
  }

  /**
   * A conversa com o NPC: cumpre as "Fale com" ele e, se ele dá missões nesta
   * ilha, oferece (sem aceitar), entrega ou mostra o progresso da primeira não
   * entregue, com a conversa escrita daquele momento (auralis/10).
   */
  async talk(userId: string, npcId: number): Promise<TalkResult> {
    const islandId = this.explorations.get(userId)?.islandId;
    if (islandId === undefined) throw new ConflictException(NOT_ON_ISLAND);
    const placed = await this.completion.placedNpcs(islandId);
    if (!this.completion.isPlaced(placed, npcId)) {
      throw new ConflictException(NPC_NOT_HERE);
    }
    await this.prisma.$executeRaw`
      UPDATE "ecobeasts"."player_quests" pq
      SET "progress" = 1
      FROM "ecobeasts"."quests" q
      WHERE pq."quest_id" = q."id"
        AND pq."player_id" = ${userId}::uuid
        AND pq."claimed_at" IS NULL
        AND q."quest_type_id" = ${QUEST_TYPES.talk_npc}
        AND q."target_npc_id" = ${npcId}`;

    const [queue, islandName] = await Promise.all([
      this.prisma.quest.findMany({
        where: { islandId, npcId },
        orderBy: { position: 'asc' },
        select: {
          ...QUEST_SELECT,
          players: {
            where: { playerId: userId },
            select: { progress: true, claimedAt: true },
          },
        },
      }),
      this.islandName(islandId),
    ]);
    const result: TalkResult = {
      stage: 'none',
      questId: null,
      dialogue: [],
      offerScene: null,
      next: null,
      lines: [],
      reward: null,
      tamerProgress: null,
      islandUnlocked: null,
      questPlaces: [],
    };
    const index = queue.findIndex(({ players }) => !players[0]?.claimedAt);
    const quest = queue[index];
    if (quest) {
      const title = questTitle(quest, namesOf(quest, islandName));
      const row = quest.players[0];
      result.questId = quest.id;
      if (!row) {
        Object.assign(result, offerOf(quest));
        result.stage = 'offer';
      } else {
        const progress = await this.progressOf(userId, quest, row.progress);
        if (progress >= questTarget(quest)) {
          const next = queue[index + 1];
          Object.assign(result, await this.claim(userId, quest));
          result.stage = 'done';
          result.dialogue = dialogueOf(quest, 'done');
          result.lines.push(claimedLine(title));
          result.next = next ? offerOf(next) : null;
        } else {
          result.stage = 'ongoing';
          result.dialogue = dialogueOf(quest, 'ongoing');
          result.lines.push(progressLine(quest, title, progress));
        }
      }
    }
    result.questPlaces = await this.places(userId, islandId);
    return result;
  }

  /**
   * Aceita a missão, se ela é a primeira não entregue do NPC dela nesta ilha,
   * com o NPC posto; uma já aceita responde sem falas (auralis/10).
   */
  async acceptQuest(userId: string, questId: number): Promise<AcceptResult> {
    const islandId = this.explorations.get(userId)?.islandId;
    if (islandId === undefined) throw new ConflictException(NOT_ON_ISLAND);
    const quest = await this.prisma.quest.findUnique({
      where: { id: questId },
      select: { ...QUEST_SELECT, npcId: true },
    });
    if (!quest || quest.islandId !== islandId) {
      throw new NotFoundException(QUEST_NOT_FOUND);
    }
    const placed = await this.completion.placedNpcs(islandId);
    if (!this.completion.isPlaced(placed, quest.npcId)) {
      throw new ConflictException(NPC_NOT_HERE);
    }
    const first = await this.prisma.quest.findFirst({
      where: {
        islandId,
        npcId: quest.npcId,
        players: { none: { playerId: userId, claimedAt: { not: null } } },
      },
      orderBy: { position: 'asc' },
      select: {
        id: true,
        players: { where: { playerId: userId }, select: { questId: true } },
      },
    });
    if (first?.id !== questId) throw new ConflictException(QUEST_NOT_NEXT);
    const lines: string[] = [];
    if (first.players.length === 0) {
      await this.accept(userId, questId);
      const title = questTitle(
        quest,
        namesOf(quest, await this.islandName(islandId)),
      );
      lines.push(acceptedLine(title));
    }
    return { lines, questPlaces: await this.places(userId, islandId) };
  }

  /** O Domador pisou em (q, r): cumpre as "Vá até" da ilha com esse hexágono. */
  async reach(userId: string, position: HexCoord): Promise<ReachResult> {
    const exploration = this.explorations.get(userId);
    if (!exploration) throw new NotFoundException(NO_EXPLORATION);
    const islandId = exploration.islandId;
    if (islandId === undefined) throw new ConflictException(NOT_ON_ISLAND);
    const confirmed = this.explorations.confirmPosition(userId, position);
    if (confirmed === 'none') throw new NotFoundException(NO_EXPLORATION);
    if (confirmed === 'unreachable') throw new ConflictException(UNREACHABLE);

    const rows = await this.prisma.playerQuest.findMany({
      where: {
        playerId: userId,
        claimedAt: null,
        progress: 0,
        quest: {
          islandId,
          questTypeId: QUEST_TYPES.reach_place,
          tiles: { some: { q: position.q, r: position.r } },
        },
      },
      select: { questId: true, quest: { select: { placeName: true } } },
    });
    if (rows.length > 0) {
      await this.prisma.playerQuest.updateMany({
        where: {
          playerId: userId,
          questId: { in: rows.map(({ questId }) => questId) },
          claimedAt: null,
        },
        data: { progress: 1 },
      });
    }
    return {
      reached: [...new Set(rows.map(({ quest }) => quest.placeName ?? ''))],
      questPlaces: await this.places(userId, islandId),
    };
  }

  private accept(userId: string, questId: number) {
    return this.prisma.playerQuest.upsert({
      where: { playerId_questId: { playerId: userId, questId } },
      create: { playerId: userId, questId },
      update: {},
    });
  }

  /** O progresso de agora; no "Explore", o descoberto da ilha, gravado junto. */
  private async progressOf(
    userId: string,
    quest: QuestRow,
    stored: number,
  ): Promise<number> {
    if (quest.questTypeId !== QUEST_TYPES.explore_percent) return stored;
    const where = { islandMap: { islandId: quest.islandId, kind: PUBLISHED } };
    const [tiles, discovered] = await Promise.all([
      this.prisma.islandTile.findMany({ where, select: { q: true, r: true } }),
      this.prisma.islandDiscovery.findMany({
        where: { playerId: userId, islandId: quest.islandId },
        select: { q: true, r: true },
      }),
    ]);
    const existing = new Set(tiles.map(({ q, r }) => `${q},${r}`));
    const found = discovered.filter(({ q, r }) => existing.has(`${q},${r}`));
    const progress = Math.min(
      questTarget(quest),
      explorePercent(found.length, tiles.length),
    );
    if (progress !== stored) {
      await this.prisma.playerQuest.updateMany({
        where: { playerId: userId, questId: quest.id, claimedAt: null },
        data: { progress },
      });
    }
    return progress;
  }

  /** A entrega: moedas, item e XP numa transação; a seguinte fica para oferecer. */
  private async claim(
    userId: string,
    quest: QuestRow,
  ): Promise<Pick<TalkResult, 'reward' | 'tamerProgress' | 'islandUnlocked'>> {
    const [unlocked, { levels, sources }] = await Promise.all([
      this.completion.unlockedBy(userId, quest.islandId, {
        questId: quest.id,
      }),
      this.tamerLevel.catalog(),
    ]);
    const xp =
      (sources.get('quest') ?? 0) +
      (unlocked ? (sources.get('island_unlocked') ?? 0) : 0);
    const award = await this.tamerLevel.award(userId, xp, levels);
    const { itemId, itemQuantity, coins } = quest;
    await this.prisma.$transaction([
      // Sem a linha não entregue, o `update` falha e nada se paga duas vezes.
      this.prisma.playerQuest.update({
        where: {
          playerId_questId: { playerId: userId, questId: quest.id },
          claimedAt: null,
        },
        data: { claimedAt: new Date() },
      }),
      ...(coins > 0
        ? [
            this.prisma.player.update({
              where: { id: userId },
              data: { coins: { increment: coins } },
            }),
          ]
        : []),
      ...(itemId !== null && itemQuantity !== null
        ? [
            this.prisma.inventoryItem.upsert({
              where: { playerId_itemId: { playerId: userId, itemId } },
              create: { playerId: userId, itemId, quantity: itemQuantity },
              update: { quantity: { increment: itemQuantity } },
            }),
            itemQuestWrite(this.prisma, userId, itemId, itemQuantity),
          ]
        : []),
      ...award.writes,
      ...(unlocked
        ? [
            this.prisma.playerIsland.create({
              data: { playerId: userId, islandId: unlocked.id },
            }),
          ]
        : []),
    ]);
    return {
      reward: { coins, itemId, itemQuantity, xp },
      tamerProgress: award.progress,
      islandUnlocked: unlocked,
    };
  }

  private addProgress(
    userId: string,
    questId: number,
    amount: number,
    target: number,
  ): Prisma.PrismaPromise<number> {
    return this.prisma.$executeRaw`
      UPDATE "ecobeasts"."player_quests"
      SET "progress" = LEAST("progress" + ${amount}, ${target})
      WHERE "player_id" = ${userId}::uuid
        AND "quest_id" = ${questId}
        AND "claimed_at" IS NULL`;
  }

  private async islandName(islandId: number): Promise<string> {
    const map = await this.prisma.islandMap.findUnique({
      where: { islandId_kind: { islandId, kind: PUBLISHED } },
      select: { name: true },
    });
    return map?.name ?? '';
  }
}

function dialogueOf(quest: QuestRow, stage: DialogueStage): DialogueStep[] {
  return dialoguesFromRows(
    quest.dialogue,
    quest.dialogue.flatMap(({ options }) => options),
  )[stage];
}

function offerOf(quest: QuestRow): QuestOffer {
  return {
    questId: quest.id,
    dialogue: dialogueOf(quest, 'offer'),
    offerScene: quest.offerScene,
  };
}

function namesOf(quest: QuestRow, island: string) {
  return {
    island,
    species: quest.species?.name ?? null,
    targetNpc: quest.targetNpc?.name ?? null,
    targetItem: quest.targetItem?.name ?? null,
  };
}
