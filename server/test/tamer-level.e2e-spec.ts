import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { BattleStore } from '../src/battle/battle.store.js';
import { TAMER_XP_MULTIPLIER, xpYield } from '../src/domain/progression/xp.js';
import { Item, PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import {
  type PlayableBattle,
  playOut as playBoard,
  waitVez,
} from './support/board-play.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';
import { HERE, placeWild } from './support/wild.js';

const RUVO = 1;
const TEMPESTIDE = 19;
const ENEMY_LEVEL = 30;

interface TamerProgressBody {
  xp_gained: number;
  level_before: number;
  level_after: number;
  current_xp: number;
  level_xp: number;
  next_level_xp: number | null;
  levels: {
    level: number;
    reward_coins: number;
    reward_item_id: number | null;
    reward_item_quantity: number | null;
  }[];
}

interface BoardBody {
  battle: PlayableBattle & { result: string | null };
  events: { type: string; amount?: number }[];
  tamer_progress: TamerProgressBody | null;
}

interface MeBody {
  player: {
    level: number;
    xp: number;
    level_xp: number;
    next_level_xp: number | null;
    coins: number;
  };
}

describe('Nível do Domador (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let sphere: Item;
  let sources: Map<string, number>;
  const users: string[] = [];

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({ tokenVerifier: tokens.verifier });
    sphere = await prisma.item.findFirstOrThrow({
      where: { captureBonus: { not: null } },
    });
    const rows = await prisma.tamerXpSource.findMany();
    sources = new Map(rows.map(({ slug, amount }) => [slug, amount]));
  });

  afterAll(async () => {
    await prisma.player.deleteMany({ where: { id: { in: users } } });
    await prisma.$disconnect();
    await app.close();
  });

  async function newUser(level = 100) {
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
      data: { level, currentHp: level === 1 ? 1 : 300 },
    });
    const act = async (body: object) =>
      (
        await http()
          .post('/v1/me/board-battle/action')
          .set(auth)
          .send(body)
          .expect(200)
      ).body as BoardBody;
    return {
      id,
      me: async () =>
        (await http().get('/v1/me').set(auth).expect(200)).body as MeBody,
      start: async (body: object) =>
        (
          await http()
            .post('/v1/me/board-battle')
            .set(auth)
            .send(body)
            .expect(201)
        ).body as BoardBody,
      wild: async (body: object) =>
        (
          await http()
            .post('/v1/me/board-battle/wild')
            .set(auth)
            .send(body)
            .expect(201)
        ).body as BoardBody,
      tamer: async () =>
        (
          await http()
            .post('/v1/me/board-battle/tamer')
            .set(auth)
            .send(HERE)
            .expect(201)
        ).body as BoardBody,
      skillTest: (body: object) =>
        http().post('/v1/me/board-battle/skill-test').set(auth).send(body),
      act,
      playOut: (first: BoardBody, vez?: typeof waitVez) =>
        playBoard(act, first, vez as never) as Promise<BoardBody>,
    };
  }

  type User = Awaited<ReturnType<typeof newUser>>;

  async function rawXp(level: number): Promise<number> {
    const { baseXpYield } = await prisma.species.findUniqueOrThrow({
      where: { id: RUVO },
    });
    return xpYield(baseXpYield, level);
  }

  const battleShare = (raw: number) =>
    Math.floor((raw * sources.get('battle_xp_percent')!) / 100);

  async function capture(user: User, speciesId: number): Promise<BoardBody> {
    await prisma.inventoryItem.upsert({
      where: { playerId_itemId: { playerId: user.id, itemId: sphere.id } },
      create: { playerId: user.id, itemId: sphere.id, quantity: 1 },
      update: { quantity: { increment: 1 } },
    });
    const started = await user.start({
      enemies: [{ species_id: speciesId, level: 1 }],
    });
    const { catalog } = app.get(BattleStore).get(user.id)!;
    catalog.captureRates.set(speciesId, 100);
    catalog.items.get(sphere.id)!.captureBonus = 1000;
    const last = await user.act({
      position: 0,
      action: {
        type: 'capture',
        item_id: sphere.id,
        target: started.battle.enemy.cells[0]!,
      },
    });
    expect(last.battle.result).toBe('captured');
    return last;
  }

  it('um Domador novo está no nível 1, com 0 XP e o próximo nível do catálogo', async () => {
    const user = await newUser();
    const second = await prisma.tamerLevel.findUniqueOrThrow({
      where: { level: 2 },
    });
    expect((await user.me()).player).toMatchObject({
      level: 1,
      xp: 0,
      level_xp: 0,
      next_level_xp: second.xpTotal,
    });
  });

  it('vencer um selvagem dá a parte da luta, mesmo com a equipe no nível 100', async () => {
    const user = await newUser(100);
    const last = await user.playOut(
      await user.start({ enemies: [{ species_id: RUVO, level: ENEMY_LEVEL }] }),
    );
    expect(last.battle.result).toBe('victory');
    const expected = battleShare(await rawXp(ENEMY_LEVEL));
    expect(expected).toBeGreaterThan(0);
    expect(last.tamer_progress?.xp_gained).toBe(expected);
    expect((await user.me()).player.xp).toBe(expected);
  });

  it('vencer um Domador NPC soma a vitória contra Domador', async () => {
    const user = await newUser(100);
    placeWild(
      app,
      user.id,
      [],
      [{ team: [{ speciesId: RUVO, level: ENEMY_LEVEL }] }],
    );
    const last = await user.playOut(await user.tamer());
    expect(last.battle.result).toBe('victory');
    const raw = Math.floor((await rawXp(ENEMY_LEVEL)) * TAMER_XP_MULTIPLIER);
    expect(last.tamer_progress?.xp_gained).toBe(
      battleShare(raw) + sources.get('tamer_win')!,
    );
  });

  it('capturar uma espécie nova dá o XP dela; a mesma espécie de novo não dá nada', async () => {
    const user = await newUser();
    const first = await capture(user, TEMPESTIDE);
    expect(first.tamer_progress?.xp_gained).toBe(sources.get('new_species'));
    const again = await capture(user, TEMPESTIDE);
    expect(again.tamer_progress).toBeNull();
    expect((await user.me()).player.xp).toBe(sources.get('new_species'));
  });

  it('perder não dá XP ao Domador', async () => {
    const user = await newUser(1);
    const last = await user.playOut(
      await user.start({ enemies: [{ species_id: RUVO, level: 100 }] }),
      waitVez,
    );
    expect(last.battle.result).toBe('defeat');
    expect(last.tamer_progress).toBeNull();
    expect((await user.me()).player.xp).toBe(0);
  });

  it('a luta em modo deus e a luta de teste da Técnica não dão XP', async () => {
    const user = await newUser(100);
    placeWild(app, user.id, [{ speciesId: RUVO, level: ENEMY_LEVEL }]);
    const god = await user.playOut(await user.wild({ ...HERE, god: true }));
    expect(god.battle.result).toBe('victory');
    expect(god.tamer_progress).toBeNull();

    const scratch = await prisma.skill.findUniqueOrThrow({
      where: { slug: 'arranhao' },
    });
    const res = await user
      .skillTest({
        skill_id: scratch.id,
        species_id: RUVO,
        enemy_species_id: RUVO,
        level: 30,
        enemy_idle: true,
      })
      .expect(201);
    const test = await user.playOut(res.body as BoardBody);
    expect(test.battle.result).toBe('victory');
    expect(test.tamer_progress).toBeNull();
    expect((await user.me()).player.xp).toBe(0);
  });

  it('subir vários níveis paga cada recompensa uma vez, com as moedas e os itens', async () => {
    const user = await newUser();
    const levels = await prisma.tamerLevel.findMany({
      orderBy: { level: 'asc' },
    });
    const fifth = levels.find(({ level }) => level === 5)!;
    const startXp = fifth.xpTotal - 1;
    await prisma.player.update({
      where: { id: user.id },
      data: { xp: startXp, level: 4 },
    });
    const before = (await user.me()).player;
    const items = await prisma.inventoryItem.findMany({
      where: { playerId: user.id },
    });

    const last = await capture(user, TEMPESTIDE);
    const gained = sources.get('new_species')!;
    const reached = levels.filter(
      ({ level, xpTotal }) => level > 4 && xpTotal <= startXp + gained,
    );
    expect(reached.length).toBeGreaterThanOrEqual(1);
    expect(last.tamer_progress).toMatchObject({
      xp_gained: gained,
      level_before: 4,
      level_after: reached.at(-1)!.level,
      current_xp: startXp + gained,
    });
    expect(last.tamer_progress!.levels.map(({ level }) => level)).toEqual(
      reached.map(({ level }) => level),
    );

    const after = (await user.me()).player;
    expect(after.level).toBe(reached.at(-1)!.level);
    const battleCoins = last.events.reduce(
      (sum, event) =>
        event.type === 'coins_gained'
          ? sum + event.amount!
          : event.type === 'coins_lost'
            ? sum - event.amount!
            : sum,
      0,
    );
    const rewardCoins = reached.reduce((sum, row) => sum + row.rewardCoins, 0);
    expect(after.coins - before.coins).toBe(battleCoins + rewardCoins);

    const quantity = async (itemId: number) =>
      (
        await prisma.inventoryItem.findUnique({
          where: { playerId_itemId: { playerId: user.id, itemId } },
        })
      )?.quantity ?? 0;
    // A Esfera da captura entra e sai na própria captura.
    const rewards = new Map<number, number>();
    for (const { rewardItemId, rewardItemQuantity } of reached) {
      if (rewardItemId === null) continue;
      rewards.set(
        rewardItemId,
        (rewards.get(rewardItemId) ?? 0) + rewardItemQuantity!,
      );
    }
    for (const [itemId, reward] of rewards) {
      const had = items.find((row) => row.itemId === itemId)?.quantity ?? 0;
      expect(await quantity(itemId)).toBe(had + reward);
    }
  });
});
