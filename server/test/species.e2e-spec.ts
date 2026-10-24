import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';

// Rotas de espécies (.specs/backend-api/04-species-api.md). Conferem formato e
// ids estáveis, não valores de balanceamento.

describe('rotas de espécies (e2e)', () => {
  let app: INestApplication<App>;
  let speciesCount: number;

  beforeAll(async () => {
    app = await createTestApp();
    const prisma = createTestPrisma();
    speciesCount = await prisma.species.count();
    await prisma.$disconnect();
  });

  afterAll(async () => {
    await app.close();
  });

  const get = (path: string) => request(app.getHttpServer()).get(path);

  it('GET /v1/species lista em ordem de id, com o total', async () => {
    const { body } = await get('/v1/species').expect(200);
    expect(body.count).toBe(speciesCount);
    expect(body.previous).toBeNull();
    const ids = body.results.map((item: { id: number }) => item.id);
    expect(ids).toEqual([...ids].sort((a, b) => a - b));
    expect(body.results[0]).toEqual({
      id: 1,
      slug: 'fagulho',
      name: expect.any(String),
      url: '/v1/species/1',
    });
  });

  it('GET /v1/species?limit=2&offset=2 pagina com next e previous', async () => {
    const { body } = await get('/v1/species?limit=2&offset=2').expect(200);
    expect(body.results).toHaveLength(2);
    expect(body.next).toBe('/v1/species?limit=2&offset=4');
    expect(body.previous).toBe('/v1/species?limit=2&offset=0');
  });

  it('offset além do total devolve lista vazia', async () => {
    const { body } = await get('/v1/species?offset=1000').expect(200);
    expect(body.results).toEqual([]);
    expect(body.count).toBe(speciesCount);
  });

  it.each(['limit=0', 'limit=101', 'limit=abc'])(
    '?%s responde 400 em pt-BR',
    async (query) => {
      const { body } = await get(`/v1/species?${query}`).expect(400);
      expect(body.message).toContain('limit deve ser um inteiro de 1 a 100');
    },
  );

  it('?offset=-1 responde 400 em pt-BR', async () => {
    const { body } = await get('/v1/species?offset=-1').expect(400);
    expect(body.message).toContain(
      'offset deve ser um inteiro maior ou igual a 0',
    );
  });

  it('detalhe por id, por slug e por slug em maiúsculas é igual', async () => {
    const byId = (await get('/v1/species/1').expect(200)).body;
    expect((await get('/v1/species/fagulho').expect(200)).body).toEqual(byId);
    expect((await get('/v1/species/FAGULHO').expect(200)).body).toEqual(byId);
  });

  it.each(['9999', 'xyz', '99999999999'])(
    'GET /v1/species/%s responde 404',
    async (param) => {
      const { body } = await get(`/v1/species/${param}`).expect(404);
      expect(body.message).toBe(`Espécie não encontrada: ${param}`);
    },
  );

  it('detalhe tem os campos e as referências do RF-07', async () => {
    const { body } = await get('/v1/species/1').expect(200);
    expect(Object.keys(body).sort()).toEqual(
      [
        'id',
        'slug',
        'name',
        'description',
        'height_m',
        'weight_kg',
        'gender_ratio',
        'capture_rate',
        'base_xp_yield',
        'growth_rate',
        'rarity',
        'evolves_from',
        'elements',
        'stats',
        'traits',
      ].sort(),
    );
    expect(body.growth_rate.url).toMatch(/^\/v1\/growth-rates\/\d+$/);
    expect(body.rarity.url).toMatch(/^\/v1\/rarities\/\d+$/);
    expect(body.evolves_from).toBeNull();
    expect(body.stats.length).toBeGreaterThan(0);
    expect(body.stats[0]).toEqual({
      stat: expect.any(Object),
      base_value: expect.any(Number),
      training_yield: expect.any(Number),
    });
    expect(body.traits[0]).toEqual({
      slot: 1,
      is_hidden: false,
      trait: expect.any(Object),
    });
  });

  it('Infernolobo (3): fire no slot 1, shadow no slot 2, ascende de 2', async () => {
    const { body } = await get('/v1/species/3').expect(200);
    const elements = body.elements.map(
      (e: { slot: number; element: { slug: string } }) => [
        e.slot,
        e.element.slug,
      ],
    );
    expect(elements).toEqual([
      [1, 'fire'],
      [2, 'shadow'],
    ]);
    expect(body.evolves_from.id).toBe(2);
    expect(body.evolves_from.url).toBe('/v1/species/2');
  });

  it('GET /v1/species/1/skills tem Técnica por nível no nível 1', async () => {
    const { body } = await get('/v1/species/1/skills').expect(200);
    expect(body.species.id).toBe(1);
    expect(body.skills).toContainEqual({
      skill: expect.objectContaining({
        url: expect.stringMatching(/^\/v1\/skills\/\d+$/),
      }),
      learn_method: expect.objectContaining({ slug: 'level_up' }),
      level: 1,
    });
  });

  it('GET /v1/species/fagulho/skills aceita slug; espécie inexistente dá 404', async () => {
    await get('/v1/species/fagulho/skills').expect(200);
    await get('/v1/species/xyz/skills').expect(404);
  });

  it('GET /v1/species/2/evolutions devolve a linha inteira a partir de Fagulho', async () => {
    const { body } = await get('/v1/species/2/evolutions').expect(200);
    expect(body.chain.species.id).toBe(1);
    const second = body.chain.evolves_to[0];
    expect(second.trigger.slug).toBe('level');
    expect(second.node.species.id).toBe(2);
    expect(second.node.evolves_to[0].node.species.id).toBe(3);
    expect(second.node.evolves_to[0].node.evolves_to).toEqual([]);
  });

  it('pedir Fagulho, Brasalobo ou Infernolobo devolve a mesma linha', async () => {
    const lines = await Promise.all(
      [1, 2, 3].map(
        async (id) => (await get(`/v1/species/${id}/evolutions`)).body,
      ),
    );
    expect(lines[1]).toEqual(lines[0]);
    expect(lines[2]).toEqual(lines[0]);
  });

  it('as rotas aparecem no OpenAPI na tag "Espécies"', async () => {
    const { body } = await get('/docs/openapi.json').expect(200);
    const paths = [
      '/v1/species',
      '/v1/species/{idOrSlug}',
      '/v1/species/{idOrSlug}/skills',
      '/v1/species/{idOrSlug}/evolutions',
    ];
    for (const path of paths) {
      expect(body.paths[path]?.get?.tags).toEqual(['Espécies']);
    }
  });
});

describe('limite de chamadas (e2e)', () => {
  let app: INestApplication<App>;

  beforeAll(async () => {
    app = await createTestApp({ env: { THROTTLE_LIMIT: 3 } });
  });

  afterAll(async () => {
    await app.close();
  });

  it('com THROTTLE_LIMIT=3, a 4ª chamada seguida responde 429', async () => {
    for (let i = 0; i < 3; i++) {
      await request(app.getHttpServer()).get('/v1/species?limit=1').expect(200);
    }
    await request(app.getHttpServer()).get('/v1/species?limit=1').expect(429);
  });
});
