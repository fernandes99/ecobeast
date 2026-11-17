import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

const PER_CALL = 'Mande de 1 a 50 Marcos por vez.';
const LIMIT = 'O Domador pode ter até 2.000 Marcos.';

describe('Marcos da história (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  const users: string[] = [];

  async function newUser(withPlayer = true) {
    const id = randomUUID();
    users.push(id);
    const auth = { Authorization: `Bearer ${await tokens.sign(id)}` };
    const http = () => request(app.getHttpServer());
    if (withPlayer) {
      await http().post('/v1/me').set(auth).send({ name: 'Ana' }).expect(201);
    }
    return {
      id,
      auth,
      add: (body: unknown) =>
        http()
          .post('/v1/me/story/marks')
          .set(auth)
          .send(body as object),
      marks: async () => {
        const { body } = await http().get('/v1/me').set(auth).expect(200);
        return (body as { player: { story_marks: string[] } }).player
          .story_marks;
      },
      reset: () => http().delete('/v1/me').set(auth),
      create: () => http().post('/v1/me').set(auth).send({ name: 'Ana' }),
    };
  }

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

  it('sem token, dá 401', async () => {
    await request(app.getHttpServer())
      .post('/v1/me/story/marks')
      .send({ marks: ['avo_chega'] })
      .expect(401);
  });

  it('começa sem Marcos', async () => {
    const user = await newUser();
    expect(await user.marks()).toEqual([]);
  });

  it('liga, devolve em ordem alfabética e aceita repetidos', async () => {
    const user = await newUser();
    const first = await user
      .add({ marks: ['sabe_da_mira', 'avo_chega', 'avo_chega'] })
      .expect(201);
    expect(first.body).toEqual({ story_marks: ['avo_chega', 'sabe_da_mira'] });
    const again = await user.add({ marks: ['avo_chega'] }).expect(201);
    expect(again.body).toEqual({ story_marks: ['avo_chega', 'sabe_da_mira'] });
    expect(await user.marks()).toEqual(['avo_chega', 'sabe_da_mira']);
  });

  it.each([
    [{}, PER_CALL],
    [{ marks: 'avo_chega' }, PER_CALL],
    [{ marks: [] }, PER_CALL],
    [{ marks: Array.from({ length: 51 }, (_, i) => `m${i}`) }, PER_CALL],
    [
      { marks: ['ok', 'Avo Chega'] },
      'O Marco "Avo Chega" tem caracteres inválidos.',
    ],
    [{ marks: [''] }, 'O Marco "" tem caracteres inválidos.'],
    [
      { marks: ['a'.repeat(49)] },
      `O Marco "${'a'.repeat(48)}" tem caracteres inválidos.`,
    ],
    [{ marks: [7] }, 'O Marco "7" tem caracteres inválidos.'],
  ])('recusa %j', async (body, message) => {
    const user = await newUser();
    const { body: error } = await user.add(body).expect(400);
    expect((error as { message: string }).message).toBe(message);
    expect(await user.marks()).toEqual([]);
  });

  it('recusa passar de 2.000 Marcos sem gravar nada', async () => {
    const user = await newUser();
    await prisma.playerStoryMark.createMany({
      data: Array.from({ length: 1999 }, (_, i) => ({
        playerId: user.id,
        mark: `m${i}`,
      })),
    });
    const { body } = await user
      .add({ marks: ['novo_a', 'novo_b'] })
      .expect(400);
    expect((body as { message: string }).message).toBe(LIMIT);
    const ok = await user.add({ marks: ['m0', 'novo_a'] }).expect(201);
    expect((ok.body as { story_marks: string[] }).story_marks).toHaveLength(
      2000,
    );
  });

  it('sem Domador, dá 409', async () => {
    const user = await newUser(false);
    const { body } = await user.add({ marks: ['avo_chega'] }).expect(409);
    expect((body as { message: string }).message).toBe(
      'Crie seu Domador primeiro.',
    );
  });

  it('apagar o progresso leva os Marcos junto', async () => {
    const user = await newUser();
    await user.add({ marks: ['avo_chega'] }).expect(201);
    await user.reset().expect(204);
    await user.create().expect(201);
    expect(await user.marks()).toEqual([]);
  });
});
