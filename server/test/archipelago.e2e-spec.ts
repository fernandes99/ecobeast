import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

// O Arquipélago (auralis/01). As ilhas de teste ficam bem no fim da ordem, depois
// de Liora e das ilhas de verdade, e a ordem é devolvida a nulo no fim.

const RUVO = 1;
const LOCKED = 'Essa ilha ainda está trancada.';
const NOT_FOUND = 'Ilha não encontrada.';
const BASE_ORDER = 900_000;

interface Entry {
  id: number | null;
  order: number;
  state: 'open' | 'next' | 'hidden';
  name: string | null;
}

function draft(name: string) {
  const tiles = [];
  for (let q = -1; q <= 1; q++) {
    for (let r = -1; r <= 1; r++) {
      if (Math.abs(q + r) <= 1) {
        tiles.push({ q, r, biome: 'temperate', height: 1, variant: 1 });
      }
    }
  }
  return { name, start: { q: 0, r: 0 }, tiles, actions: [], areas: [] };
}

describe('O Arquipélago (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let owner: string;
  const editor = randomUUID();
  const islands: number[] = [];
  const users: string[] = [];
  let first: number;
  let second: number;
  let third: number;
  let unpublished: number;
  let outside: number;

  const editorCall = (method: 'post', path: string) =>
    request(app.getHttpServer())
      [method](`/v1/editor${path}`)
      .set('Authorization', `Bearer ${owner}`);

  async function create(name: string, publish: boolean): Promise<number> {
    const response = await editorCall('post', '/islands')
      .send(draft(name))
      .expect(201);
    const id = (response.body as { id: number }).id;
    islands.push(id);
    if (publish) await editorCall('post', `/islands/${id}/publish`).expect(200);
    return id;
  }

  async function player() {
    const id = randomUUID();
    users.push(id);
    const auth = { Authorization: `Bearer ${await tokens.sign(id)}` };
    const http = () => request(app.getHttpServer());
    await http().post('/v1/me').set(auth).send({}).expect(201);
    await http()
      .post('/v1/me/starter')
      .set(auth)
      .send({ species_id: RUVO })
      .expect(200);
    return {
      archipelago: async (): Promise<Entry[]> => {
        const { body } = await http()
          .get('/v1/me/archipelago')
          .set(auth)
          .expect(200);
        return (body as { islands: Entry[] }).islands.filter(
          ({ order }) => order > BASE_ORDER && order < BASE_ORDER + 1_000,
        );
      },
      islandIds: async (): Promise<number[]> => {
        const { body } = await http()
          .get('/v1/me/islands')
          .set(auth)
          .expect(200);
        return (body as { islands: { id: number }[] }).islands.map(
          ({ id }) => id,
        );
      },
      explore: (islandId: number) =>
        http()
          .post('/v1/me/exploration')
          .set(auth)
          .send({ island_id: islandId }),
      unlock: (islandId: number | string) =>
        http().put(`/v1/me/archipelago/${islandId}/unlock`).set(auth),
      relock: (islandId: number) =>
        http().delete(`/v1/me/archipelago/${islandId}/unlock`).set(auth),
    };
  }

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({
      tokenVerifier: tokens.verifier,
      env: { MAP_EDITOR_USER_IDS: [editor] },
    });
    owner = await tokens.sign(editor);
    first = await create('Primeira de teste', true);
    second = await create('Segunda de teste', true);
    third = await create('Terceira de teste', true);
    unpublished = await create('Rascunho de teste', false);
    outside = await create('Fora de teste', true);
    const orders: [number, number][] = [
      [first, BASE_ORDER + 1],
      [second, BASE_ORDER + 2],
      [third, BASE_ORDER + 3],
      [unpublished, BASE_ORDER + 4],
    ];
    for (const [id, order] of orders) {
      await prisma.island.update({
        where: { id },
        data: { archipelagoOrder: order },
      });
    }
  });

  afterAll(async () => {
    await prisma.island.deleteMany({ where: { id: { in: islands } } });
    await prisma.player.deleteMany({ where: { id: { in: users } } });
    await prisma.$disconnect();
    await app.close();
  });

  it('sem token, dá 401', async () => {
    await request(app.getHttpServer()).get('/v1/me/archipelago').expect(401);
  });

  it('sem Domador, dá 409', async () => {
    const auth = { Authorization: `Bearer ${await tokens.sign(randomUUID())}` };
    await request(app.getHttpServer())
      .get('/v1/me/archipelago')
      .set(auth)
      .expect(409);
  });

  it('a próxima vem com o nome, as outras escondidas, e o rascunho fica de fora', async () => {
    const me = await player();
    // A ilha de ordem BASE+1 é a próxima: as de antes dela (Liora) estão abertas.
    expect(await me.archipelago()).toEqual([
      {
        id: first,
        order: BASE_ORDER + 1,
        state: 'next',
        name: 'Primeira de teste',
      },
      { id: null, order: BASE_ORDER + 2, state: 'hidden', name: null },
      { id: null, order: BASE_ORDER + 3, state: 'hidden', name: null },
    ]);
  });

  it('a trancada dá 403, e abrir pela depuração a deixa entrar', async () => {
    const me = await player();
    const locked = await me.explore(first).expect(403);
    expect(locked.body.message).toBe(LOCKED);
    expect(await me.islandIds()).not.toContain(first);

    await me.unlock(first).expect(204);
    await me.unlock(first).expect(204);
    const opened = await me.explore(first).expect(201);
    expect(opened.body.map.island.id).toBe(first);
    expect(await me.islandIds()).toContain(first);
    expect((await me.archipelago()).map(({ state }) => state)).toEqual([
      'open',
      'next',
      'hidden',
    ]);

    await me.relock(first).expect(204);
    await me.explore(first).expect(403);
  });

  it('a ilha fora do Arquipélago abre e aparece na lista', async () => {
    const me = await player();
    await me.explore(outside).expect(201);
    expect(await me.islandIds()).toContain(outside);
  });

  it('a ilha que não existe continua dando 404', async () => {
    const me = await player();
    const missing = await me.explore(2_000_000_000).expect(404);
    expect(missing.body.message).toBe(NOT_FOUND);
  });

  it('abrir uma ilha fora do Arquipélago ou nunca publicada dá 404', async () => {
    const me = await player();
    await me.unlock(outside).expect(404);
    await me.unlock(unpublished).expect(404);
    await me.unlock('abc').expect(400);
  });

  it('com ENABLE_TEST_BATTLE desligada, abrir e trancar não existem', async () => {
    const closed = await createTestApp({
      tokenVerifier: tokens.verifier,
      env: { ENABLE_TEST_BATTLE: false },
    });
    try {
      const id = randomUUID();
      users.push(id);
      const auth = { Authorization: `Bearer ${await tokens.sign(id)}` };
      await request(closed.getHttpServer())
        .post('/v1/me')
        .set(auth)
        .send({})
        .expect(201);
      await request(closed.getHttpServer())
        .put(`/v1/me/archipelago/${first}/unlock`)
        .set(auth)
        .expect(404);
      await request(closed.getHttpServer())
        .delete(`/v1/me/archipelago/${first}/unlock`)
        .set(auth)
        .expect(404);
    } finally {
      await closed.close();
    }
  });

  it('aparece nos docs, com o cadeado', async () => {
    const { body } = await request(app.getHttpServer())
      .get('/docs/openapi.json')
      .expect(200);
    const doc = body as {
      paths: Record<string, { get: { security: object[]; tags: string[] } }>;
    };
    const operation = doc.paths['/v1/me/archipelago']!.get;
    expect(operation.security).toEqual([{ bearer: [] }]);
    expect(operation.tags).toEqual(['Ilhas']);
  });
});
