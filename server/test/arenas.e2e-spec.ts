import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { playOut } from './support/board-play.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

// As Arenas (auralis/05). As ilhas de teste ficam no fim da ordem do Arquipélago,
// longe das dos outros e2e.

const RUVO = 1;
const ARENA_LOCKED = 'Essa Arena ainda está trancada.';
const BASE_ORDER = 920_000;

interface BoardBody {
  battle: {
    phase: string;
    result: string | null;
    board: { cells: { q: number; r: number }[] };
    queue: { side: string; position: number }[];
    player: { cells: ({ q: number; r: number } | null)[] };
    enemy: { cells: ({ q: number; r: number } | null)[] };
  };
  tamer_progress: { xp_gained: number } | null;
  island_unlocked: { id: number; name: string } | null;
  arena_won: {
    id: number;
    name: string;
    next_interior_id: number | null;
  } | null;
}

interface ExploreBody {
  locked_interior_ids: number[];
  tamer_npc_ids: number[];
}

function floorOf(width: number, height: number) {
  const tiles = [];
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      tiles.push({
        layer: 'floor',
        x,
        y,
        sheet: 'walls_floor',
        col: 4,
        row: 9,
      });
    }
  }
  return tiles;
}

describe('As Arenas (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let owner: string;
  let house: number;
  let arenaXp: number;
  const editor = randomUUID();
  const islands: number[] = [];
  const rooms: number[] = [];
  const npcs: number[] = [];
  const users: string[] = [];

  const editorCall = (method: 'post' | 'put', path: string) =>
    request(app.getHttpServer())
      [method](`/v1/editor${path}`)
      .set('Authorization', `Bearer ${owner}`);

  async function npc(): Promise<number> {
    const { id } = await prisma.npc.create({
      data: {
        slug: `zz_test_arena_${randomUUID().slice(0, 8)}`,
        name: 'Mestra',
        description: 'Teste.',
        sprite: 'ruvo',
      },
    });
    npcs.push(id);
    return id;
  }

  async function room(npcIds: number[]): Promise<number> {
    const created = await editorCall('post', '/interiors')
      .send({ name: 'Arena e2e', width: 8, height: 6 })
      .expect(201);
    const id = (created.body as { id: number }).id;
    rooms.push(id);
    await editorCall('put', `/interiors/${id}`)
      .send({
        name: 'Arena e2e',
        width: 8,
        height: 6,
        door: { x: 4, y: 5 },
        tiles: floorOf(8, 6),
        objects: [],
        blocks: [],
        npcs: npcIds.map((npc_id, index) => ({
          npc_id,
          x: 1 + index,
          y: 1,
          dialogue: 'Lute!',
          action_type_id: null,
        })),
      })
      .expect(200);
    return id;
  }

  async function island(
    name: string,
    order: number,
    roomIds: number[],
  ): Promise<number> {
    const tiles = [];
    for (let q = -2; q <= 2; q++) {
      for (let r = -2; r <= 2; r++) {
        if (Math.abs(q + r) <= 2) {
          tiles.push({ q, r, biome: 'temperate', height: 1, variant: 1 });
        }
      }
    }
    const response = await editorCall('post', '/islands')
      .send({
        name,
        start: { q: 0, r: 0 },
        tiles,
        actions: [],
        areas: [],
        props: roomIds.map((interior_id, index) => ({
          prop_type_id: house,
          q: index + 1,
          r: 0,
          dx: 0,
          dy: 0,
          variant: 1,
          mirrored: false,
          block: [],
          interior_id,
        })),
      })
      .expect(201);
    const id = (response.body as { id: number }).id;
    islands.push(id);
    await editorCall('post', `/islands/${id}/publish`).expect(200);
    await prisma.island.update({
      where: { id },
      data: { archipelagoOrder: order },
    });
    return id;
  }

  async function tamer(
    npcId: number,
    islandId: number,
    countsForUnlock = false,
  ): Promise<number> {
    const { id } = await prisma.tamer.create({
      data: {
        npcId,
        islandId,
        countsForUnlock,
        creatures: { create: [{ position: 1, speciesId: RUVO, level: 2 }] },
      },
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
      ).body as BoardBody;
    const fight = (npcId: number) =>
      http()
        .post('/v1/me/board-battle/island-tamer')
        .set(auth)
        .send({ npc_id: npcId });
    return {
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
        ).body as ExploreBody,
      fight,
      win: async (npcId: number) =>
        (await playOut(
          act,
          (await fight(npcId).expect(201)).body as never,
        )) as BoardBody,
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
    house = (
      await prisma.propType.findUniqueOrThrow({ where: { slug: 'big_house' } })
    ).id;
    arenaXp = (
      await prisma.tamerXpSource.findUniqueOrThrow({ where: { slug: 'arena' } })
    ).amount;
  });

  afterAll(async () => {
    await prisma.island.deleteMany({ where: { id: { in: islands } } });
    await prisma.interior.deleteMany({ where: { id: { in: rooms } } });
    await prisma.tamer.deleteMany({ where: { npcId: { in: npcs } } });
    await prisma.npc.deleteMany({ where: { id: { in: npcs } } });
    await prisma.player.deleteMany({ where: { id: { in: users } } });
    await prisma.$disconnect();
    await app.close();
  });

  it('as Arenas abrem em ordem, dão o emblema e abrem a ilha seguinte', async () => {
    const [boss1, trainee, boss2] = [await npc(), await npc(), await npc()];
    const [room1, room2] = [await room([boss1, trainee]), await room([boss2])];
    const first = await island('Arenas A', BASE_ORDER + 1, [room1, room2]);
    const second = await island('Arenas B', BASE_ORDER + 2, []);
    const [bossTamer1, , bossTamer2] = [
      await tamer(boss1, first),
      await tamer(trainee, first),
      await tamer(boss2, first),
    ];
    const arena1 = await prisma.arena.create({
      data: {
        islandId: first,
        position: 1,
        name: 'Arena do Vento',
        interiorId: room1,
        bossTamerId: bossTamer1,
      },
    });
    const arena2 = await prisma.arena.create({
      data: {
        islandId: first,
        position: 2,
        name: 'Arena da Pedra',
        interiorId: room2,
        bossTamerId: bossTamer2,
      },
    });
    const me = await player();
    await me.unlock(first);

    const start = await me.explore(first);
    expect(start.locked_interior_ids).toEqual([room2]);
    expect([...start.tamer_npc_ids].sort((a, b) => a - b)).toEqual(
      [boss1, trainee, boss2].sort((a, b) => a - b),
    );
    expect((await me.fight(boss2).expect(409)).body.message).toBe(ARENA_LOCKED);

    const training = await me.win(trainee);
    expect(training.battle.result).toBe('victory');
    expect(training.arena_won).toBeNull();

    await me.explore(first);
    const won1 = await me.win(boss1);
    expect(won1.arena_won).toEqual({
      id: arena1.id,
      name: 'Arena do Vento',
      next_interior_id: room2,
    });
    expect(won1.island_unlocked).toBeNull();
    expect(won1.tamer_progress!.xp_gained).toBeGreaterThanOrEqual(arenaXp);

    expect((await me.explore(first)).locked_interior_ids).toEqual([]);
    const won2 = await me.win(boss2);
    expect(won2.arena_won).toEqual({
      id: arena2.id,
      name: 'Arena da Pedra',
      next_interior_id: null,
    });
    expect(won2.island_unlocked).toEqual({ id: second, name: 'Arenas B' });
    // Quatro lutas seguidas.
  }, 180_000);

  it('no mapa sorteado, as listas vêm vazias', async () => {
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
    const { body } = await http()
      .post('/v1/me/exploration')
      .set(auth)
      .send({})
      .expect(201);
    expect((body as ExploreBody).locked_interior_ids).toEqual([]);
    expect((body as ExploreBody).tamer_npc_ids).toEqual([]);
  });
});
