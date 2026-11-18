import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { ExplorationStore } from '../src/exploration/exploration.store.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

// O teleporte de depuração do mapa grande (minimap/03).

const RUVO = 1;
const RUVAK = 2;
const FAR = 40;

describe('Teleporte de depuração (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  const editor = randomUUID();
  const users: string[] = [];

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({
      tokenVerifier: tokens.verifier,
      env: { MAP_EDITOR_USER_IDS: [editor] },
    });
  });

  afterAll(async () => {
    await prisma.player.deleteMany({ where: { id: { in: users } } });
    await prisma.$disconnect();
    await app.close();
  });

  async function explorer(id = randomUUID(), server = app) {
    users.push(id);
    const auth = { Authorization: `Bearer ${await tokens.sign(id)}` };
    const http = () => request(server.getHttpServer());
    await http().post('/v1/me').set(auth).send({ name: 'Ana' }).expect(201);
    await http()
      .post('/v1/me/starter')
      .set(auth)
      .send({ species_id: RUVO })
      .expect(200);
    const { body } = await http()
      .post('/v1/me/exploration')
      .set(auth)
      .expect(201);
    const start = (body as { map: { start: { q: number; r: number } } }).map
      .start;
    return {
      id,
      start,
      teleport: (position: object) =>
        http().put('/v1/me/exploration/position').set(auth).send(position),
      spawn: (body: object) =>
        http().post('/v1/me/exploration/spawns').set(auth).send(body),
      wild: (body: object) =>
        http().post('/v1/me/board-battle/wild').set(auth).send(body),
    };
  }

  it('longe, sem o teleporte, o Procurar recusa', async () => {
    const user = await explorer(editor);
    app.get(ExplorationStore).get(user.id)!.spawns.clear();
    const far = { q: user.start.q + FAR, r: user.start.r };
    await user.spawn({ species_id: RUVAK, ...far }).expect(201);
    const res = await user.wild(far).expect(409);
    expect(res.body.message).toBe('Você não chegou até aí.');
  });

  it('teleporta e o Procurar vale no hexágono novo na hora', async () => {
    await prisma.player.deleteMany({ where: { id: editor } });
    const user = await explorer(editor);
    app.get(ExplorationStore).get(user.id)!.spawns.clear();
    const far = { q: user.start.q + FAR, r: user.start.r - 3 };
    const res = await user.teleport(far).expect(200);
    expect(res.body).toEqual(far);
    expect(app.get(ExplorationStore).get(user.id)!.position).toEqual(far);

    await user.spawn({ species_id: RUVAK, ...far }).expect(201);
    await user.wild(far).expect(201);
  });

  it('recusa q e r que não são inteiros de -1000 a 1000 (400)', async () => {
    await prisma.player.deleteMany({ where: { id: editor } });
    const user = await explorer(editor);
    for (const body of [
      { q: 1.5, r: 0 },
      { q: 0, r: 1001 },
      { q: 'a', r: 0 },
      {},
    ]) {
      const res = await user.teleport(body).expect(400);
      expect(res.body.message).toBe(
        'q e r precisam ser inteiros de -1000 a 1000.',
      );
    }
  });

  it('recusa quem não está em MAP_EDITOR_USER_IDS (403)', async () => {
    const user = await explorer();
    await user.teleport({ q: 0, r: 0 }).expect(403);
  });

  it('sem exploração, dá 404', async () => {
    await prisma.player.deleteMany({ where: { id: editor } });
    const user = await explorer(editor);
    app.get(ExplorationStore).delete(user.id);
    const res = await user.teleport({ q: 0, r: 0 }).expect(404);
    expect(res.body.message).toBe(
      'Essa exploração acabou. Saia e entre de novo.',
    );
  });

  it('com MAP_EDITOR_USER_IDS vazia, a rota não existe (404)', async () => {
    const closed = await createTestApp({
      tokenVerifier: tokens.verifier,
      env: { MAP_EDITOR_USER_IDS: [] },
    });
    try {
      const user = await explorer(randomUUID(), closed);
      const res = await user.teleport({ q: 0, r: 0 }).expect(404);
      expect(res.body.message).toBe('Rota não encontrada.');
    } finally {
      await closed.close();
    }
  });
});
