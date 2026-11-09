import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { BattleStore } from '../src/battle/battle.store.js';
import type { BattleEvent } from '../src/domain/battle/types.js';
import { ExplorationStore } from '../src/exploration/exploration.store.js';
import { Item, Prisma, PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import {
  attackVez,
  fleeVez,
  playOut as playBoard,
  waitVez,
} from './support/board-play.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';
import { HERE, placeWild } from './support/wild.js';

// As rotas da luta no tabuleiro (.specs/board-battle/03-board-api.md).

const RUVO = 1;
const NO_BATTLE = 'Nenhuma batalha em andamento.';
const CANNOT_REACH = 'Não dá para chegar lá.';
/** Bem mais vezes do que uma luta precisa; só evita um teste sem fim. */
const MAX_VEZES = 80;

interface Cell {
  q: number;
  r: number;
}

interface BoardBody {
  battle: {
    phase: string;
    result: string | null;
    round: number;
    board: { cells: Cell[]; zones: { player: Cell[]; enemy: Cell[] } };
    marks: unknown[];
    queue: { side: string; position: number }[];
    player: {
      cells: (Cell | null)[];
      entry_cells: Cell[];
      pending_positions: number[];
      team: { hp: number; skills: { current_pp: number }[] }[];
    };
    enemy: { cells: (Cell | null)[] };
  };
  events: BattleEvent[];
  captured_to: string | null;
  spawn_id: number | null;
  progression: {
    team_index: number;
    level_after: number;
    evolution: { species_id: number } | null;
  }[];
}

type Battle = BoardBody['battle'];

describe('Rotas da luta no tabuleiro (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let sphere: Item;
  const users: string[] = [];

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({ tokenVerifier: tokens.verifier });
    sphere = await prisma.item.findFirstOrThrow({
      where: { captureBonus: { not: null } },
    });
  });

  afterAll(async () => {
    await prisma.player.deleteMany({ where: { id: { in: users } } });
    await prisma.$disconnect();
    await app.close();
  });

  async function userWithStarter(
    data: Prisma.CreatureInstanceUncheckedUpdateManyInput = {},
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
      start: (body: object) =>
        http().post('/v1/me/board-battle').set(auth).send(body),
      wild: (body: object = HERE) =>
        http().post('/v1/me/board-battle/wild').set(auth).send(body),
      act: (body: object) =>
        http().post('/v1/me/board-battle/action').set(auth).send(body),
      startClassic: (body: object) =>
        http().post('/v1/me/battle').set(auth).send(body),
      evolve: (uid: string, body: object) =>
        http().post(`/v1/me/creatures/${uid}/evolution`).set(auth).send(body),
    };
  }

  type User = Awaited<ReturnType<typeof userWithStarter>>;

  /** Uma cópia do inicial na vaga dada da equipe, com os campos pedidos. */
  async function addCreature(
    user: User,
    partySlot: number,
    data: Partial<Prisma.CreatureInstanceUncheckedCreateInput> = {},
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
        location: 'party',
        partySlot,
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

  async function start(user: User, body: object): Promise<BoardBody> {
    return (await user.start(body).expect(201)).body as BoardBody;
  }

  async function act(user: User, body: object): Promise<BoardBody> {
    return (await user.act(body).expect(200)).body as BoardBody;
  }

  /** Nível 100: joga antes de um selvagem de nível 1 e aguenta qualquer golpe dele. */
  const strongUser = () => userWithStarter({ level: 100, currentHp: 150 });
  const WEAK_ENEMY = { species_id: RUVO, level: 1 };
  /** Aguenta um Arranhão de nível 100, até crítico; pode jogar antes do jogador. */
  const TOUGH_ENEMY = { species_id: RUVO, level: 70 };

  /** Joga as vezes do jogador até a luta sair do `choose_action`. */
  const playOut = (
    user: User,
    first: BoardBody,
    vez?: (battle: Battle) => object,
  ): Promise<BoardBody> => playBoard((body) => act(user, body), first, vez);

  async function team(user: User) {
    return prisma.creatureInstance.findMany({
      where: { playerId: user.id },
      orderBy: { partySlot: 'asc' },
      include: { skills: { orderBy: { slot: 'asc' } }, statusCondition: true },
    });
  }

  /** O HP e o PP do banco são os da resposta do fim. */
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

  async function coinsOf(user: User): Promise<number> {
    return (await prisma.player.findUniqueOrThrow({ where: { id: user.id } }))
      .coins;
  }

  it('um 1×1 de teste traz o tabuleiro, as áreas, onde cada um está e a fila', async () => {
    const user = await strongUser();
    const body = await start(user, { enemies: [WEAK_ENEMY] });
    expect(body.battle.board.cells).toHaveLength(18);
    expect(body.battle.board.zones.player).toHaveLength(6);
    expect(body.battle.board.zones.enemy).toHaveLength(6);
    expect(body.battle.player.cells).toEqual([{ q: -1, r: 4 }]);
    expect(body.battle.enemy.cells).toEqual([{ q: 1, r: 1 }]);
    expect(body.battle.queue[0]).toEqual({ side: 'player', position: 0 });
    expect(body.battle.round).toBe(1);
    expect(body.events.at(-1)).toEqual({
      type: 'vez_started',
      side: 'player',
      position: 0,
    });
  });

  it('chegar ao lado do selvagem e usar Arranhão traz a vez dele junto', async () => {
    const user = await strongUser();
    let body = await start(user, { enemies: [TOUGH_ENEMY] });
    const scratched = (events: BattleEvent[]) =>
      events.some(
        (event) => event.type === 'skill_used' && event.side === 'player',
      );
    for (let vez = 0; vez < MAX_VEZES && !scratched(body.events); vez++) {
      body = await act(user, attackVez(body.battle));
    }
    expect(body.events.map((event) => event.type)).toContain('damage');
    expect(body.events).toContainEqual(
      expect.objectContaining({ type: 'vez_started', side: 'enemy' }),
    );
  });

  it('andar 1 hexágono funciona; 2 é recusado com 400, e a luta segue igual', async () => {
    const user = await strongUser();
    await start(user, { enemies: [WEAK_ENEMY] });
    const res = await user
      .act({ position: 0, move: { q: -1, r: 2 }, action: { type: 'wait' } })
      .expect(400);
    expect(res.body.message).toBe(CANNOT_REACH);
    const body = await act(user, {
      position: 0,
      move: { q: -1, r: 3 },
      action: { type: 'wait' },
    });
    expect(body.battle.player.cells).toEqual([{ q: -1, r: 3 }]);
  });

  it('corpo sem action fora do choose_next é malformado', async () => {
    const user = await strongUser();
    await start(user, { enemies: [WEAK_ENEMY] });
    const res = await user.act({ position: 0 }).expect(400);
    expect(res.body.message).toBe('Ação inválida.');
  });

  it('a Esfera sem o hexágono do alvo é malformada', async () => {
    const user = await strongUser();
    await start(user, { enemies: [WEAK_ENEMY] });
    const res = await user
      .act({ position: 0, action: { type: 'capture', item_id: sphere.id } })
      .expect(400);
    expect(res.body.message).toBe('Ação inválida.');
  });

  it('quem entra sem o hexágono é malformado', async () => {
    const user = await strongUser();
    await start(user, { enemies: [WEAK_ENEMY] });
    const res = await user
      .act({ entries: [{ position: 0, team_index: 1 }] })
      .expect(400);
    expect(res.body.message).toBe('Ação inválida.');
  });

  it('num 2×2, quem cai com reserva espera a escolha, e o novo entra no hexágono escolhido', async () => {
    const user = await userWithStarter({ currentHp: 1 });
    await addCreature(user, 2, { currentHp: 1 });
    await addCreature(user, 3);
    const strong = { species_id: RUVO, level: 100 };
    let body = await start(user, { enemies: [strong, strong], slots: 2 });
    for (let vez = 0; vez < MAX_VEZES; vez++) {
      if (body.battle.phase !== 'choose_action') break;
      const head = body.battle.queue[0]!;
      body = await act(user, {
        position: head.position,
        action: { type: 'wait' },
      });
    }
    expect(body.battle.phase).toBe('choose_next');
    const position = body.battle.player.pending_positions[0]!;
    const cell = body.battle.player.entry_cells.at(-1)!;
    const after = await act(user, {
      entries: [{ position, team_index: 2, cell }],
    });
    expect(after.events).toContainEqual(
      expect.objectContaining({
        type: 'creature_entered',
        side: 'player',
        position,
        team_index: 2,
        cell,
      }),
    );
  });

  it('uma Esfera no selvagem a 3 hexágonos captura, e ele entra na equipe', async () => {
    const user = await strongUser();
    await prisma.inventoryItem.create({
      data: { playerId: user.id, itemId: sphere.id, quantity: 1 },
    });
    await start(user, { enemies: [WEAK_ENEMY] });
    const { catalog } = app.get(BattleStore).get(user.id)!;
    catalog.captureRates.set(RUVO, 100);
    catalog.items.get(sphere.id)!.captureBonus = 1000;
    const body = await act(user, {
      position: 0,
      action: { type: 'capture', item_id: sphere.id, target: { q: 1, r: 1 } },
    });
    expect(body.battle.result).toBe('captured');
    expect(body.captured_to).toBe('party');
    const team = await prisma.creatureInstance.findMany({
      where: { playerId: user.id },
    });
    expect(team).toHaveLength(2);
  });

  it('com a equipe cheia, o capturado vai para o Santuário, e a Esfera é gasta', async () => {
    const user = await strongUser();
    for (let slot = 2; slot <= 6; slot++) await addCreature(user, slot);
    await prisma.inventoryItem.create({
      data: { playerId: user.id, itemId: sphere.id, quantity: 1 },
    });
    await start(user, { enemies: [WEAK_ENEMY] });
    const { catalog } = app.get(BattleStore).get(user.id)!;
    catalog.captureRates.set(RUVO, 100);
    catalog.items.get(sphere.id)!.captureBonus = 1000;
    const body = await act(user, {
      position: 0,
      action: { type: 'capture', item_id: sphere.id, target: { q: 1, r: 1 } },
    });
    expect(body.captured_to).toBe('storage');
    const stored = await prisma.creatureInstance.count({
      where: { playerId: user.id, location: 'storage' },
    });
    expect(stored).toBe(1);
    const spheres = await prisma.inventoryItem.findFirst({
      where: { playerId: user.id, itemId: sphere.id },
    });
    expect(spheres).toBeNull();
  });

  describe('fim da luta', () => {
    it('vencer grava o HP e o PP da resposta, dá XP e soma as moedas', async () => {
      // No 100, o nível máximo, não há XP a ganhar.
      const user = await userWithStarter({ level: 50 });
      const coins = await coinsOf(user);
      const last = await playOut(
        user,
        await start(user, { enemies: [WEAK_ENEMY] }),
      );
      expect(last.battle.result).toBe('victory');
      await expectTeamSaved(user, last.battle);
      expect(last.events).toContainEqual(
        expect.objectContaining({ type: 'xp_gained', team_index: 0 }),
      );
      const gained = last.events.find((event) => event.type === 'coins_gained');
      expect(gained).toBeDefined();
      expect(await coinsOf(user)).toBe(
        coins + (gained as { amount: number }).amount,
      );
    });

    it('subir para o nível de evolução grava o nível, e aceitar a oferta evolui', async () => {
      const RUVAK = 2;
      const user = await userWithStarter({
        level: 15,
        currentXp: 16 ** 3 - 1,
        currentHp: 40,
      });
      const last = await playOut(
        user,
        await start(user, { enemies: [WEAK_ENEMY] }),
      );
      expect(last.battle.result).toBe('victory');
      expect(last.progression[0]).toMatchObject({
        level_after: 16,
        evolution: { species_id: RUVAK },
      });
      const [row] = await team(user);
      expect(row!.level).toBe(16);
      await user.evolve(row!.uid, { accept: true }).expect(200);
      const [evolved] = await team(user);
      expect(evolved!.speciesId).toBe(RUVAK);
    });

    it('perder grava 0 HP, limpa o status e tira as moedas do evento', async () => {
      const poison = await prisma.statusCondition.findFirstOrThrow({
        where: { slug: 'poison' },
      });
      const user = await userWithStarter({ statusConditionId: poison.id });
      await prisma.player.update({
        where: { id: user.id },
        data: { coins: 500 },
      });
      const strong = { species_id: RUVO, level: 100 };
      const last = await playOut(
        user,
        await start(user, { enemies: [strong] }),
        waitVez,
      );
      expect(last.battle.result).toBe('defeat');
      const [row] = await team(user);
      expect(row!.currentHp).toBe(0);
      expect(row!.statusConditionId).toBeNull();
      const lost = last.events.find((event) => event.type === 'coins_lost');
      expect(lost).toBeDefined();
      expect(await coinsOf(user)).toBe(
        500 - (lost as { amount: number }).amount,
      );
    });

    it('uma luta que acaba antes da primeira vez do jogador também grava o fim', async () => {
      // A 1 HP, contra um selvagem de nível 100 que joga antes e alcança de 3
      // hexágonos, a luta quase sempre acaba já na abertura.
      const strong = { species_id: RUVO, level: 100 };
      let opening: BoardBody | null = null;
      let user: User | null = null;
      for (let attempt = 0; attempt < 10 && !opening; attempt++) {
        user = await userWithStarter({ currentHp: 1 });
        const body = await start(user, { enemies: [strong] });
        if (body.battle.phase === 'ended') opening = body;
      }
      expect(opening?.battle.result).toBe('defeat');
      const [row] = await team(user!);
      expect(row!.currentHp).toBe(0);
      await user!.act({ position: 0, action: { type: 'wait' } }).expect(404);
    });

    it('fugir grava o HP, o PP e o status daquele momento, sem XP', async () => {
      const user = await strongUser();
      const opening = await start(user, { enemies: [TOUGH_ENEMY] });
      const creature = app.get(BattleStore).get(user.id)!.state.player.team[0]!;
      creature.statusSlug = 'poison';
      const last = await playOut(user, opening, fleeVez);
      expect(last.battle.result).toBe('fled');
      await expectTeamSaved(user, last.battle);
      const [row] = await team(user);
      expect(row!.statusCondition?.slug).toBe('poison');
      expect(last.events.map((event) => event.type)).not.toContain('xp_gained');
    });
  });

  describe('Mochila e troca', () => {
    async function withTonic(user: User, quantity: number): Promise<Item> {
      const tonic = await prisma.item.findFirstOrThrow({
        where: { healAmount: { not: null } },
        orderBy: { id: 'asc' },
      });
      await prisma.inventoryItem.create({
        data: { playerId: user.id, itemId: tonic.id, quantity },
      });
      return tonic;
    }

    it('curar quem está na reserva gasta a vez, sobe o HP dele e desconta o item no fim', async () => {
      const user = await strongUser();
      await addCreature(user, 2, { currentHp: 1 });
      const tonic = await withTonic(user, 2);
      await start(user, { enemies: [WEAK_ENEMY] });
      const body = await act(user, {
        position: 0,
        action: { type: 'item', item_id: tonic.id, team_index: 1 },
      });
      expect(body.events).toContainEqual(
        expect.objectContaining({ type: 'item_used', team_index: 1 }),
      );
      expect(body.battle.player.team[1]!.hp).toBeGreaterThan(1);
      expect(body.events).toContainEqual(
        expect.objectContaining({ type: 'vez_started', side: 'enemy' }),
      );
      const last = await playOut(user, body);
      expect(last.battle.result).toBe('victory');
      const tonics = await prisma.inventoryItem.findFirstOrThrow({
        where: { playerId: user.id, itemId: tonic.id },
      });
      expect(tonics.quantity).toBe(1);
      await expectTeamSaved(user, last.battle);
    });

    it('trocar põe quem entra no hexágono de quem saiu, e ele só joga na rodada seguinte', async () => {
      const user = await strongUser();
      await addCreature(user, 2);
      const opening = await start(user, { enemies: [WEAK_ENEMY] });
      const from = opening.battle.player.cells[0]!;
      const moved = { q: from.q, r: from.r - 1 };
      const body = await act(user, {
        position: 0,
        move: moved,
        action: { type: 'switch', team_index: 1 },
      });
      const types = body.events.map((event) => event.type);
      const entered = body.events.findIndex(
        (event) => event.type === 'creature_entered' && event.side === 'player',
      );
      expect(body.events[entered]).toMatchObject({
        team_index: 1,
        cell: moved,
      });
      expect(types.lastIndexOf('round_started')).toBeGreaterThan(entered);
      expect(body.battle.player.cells[0]).toEqual(moved);
    });
  });

  it('o encontro de Explorar zona tira o Ecobeast do mapa e começa no tabuleiro', async () => {
    const user = await strongUser();
    placeWild(app, user.id);
    const res = await user.wild().expect(201);
    const body = res.body as BoardBody;
    expect(body.spawn_id).toBe(1);
    expect(body.battle.board.cells).toHaveLength(18);
    expect(app.get(ExplorationStore).get(user.id)!.spawns.has(1)).toBe(false);
  });

  it('o encontro sem Ecobeast no hexágono dá 409, como na luta de hoje', async () => {
    const user = await strongUser();
    placeWild(app, user.id, [{ q: 3, r: 3 }]);
    const res = await user.wild().expect(409);
    expect(res.body.message).toBe('Nada por aqui.');
  });

  it('sem luta no tabuleiro, a vez dá 404, mesmo com uma luta de hoje em andamento', async () => {
    const user = await strongUser();
    await user.act({ position: 0, action: { type: 'wait' } }).expect(404);
    await user.startClassic({ species_id: RUVO, level: 1 }).expect(201);
    const res = await user
      .act({ position: 0, action: { type: 'wait' } })
      .expect(404);
    expect(res.body.message).toBe(NO_BATTLE);
  });

  it('começar uma luta no tabuleiro descarta a de hoje', async () => {
    const user = await strongUser();
    await user.startClassic({ species_id: RUVO, level: 1 }).expect(201);
    await start(user, { enemies: [WEAK_ENEMY] });
    expect(app.get(BattleStore).get(user.id)!.kind).toBe('board');
  });

  it('o /docs mostra as três rotas', async () => {
    const { body: doc } = await request(app.getHttpServer())
      .get('/docs/openapi.json')
      .expect(200);
    expect(doc.paths['/v1/me/board-battle']?.post).toBeDefined();
    expect(doc.paths['/v1/me/board-battle/wild']?.post).toBeDefined();
    expect(doc.paths['/v1/me/board-battle/action']?.post).toBeDefined();
  });

  it('o /docs marca as rotas da luta antiga como legado', async () => {
    const { body: doc } = await request(app.getHttpServer())
      .get('/docs/openapi.json')
      .expect(200);
    for (const path of [
      '/v1/me/battle',
      '/v1/me/battle/wild',
      '/v1/me/battle/action',
    ]) {
      const operation = doc.paths[path]?.post;
      expect(operation?.deprecated).toBe(true);
      expect(operation?.tags).toEqual(['Batalha (legado)']);
    }
    expect(
      doc.paths['/v1/me/board-battle/action']?.post?.deprecated,
    ).toBeUndefined();
  });
});
