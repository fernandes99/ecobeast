import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import type { MapTile } from '../src/domain/exploration/map-generator.js';
import { DEFAULT_SPAWN_CONFIG } from '../src/domain/exploration/spawn-config.js';
import { encounterBiome } from '../src/domain/exploration/spawns.js';
import { ExplorationStore } from '../src/exploration/exploration.store.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

const RUVO = 1;
const NO_PLAYER = 'Crie seu Domador primeiro.';

interface ExplorationBody {
  map: {
    seed: number;
    start: { q: number; r: number };
    tiles: {
      q: number;
      r: number;
      biome: MapTile['biome'];
      shape: MapTile['shape'];
      variant: number;
    }[];
    creatures: { id: number; species_id: number; q: number; r: number }[];
  };
}

describe('Rota do mapa de exploração (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  const users: string[] = [];

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({ tokenVerifier: tokens.verifier });
  });

  afterAll(async () => {
    await prisma.player.deleteMany({ where: { id: { in: users } } });
    await prisma.$disconnect();
    await app.close();
  });

  async function newUser() {
    const id = randomUUID();
    users.push(id);
    const auth = { Authorization: `Bearer ${await tokens.sign(id)}` };
    const http = () => request(app.getHttpServer());
    return {
      id,
      create: () => http().post('/v1/me').set(auth).send({ name: 'Ana' }),
      starter: () =>
        http().post('/v1/me/starter').set(auth).send({ species_id: RUVO }),
      explore: () => http().post('/v1/me/exploration').set(auth),
    };
  }

  async function userWithStarter() {
    const user = await newUser();
    await user.create().expect(201);
    await user.starter().expect(200);
    return user;
  }

  it('sem token, dá 401', async () => {
    await request(app.getHttpServer()).post('/v1/me/exploration').expect(401);
  });

  it('sem Domador, dá 409', async () => {
    const user = await newUser();

    const { body } = await user.explore().expect(409);

    expect((body as { message: string }).message).toBe(NO_PLAYER);
  });

  it('sem equipe, dá 409', async () => {
    const user = await newUser();
    await user.create().expect(201);

    const { body } = await user.explore().expect(409);

    expect((body as { message: string }).message).toBe(NO_PLAYER);
  });

  it('devolve um mapa no formato do contrato', async () => {
    const user = await userWithStarter();

    const { body } = await user.explore().expect(201);

    const { map } = body as ExplorationBody;
    expect(Number.isInteger(map.seed)).toBe(true);
    expect(map.tiles.length).toBeGreaterThan(0);
    expect(map.tiles).toContainEqual(expect.objectContaining(map.start));
    expect(Object.keys(map.tiles[0]!).sort()).toEqual([
      'biome',
      'q',
      'r',
      'shape',
      'variant',
    ]);
  });

  it('devolve os Ecobeasts sem nível nem nome', async () => {
    const user = await userWithStarter();

    const { body } = await user.explore().expect(201);

    const { creatures } = (body as ExplorationBody).map;
    expect(creatures).toHaveLength(DEFAULT_SPAWN_CONFIG.count);
    expect(Object.keys(creatures[0]!).sort()).toEqual([
      'id',
      'q',
      'r',
      'species_id',
    ]);
  });

  it('todo Ecobeast nasce em um hexágono do mapa e em um bioma dele', async () => {
    const user = await userWithStarter();
    const rates = await prisma.speciesBiome.findMany({
      where: { rate: { gt: 0 } },
      include: { biome: true },
    });
    const allowed = new Set(
      rates.map(({ speciesId, biome }) => `${speciesId}|${biome.slug}`),
    );

    const { body } = await user.explore().expect(201);

    const { tiles, creatures } = (body as ExplorationBody).map;
    const byKey = new Map(tiles.map((tile) => [`${tile.q},${tile.r}`, tile]));
    for (const { species_id, q, r } of creatures) {
      const tile = byKey.get(`${q},${r}`);
      expect(tile).toBeDefined();
      expect(allowed).toContain(`${species_id}|${encounterBiome(tile!)}`);
    }
  });

  it('a média do time decide o nível de quem nasce', async () => {
    const levelsOf = async (level: number) => {
      const user = await userWithStarter();
      await prisma.creatureInstance.updateMany({
        where: { playerId: user.id },
        data: { level },
      });
      await user.explore().expect(201);
      const { spawns } = app.get(ExplorationStore).get(user.id)!;
      return [...spawns.values()].map((spawn) => spawn.level);
    };

    const low = await levelsOf(5);
    const high = await levelsOf(100);

    expect(Math.max(...low)).toBeLessThan(Math.min(...high));
  });

  it('guarda os Ecobeasts e o Domador no início do mapa', async () => {
    const user = await userWithStarter();

    const { body } = await user.explore().expect(201);

    const { map } = body as ExplorationBody;
    const stored = app.get(ExplorationStore).get(user.id)!;
    expect(stored.position).toEqual(map.start);
    expect([...stored.spawns.keys()]).toEqual(
      map.creatures.map(({ id }) => id),
    );
  });

  it('uma exploração nova substitui a anterior', async () => {
    const user = await userWithStarter();
    await user.explore().expect(201);
    const store = app.get(ExplorationStore);
    store.get(user.id)!.spawns.clear();

    await user.explore().expect(201);

    expect(store.get(user.id)!.spawns.size).toBe(DEFAULT_SPAWN_CONFIG.count);
  });

  it('cada chamada gera um mapa novo', async () => {
    const user = await userWithStarter();

    const first = (await user.explore().expect(201)).body as ExplorationBody;
    const second = (await user.explore().expect(201)).body as ExplorationBody;

    expect(second.map.seed).not.toBe(first.map.seed);
  });

  it('funciona com a equipe a 0 HP', async () => {
    const user = await userWithStarter();
    await prisma.creatureInstance.updateMany({
      where: { playerId: user.id },
      data: { currentHp: 0 },
    });

    await user.explore().expect(201);
  });

  it('aparece nos docs, com o cadeado', async () => {
    const { body } = await request(app.getHttpServer())
      .get('/docs/openapi.json')
      .expect(200);
    const doc = body as {
      paths: Record<string, { post: { security: object[]; tags: string[] } }>;
    };

    const operation = doc.paths['/v1/me/exploration']!.post;

    expect(operation.security).toEqual([{ bearer: [] }]);
    expect(operation.tags).toEqual(['Exploração']);
  });
});
