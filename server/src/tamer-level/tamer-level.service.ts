import { Injectable } from '@nestjs/common';
import {
  addTamerXp,
  levelBounds,
  type TamerLevelRow,
  type TamerXpSources,
} from '../domain/progression/tamer-level.js';
import type { Prisma } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import type { TamerProgressDto } from './tamer-level.dto.js';

export interface TamerLevelCatalog {
  levels: TamerLevelRow[];
  sources: TamerXpSources;
}

export interface TamerAward {
  writes: Prisma.PrismaPromise<unknown>[];
  progress: TamerProgressDto | null;
}

@Injectable()
export class TamerLevelService {
  constructor(private readonly prisma: PrismaService) {}

  async levels(): Promise<TamerLevelRow[]> {
    return this.prisma.tamerLevel.findMany({ orderBy: { level: 'asc' } });
  }

  async catalog(): Promise<TamerLevelCatalog> {
    const [levels, sources] = await Promise.all([
      this.levels(),
      this.prisma.tamerXpSource.findMany({
        select: { slug: true, amount: true },
      }),
    ]);
    return {
      levels,
      sources: new Map(sources.map(({ slug, amount }) => [slug, amount])),
    };
  }

  /** As escritas que somam o XP, sobem o nível e pagam as recompensas, para a transação de quem chama. */
  async award(
    userId: string,
    gained: number,
    levels: readonly TamerLevelRow[],
  ): Promise<TamerAward> {
    if (gained <= 0) return { writes: [], progress: null };
    const player = await this.prisma.player.findUniqueOrThrow({
      where: { id: userId },
      select: { xp: true, level: true },
    });
    const result = addTamerXp(player.xp, player.level, gained, levels);
    const coins = result.levels.reduce((sum, row) => sum + row.rewardCoins, 0);
    const items = result.levels.flatMap(
      ({ rewardItemId, rewardItemQuantity }) =>
        rewardItemId === null
          ? []
          : [{ itemId: rewardItemId, quantity: rewardItemQuantity! }],
    );
    const writes: Prisma.PrismaPromise<unknown>[] = [
      this.prisma.player.update({
        where: { id: userId },
        data: {
          xp: { increment: gained },
          level: result.level,
          ...(coins > 0 && { coins: { increment: coins } }),
        },
      }),
      ...items.map(({ itemId, quantity }) =>
        this.prisma.inventoryItem.upsert({
          where: { playerId_itemId: { playerId: userId, itemId } },
          create: { playerId: userId, itemId, quantity },
          update: { quantity: { increment: quantity } },
        }),
      ),
    ];
    const bounds = levelBounds(result.level, levels);
    return {
      writes,
      progress: {
        xp_gained: gained,
        level_before: player.level,
        level_after: result.level,
        current_xp: result.xp,
        level_xp: bounds.levelXp,
        next_level_xp: bounds.nextLevelXp,
        levels: result.levels.map((row) => ({
          level: row.level,
          reward_coins: row.rewardCoins,
          reward_item_id: row.rewardItemId,
          reward_item_quantity: row.rewardItemQuantity,
        })),
      },
    };
  }
}
