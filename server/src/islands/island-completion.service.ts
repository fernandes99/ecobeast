import { Injectable } from '@nestjs/common';
import {
  islandComplete,
  nextIslandAfter,
} from '../domain/islands/archipelago.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { ArchipelagoService } from './archipelago.service.js';

const PUBLISHED = 'published';

export interface UnlockedIsland {
  id: number;
  name: string;
}

export interface PlacedNpcs {
  outside: Set<number>;
  /** Para cada NPC de uma sala que uma peça do mapa publicado abre, as salas dele. */
  inside: Map<number, Set<number>>;
}

/** O que acabou de acontecer e ainda não está gravado. */
export interface JustDone {
  tamerId?: number;
  arenaId?: number;
  questId?: number;
}

function withExtra(ids: number[], extra: number | undefined): Set<number> {
  return new Set(extra === undefined ? ids : [...ids, extra]);
}

/** A ilha completa (auralis/04 a 06): os Domadores, as Arenas e as missões. */
@Injectable()
export class IslandCompletionService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly archipelago: ArchipelagoService,
  ) {}

  isPlaced(placed: PlacedNpcs, npcId: number): boolean {
    return placed.outside.has(npcId) || placed.inside.has(npcId);
  }

  async placedNpcs(islandId: number): Promise<PlacedNpcs> {
    const where = { islandMap: { islandId, kind: PUBLISHED } };
    const [npcs, props] = await Promise.all([
      this.prisma.islandNpc.findMany({ where, select: { npcId: true } }),
      this.prisma.islandProp.findMany({
        where: { ...where, interiorId: { not: null } },
        select: { interiorId: true },
      }),
    ]);
    const roomIds = [...new Set(props.map(({ interiorId }) => interiorId!))];
    const roomNpcs =
      roomIds.length === 0
        ? []
        : await this.prisma.interiorNpc.findMany({
            where: { interiorId: { in: roomIds } },
            select: { npcId: true, interiorId: true },
          });
    const inside = new Map<number, Set<number>>();
    for (const { npcId, interiorId } of roomNpcs) {
      const rooms = inside.get(npcId) ?? new Set<number>();
      rooms.add(interiorId);
      inside.set(npcId, rooms);
    }
    return { outside: new Set(npcs.map(({ npcId }) => npcId)), inside };
  }

  /** A ilha que abre se o `just` completa esta; nula se não completa ou se ela já está aberta. */
  async unlockedBy(
    userId: string,
    islandId: number,
    just: JustDone,
  ): Promise<UnlockedIsland | null> {
    const [
      island,
      counting,
      arenas,
      quests,
      placed,
      won,
      wonArenas,
      claimed,
      islands,
      open,
    ] = await Promise.all([
      this.prisma.island.findUnique({
        where: { id: islandId },
        select: { requiredTamerWins: true, requiredQuests: true },
      }),
      this.prisma.tamer.findMany({
        where: { islandId, countsForUnlock: true },
        select: { id: true, npcId: true },
      }),
      this.prisma.arena.findMany({
        where: { islandId },
        select: { id: true, bossTamerId: true },
      }),
      this.prisma.quest.findMany({
        where: { islandId, countsForUnlock: true },
        select: { id: true, npcId: true },
      }),
      this.placedNpcs(islandId),
      this.prisma.playerTamerWin.findMany({
        where: { playerId: userId },
        select: { tamerId: true },
      }),
      this.prisma.playerArena.findMany({
        where: { playerId: userId },
        select: { arenaId: true },
      }),
      this.prisma.playerQuest.findMany({
        where: { playerId: userId, claimedAt: { not: null } },
        select: { questId: true },
      }),
      this.archipelago.publishedIslands(),
      this.prisma.playerIsland.findMany({
        where: { playerId: userId },
        select: { islandId: true },
      }),
    ]);
    const bosses = new Set(arenas.map(({ bossTamerId }) => bossTamerId));
    const complete = islandComplete({
      countingTamerIds: counting
        .filter(
          ({ id, npcId }) => !bosses.has(id) && this.isPlaced(placed, npcId),
        )
        .map(({ id }) => id),
      wonTamerIds: withExtra(
        won.map(({ tamerId }) => tamerId),
        just.tamerId,
      ),
      requiredTamerWins: island?.requiredTamerWins ?? null,
      arenaIds: arenas.map(({ id }) => id),
      wonArenaIds: withExtra(
        wonArenas.map(({ arenaId }) => arenaId),
        just.arenaId,
      ),
      questIds: quests
        .filter(({ npcId }) => this.isPlaced(placed, npcId))
        .map(({ id }) => id),
      claimedQuestIds: withExtra(
        claimed.map(({ questId }) => questId),
        just.questId,
      ),
      requiredQuests: island?.requiredQuests ?? null,
    });
    if (!complete) return null;
    const nextId = nextIslandAfter(islands, islandId);
    if (nextId === null) return null;
    if (open.some((row) => row.islandId === nextId)) return null;
    const name = islands.find(({ id }) => id === nextId)?.name ?? '';
    return { id: nextId, name };
  }
}
