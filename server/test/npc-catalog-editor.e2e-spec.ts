import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

// Criar, editar e apagar NPCs pelo F2 (island-npcs/04). Grava no catálogo: apaga
// no fim todo NPC que criou.

describe('Catálogo de NPCs pelo editor (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let owner: string;
  const editor = randomUUID();
  const created: number[] = [];
  const tag = randomUUID().slice(0, 6);

  const call = (
    method: 'post' | 'put' | 'delete',
    path: string,
    body?: object,
  ) => {
    const req = request(app.getHttpServer())
      [method](`/v1/editor/npcs${path}`)
      .set('Authorization', `Bearer ${owner}`);
    return body ? req.send(body) : req;
  };
  const create = async (body: object) => {
    const response = await call('post', '', body);
    if (response.status === 201) created.push(response.body.id);
    return response;
  };

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({
      tokenVerifier: tokens.verifier,
      env: { MAP_EDITOR_USER_IDS: [editor] },
    });
    owner = await tokens.sign(editor);
  });

  afterAll(async () => {
    await prisma.npc.deleteMany({ where: { id: { in: created } } });
    await prisma.$disconnect();
    await app.close();
  });

  it('cria um NPC Ecobeast, com o slug saído do nome', async () => {
    const response = await create({
      name: `  Pássaro ${tag} `,
      description: 'Teste',
      default_dialogue: 'Piu!',
      sprite: 'puffcoo',
    });
    expect(response.status).toBe(201);
    expect(response.body).toMatchObject({
      slug: `passaro_${tag}`,
      name: `Pássaro ${tag}`,
      sprite: 'puffcoo',
      body_type_id: null,
      default_dialogue: 'Piu!',
    });

    const again = await create({
      name: `Pássaro ${tag}`,
      description: '',
      default_dialogue: '',
      sprite: 'puffcoo',
    });
    expect(again.body.slug).toBe(`passaro_${tag}_2`);
  });

  it('cria um NPC pessoa já vestido nos lugares obrigatórios', async () => {
    const response = await create({
      name: `Dona ${tag}`,
      description: '',
      default_dialogue: '',
      body_type_id: 2,
      voice_id: 3,
    });
    expect(response.status).toBe(201);
    expect(response.body).toMatchObject({
      sprite: null,
      body_type_id: 2,
      voice_id: 3,
    });
    expect(response.body.skin_palette_id).toEqual(expect.any(Number));

    const required = await prisma.appearanceSlot.findMany({
      where: { required: true },
      select: { id: true },
    });
    const worn = await prisma.npcAppearancePart.findMany({
      where: { npcId: response.body.id },
      select: { appearanceSlotId: true },
    });
    expect(worn.map(({ appearanceSlotId }) => appearanceSlotId).sort()).toEqual(
      required.map(({ id }) => id).sort(),
    );
  });

  it('recusa sem tipo, com os dois tipos, Ecobeast que não existe e nome vazio', async () => {
    const base = { name: 'X', description: '', default_dialogue: '' };
    expect((await create(base)).status).toBe(400);
    expect(
      (await create({ ...base, sprite: 'puffcoo', body_type_id: 1 })).status,
    ).toBe(400);
    expect((await create({ ...base, sprite: 'nao_existe' })).status).toBe(400);
    expect(
      (await create({ ...base, name: '   ', sprite: 'puffcoo' })).status,
    ).toBe(400);
  });

  it('edita o nome e a espécie, mas não a espécie de uma pessoa', async () => {
    const bird = await create({
      name: `Edita ${tag}`,
      description: '',
      default_dialogue: '',
      sprite: 'puffcoo',
    });
    const edited = await call('put', `/${bird.body.id}`, {
      name: `Editado ${tag}`,
      description: 'Nova',
      default_dialogue: 'Oi',
      sprite: 'ruvo',
    });
    expect(edited.status).toBe(200);
    expect(edited.body).toMatchObject({
      slug: `edita_${tag}`,
      name: `Editado ${tag}`,
      description: 'Nova',
      sprite: 'ruvo',
    });

    const person = await create({
      name: `Pessoa ${tag}`,
      description: '',
      default_dialogue: '',
      body_type_id: 1,
    });
    const refused = await call('put', `/${person.body.id}`, {
      name: 'Y',
      description: '',
      default_dialogue: '',
      sprite: 'ruvo',
    });
    expect(refused.status).toBe(400);

    const missing = await call('put', '/2147483000', {
      name: 'Y',
      description: '',
      default_dialogue: '',
    });
    expect(missing.status).toBe(404);
  });

  it('apaga um NPC sem uso e recusa um em uso, dizendo onde', async () => {
    const used =
      (await prisma.islandNpc.findFirst({ select: { npcId: true } }))?.npcId ??
      (await prisma.quest.findFirst({ select: { npcId: true } }))?.npcId;
    if (used !== undefined) {
      const refused = await call('delete', `/${used}`);
      expect(refused.status).toBe(409);
      expect(refused.body.message).toContain('Esse NPC está em uso');
      expect(
        await prisma.npc.findUnique({ where: { id: used } }),
      ).not.toBeNull();
    }

    const loose = await create({
      name: `Apaga ${tag}`,
      description: '',
      default_dialogue: '',
      body_type_id: 2,
    });
    const removed = await call('delete', `/${loose.body.id}`);
    expect(removed.status).toBe(200);
    expect(removed.body).toEqual({ id: loose.body.id });
    expect(
      await prisma.npc.findUnique({ where: { id: loose.body.id } }),
    ).toBeNull();
    expect(
      await prisma.npcAppearancePart.count({ where: { npcId: loose.body.id } }),
    ).toBe(0);
  });
});
