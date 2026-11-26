import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { BattleStore } from '../src/battle/battle.store.js';
import { MIN_STEP_MS } from '../src/domain/exploration/hex.js';
import { ExplorationStore } from '../src/exploration/exploration.store.js';
import { COUNTER_IDS } from '../src/domain/counters/counters.js';
import {
  blocksWalking,
  type Biome,
} from '../src/domain/exploration/map-generator.js';
import { Item, PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import {
  playOut as playBoard,
  type PlayableBattle,
  waitVez,
} from './support/board-play.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

const RUVO = 1;
const TEMPESTIDE = 19;
const WEAK_ENEMY = { species_id: RUVO, level: 1 };
const NO_PLAYER = 'Crie seu Domador primeiro.';

interface CountersBody {
  counters: { counter_id: number; subject_id: number; value: number }[];
  partner: { creature_uid: string; species_id: number; battles: number } | null;
  created_at: string;
  walkable_biomes: number;
}

interface BoardBody {
  battle: PlayableBattle & { result: string | null };
}

describe('Contadores do Domador (e2e)', () => {
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

  async function newUser({ starter = true, level = 100 } = {}) {
    const id = randomUUID();
    users.push(id);
    const auth = { Authorization: `Bearer ${await tokens.sign(id)}` };
    const http = () => request(app.getHttpServer());
    if (starter) {
      await http().post('/v1/me').set(auth).send({ name: 'Ana' }).expect(201);
      await http()
        .post('/v1/me/starter')
        .set(auth)
        .send({ species_id: RUVO })
        .expect(200);
      await prisma.creatureInstance.updateMany({
        where: { playerId: id },
        data: { level, currentHp: 150 },
      });
    }
    const user = {
      id,
      read: () => http().get('/v1/me/counters').set(auth),
      start: async (body: object) =>
        (
          await http()
            .post('/v1/me/board-battle')
            .set(auth)
            .send(body)
            .expect(201)
        ).body as BoardBody,
      act: async (body: object) =>
        (
          await http()
            .post('/v1/me/board-battle/action')
            .set(auth)
            .send(body)
            .expect(200)
        ).body as BoardBody,
      skillTest: (body: object) =>
        http().post('/v1/me/board-battle/skill-test').set(auth).send(body),
      buy: (itemId: number) =>
        http().post('/v1/me/shop/buy').set(auth).send({ item_id: itemId }),
      heal: () => http().post('/v1/me/heal').set(auth),
      explore: () => http().post('/v1/me/exploration').set(auth),
      ping: (hexes: { biome: string; count: number }[] = []) =>
        http().post('/v1/me/counters/ping').set(auth).send({ hexes }),
    };
    return user;
  }

  type User = Awaited<ReturnType<typeof newUser>>;

  async function counters(user: User): Promise<CountersBody> {
    return (await user.read().expect(200)).body as CountersBody;
  }

  function value(body: CountersBody, id: number, subjectId = 0): number {
    return (
      body.counters.find(
        (row) => row.counter_id === id && row.subject_id === subjectId,
      )?.value ?? 0
    );
  }

  const playOut = (user: User, first: BoardBody, vez?: (b: never) => object) =>
    playBoard((body) => user.act(body), first, vez as never);

  it('um Domador novo não tem contadores nem parceiro', async () => {
    const user = await newUser();
    const body = await counters(user);
    const biomes = await prisma.biome.findMany();
    const walkable = biomes.filter(({ slug }) => !blocksWalking(slug as Biome));

    expect(body.counters).toEqual([]);
    expect(body.partner).toBeNull();
    expect(body.walkable_biomes).toBe(walkable.length);
    expect(Number.isNaN(Date.parse(body.created_at))).toBe(false);
  });

  it('sem Domador, responde 404', async () => {
    const user = await newUser({ starter: false });
    const res = await user.read().expect(404);
    expect(res.body.message).toBe(NO_PLAYER);
  });

  it('vencer um selvagem conta a vitória, o XP e o parceiro', async () => {
    const user = await newUser({ level: 50 });
    const last = await playOut(
      user,
      await user.start({ enemies: [WEAK_ENEMY] }),
    );
    expect(last.battle.result).toBe('victory');

    const body = await counters(user);
    expect(value(body, COUNTER_IDS.wins_wild)).toBe(1);
    expect(value(body, COUNTER_IDS.xp_gained)).toBeGreaterThan(0);
    const [creature] = await prisma.creatureInstance.findMany({
      where: { playerId: user.id },
    });
    expect(body.partner).toEqual({
      creature_uid: creature!.uid,
      species_id: RUVO,
      battles: 1,
    });
  });

  it('perder conta a derrota', async () => {
    const user = await newUser({ level: 1 });
    const strong = { species_id: RUVO, level: 100 };
    const last = await playOut(
      user,
      await user.start({ enemies: [strong] }),
      waitVez as never,
    );
    expect(last.battle.result).toBe('defeat');

    const body = await counters(user);
    expect(value(body, COUNTER_IDS.defeats)).toBe(1);
    expect(value(body, COUNTER_IDS.wins_wild)).toBe(0);
  });

  it('capturar com uma Esfera conta a captura, a Esfera, cada Elemento e a parte do dia', async () => {
    const user = await newUser();
    await prisma.inventoryItem.create({
      data: { playerId: user.id, itemId: sphere.id, quantity: 1 },
    });
    const started = await user.start({
      enemies: [{ species_id: TEMPESTIDE, level: 1 }],
    });
    const { catalog } = app.get(BattleStore).get(user.id)!;
    catalog.captureRates.set(TEMPESTIDE, 100);
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

    const body = await counters(user);
    const elements = await prisma.speciesElement.findMany({
      where: { speciesId: TEMPESTIDE },
    });
    expect(value(body, COUNTER_IDS.captures)).toBe(1);
    expect(value(body, COUNTER_IDS.spheres_used)).toBe(1);
    expect(value(body, COUNTER_IDS.captures_first_sphere)).toBe(1);
    expect(elements).toHaveLength(2);
    for (const { elementId } of elements) {
      expect(value(body, COUNTER_IDS.captures_by_element, elementId)).toBe(1);
    }
    const phases = body.counters.filter(
      (row) => row.counter_id === COUNTER_IDS.captures_by_day_phase,
    );
    expect(phases).toHaveLength(1);
    expect(phases[0]!.value).toBe(1);
  });

  it('a luta de teste da Técnica não conta nada', async () => {
    const user = await newUser({ level: 20 });
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
    const last = await playOut(user, res.body as BoardBody);
    expect(last.battle.result).toBe('victory');

    const body = await counters(user);
    expect(body.counters).toEqual([]);
    expect(body.partner).toBeNull();
  });

  it('comprar, curar e explorar contam as moedas gastas, as curas e os mapas', async () => {
    const user = await newUser();
    const item = await prisma.item.findFirstOrThrow({
      where: { price: { gt: 0 } },
      orderBy: { price: 'asc' },
    });
    const price = item.price ?? 0;
    await prisma.player.update({
      where: { id: user.id },
      data: { coins: price * 2 },
    });
    await user.buy(item.id).expect(200);
    await user.buy(item.id).expect(200);
    await user.heal().expect(200);
    await user.explore().expect(201);

    const body = await counters(user);
    expect(value(body, COUNTER_IDS.coins_spent)).toBe(price * 2);
    expect(value(body, COUNTER_IDS.heals)).toBe(1);
    expect(value(body, COUNTER_IDS.maps_explored)).toBe(1);
  });

  describe('o sinal de cada minuto (player-stats/02)', () => {
    async function lastPingAgo(user: User, seconds: number): Promise<void> {
      await prisma.player.update({
        where: { id: user.id },
        data: { lastPingAt: new Date(Date.now() - seconds * 1000) },
      });
    }

    it('o primeiro sinal conta o dia e nada de tempo', async () => {
      const user = await newUser();
      await user.ping().expect(204);

      const body = await counters(user);
      expect(value(body, COUNTER_IDS.play_days)).toBe(1);
      expect(value(body, COUNTER_IDS.play_streak)).toBe(1);
      expect(value(body, COUNTER_IDS.play_seconds)).toBe(0);
    });

    it('o sinal seguinte soma o tempo, e um sinal depois de parado não soma', async () => {
      const user = await newUser();
      await user.ping().expect(204);
      await lastPingAgo(user, 60);
      await user.ping().expect(204);
      await lastPingAgo(user, 300);
      await user.ping().expect(204);

      const body = await counters(user);
      expect(value(body, COUNTER_IDS.play_seconds)).toBeGreaterThanOrEqual(60);
      expect(value(body, COUNTER_IDS.play_seconds)).toBeLessThanOrEqual(62);
      expect(value(body, COUNTER_IDS.play_days)).toBe(1);
    });

    it('jogar no dia seguinte soma a sequência; pular um dia volta a 1', async () => {
      const user = await newUser();
      const day = 24 * 60 * 60 * 1000;
      const today = new Date(Date.now() - 3 * 60 * 60 * 1000);
      const dateOnly = (ms: number) =>
        new Date(new Date(ms).toISOString().slice(0, 10) + 'T00:00:00Z');
      await user.ping().expect(204);
      await prisma.player.update({
        where: { id: user.id },
        data: { lastPlayDay: dateOnly(today.getTime() - day) },
      });
      await user.ping().expect(204);
      expect(value(await counters(user), COUNTER_IDS.play_streak)).toBe(2);

      await prisma.player.update({
        where: { id: user.id },
        data: { lastPlayDay: dateOnly(today.getTime() - 2 * day) },
      });
      await user.ping().expect(204);
      const body = await counters(user);
      expect(value(body, COUNTER_IDS.play_streak)).toBe(1);
      expect(value(body, COUNTER_IDS.play_days)).toBe(3);
    });

    it('conta os hexágonos por bioma do mapa, com o teto pelo tempo', async () => {
      const user = await newUser();
      await user.explore().expect(201);
      const exploration = app.get(ExplorationStore).get(user.id)!;
      const biomes = await prisma.biome.findMany({
        where: { id: { in: [...exploration.biomeIds] } },
      });
      const [first] = biomes;
      const outside = await prisma.biome.findFirstOrThrow({
        where: { id: { notIn: [...exploration.biomeIds] } },
      });
      exploration.hexesCreditedAt = Date.now() - 20 * MIN_STEP_MS;
      await user
        .ping([
          { biome: first!.slug, count: 500 },
          { biome: outside.slug, count: 7 },
        ])
        .expect(204);

      const body = await counters(user);
      const walked = value(body, COUNTER_IDS.hexes_walked);
      expect(walked).toBeGreaterThanOrEqual(20);
      expect(walked).toBeLessThanOrEqual(22);
      expect(value(body, COUNTER_IDS.biome_hexes, first!.id)).toBe(walked);
      expect(value(body, COUNTER_IDS.biome_hexes, outside.id)).toBe(0);
    });

    it('sem exploração aberta, os hexágonos não contam', async () => {
      const user = await newUser();
      await user.ping([{ biome: 'temperate', count: 5 }]).expect(204);

      expect(value(await counters(user), COUNTER_IDS.hexes_walked)).toBe(0);
    });

    it('recusa mais de 32 biomas e conta negativa', async () => {
      const user = await newUser();
      const many = Array.from({ length: 33 }, () => ({
        biome: 'temperate',
        count: 1,
      }));
      await user.ping(many).expect(400);
      await user.ping([{ biome: 'temperate', count: -1 }]).expect(400);
    });

    it('sem Domador, responde 404', async () => {
      const user = await newUser({ starter: false });
      await user.ping().expect(404);
    });
  });
});
