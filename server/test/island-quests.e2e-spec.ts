import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { type Prisma, PrismaClient } from '../src/generated/prisma/client.js';
import { MIN_STEP_MS } from '../src/domain/exploration/hex.js';
import { createTestApp } from './support/app.js';
import { playOut } from './support/board-play.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

// As missões das ilhas (auralis/06). As ilhas de teste ficam no fim da ordem do
// Arquipélago, longe das dos outros e2e.

const RUVO = 1;
const BASE_ORDER = 930_000;
const NOT_ON_ISLAND = 'Missões só numa ilha.';
const NPC_NOT_HERE = 'Esse NPC não está nesta ilha.';

interface Place {
  quest_id: number;
  name: string;
  tiles: { q: number; r: number }[];
}

interface TalkBody {
  lines: string[];
  reward: {
    coins: number;
    item_id: number | null;
    item_quantity: number | null;
    xp: number;
  } | null;
  tamer_progress: { xp_gained: number } | null;
  island_unlocked: { id: number; name: string } | null;
  quest_places: Place[];
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

describe('As missões das ilhas (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let owner: string;
  let questXp: number;
  const editor = randomUUID();
  const islands: number[] = [];
  const npcs: number[] = [];
  const users: string[] = [];

  async function npc(name: string): Promise<number> {
    const { id } = await prisma.npc.create({
      data: {
        slug: `zz_test_quest_${randomUUID().slice(0, 8)}`,
        name,
        description: 'Teste.',
        sprite: 'ruvo',
      },
    });
    npcs.push(id);
    return id;
  }

  async function island(
    name: string,
    order: number,
    npcIds: number[],
  ): Promise<number> {
    const response = await request(app.getHttpServer())
      .post('/v1/editor/islands')
      .set('Authorization', `Bearer ${owner}`)
      .send({
        name,
        start: { q: 0, r: 0 },
        tiles: hexTiles(),
        actions: [],
        areas: [],
        npcs: npcIds.map((npc_id, index) => ({
          npc_id,
          q: index - 1,
          r: -1,
          still: true,
          tiles: [],
          dialogue: 'Olá!',
          action_type_id: null,
        })),
      })
      .expect(201);
    const id = (response.body as { id: number }).id;
    islands.push(id);
    await request(app.getHttpServer())
      .post(`/v1/editor/islands/${id}/publish`)
      .set('Authorization', `Bearer ${owner}`)
      .expect(200);
    await prisma.island.update({
      where: { id },
      data: { archipelagoOrder: order },
    });
    return id;
  }

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
    await prisma.creatureInstance.updateMany({
      where: { playerId: id },
      data: { level: 100, currentHp: 300 },
    });
    const act = async (body: object) =>
      (
        await http()
          .post('/v1/me/board-battle/action')
          .set(auth)
          .send(body)
          .expect(200)
      ).body as never;
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
        ).body as { quest_places: Place[] },
      talk: (npcId: number) =>
        http().post('/v1/me/quests/talk').set(auth).send({ npc_id: npcId }),
      said: async (npcId: number) =>
        (
          await http()
            .post('/v1/me/quests/talk')
            .set(auth)
            .send({ npc_id: npcId })
            .expect(200)
        ).body as TalkBody,
      reach: (q: number, r: number) =>
        http().post('/v1/me/quests/reach').set(auth).send({ q, r }),
      win: async (npcId: number) =>
        playOut(
          act,
          (
            await http()
              .post('/v1/me/board-battle/island-tamer')
              .set(auth)
              .send({ npc_id: npcId })
              .expect(201)
          ).body as never,
        ),
      discover: (islandId: number, tiles: { q: number; r: number }[]) =>
        http()
          .post(`/v1/me/islands/${islandId}/discoveries`)
          .set(auth)
          .send({ tiles })
          .expect(201),
      ping: () =>
        http()
          .post('/v1/me/counters/ping')
          .set(auth)
          .send({ hexes: [] })
          .expect(204),
    };
  }

  const progressOf = async (userId: string, questId: number) =>
    (
      await prisma.playerQuest.findUniqueOrThrow({
        where: { playerId_questId: { playerId: userId, questId } },
      })
    ).progress;

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({
      tokenVerifier: tokens.verifier,
      env: { MAP_EDITOR_USER_IDS: [editor] },
    });
    owner = await tokens.sign(editor);
    questXp = (
      await prisma.tamerXpSource.findUniqueOrThrow({ where: { slug: 'quest' } })
    ).amount;
  });

  afterAll(async () => {
    await prisma.island.deleteMany({ where: { id: { in: islands } } });
    await prisma.tamer.deleteMany({ where: { npcId: { in: npcs } } });
    await prisma.npc.deleteMany({ where: { id: { in: npcs } } });
    await prisma.player.deleteMany({ where: { id: { in: users } } });
    await prisma.$disconnect();
    await app.close();
  });

  it('o NPC dá a missão, mostra o progresso, entrega e dá a seguinte; a última abre a ilha seguinte', async () => {
    const giver = await npc('Vovó');
    const rival = await npc('Caio');
    const first = await island('Missões A', BASE_ORDER + 1, [giver, rival]);
    const second = await island('Missões B', BASE_ORDER + 2, []);
    await prisma.tamer.create({
      data: {
        npcId: rival,
        islandId: first,
        countsForUnlock: false,
        creatures: { create: [{ position: 1, speciesId: RUVO, level: 2 }] },
      },
    });
    const potion = await prisma.item.findFirstOrThrow({
      where: { healAmount: { not: null } },
      orderBy: { id: 'asc' },
    });
    const defeat = await prisma.quest.create({
      data: {
        islandId: first,
        npcId: giver,
        position: 1,
        questTypeId: 2,
        amount: 1,
        coins: 50,
        itemId: potion.id,
        itemQuantity: 2,
      },
    });
    const farol = await prisma.quest.create({
      data: {
        islandId: first,
        npcId: giver,
        position: 2,
        questTypeId: 4,
        placeName: 'o Farol',
        tiles: { create: [{ q: 1, r: 0 }] },
      },
    });
    const me = await player();
    await me.unlock(first);

    expect((await me.talk(giver).expect(409)).body.message).toBe(NOT_ON_ISLAND);
    await me.explore(first);
    expect((await me.talk(npcs[0]! + 999_999).expect(409)).body.message).toBe(
      NPC_NOT_HERE,
    );

    const accepted = await me.said(giver);
    expect(accepted.lines).toEqual(['Nova missão: Derrote 1 Ecobeast.']);
    expect(accepted.reward).toBeNull();
    expect((await me.said(giver)).lines).toEqual([
      'Derrote 1 Ecobeast: 0 de 1.',
    ]);

    await me.win(rival);
    expect(await progressOf(me.id, defeat.id)).toBe(1);

    const coinsBefore = (
      await prisma.player.findUniqueOrThrow({ where: { id: me.id } })
    ).coins;
    const claimed = await me.said(giver);
    expect(claimed.lines).toEqual([
      'Missão cumprida: Derrote 1 Ecobeast!',
      'Nova missão: Vá até o Farol.',
    ]);
    expect(claimed.reward).toEqual({
      coins: 50,
      item_id: potion.id,
      item_quantity: 2,
      xp: questXp,
    });
    expect(claimed.tamer_progress!.xp_gained).toBe(questXp);
    expect(claimed.island_unlocked).toBeNull();
    expect(claimed.quest_places).toEqual([
      { quest_id: farol.id, name: 'o Farol', tiles: [{ q: 1, r: 0 }] },
    ]);
    const after = await prisma.player.findUniqueOrThrow({
      where: { id: me.id },
      include: { inventory: { where: { itemId: potion.id } } },
    });
    expect(after.coins).toBeGreaterThanOrEqual(coinsBefore + 50);
    expect(after.inventory[0]!.quantity).toBeGreaterThanOrEqual(2);

    const again = await me.explore(first);
    expect(again.quest_places.map(({ quest_id }) => quest_id)).toEqual([
      farol.id,
    ]);
    await wait(MIN_STEP_MS + 50);
    const reached = (await me.reach(1, 0).expect(200)).body as {
      reached: string[];
      quest_places: Place[];
    };
    expect(reached).toEqual({ reached: ['o Farol'], quest_places: [] });

    const last = await me.said(giver);
    expect(last.lines).toEqual(['Missão cumprida: Vá até o Farol!']);
    expect(last.island_unlocked).toEqual({ id: second, name: 'Missões B' });
    expect(last.reward!.xp).toBeGreaterThan(questXp);
    expect((await me.said(giver)).lines).toEqual([]);
  }, 120_000);

  it('cada tipo soma pelo seu acontecimento, sem passar do alvo', async () => {
    const giver = await npc('Lia');
    const friend = await npc('Téo');
    const rival = await npc('Rui');
    const home = await island('Missões C', BASE_ORDER + 3, [
      giver,
      friend,
      rival,
    ]);
    await prisma.tamer.create({
      data: {
        npcId: rival,
        islandId: home,
        countsForUnlock: false,
        creatures: { create: [{ position: 1, speciesId: RUVO, level: 2 }] },
      },
    });
    const create = (
      position: number,
      data: Omit<
        Prisma.QuestUncheckedCreateInput,
        'islandId' | 'npcId' | 'position'
      >,
    ) =>
      prisma.quest.create({
        data: { islandId: home, npcId: giver, position, ...data },
      });
    const quests = [
      await create(1, { questTypeId: 5, targetNpcId: friend }),
      await create(2, { questTypeId: 7, speciesId: RUVO }),
      await create(3, { questTypeId: 8, speciesId: RUVO, amount: 1 }),
      await create(4, { questTypeId: 9, targetNpcId: rival }),
      await create(5, { questTypeId: 6, amount: 1 }),
      await create(6, { questTypeId: 3, amount: 30 }),
      await create(7, { questTypeId: 1, amount: 2 }),
    ];
    const me = await player();
    await me.unlock(home);
    await me.explore(home);
    await prisma.playerQuest.createMany({
      data: quests.map(({ id }) => ({ playerId: me.id, questId: id })),
    });

    await me.said(friend);
    expect(await progressOf(me.id, quests[0]!.id)).toBe(1);

    await me.win(rival);
    await me.win(rival);
    expect(await progressOf(me.id, quests[1]!.id)).toBe(1);
    expect(await progressOf(me.id, quests[2]!.id)).toBe(1);
    expect(await progressOf(me.id, quests[3]!.id)).toBe(1);
    expect(await progressOf(me.id, quests[6]!.id)).toBe(0);

    await me.explore(home);
    await me.ping();
    await prisma.player.update({
      where: { id: me.id },
      data: { lastPingAt: new Date(Date.now() - 45_000) },
    });
    await me.ping();
    const stayed = await progressOf(me.id, quests[4]!.id);
    expect(stayed).toBeGreaterThanOrEqual(44);
    await prisma.player.update({
      where: { id: me.id },
      data: { lastPingAt: new Date(Date.now() - 45_000) },
    });
    await me.ping();
    expect(await progressOf(me.id, quests[4]!.id)).toBe(60);

    await me.discover(
      home,
      hexTiles()
        .slice(0, 10)
        .map(({ q, r }) => ({ q, r })),
    );
    // As 4 primeiras da fila estão cumpridas e se entregam uma a cada conversa.
    for (let index = 0; index < 5; index++) {
      expect((await me.said(giver)).lines[0]).toMatch(/^Missão cumprida/);
    }
    const explore = await me.said(giver);
    expect(explore.lines[0]).toBe('Missão cumprida: Explore 30% de Missões C!');
    expect(explore.lines[1]).toBe('Nova missão: Capture 2 Ecobeasts.');
  }, 120_000);

  it('no mapa sorteado, os lugares vêm vazios e a conversa é recusada', async () => {
    const me = await player();
    expect((await me.explore()).quest_places).toEqual([]);
    expect((await me.talk(1).expect(409)).body.message).toBe(NOT_ON_ISLAND);
    expect((await me.reach(0, 0).expect(409)).body.message).toBe(NOT_ON_ISLAND);
  });

  it('recusa uma missão sem os parâmetros do tipo', async () => {
    const giver = await npc('Ana');
    const home = await island('Missões D', BASE_ORDER + 4, [giver]);
    await expect(
      prisma.quest.create({
        data: { islandId: home, npcId: giver, position: 1, questTypeId: 1 },
      }),
    ).rejects.toThrow(/quests_params_check/);
    await expect(
      prisma.quest.create({
        data: {
          islandId: home,
          npcId: giver,
          position: 1,
          questTypeId: 3,
          amount: 101,
        },
      }),
    ).rejects.toThrow(/quests_params_check/);
  });
});
