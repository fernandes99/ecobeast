import { Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Env } from '../config/env.js';
import type { HexCoord } from '../domain/exploration/hex.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { ISLAND_NOT_FOUND } from './islands.service.js';

const PUBLISHED = 'published';

/** Os hexágonos de ilha que cada Domador já descobriu (fog-of-war/01). */
@Injectable()
export class DiscoveriesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService<Env, true>,
  ) {}

  /** Só os que existem em `tiles`, a versão publicada de agora. */
  async listDiscovered(
    userId: string,
    islandId: number,
    tiles: readonly HexCoord[],
  ): Promise<HexCoord[]> {
    const rows = await this.prisma.islandDiscovery.findMany({
      where: { playerId: userId, islandId },
      select: { q: true, r: true },
    });
    const existing = new Set(tiles.map(({ q, r }) => `${q},${r}`));
    return rows.filter(({ q, r }) => existing.has(`${q},${r}`));
  }

  async add(
    userId: string,
    islandId: number,
    tiles: readonly HexCoord[],
  ): Promise<number> {
    await this.requirePublished(islandId);
    const qs = tiles.map(({ q }) => q);
    const rs = tiles.map(({ r }) => r);
    // Junta com os hexágonos publicados e com o jogador: o que não existe fica de fora.
    return this.prisma.$executeRaw`
      INSERT INTO "ecobeasts"."island_discoveries" ("player_id", "island_id", "q", "r")
      SELECT DISTINCT p."id", m."island_id", t."q", t."r"
      FROM unnest(${qs}::int[], ${rs}::int[]) AS c("q", "r")
      JOIN "ecobeasts"."island_maps" m
        ON m."island_id" = ${islandId} AND m."kind" = ${PUBLISHED}
      JOIN "ecobeasts"."island_tiles" t
        ON t."island_map_id" = m."id" AND t."q" = c."q" AND t."r" = c."r"
      JOIN "ecobeasts"."players" p ON p."id" = ${userId}::uuid
      ON CONFLICT DO NOTHING`;
  }

  async forget(userId: string, islandId: number): Promise<number> {
    if (!this.config.get('ENABLE_TEST_BATTLE', { infer: true })) {
      throw new NotFoundException('Rota não encontrada.');
    }
    const { count } = await this.prisma.islandDiscovery.deleteMany({
      where: { playerId: userId, islandId },
    });
    return count;
  }

  private async requirePublished(islandId: number): Promise<void> {
    const map = await this.prisma.islandMap.findUnique({
      where: { islandId_kind: { islandId, kind: PUBLISHED } },
      select: { id: true },
    });
    if (!map) throw new NotFoundException(ISLAND_NOT_FOUND);
  }
}
