import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { Env } from '../config/env.js';
import {
  type ArchipelagoEntry,
  type ArchipelagoIsland,
  archipelagoStates,
} from '../domain/islands/archipelago.js';
import { PrismaService } from '../prisma/prisma.service.js';
import type { ArchipelagoIslandDto } from './archipelago.dto.js';
import { ISLAND_NOT_FOUND } from './islands.service.js';

export const ISLAND_LOCKED = 'Essa ilha ainda está trancada.';
export const ARCHIPELAGO_NO_PLAYER = 'Crie seu Domador primeiro.';

const PUBLISHED = 'published';

interface NamedEntry extends ArchipelagoEntry {
  name: string;
}

@Injectable()
export class ArchipelagoService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService<Env, true>,
  ) {}

  async list(userId: string): Promise<ArchipelagoIslandDto[]> {
    await this.requirePlayer(userId);
    return (await this.entries(userId)).map(({ id, order, state, name }) =>
      state === 'hidden'
        ? { id: null, order, state, name: null }
        : { id, order, state, name },
    );
  }

  /** As ilhas do Arquipélago que o jogador ainda não abriu. */
  async lockedIds(userId: string): Promise<Set<number>> {
    const entries = await this.entries(userId);
    return new Set(
      entries.filter((entry) => entry.state !== 'open').map(({ id }) => id),
    );
  }

  async assertOpen(userId: string, islandId: number): Promise<void> {
    if ((await this.lockedIds(userId)).has(islandId)) {
      throw new ForbiddenException(ISLAND_LOCKED);
    }
  }

  async unlock(userId: string, islandId: number): Promise<void> {
    await this.requireDebugIsland(userId, islandId);
    await this.prisma.playerIsland.upsert({
      where: { playerId_islandId: { playerId: userId, islandId } },
      create: { playerId: userId, islandId },
      update: {},
    });
  }

  async relock(userId: string, islandId: number): Promise<void> {
    await this.requireDebugIsland(userId, islandId);
    await this.prisma.playerIsland.deleteMany({
      where: { playerId: userId, islandId },
    });
  }

  /** As ilhas publicadas do Arquipélago, com a ordem e o nome, sem o estado. */
  async publishedIslands(): Promise<(ArchipelagoIsland & { name: string })[]> {
    const islands = await this.prisma.island.findMany({
      where: {
        archipelagoOrder: { not: null },
        maps: { some: { kind: PUBLISHED } },
      },
      select: {
        id: true,
        archipelagoOrder: true,
        maps: { where: { kind: PUBLISHED }, select: { name: true } },
      },
    });
    return islands.map(({ id, archipelagoOrder, maps }) => ({
      id,
      order: archipelagoOrder ?? 0,
      name: maps[0]?.name ?? '',
    }));
  }

  private async entries(userId: string): Promise<NamedEntry[]> {
    const [islands, unlocked] = await Promise.all([
      this.publishedIslands(),
      this.prisma.playerIsland.findMany({
        where: { playerId: userId },
        select: { islandId: true },
      }),
    ]);
    const names = new Map(islands.map(({ id, name }) => [id, name]));
    return archipelagoStates(
      islands,
      new Set(unlocked.map(({ islandId }) => islandId)),
    ).map((entry) => ({ ...entry, name: names.get(entry.id) ?? '' }));
  }

  private async requirePlayer(userId: string): Promise<void> {
    const player = await this.prisma.player.findUnique({
      where: { id: userId },
      select: { id: true },
    });
    if (!player) throw new ConflictException(ARCHIPELAGO_NO_PLAYER);
  }

  private async requireDebugIsland(
    userId: string,
    islandId: number,
  ): Promise<void> {
    if (!this.config.get('ENABLE_TEST_BATTLE', { infer: true })) {
      throw new NotFoundException('Rota não encontrada.');
    }
    await this.requirePlayer(userId);
    const entries = await this.entries(userId);
    if (!entries.some(({ id }) => id === islandId)) {
      throw new NotFoundException(ISLAND_NOT_FOUND);
    }
  }
}
