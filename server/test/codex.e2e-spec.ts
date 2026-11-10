import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { BattleStore } from '../src/battle/battle.store.js';
import { Item, Prisma, PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { type PlayableBattle, playOut } from './support/board-play.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';
import { HERE, placeWild } from './support/wild.js';

// O Bestiário (.specs/codex/01-codex-records.md). As espécies vêm do banco,
// sem conferir valores de balanceamento.

const RUVO = 1;
const RUVAK = 2;

interface Entry {
  species_id: number;
  caught: boolean;
}

interface Body {
  battle: PlayableBattle & { result: string | null };
  registered_species_ids: number[];
}

describe('Bestiário (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let sphere: Item;
  let starters: number[];
  /** Uma espécie que não é inicial: nasce "???" para quem acabou de começar. */
  let stranger: number;
  const users: string[] = [];

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({ tokenVerifier: tokens.verifier });
    sphere = await prisma.item.findFirstOrThrow({
      where: { captureBonus: { not: null } },
    });
    starters = (
      await prisma.starterOption.findMany({ orderBy: { speciesId: 'asc' } })
    ).map((option) => option.speciesId);
    stranger = (
      await prisma.species.findFirstOrThrow({
        where: { starterOption: null },
        orderBy: { id: 'asc' },
      })
    ).id;
  });

  afterAll(async () => {
    await prisma.player.deleteMany({ where: { id: { in: users } } });
    await prisma.$disconnect();
    await app.close();
  });

  async function newUser() {
    const id = randomUUID();
    users.push(id);
    const auth = { Authorization: `Bearer ${await tokens.sign(id)}` };
    const http = () => request(app.getHttpServer());
    return {
      id,
      http,
      auth,
      codex: async () =>
        (await http().get('/v1/me/codex').set(auth).expect(200)).body
          .entries as Entry[],
      clear: () => http().delete('/v1/me/codex').set(auth),
      start: async (body: object) =>
        (
          await http()
            .post('/v1/me/board-battle')
            .set(auth)
            .send(body)
            .expect(201)
        ).body as Body,
      act: async (body: object) =>
        (
          await http()
            .post('/v1/me/board-battle/action')
            .set(auth)
            .send(body)
            .expect(200)
        ).body as Body,
      wild: () => http().post('/v1/me/board-battle/wild').set(auth).send(HERE),
      tamer: () =>
        http().post('/v1/me/board-battle/tamer').set(auth).send(HERE),
      evolve: (uid: string, accept: boolean) =>
        http()
          .post(`/v1/me/creatures/${uid}/evolution`)
          .set(auth)
          .send({ accept }),
    };
  }

  async function userWithStarter(
    data: Prisma.CreatureInstanceUncheckedUpdateManyInput = {},
  ) {
    const user = await newUser();
    await user
      .http()
      .post('/v1/me')
      .set(user.auth)
      .send({ name: 'Ana' })
      .expect(201);
    await user
      .http()
      .post('/v1/me/starter')
      .set(user.auth)
      .send({ species_id: RUVO })
      .expect(200);
    await prisma.creatureInstance.updateMany({
      where: { playerId: user.id },
      data,
    });
    return user;
  }

  type User = Awaited<ReturnType<typeof userWithStarter>>;

  /** Nível 100: joga antes de um Ecobeast de nível 1 e aguenta qualquer golpe dele. */
  const strongUser = () => userWithStarter({ level: 100, currentHp: 150 });

  const entryOf = (entries: Entry[], speciesId: number) =>
    entries.find((entry) => entry.species_id === speciesId);

  /** Uma luta de teste contra um Ecobeast de nível 1, capturado de primeira. */
  async function capture(user: User, speciesId: number): Promise<Body> {
    await prisma.inventoryItem.upsert({
      where: { playerId_itemId: { playerId: user.id, itemId: sphere.id } },
      create: { playerId: user.id, itemId: sphere.id, quantity: 1 },
      update: { quantity: 1 },
    });
    const opened = await user.start({
      enemies: [{ species_id: speciesId, level: 1 }],
    });
    const { catalog } = app.get(BattleStore).get(user.id)!;
    catalog.captureRates.set(speciesId, 100);
    catalog.items.get(sphere.id)!.captureBonus = 1000;
    const position = opened.battle.queue[0]!.position;
    const body = await user.act({
      position,
      action: {
        type: 'capture',
        item_id: sphere.id,
        target: opened.battle.enemy.cells[0],
      },
    });
    expect(body.battle.result).toBe('captured');
    return body;
  }

  it('sem Domador, o Bestiário vem vazio', async () => {
    const user = await newUser();
    expect(await user.codex()).toEqual([]);
  });

  it('escolher o inicial deixa só ele capturado, e os outros iniciais vistos', async () => {
    const user = await userWithStarter();
    expect(await user.codex()).toEqual(
      starters.map((speciesId) => ({
        species_id: speciesId,
        caught: speciesId === RUVO,
      })),
    );
  });

  it('a lista vem na ordem do número da espécie', async () => {
    const user = await strongUser();
    await user.start({ enemies: [{ species_id: stranger, level: 1 }] });
    const ids = (await user.codex()).map((entry) => entry.species_id);
    expect(ids).toEqual([...ids].sort((a, b) => a - b));
  });

  it('abrir uma luta contra um selvagem deixa a espécie dele vista', async () => {
    const user = await strongUser();
    expect(entryOf(await user.codex(), stranger)).toBeUndefined();
    placeWild(app, user.id, [{ speciesId: stranger, level: 1 }]);
    const { body } = await user.wild().expect(201);
    expect(body.registered_species_ids).toEqual([]);
    expect(entryOf(await user.codex(), stranger)).toEqual({
      species_id: stranger,
      caught: false,
    });
  });

  it('a luta contra um Domador deixa as espécies dele vistas', async () => {
    const user = await strongUser();
    placeWild(
      app,
      user.id,
      [],
      [{ team: [{ speciesId: stranger, level: 1 }] }],
    );
    await user.tamer().expect(201);
    expect(entryOf(await user.codex(), stranger)).toEqual({
      species_id: stranger,
      caught: false,
    });
  });

  it('capturar uma espécie nova a registra, e capturar outra igual não', async () => {
    const user = await strongUser();
    const first = await capture(user, stranger);
    expect(first.registered_species_ids).toEqual([stranger]);
    expect(entryOf(await user.codex(), stranger)).toEqual({
      species_id: stranger,
      caught: true,
    });
    const second = await capture(user, stranger);
    expect(second.registered_species_ids).toEqual([]);
  });

  it('vencer sem capturar não registra nada', async () => {
    const user = await strongUser();
    const last = await playOut(
      user.act,
      await user.start({ enemies: [{ species_id: stranger, level: 1 }] }),
    );
    expect(last.battle.result).toBe('victory');
    expect(last.registered_species_ids).toEqual([]);
    expect(entryOf(await user.codex(), stranger)?.caught).toBe(false);
  });

  describe('Evolução', () => {
    /** Ruvo a 1 XP do nível 16, que vence um Ruvo de nível 1 e ganha a oferta. */
    async function offered(): Promise<{ user: User; uid: string }> {
      const user = await userWithStarter({
        level: 15,
        currentXp: 16 ** 3 - 1,
        currentHp: 40,
      });
      const last = await playOut(
        user.act,
        await user.start({ enemies: [{ species_id: RUVO, level: 1 }] }),
      );
      expect(last.battle.result).toBe('victory');
      const row = await prisma.creatureInstance.findFirstOrThrow({
        where: { playerId: user.id },
      });
      return { user, uid: row.uid };
    }

    it('aceitar registra a espécie nova', async () => {
      const { user, uid } = await offered();
      const { body } = await user.evolve(uid, true).expect(200);
      expect(body.registered_species_ids).toEqual([RUVAK]);
      expect(entryOf(await user.codex(), RUVAK)).toEqual({
        species_id: RUVAK,
        caught: true,
      });
    });

    it('cancelar não registra', async () => {
      const { user, uid } = await offered();
      const { body } = await user.evolve(uid, false).expect(200);
      expect(body.registered_species_ids).toEqual([]);
      expect(entryOf(await user.codex(), RUVAK)).toBeUndefined();
    });
  });

  it('apagar o progresso apaga o Bestiário', async () => {
    const user = await userWithStarter();
    await user.http().delete('/v1/me').set(user.auth).expect(204);
    expect(
      await prisma.codexEntry.count({ where: { playerId: user.id } }),
    ).toBe(0);
  });

  describe('Limpar Bestiário (depuração)', () => {
    it('apaga os registros do jogador', async () => {
      const user = await userWithStarter();
      await user.clear().expect(204);
      expect(await user.codex()).toEqual([]);
    });

    it('com ENABLE_TEST_BATTLE desligada, a rota não existe', async () => {
      const closed = await createTestApp({
        tokenVerifier: tokens.verifier,
        env: { ENABLE_TEST_BATTLE: false },
      });
      await request(closed.getHttpServer())
        .delete('/v1/me/codex')
        .set({ Authorization: `Bearer ${await tokens.sign(randomUUID())}` })
        .expect(404);
      await closed.close();
    });
  });
});
