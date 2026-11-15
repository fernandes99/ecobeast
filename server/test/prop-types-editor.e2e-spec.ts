import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

// A rota das linhas de bloqueio de um tipo de peça (.specs/free-objects/02).
// Cria um tipo zz_teste_ e uma ilha com ele; o afterAll apaga os dois.

const TEST_SLUG = 'zz_teste_bloqueio';
const square = { closed: true, points: [-10, -10, 10, -10, 10, 10, -10, 10] };

describe('linhas de bloqueio do tipo de peça (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let owner: string;
  let typeId: number;
  const editor = randomUUID();
  const islands: number[] = [];

  const call = (method: 'put' | 'post', path: string) =>
    request(app.getHttpServer())
      [method](`/v1/editor${path}`)
      .set('Authorization', `Bearer ${owner}`);

  async function cleanUp() {
    await prisma.island.deleteMany({ where: { id: { in: islands } } });
    await prisma.propType.deleteMany({ where: { slug: TEST_SLUG } });
  }

  beforeAll(async () => {
    prisma = createTestPrisma();
    await prisma.propType.deleteMany({ where: { slug: TEST_SLUG } });
    tokens = await createTestTokens();
    app = await createTestApp({
      tokenVerifier: tokens.verifier,
      env: { MAP_EDITOR_USER_IDS: [editor] },
    });
    owner = await tokens.sign(editor);
    typeId = (
      await prisma.propType.create({
        data: { slug: TEST_SLUG, name: 'Teste', variants: 1 },
      })
    ).id;
  });

  afterAll(async () => {
    await cleanUp();
    await prisma.$disconnect();
    await app.close();
  });

  it('troca as linhas do tipo, e o catálogo novo as traz', async () => {
    const response = await call('put', `/prop-types/${typeId}/blocks`)
      .send({ blocks: [square, { closed: false, points: [0, 0, 5, 5] }] })
      .expect(200);
    expect(response.body.blocks).toHaveLength(2);
    const catalog = await request(app.getHttpServer())
      .get('/v1/catalog')
      .expect(200);
    const rows = (
      catalog.body.tables.prop_type_blocks as {
        prop_type_id: number;
        position: number;
        closed: boolean;
        points: number[];
      }[]
    ).filter((row) => row.prop_type_id === typeId);
    expect(
      rows.map(({ position, closed, points }) => [position, closed, points]),
    ).toEqual([
      [0, true, square.points],
      [1, false, [0, 0, 5, 5]],
    ]);
    await call('put', `/prop-types/${typeId}/blocks`)
      .send({ blocks: [] })
      .expect(200);
    expect(
      await prisma.propTypeBlock.count({ where: { propTypeId: typeId } }),
    ).toBe(0);
  });

  it('recusa uma linha fora dos limites (400) e um tipo que não existe (404)', async () => {
    const bad = await call('put', `/prop-types/${typeId}/blocks`)
      .send({ blocks: [{ closed: true, points: [0, 0, 5, 5] }] })
      .expect(400);
    expect(bad.body.message).toBe(
      'A linha de bloqueio 1 fechada precisa ter pelo menos 3 pontos.',
    );
    await call('put', '/prop-types/999999/blocks')
      .send({ blocks: [] })
      .expect(404);
  });

  it('lista as ilhas cuja chegada passou a ficar bloqueada', async () => {
    const tiles = [
      { q: 0, r: 0, biome: 'temperate', height: 1, variant: 1 },
      { q: 1, r: 0, biome: 'temperate', height: 1, variant: 1 },
    ];
    const created = await call('post', '/islands')
      .send({
        name: 'Ilha do bloqueio',
        start: { q: 0, r: 0 },
        tiles,
        actions: [],
        objects: [],
        props: [
          {
            prop_type_id: typeId,
            q: 0,
            r: 0,
            dx: 0,
            dy: 0,
            variant: 1,
            mirrored: false,
          },
        ],
        areas: [],
      })
      .expect(201);
    const islandId = (created.body as { id: number }).id;
    islands.push(islandId);
    const response = await call('put', `/prop-types/${typeId}/blocks`)
      .send({ blocks: [square] })
      .expect(200);
    expect(response.body.blocked_starts).toEqual([
      { island_id: islandId, kind: 'draft', name: 'Ilha do bloqueio' },
    ]);
  });
});
