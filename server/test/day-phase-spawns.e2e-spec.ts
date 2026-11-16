import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { INVALID_DEBUG_MINUTE } from '../src/exploration/exploration.dto.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

const RUVO = 1;
const MAPS = 6;

interface ExplorationBody {
  map: { creatures: { species_id: number }[] };
}

// Apaga e devolve linhas de species_day_phases: roda no grupo e2e-catalog-writers.
describe('Os selvagens pela parte do dia (e2e, day-phase-spawns/01)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let auth: { Authorization: string };
  const userId = randomUUID();
  let nightOnly: number;
  let morning: { id: number; startMinute: number };
  let night: { id: number; startMinute: number };
  let removed: { speciesId: number; dayPhaseId: number }[] = [];

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({ tokenVerifier: tokens.verifier });
    auth = { Authorization: `Bearer ${await tokens.sign(userId)}` };
    await request(app.getHttpServer())
      .post('/v1/me')
      .set(auth)
      .send({ name: 'Ana' })
      .expect(201);
    await request(app.getHttpServer())
      .post('/v1/me/starter')
      .set(auth)
      .send({ species_id: RUVO })
      .expect(200);

    const phases = await prisma.dayPhase.findMany();
    morning = phases.find(({ slug }) => slug === 'morning')!;
    night = phases.find(({ slug }) => slug === 'night')!;
    // O Ecobeast com mais taxa nos biomas, para ele aparecer em quase todo mapa.
    const rates = await prisma.speciesBiome.groupBy({
      by: ['speciesId'],
      _sum: { rate: true },
      orderBy: { _sum: { rate: 'desc' } },
      take: 1,
    });
    nightOnly = rates[0]!.speciesId;
    removed = await prisma.speciesDayPhase.findMany({
      where: { speciesId: nightOnly, dayPhaseId: { not: night.id } },
    });
    await prisma.speciesDayPhase.deleteMany({
      where: { speciesId: nightOnly, dayPhaseId: { not: night.id } },
    });
  });

  afterAll(async () => {
    await prisma.speciesDayPhase.createMany({
      data: removed,
      skipDuplicates: true,
    });
    await prisma.player.deleteMany({ where: { id: userId } });
    await prisma.$disconnect();
    await app.close();
  });

  async function speciesAt(minute: number): Promise<Set<number>> {
    const seen = new Set<number>();
    for (let index = 0; index < MAPS; index += 1) {
      const { body } = await request(app.getHttpServer())
        .post('/v1/me/exploration')
        .set(auth)
        .send({ debug_minute: minute })
        .expect(201);
      for (const { species_id } of (body as ExplorationBody).map.creatures) {
        seen.add(species_id);
      }
    }
    return seen;
  }

  it('o Ecobeast só da Noite não nasce de manhã', async () => {
    const seen = await speciesAt(morning.startMinute);
    expect(seen.size).toBeGreaterThan(0);
    expect(seen.has(nightOnly)).toBe(false);
  });

  it('à Noite, ele nasce', async () => {
    expect((await speciesAt(night.startMinute)).has(nightOnly)).toBe(true);
  });

  it('debug_minute fora de 0 a 1439, ou quebrado, dá 400', async () => {
    for (const debug_minute of [-1, 1440, 12.5, '600']) {
      const { body } = await request(app.getHttpServer())
        .post('/v1/me/exploration')
        .set(auth)
        .send({ debug_minute })
        .expect(400);
      expect((body as { message: string }).message).toBe(INVALID_DEBUG_MINUTE);
    }
  });
});
