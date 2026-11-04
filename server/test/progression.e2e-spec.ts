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
      evolve: (uid: string, body: object) =>
        http().post(`/v1/me/creatures/${uid}/evolution`).set(auth).send(body),
      learn: (uid: string, body: object) =>
        http().post(`/v1/me/creatures/${uid}/skills`).set(auth).send(body),
      wildGod: (server: INestApplication<App> = app) =>
        request(server.getHttpServer())
          .post('/v1/me/battle/wild')
          .set(auth)
          .send({ ...HERE, god: true }),
      almostLevelUp: (server: INestApplication<App> = app) =>
        request(server.getHttpServer()).post('/v1/me/debug/xp').set(auth),
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

  describe('Técnicas e evolução', () => {
    /** No 16, o Ruvo pode virar Ruvak (2), que aprende a 6 ao evoluir. */
    const RUVAK = 2;
    /**
     * No 34, o Ruvak aprende a Técnica 9 e ainda não evolui (só no 36); o
     * inicial sabe a 1 e a 2. Um Ruvo no 34 receberia a oferta de evolução.
     */
    const BEFORE_34 = {
      speciesId: RUVAK,
      level: 33,
      currentXp: 34 ** 3 - 1,
      currentHp: 80,
    };
    const AT_34 = 9;
    const RUVAK_EVOLUTION_SKILL = 6;
    const BEFORE_16 = { level: 15, currentXp: 16 ** 3 - 1, currentHp: 40 };

    async function skillsOf(uid: string) {
      const rows = await prisma.creatureInstanceSkill.findMany({
        where: { creatureUid: uid },
        orderBy: { slot: 'asc' },
      });
      return rows.map(({ slot, skillId, currentPp }) => ({
        slot,
        skillId,
        currentPp,
      }));
    }

    /** Completa as 4 vagas com as Técnicas 3 e 7. */
    async function fillSkills(uid: string): Promise<void> {
      await prisma.creatureInstanceSkill.createMany({
        data: [
          { creatureUid: uid, slot: 3, skillId: 3, currentPp: 5 },
          { creatureUid: uid, slot: 4, skillId: 7, currentPp: 5 },
        ],
      });
    }

    async function maxPp(skillId: number): Promise<number> {
      return (await prisma.skill.findUniqueOrThrow({ where: { id: skillId } }))
        .maxPp;
    }

    async function win(user: User): Promise<BattleBody> {
      return (await playOut(user, await user.start())).last;
    }

    it('com vaga, a Técnica do nível é aprendida com o PP cheio', async () => {
      const user = await newUser(BEFORE_34);
      const [row] = await party(user);
      const last = await win(user);

      expect(last.progression[0]).toMatchObject({
        evolution: null,
        learned_skill_ids: [AT_34],
        pending_skill_ids: [],
      });
      expect(await skillsOf(row!.uid)).toContainEqual({
        slot: 3,
        skillId: AT_34,
        currentPp: await maxPp(AT_34),
      });
    });

    it('com 4, a Técnica fica pendente e esquecer uma põe a nova no lugar', async () => {
      const user = await newUser(BEFORE_34);
      const [row] = await party(user);
      await fillSkills(row!.uid);
      const last = await win(user);

      expect(last.progression[0]).toMatchObject({
        learned_skill_ids: [],
        pending_skill_ids: [AT_34],
      });
      expect((await skillsOf(row!.uid)).map((skill) => skill.skillId)).toEqual([
        1, 2, 3, 7,
      ]);

      const res = await user
        .learn(row!.uid, { skill_id: AT_34, forget_skill_id: 2 })
        .expect(200);
      expect(res.body.pending_skill_ids).toEqual([]);
      expect(
        res.body.creature.skills.map(
          (skill: { skill_id: number }) => skill.skill_id,
        ),
      ).toEqual([1, AT_34, 3, 7]);
      expect((await skillsOf(row!.uid))[1]).toEqual({
        slot: 2,
        skillId: AT_34,
        currentPp: await maxPp(AT_34),
      });
    });

    it('não aprender mantém as 4, e a mesma escolha de novo dá 404', async () => {
      const user = await newUser(BEFORE_34);
      const [row] = await party(user);
      await fillSkills(row!.uid);
      await win(user);

      await user
        .learn(row!.uid, { skill_id: AT_34, forget_skill_id: null })
        .expect(200);
      expect((await skillsOf(row!.uid)).map((skill) => skill.skillId)).toEqual([
        1, 2, 3, 7,
      ]);
      const again = await user
        .learn(row!.uid, { skill_id: AT_34, forget_skill_id: null })
        .expect(404);
      expect(again.body.message).toBe('Essa escolha não está mais disponível.');
    });

    it('esquecer uma Técnica que ele não conhece dá 400, e a escolha continua', async () => {
      const user = await newUser(BEFORE_34);
      const [row] = await party(user);
      await fillSkills(row!.uid);
      await win(user);

      const res = await user
        .learn(row!.uid, { skill_id: AT_34, forget_skill_id: 999 })
        .expect(400);
      expect(res.body.message).toBe('Esse Ecobeast não conhece essa Técnica.');
      await user
        .learn(row!.uid, { skill_id: AT_34, forget_skill_id: 1 })
        .expect(200);
    });

    it('corpo sem forget_skill_id ou sem accept dá 400', async () => {
      const user = await newUser(BEFORE_34);
      const [row] = await party(user);
      await user.learn(row!.uid, { skill_id: AT_34 }).expect(400);
      await user.evolve(row!.uid, {}).expect(400);
    });

    it('uma escolha da luta anterior dá 404 depois de outra vitória', async () => {
      const user = await newUser(BEFORE_34);
      const [row] = await party(user);
      await fillSkills(row!.uid);
      await win(user);
      await win(user);

      await user
        .learn(row!.uid, { skill_id: AT_34, forget_skill_id: 1 })
        .expect(404);
    });

    it('no nível de evolução, a vitória oferece a espécie nova e nada de Técnicas', async () => {
      const user = await newUser(BEFORE_16);
      const last = await win(user);

      expect(last.progression[0]).toMatchObject({
        level_after: 16,
        evolution: { species_id: RUVAK },
        learned_skill_ids: [],
        pending_skill_ids: [],
      });
    });

    it('aceitar transforma em Ruvak, com o resto igual e a Técnica de evolução', async () => {
      const user = await newUser({ ...BEFORE_16, nickname: 'Fogo' });
      const [before] = await party(user);
      await win(user);
      const [beaten] = await party(user);

      const res = await user.evolve(before!.uid, { accept: true }).expect(200);
      expect(res.body.learned_skill_ids).toEqual([RUVAK_EVOLUTION_SKILL]);
      expect(res.body.pending_skill_ids).toEqual([]);
      const [after] = await party(user);
      expect(after).toMatchObject({
        speciesId: RUVAK,
        nickname: 'Fogo',
        level: 16,
        currentXp: beaten!.currentXp,
        temperamentId: before!.temperamentId,
        traitId: before!.traitId,
      });
      expect(after!.currentHp).toBeGreaterThan(beaten!.currentHp);
      expect(res.body.creature.species_id).toBe(RUVAK);
      expect(
        (await skillsOf(before!.uid)).map((skill) => skill.skillId),
      ).toContain(RUVAK_EVOLUTION_SKILL);
      const me = await user.me().expect(200);
      expect(me.body.player.party[0].species_id).toBe(RUVAK);
      await user.evolve(before!.uid, { accept: true }).expect(404);
    });

    it('cancelar mantém o Ruvo, e a oferta volta no próximo nível', async () => {
      const user = await newUser(BEFORE_16);
      const [row] = await party(user);
      await win(user);

      const res = await user.evolve(row!.uid, { accept: false }).expect(200);
      expect(res.body.creature.species_id).toBe(RUVO);
      expect(res.body.learned_skill_ids).toEqual([]);

      await prisma.creatureInstance.update({
        where: { uid: row!.uid },
        data: { currentXp: 17 ** 3 - 1 },
      });
      const last = await win(user);
      expect(last.progression[0]).toMatchObject({
        level_after: 17,
        evolution: { species_id: RUVAK },
      });
    });

    it('escolher Técnica antes de decidir a evolução dá 409', async () => {
      const user = await newUser(BEFORE_16);
      const [row] = await party(user);
      await win(user);

      const res = await user
        .learn(row!.uid, { skill_id: AT_34, forget_skill_id: null })
        .expect(409);
      expect(res.body.message).toBe('Escolha primeiro se ele vai evoluir.');
    });

    it('o Ecobeast de outro Domador dá 404', async () => {
      const owner = await newUser(BEFORE_16);
      const [row] = await party(owner);
      await win(owner);
      const other = await newUser(LEVEL_30);

      await other.evolve(row!.uid, { accept: true }).expect(404);
      await other
        .learn(row!.uid, { skill_id: AT_34, forget_skill_id: null })
        .expect(404);
      await owner.evolve(row!.uid, { accept: true }).expect(200);
    });

    it('um uid malformado dá 404', async () => {
      const user = await newUser(LEVEL_30);
      await user.evolve('nao-e-uuid', { accept: true }).expect(404);
    });
  });

  describe('depuração: quase subir de nível', () => {
    it('deixa cada um da equipe a 1 XP do próximo nível, e a próxima vitória sobe', async () => {
      const user = await newUser(LEVEL_30);
      await addSecondCreature(user);
      await prisma.creatureInstance.updateMany({
        where: { playerId: user.id, partySlot: 2 },
        data: { level: 100, currentXp: 1_000_000 },
      });

      const res = await user.almostLevelUp().expect(200);
      expect(
        res.body.player.party.map(
          (creature: { current_xp: number; level: number }) => [
            creature.level,
            creature.current_xp,
          ],
        ),
      ).toEqual([
        [30, LEVEL_31_XP - 1],
        [100, 1_000_000],
      ]);

      const last = (await playOut(user, await user.start())).last;
      expect(last.progression[0]).toMatchObject({
        level_before: 30,
        level_after: 31,
      });
    });

    it('sem Domador, dá 409', async () => {
      const id = randomUUID();
      users.push(id);
      await request(app.getHttpServer())
        .post('/v1/me/debug/xp')
        .set({ Authorization: `Bearer ${await tokens.sign(id)}` })
        .expect(409);
    });

    it('com ENABLE_TEST_BATTLE desligada, a rota não existe', async () => {
      const closed = await createTestApp({
        tokenVerifier: tokens.verifier,
        env: { ENABLE_TEST_BATTLE: false },
      });
      const user = await newUser(LEVEL_30);
      await user.almostLevelUp(closed).expect(404);
      await closed.close();
    });
  });

  describe('depuração: modo God', () => {
    /** Um selvagem de nível 40 aguenta vários golpes de um nível 30. */
    const TOUGH_WILD = [{ level: 40 }];

    it('o primeiro golpe que acerta derruba o inimigo', async () => {
      const user = await newUser(LEVEL_30);
      placeWild(app, user.id, TOUGH_WILD);
      const first = (await user.wildGod().expect(201)).body as BattleBody;
      const { events } = await playOut(user, first);

      const hits = events.filter(
        (event) => event.type === 'damage' && event.side === 'enemy',
      );
      expect(hits).toHaveLength(1);
      expect(hits[0]).toMatchObject({ hp: 0 });
    });

    it('com ENABLE_TEST_BATTLE desligada, o god é ignorado', async () => {
      const closed = await createTestApp({
        tokenVerifier: tokens.verifier,
        env: { ENABLE_TEST_BATTLE: false },
      });
      const user = await newUser(LEVEL_30);
      placeWild(closed, user.id, TOUGH_WILD);
      const first = (await user.wildGod(closed).expect(201)).body as BattleBody;
      const res = await request(closed.getHttpServer())
        .post('/v1/me/battle/action')
        .set({ Authorization: `Bearer ${await tokens.sign(user.id)}` })
        .send(nextAttack(first.battle))
        .expect(200);
      expect((res.body as BattleBody).battle.phase).not.toBe('ended');
      await closed.close();
    });
  });
});
