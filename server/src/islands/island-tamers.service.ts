import { ConflictException, Injectable } from '@nestjs/common';
import {
  arenaOpen,
  islandComplete,
  nextIslandAfter,
} from '../domain/islands/archipelago.js';
import type { TamerCreature } from '../domain/tamers/tamers.js';
import type { Prisma } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { ArchipelagoService } from './archipelago.service.js';

export const NO_ISLAND_TAMER = 'Nenhum Domador aqui.';
export const ARENA_LOCKED = 'Essa Arena ainda está trancada.';

const PUBLISHED = 'published';

export interface IslandTamer {
  id: number;
  islandId: number;
  name: string;
  size: number;
  team: TamerCreature[];
}

export interface UnlockedIsland {
  id: number;
  name: string;
}

export interface WonArena {
  id: number;
  name: string;
  /** A sala da Arena seguinte da ilha, que abre com esta vitória. */
  nextInteriorId: number | null;
}

/** O que a vitória contra um Domador da ilha grava, para a transação do fim da luta. */
export interface IslandTamerVictory {
  kind: 'first' | 'rematch' | 'arena';
  unlocked: UnlockedIsland | null;
  arena: WonArena | null;
  writes: Prisma.PrismaPromise<unknown>[];
}

interface ArenaRow {
  id: number;
  position: number;
  name: string;
  interiorId: number;
  bossTamerId: number;
}

/** Os Domadores fixos das ilhas do Arquipélago (auralis/04) e as Arenas (05). */
@Injectable()
export class IslandTamersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly archipelago: ArchipelagoService,
  ) {}

  /**
   * O Domador do NPC, se ele é desta ilha e está posto nela, no mapa publicado
   * ou numa sala dele. Na sala de uma Arena trancada, a luta é recusada.
   */
  async find(
    userId: string,
    islandId: number,
    npcId: number,
  ): Promise<IslandTamer | null> {
    const tamer = await this.prisma.tamer.findUnique({
      where: { npcId },
      select: {
        id: true,
        islandId: true,
        size: true,
        npc: { select: { name: true } },
        creatures: {
          orderBy: { position: 'asc' },
          select: { speciesId: true, level: true },
        },
      },
    });
    if (!tamer || tamer.islandId !== islandId || tamer.creatures.length === 0) {
      return null;
    }
    const placed = await this.placedNpcs(islandId);
    if (!placed.outside.has(npcId) && !placed.inside.has(npcId)) return null;
    const rooms = placed.inside.get(npcId) ?? new Set<number>();
    if (rooms.size > 0) {
      const [arenas, won] = await Promise.all([
        this.arenas(islandId),
        this.wonArenaIds(userId),
      ]);
      const locked = arenas.some(
        (arena) =>
          rooms.has(arena.interiorId) && !arenaOpen(arenas, won, arena.id),
      );
      if (locked) throw new ConflictException(ARENA_LOCKED);
    }
    return {
      id: tamer.id,
      islandId,
      name: tamer.npc.name,
      size: tamer.size,
      team: tamer.creatures,
    };
  }

  /** Os NPCs que são Domadores da ilha, de fora e de dentro das salas. */
  async npcIds(islandId: number): Promise<Set<number>> {
    const tamers = await this.prisma.tamer.findMany({
      where: { islandId },
      select: { npcId: true },
    });
    return new Set(tamers.map(({ npcId }) => npcId));
  }

  /** As salas das Arenas que o Domador ainda não pode abrir. */
  async lockedInteriorIds(userId: string, islandId: number): Promise<number[]> {
    const [arenas, won] = await Promise.all([
      this.arenas(islandId),
      this.wonArenaIds(userId),
    ]);
    const open = new Set(
      arenas
        .filter((arena) => arenaOpen(arenas, won, arena.id))
        .map(({ interiorId }) => interiorId),
    );
    return [
      ...new Set(
        arenas
          .map(({ interiorId }) => interiorId)
          .filter((interiorId) => !open.has(interiorId)),
      ),
    ];
  }

  async victory(
    userId: string,
    tamer: Pick<IslandTamer, 'id' | 'islandId'>,
  ): Promise<IslandTamerVictory> {
    const [before, arenas] = await Promise.all([
      this.prisma.playerTamerWin.findUnique({
        where: { playerId_tamerId: { playerId: userId, tamerId: tamer.id } },
        select: { wins: true },
      }),
      this.arenas(tamer.islandId),
    ]);
    const writes: Prisma.PrismaPromise<unknown>[] = [
      this.prisma.playerTamerWin.upsert({
        where: { playerId_tamerId: { playerId: userId, tamerId: tamer.id } },
        create: { playerId: userId, tamerId: tamer.id },
        update: { wins: { increment: 1 } },
      }),
    ];
    if (before) {
      return { kind: 'rematch', unlocked: null, arena: null, writes };
    }
    const bossOf = arenas.find(({ bossTamerId }) => bossTamerId === tamer.id);
    if (bossOf) {
      writes.push(
        this.prisma.playerArena.upsert({
          where: {
            playerId_arenaId: { playerId: userId, arenaId: bossOf.id },
          },
          create: { playerId: userId, arenaId: bossOf.id },
          update: {},
        }),
      );
    }
    const unlocked = await this.unlockedBy(userId, tamer, arenas, bossOf);
    if (unlocked) {
      writes.push(
        this.prisma.playerIsland.create({
          data: { playerId: userId, islandId: unlocked.id },
        }),
      );
    }
    return {
      kind: bossOf ? 'arena' : 'first',
      unlocked,
      arena: bossOf ? wonArena(arenas, bossOf) : null,
      writes,
    };
  }

  /** A ilha que esta vitória abre, se ela completa a ilha do Domador. */
  private async unlockedBy(
    userId: string,
    tamer: Pick<IslandTamer, 'id' | 'islandId'>,
    arenas: ArenaRow[],
    bossOf: ArenaRow | undefined,
  ): Promise<UnlockedIsland | null> {
    const [island, counting, placed, won, wonArenas, islands, open] =
      await Promise.all([
        this.prisma.island.findUnique({
          where: { id: tamer.islandId },
          select: { requiredTamerWins: true },
        }),
        this.prisma.tamer.findMany({
          where: { islandId: tamer.islandId, countsForUnlock: true },
          select: { id: true, npcId: true },
        }),
        this.placedNpcs(tamer.islandId),
        this.prisma.playerTamerWin.findMany({
          where: { playerId: userId },
          select: { tamerId: true },
        }),
        this.wonArenaIds(userId),
        this.archipelago.publishedIslands(),
        this.prisma.playerIsland.findMany({
          where: { playerId: userId },
          select: { islandId: true },
        }),
      ]);
    const bosses = new Set(arenas.map(({ bossTamerId }) => bossTamerId));
    const countingTamerIds = counting
      .filter(
        ({ id, npcId }) =>
          !bosses.has(id) &&
          (placed.outside.has(npcId) || placed.inside.has(npcId)),
      )
      .map(({ id }) => id);
    const complete = islandComplete({
      countingTamerIds,
      wonTamerIds: new Set([...won.map(({ tamerId }) => tamerId), tamer.id]),
      requiredTamerWins: island?.requiredTamerWins ?? null,
      arenaIds: arenas.map(({ id }) => id),
      wonArenaIds: bossOf ? new Set([...wonArenas, bossOf.id]) : wonArenas,
    });
    if (!complete) return null;
    const nextId = nextIslandAfter(islands, tamer.islandId);
    if (nextId === null) return null;
    if (open.some(({ islandId }) => islandId === nextId)) return null;
    const name = islands.find(({ id }) => id === nextId)?.name ?? '';
    return { id: nextId, name };
  }

  private arenas(islandId: number): Promise<ArenaRow[]> {
    return this.prisma.arena.findMany({
      where: { islandId },
      orderBy: { position: 'asc' },
      select: {
        id: true,
        position: true,
        name: true,
        interiorId: true,
        bossTamerId: true,
      },
    });
  }

  private async wonArenaIds(userId: string): Promise<Set<number>> {
    const rows = await this.prisma.playerArena.findMany({
      where: { playerId: userId },
      select: { arenaId: true },
    });
    return new Set(rows.map(({ arenaId }) => arenaId));
  }

  /**
   * Os NPCs postos na ilha: os do mapa publicado e, para cada NPC de uma sala
   * que uma peça do mapa publicado abre, as salas onde ele está.
   */
  private async placedNpcs(islandId: number): Promise<{
    outside: Set<number>;
    inside: Map<number, Set<number>>;
  }> {
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
}

function wonArena(arenas: ArenaRow[], arena: ArenaRow): WonArena {
  const next = arenas.find(({ position }) => position > arena.position);
  return {
    id: arena.id,
    name: arena.name,
    nextInteriorId: next?.interiorId ?? null,
  };
}
