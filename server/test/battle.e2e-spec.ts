import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { MIN_STEP_MS } from '../src/battle/battle.service.js';
import { BattleStore } from '../src/battle/battle.store.js';
import type { BattleEvent } from '../src/domain/battle/types.js';
import { ExplorationStore } from '../src/exploration/exploration.store.js';
import { Prisma, PrismaClient } from '../src/generated/prisma/client.js';
import { PrismaService } from '../src/prisma/prisma.service.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';
import { HERE, placeWild } from './support/wild.js';

const RUVO = 1;
const WEAK_ENEMY = { species_id: RUVO, level: 1 };
const STRONG_ENEMY = { species_id: RUVO, level: 100 };
const FLEE = { type: 'flee' };
const NO_PLAYER = 'Crie seu Domador primeiro.';
const NO_HEALTHY = 'Cure sua equipe no Refúgio.';
const INVALID_ENEMY = 'Esse inimigo não existe.';
const INVALID_ACTION = 'Ação inválida.';
const NO_BATTLE = 'Nenhuma batalha em andamento.';
const INVALID_POSITION = 'Posição inválida.';
const NO_EXPLORATION = 'Essa exploração acabou. Saia e entre de novo.';
const UNREACHABLE = 'Você não chegou até aí.';
const NOTHING_HERE = 'Nada por aqui.';
/** Bem mais turnos do que uma luta precisa; só evita um teste sem fim. */
const MAX_TURNS = 60;

interface BattleCreature {
  uid: string;
  species_id: number;
  hp: number;
  skills: { skill_id: number; current_pp: number }[];
}

interface Battle {
  phase: string;
  result: string | null;
  turn: number;
  can_flee: boolean;
  player: { active_index: number; team: BattleCreature[] };
  enemy: {
    active: Record<string, unknown>;
    team_size: number;
    fainted: number;
  };
}

interface BattleBody {
  battle: Battle;
  events: BattleEvent[];
  spawn_id: number | null;
}

interface ExplorationBody {
  map: { creatures: { id: number; q: number; r: number }[] };
}

describe('Rotas da batalha (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let attacks: Set<number>;
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
  });

  afterAll(async () => {
    await prisma.player.deleteMany({ where: { id: { in: users } } });
    await prisma.$disconnect();
    await app.close();
  });

  async function newUser(server: INestApplication<App> = app) {
    const id = randomUUID();
    users.push(id);
    const auth = { Authorization: `Bearer ${await tokens.sign(id)}` };
    const http = () => request(server.getHttpServer());
    return {
      id,
      create: () => http().post('/v1/me').set(auth).send({ name: 'Ana' }),
      starter: () =>
        http().post('/v1/me/starter').set(auth).send({ species_id: RUVO }),
      remove: () => http().delete('/v1/me').set(auth),
      explore: () => http().post('/v1/me/exploration').set(auth),
      start: (body: object) =>
        http().post('/v1/me/battle').set(auth).send(body),
      wild: (body: object = HERE) =>
        http().post('/v1/me/battle/wild').set(auth).send(body),
      wildRaw: () => http().post('/v1/me/battle/wild').set(auth),
      act: (body: object) =>
        http().post('/v1/me/battle/action').set(auth).send(body),
    };
  }

  type User = Awaited<ReturnType<typeof newUser>>;

  async function userWithStarter(
    data: Prisma.CreatureInstanceUncheckedUpdateManyInput = {},
    server?: INestApplication<App>,
  ): Promise<User> {
    const user = await newUser(server);
    await user.create().expect(201);
    await user.starter().expect(200);
    await prisma.creatureInstance.updateMany({
      where: { playerId: user.id },
      data,
    });
    return user;
  }

  /** Nível 100 contra um inimigo de nível 1: vence sem depender de sorte. */
  const strongUser = () => userWithStarter({ level: 100, currentHp: 150 });
  /** 1 de HP contra um inimigo de nível 100: perde sem depender de sorte. */
  const weakUser = () => userWithStarter({ currentHp: 1 });

  function team(user: User) {
    return prisma.creatureInstance.findMany({
      where: { playerId: user.id },
      orderBy: { partySlot: 'asc' },
      include: {
        skills: { orderBy: { slot: 'asc' } },
        statusCondition: true,
      },
    });
  }

  /** Uma cópia do inicial no slot 2, com os campos pedidos. */
  async function addSecondCreature(
    user: User,
    data: Pick<Prisma.CreatureInstanceUncheckedCreateInput, 'currentHp'> &
      Partial<Pick<Prisma.CreatureInstanceUncheckedCreateInput, 'level'>>,
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
        ...data,
      },
    });
  }

  async function start(user: User, enemy: object): Promise<BattleBody> {
    return (await user.start(enemy).expect(201)).body as BattleBody;
  }

  /** Um golpe com PP; sem nenhum, o golpe de emergência. */
  function nextAttack(battle: Battle): object {
    const { skills } = battle.player.team[battle.player.active_index]!;
    const usable = (attacksOnly: boolean) =>
      skills.findIndex(
        (skill) =>
          skill.current_pp > 0 && (!attacksOnly || attacks.has(skill.skill_id)),
      );
    const index = usable(true) >= 0 ? usable(true) : usable(false);
    return index >= 0
      ? { type: 'skill', slot: index + 1 }
      : { type: 'emergency' };
  }

  /** Age até a fase sair de `choose_action`. */
  async function actUntilChoiceEnds(
    user: User,
    first: BattleBody,
    action: (battle: Battle) => object,
  ): Promise<BattleBody> {
    let current = first;
    for (
      let turn = 0;
      turn < MAX_TURNS && current.battle.phase === 'choose_action';
      turn += 1
    ) {
      const res = await user.act(action(current.battle)).expect(200);
      current = res.body as BattleBody;
    }
    return current;
  }

  const fight = (user: User, first: BattleBody) =>
    actUntilChoiceEnds(user, first, nextAttack);
  const flee = (user: User, first: BattleBody) =>
    actUntilChoiceEnds(user, first, () => FLEE);

  async function expectTeamSaved(user: User, battle: Battle): Promise<void> {
    const rows = await team(user);
    expect(rows.map((row) => row.currentHp)).toEqual(
      battle.player.team.map((creature) => creature.hp),
    );
    expect(
      rows.map((row) => row.skills.map((skill) => skill.currentPp)),
    ).toEqual(
      battle.player.team.map((creature) =>
        creature.skills.map((skill) => skill.current_pp),
      ),
    );
  }

  it('sem token, as duas rotas dão 401', async () => {
    const http = () => request(app.getHttpServer());
    const responses = await Promise.all([
      http().post('/v1/me/battle').send(WEAK_ENEMY),
      http().post('/v1/me/battle/action').send(FLEE),
    ]);
    for (const res of responses) expect(res.status).toBe(401);
  });

  describe('começar', () => {
    it('com a variável desligada, dá 404', async () => {
      const closed = await createTestApp({
        tokenVerifier: tokens.verifier,
        env: { ENABLE_TEST_BATTLE: false },
      });
      const user = await userWithStarter({}, closed);
      await user.start(WEAK_ENEMY).expect(404);
      await closed.close();
    });

    it('sem Domador, dá 409', async () => {
      const user = await newUser();
      const res = await user.start(WEAK_ENEMY).expect(409);
      expect(res.body.message).toBe(NO_PLAYER);
    });

    it('sem criaturas, dá 409', async () => {
      const user = await newUser();
      await user.create().expect(201);
      const res = await user.start(WEAK_ENEMY).expect(409);
      expect(res.body.message).toBe(NO_PLAYER);
    });

    it('com a equipe toda a 0 HP, dá 409', async () => {
      const user = await userWithStarter({ currentHp: 0 });
      const res = await user.start(WEAK_ENEMY).expect(409);
      expect(res.body.message).toBe(NO_HEALTHY);
    });

    it.each([
      ['espécie 999', { species_id: 999, level: 5 }],
      ['nível 0', { species_id: RUVO, level: 0 }],
      ['nível 101', { species_id: RUVO, level: 101 }],
      ['nível quebrado', { species_id: RUVO, level: 1.5 }],
      ['nível em texto', { species_id: RUVO, level: '5' }],
      ['espécie em texto', { species_id: 'um', level: 5 }],
      ['corpo vazio', {}],
    ])('%s dá 400', async (_name, body) => {
      const user = await userWithStarter();
      const res = await user.start(body).expect(400);
      expect(res.body.message).toBe(INVALID_ENEMY);
    });

    it('começa com o Ruvo, e o JSON não mostra o inimigo por dentro', async () => {
      const user = await userWithStarter();
      const { battle, events } = await start(user, WEAK_ENEMY);
      const [creature] = await team(user);

      expect(battle).toMatchObject({
        phase: 'choose_action',
        result: null,
        turn: 1,
        can_flee: true,
      });
      expect(battle.player.team[0]).toMatchObject({
        uid: creature!.uid,
        species_id: RUVO,
        hp: creature!.currentHp,
      });
      expect(Object.keys(battle.enemy).sort()).toEqual([
        'active',
        'actives',
        'fainted',
        'team_size',
      ]);
      expect(Object.keys(battle.enemy.active).sort()).toEqual([
        'confused',
        'hp',
        'level',
        'max_hp',
        'species_id',
        'stages',
        'status',
      ]);
      expect(events[0]).toEqual({ type: 'battle_started' });
      expect(events.filter((e) => e.type === 'creature_entered')).toHaveLength(
        2,
      );
    });

    it('começar outra batalha no meio da primeira não muda o banco', async () => {
      const user = await strongUser();
      const before = await team(user);
      const first = await start(user, STRONG_ENEMY);
      await user.act(nextAttack(first.battle)).expect(200);

      const second = await start(user, STRONG_ENEMY);
      expect(second.battle.turn).toBe(1);
      expect(await team(user)).toEqual(before);
    });
  });

  describe('agir', () => {
    it('sem batalha, dá 404', async () => {
      const user = await userWithStarter();
      const res = await user.act(FLEE).expect(404);
      expect(res.body.message).toBe(NO_BATTLE);
    });

    it.each([
      ['corpo vazio', {}],
      ['tipo que não existe', { type: 'dance' }],
      ['Técnica sem slot', { type: 'skill' }],
      ['slot em texto', { type: 'skill', slot: '1' }],
      ['troca sem posição', { type: 'switch' }],
    ])('%s dá 400', async (_name, body) => {
      const user = await userWithStarter();
      await start(user, WEAK_ENEMY);
      const res = await user.act(body).expect(400);
      expect(res.body.message).toBe(INVALID_ACTION);
    });

    it('uma ação recusada pelo motor dá 400 com a mensagem dele', async () => {
      const user = await userWithStarter();
      await start(user, WEAK_ENEMY);
      const noSkill = await user.act({ type: 'skill', slot: 9 }).expect(400);
      expect(noSkill.body.message).toBe('Essa Técnica não existe.');
      const hasPp = await user.act({ type: 'emergency' }).expect(400);
      expect(hasPp.body.message).toBe('Ainda há Técnicas com PP.');
    });

    it('a resposta traz os eventos só deste turno', async () => {
      const user = await strongUser();
      const first = await start(user, STRONG_ENEMY);
      const res = await user.act(nextAttack(first.battle)).expect(200);
      const { events } = res.body as BattleBody;
      expect(events.some((e) => e.type === 'battle_started')).toBe(false);
      expect(events.some((e) => e.type === 'skill_used')).toBe(true);
    });

    it('um jogador não age na batalha do outro', async () => {
      const owner = await strongUser();
      const other = await userWithStarter();
      const first = await start(owner, STRONG_ENEMY);

      await other.act(nextAttack(first.battle)).expect(404);
      await owner.act(nextAttack(first.battle)).expect(200);
    });

    it('quem desmaia dá lugar ao próximo, escolhido pelo jogador', async () => {
      const user = await weakUser();
      const second = await addSecondCreature(user, { currentHp: 5 });

      const opening = await start(user, STRONG_ENEMY);
      const fainted = await fight(user, opening);
      expect(fainted.battle.phase).toBe('choose_next');

      const res = await user.act({ type: 'switch', team_index: 1 }).expect(200);
      const { battle, events } = res.body as BattleBody;
      expect(battle.phase).toBe('choose_action');
      expect(battle.player.active_index).toBe(1);
      expect(battle.player.team[1]!.uid).toBe(second.uid);
      expect(events.map((event) => event.type)).toEqual(['creature_entered']);
    });

    describe('troca durante a luta', () => {
      const SWITCH = { type: 'switch', team_index: 1 };

      async function userWithBench() {
        const user = await strongUser();
        const second = await addSecondCreature(user, {
          level: 100,
          currentHp: 120,
        });
        return { user, second };
      }

      it('põe o outro em campo e gasta a rodada', async () => {
        const { user, second } = await userWithBench();
        const opening = await start(user, WEAK_ENEMY);

        const res = await user.act(SWITCH).expect(200);

        const { battle, events } = res.body as BattleBody;
        expect(battle.phase).toBe('choose_action');
        expect(battle.turn).toBe(opening.battle.turn + 1);
        expect(battle.player.active_index).toBe(1);
        expect(battle.player.team[1]!.uid).toBe(second.uid);
        expect(events[0]).toMatchObject({
          type: 'creature_entered',
          side: 'player',
          position: 0,
          hp: 120,
          status: null,
        });
        expect(events.some((e) => e.type === 'skill_used')).toBe(true);
      });

      it('uma troca recusada não gasta a rodada', async () => {
        const { user } = await userWithBench();
        const opening = await start(user, WEAK_ENEMY);

        const res = await user.act({ type: 'switch', team_index: 0 });

        expect(res.status).toBe(400);
        expect((res.body as { message: string }).message).toBe(
          'Esse Ecobeast já está em campo.',
        );
        expect(app.get(BattleStore).get(user.id)!.state.turn).toBe(
          opening.battle.turn,
        );
      });

      it('Preso, a troca é recusada', async () => {
        const { user } = await userWithBench();
        await start(user, WEAK_ENEMY);
        app.get(BattleStore).get(user.id)!.state.player.team[0]!.isTrapped =
          true;

        const res = await user.act(SWITCH);

        expect(res.status).toBe(400);
        expect((res.body as { message: string }).message).toBe(
          'Não dá para trocar agora.',
        );
      });

      it('o fim da luta grava o HP dos dois Ecobeasts', async () => {
        const { user } = await userWithBench();
        await start(user, WEAK_ENEMY);
        const { state } = app.get(BattleStore).get(user.id)!;
        state.player.team[0]!.currentHp = 33;

        const switched = await user.act(SWITCH).expect(200);
        const { battle } = await fight(user, switched.body as BattleBody);

        expect(battle.result).toBe('victory');
        expect(battle.player.active_index).toBe(1);
        expect(battle.player.team[0]!.hp).toBe(33);
        await expectTeamSaved(user, battle);
      });
    });
  });

  describe('fim', () => {
    it('usar Técnicas até vencer grava o HP e o PP da resposta', async () => {
      const user = await strongUser();
      const { battle, events } = await fight(
        user,
        await start(user, WEAK_ENEMY),
      );

      expect(battle).toMatchObject({ phase: 'ended', result: 'victory' });
      expect(events.at(-1)).toEqual({
        type: 'battle_ended',
        result: 'victory',
      });
      await expectTeamSaved(user, battle);
    });

    it('uma derrota grava 0 HP e limpa o status, e a seguinte dá 409', async () => {
      const user = await weakUser();
      const poison = await prisma.statusCondition.findUniqueOrThrow({
        where: { slug: 'poison' },
      });
      await prisma.creatureInstance.updateMany({
        where: { playerId: user.id },
        data: { statusConditionId: poison.id },
      });

      const { battle } = await fight(user, await start(user, STRONG_ENEMY));

      expect(battle.result).toBe('defeat');
      const [creature] = await team(user);
      expect(creature).toMatchObject({
        currentHp: 0,
        statusConditionId: null,
      });
      const res = await user.start(WEAK_ENEMY).expect(409);
      expect(res.body.message).toBe(NO_HEALTHY);
    });

    it('fugir com sucesso grava o HP e o PP daquele momento', async () => {
      const user = await strongUser();
      const opening = await start(user, WEAK_ENEMY);
      // Um inimigo que aguenta o golpe, para a luta seguir até a fuga.
      app.get(BattleStore).get(user.id)!.state.enemy.team[0]!.currentHp =
        100_000;
      const attacked = await user.act(nextAttack(opening.battle)).expect(200);

      const { battle } = await flee(user, attacked.body as BattleBody);

      expect(battle.result).toBe('fled');
      const totalPp = ({ player }: Battle) =>
        player.team[0]!.skills.reduce((sum, s) => sum + s.current_pp, 0);
      expect(totalPp(battle)).toBeLessThan(totalPp(opening.battle));
      await expectTeamSaved(user, battle);
    });

    it('um status principal fica gravado; um Confuso, não', async () => {
      const user = await strongUser();
      const opening = await start(user, WEAK_ENEMY);
      const creature = app.get(BattleStore).get(user.id)!.state.player.team[0]!;
      creature.statusSlug = 'poison';
      creature.confusionTurns = 5;

      const { battle } = await flee(user, opening);

      expect(battle.result).toBe('fled');
      const [row] = await team(user);
      expect(row!.statusCondition?.slug).toBe('poison');
    });

    it('uma segunda ação depois do fim dá 404', async () => {
      const user = await strongUser();
      await fight(user, await start(user, WEAK_ENEMY));
      const res = await user.act(FLEE).expect(404);
      expect(res.body.message).toBe(NO_BATTLE);
    });

    it('apagar o Domador no meio da luta não dá erro no fim', async () => {
      const user = await strongUser();
      const opening = await start(user, WEAK_ENEMY);
      await user.remove().expect(204);

      const { battle } = await flee(user, opening);

      expect(battle.result).toBe('fled');
      await user.act(FLEE).expect(404);
    });

    it('se a gravação falhar, dá 500, e a equipe fica como antes', async () => {
      const user = await strongUser();
      const before = await team(user);
      await start(user, WEAK_ENEMY);
      const database = app.get(PrismaService);
      const failure = vi
        .spyOn(database, '$transaction')
        .mockRejectedValue(new Error('o banco caiu'));

      let res = await user.act(FLEE);
      for (let turn = 0; res.status === 200 && turn < MAX_TURNS; turn += 1) {
        res = await user.act(FLEE);
      }
      failure.mockRestore();

      expect(res.status).toBe(500);
      expect(await team(user)).toEqual(before);
      await user.act(FLEE).expect(404);
    });
  });

  describe('encontro selvagem', () => {
    async function wild(user: User, position = HERE): Promise<BattleBody> {
      return (await user.wild(position).expect(201)).body as BattleBody;
    }

    /** Sem o valor padrão de `user.wild`, para mandar um corpo inválido. */
    const http = (user: User, body: object | undefined) =>
      user.wildRaw().send(body);

    it('sem token, dá 401', async () => {
      await request(app.getHttpServer()).post('/v1/me/battle/wild').expect(401);
    });

    it('sem Domador, dá 409', async () => {
      const user = await newUser();
      placeWild(app, user.id);
      const res = await user.wild().expect(409);
      expect(res.body.message).toBe(NO_PLAYER);
    });

    it('sem criaturas, dá 409', async () => {
      const user = await newUser();
      await user.create().expect(201);
      placeWild(app, user.id);
      const res = await user.wild().expect(409);
      expect(res.body.message).toBe(NO_PLAYER);
    });

    it('com a equipe toda a 0 HP, dá 409, e o Ecobeast fica no mapa', async () => {
      const user = await userWithStarter({ currentHp: 0 });
      const store = placeWild(app, user.id);

      const res = await user.wild().expect(409);

      expect(res.body.message).toBe(NO_HEALTHY);
      expect(store.get(user.id)!.spawns.size).toBe(1);
    });

    it.each([
      ['sem corpo', undefined],
      ['sem r', { q: 0 }],
      ['com q quebrado', { q: 0.5, r: 0 }],
      ['com texto', { q: 'a', r: 0 }],
    ])('%s, dá 400', async (_label, body) => {
      const user = await userWithStarter();
      placeWild(app, user.id);

      const res = await http(user, body).expect(400);

      expect(res.body.message).toBe(INVALID_POSITION);
    });

    it('sem exploração, dá 404', async () => {
      const user = await userWithStarter();

      const res = await user.wild().expect(404);

      expect(res.body.message).toBe(NO_EXPLORATION);
    });

    it('longe demais para o tempo que passou, dá 409', async () => {
      const user = await userWithStarter();
      placeWild(app, user.id, [{ q: 40, r: 0 }]);

      const res = await user.wild({ q: 40, r: 0 }).expect(409);

      expect(res.body.message).toBe(UNREACHABLE);
    });

    it('longe, depois de passar o tempo do caminho, funciona', async () => {
      const user = await userWithStarter();
      const store = placeWild(app, user.id, [{ q: 40, r: 0 }]);
      store.get(user.id)!.positionAt = Date.now() - 40 * MIN_STEP_MS;

      await user.wild({ q: 40, r: 0 }).expect(201);
    });

    it('a distância conta passos na grade, não colunas', async () => {
      const user = await userWithStarter();
      const store = placeWild(app, user.id, [{ q: 40, r: -40 }]);
      store.get(user.id)!.positionAt = Date.now() - 40 * MIN_STEP_MS;

      await user.wild({ q: 40, r: -40 }).expect(201);
    });

    it('a posição aceita passa a valer para o próximo pedido', async () => {
      const user = await userWithStarter();
      const store = placeWild(app, user.id, [
        { q: 40, r: 0 },
        { q: 80, r: 0 },
      ]);
      store.get(user.id)!.positionAt = Date.now() - 40 * MIN_STEP_MS;
      await user.wild({ q: 40, r: 0 }).expect(201);

      const res = await user.wild({ q: 80, r: 0 }).expect(409);

      expect(res.body.message).toBe(UNREACHABLE);
      expect(store.get(user.id)!.position).toEqual({ q: 40, r: 0 });
    });

    it('em um hexágono sem Ecobeast, dá 409', async () => {
      const user = await userWithStarter();
      const store = placeWild(app, user.id, [{ q: 1, r: 0 }]);

      const res = await user.wild().expect(409);

      expect(res.body.message).toBe(NOTHING_HERE);
      expect(store.get(user.id)!.spawns.size).toBe(1);
    });

    it('a resposta diz qual Ecobeast saiu do mapa', async () => {
      const user = await userWithStarter();
      const store = placeWild(app, user.id, [{ q: 1, r: 0 }, {}]);

      const { spawn_id } = await wild(user);

      expect(spawn_id).toBe(2);
      expect([...store.get(user.id)!.spawns.keys()]).toEqual([1]);
    });

    it('agir na luta responde sem `spawn_id`', async () => {
      const user = await userWithStarter();
      placeWild(app, user.id);
      const { battle } = await wild(user);

      const res = await user.act(nextAttack(battle)).expect(200);

      expect(res.body.spawn_id).toBeNull();
    });

    it('o Ecobeast só pode ser enfrentado uma vez', async () => {
      const user = await userWithStarter();
      placeWild(app, user.id);
      await wild(user);

      const res = await user.wild().expect(409);

      expect(res.body.message).toBe(NOTHING_HERE);
    });

    it('em um hexágono com dois, cada busca enfrenta um deles', async () => {
      const user = await userWithStarter();
      placeWild(app, user.id, [{}, {}]);

      const first = await wild(user);
      const second = await wild(user);

      expect([first.spawn_id, second.spawn_id].sort()).toEqual([1, 2]);
      await user.wild().expect(409);
    });

    it('dois pedidos ao mesmo tempo não enfrentam o mesmo Ecobeast', async () => {
      const user = await userWithStarter();
      placeWild(app, user.id);

      const responses = await Promise.all([user.wild(), user.wild()]);

      expect(responses.map(({ status }) => status).sort()).toEqual([201, 409]);
    });

    it('o Ecobeast do mapa de verdade é o que entra na luta', async () => {
      const user = await userWithStarter();
      const { body } = await user.explore().expect(201);
      const { creatures } = (body as ExplorationBody).map;
      const store = app.get(ExplorationStore);
      store.get(user.id)!.positionAt = Date.now() - 100_000 * MIN_STEP_MS;
      const { q, r } = creatures[0]!;
      const stored = new Map(store.get(user.id)!.spawns);

      const { battle, spawn_id } = await wild(user, { q, r });

      const spawn = stored.get(spawn_id!)!;
      expect({ q: spawn.q, r: spawn.r }).toEqual({ q, r });
      expect(battle.enemy.active['species_id']).toBe(spawn.speciesId);
      expect(battle.enemy.active['level']).toBe(spawn.level);
      expect(store.get(user.id)!.spawns.has(spawn_id!)).toBe(false);
    });

    it('funciona com a variável de teste desligada', async () => {
      const closed = await createTestApp({
        tokenVerifier: tokens.verifier,
        env: { ENABLE_TEST_BATTLE: false },
      });
      const user = await userWithStarter({}, closed);
      placeWild(closed, user.id);
      await user.wild().expect(201);
      await user.start(WEAK_ENEMY).expect(404);
      await closed.close();
    });

    it('o inimigo tem a espécie e o nível guardados no mapa', async () => {
      const user = await userWithStarter({ level: 20 });
      placeWild(app, user.id, [{ speciesId: 8, level: 37 }]);

      const { battle } = await wild(user);

      expect(battle.enemy.active['species_id']).toBe(8);
      expect(battle.enemy.active['level']).toBe(37);
    });

    it('com o primeiro caído, entra o segundo', async () => {
      const user = await userWithStarter({ level: 50, currentHp: 0 });
      await addSecondCreature(user, { level: 30, currentHp: 5 });
      placeWild(app, user.id);

      const { battle } = await wild(user);

      expect(battle.player.active_index).toBe(1);
    });

    it('uma nova batalha descarta a anterior, sem gravar', async () => {
      const user = await userWithStarter();
      const before = await team(user);
      placeWild(app, user.id, [{}, {}]);
      const first = await wild(user);
      // O sorteio não importa aqui: ninguém cai, e a luta não termina.
      const { state } = app.get(BattleStore).get(user.id)!;
      state.player.team[0]!.currentHp = 100_000;
      state.enemy.team[0]!.currentHp = 100_000;
      await user.act(nextAttack(first.battle)).expect(200);

      const second = await wild(user);

      expect(second.battle.turn).toBe(1);
      expect(await team(user)).toEqual(before);
    });

    it('a luta vai até o fim e grava HP e PP', async () => {
      const user = await userWithStarter();
      placeWild(app, user.id);
      const { battle } = await fight(user, await wild(user));

      expect(battle.phase).toBe('ended');
      await expectTeamSaved(user, battle);
    });
  });

  it('as rotas aparecem no OpenAPI, com o cadeado', async () => {
    const { body } = await request(app.getHttpServer())
      .get('/docs/openapi.json')
      .expect(200);
    for (const path of [
      '/v1/me/battle',
      '/v1/me/battle/wild',
      '/v1/me/battle/action',
    ]) {
      const operation = body.paths[path].post;
      expect(operation.tags).toEqual(['Batalha']);
      expect(operation.security).toEqual([{ bearer: [] }]);
    }
  });
});
