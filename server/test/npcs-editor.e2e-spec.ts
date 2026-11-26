import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

// Vestir um NPC pessoa pelo editor (liora-intro/02). Grava no catálogo: guarda a
// aparência da Mira antes e a devolve no fim.

const MIRA = 4;
const RUVO_NPC = 1;

describe('Editor de NPCs (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let owner: string;
  const editor = randomUUID();
  let saved: {
    bodyTypeId: number | null;
    skinPaletteId: number | null;
    parts: {
      appearanceSlotId: number;
      appearancePartId: number;
      paletteId: number | null;
    }[];
  };

  const put = (id: number | string, body: object) =>
    request(app.getHttpServer())
      .put(`/v1/editor/npcs/${id}/appearance`)
      .set('Authorization', `Bearer ${owner}`)
      .send(body);

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({
      tokenVerifier: tokens.verifier,
      env: { MAP_EDITOR_USER_IDS: [editor] },
    });
    owner = await tokens.sign(editor);
    const mira = await prisma.npc.findUniqueOrThrow({
      where: { id: MIRA },
      include: { appearanceParts: true },
    });
    saved = {
      bodyTypeId: mira.bodyTypeId,
      skinPaletteId: mira.skinPaletteId,
      parts: mira.appearanceParts.map(
        ({ appearanceSlotId, appearancePartId, paletteId }) => ({
          appearanceSlotId,
          appearancePartId,
          paletteId,
        }),
      ),
    };
  });

  afterAll(async () => {
    await prisma.$transaction([
      prisma.npc.update({
        where: { id: MIRA },
        data: {
          bodyTypeId: saved.bodyTypeId,
          skinPaletteId: saved.skinPaletteId,
        },
      }),
      prisma.npcAppearancePart.deleteMany({ where: { npcId: MIRA } }),
      prisma.npcAppearancePart.createMany({
        data: saved.parts.map((part) => ({ npcId: MIRA, ...part })),
      }),
    ]);
    await prisma.$disconnect();
    await app.close();
  });

  it('troca a aparência da Mira e o catálogo traz a nova', async () => {
    const body = {
      body_type_id: 2,
      skin_palette_id: 5,
      parts: [
        { part_id: 2, palette_id: null },
        { part_id: 5, palette_id: 11 },
      ],
    };
    const response = await put(MIRA, body).expect(200);
    expect(response.body).toEqual({ id: MIRA, ...body });

    const catalog = await request(app.getHttpServer())
      .get('/v1/catalog')
      .expect(200);
    const tables = catalog.body.tables as Record<
      string,
      Record<string, unknown>[]
    >;
    const mira = tables.npcs.find(({ id }) => id === MIRA)!;
    expect(mira.skin_palette_id).toBe(5);
    const parts = tables.npc_appearance_parts
      .filter(({ npc_id }) => npc_id === MIRA)
      .map(({ appearance_part_id }) => appearance_part_id)
      .sort();
    expect(parts).toEqual([2, 5]);
  });

  it('veste a Mira de Menina, com a Saia do corpo Feminino (village-crowd/02)', async () => {
    const body = {
      body_type_id: 4,
      skin_palette_id: 5,
      parts: [
        { part_id: 2, palette_id: null },
        { part_id: 15, palette_id: 20 },
      ],
    };
    const response = await put(MIRA, body).expect(200);
    expect(response.body).toEqual({ id: MIRA, ...body });
  });

  it('recusa a Saia no Menino (400)', async () => {
    const response = await put(MIRA, {
      body_type_id: 3,
      skin_palette_id: 5,
      parts: [
        { part_id: 2, palette_id: null },
        { part_id: 15, palette_id: 20 },
      ],
    }).expect(400);
    expect(response.body.message).toBe(
      'A peça Saia não serve no corpo Menino.',
    );
  });

  it('recusa um NPC de Ecobeast (400)', async () => {
    const response = await put(RUVO_NPC, {
      body_type_id: 1,
      skin_palette_id: 1,
      parts: [{ part_id: 1, palette_id: null }],
    }).expect(400);
    expect(response.body.message).toBe('Esse NPC é um Ecobeast.');
  });

  it('recusa um NPC que não existe (404)', async () => {
    const body = { body_type_id: 1, skin_palette_id: 1, parts: [] };
    const missing = await put(2_147_483_647, body).expect(404);
    expect(missing.body.message).toBe('NPC não encontrado.');
    await put('abc', body).expect(404);
  });

  it('recusa a aparência sem rosto, com a mensagem do Domador (400)', async () => {
    const response = await put(MIRA, {
      body_type_id: 2,
      skin_palette_id: 1,
      parts: [],
    }).expect(400);
    expect(response.body.message).toBe('Escolha um Rosto.');
  });

  it('recusa quem não edita (403)', async () => {
    const other = await tokens.sign(randomUUID());
    await request(app.getHttpServer())
      .put(`/v1/editor/npcs/${MIRA}/appearance`)
      .set('Authorization', `Bearer ${other}`)
      .send({ body_type_id: 2, skin_palette_id: 1, parts: [] })
      .expect(403);
  });
});
