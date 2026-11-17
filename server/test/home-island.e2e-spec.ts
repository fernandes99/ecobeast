import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

// A ilha casa (home-island/01) e Liora sem equipe (liora-intro/01). A casa é uma só
// para o banco inteiro: o teste guarda a de antes e a devolve no fim.

const RUVO = 1;
const NO_TEAM = 'Escolha seu primeiro Ecobeast antes de viajar.';

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

describe('A ilha casa (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let owner: string;
  let before: number | null = null;
  const editor = randomUUID();
  const islands: number[] = [];
  const users: string[] = [];

  const call = (method: 'get' | 'post' | 'put', path: string) =>
    request(app.getHttpServer())
      [method](`/v1/editor${path}`)
      .set('Authorization', `Bearer ${owner}`);

  async function create(publish: boolean): Promise<number> {
    const response = await call('post', '/islands')
      .send(draft('Ilha casa de teste'))
      .expect(201);
    const id = (response.body as { id: number }).id;
    islands.push(id);
    if (publish) await call('post', `/islands/${id}/publish`).expect(200);
    return id;
  }

  async function player(withStarter: boolean) {
    const id = randomUUID();
    users.push(id);
    const auth = { Authorization: `Bearer ${await tokens.sign(id)}` };
    const http = () => request(app.getHttpServer());
    await http().post('/v1/me').set(auth).send({}).expect(201);
    if (withStarter) {
      await http()
        .post('/v1/me/starter')
        .set(auth)
        .send({ species_id: RUVO })
        .expect(200);
    }
    return (body: object) =>
      http().post('/v1/me/exploration').set(auth).send(body);
  }

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({
      tokenVerifier: tokens.verifier,
      env: { MAP_EDITOR_USER_IDS: [editor] },
    });
    owner = await tokens.sign(editor);
    before =
      (await prisma.island.findFirst({ where: { isHome: true } }))?.id ?? null;
  });

  afterAll(async () => {
    await prisma.island.updateMany({
      where: { isHome: true },
      data: { isHome: false },
    });
    if (before !== null) {
      await prisma.island.update({
        where: { id: before },
        data: { isHome: true },
      });
    }
    await prisma.island.deleteMany({ where: { id: { in: islands } } });
    await prisma.player.deleteMany({ where: { id: { in: users } } });
    await prisma.$disconnect();
    await app.close();
  });

  describe('PUT /v1/editor/islands/:id/home', () => {
    it('liga a casa numa ilha e a troca para outra, deixando só uma', async () => {
      const first = await create(true);
      const second = await create(true);

      const on = await call('put', `/islands/${first}/home`)
        .send({ home: true })
        .expect(200);
      expect(on.body.home).toBe(true);
      await call('put', `/islands/${second}/home`)
        .send({ home: true })
        .expect(200);

      const homes = await prisma.island.findMany({ where: { isHome: true } });
      expect(homes.map(({ id }) => id)).toEqual([second]);
      const read = await call('get', `/islands/${first}`).expect(200);
      expect(read.body.home).toBe(false);

      const list = await request(app.getHttpServer())
        .get('/v1/me/islands')
        .set('Authorization', `Bearer ${owner}`)
        .expect(200);
      const flagged = (
        list.body as { islands: { id: number; home: boolean }[] }
      ).islands.filter(({ home }) => home);
      expect(flagged.map(({ id }) => id)).toEqual([second]);
    });

    it('desliga a casa', async () => {
      const id = await create(true);
      await call('put', `/islands/${id}/home`).send({ home: true }).expect(200);
      const off = await call('put', `/islands/${id}/home`)
        .send({ home: false })
        .expect(200);
      expect(off.body.home).toBe(false);
    });

    it('recusa a casa numa ilha nunca publicada (400)', async () => {
      const id = await create(false);
      const response = await call('put', `/islands/${id}/home`)
        .send({ home: true })
        .expect(400);
      expect(response.body.message).toBe(
        'Publique a ilha antes de fazer dela a casa do jogador.',
      );
    });

    it('recusa um home que não é booleano (400)', async () => {
      const id = await create(true);
      await call('put', `/islands/${id}/home`)
        .send({ home: 'sim' })
        .expect(400);
    });
  });

  describe('Explorar sem equipe (liora-intro/01)', () => {
    it('abre só a ilha casa; outra ilha e a zona dão 409', async () => {
      const home = await create(true);
      const other = await create(true);
      await call('put', `/islands/${home}/home`)
        .send({ home: true })
        .expect(200);
      const explore = await player(false);

      const opened = await explore({ island_id: home }).expect(201);
      expect(opened.body.map.island.id).toBe(home);
      const elsewhere = await explore({ island_id: other }).expect(409);
      expect(elsewhere.body.message).toBe(NO_TEAM);
      const zone = await explore({}).expect(409);
      expect(zone.body.message).toBe(NO_TEAM);
    });

    it('com equipe, qualquer ilha abre, como antes', async () => {
      const home = await create(true);
      const other = await create(true);
      await call('put', `/islands/${home}/home`)
        .send({ home: true })
        .expect(200);
      const explore = await player(true);
      await explore({ island_id: other }).expect(201);
    });
  });
});
