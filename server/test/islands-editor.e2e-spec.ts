import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

// As rotas do editor de ilhas (.specs/map-editor/01-island-records.md). Cada
// teste cria as ilhas dele e o afterAll apaga todas, publicadas ou não.

const RUVO = 1;

interface Tile {
  q: number;
  r: number;
  biome: string;
  height: number;
  variant: number;
  area?: number;
}

interface Draft {
  name: string;
  start: { q: number; r: number };
  tiles: Tile[];
  buildings: { building_type_id: number; tiles: { q: number; r: number }[] }[];
  areas: {
    key: number;
    name: string;
    color_hex: string;
    spawn_count: number;
    species: {
      species_id: number;
      weight: number;
      min_level: number;
      max_level: number;
    }[];
  }[];
}

/** Um hexágono de raio `radius` em volta de (0, 0), todo planície plana. */
function hexagon(radius: number): Tile[] {
  const tiles: Tile[] = [];
  for (let q = -radius; q <= radius; q++) {
    for (let r = -radius; r <= radius; r++) {
      if (Math.abs(q + r) <= radius) {
        tiles.push({ q, r, biome: 'temperate', height: 1, variant: 1 });
      }
    }
  }
  return tiles;
}

describe('Editor de ilhas (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let owner: string;
  let refuge: number;
  const editor = randomUUID();
  const islands: number[] = [];

  /** Uma ilha válida e pequena: 7 hexágonos, um Refúgio e uma área. */
  function draft(name = 'Ilha de teste'): Draft {
    const tiles = hexagon(1);
    tiles.find((tile) => tile.q === 1 && tile.r === 0)!.area = 1;
    return {
      name,
      start: { q: 0, r: 0 },
      tiles,
      buildings: [{ building_type_id: refuge, tiles: [{ q: 0, r: 1 }] }],
      areas: [
        {
          key: 1,
          name: 'Campo',
          color_hex: '#5B8C3A',
          spawn_count: 10,
          species: [
            { species_id: RUVO, weight: 10, min_level: 2, max_level: 4 },
          ],
        },
      ],
    };
  }

  const call = (
    method: 'get' | 'post' | 'put' | 'delete',
    path: string,
    target = app,
  ) =>
    request(target.getHttpServer())
      [method](`/v1/editor${path}`)
      .set('Authorization', `Bearer ${owner}`);

  async function create(body: Draft = draft()): Promise<number> {
    const response = await call('post', '/islands').send(body).expect(201);
    const id = (response.body as { id: number }).id;
    islands.push(id);
    return id;
  }

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({
      tokenVerifier: tokens.verifier,
      env: { MAP_EDITOR_USER_IDS: [editor] },
    });
    owner = await tokens.sign(editor);
    refuge = (
      await prisma.buildingType.findUniqueOrThrow({
        where: { slug: 'refuge' },
      })
    ).id;
  });

  afterAll(async () => {
    await prisma.island.deleteMany({ where: { id: { in: islands } } });
    await prisma.$disconnect();
    await app.close();
  });

  describe('quem edita', () => {
    it('responde 404 com MAP_EDITOR_USER_IDS vazia', async () => {
      const off = await createTestApp({
        tokenVerifier: tokens.verifier,
        env: { MAP_EDITOR_USER_IDS: [] },
      });
      try {
        const response = await call('get', '/islands', off).expect(404);
        expect(response.body.message).toBe('Rota não encontrada.');
      } finally {
        await off.close();
      }
    });

    it('responde 401 sem sessão', async () => {
      await request(app.getHttpServer()).get('/v1/editor/islands').expect(401);
    });

    it('responde 403 a quem não está na lista', async () => {
      const stranger = await tokens.sign(randomUUID());
      const response = await request(app.getHttpServer())
        .get('/v1/editor/islands')
        .set('Authorization', `Bearer ${stranger}`)
        .expect(403);
      expect(response.body.message).toBe(
        'Só quem edita o mapa pode usar esta rota.',
      );
    });
  });

  describe('ilhas', () => {
    it('cria e lê de volta o mesmo rascunho, como rascunho', async () => {
      const body = draft('Ilha das Brumas');
      const id = await create(body);
      const response = await call('get', `/islands/${id}`).expect(200);
      expect(response.body).toMatchObject({
        id,
        status: 'draft',
        published_at: null,
        name: 'Ilha das Brumas',
        start: { q: 0, r: 0 },
        buildings: body.buildings,
        areas: body.areas,
      });
      const byCoord = (a: Tile, b: Tile) => a.r - b.r || a.q - b.q;
      expect([...(response.body as Draft).tiles].sort(byCoord)).toEqual(
        [...body.tiles].sort(byCoord),
      );

      const list = await call('get', '/islands').expect(200);
      expect(
        (list.body as { islands: { id: number }[] }).islands.find(
          (island) => island.id === id,
        ),
      ).toMatchObject({ name: 'Ilha das Brumas', status: 'draft' });
    });

    it('responde 404 a uma ilha que não existe', async () => {
      const response = await call('get', '/islands/2147483647').expect(404);
      expect(response.body.message).toBe('Ilha não encontrada.');
    });

    it.each([
      [
        'hexágono repetido',
        (d: Draft) => d.tiles.push({ ...d.tiles[0]! }),
        'aparece duas vezes',
      ],
      [
        'chegada fora da ilha',
        (d: Draft) => (d.start = { q: 5, r: 5 }),
        'A chegada precisa ser um hexágono da ilha.',
      ],
      [
        'construção sobre outra',
        (d: Draft) =>
          d.buildings.push({
            building_type_id: refuge,
            tiles: [{ q: 0, r: 1 }],
          }),
        'O hexágono (0, 1) é de duas construções.',
      ],
      [
        'área que não existe',
        (d: Draft) => (d.tiles[0]!.area = 9),
        'para a área 9, que não existe.',
      ],
      [
        'bioma que não é de terreno',
        (d: Draft) => (d.tiles[0]!.biome = 'lava'),
        'biome',
      ],
      ['altura acima de 4', (d: Draft) => (d.tiles[0]!.height = 5), 'height'],
      [
        'hexágono sem altura',
        (d: Draft) => delete (d.tiles[0] as { height?: number }).height,
        'height',
      ],
      [
        'variante 4 na Colina',
        (d: Draft) => {
          d.tiles[0]!.biome = 'hill';
          d.tiles[0]!.variant = 4;
        },
        'vai de 1 a 3 na Colina e na Montanha',
      ],
    ])('recusa salvar com %s (400)', async (_label, change, message) => {
      const id = await create();
      const body = draft();
      change(body);
      const response = await call('put', `/islands/${id}/draft`)
        .send(body)
        .expect(400);
      expect(response.body.message).toContain(message);
    });

    it.each([0, 201])(
      'recusa a quantidade %d de Ecobeasts na área (400)',
      async (count) => {
        const id = await create();
        const body = draft();
        body.areas[0]!.spawn_count = count;
        const response = await call('put', `/islands/${id}/draft`)
          .send(body)
          .expect(400);
        expect(response.body.message).toBe(
          'Na área 1, a quantidade de Ecobeasts precisa ir de 1 a 200.',
        );
      },
    );

    it.each([
      ['2,5', 2.5],
      ['sem o campo', undefined],
    ])('recusa a quantidade de Ecobeasts %s (400)', async (_label, count) => {
      const id = await create();
      const body = draft() as unknown as {
        areas: Record<string, unknown>[];
      };
      if (count === undefined) delete body.areas[0]!.spawn_count;
      else body.areas[0]!.spawn_count = count;
      const response = await call('put', `/islands/${id}/draft`)
        .send(body)
        .expect(400);
      expect(response.body.message).toBe(
        'spawn_count precisa ser um número inteiro.',
      );
    });

    it('guarda a quantidade de Ecobeasts e a copia ao publicar', async () => {
      const body = draft();
      body.areas[0]!.spawn_count = 25;
      const id = await create(body);
      const read = await call('get', `/islands/${id}`).expect(200);
      expect((read.body as Draft).areas[0]!.spawn_count).toBe(25);
      await call('post', `/islands/${id}/publish`).expect(200);
      const published = await prisma.islandArea.findFirstOrThrow({
        where: { islandMap: { islandId: id, kind: 'published' } },
      });
      expect(published.spawnCount).toBe(25);
    });

    it('publica, marca mudança e volta a publicada com o mesmo rascunho', async () => {
      const id = await create();
      const published = await call('post', `/islands/${id}/publish`).expect(
        200,
      );
      expect(published.body.status).toBe('published');
      expect(published.body.published_at).toEqual(expect.any(String));

      const changed = draft('Ilha mudada');
      const saved = await call('put', `/islands/${id}/draft`)
        .send(changed)
        .expect(200);
      expect(saved.body.status).toBe('changed');

      const back = await call('put', `/islands/${id}/draft`)
        .send(draft())
        .expect(200);
      expect(back.body.status).toBe('published');

      const maps = await prisma.islandMap.findMany({ where: { islandId: id } });
      expect(maps.map((map) => map.kind).sort()).toEqual([
        'draft',
        'published',
      ]);
    });

    it('recusa publicar com a chegada na água (409)', async () => {
      const body = draft();
      body.tiles.find((tile) => tile.q === 0 && tile.r === 0)!.biome = 'wdeep';
      const id = await create(body);
      const response = await call('post', `/islands/${id}/publish`).expect(409);
      expect(response.body.message).toBe('A chegada não pode ficar na água.');
    });

    it('apaga só a ilha que nunca foi publicada', async () => {
      const kept = await create();
      await call('post', `/islands/${kept}/publish`).expect(200);
      const refused = await call('delete', `/islands/${kept}`).expect(409);
      expect(refused.body.message).toBe(
        'Uma ilha publicada não pode ser apagada.',
      );

      const gone = await create();
      await call('delete', `/islands/${gone}`).expect(204);
      await call('get', `/islands/${gone}`).expect(404);
    });

    it('salva e lê uma ilha de quase 20.000 hexágonos', async () => {
      const body = { ...draft(), tiles: hexagon(81), buildings: [], areas: [] };
      expect(body.tiles).toHaveLength(19_927);
      const id = await create(body);
      const response = await call('get', `/islands/${id}`).expect(200);
      expect((response.body as Draft).tiles).toHaveLength(19_927);
    });
  });

  describe('limite do corpo', () => {
    it('as outras rotas continuam lendo JSON, com o limite de 100 KB', async () => {
      const userId = randomUUID();
      const player = await tokens.sign(userId);
      try {
        // O corpo foi lido: o Domador nasce com o nome mandado.
        const created = await request(app.getHttpServer())
          .post('/v1/me')
          .set('Authorization', `Bearer ${player}`)
          .send({ name: 'Teste Editor' })
          .expect(201);
        expect(created.body.player.name).toBe('Teste Editor');
      } finally {
        await prisma.player.deleteMany({ where: { id: userId } });
      }

      await request(app.getHttpServer())
        .post('/v1/me')
        .set('Authorization', `Bearer ${player}`)
        .send({ name: 'x'.repeat(200_000) })
        .expect(413);
    });
  });

  describe('gerador', () => {
    interface Generated {
      start: { q: number; r: number };
      tiles: Tile[];
    }
    const water = (body: Generated) =>
      body.tiles.filter(({ biome }) => biome.startsWith('w')).length;

    it('devolve os parâmetros padrão e as faixas', async () => {
      const response = await call('get', '/map-generator').expect(200);
      expect(response.body.defaults.tile_count).toEqual(expect.any(Number));
      expect(response.body.ranges.tile_count).toEqual({
        min: 100,
        max: 20000,
        integer: true,
      });
    });

    it('gera o mesmo mapa com a mesma seed e mais água com mais water_fraction', async () => {
      const ask = (config: object) =>
        call('post', '/map-generator')
          .send({ seed: 42, config: { tile_count: 500, ...config } })
          .expect(200)
          .then((response) => response.body as Generated);
      const first = await ask({ water_fraction: 0.1 });
      const again = await ask({ water_fraction: 0.1 });
      const wetter = await ask({ water_fraction: 0.6 });
      expect(first.tiles).toHaveLength(500);
      expect(again).toEqual(first);
      expect(water(wetter)).toBeGreaterThan(water(first));
    });

    it('recusa um parâmetro fora da faixa (400)', async () => {
      const response = await call('post', '/map-generator')
        .send({ seed: 1, config: { tile_count: 50 } })
        .expect(400);
      expect(response.body.message).toBe(
        'tile_count precisa ficar entre 100 e 20000.',
      );
    });
  });
});
