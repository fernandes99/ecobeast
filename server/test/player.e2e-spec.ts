import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

const FAGULHO = 1;
const BRASALOBO = 2;
const INVALID_NAME = 'Use de 2 a 16 letras, números ou espaços.';
const CREATURE_NOT_FOUND = 'Ecobeast não encontrado.';
const STAT_KEYS = ['atk', 'def', 'hp', 'sp_atk', 'sp_def', 'spd'];

interface Creature {
  uid: string;
  species_id: number;
  nickname: string;
  level: number;
  current_xp: number;
  level_xp: number;
  next_level_xp: number | null;
  current_hp: number;
  stats: Record<string, number>;
  genes: Record<string, number>;
  training_points: Record<string, number>;
  temperament_id: number;
  trait_id: number;
  gender: string;
  is_prismatic: boolean;
  bond: number;
  skills: { skill_id: number; current_pp: number }[];
  status_condition_id: number | null;
  held_item_id: number | null;
  original_player_id: string;
  caught_at: string;
  caught_zone_id: number | null;
}

describe('Rotas do jogador (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  const users: string[] = [];

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

  /** Um usuário novo, com as chamadas já assinadas por ele. */
  async function newUser() {
    const id = randomUUID();
    users.push(id);
    const auth = { Authorization: `Bearer ${await tokens.sign(id)}` };
    const server = () => request(app.getHttpServer());
    return {
      id,
      read: () => server().get('/v1/me').set(auth),
      create: (body: object) => server().post('/v1/me').set(auth).send(body),
      starter: (body: object) =>
        server().post('/v1/me/starter').set(auth).send(body),
      remove: () => server().delete('/v1/me').set(auth),
      nickname: (uid: string, body: object) =>
        server().patch(`/v1/me/creatures/${uid}`).set(auth).send(body),
    };
  }

  /** Um usuário novo com Domador e inicial; devolve o `uid` da criatura. */
  async function userWithStarter() {
    const user = await newUser();
    await user.create({ name: 'Ana' }).expect(201);
    const res = await user.starter({ species_id: FAGULHO }).expect(200);
    return { user, uid: (res.body.player.party[0] as Creature).uid };
  }

  it('sem token, cada rota dá 401', async () => {
    const server = () => request(app.getHttpServer());
    const responses = await Promise.all([
      server().get('/v1/me'),
      server().post('/v1/me').send({ name: 'Ana' }),
      server().post('/v1/me/starter').send({ species_id: FAGULHO }),
      server().delete('/v1/me'),
      server().patch(`/v1/me/creatures/${randomUUID()}`).send({ nickname: '' }),
    ]);
    for (const res of responses) {
      expect(res.status).toBe(401);
      expect(res.body.message).toBe('Sessão inválida. Entre de novo.');
    }
  });

  it('um token de outra chave dá 401', async () => {
    const other = await createTestTokens();
    await request(app.getHttpServer())
      .get('/v1/me')
      .set('Authorization', `Bearer ${await other.sign(randomUUID())}`)
      .expect(401);
  });

  it('um usuário novo não tem Domador', async () => {
    const user = await newUser();
    const res = await user.read().expect(200);
    expect(res.body).toEqual({ player: null });
  });

  it('cria o Domador com o nome normalizado e 1000 moedas', async () => {
    const user = await newUser();
    const res = await user.create({ name: '  Ana   Maria ' }).expect(201);

    expect(res.body.player).toEqual({
      id: user.id,
      name: 'Ana Maria',
      level: 1,
      coins: 1000,
      created_at: expect.stringMatching(
        /^\d{4}-\d{2}-\d{2}T[\d:.]+Z$/,
      ) as string,
      party: [],
    });
  });

  it('um segundo POST /v1/me dá 409', async () => {
    const user = await newUser();
    await user.create({ name: 'Ana' }).expect(201);
    const res = await user.create({ name: 'Outra' }).expect(409);
    expect(res.body.message).toBe('Você já tem um Domador.');
    const read = await user.read().expect(200);
    expect(read.body.player.name).toBe('Ana');
  });

  it('dois POST /v1/me ao mesmo tempo criam um Domador só', async () => {
    const user = await newUser();
    const statuses = (
      await Promise.all([
        user.create({ name: 'Ana' }),
        user.create({ name: 'Ana' }),
      ])
    )
      .map((res) => res.status)
      .sort();
    expect(statuses).toEqual([201, 409]);
  });

  it.each([
    ['curto demais', 'A'],
    ['longo demais', 'A'.repeat(17)],
    ['com símbolo', 'Ana!'],
    ['só de espaços', '     '],
  ])('recusa nome %s', async (_case, name) => {
    const user = await newUser();
    const res = await user.create({ name }).expect(400);
    expect(res.body.message).toBe(INVALID_NAME);
  });

  it('recusa corpo sem nome ou com nome que não é texto', async () => {
    const user = await newUser();
    const empty = await user.create({}).expect(400);
    expect(empty.body.message).toBe(INVALID_NAME);
    await user.create({ name: 123 }).expect(400);
  });

  it('aceita letras acentuadas e números no nome', async () => {
    const user = await newUser();
    const res = await user.create({ name: 'João 2' }).expect(201);
    expect(res.body.player.name).toBe('João 2');
  });

  it('escolher o inicial antes do Domador dá 409', async () => {
    const user = await newUser();
    const res = await user.starter({ species_id: FAGULHO }).expect(409);
    expect(res.body.message).toBe('Crie seu Domador primeiro.');
  });

  it('espécie fora dos iniciais dá 400', async () => {
    const user = await newUser();
    await user.create({ name: 'Ana' }).expect(201);
    const res = await user.starter({ species_id: BRASALOBO }).expect(400);
    expect(res.body.message).toBe('Esse Ecobeast não pode ser escolhido.');
  });

  it('species_id inválido dá 400', async () => {
    const user = await newUser();
    await user.create({ name: 'Ana' }).expect(201);
    await user.starter({ species_id: 'um' }).expect(400);
    await user.starter({}).expect(400);
  });

  it('escolhe o inicial, grava no banco e devolve o mesmo na leitura', async () => {
    const user = await newUser();
    await user.create({ name: 'Ana' }).expect(201);

    const res = await user.starter({ species_id: FAGULHO }).expect(200);
    const party = res.body.player.party as Creature[];
    expect(party).toHaveLength(1);
    const creature = party[0]!;

    expect(creature.species_id).toBe(FAGULHO);
    expect(creature.nickname).toBe('');
    expect(creature.level).toBe(5);
    expect(creature.is_prismatic).toBe(false);
    expect(creature.bond).toBe(70);
    expect(creature.original_player_id).toBe(user.id);
    expect(creature.status_condition_id).toBeNull();
    expect(creature.held_item_id).toBeNull();
    expect(creature.caught_zone_id).toBeNull();
    expect(['male', 'female', 'none']).toContain(creature.gender);

    expect(Object.keys(creature.stats).sort()).toEqual(STAT_KEYS);
    expect(Object.keys(creature.genes).sort()).toEqual(STAT_KEYS);
    expect(Object.keys(creature.training_points).sort()).toEqual(STAT_KEYS);
    for (const key of STAT_KEYS) {
      expect(creature.genes[key]).toBeGreaterThanOrEqual(0);
      expect(creature.genes[key]).toBeLessThanOrEqual(31);
      expect(creature.training_points[key]).toBe(0);
      expect(creature.stats[key]).toBeGreaterThan(0);
    }
    expect(creature.current_hp).toBe(creature.stats['hp']);
    expect(creature.skills.length).toBeGreaterThanOrEqual(1);
    expect(creature.skills.length).toBeLessThanOrEqual(4);

    const read = await user.read().expect(200);
    expect(read.body.player).toEqual(res.body.player);

    const row = await prisma.creatureInstance.findMany({
      where: { playerId: user.id },
      include: { stats: true, skills: true },
    });
    expect(row).toHaveLength(1);
    expect(row[0]!.location).toBe('party');
    expect(row[0]!.partySlot).toBe(1);
    expect(row[0]!.caughtZoneId).toBeNull();
    expect(row[0]!.stats).toHaveLength(6);
    expect(row[0]!.skills).toHaveLength(creature.skills.length);
  });

  it('as Técnicas vêm com o PP cheio e o Traço não é oculto', async () => {
    const user = await newUser();
    await user.create({ name: 'Ana' }).expect(201);
    const res = await user.starter({ species_id: FAGULHO }).expect(200);
    const creature = res.body.player.party[0] as Creature;

    const skills = await prisma.skill.findMany({
      where: { id: { in: creature.skills.map((skill) => skill.skill_id) } },
    });
    for (const slot of creature.skills) {
      const skill = skills.find((row) => row.id === slot.skill_id);
      expect(slot.current_pp).toBe(skill?.maxPp);
    }
    const trait = await prisma.speciesTrait.findFirstOrThrow({
      where: { speciesId: FAGULHO, traitId: creature.trait_id },
    });
    expect(trait.isHidden).toBe(false);
  });

  it('um segundo inicial dá 409', async () => {
    const user = await newUser();
    await user.create({ name: 'Ana' }).expect(201);
    await user.starter({ species_id: FAGULHO }).expect(200);
    const res = await user.starter({ species_id: FAGULHO }).expect(409);
    expect(res.body.message).toBe('Você já escolheu seu Ecobeast.');
  });

  it('dois iniciais ao mesmo tempo terminam com uma criatura só', async () => {
    const user = await newUser();
    await user.create({ name: 'Ana' }).expect(201);

    const responses = await Promise.all([
      user.starter({ species_id: FAGULHO }),
      user.starter({ species_id: FAGULHO }),
    ]);

    expect(responses.map((res) => res.status).sort()).toEqual([200, 409]);
    const loser = responses.find((res) => res.status === 409);
    expect(loser?.body.message).toBe('Você já escolheu seu Ecobeast.');
    const count = await prisma.creatureInstance.count({
      where: { playerId: user.id },
    });
    expect(count).toBe(1);
  });

  it('o inicial nasce no começo do nível e traz o XP do próximo', async () => {
    const user = await newUser();
    await user.create({ name: 'Ana' }).expect(201);
    const res = await user.starter({ species_id: FAGULHO }).expect(200);
    const creature = res.body.player.party[0] as Creature;

    expect(creature.level_xp).toBe(creature.current_xp);
    expect(creature.next_level_xp).toBeGreaterThan(creature.level_xp);
  });

  it('grava o apelido normalizado e devolve o jogador', async () => {
    const { user, uid } = await userWithStarter();

    const res = await user
      .nickname(uid, { nickname: '  Chama   Viva ' })
      .expect(200);
    expect(res.body.player.party[0].nickname).toBe('Chama Viva');

    const read = await user.read().expect(200);
    expect(read.body.player).toEqual(res.body.player);
  });

  it.each([
    ['vazio', ''],
    ['só de espaços', '   '],
  ])('apelido %s remove o apelido', async (_case, nickname) => {
    const { user, uid } = await userWithStarter();
    await user.nickname(uid, { nickname: 'Brasa' }).expect(200);

    const res = await user.nickname(uid, { nickname }).expect(200);

    expect(res.body.player.party[0].nickname).toBe('');
    const row = await prisma.creatureInstance.findUniqueOrThrow({
      where: { uid },
    });
    expect(row.nickname).toBeNull();
  });

  it.each([
    ['curto demais', 'A'],
    ['longo demais', 'A'.repeat(17)],
    ['com símbolo', 'Fogo!'],
  ])('recusa apelido %s', async (_case, nickname) => {
    const { user, uid } = await userWithStarter();
    const res = await user.nickname(uid, { nickname }).expect(400);
    expect(res.body.message).toBe(INVALID_NAME);
  });

  it('recusa corpo sem apelido ou com apelido que não é texto', async () => {
    const { user, uid } = await userWithStarter();
    const empty = await user.nickname(uid, {}).expect(400);
    expect(empty.body.message).toBe(INVALID_NAME);
    const number = await user.nickname(uid, { nickname: 5 }).expect(400);
    expect(number.body.message).toBe(INVALID_NAME);
  });

  it('a criatura de outro Domador dá 404 e não muda', async () => {
    const { uid } = await userWithStarter();
    const { user: other } = await userWithStarter();

    const res = await other.nickname(uid, { nickname: 'Roubado' }).expect(404);

    expect(res.body.message).toBe(CREATURE_NOT_FOUND);
    const row = await prisma.creatureInstance.findUniqueOrThrow({
      where: { uid },
    });
    expect(row.nickname).toBeNull();
  });

  it.each([
    ['que não existe', randomUUID()],
    ['malformado', 'abc'],
  ])('uid %s dá 404', async (_case, uid) => {
    const { user } = await userWithStarter();
    const res = await user.nickname(uid, { nickname: 'Brasa' }).expect(404);
    expect(res.body.message).toBe(CREATURE_NOT_FOUND);
  });

  it('um Domador não enxerga o outro', async () => {
    const ana = await newUser();
    const bia = await newUser();
    await ana.create({ name: 'Ana' }).expect(201);
    const res = await bia.read().expect(200);
    expect(res.body.player).toBeNull();
  });

  it('DELETE /v1/me apaga o Domador e o que é dele', async () => {
    const user = await newUser();
    await user.create({ name: 'Ana' }).expect(201);
    await user.starter({ species_id: FAGULHO }).expect(200);

    await user.remove().expect(204);

    const read = await user.read().expect(200);
    expect(read.body).toEqual({ player: null });
    const count = await prisma.creatureInstance.count({
      where: { playerId: user.id },
    });
    expect(count).toBe(0);
  });

  it('DELETE /v1/me sem Domador também dá 204', async () => {
    const user = await newUser();
    await user.remove().expect(204);
  });

  it('as rotas aparecem na documentação com o cadeado', async () => {
    const doc = await request(app.getHttpServer())
      .get('/docs/openapi.json')
      .expect(200);
    const me = doc.body.paths['/v1/me'];
    for (const operation of [me.get, me.post, me.delete]) {
      expect(operation.tags).toEqual(['Jogador']);
      expect(operation.security).toEqual([{ bearer: [] }]);
    }
    expect(doc.body.paths['/v1/me/starter'].post.security).toEqual([
      { bearer: [] },
    ]);
    const nickname = doc.body.paths['/v1/me/creatures/{uid}'].patch;
    expect(nickname.tags).toEqual(['Jogador']);
    expect(nickname.security).toEqual([{ bearer: [] }]);
    const creature = doc.body.components.schemas.CreatureDto.properties;
    expect(creature.level_xp.description).toBeTruthy();
    expect(creature.next_level_xp.nullable).toBe(true);
  });
});
