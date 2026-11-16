import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

const RUVO = 1;
const NOT_FOUND = 'Ilha não encontrada.';
const INVALID = 'Hexágonos descobertos inválidos.';

interface Hex {
  q: number;
  r: number;
}

function hexagon(radius: number) {
  const tiles: (Hex & { biome: string; height: number; variant: number })[] =
    [];
  for (let q = -radius; q <= radius; q++) {
    for (let r = -radius; r <= radius; r++) {
      if (Math.abs(q + r) > radius) continue;
      tiles.push({ q, r, biome: 'temperate', height: 1, variant: 1 });
    }
  }
  return tiles;
}

function draft(name: string, radius: number) {
  return {
    name,
    start: { q: 0, r: 0 },
    tiles: hexagon(radius),
    actions: [],
    props: [],
    areas: [],
  };
}

const sorted = (hexes: Hex[]) =>
  [...hexes].sort((a, b) => a.q - b.q || a.r - b.r);

describe('Hexágonos descobertos nas ilhas (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let editorToken: string;
  const editor = randomUUID();
  const users: string[] = [];
  const islands: number[] = [];
  let island: number;
  let other: number;

  const editorCall = (method: 'post' | 'put', path: string) =>
    request(app.getHttpServer())
      [method](`/v1/editor${path}`)
      .set('Authorization', `Bearer ${editorToken}`);

  async function createIsland(name: string, radius: number) {
    const response = await editorCall('post', '/islands')
      .send(draft(name, radius))
      .expect(201);
    const id = (response.body as { id: number }).id;
    islands.push(id);
    await editorCall('post', `/islands/${id}/publish`).expect(200);
    return id;
  }

  async function newUser() {
    const id = randomUUID();
    users.push(id);
    const auth = { Authorization: `Bearer ${await tokens.sign(id)}` };
    const http = () => request(app.getHttpServer());
    await http().post('/v1/me').set(auth).send({ name: 'Ana' }).expect(201);
    await http()
      .post('/v1/me/starter')
      .set(auth)
      .send({ species_id: RUVO })
      .expect(200);
    return {
      auth,
      explore: (body?: object) => {
        const call = http().post('/v1/me/exploration').set(auth);
        return body === undefined ? call : call.send(body);
      },
      discovered: async (islandId: number) => {
        const { body } = await http()
          .post('/v1/me/exploration')
          .set(auth)
          .send({ island_id: islandId })
          .expect(201);
        return sorted((body as { discovered: Hex[] }).discovered);
      },
      add: (islandId: number | string, body: object) =>
        http()
          .post(`/v1/me/islands/${islandId}/discoveries`)
          .set(auth)
          .send(body),
      forget: (islandId: number) =>
        http().delete(`/v1/me/islands/${islandId}/discoveries`).set(auth),
    };
  }

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({
      tokenVerifier: tokens.verifier,
      env: { MAP_EDITOR_USER_IDS: [editor] },
    });
    editorToken = await tokens.sign(editor);
    island = await createIsland('Ilha da névoa de teste', 2);
    other = await createIsland('Outra ilha da névoa de teste', 1);
  });

  afterAll(async () => {
    await prisma.island.deleteMany({ where: { id: { in: islands } } });
    await prisma.player.deleteMany({ where: { id: { in: users } } });
    await prisma.$disconnect();
    await app.close();
  });

  it('sem token, dá 401', async () => {
    await request(app.getHttpServer())
      .post(`/v1/me/islands/${island}/discoveries`)
      .send({ tiles: [{ q: 0, r: 0 }] })
      .expect(401);
  });

  it('começa vazio na ilha e no mapa sorteado', async () => {
    const user = await newUser();
    expect(await user.discovered(island)).toEqual([]);
    const { body } = await user.explore().expect(201);
    expect((body as { discovered: Hex[] }).discovered).toEqual([]);
  });

  it('grava, devolve na entrada e é só do jogador', async () => {
    const user = await newUser();
    const stranger = await newUser();
    const tiles = [
      { q: 0, r: 0 },
      { q: 1, r: 0 },
      { q: 0, r: 1 },
    ];

    const { body } = await user.add(island, { tiles }).expect(201);
    expect(body).toEqual({ added: 3 });

    expect(await user.discovered(island)).toEqual(sorted(tiles));
    expect(await user.discovered(other)).toEqual([]);
    expect(await stranger.discovered(island)).toEqual([]);
  });

  it('ignora os repetidos e os que não existem na ilha', async () => {
    const user = await newUser();
    await user.add(island, { tiles: [{ q: 0, r: 0 }] }).expect(201);

    const { body } = await user
      .add(island, {
        tiles: [
          { q: 0, r: 0 },
          { q: -1, r: 0 },
          { q: -1, r: 0 },
          { q: 9, r: 9 },
        ],
      })
      .expect(201);

    expect(body).toEqual({ added: 1 });
  });

  it('recusa ilha que não existe, id inválido e lista inválida', async () => {
    const user = await newUser();
    const one = { tiles: [{ q: 0, r: 0 }] };
    const missing = await user.add(2_000_000_000, one).expect(404);
    expect((missing.body as { message: string }).message).toBe(NOT_FOUND);
    const word = await user.add('abc', one).expect(400);
    expect((word.body as { message: string }).message).toBe(NOT_FOUND);

    const invalid = [
      {},
      { tiles: [] },
      { tiles: [{ q: 0 }] },
      { tiles: [{ q: 0.5, r: 0 }] },
      { tiles: [{ q: '0', r: 0 }] },
      { tiles: Array.from({ length: 1001 }, () => ({ q: 0, r: 0 })) },
    ];
    for (const body of invalid) {
      const response = await user.add(island, body).expect(400);
      expect((response.body as { message: string }).message).toBe(INVALID);
    }
  });

  it('um hexágono que some ao republicar não volta', async () => {
    const shrinking = await createIsland('Ilha que encolhe de teste', 2);
    const user = await newUser();
    await user
      .add(shrinking, {
        tiles: [
          { q: 0, r: 0 },
          { q: 2, r: 0 },
        ],
      })
      .expect(201);

    await editorCall('put', `/islands/${shrinking}/draft`)
      .send(draft('Ilha que encolhe de teste', 1))
      .expect(200);
    await editorCall('post', `/islands/${shrinking}/publish`).expect(200);

    expect(await user.discovered(shrinking)).toEqual([{ q: 0, r: 0 }]);
  });

  it('esquecer apaga só a ilha pedida e só do jogador', async () => {
    const user = await newUser();
    const stranger = await newUser();
    const tiles = [
      { q: 0, r: 0 },
      { q: 1, r: 0 },
    ];
    await user.add(island, { tiles }).expect(201);
    await user.add(other, { tiles }).expect(201);
    await stranger.add(island, { tiles }).expect(201);

    const { body } = await user.forget(island).expect(200);

    expect(body).toEqual({ removed: 2 });
    expect(await user.discovered(island)).toEqual([]);
    expect(await user.discovered(other)).toEqual(sorted(tiles));
    expect(await stranger.discovered(island)).toEqual(sorted(tiles));
  });

  it('esquecer não existe sem as rotas de teste', async () => {
    const closed = await createTestApp({
      tokenVerifier: tokens.verifier,
      env: { ENABLE_TEST_BATTLE: false },
    });
    try {
      const user = await newUser();
      await request(closed.getHttpServer())
        .delete(`/v1/me/islands/${island}/discoveries`)
        .set(user.auth)
        .expect(404);
    } finally {
      await closed.close();
    }
  });
});
