import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { ExplorationStore } from '../src/exploration/exploration.store.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { playOut, waitVez } from './support/board-play.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

// Os Domadores das ilhas (auralis/04). As ilhas de teste ficam no fim da ordem do
// Arquipélago, longe das do e2e do Arquipélago.

const RUVO = 1;
const NO_TAMER = 'Nenhum Domador aqui.';
const BASE_ORDER = 910_000;

interface BoardBody {
  battle: {
    phase: string;
    result: string | null;
    board: { cells: { q: number; r: number }[] };
    queue: { side: string; position: number }[];
    player: { cells: ({ q: number; r: number } | null)[] };
    enemy: { cells: ({ q: number; r: number } | null)[] };
    tamer: { name_id: number; source: string; name: string | null } | null;
  };
  tamer_progress: { xp_gained: number } | null;
  island_unlocked: { id: number; name: string } | null;
}

function draft(name: string, npcIds: number[]) {
  const tiles = [];
  for (let q = -2; q <= 2; q++) {
    for (let r = -2; r <= 2; r++) {
      if (Math.abs(q + r) <= 2) {
        tiles.push({ q, r, biome: 'temperate', height: 1, variant: 1 });
      }
    }
  }
  return {
    name,
    start: { q: 0, r: 0 },
    tiles,
    actions: [],
    areas: [],
    npcs: npcIds.map((npc_id, index) => ({
      npc_id,
      q: index + 1,
      r: 0,
      still: true,
      tiles: [],
      dialogue: 'Vamos lutar!',
      action_type_id: null,
    })),
  };
}

describe('Os Domadores da ilha (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let owner: string;
  const editor = randomUUID();
  const islands: number[] = [];
  const npcs: number[] = [];
  const users: string[] = [];
  let sources: Map<string, number>;

  const editorCall = (path: string) =>
    request(app.getHttpServer())
      .post(`/v1/editor${path}`)
      .set('Authorization', `Bearer ${owner}`);

  async function npc(): Promise<number> {
    const { id } = await prisma.npc.create({
      data: {
        slug: `zz_test_tamer_${randomUUID().slice(0, 8)}`,
        name: 'Caio',
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
    publish = true,
  ): Promise<number> {
    const response = await editorCall('/islands')
      .send(draft(name, npcIds))
      .expect(201);
    const id = (response.body as { id: number }).id;
    islands.push(id);
    if (publish) await editorCall(`/islands/${id}/publish`).expect(200);
    await prisma.island.update({
      where: { id },
      data: { archipelagoOrder: order },
    });
    return id;
  }

  async function tamer(
    npcId: number,
    islandId: number,
    level = 2,
    countsForUnlock = true,
  ): Promise<number> {
    const { id } = await prisma.tamer.create({
      data: {
        npcId,
        islandId,
        countsForUnlock,
        creatures: { create: [{ position: 1, speciesId: RUVO, level }] },
      },
    });
    return id;
  }

  async function player(level: number, hp: number) {
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
      data: { level, currentHp: hp },
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
      unlock: (islandId: number) =>
        http()
          .put(`/v1/me/archipelago/${islandId}/unlock`)
          .set(auth)
          .expect(204),
      explore: async (islandId: number) =>
        (
          await http()
            .post('/v1/me/exploration')
            .set(auth)
            .send({ island_id: islandId })
            .expect(201)
        ).body as { map: { npcs: { npc_id: number; tamer?: boolean }[] } },
      fight: (npcId: number, god = false) =>
        http()
          .post('/v1/me/board-battle/island-tamer')
          .set(auth)
          .send({ npc_id: npcId, god }),
      archipelago: async () =>
        (
          (await http().get('/v1/me/archipelago').set(auth).expect(200))
            .body as { islands: { id: number | null; state: string }[] }
        ).islands,
      playOut: (first: BoardBody, vez?: typeof waitVez) =>
        playOut(act, first as never, vez as never) as Promise<BoardBody>,
    };
  }

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({
      tokenVerifier: tokens.verifier,
      env: { MAP_EDITOR_USER_IDS: [editor] },
    });
    owner = await tokens.sign(editor);
    const rows = await prisma.tamerXpSource.findMany();
    sources = new Map(rows.map(({ slug, amount }) => [slug, amount]));
  });

  afterAll(async () => {
    await prisma.island.deleteMany({ where: { id: { in: islands } } });
    await prisma.tamer.deleteMany({ where: { npcId: { in: npcs } } });
    await prisma.npc.deleteMany({ where: { id: { in: npcs } } });
    await prisma.player.deleteMany({ where: { id: { in: users } } });
    await prisma.$disconnect();
    await app.close();
  });

  it('a primeira vitória abre a ilha seguinte, e a revanche paga menos', async () => {
    const caio = await npc();
    const first = await island('Domadores A', BASE_ORDER + 1, [caio]);
    const second = await island('Domadores B', BASE_ORDER + 2, []);
    await tamer(caio, first);
    const me = await player(100, 300);
    await me.unlock(first);

    const map = await me.explore(first);
    expect(map.map.npcs.map(({ tamer }) => tamer)).toEqual([true]);

    const opened = await me.fight(caio, true).expect(201);
    const start = opened.body as BoardBody;
    expect(start.battle.tamer).toEqual({
      name_id: 0,
      source: 'island',
      name: 'Caio',
    });
    // O modo deus não grava a vitória: a de verdade vem depois.
    const god = await me.playOut(start);
    expect(god.battle.result).toBe('victory');
    expect(god.island_unlocked).toBeNull();

    await me.explore(first);
    const won = await me.playOut(
      (await me.fight(caio).expect(201)).body as BoardBody,
    );
    expect(won.battle.result).toBe('victory');
    expect(won.island_unlocked).toEqual({ id: second, name: 'Domadores B' });
    const states = await me.archipelago();
    expect(states.find(({ id }) => id === second)?.state).toBe('open');

    await me.explore(first);
    const rematch = await me.playOut(
      (await me.fight(caio).expect(201)).body as BoardBody,
    );
    expect(rematch.island_unlocked).toBeNull();
    const firstXp = won.tamer_progress!.xp_gained;
    const rematchXp = rematch.tamer_progress!.xp_gained;
    expect(firstXp - rematchXp).toBe(
      sources.get('island_tamer_win')! +
        sources.get('island_unlocked')! -
        sources.get('island_tamer_rematch')!,
    );
    // Três lutas seguidas.
  }, 120_000);

  it('com required_tamer_wins = 1, vencer um de dois abre a seguinte', async () => {
    const [ana, bia] = [await npc(), await npc()];
    const first = await island('Domadores C', BASE_ORDER + 3, [ana, bia]);
    const second = await island('Domadores D', BASE_ORDER + 4, []);
    await prisma.island.update({
      where: { id: first },
      data: { requiredTamerWins: 1 },
    });
    await tamer(ana, first);
    await tamer(bia, first);
    const me = await player(100, 300);
    await me.unlock(first);
    await me.explore(first);
    const won = await me.playOut(
      (await me.fight(bia).expect(201)).body as BoardBody,
    );
    expect(won.island_unlocked?.id).toBe(second);
  });

  it('um Domador fora da versão publicada ou de outra ilha dá 409', async () => {
    const [placed, absent] = [await npc(), await npc()];
    const first = await island('Domadores E', BASE_ORDER + 5, [placed]);
    const other = await island('Domadores F', BASE_ORDER + 6, []);
    await tamer(absent, first);
    await tamer(placed, other);
    const me = await player(100, 300);
    await me.unlock(first);
    await me.explore(first);
    expect((await me.fight(absent).expect(409)).body.message).toBe(NO_TAMER);
    expect((await me.fight(placed).expect(409)).body.message).toBe(NO_TAMER);
    const map = await me.explore(first);
    expect(map.map.npcs.map(({ tamer }) => tamer)).toEqual([false]);
  });

  it('o Domador que não conta não abre a seguinte', async () => {
    const dan = await npc();
    const first = await island('Domadores G', BASE_ORDER + 7, [dan]);
    await island('Domadores H', BASE_ORDER + 8, []);
    await tamer(dan, first, 2, false);
    const me = await player(100, 300);
    await me.unlock(first);
    await me.explore(first);
    const won = await me.playOut(
      (await me.fight(dan).expect(201)).body as BoardBody,
    );
    expect(won.battle.result).toBe('victory');
    expect(won.island_unlocked).toBeNull();
  });

  it('perder para o Domador da ilha encerra a exploração', async () => {
    const eva = await npc();
    const first = await island('Domadores I', BASE_ORDER + 9, [eva]);
    await tamer(eva, first, 60);
    const me = await player(1, 1);
    await me.unlock(first);
    await me.explore(first);
    const lost = await me.playOut(
      (await me.fight(eva).expect(201)).body as BoardBody,
      waitVez,
    );
    expect(lost.battle.result).toBe('defeat');
    expect(app.get(ExplorationStore).get(me.id)).toBeUndefined();
  });

  it('sem exploração numa ilha, dá 409', async () => {
    const me = await player(100, 300);
    expect((await me.fight(1).expect(409)).body.message).toBe(NO_TAMER);
  });
});
