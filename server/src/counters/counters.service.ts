import { Injectable, NotFoundException } from '@nestjs/common';
import {
  COUNTER_IDS,
  counterTotal,
  mergeIncrements,
  type CounterIncrement,
} from '../domain/counters/counters.js';
import {
  nextStreak,
  playDayOf,
  playSecondsFor,
} from '../domain/counters/ping.js';
import {
  blocksWalking,
  type Biome,
} from '../domain/exploration/map-generator.js';
import type { Prisma } from '../generated/prisma/client.js';
import { ExplorationStore } from '../exploration/exploration.store.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { QuestsService } from '../quests/quests.service.js';

export const NO_PLAYER = 'Crie seu Domador primeiro.';

type CounterClient = Pick<Prisma.TransactionClient, 'playerCounter'>;

export interface CountersView {
  counters: { counterId: number; subjectId: number; value: number }[];
  partner: { creatureUid: string; speciesId: number; battles: number } | null;
  createdAt: Date;
  walkableBiomes: number;
}

@Injectable()
export class CountersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly explorations: ExplorationStore,
    private readonly quests: QuestsService,
  ) {}

  /** Um `upsert` por contador; o `client` aceita o `tx` de uma transação. */
  increments(
    userId: string,
    list: CounterIncrement[],
    client: CounterClient = this.prisma,
  ): Prisma.PrismaPromise<unknown>[] {
    return list.map(({ counterId, subjectId, amount }) =>
      client.playerCounter.upsert({
        where: {
          playerId_counterId_subjectId: {
            playerId: userId,
            counterId,
            subjectId,
          },
        },
        create: { playerId: userId, counterId, subjectId, value: amount },
        update: { value: { increment: amount } },
      }),
    );
  }

  /**
   * O sinal de cada minuto (player-stats/02). Quem grava o `last_ping_at` lido
   * ganha o tempo e o dia: dois sinais juntos não contam o mesmo minuto duas vezes.
   */
  async ping(
    userId: string,
    hexes: { biome: string; count: number }[],
  ): Promise<void> {
    const now = new Date();
    const player = await this.prisma.player.findUnique({
      where: { id: userId },
      select: { lastPingAt: true, lastPlayDay: true },
    });
    if (!player) throw new NotFoundException(NO_PLAYER);
    const [biomes, streakRow] = await Promise.all([
      this.prisma.biome.findMany({
        where: { slug: { in: hexes.map(({ biome }) => biome) } },
        select: { id: true, slug: true },
      }),
      this.prisma.playerCounter.findUnique({
        where: {
          playerId_counterId_subjectId: {
            playerId: userId,
            counterId: COUNTER_IDS.play_streak,
            subjectId: 0,
          },
        },
      }),
    ]);
    const biomeIds = new Map(biomes.map(({ id, slug }) => [slug, id]));
    const walked = this.explorations.creditHexes(
      userId,
      hexes.flatMap(({ biome, count }) => {
        const biomeId = biomeIds.get(biome);
        return biomeId === undefined ? [] : [{ biomeId, count }];
      }),
    );
    const islandId = this.explorations.get(userId)?.islandId;
    const today = playDayOf(now);
    const lastDay = player.lastPlayDay?.toISOString().slice(0, 10) ?? null;
    const { newDay, streak } = nextStreak(
      lastDay,
      today,
      streakRow?.value ?? 0,
    );

    await this.prisma.$transaction(async (tx) => {
      const { count: claimed } = await tx.player.updateMany({
        where: { id: userId, lastPingAt: player.lastPingAt },
        data: { lastPingAt: now, lastPlayDay: new Date(`${today}T00:00:00Z`) },
      });
      const list: CounterIncrement[] = walked.map(({ biomeId, count }) => ({
        counterId: COUNTER_IDS.biome_hexes,
        subjectId: biomeId,
        amount: count,
      }));
      list.push(
        counterTotal(
          'hexes_walked',
          walked.reduce((sum, { count }) => sum + count, 0),
        ),
      );
      if (claimed === 1) {
        const seconds = playSecondsFor(player.lastPingAt, now);
        list.push(counterTotal('play_seconds', seconds));
        if (islandId !== undefined && seconds > 0) {
          await this.quests.stayWrite(tx, userId, islandId, seconds);
        }
        if (newDay) list.push(counterTotal('play_days', 1));
      }
      await Promise.all(this.increments(userId, mergeIncrements(list), tx));
      if (claimed === 1 && newDay) {
        const key = {
          playerId: userId,
          counterId: COUNTER_IDS.play_streak,
          subjectId: 0,
        };
        await tx.playerCounter.upsert({
          where: { playerId_counterId_subjectId: key },
          create: { ...key, value: streak },
          update: { value: streak },
        });
      }
    });
  }

  async read(userId: string): Promise<CountersView> {
    const player = await this.prisma.player.findUnique({
      where: { id: userId },
      select: { createdAt: true },
    });
    if (!player) throw new NotFoundException(NO_PLAYER);
    const [rows, partner, biomes] = await Promise.all([
      this.prisma.playerCounter.findMany({
        where: { playerId: userId },
        orderBy: [{ counterId: 'asc' }, { subjectId: 'asc' }],
      }),
      this.prisma.creatureInstance.findFirst({
        where: { playerId: userId, battles: { gt: 0 } },
        orderBy: [{ battles: 'desc' }, { caughtAt: 'asc' }],
        select: { uid: true, speciesId: true, battles: true },
      }),
      this.prisma.biome.findMany({ select: { slug: true } }),
    ]);
    return {
      counters: rows.map(({ counterId, subjectId, value }) => ({
        counterId,
        subjectId,
        value,
      })),
      partner: partner && {
        creatureUid: partner.uid,
        speciesId: partner.speciesId,
        battles: partner.battles,
      },
      createdAt: player.createdAt,
      walkableBiomes: biomes.filter(({ slug }) => !blocksWalking(slug as Biome))
        .length,
    };
  }
}
