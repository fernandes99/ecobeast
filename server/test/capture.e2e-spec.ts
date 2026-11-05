import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { BattleStore } from '../src/battle/battle.store.js';
import type { BattleEvent } from '../src/domain/battle/types.js';
import { Item, PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';
import { HERE, placeWild } from './support/wild.js';

// O sorteio não é controlável pela API: cada teste troca a taxa e o bônus da
// luta no `BattleStore`, sem conferir os valores do catálogo.

const RUVO = 1;
const WEAK_ENEMY = { species_id: RUVO, level: 1 };
const FLEE = { type: 'flee' };
const NOT_CAPTURABLE = 'Esse Ecobeast não pode ser capturado.';
const CANNOT_USE = 'Esse item não pode ser usado agora.';
const NO_ITEM = 'Você não tem esse item.';
const INVALID_ACTION = 'Ação inválida.';
/** A fuga falha às vezes: bem mais tentativas do que ela precisa. */
const MAX_TRIES = 60;

interface Body {
  battle: { phase: string; result: string | null; turn: number };
  events: BattleEvent[];
  captured_to: string | null;
}

describe('Captura (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let sphere: Item;
  let tonic: Item;
  const users: string[] = [];

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({ tokenVerifier: tokens.verifier });
    sphere = await prisma.item.findFirstOrThrow({
      where: { captureBonus: { not: null } },
    });
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
  async function strongUser(spheres = 3) {
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
    await prisma.creatureInstance.updateMany({
      where: { playerId: id },
      data: { level: 100, currentHp: 100 },
    });
    await prisma.inventoryItem.create({
      data: { playerId: id, itemId: sphere.id, quantity: spheres },
    });
    return {
      id,
      me: () => http().get('/v1/me').set(auth),
      remove: () => http().delete('/v1/me').set(auth),
      start: () => http().post('/v1/me/battle').set(auth).send(WEAK_ENEMY),
      wild: () => {
        placeWild(app, id);
        return http().post('/v1/me/battle/wild').set(auth).send(HERE);
      },
      act: (body: object) =>
        http().post('/v1/me/battle/action').set(auth).send(body),
    };
  }

  type User = Awaited<ReturnType<typeof strongUser>>;

  const CAPTURE = () => ({ type: 'capture', item_id: sphere.id });

  function stored(user: User) {
    return app.get(BattleStore).get(user.id)!;
  }

  /** Taxa e bônus só desta luta, que fazem a chance virar certeza ou quase zero. */
  function force(user: User, success: boolean) {
    const { catalog } = stored(user);
    catalog.captureRates.set(RUVO, success ? 100 : 1);
    catalog.items.get(sphere.id)!.captureBonus = success ? 1000 : 1e-12;
  }

  async function capture(user: User, success: boolean): Promise<Body> {
    force(user, success);
    return (await user.act(CAPTURE()).expect(200)).body as Body;
  }

  async function spheresInDb(user: User) {
    const row = await prisma.inventoryItem.findUnique({
      where: { playerId_itemId: { playerId: user.id, itemId: sphere.id } },
    });
    return row?.quantity ?? 0;
  }

  function creatures(user: User) {
    return prisma.creatureInstance.findMany({
      where: { playerId: user.id },
      orderBy: { caughtAt: 'asc' },
      include: {
        stats: { include: { stat: true } },
        skills: { orderBy: { slot: 'asc' } },
        statusCondition: true,
      },
    });
  }

  /** Cópias do inicial nas vagas pedidas. */
  async function fillSlots(user: User, slots: number[]) {
    const [row] = await creatures(user);
    for (const partySlot of slots) {
      await prisma.creatureInstance.create({
        data: {
          playerId: user.id,
          speciesId: row!.speciesId,
          level: row!.level,
          currentXp: row!.currentXp,
          currentHp: row!.currentHp,
          temperamentId: row!.temperamentId,
          traitId: row!.traitId,
          gender: row!.gender,
          bond: row!.bond,
          location: 'party',
          partySlot,
          originalPlayerId: user.id,
          caughtAt: row!.caughtAt,
          stats: {
            create: row!.stats.map(({ statId, genes, trainingPoints }) => ({
              statId,
              genes,
              trainingPoints,
            })),
          },
          skills: {
            create: row!.skills.map(({ slot, skillId, currentPp }) => ({
              slot,
              skillId,
              currentPp,
            })),
          },
        },
      });
    }
  }

  async function fleeUntilOver(user: User) {
    for (let tries = 0; tries < MAX_TRIES; tries += 1) {
      const res = await user.act(FLEE).expect(200);
      if ((res.body as Body).battle.phase === 'ended') return;
    }
    throw new Error('A fuga não terminou a luta.');
  }

  describe('com sucesso', () => {
    it('a luta acaba, e o Ecobeast entra na equipe', async () => {
      const user = await strongUser();
      await user.start().expect(201);

      const body = await capture(user, true);

      expect(body.events).toEqual([
        {
          type: 'capture_attempted',
          item_id: sphere.id,
          success: true,
          target: 0,
          captured_to: 'party',
        },
        { type: 'battle_ended', result: 'captured' },
      ]);
      expect(body.battle.result).toBe('captured');
      expect(body.captured_to).toBe('party');
      const me = await user.me().expect(200);
      expect(me.body.player.party).toHaveLength(2);
    });

    it('funciona no encontro selvagem', async () => {
      const user = await strongUser();
      await user.wild().expect(201);
      const { catalog, state } = stored(user);
      catalog.captureRates.set(state.enemy.team[0]!.speciesId, 100);
      catalog.items.get(sphere.id)!.captureBonus = 1000;

      const res = await user.act(CAPTURE()).expect(200);

      expect((res.body as Body).captured_to).toBe('party');
    });

    it('grava os Genes, o Temperamento, o Traço e o gênero do inimigo', async () => {
      const user = await strongUser();
      await user.start().expect(201);
      const { creature } = stored(user).wilds[0]!;

      await capture(user, true);

      const [, caught] = await creatures(user);
      expect(caught).toMatchObject({
        speciesId: RUVO,
        level: 1,
        temperamentId: creature.temperamentId,
        traitId: creature.traitId,
        gender: creature.gender,
        currentXp: creature.currentXp,
        bond: creature.bond,
        originalPlayerId: user.id,
        location: 'party',
        partySlot: 2,
        nickname: null,
        heldItemId: null,
      });
      expect(caught!.caughtAt).toBeInstanceOf(Date);
      const genes = Object.fromEntries(
        caught!.stats.map(({ stat, genes: value }) => [stat.slug, value]),
      );
      expect(genes).toEqual(creature.genes);
    });

    it('grava o HP, o status e os PP do fim da luta', async () => {
      const user = await strongUser();
      await user.start().expect(201);
      const enemy = stored(user).state.enemy.team[0]!;
      enemy.currentHp = 3;
      enemy.statusSlug = 'poison';
      enemy.skills[0]!.currentPp = 7;

      await capture(user, true);

      const [, caught] = await creatures(user);
      expect(caught!.currentHp).toBe(3);
      expect(caught!.statusCondition!.slug).toBe('poison');
      expect(caught!.skills[0]!.currentPp).toBe(7);
    });

    it('gasta a Esfera', async () => {
      const user = await strongUser(2);
      await user.start().expect(201);
      await capture(user, true);
      expect(await spheresInDb(user)).toBe(1);
    });

    it('a resposta não mostra os Genes do inimigo', async () => {
      const user = await strongUser();
      await user.start().expect(201);
      force(user, true);
      const res = await user.act(CAPTURE()).expect(200);
      expect(JSON.stringify(res.body)).not.toMatch(/genes|temperament|wild/i);
    });

    it('com uma vaga no meio, entra nela', async () => {
      const user = await strongUser();
      await fillSlots(user, [3]);
      await user.start().expect(201);

      await capture(user, true);

      const row = await prisma.creatureInstance.findFirstOrThrow({
        where: { playerId: user.id, partySlot: 2 },
      });
      expect(row.level).toBe(1);
    });

    it('com a equipe cheia, vai para o Santuário', async () => {
      const user = await strongUser();
      await fillSlots(user, [2, 3, 4, 5, 6]);
      await user.start().expect(201);

      const body = await capture(user, true);

      expect(body.captured_to).toBe('storage');
      const stored = await prisma.creatureInstance.findFirstOrThrow({
        where: { playerId: user.id, location: 'storage' },
      });
      expect(stored.partySlot).toBeNull();
      const me = await user.me().expect(200);
      expect(me.body.player.party).toHaveLength(6);
    });

    it('o capturado pode lutar na próxima batalha', async () => {
      const user = await strongUser();
      await user.start().expect(201);
      await capture(user, true);

      const res = await user.start().expect(201);

      expect(res.body.battle.player.team).toHaveLength(2);
    });

    it('com o Domador apagado no meio da luta, não grava nada', async () => {
      const user = await strongUser();
      await user.start().expect(201);
      force(user, true);
      await user.remove().expect(204);

      const res = await user.act(CAPTURE()).expect(200);

      expect((res.body as Body).captured_to).toBeNull();
      expect(await creatures(user)).toEqual([]);
    });

    it('uma falha na gravação não deixa nada pela metade', async () => {
      const user = await strongUser();
      await user.start().expect(201);
      force(user, true);
      const wild = stored(user).wilds[0]!;
      wild.statIds = { ...wild.statIds, hp: -1 };

      await user.act(CAPTURE()).expect(500);

      expect(await creatures(user)).toHaveLength(1);
      expect(await spheresInDb(user)).toBe(3);
    });
  });

  describe('com falha', () => {
    it('o inimigo age, a luta segue e ninguém é capturado', async () => {
      const user = await strongUser();
      const opening = (await user.start().expect(201)).body as Body;

      const body = await capture(user, false);

      expect(body.events[0]).toEqual({
        type: 'capture_attempted',
        item_id: sphere.id,
        success: false,
        target: 0,
        captured_to: null,
      });
      expect(body.events.map((event) => event.type)).toContain('skill_used');
      expect(body.battle.phase).toBe('choose_action');
      expect(body.battle.turn).toBe(opening.battle.turn + 1);
      expect(body.captured_to).toBeNull();
      expect(await creatures(user)).toHaveLength(1);
    });

    it('a Esfera sai da Mochila no fim da luta', async () => {
      const user = await strongUser(2);
      await user.start().expect(201);
      await capture(user, false);
      expect(await spheresInDb(user)).toBe(2);

      await fleeUntilOver(user);

      expect(await spheresInDb(user)).toBe(1);
    });

    it('uma luta abandonada não gasta a Esfera', async () => {
      const user = await strongUser(2);
      await user.start().expect(201);
      await capture(user, false);

      await user.start().expect(201);

      expect(await spheresInDb(user)).toBe(2);
    });
  });

  describe('recusas', () => {
    it('capture_rate 0 dá 400, sem gastar a Esfera', async () => {
      const user = await strongUser();
      const opening = (await user.start().expect(201)).body as Body;
      stored(user).catalog.captureRates.set(RUVO, 0);

      const res = await user.act(CAPTURE()).expect(400);

      expect(res.body.message).toBe(NOT_CAPTURABLE);
      expect(stored(user).state.bag[0]!.used).toBe(0);
      expect(stored(user).state.turn).toBe(opening.battle.turn);
    });

    it('um Tônico dá 400', async () => {
      const user = await strongUser();
      await prisma.inventoryItem.create({
        data: { playerId: user.id, itemId: tonic.id, quantity: 1 },
      });
      await user.start().expect(201);

      const res = await user
        .act({ type: 'capture', item_id: tonic.id })
        .expect(400);

      expect(res.body.message).toBe(CANNOT_USE);
    });

    it('sem a Esfera, dá 400', async () => {
      const user = await strongUser();
      await prisma.inventoryItem.deleteMany({ where: { playerId: user.id } });
      await user.start().expect(201);

      const res = await user.act(CAPTURE()).expect(400);

      expect(res.body.message).toBe(NO_ITEM);
    });

    it('uma Esfera na ação `item` continua recusada', async () => {
      const user = await strongUser();
      await user.start().expect(201);

      const res = await user
        .act({ type: 'item', item_id: sphere.id, team_index: 0 })
        .expect(400);

      expect(res.body.message).toBe(CANNOT_USE);
    });

    it.each([
      ['sem item_id', { type: 'capture' }],
      ['com item_id em texto', { type: 'capture', item_id: 'x' }],
    ])('%s, dá 400', async (_name, body) => {
      const user = await strongUser();
      await user.start().expect(201);
      const res = await user.act(body).expect(400);
      expect(res.body.message).toContain(INVALID_ACTION);
    });
  });

  it('as outras ações respondem `captured_to` nulo', async () => {
    const user = await strongUser();
    const opening = (await user.start().expect(201)).body as Body;
    expect(opening.captured_to).toBeNull();
  });
});
