import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { MIN_STEP_MS } from '../src/domain/exploration/hex.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

// Os itens no chão das ilhas e a missão "Encontre X item" (auralis/09). As
// ilhas de teste ficam no fim da ordem do Arquipélago, longe das dos outros e2e.

const RUVO = 1;
const BASE_ORDER = 940_000;
const ONCE_KEY = 11;
const BACK_KEY = 12;
const HIDDEN_KEY = 13;

interface GroundItem {
  key: number;
  item_id: number;
  q: number;
  r: number;
  quantity: number;
  hidden: boolean;
}

function hexTiles() {
  const tiles = [];
  for (let q = -2; q <= 2; q++) {
    for (let r = -2; r <= 2; r++) {
      if (Math.abs(q + r) <= 2) {
        tiles.push({ q, r, biome: 'temperate', height: 1, variant: 1 });
      }
    }
  }
  return tiles;
}

const wait = (ms: number) => new Promise((done) => setTimeout(done, ms));
const step = () => wait(MIN_STEP_MS * 2 + 50);

describe('Os itens no chão (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let owner: string;
  let potion: { id: number; name: string };
  const editor = randomUUID();
  const islands: number[] = [];
  const npcs: number[] = [];
  const users: string[] = [];

  const editorCall = () => request(app.getHttpServer());

  async function player() {
    const id = randomUUID();
    users.push(id);
    const auth = { Authorization: `Bearer ${await tokens.sign(id)}` };
    const http = () => request(app.getHttpServer());
    await http().post('/v1/me').set(auth).send({}).expect(201);
    await http()
      .post('/v1/me/starter')
      .set(auth)
      .send({ species_id: RUVO })
      .expect(200);
    await prisma.player.update({ where: { id }, data: { coins: 100_000 } });
    return {
      id,
      unlock: (islandId: number) =>
        http()
          .put(`/v1/me/archipelago/${islandId}/unlock`)
          .set(auth)
          .expect(204),
      explore: async (islandId?: number) =>
        (
          await http()
            .post('/v1/me/exploration')
            .set(auth)
            .send(islandId === undefined ? {} : { island_id: islandId })
            .expect(201)
        ).body as { ground_items: GroundItem[] },
      pick: (key: number) =>
        http().post('/v1/me/ground-items/pick').set(auth).send({ key }),
      accept: (questId: number) =>
        http()
          .post('/v1/me/quests/accept')
          .set(auth)
          .send({ quest_id: questId })
          .expect(200),
      buy: (itemId: number) =>
        http()
          .post('/v1/me/shop/buy')
          .set(auth)
          .send({ item_id: itemId })
          .expect(200),
    };
  }

  const bag = async (userId: string, itemId: number) =>
    (
      await prisma.inventoryItem.findUnique({
        where: { playerId_itemId: { playerId: userId, itemId } },
      })
    )?.quantity ?? 0;

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({
      tokenVerifier: tokens.verifier,
      env: { MAP_EDITOR_USER_IDS: [editor] },
    });
    owner = await tokens.sign(editor);
    potion = await prisma.item.findFirstOrThrow({
      where: { healAmount: { not: null } },
      orderBy: { id: 'asc' },
      select: { id: true, name: true },
    });
  });

  afterAll(async () => {
    await prisma.island.deleteMany({ where: { id: { in: islands } } });
    await prisma.npc.deleteMany({ where: { id: { in: npcs } } });
    await prisma.player.deleteMany({ where: { id: { in: users } } });
    await prisma.$disconnect();
    await app.close();
  });

  it('o editor guarda os itens, e pegar vai para a Mochila; o "só uma vez" não volta, e o outro volta a cada entrada', async () => {
    const { id: giver } = await prisma.npc.create({
      data: {
        slug: `zz_test_ground_${randomUUID().slice(0, 8)}`,
        name: 'Lia',
        description: 'Teste.',
        sprite: 'ruvo',
      },
    });
    npcs.push(giver);
    const items = [
      {
        key: ONCE_KEY,
        item_id: potion.id,
        q: 1,
        r: 0,
        quantity: 2,
        once: true,
        hidden: false,
      },
      {
        key: BACK_KEY,
        item_id: potion.id,
        q: -1,
        r: 0,
        quantity: 1,
        once: false,
        hidden: false,
      },
      {
        key: HIDDEN_KEY,
        item_id: potion.id,
        q: 0,
        r: 1,
        quantity: 1,
        once: true,
        hidden: true,
      },
    ];
    const body = {
      name: 'Itens no chão A',
      start: { q: 0, r: 0 },
      tiles: hexTiles(),
      actions: [],
      areas: [],
      npcs: [
        {
          npc_id: giver,
          q: 0,
          r: -1,
          still: true,
          tiles: [],
          dialogue: 'Olá!',
          action_type_id: null,
        },
      ],
      items,
    };
    const bad = await editorCall()
      .post('/v1/editor/islands')
      .set('Authorization', `Bearer ${owner}`)
      .send({ ...body, items: [{ ...items[0], item_id: 2_000_000_000 }] })
      .expect(400);
    expect((bad.body as { message: string }).message).toBe(
      'O item no chão 1 não existe no catálogo.',
    );
    const created = await editorCall()
      .post('/v1/editor/islands')
      .set('Authorization', `Bearer ${owner}`)
      .send(body)
      .expect(201);
    const islandId = (created.body as { id: number }).id;
    islands.push(islandId);
    const saved = await editorCall()
      .get(`/v1/editor/islands/${islandId}`)
      .set('Authorization', `Bearer ${owner}`)
      .expect(200);
    expect((saved.body as { items: unknown[] }).items).toEqual(items);
    await editorCall()
      .post(`/v1/editor/islands/${islandId}/publish`)
      .set('Authorization', `Bearer ${owner}`)
      .expect(200);
    await prisma.island.update({
      where: { id: islandId },
      data: { archipelagoOrder: BASE_ORDER + 1 },
    });
    const quest = await prisma.quest.create({
      data: {
        islandId,
        npcId: giver,
        position: 1,
        questTypeId: 10,
        targetItemId: potion.id,
        amount: 4,
      },
    });

    const me = await player();
    await me.unlock(islandId);
    const random = await me.explore();
    expect(random.ground_items).toEqual([]);
    expect((await me.pick(ONCE_KEY).expect(409)).body.message).toBe(
      'Itens no chão só numa ilha.',
    );

    const entered = await me.explore(islandId);
    expect(entered.ground_items).toEqual(
      items.map(({ key, item_id, q, r, quantity, hidden }) => ({
        key,
        item_id,
        q,
        r,
        quantity,
        hidden,
      })),
    );

    // Antes de aceitar, a compra não conta; depois, a Loja e o chão contam.
    await me.buy(potion.id);
    await me.accept(quest.id);
    const progress = async () =>
      (
        await prisma.playerQuest.findUniqueOrThrow({
          where: { playerId_questId: { playerId: me.id, questId: quest.id } },
        })
      ).progress;
    expect(await progress()).toBe(0);
    await me.buy(potion.id);
    expect(await progress()).toBe(1);

    const before = await bag(me.id, potion.id);
    await step();
    const picked = await me.pick(ONCE_KEY).expect(200);
    expect(picked.body).toEqual({
      item_id: potion.id,
      quantity: 2,
      line: `Você encontrou 2 ${potion.name}!`,
    });
    expect(await bag(me.id, potion.id)).toBe(before + 2);
    expect(await progress()).toBe(3);
    await me.pick(ONCE_KEY).expect(404);

    await step();
    await step();
    await me.pick(BACK_KEY).expect(200);
    expect(await progress()).toBe(4);
    expect((await me.pick(BACK_KEY).expect(404)).body.message).toBe(
      'Esse item não está mais aqui.',
    );

    const again = await me.explore(islandId);
    expect(again.ground_items.map(({ key }) => key)).toEqual([
      BACK_KEY,
      HIDDEN_KEY,
    ]);
    await me.pick(2_000_000_000).expect(404);
  }, 90_000);
});
