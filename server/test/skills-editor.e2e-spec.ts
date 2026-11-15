import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

// As rotas do editor de Técnicas (.specs/skill-editor/01-skill-routes.md). Só
// cria Técnicas zz_teste_, e o afterAll apaga todas, com efeitos e aprendizes.

const TEST_PREFIX = 'zz_teste_';

interface Row {
  id: number;
  slug: string;
}

describe('editor de Técnicas (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let owner: string;
  const editor = randomUUID();
  const ids: Record<string, number> = {};

  const call = (method: 'post' | 'put', path = '') =>
    request(app.getHttpServer())
      [method](`/v1/editor/skills${path}`)
      .set('Authorization', `Bearer ${owner}`);

  function skill(slug: string) {
    return {
      slug: `${TEST_PREFIX}${slug}`,
      name: 'Técnica de teste',
      description: 'Criada pelo e2e.',
      element_id: ids.element,
      skill_category_id: ids.category,
      power: 40,
      accuracy: 100,
      max_pp: 20,
      priority: 0,
      crit_stage: 0,
      skill_target_id: ids.enemy,
      makes_contact: false,
      min_hits: 1,
      max_hits: 1,
      area_shape_id: ids.area,
      range: 1,
      pierces: false,
      ground_effect_id: null,
      ground_turns: null,
      cooldown: 0,
      effects: [
        {
          effect_type_id: ids.apply_status,
          chance: 30,
          status_condition_id: ids.status,
        },
        {
          effect_type_id: ids.modify_stat,
          chance: 100,
          skill_target_id: ids.enemy,
          stat_id: ids.stat,
          stages: -1,
        },
      ],
      learners: [
        {
          species_id: ids.species,
          skill_learn_method_id: ids.teachable,
          level: null,
        },
      ],
    };
  }

  async function create(slug: string): Promise<number> {
    const response = await call('post').send(skill(slug)).expect(201);
    return (response.body as { id: number }).id;
  }

  async function catalog() {
    const response = await request(app.getHttpServer())
      .get('/v1/catalog')
      .expect(200);
    return response.body as {
      version: string;
      tables: Record<string, Record<string, unknown>[]>;
    };
  }

  async function cleanUp() {
    const where = { skill: { slug: { startsWith: TEST_PREFIX } } };
    await prisma.speciesSkill.deleteMany({ where });
    await prisma.skillEffect.deleteMany({ where });
    await prisma.skill.deleteMany({
      where: { slug: { startsWith: TEST_PREFIX } },
    });
  }

  const bySlug = (rows: Row[], slug: string) =>
    rows.find((row) => row.slug === slug)!.id;

  beforeAll(async () => {
    prisma = createTestPrisma();
    await cleanUp();
    tokens = await createTestTokens();
    app = await createTestApp({
      tokenVerifier: tokens.verifier,
      env: { MAP_EDITOR_USER_IDS: [editor] },
    });
    owner = await tokens.sign(editor);
    const types = await prisma.effectType.findMany();
    ids.apply_status = bySlug(types, 'apply_status');
    ids.modify_stat = bySlug(types, 'modify_stat');
    ids.heal = bySlug(types, 'heal');
    ids.set_weather = bySlug(types, 'set_weather');
    ids.enemy = bySlug(await prisma.skillTarget.findMany(), 'enemy');
    ids.area = bySlug(await prisma.areaShape.findMany(), 'single');
    ids.teachable = bySlug(
      await prisma.skillLearnMethod.findMany(),
      'teachable',
    );
    ids.element = (await prisma.element.findFirstOrThrow()).id;
    ids.category = (await prisma.skillCategory.findFirstOrThrow()).id;
    ids.status = (await prisma.statusCondition.findFirstOrThrow()).id;
    ids.stat = (await prisma.stat.findFirstOrThrow()).id;
    ids.species = (await prisma.species.findFirstOrThrow()).id;
  });

  afterAll(async () => {
    await cleanUp();
    expect(
      await prisma.skill.count({
        where: { slug: { startsWith: TEST_PREFIX } },
      }),
    ).toBe(0);
    await prisma.$disconnect();
    await app.close();
  });

  describe('quem edita', () => {
    it('responde 403 a quem não está na lista', async () => {
      const stranger = await tokens.sign(randomUUID());
      await request(app.getHttpServer())
        .post('/v1/editor/skills')
        .set('Authorization', `Bearer ${stranger}`)
        .send(skill('estranho'))
        .expect(403);
    });

    it('responde 404 com MAP_EDITOR_USER_IDS vazia', async () => {
      const off = await createTestApp({
        tokenVerifier: tokens.verifier,
        env: { MAP_EDITOR_USER_IDS: [] },
      });
      try {
        const response = await request(off.getHttpServer())
          .post('/v1/editor/skills')
          .set('Authorization', `Bearer ${owner}`)
          .send(skill('desligado'))
          .expect(404);
        expect(response.body.message).toBe('Rota não encontrada.');
      } finally {
        await off.close();
      }
    });
  });

  it('cria a Técnica com os efeitos e o aprendiz, e o catálogo a traz', async () => {
    const id = await create('criada');
    const { tables } = await catalog();
    expect(tables.skills.find((row) => row.id === id)).toMatchObject({
      slug: `${TEST_PREFIX}criada`,
      power: 40,
    });
    const effects = tables.skill_effects.filter((row) => row.skill_id === id);
    expect(effects.map((row) => row.sort_order)).toEqual([1, 2]);
    expect(effects[0]).toMatchObject({ weather_id: null, stat_id: null });
    expect(tables.species_skills.filter((row) => row.skill_id === id)).toEqual([
      {
        species_id: ids.species,
        skill_id: id,
        skill_learn_method_id: ids.teachable,
        level: null,
      },
    ]);
  });

  it('cria mesmo com o contador de id atrás das linhas do painel', async () => {
    for (const table of ['skills', 'skill_effects']) {
      await prisma.$executeRawUnsafe(
        `SELECT setval(pg_get_serial_sequence('"ecobeasts"."${table}"', 'id'), 1)`,
      );
    }
    await create('contador');
  });

  it('salva o poder novo, e o catálogo muda de versão', async () => {
    const id = await create('salva');
    const before = await catalog();
    const body = { ...skill('ignorado'), power: 90, effects: [] };
    await call('put', `/${id}`).send(body).expect(200, { id });
    const after = await catalog();
    expect(after.version).not.toBe(before.version);
    const row = after.tables.skills.find((row) => row.id === id)!;
    expect(row).toMatchObject({ power: 90, slug: `${TEST_PREFIX}salva` });
    expect(
      after.tables.skill_effects.filter((row) => row.skill_id === id),
    ).toEqual([]);
  });

  it('salvar mantém o id dos efeitos que continuam', async () => {
    const id = await create('ids');
    const idsOf = async () =>
      (
        await prisma.skillEffect.findMany({
          where: { skillId: id },
          orderBy: { sortOrder: 'asc' },
        })
      ).map((row) => row.id);
    const before = await idsOf();
    const body = skill('ids');
    body.effects[0]!.chance = 60;
    await call('put', `/${id}`).send(body).expect(200);
    expect(await idsOf()).toEqual(before);

    await call('put', `/${id}`)
      .send({ ...body, effects: [body.effects[0]] })
      .expect(200);
    expect(await idsOf()).toEqual([before[0]]);
    const kept = await prisma.skillEffect.findUniqueOrThrow({
      where: { id: before[0] },
    });
    expect(kept.chance).toBe(60);
  });

  it('recusa max_hits menor que min_hits sem mudar o banco', async () => {
    const id = await create('golpes');
    const response = await call('put', `/${id}`)
      .send({ ...skill('golpes'), min_hits: 3, max_hits: 2, power: 77 })
      .expect(400);
    expect(response.body.message).toBe(
      'O mínimo de golpes não pode passar do máximo.',
    );
    const saved = await prisma.skill.findUniqueOrThrow({ where: { id } });
    expect(saved.power).toBe(40);
  });

  it('recusa um apply_status sem Estado e mantém os efeitos', async () => {
    const id = await create('sem_estado');
    const body = skill('sem_estado');
    body.effects[0] = { effect_type_id: ids.apply_status, chance: 30 } as never;
    const response = await call('put', `/${id}`).send(body).expect(400);
    expect(response.body.message).toMatch(
      /^O efeito 1 \(.+\) precisa de um Estado\.$/,
    );
    expect(await prisma.skillEffect.count({ where: { skillId: id } })).toBe(2);
  });

  it('recusa um heal com atributo', async () => {
    const body = skill('cura');
    body.effects = [
      { effect_type_id: ids.heal, chance: 100, percent: 50, stat_id: ids.stat },
    ] as never;
    const response = await call('post').send(body).expect(400);
    expect(response.body.message).toMatch(/não usa o atributo\.$/);
  });

  it('recusa o set_weather', async () => {
    const body = skill('clima');
    body.effects = [{ effect_type_id: ids.set_weather, chance: 100 }] as never;
    const response = await call('post').send(body).expect(400);
    expect(response.body.message).toBe('O clima ainda não existe.');
  });

  it('recusa um número fora do limite', async () => {
    const response = await call('post')
      .send({ ...skill('forte'), power: 300 })
      .expect(400);
    expect(response.body.message).toBe('O poder vai de 0 a 250.');
  });

  it('responde 409 a um slug repetido', async () => {
    await create('repetida');
    const response = await call('post').send(skill('repetida')).expect(409);
    expect(response.body.message).toBe('Já existe uma Técnica com esse slug.');
  });

  it('responde 404 a uma Técnica que não existe', async () => {
    const response = await call('put', '/999999')
      .send(skill('fantasma'))
      .expect(404);
    expect(response.body.message).toBe('Técnica não encontrada.');
  });
});
