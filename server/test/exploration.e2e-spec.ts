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
      spawn: (body: object) =>
        http().post('/v1/me/exploration/spawns').set(auth).send(body),
      clear: () => http().delete('/v1/me/exploration/spawns').set(auth),
      wild: (body: object) =>
        http().post('/v1/me/board-battle/wild').set(auth).send(body),
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

  describe('spawn de depuração (biome-encounters/05)', () => {
    const RUVAK = 2;
    const INVALID_ENEMY = 'Esse inimigo não existe.';

    async function explorer() {
      const user = await userWithStarter();
      const { body } = await user.explore().expect(201);
      return { user, start: (body as ExplorationBody).map.start };
    }

    it('põe o Ecobeast na exploração, no formato do mapa, com o nível da equipe', async () => {
      const { user, start } = await explorer();
      const before = app.get(ExplorationStore).get(user.id)!.spawns.size;

      const { body } = await user
        .spawn({ species_id: RUVAK, ...start })
        .expect(201);

      const { creature } = body as {
        creature: { id: number; species_id: number; q: number; r: number };
      };
      expect(Object.keys(creature).sort()).toEqual([
        'id',
        'q',
        'r',
        'species_id',
      ]);
      expect(creature).toMatchObject({ species_id: RUVAK, ...start });
      const spawns = app.get(ExplorationStore).get(user.id)!.spawns;
      expect(spawns.size).toBe(before + 1);
      expect(spawns.get(creature.id)).toMatchObject({
        speciesId: RUVAK,
        level: 5,
        debug: true,
      });
    });

    it('aceita um nível de 1 a 100', async () => {
      const { user, start } = await explorer();

      const { body } = await user
        .spawn({ species_id: RUVAK, level: 30, ...start })
        .expect(201);

      const { id } = (body as { creature: { id: number } }).creature;
      expect(
        app.get(ExplorationStore).get(user.id)!.spawns.get(id)!.level,
      ).toBe(30);
    });

    it('Procurar no hexágono enfrenta o Ecobeast do spawn', async () => {
      const { user, start } = await explorer();
      const store = app.get(ExplorationStore);
      // Só o do spawn no hexágono: os do sorteio poderiam cair no mesmo.
      store.get(user.id)!.spawns.clear();
      const { body } = await user
        .spawn({ species_id: RUVAK, ...start })
        .expect(201);
      const { id } = (body as { creature: { id: number } }).creature;

      const res = await user.wild(start).expect(201);

      const battle = res.body as {
        spawn_id: number;
        battle: { enemy: { actives: { species_id: number }[] } };
      };
      expect(battle.spawn_id).toBe(id);
      expect(battle.battle.enemy.actives[0]!.species_id).toBe(RUVAK);
      expect(store.get(user.id)!.spawns.has(id)).toBe(false);
    });

    it('espécie que não existe ou nível fora de 1 a 100 dão 400', async () => {
      const { user, start } = await explorer();

      for (const body of [
        { species_id: 9999, ...start },
        { species_id: RUVAK, level: 0, ...start },
        { species_id: RUVAK, level: 101, ...start },
        { species_id: RUVAK, q: 'x', r: 0 },
      ]) {
        const res = await user.spawn(body).expect(400);
        expect((res.body as { message: string }).message).toBe(INVALID_ENEMY);
      }
    });

    it('sem exploração, dá 404', async () => {
      const user = await userWithStarter();

      const res = await user
        .spawn({ species_id: RUVAK, q: 0, r: 0 })
        .expect(404);
      await user.clear().expect(404);

      expect((res.body as { message: string }).message).toBe(
        'Essa exploração acabou. Saia e entre de novo.',
      );
    });

    it('remover tira só os do spawn e devolve os ids', async () => {
      const { user, start } = await explorer();
      const store = app.get(ExplorationStore);
      const drawn = [...store.get(user.id)!.spawns.keys()];
      const ids: number[] = [];
      for (const species_id of [RUVO, RUVAK]) {
        const { body } = await user.spawn({ species_id, ...start }).expect(201);
        ids.push((body as { creature: { id: number } }).creature.id);
      }

      const { body } = await user.clear().expect(200);

      expect((body as { removed_ids: number[] }).removed_ids.sort()).toEqual(
        ids.sort(),
      );
      expect([...store.get(user.id)!.spawns.keys()]).toEqual(drawn);
    });

    it('com ENABLE_TEST_BATTLE desligada, as rotas não existem', async () => {
      const closed = await createTestApp({
        tokenVerifier: tokens.verifier,
        env: { ENABLE_TEST_BATTLE: false },
      });
      try {
        const id = randomUUID();
        users.push(id);
        const auth = { Authorization: `Bearer ${await tokens.sign(id)}` };
        await request(closed.getHttpServer())
          .post('/v1/me/exploration/spawns')
          .set(auth)
          .send({ species_id: RUVAK, q: 0, r: 0 })
          .expect(404);
        await request(closed.getHttpServer())
          .delete('/v1/me/exploration/spawns')
          .set(auth)
          .expect(404);
      } finally {
        await closed.close();
      }
    });
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
