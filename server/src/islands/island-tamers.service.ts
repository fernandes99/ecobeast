import { Injectable } from '@nestjs/common';
import {
  nextIslandAfter,
  tamersComplete,
} from '../domain/islands/archipelago.js';
import type { TamerCreature } from '../domain/tamers/tamers.js';
import type { Prisma } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { ArchipelagoService } from './archipelago.service.js';

export const NO_ISLAND_TAMER = 'Nenhum Domador aqui.';

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

/** O que a vitória contra um Domador da ilha grava, para a transação do fim da luta. */
export interface IslandTamerVictory {
  kind: 'first' | 'rematch';
  unlocked: UnlockedIsland | null;
  writes: Prisma.PrismaPromise<unknown>[];
}

/** Os Domadores fixos das ilhas do Arquipélago (auralis/04). */
@Injectable()
export class IslandTamersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly archipelago: ArchipelagoService,
  ) {}

  /** O Domador do NPC, se ele é desta ilha e está na versão publicada dela. */
  async find(islandId: number, npcId: number): Promise<IslandTamer | null> {
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
    if (!(await this.placedNpcIds(islandId)).has(npcId)) return null;
    return {
      id: tamer.id,
      islandId,
      name: tamer.npc.name,
      size: tamer.size,
      team: tamer.creatures,
    };
  }

  /** Os NPCs da ilha que são Domadores dela, para a exploração marcar. */
  async npcIds(islandId: number): Promise<Set<number>> {
    const tamers = await this.prisma.tamer.findMany({
      where: { islandId },
      select: { npcId: true },
    });
    return new Set(tamers.map(({ npcId }) => npcId));
  }

  async victory(
    userId: string,
    tamer: Pick<IslandTamer, 'id' | 'islandId'>,
  ): Promise<IslandTamerVictory> {
    const before = await this.prisma.playerTamerWin.findUnique({
      where: { playerId_tamerId: { playerId: userId, tamerId: tamer.id } },
      select: { wins: true },
    });
    const write = this.prisma.playerTamerWin.upsert({
      where: { playerId_tamerId: { playerId: userId, tamerId: tamer.id } },
      create: { playerId: userId, tamerId: tamer.id },
      update: { wins: { increment: 1 } },
    });
    if (before) return { kind: 'rematch', unlocked: null, writes: [write] };
    const unlocked = await this.unlockedBy(userId, tamer);
    return {
      kind: 'first',
      unlocked,
      writes: unlocked
        ? [
            write,
            this.prisma.playerIsland.create({
              data: { playerId: userId, islandId: unlocked.id },
            }),
          ]
        : [write],
    };
  }

  /** A ilha que esta vitória abre, se ela completa a ilha do Domador. */
  private async unlockedBy(
    userId: string,
    tamer: Pick<IslandTamer, 'id' | 'islandId'>,
  ): Promise<UnlockedIsland | null> {
    const [island, counting, placed, won, islands, open] = await Promise.all([
      this.prisma.island.findUnique({
        where: { id: tamer.islandId },
        select: { requiredTamerWins: true },
      }),
      this.prisma.tamer.findMany({
        where: { islandId: tamer.islandId, countsForUnlock: true },
        select: { id: true, npcId: true },
      }),
      this.placedNpcIds(tamer.islandId),
      this.prisma.playerTamerWin.findMany({
        where: { playerId: userId },
        select: { tamerId: true },
      }),
      this.archipelago.publishedIslands(),
      this.prisma.playerIsland.findMany({
        where: { playerId: userId },
        select: { islandId: true },
      }),
    ]);
    const countingIds = counting
      .filter(({ npcId }) => placed.has(npcId))
      .map(({ id }) => id);
    const wonIds = new Set([...won.map(({ tamerId }) => tamerId), tamer.id]);
    if (
      !tamersComplete(countingIds, wonIds, island?.requiredTamerWins ?? null)
    ) {
      return null;
    }
    const nextId = nextIslandAfter(islands, tamer.islandId);
    if (nextId === null) return null;
    if (open.some(({ islandId }) => islandId === nextId)) return null;
    const name = islands.find(({ id }) => id === nextId)?.name ?? '';
    return { id: nextId, name };
  }

  private async placedNpcIds(islandId: number): Promise<Set<number>> {
    const npcs = await this.prisma.islandNpc.findMany({
      where: { islandMap: { islandId, kind: PUBLISHED } },
      select: { npcId: true },
    });
    return new Set(npcs.map(({ npcId }) => npcId));
  }
}
