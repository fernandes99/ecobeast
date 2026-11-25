import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

// As salas dos interiores (interiors/01). Cria as próprias salas e as apaga no fim;
// a sala 1, o Refúgio, só é lida.

const GRANDPA = 3;
const DOOR_MESSAGE = 'A porta precisa estar num quadrado de chão, sem bloqueio.';

interface Tile {
  layer: string;
  x: number;
  y: number;
  sheet: string;
  col: number;
  row: number;
}

function floorOf(width: number, height: number): Tile[] {
  const tiles: Tile[] = [];
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      tiles.push({ layer: 'floor', x, y, sheet: 'walls_floor', col: 4, row: 9 });
    }
  }
  return tiles;
}

describe('Interiores (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let owner: string;
  let refugeAction: number;
  const editor = randomUUID();
  const created: number[] = [];
  const islands: number[] = [];

  const server = () => app.getHttpServer();
  const auth = (token = owner) => ({ Authorization: `Bearer ${token}` });

  async function newRoom(): Promise<number> {
    const response = await request(server())
      .post('/v1/editor/interiors')
      .set(auth())
      .send({ name: 'Teste e2e', width: 8, height: 6 })
      .expect(201);
    created.push(response.body.id);
    return response.body.id;
  }

  function body(change: (room: Record<string, unknown>) => void = () => {}) {
    const room: Record<string, unknown> = {
      name: 'Teste e2e',
      width: 8,
      height: 6,
      door: { x: 4, y: 5 },
      tiles: floorOf(8, 6),
      objects: [
        { x: 1, y: 1, sheet: 'interior', col: 0, row: 0, width: 2, height: 2, action_type_id: refugeAction },
      ],
      blocks: [{ x: 1, y: 2 }],
      npcs: [
        { npc_id: GRANDPA, x: 5, y: 2, dialogue: 'Olá!', action_type_id: refugeAction },
      ],
    };
    change(room);
    return room;
  }

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({
      tokenVerifier: tokens.verifier,
      env: { MAP_EDITOR_USER_IDS: [editor] },
    });
    owner = await tokens.sign(editor);
    refugeAction = (
      await prisma.actionType.findUniqueOrThrow({ where: { slug: 'refuge' } })
    ).id;
  });

  afterAll(async () => {
    await prisma.island.deleteMany({ where: { id: { in: islands } } });
    await prisma.interior.deleteMany({ where: { id: { in: created } } });
    await prisma.$disconnect();
    await app.close();
  });

  describe('o jogo', () => {
    it('traz o Refúgio, o hospital, com a porta num chão livre e a máquina de cura', async () => {
      const response = await request(server()).get('/v1/interiors/1').set(auth()).expect(200);
      const room = response.body;
      expect(room.id).toBe(1);
      expect(room.name).toBe('Refúgio');
      const layers = new Set((room.tiles as Tile[]).map(({ layer }) => layer));
      expect([...layers].sort()).toEqual(['floor', 'floor_detail', 'wall', 'wall_detail']);
      expect(room.objects.length).toBeGreaterThan(0);
      expect(room.blocks.length).toBeGreaterThan(0);
      expect(room.objects).toContainEqual(
        expect.objectContaining({ sheet: 'refuge', width: 5, height: 2, action_type_id: refugeAction }),
      );
      const door = room.door as { x: number; y: number };
      expect(
        (room.tiles as Tile[]).some(
          ({ layer, x, y }) => layer === 'floor' && x === door.x && y === door.y,
        ),
      ).toBe(true);
      expect(
        (room.blocks as { x: number; y: number }[]).some(
          ({ x, y }) => x === door.x && y === door.y,
        ),
      ).toBe(false);
    });

    it('dá 404 para uma sala que não existe', async () => {
      for (const id of ['999999', 'abc']) {
        const response = await request(server())
          .get(`/v1/interiors/${id}`)
          .set(auth())
          .expect(404);
        expect(response.body.message).toBe('Esse lugar não existe.');
      }
    });

    it('pede a sessão', async () => {
      await request(server()).get('/v1/interiors/1').expect(401);
    });
  });

  describe('o editor', () => {
    it('lista as salas', async () => {
      const response = await request(server())
        .get('/v1/editor/interiors')
        .set(auth())
        .expect(200);
      expect(response.body.interiors).toContainEqual({ id: 1, name: 'Refúgio' });
    });

    it('recusa quem não edita (403)', async () => {
      const other = await tokens.sign(randomUUID());
      await request(server()).get('/v1/editor/interiors').set(auth(other)).expect(403);
    });

    it('cria uma sala vazia com a porta no meio da linha de baixo', async () => {
      const id = await newRoom();
      const response = await request(server())
        .get(`/v1/editor/interiors/${id}`)
        .set(auth())
        .expect(200);
      expect(response.body).toEqual({
        id,
        name: 'Teste e2e',
        width: 8,
        height: 6,
        door: { x: 4, y: 5 },
        tiles: [],
        objects: [],
        blocks: [],
        npcs: [],
      });
    });

    it('troca a sala inteira e devolve os ids novos', async () => {
      const id = await newRoom();
      const first = await request(server())
        .put(`/v1/editor/interiors/${id}`)
        .set(auth())
        .send(body())
        .expect(200);
      const second = await request(server())
        .put(`/v1/editor/interiors/${id}`)
        .set(auth())
        .send(first.body)
        .expect(200);
      expect(second.body.objects[0].id).not.toBe(first.body.objects[0].id);
      expect(second.body.npcs[0].id).not.toBe(first.body.npcs[0].id);
      const read = await request(server())
        .get(`/v1/editor/interiors/${id}`)
        .set(auth())
        .expect(200);
      expect(read.body).toEqual(second.body);
      expect(read.body.npcs[0]).toMatchObject({
        npc_id: GRANDPA,
        x: 5,
        y: 2,
        dialogue: 'Olá!',
        action_type_id: refugeAction,
      });
      expect(read.body.objects[0]).toMatchObject({ x: 1, y: 1, action_type_id: refugeAction });
    });

    it('recusa o objeto com uma ação que não existe', async () => {
      const id = await newRoom();
      const response = await request(server())
        .put(`/v1/editor/interiors/${id}`)
        .set(auth())
        .send(
          body((room) => {
            (room.objects as Record<string, unknown>[])[0]!.action_type_id = 9_999;
          }),
        )
        .expect(400);
      expect(response.body.message).toBe('O objeto tem uma ação que não existe.');
    });

    it('recusa a porta bloqueada e o tile fora da sala', async () => {
      const id = await newRoom();
      const door = await request(server())
        .put(`/v1/editor/interiors/${id}`)
        .set(auth())
        .send(body((room) => (room.blocks = [{ x: 4, y: 5 }])))
        .expect(400);
      expect(door.body.message).toBe(DOOR_MESSAGE);
      const outside = await request(server())
        .put(`/v1/editor/interiors/${id}`)
        .set(auth())
        .send(
          body((room) =>
            (room.tiles as Tile[]).push({ layer: 'wall', x: 8, y: 0, sheet: 'walls_floor', col: 1, row: 1 }),
          ),
        )
        .expect(400);
      expect(outside.body.message).toBe('Há um tile fora da sala.');
    });

    it('dá 404 ao salvar uma sala que não existe', async () => {
      const response = await request(server())
        .put('/v1/editor/interiors/999999')
        .set(auth())
        .send(body())
        .expect(404);
      expect(response.body.message).toBe('Interior não encontrado.');
    });

    it('apaga a sala', async () => {
      const id = await newRoom();
      await request(server()).delete(`/v1/editor/interiors/${id}`).set(auth()).expect(204);
      await request(server()).get(`/v1/editor/interiors/${id}`).set(auth()).expect(404);
    });
  });

  describe('a sala na peça', () => {
    const tiles = [
      { q: 0, r: 0, biome: 'temperate', height: 1, variant: 1 },
      { q: 1, r: 0, biome: 'temperate', height: 1, variant: 1 },
    ];

    async function island(interiorId: number): Promise<{ id: number; draft: Record<string, unknown> }> {
      const house = (
        await prisma.propType.findUniqueOrThrow({ where: { slug: 'big_house' } })
      ).id;
      const draft = {
        name: 'Ilha da sala e2e',
        start: { q: 0, r: 0 },
        tiles,
        actions: [],
        areas: [],
        props: [
          {
            prop_type_id: house,
            q: 1,
            r: 0,
            dx: 0,
            dy: 0,
            variant: 1,
            mirrored: false,
            block: [],
            action_type_id: refugeAction,
            interior_id: interiorId,
          },
        ],
      };
      const response = await request(server())
        .post('/v1/editor/islands')
        .set(auth())
        .send(draft)
        .expect(201);
      islands.push(response.body.id);
      return { id: response.body.id, draft };
    }

    it('guarda a sala da peça no rascunho e na publicação', async () => {
      const room = await newRoom();
      const { id } = await island(room);
      const read = await request(server()).get(`/v1/editor/islands/${id}`).set(auth()).expect(200);
      expect(read.body.props[0].interior_id).toBe(room);

      await request(server()).post(`/v1/editor/islands/${id}/publish`).set(auth()).expect(200);
      const published = await prisma.islandProp.findFirstOrThrow({
        where: { islandMap: { islandId: id, kind: 'published' } },
      });
      expect(published.interiorId).toBe(room);
    });

    it('marca a ilha publicada como mudada ao trocar só a sala da peça', async () => {
      const room = await newRoom();
      const other = await newRoom();
      const { id, draft } = await island(room);
      await request(server()).post(`/v1/editor/islands/${id}/publish`).set(auth()).expect(200);
      (draft.props as Record<string, unknown>[])[0]!.interior_id = other;
      const saved = await request(server())
        .put(`/v1/editor/islands/${id}/draft`)
        .set(auth())
        .send(draft)
        .expect(200);
      expect(saved.body.status).toBe('changed');
    });

    it('recusa uma sala que não existe', async () => {
      const room = await newRoom();
      const { id, draft } = await island(room);
      (draft.props as Record<string, unknown>[])[0]!.interior_id = 999999;
      const response = await request(server())
        .put(`/v1/editor/islands/${id}/draft`)
        .set(auth())
        .send(draft)
        .expect(400);
      expect(response.body.message).toBe('Esse interior não existe.');
    });

    it('não apaga a sala que só o rascunho de uma ilha usa (409)', async () => {
      const room = await newRoom();
      await island(room);
      const response = await request(server())
        .delete(`/v1/editor/interiors/${room}`)
        .set(auth())
        .expect(409);
      expect(response.body.message).toBe('Uma peça de ilha leva a esse interior.');
    });
  });
});
