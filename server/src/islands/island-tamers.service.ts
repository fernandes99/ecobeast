import { ConflictException, Injectable } from '@nestjs/common';
import { arenaOpen } from '../domain/islands/archipelago.js';
import type { TamerCreature } from '../domain/tamers/tamers.js';
import type { Prisma } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import {
  IslandCompletionService,
  type UnlockedIsland,
} from './island-completion.service.js';

export type { UnlockedIsland } from './island-completion.service.js';

export const NO_ISLAND_TAMER = 'Nenhum Domador aqui.';
export const ARENA_LOCKED = 'Essa Arena ainda está trancada.';

export interface IslandTamer {
  id: number;
  islandId: number;
  name: string;
  size: number;
  team: TamerCreature[];
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
    private readonly completion: IslandCompletionService,
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
    const placed = await this.completion.placedNpcs(islandId);
    if (!this.completion.isPlaced(placed, npcId)) return null;
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
    const unlocked = await this.completion.unlockedBy(userId, tamer.islandId, {
      tamerId: tamer.id,
      arenaId: bossOf?.id,
    });
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
}

function wonArena(arenas: ArenaRow[], arena: ArenaRow): WonArena {
  const next = arenas.find(({ position }) => position > arena.position);
  return {
    id: arena.id,
    name: arena.name,
    nextInteriorId: next?.interiorId ?? null,
  };
}
