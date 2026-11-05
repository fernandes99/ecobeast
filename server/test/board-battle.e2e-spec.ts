import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { BattleStore } from '../src/battle/battle.store.js';
import type { BattleEvent } from '../src/domain/battle/types.js';
import { hexDistance, hexNeighbors } from '../src/domain/exploration/hex.js';
import { ExplorationStore } from '../src/exploration/exploration.store.js';
import { Item, Prisma, PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';
import { HERE, placeWild } from './support/wild.js';

// As rotas da luta no tabuleiro (.specs/board-battle/03-board-api.md).

const RUVO = 1;
const ARRANHAO_SLOT = 1;
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
      team: { hp: number }[];
    };
    enemy: { cells: (Cell | null)[] };
  };
  events: BattleEvent[];
  captured_to: string | null;
  spawn_id: number | null;
}

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

  const sameCell = (a: Cell, b: Cell) => a.q === b.q && a.r === b.r;

  it('um 1×1 de teste traz o tabuleiro, as áreas, onde cada um está e a fila', async () => {
    const user = await strongUser();
    const body = await start(user, { enemies: [WEAK_ENEMY] });
    expect(body.battle.board.cells).toHaveLength(42);
    expect(body.battle.board.zones.player).toHaveLength(12);
    expect(body.battle.board.zones.enemy).toHaveLength(12);
    expect(body.battle.player.cells).toEqual([{ q: 0, r: 5 }]);
    expect(body.battle.enemy.cells).toEqual([{ q: 2, r: 1 }]);
    expect(body.battle.queue[0]).toEqual({ side: 'player', position: 0 });
    expect(body.battle.round).toBe(1);
    expect(body.events.at(-1)).toEqual({
      type: 'vez_started',
      side: 'player',
      position: 0,
    });
  });

  it('andar 3 hexágonos e usar Arranhão ao lado do selvagem traz a vez dele junto', async () => {
    const user = await strongUser();
    const started = await start(user, { enemies: [TOUGH_ENEMY] });
    // O selvagem pode ter jogado antes e andado: o passo sai de onde ele está.
    const me = started.battle.player.cells[0]!;
    const enemy = started.battle.enemy.cells[0]!;
    const board = started.battle.board.cells;
    const next = hexNeighbors(enemy).find(
      (cell) =>
        board.some((boardCell) => sameCell(boardCell, cell)) &&
        !sameCell(cell, me) &&
        hexDistance(me, cell) <= 3,
    );
    const body = await act(user, {
      position: 0,
      ...(hexDistance(me, enemy) > 1 && { move: next }),
      action: { type: 'skill', slot: ARRANHAO_SLOT, target: enemy },
    });
    const types = body.events.map((event) => event.type);
    expect(types).toContain('skill_used');
    expect(types).toContain('damage');
    expect(body.events).toContainEqual(
      expect.objectContaining({ type: 'vez_started', side: 'enemy' }),
    );
  });

  it('andar 4 hexágonos é recusado com 400, e a luta segue igual', async () => {
    const user = await strongUser();
    await start(user, { enemies: [WEAK_ENEMY] });
    const res = await user
      .act({ position: 0, move: { q: 0, r: 1 }, action: { type: 'wait' } })
      .expect(400);
    expect(res.body.message).toBe(CANNOT_REACH);
    const body = await act(user, {
      position: 0,
      move: { q: 0, r: 2 },
      action: { type: 'wait' },
    });
    expect(body.battle.player.cells).toEqual([{ q: 0, r: 2 }]);
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

  it('capturar o selvagem grava o capturado na equipe', async () => {
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
      action: { type: 'capture', item_id: sphere.id, target: { q: 2, r: 1 } },
    });
    expect(body.battle.result).toBe('captured');
    expect(body.captured_to).toBe('party');
    const team = await prisma.creatureInstance.findMany({
      where: { playerId: user.id },
    });
    expect(team).toHaveLength(2);
  });

  it('o encontro de Explorar zona tira o Ecobeast do mapa e começa no tabuleiro', async () => {
    const user = await strongUser();
    placeWild(app, user.id);
    const res = await user.wild().expect(201);
    const body = res.body as BoardBody;
    expect(body.spawn_id).toBe(1);
    expect(body.battle.board.cells).toHaveLength(42);
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
});
