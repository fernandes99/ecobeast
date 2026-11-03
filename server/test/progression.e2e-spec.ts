import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { BattleStore } from '../src/battle/battle.store.js';
import type { BattleEvent } from '../src/domain/battle/types.js';
import { Prisma, PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';
import { HERE, placeWild } from './support/wild.js';

const RUVO = 1;
/** Um Ruvo de nível 1 dá floor(62 · 1 ÷ 7) = 8 de XP. */
const WEAK_ENEMY = { species_id: RUVO, level: 1 };
const ENEMY_XP = 8;
const STRONG_ENEMY = { species_id: RUVO, level: 100 };
/** Nível 30 na curva Média: 30³ de XP, e o 31 começa em 31³. */
const LEVEL_30 = { level: 30, currentXp: 27_000, currentHp: 60 };
const LEVEL_31_XP = 29_791;
const MAX_TURNS = 60;

interface Battle {
  phase: string;
  result: string | null;
  player: {
    active_index: number;
    team: { hp: number; skills: { skill_id: number; current_pp: number }[] }[];
  };
}

interface Progress {
  uid: string;
  team_index: number;
  xp_gained: number;
  level_before: number;
  level_after: number;
  current_xp: number;
  level_xp: number;
  next_level_xp: number | null;
  stats_before: Record<string, number>;
  stats_after: Record<string, number>;
  evolution: { species_id: number } | null;
  learned_skill_ids: number[];
  pending_skill_ids: number[];
}

interface BattleBody {
  battle: Battle;
  events: BattleEvent[];
  progression: Progress[];
}

describe('XP e nível depois da luta (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let attacks: Set<number>;
  let sphereId: number;
  const users: string[] = [];

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({ tokenVerifier: tokens.verifier });
    const skills = await prisma.skill.findMany({
      where: { power: { gt: 0 } },
      select: { id: true },
    });
    attacks = new Set(skills.map((skill) => skill.id));
    const sphere = await prisma.item.findFirstOrThrow({
      where: { captureBonus: { not: null } },
    });
    sphereId = sphere.id;
  });

  afterAll(async () => {
    await prisma.player.deleteMany({ where: { id: { in: users } } });
    await prisma.$disconnect();
    await app.close();
  });

  async function newUser(
    data: Prisma.CreatureInstanceUncheckedUpdateManyInput,
  ) {
    const id = randomUUID();
    users.push(id);
    const auth = { Authorization: `Bearer ${await tokens.sign(id)}` };
    const http = () => request(app.getHttpServer());
    await http().post('/v1/me').set(auth).send({ name: 'Ana' }).expect(201);
    await http()
      .post('/v1/me/starter')
      .set(auth)
      .send({ species_id: RUVO })
      .expect(200);
    await prisma.creatureInstance.updateMany({ where: { playerId: id }, data });
    return {
      id,
      me: () => http().get('/v1/me').set(auth),
      start: async (enemy: object = WEAK_ENEMY) =>
        (await http().post('/v1/me/battle').set(auth).send(enemy).expect(201))
          .body as BattleBody,
      wild: async () =>
        (
          await http()
            .post('/v1/me/battle/wild')
            .set(auth)
            .send(HERE)
            .expect(201)
        ).body as BattleBody,
      act: async (body: object) =>
        (
          await http()
            .post('/v1/me/battle/action')
            .set(auth)
            .send(body)
            .expect(200)
        ).body as BattleBody,
    };
  }

  type User = Awaited<ReturnType<typeof newUser>>;

  /** Uma cópia do inicial no slot 2. */
  async function addSecondCreature(user: User): Promise<string> {
    const row = await prisma.creatureInstance.findFirstOrThrow({
      where: { playerId: user.id },
      include: { stats: true, skills: true },
    });
    const created = await prisma.creatureInstance.create({
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
        location: 'party',
        partySlot: 2,
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
      },
    });
    return created.uid;
  }

  function nextAttack(battle: Battle): object {
    const { skills } = battle.player.team[battle.player.active_index]!;
    const slot = skills.findIndex(
      (skill) => skill.current_pp > 0 && attacks.has(skill.skill_id),
    );
    return slot >= 0
      ? { type: 'skill', slot: slot + 1 }
      : { type: 'emergency' };
  }

  /** Age até a luta acabar; devolve a última resposta e todos os eventos. */
  async function playOut(
    user: User,
    first: BattleBody,
    action: (battle: Battle) => object = nextAttack,
  ): Promise<{ last: BattleBody; events: BattleEvent[] }> {
    let last = first;
    const events: BattleEvent[] = [...first.events];
    for (
      let turn = 0;
      turn < MAX_TURNS && last.battle.phase !== 'ended';
      turn++
    ) {
      last = await user.act(action(last.battle));
      events.push(...last.events);
      expect(
        last.battle.phase === 'ended' || last.progression.length === 0,
      ).toBe(true);
    }
    expect(last.battle.phase).toBe('ended');
    return { last, events };
  }

  function xpEvents(events: BattleEvent[]) {
    return events.filter((event) => event.type === 'xp_gained');
  }

  async function party(user: User) {
    return prisma.creatureInstance.findMany({
      where: { playerId: user.id },
      orderBy: { partySlot: 'asc' },
    });
  }

  it('o começo e o meio da luta trazem progression vazia', async () => {
    const user = await newUser(LEVEL_30);
    const first = await user.start();
    expect(first.progression).toEqual([]);
    await playOut(user, first);
  });

  it('quem vence sozinho recebe todo o XP, no evento e na progression', async () => {
    const user = await newUser(LEVEL_30);
    const [row] = await party(user);
    const { last, events } = await playOut(user, await user.start());

    expect(last.battle.result).toBe('victory');
    expect(xpEvents(events)).toEqual([
      { type: 'xp_gained', team_index: 0, amount: ENEMY_XP },
    ]);
    expect(last.progression).toEqual([
      expect.objectContaining({
        uid: row!.uid,
        team_index: 0,
        xp_gained: ENEMY_XP,
        level_before: 30,
        level_after: 30,
        current_xp: 27_000 + ENEMY_XP,
        level_xp: 27_000,
        next_level_xp: LEVEL_31_XP,
        evolution: null,
        learned_skill_ids: [],
        pending_skill_ids: [],
      }),
    ]);
    expect(last.progression[0]!.stats_after).toEqual(
      last.progression[0]!.stats_before,
    );
    const me = await user.me().expect(200);
    expect(me.body.player.party[0].current_xp).toBe(27_000 + ENEMY_XP);
  });

  it('subir de nível grava o nível e sobe o HP o mesmo tanto que o máximo', async () => {
    const user = await newUser({ ...LEVEL_30, currentXp: LEVEL_31_XP - 1 });
    const { last } = await playOut(user, await user.start());

    const [progress] = last.progression;
    expect(progress).toMatchObject({
      level_before: 30,
      level_after: 31,
      current_xp: LEVEL_31_XP - 1 + ENEMY_XP,
      level_xp: LEVEL_31_XP,
    });
    const hpGain = progress!.stats_after.hp! - progress!.stats_before.hp!;
    expect(hpGain).toBeGreaterThan(0);
    const [row] = await party(user);
    expect(row!.level).toBe(31);
    expect(row!.currentHp).toBe(last.battle.player.team[0]!.hp + hpGain);
    const me = await user.me().expect(200);
    expect(me.body.player.party[0].level).toBe(31);
    expect(me.body.player.party[0].stats).toEqual(progress!.stats_after);
  });

  it('dois que entraram em campo dividem o XP', async () => {
    const user = await newUser(LEVEL_30);
    await addSecondCreature(user);
    await user.start();
    const switched = await user.act({ type: 'switch', team_index: 1 });
    const { last, events } = await playOut(user, switched);

    expect(xpEvents(events)).toEqual([
      { type: 'xp_gained', team_index: 0, amount: ENEMY_XP / 2 },
      { type: 'xp_gained', team_index: 1, amount: ENEMY_XP / 2 },
    ]);
    expect(last.progression.map((item) => item.team_index)).toEqual([0, 1]);
    const rows = await party(user);
    expect(rows.map((row) => row.currentXp)).toEqual([
      27_000 + ENEMY_XP / 2,
      27_000 + ENEMY_XP / 2,
    ]);
  });

  it('quem nunca entrou em campo não recebe', async () => {
    const user = await newUser(LEVEL_30);
    await addSecondCreature(user);
    const { last } = await playOut(user, await user.start());

    expect(last.progression.map((item) => item.team_index)).toEqual([0]);
    const rows = await party(user);
    expect(rows.map((row) => row.currentXp)).toEqual([
      27_000 + ENEMY_XP,
      27_000,
    ]);
  });

  it('quem desmaiou depois de entrar em campo não recebe', async () => {
    const user = await newUser(LEVEL_30);
    await addSecondCreature(user);
    await user.start();
    const switched = await user.act({ type: 'switch', team_index: 1 });
    // O primeiro desmaia fora de campo, sem depender de sorte.
    app.get(BattleStore).get(user.id)!.state.player.team[0]!.currentHp = 0;
    const { events } = await playOut(user, switched);

    expect(xpEvents(events)).toEqual([
      { type: 'xp_gained', team_index: 1, amount: ENEMY_XP },
    ]);
  });

  it('a luta do mapa também dá XP', async () => {
    const user = await newUser(LEVEL_30);
    placeWild(app, user.id, [{ level: 1 }]);
    const { last } = await playOut(user, await user.wild());
    expect(last.progression.map((item) => item.xp_gained)).toEqual([ENEMY_XP]);
  });

  it('fugir não dá XP', async () => {
    const user = await newUser(LEVEL_30);
    const { last, events } = await playOut(user, await user.start(), () => ({
      type: 'flee',
    }));
    expect(last.battle.result).toBe('fled');
    expect(xpEvents(events)).toEqual([]);
    expect(last.progression).toEqual([]);
    const [row] = await party(user);
    expect(row!.currentXp).toBe(27_000);
  });

  it('perder não dá XP', async () => {
    const user = await newUser({ ...LEVEL_30, currentHp: 1 });
    const { last } = await playOut(user, await user.start(STRONG_ENEMY));
    expect(last.battle.result).toBe('defeat');
    expect(last.progression).toEqual([]);
    const [row] = await party(user);
    expect(row!.currentXp).toBe(27_000);
  });

  it('capturar não dá XP', async () => {
    const user = await newUser(LEVEL_30);
    await prisma.inventoryItem.create({
      data: { playerId: user.id, itemId: sphereId, quantity: 1 },
    });
    await user.start();
    // Taxa e bônus só desta luta, que fazem a captura virar certeza.
    const { catalog } = app.get(BattleStore).get(user.id)!;
    catalog.captureRates.set(RUVO, 100);
    catalog.items.get(sphereId)!.captureBonus = 1000;
    const last = await user.act({ type: 'capture', item_id: sphereId });

    expect(last.battle.result).toBe('captured');
    expect(xpEvents(last.events)).toEqual([]);
    expect(last.progression).toEqual([]);
    const [row] = await party(user);
    expect(row!.currentXp).toBe(27_000);
  });

  it('o método de aprender ao evoluir se chama "Ao evoluir"', async () => {
    const method = await prisma.skillLearnMethod.findUniqueOrThrow({
      where: { slug: 'evolution' },
    });
    expect(method.name).toBe('Ao evoluir');
  });
});
