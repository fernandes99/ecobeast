import { Injectable, NotFoundException } from '@nestjs/common';
import type { CounterIncrement } from '../domain/counters/counters.js';
import {
  blocksWalking,
  type Biome,
} from '../domain/exploration/map-generator.js';
import type { Prisma } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';

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
  constructor(private readonly prisma: PrismaService) {}

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
