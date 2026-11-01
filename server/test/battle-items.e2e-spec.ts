import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import type { BattleEvent } from '../src/domain/battle/types.js';
import { Item, PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

// A luta guarda o gasto na memória, e o banco só muda no fim dela
// (.specs/inventory-shop/architecture.md, "O item na batalha").

const FAGULHO = 1;
const WEAK_ENEMY = { species_id: FAGULHO, level: 1 };
const FLEE = { type: 'flee' };
const NO_ITEM = 'Você não tem esse item.';
const NO_EFFECT = 'Não teria efeito.';
const INVALID_ACTION = 'Ação inválida.';
/** A fuga falha às vezes: bem mais tentativas do que ela precisa. */
const MAX_TRIES = 60;

interface Body {
  battle: {
    phase: string;
    turn: number;
    player: {
      team: { hp: number; max_hp: number }[];
      items: { item_id: number; quantity: number }[];
    };
  };
  events: BattleEvent[];
}

describe('Itens na batalha (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let tonic: Item;
  const users: string[] = [];

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({ tokenVerifier: tokens.verifier });
    tonic = await prisma.item.findFirstOrThrow({
      where: { healAmount: { not: null } },
    });
  });

  afterAll(async () => {
    await prisma.player.deleteMany({ where: { id: { in: users } } });
    await prisma.$disconnect();
    await app.close();
  });

  /** Nível 100 contra um inimigo de nível 1: sobrevive sem depender de sorte. */
  async function strongUser() {
    const id = randomUUID();
    users.push(id);
    const auth = { Authorization: `Bearer ${await tokens.sign(id)}` };
    const http = () => request(app.getHttpServer());
    await http().post('/v1/me').set(auth).send({ name: 'Ana' }).expect(201);
    await http()
      .post('/v1/me/starter')
      .set(auth)
      .send({ species_id: FAGULHO })
      .expect(200);
    await prisma.creatureInstance.updateMany({
      where: { playerId: id },
      data: { level: 100, currentHp: 100 },
    });
    return {
      id,
      start: () => http().post('/v1/me/battle').set(auth).send(WEAK_ENEMY),
      act: (body: object) =>
        http().post('/v1/me/battle/action').set(auth).send(body),
      buy: () =>
        http().post('/v1/me/shop/buy').set(auth).send({ item_id: tonic.id }),
    };
  }

  type User = Awaited<ReturnType<typeof strongUser>>;

  const USE_TONIC = () => ({
    type: 'item',
    item_id: tonic.id,
    team_index: 0,
  });

  async function give(user: User, quantity: number) {
    await prisma.inventoryItem.create({
      data: { playerId: user.id, itemId: tonic.id, quantity },
    });
  }

  async function quantityInDb(user: User) {
    const row = await prisma.inventoryItem.findUnique({
      where: { playerId_itemId: { playerId: user.id, itemId: tonic.id } },
    });
    return row?.quantity ?? 0;
  }

  async function fleeUntilOver(user: User): Promise<Body> {
    for (let tries = 0; tries < MAX_TRIES; tries += 1) {
      const res = await user.act(FLEE).expect(200);
      if ((res.body as Body).battle.phase === 'ended') return res.body as Body;
    }
    throw new Error('A fuga não terminou a luta.');
  }

  it('a batalha mostra a Mochila ao começar', async () => {
    const user = await strongUser();
    await give(user, 2);
    const res = await user.start().expect(201);
    expect((res.body as Body).battle.player.items).toEqual([
      { item_id: tonic.id, quantity: 2 },
    ]);
  });

  it('usar um item cura, gasta a rodada e desconta só na resposta', async () => {
    const user = await strongUser();
    await give(user, 2);
    const opening = (await user.start().expect(201)).body as Body;

    const res = await user.act(USE_TONIC()).expect(200);

    const body = res.body as Body;
    expect(body.events[0]).toMatchObject({
      type: 'item_used',
      side: 'player',
      item_id: tonic.id,
      team_index: 0,
    });
    expect(body.events.map((event) => event.type)).toContain('skill_used');
    expect(body.battle.turn).toBe(opening.battle.turn + 1);
    expect(body.battle.player.items).toEqual([
      { item_id: tonic.id, quantity: 1 },
    ]);
    expect(await quantityInDb(user)).toBe(2);
  });

  it('o fim da luta grava só o que foi gasto', async () => {
    const user = await strongUser();
    await give(user, 3);
    await user.start().expect(201);
    await user.act(USE_TONIC()).expect(200);

    await fleeUntilOver(user);

    expect(await quantityInDb(user)).toBe(2);
  });

  it('a última unidade gasta na luta apaga a linha', async () => {
    const user = await strongUser();
    await give(user, 1);
    await user.start().expect(201);
    await user.act(USE_TONIC()).expect(200);

    const body = await fleeUntilOver(user);

    expect(body.battle.player.items).toEqual([]);
    expect(await quantityInDb(user)).toBe(0);
  });

  it('o HP curado na luta fica salvo no fim dela', async () => {
    const user = await strongUser();
    await give(user, 1);
    await user.start().expect(201);
    const res = await user.act(USE_TONIC()).expect(200);
    const event = (res.body as Body).events[0] as Extract<
      BattleEvent,
      { type: 'item_used' }
    >;
    expect(event.hp).toBeGreaterThan(100);

    const body = await fleeUntilOver(user);

    const row = await prisma.creatureInstance.findFirstOrThrow({
      where: { playerId: user.id },
    });
    expect(row.currentHp).toBe(body.battle.player.team[0]!.hp);
  });

  it('comprar com a luta aberta não muda a bag, e o fim não apaga a compra', async () => {
    const user = await strongUser();
    await give(user, 1);
    await user.start().expect(201);
    await user.buy().expect(200);

    const res = await user.act(USE_TONIC()).expect(200);
    expect((res.body as Body).battle.player.items).toEqual([]);
    await fleeUntilOver(user);

    expect(await quantityInDb(user)).toBe(1);
  });

  it('uma luta abandonada não gasta o item', async () => {
    const user = await strongUser();
    await give(user, 1);
    await user.start().expect(201);
    await user.act(USE_TONIC()).expect(200);

    const res = await user.start().expect(201);

    expect((res.body as Body).battle.player.items).toEqual([
      { item_id: tonic.id, quantity: 1 },
    ]);
    expect(await quantityInDb(user)).toBe(1);
  });

  it('sem o item, dá 400, e a luta continua', async () => {
    const user = await strongUser();
    await user.start().expect(201);

    const res = await user.act(USE_TONIC()).expect(400);

    expect(res.body.message).toBe(NO_ITEM);
    await user.act(FLEE).expect(200);
  });

  it('com HP cheio, dá 400 sem gastar o item', async () => {
    const user = await strongUser();
    await give(user, 1);
    const opening = (await user.start().expect(201)).body as Body;
    await prisma.creatureInstance.updateMany({
      where: { playerId: user.id },
      data: { currentHp: opening.battle.player.team[0]!.max_hp },
    });
    await user.start().expect(201);

    const res = await user.act(USE_TONIC()).expect(400);

    expect(res.body.message).toBe(NO_EFFECT);
    expect(await quantityInDb(user)).toBe(1);
  });

  it.each([
    ['sem item_id', { type: 'item', team_index: 0 }],
    ['sem team_index', { type: 'item', item_id: 4 }],
    ['com item_id em texto', { type: 'item', item_id: 'x', team_index: 0 }],
  ])('%s, dá 400', async (_name, body) => {
    const user = await strongUser();
    await user.start().expect(201);
    const res = await user.act(body).expect(400);
    expect(res.body.message).toContain(INVALID_ACTION);
  });
});
