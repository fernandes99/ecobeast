import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { ExplorationStore } from '../src/exploration/exploration.store.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

const RUVO = 1;
const NILU = 4;
const NOT_FOUND = 'Ilha não encontrada.';

interface Tile {
  q: number;
  r: number;
  biome: string;
  shape: string;
  variant: number;
  area?: number;
}

interface IslandMap {
  seed: number;
  start: { q: number; r: number };
  tiles: Tile[];
  creatures: { id: number; species_id: number; q: number; r: number }[];
  tamers: unknown[];
  island: { id: number; name: string } | null;
  buildings: { building_type_id: number; tiles: { q: number; r: number }[] }[];
}

/** Os hexágonos de um hexágono de raio `radius` em volta de (0, 0). */
function hexagon(radius: number): Tile[] {
  const tiles: Tile[] = [];
  for (let q = -radius; q <= radius; q++) {
    for (let r = -radius; r <= radius; r++) {
      if (Math.abs(q + r) > radius) continue;
      tiles.push({ q, r, biome: 'temperate', shape: 'flat', variant: 1 });
    }
  }
  return tiles;
}

describe('Ilhas do jogador (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let refuge: number;
  let editorToken: string;
  const editor = randomUUID();
  const users: string[] = [];
  const islands: number[] = [];

  /**
   * Uma ilha de 7 hexágonos com a chegada em (0, 0), um Refúgio em (0, 1) e
   * duas áreas: o Campo, com a chegada e (1, 0), e o Lago, com (-1, 0) e o
   * hexágono do Refúgio.
   */
  function draft(name: string) {
    const tiles = hexagon(1);
    const at = (q: number, r: number) =>
      tiles.find((tile) => tile.q === q && tile.r === r)!;
    at(0, 0).area = 1;
    at(1, 0).area = 1;
    at(-1, 0).area = 2;
    at(0, 1).area = 2;
    return {
      name,
      start: { q: 0, r: 0 },
      tiles,
      buildings: [{ building_type_id: refuge, tiles: [{ q: 0, r: 1 }] }],
      areas: [
        {
          key: 1,
          name: 'Campo',
          color_hex: '#5B8C3A',
          spawn_count: 3,
          species: [
            { species_id: RUVO, weight: 10, min_level: 3, max_level: 5 },
          ],
        },
        {
          key: 2,
          name: 'Lago',
          color_hex: '#2255AA',
          spawn_count: 5,
          species: [
            { species_id: NILU, weight: 10, min_level: 7, max_level: 7 },
          ],
        },
      ],
    };
  }

  const editorCall = (method: 'post' | 'put', path: string) =>
    request(app.getHttpServer())
      [method](`/v1/editor${path}`)
      .set('Authorization', `Bearer ${editorToken}`);

  async function createIsland(name: string, publish: boolean) {
    const response = await editorCall('post', '/islands')
      .send(draft(name))
      .expect(201);
    const id = (response.body as { id: number }).id;
    islands.push(id);
    if (publish) await editorCall('post', `/islands/${id}/publish`).expect(200);
    return id;
  }

  async function newUser(withStarter = true) {
    const id = randomUUID();
    users.push(id);
    const auth = { Authorization: `Bearer ${await tokens.sign(id)}` };
    const http = () => request(app.getHttpServer());
    if (withStarter) {
      await http().post('/v1/me').set(auth).send({ name: 'Ana' }).expect(201);
      await http()
        .post('/v1/me/starter')
        .set(auth)
        .send({ species_id: RUVO })
        .expect(200);
    }
    return {
      id,
      list: () => http().get('/v1/me/islands').set(auth),
      explore: (body?: object) => {
        const call = http().post('/v1/me/exploration').set(auth);
        return body === undefined ? call : call.send(body);
      },
      wild: (body: object) =>
        http().post('/v1/me/board-battle/wild').set(auth).send(body),
    };
  }

  let published: number;
  let draftOnly: number;

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({
      tokenVerifier: tokens.verifier,
      env: { MAP_EDITOR_USER_IDS: [editor] },
    });
    editorToken = await tokens.sign(editor);
    refuge = (
      await prisma.buildingType.findUniqueOrThrow({
        where: { slug: 'refuge' },
      })
    ).id;
    published = await createIsland('Ilha publicada de teste', true);
    draftOnly = await createIsland('Ilha em rascunho de teste', false);
  });

  afterAll(async () => {
    await prisma.island.deleteMany({ where: { id: { in: islands } } });
    await prisma.player.deleteMany({ where: { id: { in: users } } });
    await prisma.$disconnect();
    await app.close();
  });

  describe('GET /v1/me/islands', () => {
    it('sem token, dá 401', async () => {
      await request(app.getHttpServer()).get('/v1/me/islands').expect(401);
    });

    it('lista só as publicadas, com o nome publicado, mesmo sem Domador', async () => {
      const user = await newUser(false);
      await editorCall('put', `/islands/${published}/draft`)
        .send(draft('Nome novo do rascunho'))
        .expect(200);

      const { body } = await user.list().expect(200);

      const list = (body as { islands: { id: number; name: string }[] })
        .islands;
      expect(list).toContainEqual({
        id: published,
        name: 'Ilha publicada de teste',
      });
      expect(list.some((island) => island.id === draftOnly)).toBe(false);
      const ids = list.map(({ id }) => id);
      expect(ids).toEqual([...ids].sort((a, b) => a - b));
    });
  });

  describe('POST /v1/me/exploration numa ilha', () => {
    it('devolve o mapa publicado, as construções e os Ecobeasts das áreas', async () => {
      const user = await newUser();

      const { body } = await user
        .explore({ island_id: published })
        .expect(201);

      const map = (body as { map: IslandMap }).map;
      expect(map.seed).toBe(published);
      expect(map.start).toEqual({ q: 0, r: 0 });
      expect(map.island).toEqual({
        id: published,
        name: 'Ilha publicada de teste',
      });
      expect(map.tiles).toHaveLength(7);
      expect(Object.keys(map.tiles[0]!).sort()).toEqual([
        'biome',
        'q',
        'r',
        'shape',
        'variant',
      ]);
      expect(map.buildings).toEqual([
        { building_type_id: refuge, tiles: [{ q: 0, r: 1 }] },
      ]);
      expect(map.tamers).toEqual([]);

      expect(map.creatures).toHaveLength(8);
      const field = map.creatures.filter((c) => c.species_id === RUVO);
      const lake = map.creatures.filter((c) => c.species_id === NILU);
      expect(field).toHaveLength(3);
      expect(lake).toHaveLength(5);
      for (const creature of field) {
        expect(['0,0', '1,0']).toContain(`${creature.q},${creature.r}`);
      }
      // O hexágono do Refúgio é do Lago, mas construção não recebe Ecobeast.
      for (const creature of lake) {
        expect(`${creature.q},${creature.r}`).toBe('-1,0');
      }
      expect(map.creatures.map(({ id }) => id).sort((a, b) => a - b)).toEqual(
        [1, 2, 3, 4, 5, 6, 7, 8],
      );

      const stored = app.get(ExplorationStore).get(user.id)!;
      expect(stored.tamers.size).toBe(0);
      expect(stored.position).toEqual({ q: 0, r: 0 });
      for (const spawn of stored.spawns.values()) {
        if (spawn.speciesId === RUVO) {
          expect(spawn.level).toBeGreaterThanOrEqual(3);
          expect(spawn.level).toBeLessThanOrEqual(5);
        } else {
          expect(spawn.level).toBe(7);
        }
      }
    });

    it('Procurar enfrenta um Ecobeast da área no hexágono do Domador', async () => {
      const user = await newUser();
      // Sorteia até um Ecobeast do Campo nascer na chegada.
      let here: IslandMap['creatures'] = [];
      for (let tries = 0; tries < 20 && here.length === 0; tries++) {
        const { body } = await user
          .explore({ island_id: published })
          .expect(201);
        const map = (body as { map: IslandMap }).map;
        expect(map.island?.id).toBe(published);
        here = map.creatures.filter(({ q, r }) => q === 0 && r === 0);
      }
      expect(here.length).toBeGreaterThan(0);

      const { body } = await user.wild({ q: 0, r: 0 }).expect(201);

      const spawnId = (body as { spawn_id: number }).spawn_id;
      expect(here.map(({ id }) => id)).toContain(spawnId);
      expect(app.get(ExplorationStore).get(user.id)!.spawns.has(spawnId)).toBe(
        false,
      );
    });

    it('responde 404 a uma ilha só em rascunho ou que não existe', async () => {
      const user = await newUser();
      for (const id of [draftOnly, 2_147_483_647]) {
        const { body } = await user.explore({ island_id: id }).expect(404);
        expect((body as { message: string }).message).toBe(NOT_FOUND);
      }
    });

    it.each([['x'], [0], [-2], [1.5]])(
      'responde 400 ao island_id %j',
      async (islandId) => {
        const user = await newUser();
        const { body } = await user
          .explore({ island_id: islandId })
          .expect(400);
        expect((body as { message: string }).message).toBe(NOT_FOUND);
      },
    );

    it('sem Domador, dá 409 antes de procurar a ilha', async () => {
      const user = await newUser(false);
      const { body } = await user.explore({ island_id: 2_147_483_647 }).expect(
        409,
      );
      expect((body as { message: string }).message).toBe(
        'Crie seu Domador primeiro.',
      );
    });

    it('sem corpo, sorteia o mapa de sempre, sem ilha nem construções', async () => {
      const user = await newUser();
      const { body } = await user.explore().expect(201);
      const map = (body as { map: IslandMap }).map;
      expect(map.island).toBeNull();
      expect(map.buildings).toEqual([]);
      expect(map.tiles.length).toBeGreaterThan(1000);
    });

    it('o /docs descreve a lista e o corpo da exploração', async () => {
      const { body: doc } = await request(app.getHttpServer())
        .get('/docs/openapi.json')
        .expect(200);
      expect(doc.paths['/v1/me/islands']?.get?.tags).toEqual(['Ilhas']);
      expect(
        doc.paths['/v1/me/exploration']?.post?.responses?.['404'],
      ).toBeDefined();
      expect(doc.components.schemas.PlayerIslandDto).toBeDefined();
      expect(doc.components.schemas.IslandSummaryDto).toBeDefined();
    });
  });
});
