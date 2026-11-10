import { Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Env } from '../config/env.js';
import { uniqueIds } from '../domain/codex/codex.js';
import type { Prisma } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';

/** Uma espécie que o jogador conhece. */
export interface CodexEntryView {
  speciesId: number;
  caught: boolean;
}

/**
 * O Bestiário de cada jogador (.specs/codex/architecture.md): as espécies que
 * ele viu numa luta e as que capturou. As datas nunca voltam: ver ou capturar
 * de novo não muda nada.
 */
@Injectable()
export class CodexService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService<Env, true>,
  ) {}

  /** As espécies conhecidas, na ordem do número. */
  async list(userId: string): Promise<CodexEntryView[]> {
    const rows = await this.prisma.codexEntry.findMany({
      where: { playerId: userId },
      orderBy: { speciesId: 'asc' },
      select: { speciesId: true, caughtAt: true },
    });
    return rows.map(({ speciesId, caughtAt }) => ({
      speciesId,
      caught: caughtAt !== null,
    }));
  }

  /** Cria a linha de quem ainda não tem; quem já tem não muda. */
  async recordSeen(userId: string, speciesIds: number[]): Promise<void> {
    if (speciesIds.length === 0) return;
    await this.seenWrite(userId, speciesIds);
  }

  /** A escrita do visto, para entrar no `$transaction([...])` de quem chama. */
  seenWrite(
    userId: string,
    speciesIds: number[],
  ): Prisma.PrismaPromise<Prisma.BatchPayload> {
    const seenAt = new Date();
    return this.prisma.codexEntry.createMany({
      data: uniqueIds(speciesIds).map((speciesId) => ({
        playerId: userId,
        speciesId,
        seenAt,
      })),
      skipDuplicates: true,
    });
  }

  /**
   * A escrita do capturado, para entrar no `$transaction([...])` de quem chama:
   * a lista não deixa ler antes de decidir, então é um `INSERT` só, que devolve
   * as espécies que ficaram capturadas agora. Quem já tinha sido visto ganha o
   * `caught_at`, nunca antes do `seen_at`. Passe a lista devolvida ao
   * `newlyCaught`.
   */
  caughtWrite(
    userId: string,
    speciesIds: number[],
  ): Prisma.PrismaPromise<{ species_id: number }[]> {
    return this.prisma.$queryRaw<{ species_id: number }[]>`
      INSERT INTO "ecobeasts"."codex_entries" ("player_id", "species_id", "seen_at", "caught_at")
      SELECT ${userId}::uuid, species_id, now(), now()
      FROM unnest(${uniqueIds(speciesIds)}::int[]) AS species_id
      ON CONFLICT ("player_id", "species_id") DO UPDATE
        SET "caught_at" = GREATEST(now(), "codex_entries"."seen_at")
        WHERE "codex_entries"."caught_at" IS NULL
      RETURNING "species_id"`;
  }

  /** As espécies da escrita do capturado, na ordem pedida e sem repetir. */
  newlyCaught(
    speciesIds: number[],
    written: { species_id: number }[],
  ): number[] {
    const fresh = new Set(written.map((row) => row.species_id));
    return uniqueIds(speciesIds).filter((id) => fresh.has(id));
  }

  /** Grava o capturado sozinho e devolve as espécies capturadas agora. */
  async recordCaught(userId: string, speciesIds: number[]): Promise<number[]> {
    if (speciesIds.length === 0) return [];
    return this.newlyCaught(
      speciesIds,
      await this.caughtWrite(userId, speciesIds),
    );
  }

  /** Só para testar o aviso de registro: apaga o Bestiário do jogador. */
  async clear(userId: string): Promise<void> {
    if (!this.config.get('ENABLE_TEST_BATTLE', { infer: true })) {
      throw new NotFoundException('Rota não encontrada.');
    }
    await this.prisma.codexEntry.deleteMany({ where: { playerId: userId } });
  }
}
