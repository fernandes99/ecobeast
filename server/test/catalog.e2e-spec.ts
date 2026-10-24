import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';

// Rotas do catálogo (.specs/backend-api/05-catalog-api.md). As contagens vêm
// do banco, não de números fixos: o dono pode acrescentar linhas.

const RESOURCES = [
  {
    path: 'skills',
    model: 'skill',
    tag: 'Técnicas',
    notFound: 'Técnica não encontrada',
  },
  {
    path: 'elements',
    model: 'element',
    tag: 'Elementos',
    notFound: 'Elemento não encontrado',
  },
  {
    path: 'traits',
    model: 'trait',
    tag: 'Traços',
    notFound: 'Traço não encontrado',
  },
  {
    path: 'temperaments',
    model: 'temperament',
    tag: 'Temperamentos',
    notFound: 'Temperamento não encontrado',
  },
  {
    path: 'stats',
    model: 'stat',
    tag: 'Stats',
    notFound: 'Stat não encontrado',
  },
  {
    path: 'growth-rates',
    model: 'growthRate',
    tag: 'Curvas de XP',
    notFound: 'Curva de XP não encontrada',
  },
  {
    path: 'rarities',
    model: 'rarity',
    tag: 'Raridades',
    notFound: 'Raridade não encontrada',
  },
  {
    path: 'status-conditions',
    model: 'statusCondition',
    tag: 'Status',
    notFound: 'Status não encontrado',
  },
  {
    path: 'skill-categories',
    model: 'skillCategory',
    tag: 'Categorias de Técnica',
    notFound: 'Categoria de Técnica não encontrada',
  },
  {
    path: 'skill-targets',
    model: 'skillTarget',
    tag: 'Alvos de Técnica',
    notFound: 'Alvo de Técnica não encontrado',
  },
  {
    path: 'skill-learn-methods',
    model: 'skillLearnMethod',
    tag: 'Métodos de aprendizado',
    notFound: 'Método de aprendizado não encontrado',
  },
  {
    path: 'effect-types',
    model: 'effectType',
    tag: 'Tipos de efeito',
    notFound: 'Tipo de efeito não encontrado',
  },
  {
    path: 'evolution-triggers',
    model: 'evolutionTrigger',
    tag: 'Gatilhos de Ascensão',
    notFound: 'Gatilho de Ascensão não encontrado',
  },
] as const;

interface CountDelegate {
  count(): Promise<number>;
  findFirst(args: object): Promise<{ id: number; slug: string } | null>;
}

describe('rotas do catálogo (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = createTestPrisma();
  });

  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  const get = (path: string) => request(app.getHttpServer()).get(path);
  const delegate = (model: string) =>
    (prisma as unknown as Record<string, CountDelegate>)[model];

  describe.each(RESOURCES)('/v1/$path', ({ path, model, notFound }) => {
    it('a lista tem o total do banco e referências em ordem de id', async () => {
      const { body } = await get(`/v1/${path}?limit=100`).expect(200);
      expect(body.count).toBe(await delegate(model).count());
      const ids = body.results.map((item: { id: number }) => item.id);
      expect(ids).toEqual([...ids].sort((a, b) => a - b));
      expect(body.results[0].url).toBe(`/v1/${path}/${body.results[0].id}`);
    });

    it('o detalhe por id e por slug é igual', async () => {
      const first = await delegate(model).findFirst({ orderBy: { id: 'asc' } });
      const byId = (await get(`/v1/${path}/${first!.id}`).expect(200)).body;
      expect(byId).toMatchObject({
        id: first!.id,
        slug: first!.slug,
        name: expect.any(String),
      });
      expect(
        (await get(`/v1/${path}/${first!.slug}`).expect(200)).body,
      ).toEqual(byId);
    });

    it('id inexistente responde 404 em pt-BR', async () => {
      const { body } = await get(`/v1/${path}/9999`).expect(404);
      expect(body.message).toBe(`${notFound}: 9999`);
    });
  });

  it('Fogo ataca Flora com multiplicador 2', async () => {
    const { body } = await get('/v1/elements/fire').expect(200);
    expect(body.color_hex).toMatch(/^#[0-9A-Fa-f]{6}$/);
    expect(body.efficacy.attacking).toContainEqual({
      element: expect.objectContaining({
        slug: 'flora',
        url: '/v1/elements/3',
      }),
      multiplier: 2,
    });
    expect(body.efficacy.defending.length).toBeGreaterThan(0);
    expect(Array.isArray(body.immune_to_status)).toBe(true);
  });

  it('Técnica 1 tem Elemento, categoria e alvo como referências e efeitos como lista', async () => {
    const { body } = await get('/v1/skills/1').expect(200);
    expect(body.element.url).toMatch(/^\/v1\/elements\/\d+$/);
    expect(body.category.url).toMatch(/^\/v1\/skill-categories\/\d+$/);
    expect(body.target.url).toMatch(/^\/v1\/skill-targets\/\d+$/);
    expect(Array.isArray(body.effects)).toBe(true);
  });

  it('efeito modify_stat mostra stat e stages, sem status', async () => {
    const effect = await prisma.skillEffect.findFirst({
      where: { effectType: { slug: 'modify_stat' } },
      orderBy: { id: 'asc' },
    });
    const { body } = await get(`/v1/skills/${effect!.skillId}`).expect(200);
    const shown = body.effects.find(
      (e: { effect_type: { slug: string } }) =>
        e.effect_type.slug === 'modify_stat',
    );
    expect(shown.stat.url).toMatch(/^\/v1\/stats\/\d+$/);
    expect(typeof shown.stages).toBe('number');
    expect(shown.status_condition).toBeNull();
  });

  it('Traço lista as espécies que podem tê-lo', async () => {
    const { body } = await get('/v1/traits/1').expect(200);
    expect(body.description).toEqual(expect.any(String));
    expect(body.species[0]).toEqual({
      species: expect.any(Object),
      slot: expect.any(Number),
      is_hidden: expect.any(Boolean),
    });
  });

  it('Temperamento tem os stats aumentado e diminuído', async () => {
    const { body } = await get('/v1/temperaments/1').expect(200);
    expect(body.increased_stat.url).toMatch(/^\/v1\/stats\/\d+$/);
    expect(body.decreased_stat.url).toMatch(/^\/v1\/stats\/\d+$/);
  });

  it('stats, curvas, raridades e status trazem os campos próprios', async () => {
    expect((await get('/v1/stats/1')).body).toMatchObject({
      short_name: expect.any(String),
      is_battle_only: false,
    });
    expect((await get('/v1/growth-rates/1')).body.xp_multiplier).toEqual(
      expect.any(Number),
    );
    expect((await get('/v1/rarities/1')).body.sort_order).toEqual(
      expect.any(Number),
    );
    const status = (await get('/v1/status-conditions/1')).body;
    expect(typeof status.is_volatile).toBe('boolean');
    expect(Array.isArray(status.immune_elements)).toBe(true);
  });

  it('GET /v1/starters devolve 1, 4 e 7, nessa ordem, sem paginação', async () => {
    const { body } = await get('/v1/starters').expect(200);
    expect(Object.keys(body)).toEqual(['results']);
    expect(
      body.results.map((r: { species: { id: number } }) => r.species.id),
    ).toEqual([1, 4, 7]);
    expect(body.results[0]).toEqual({
      sort_order: 1,
      species: expect.objectContaining({ url: '/v1/species/1' }),
    });
  });

  it('cada recurso aparece no OpenAPI na sua tag', async () => {
    const { body } = await get('/docs/openapi.json').expect(200);
    for (const { path, tag } of RESOURCES) {
      expect(body.paths[`/v1/${path}`]?.get?.tags).toEqual([tag]);
      expect(body.paths[`/v1/${path}/{idOrSlug}`]?.get?.tags).toEqual([tag]);
    }
    expect(body.paths['/v1/starters']?.get?.tags).toEqual(['Iniciais']);
  });
});
