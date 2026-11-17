import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

// Trocar a voz de um NPC pelo editor (dialogue-voices/01). Grava no catálogo:
// guarda a voz do avô antes e a devolve no fim.

const GRANDPA = 3;
const MEDIUM = 4;

describe('Voz dos NPCs no editor (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let owner: string;
  const editor = randomUUID();
  let saved: number;

  const put = (id: number | string, body: object, token = owner) =>
    request(app.getHttpServer())
      .put(`/v1/editor/npcs/${id}/voice`)
      .set('Authorization', `Bearer ${token}`)
      .send(body);

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({
      tokenVerifier: tokens.verifier,
      env: { MAP_EDITOR_USER_IDS: [editor] },
    });
    owner = await tokens.sign(editor);
    saved = (await prisma.npc.findUniqueOrThrow({ where: { id: GRANDPA } }))
      .voiceId;
  });

  afterAll(async () => {
    await prisma.npc.update({
      where: { id: GRANDPA },
      data: { voiceId: saved },
    });
    await prisma.$disconnect();
    await app.close();
  });

  it('o catálogo traz as 6 vozes e a voz de cada NPC', async () => {
    const catalog = await request(app.getHttpServer())
      .get('/v1/catalog')
      .expect(200);
    const tables = catalog.body.tables as Record<
      string,
      Record<string, unknown>[]
    >;
    expect(tables.voices.map(({ slug }) => slug)).toEqual([
      'narration',
      'tamer',
      'low',
      'medium',
      'high',
      'chirp',
    ]);
    for (const npc of tables.npcs) {
      expect(typeof npc.voice_id).toBe('number');
    }
  });

  it('troca a voz do avô e o catálogo traz a nova', async () => {
    const response = await put(GRANDPA, { voice_id: MEDIUM }).expect(200);
    expect(response.body).toEqual({ id: GRANDPA, voice_id: MEDIUM });

    const catalog = await request(app.getHttpServer())
      .get('/v1/catalog')
      .expect(200);
    const npcs = catalog.body.tables.npcs as { id: number; voice_id: number }[];
    expect(npcs.find(({ id }) => id === GRANDPA)!.voice_id).toBe(MEDIUM);
  });

  it('recusa uma voz que não existe (400)', async () => {
    const response = await put(GRANDPA, { voice_id: 99 }).expect(400);
    expect(response.body.message).toBe('Essa voz não existe.');
    await put(GRANDPA, { voice_id: 'grave' }).expect(400);
  });

  it('recusa um NPC que não existe (404)', async () => {
    const response = await put(999, { voice_id: MEDIUM }).expect(404);
    expect(response.body.message).toBe('NPC não encontrado.');
    await put('abc', { voice_id: MEDIUM }).expect(404);
  });

  it('recusa quem não edita (403)', async () => {
    const other = await tokens.sign(randomUUID());
    await put(GRANDPA, { voice_id: MEDIUM }, other).expect(403);
  });
});
