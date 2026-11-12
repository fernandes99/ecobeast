import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { Prisma, PrismaClient } from '../src/generated/prisma/client.js';
import { PrismaService } from '../src/prisma/prisma.service.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';
import { HERE, placeWild } from './support/wild.js';

const RUVO = 1;
const WAIT = { position: 0, action: { type: 'wait' } };
const NO_PLAYER = 'Crie seu Domador primeiro.';
const NO_HEALTHY = 'Cure sua equipe no Refúgio.';
const NO_BATTLE = 'Nenhuma batalha em andamento.';

interface HealedCreature {
  current_hp: number;
  stats: { hp: number };
  status_condition_id: number | null;
  skills: { skill_id: number; current_pp: number }[];
}

describe('Rota de cura (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let statusId: number;
  let maxPp: Map<number, number>;
  const users: string[] = [];

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({ tokenVerifier: tokens.verifier });
    statusId = (await prisma.statusCondition.findFirstOrThrow()).id;
    const skills = await prisma.skill.findMany();
    maxPp = new Map(skills.map(({ id, maxPp: pp }) => [id, pp]));
  });

  afterAll(async () => {
    await prisma.player.deleteMany({ where: { id: { in: users } } });
    await prisma.$disconnect();
    await app.close();
  });

  async function newUser() {
    const id = randomUUID();
    users.push(id);
    const auth = { Authorization: `Bearer ${await tokens.sign(id)}` };
    const http = () => request(app.getHttpServer());
    return {
      id,
      create: () => http().post('/v1/me').set(auth).send({ name: 'Ana' }),
      starter: () =>
        http().post('/v1/me/starter').set(auth).send({ species_id: RUVO }),
      read: () => http().get('/v1/me').set(auth),
      heal: () => http().post('/v1/me/heal').set(auth),
      wild: () => {
        placeWild(app, id);
        return http().post('/v1/me/board-battle/wild').set(auth).send(HERE);
      },
      act: (body: object) =>
        http().post('/v1/me/board-battle/action').set(auth).send(body),
    };
  }

  type User = Awaited<ReturnType<typeof newUser>>;

  async function userWithStarter(): Promise<User> {
    const user = await newUser();
    await user.create().expect(201);
    await user.starter().expect(200);
    return user;
  }

  async function addCreature(
    user: User,
    place: Pick<
      Prisma.CreatureInstanceUncheckedCreateInput,
      'location' | 'partySlot'
    >,
  ) {
    const row = await prisma.creatureInstance.findFirstOrThrow({
      where: { playerId: user.id },
      include: { stats: true, skills: true },
    });
    return prisma.creatureInstance.create({
      data: {
        playerId: user.id,
        speciesId: row.speciesId,
        level: row.level,
        currentXp: row.currentXp,
        currentHp: row.currentHp,
        temperamentId: row.temperamentId,
        traitId: row.traitId,
        gender: row.gender,
        bond: row.bond,
        originalPlayerId: user.id,
        caughtAt: row.caughtAt,
        stats: {
          create: row.stats.map(({ statId, genes, trainingPoints }) => ({
            statId,
            genes,
            trainingPoints,
          })),
        },
        skills: {
          create: row.skills.map(({ slot, skillId, currentPp }) => ({
            slot,
            skillId,
            currentPp,
          })),
        },
        ...place,
      },
    });
  }

  async function hurtAll(user: User): Promise<void> {
    await prisma.creatureInstance.updateMany({
      where: { playerId: user.id },
      data: { currentHp: 1, statusConditionId: statusId },
    });
    await prisma.creatureInstanceSkill.updateMany({
      where: { creature: { playerId: user.id } },
      data: { currentPp: 0 },
    });
  }

  function expectHealed(creature: HealedCreature): void {
    expect(creature.current_hp).toBe(creature.stats.hp);
    expect(creature.status_condition_id).toBeNull();
    expect(creature.skills.length).toBeGreaterThan(0);
    for (const skill of creature.skills) {
      expect(skill.current_pp).toBe(maxPp.get(skill.skill_id));
    }
  }

  async function healedParty(user: User): Promise<HealedCreature[]> {
    const { body } = await user.heal().expect(200);
    return (body as { player: { party: HealedCreature[] } }).player.party;
  }

  it('sem token, dá 401', async () => {
    await request(app.getHttpServer()).post('/v1/me/heal').expect(401);
  });

  it('sem Domador, dá 409', async () => {
    const user = await newUser();

    const { body } = await user.heal().expect(409);

    expect((body as { message: string }).message).toBe(NO_PLAYER);
  });

  it('sem equipe, dá 409', async () => {
    const user = await newUser();
    await user.create().expect(201);

    const { body } = await user.heal().expect(409);

    expect((body as { message: string }).message).toBe(NO_PLAYER);
  });

  it('devolve HP e PP ao máximo e tira o status de toda a equipe', async () => {
    const user = await userWithStarter();
    await addCreature(user, { location: 'party', partySlot: 2 });
    await hurtAll(user);

    const party = await healedParty(user);

    expect(party).toHaveLength(2);
    party.forEach(expectHealed);
  });

  it('grava a cura no banco', async () => {
    const user = await userWithStarter();
    await hurtAll(user);

    await user.heal().expect(200);

    const { body } = await user.read().expect(200);
    const { party } = (body as { player: { party: HealedCreature[] } }).player;
    party.forEach(expectHealed);
  });

  it('não mexe em quem está no Santuário', async () => {
    const user = await userWithStarter();
    const stored = await addCreature(user, {
      location: 'storage',
      partySlot: null,
    });
    await hurtAll(user);

    await user.heal().expect(200);

    const row = await prisma.creatureInstance.findUniqueOrThrow({
      where: { uid: stored.uid },
      include: { skills: true },
    });
    expect(row.currentHp).toBe(1);
    expect(row.statusConditionId).toBe(statusId);
    expect(row.skills.every((skill) => skill.currentPp === 0)).toBe(true);
  });

  it('não gasta moedas', async () => {
    const user = await userWithStarter();
    await hurtAll(user);
    const before = await prisma.player.findUniqueOrThrow({
      where: { id: user.id },
    });

    await user.heal().expect(200);

    const after = await prisma.player.findUniqueOrThrow({
      where: { id: user.id },
    });
    expect(after.coins).toBe(before.coins);
  });

  it('com a equipe curada, responde 200 sem mudar nada', async () => {
    const user = await userWithStarter();
    const before = (await user.read().expect(200)).body as object;

    const { body } = await user.heal().expect(200);

    expect(body).toEqual(before);
  });

  it('depois de uma derrota total, o jogador volta a lutar', async () => {
    const user = await userWithStarter();
    await prisma.creatureInstance.updateMany({
      where: { playerId: user.id },
      data: { currentHp: 0 },
    });
    const refused = await user.wild().expect(409);
    expect((refused.body as { message: string }).message).toBe(NO_HEALTHY);

    await user.heal().expect(200);

    await user.wild().expect(201);
  });

  it('descarta a batalha aberta sem gravar o HP dela', async () => {
    const user = await userWithStarter();
    await user.wild().expect(201);
    await hurtAll(user);

    const [creature] = await healedParty(user);

    const { body } = await user.act(WAIT).expect(404);
    expect((body as { message: string }).message).toBe(NO_BATTLE);
    const row = await prisma.creatureInstance.findFirstOrThrow({
      where: { playerId: user.id },
    });
    expect(row.currentHp).toBe(creature!.stats.hp);
  });

  it('com uma falha na gravação, ninguém é curado', async () => {
    const user = await userWithStarter();
    await hurtAll(user);
    const failure = vi
      .spyOn(app.get(PrismaService), '$transaction')
      .mockRejectedValueOnce(new Error('falha simulada'));

    await user.heal().expect(500);
    failure.mockRestore();

    const row = await prisma.creatureInstance.findFirstOrThrow({
      where: { playerId: user.id },
    });
    expect(row.currentHp).toBe(1);
  });

  it('aparece nos docs, com o cadeado', async () => {
    const { body } = await request(app.getHttpServer())
      .get('/docs/openapi.json')
      .expect(200);
    const doc = body as {
      paths: Record<string, { post: { security: object[]; tags: string[] } }>;
    };

    const operation = doc.paths['/v1/me/heal']!.post;

    expect(operation.security).toEqual([{ bearer: [] }]);
    expect(operation.tags).toEqual(['Jogador']);
  });
});
