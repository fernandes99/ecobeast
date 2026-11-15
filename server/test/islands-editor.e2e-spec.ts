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
  ground?: string;
  area?: number;
  bare?: boolean;
}

interface DraftProp {
  prop_type_id: number;
  block?: { closed: boolean; points: number[] }[];
  action_type_id?: number;
  q: number;
  r: number;
  dx: number;
  dy: number;
  variant: number;
  mirrored: boolean;
}

interface DraftNpc {
  npc_id: number;
  q: number;
  r: number;
  still: boolean;
  tiles?: { q: number; r: number }[];
  dialogue?: string;
  action_type_id?: number | null;
}

interface Draft {
  name: string;
  start: { q: number; r: number };
  tiles: Tile[];
  actions: { action_type_id: number; tiles: { q: number; r: number }[] }[];
  props?: DraftProp[];
  trails?: { ground: string; width: number; points: number[] }[];
  walls?: { type: string; points: number[] }[];
  bridges?: { type: string; points: number[]; width?: number }[];
  npcs?: DraftNpc[];
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

  function draft(name = 'Ilha de teste'): Draft {
    const tiles = hexagon(1);
    tiles.find((tile) => tile.q === 1 && tile.r === 0)!.area = 1;
    tiles.find((tile) => tile.q === 0 && tile.r === 0)!.ground = 'dirt_trail';
    return {
      name,
      start: { q: 0, r: 0 },
      tiles,
      actions: [{ action_type_id: refuge, tiles: [{ q: 0, r: 1 }] }],
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
      await prisma.actionType.findUniqueOrThrow({
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
        actions: body.actions,
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
        'ação sobre outra',
        (d: Draft) =>
          d.actions.push({
            action_type_id: refuge,
            tiles: [{ q: 0, r: 1 }],
          }),
        'O hexágono (0, 1) é de duas ações.',
      ],
      [
        'chão que não existe',
        (d: Draft) => (d.tiles[0]!.ground = 'lava_trail'),
        'tem um chão que não existe.',
      ],
      [
        'corpo sem ações',
        (d: Draft) => delete (d as { actions?: unknown }).actions,
        'actions precisa ser uma lista.',
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
      ['altura acima de 10', (d: Draft) => (d.tiles[0]!.height = 11), 'height'],
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

    it('recusa publicar com a chegada num hexágono bloqueado (409)', async () => {
      const body = draft();
      body.walls = [{ type: 'invisible_wall', points: [0, 0, 20, 0] }];
      const id = await create(body);
      const response = await call('post', `/islands/${id}/publish`).expect(409);
      expect(response.body.message).toBe(
        'A chegada não pode ficar num hexágono bloqueado.',
      );
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
      const body = {
        ...draft(),
        tiles: hexagon(81),
        actions: [],
        areas: [],
      };
      expect(body.tiles).toHaveLength(19_927);
      const id = await create(body);
      const response = await call('get', `/islands/${id}`).expect(200);
      expect((response.body as Draft).tiles).toHaveLength(19_927);
    });
  });

  describe('peças soltas (free-props/01)', () => {
    async function flowersId(): Promise<number> {
      return (
        await prisma.propType.findUniqueOrThrow({ where: { slug: 'flowers' } })
      ).id;
    }

    it('salva, lê de volta e publica as peças', async () => {
      const flowers = await flowersId();
      const body = draft();
      body.props = [
        {
          prop_type_id: flowers,
          q: 1,
          r: 0,
          dx: -7,
          dy: 4,
          variant: 2,
          mirrored: true,
        },
        {
          prop_type_id: flowers,
          q: 0,
          r: 0,
          dx: 10,
          dy: -3,
          variant: 1,
          mirrored: false,
        },
      ];
      const id = await create(body);
      const read = await call('get', `/islands/${id}`).expect(200);
      const byFoot = (a: DraftProp, b: DraftProp) => a.r - b.r || a.q - b.q;
      expect([...(read.body as Draft).props!].sort(byFoot)).toEqual(
        [...body.props].sort(byFoot),
      );
      await call('post', `/islands/${id}/publish`).expect(200);
      const published = await call('get', `/islands/${id}`).expect(200);
      expect((published.body as { status: string }).status).toBe('published');

      body.props[0]!.variant = 3;
      await call('put', `/islands/${id}/draft`).send(body).expect(200);
      const changed = await call('get', `/islands/${id}`).expect(200);
      expect((changed.body as { status: string }).status).toBe('changed');
    });

    it('sem o campo props, salva sem peças e devolve a lista vazia', async () => {
      const id = await create();
      const read = await call('get', `/islands/${id}`).expect(200);
      expect((read.body as Draft).props).toEqual([]);
    });

    it.each([
      [
        'a variante 5',
        { variant: 5 },
        'A peça 1 tem a variante 5: vai de 1 a 4.',
      ],
      [
        'o pé fora do hexágono',
        { dy: -30 },
        'A peça 1 tem o pé fora do hexágono (0, 0).',
      ],
      [
        'um hexágono fora da ilha',
        { q: 5 },
        'A peça 1 fica em (5, 0), que não é da ilha.',
      ],
    ])(
      'recusa salvar uma peça com %s (400)',
      async (_label, change, message) => {
        const id = await create();
        const body = draft();
        body.props = [
          {
            prop_type_id: await flowersId(),
            q: 0,
            r: 0,
            dx: 0,
            dy: 0,
            variant: 1,
            mirrored: false,
            ...change,
          },
        ];
        const response = await call('put', `/islands/${id}/draft`)
          .send(body)
          .expect(400);
        expect(response.body.message).toBe(message);
      },
    );
  });

  describe('a marca sem decorações (free-props/05)', () => {
    it('salva e lê de volta a marca só nos hexágonos marcados', async () => {
      const body = draft();
      body.tiles[0]!.bare = true;
      body.tiles[1]!.bare = false;
      const id = await create(body);
      const read = (await call('get', `/islands/${id}`).expect(200))
        .body as Draft;
      const at = (tile: Tile) =>
        read.tiles.find(({ q, r }) => q === tile.q && r === tile.r)!;
      expect(at(body.tiles[0]!).bare).toBe(true);
      expect('bare' in at(body.tiles[1]!)).toBe(false);
    });

    it('recusa uma marca que não é booleana (400)', async () => {
      const id = await create();
      const body = draft() as unknown as { tiles: Record<string, unknown>[] };
      body.tiles[0]!.bare = 'sim';
      const response = await call('put', `/islands/${id}/draft`)
        .send(body)
        .expect(400);
      expect(response.body.message).toBe(
        'bare precisa ser verdadeiro ou falso.',
      );
    });
  });

  describe('os traços de caminho (free-trails/03)', () => {
    it('salva e lê de volta os traços, na mesma ordem', async () => {
      const body = draft();
      body.trails = [
        { ground: 'gravel_trail', width: 22, points: [0, 0, 64, 0] },
        { ground: 'dirt_trail', width: 34, points: [64, 0, 0, 0] },
      ];
      const id = await create(body);
      const read = (await call('get', `/islands/${id}`).expect(200))
        .body as Draft;
      expect(read.trails).toEqual(body.trails);
    });

    it('recusa um traço com ponto fora da ilha (400)', async () => {
      const id = await create();
      const body = draft();
      body.trails = [
        { ground: 'dirt_trail', width: 22, points: [0, 0, 5000, 0] },
      ];
      const response = await call('put', `/islands/${id}/draft`)
        .send(body)
        .expect(400);
      expect(response.body.message).toBe(
        'O traço 1 tem um ponto fora da ilha.',
      );
    });

    it('recusa pontos que não são inteiros (400)', async () => {
      const id = await create();
      const body = draft() as unknown as { trails: unknown[] };
      body.trails = [{ ground: 'dirt_trail', width: 22, points: [0, 'a'] }];
      const response = await call('put', `/islands/${id}/draft`)
        .send(body)
        .expect(400);
      expect(response.body.message).toBe(
        'points precisa ter só números inteiros.',
      );
    });
  });

  describe('as paredes (free-fences/01)', () => {
    it('salva e lê de volta as paredes, na mesma ordem', async () => {
      const body = draft();
      body.walls = [
        { type: 'stone_fence', points: [0, 0, 64, 0] },
        { type: 'invisible_wall', points: [64, 0, 0, 0, 10, 4] },
      ];
      const id = await create(body);
      const read = (await call('get', `/islands/${id}`).expect(200))
        .body as Draft;
      expect(read.walls).toEqual(body.walls);
    });

    it('recusa uma parede com ponto fora da ilha (400)', async () => {
      const id = await create();
      const body = draft();
      body.walls = [{ type: 'wood_fence', points: [0, 0, 5000, 0] }];
      const response = await call('put', `/islands/${id}/draft`)
        .send(body)
        .expect(400);
      expect(response.body.message).toBe(
        'A parede 1 tem um ponto fora da ilha.',
      );
    });

    it('recusa um tipo de parede que não existe (400)', async () => {
      const id = await create();
      const body = draft();
      body.walls = [{ type: 'lava_wall', points: [0, 0, 64, 0] }];
      const response = await call('put', `/islands/${id}/draft`)
        .send(body)
        .expect(400);
      expect(response.body.message).toBe(
        'A parede 1 tem um tipo que não existe.',
      );
    });
  });

  describe('as pontes (bridges/01)', () => {
    it('salva e lê de volta as pontes, na mesma ordem', async () => {
      const body = draft();
      body.bridges = [
        { type: 'wood_bridge', points: [-64, 0, 64, 0], width: 64 },
        { type: 'rope_bridge', points: [32, -42, -32, 42], width: 16 },
        { type: 'wood_bridge', points: [-32, 42, 32, -42] },
      ];
      const id = await create(body);
      const read = (await call('get', `/islands/${id}`).expect(200))
        .body as Draft;
      expect(read.bridges).toEqual([
        body.bridges[0],
        body.bridges[1],
        { ...body.bridges[2], width: 28 },
      ]);
    });

    it('recusa uma ponte larga demais (400)', async () => {
      const id = await create();
      const body = draft();
      body.bridges = [
        { type: 'wood_bridge', points: [-64, 0, 64, 0], width: 65 },
      ];
      const response = await call('put', `/islands/${id}/draft`)
        .send(body)
        .expect(400);
      expect(response.body.message).toBe(
        'A ponte 1 precisa ter de 16 a 64 px de largura.',
      );
    });

    it('lê uma ilha sem pontes com a lista vazia', async () => {
      const id = await create();
      const read = (await call('get', `/islands/${id}`).expect(200))
        .body as Draft;
      expect(read.bridges).toEqual([]);
    });

    it('recusa uma ponta de ponte na água (400)', async () => {
      const id = await create();
      const body = draft();
      body.tiles.find((tile) => tile.q === 1 && tile.r === 0)!.biome =
        'wshallow';
      body.bridges = [{ type: 'wood_bridge', points: [-64, 0, 64, 0] }];
      const response = await call('put', `/islands/${id}/draft`)
        .send(body)
        .expect(400);
      expect(response.body.message).toBe(
        'A ponta da ponte precisa ficar em terra.',
      );
    });

    it('recusa um estilo de ponte que não existe (400)', async () => {
      const id = await create();
      const body = draft();
      body.bridges = [{ type: 'lava_bridge', points: [-64, 0, 64, 0] }];
      const response = await call('put', `/islands/${id}/draft`)
        .send(body)
        .expect(400);
      expect(response.body.message).toBe(
        'A ponte 1 tem um tipo que não existe.',
      );
    });
  });

  describe('as linhas de bloqueio das peças (free-objects/01)', () => {
    const square = {
      closed: true,
      points: [-10, -10, 10, -10, 10, 10, -10, 10],
    };
    const prop = async (block?: DraftProp['block']): Promise<DraftProp> => ({
      prop_type_id: (
        await prisma.propType.findUniqueOrThrow({ where: { slug: 'bench' } })
      ).id,
      q: 1,
      r: 0,
      dx: 0,
      dy: 0,
      variant: 1,
      mirrored: false,
      ...(block === undefined ? {} : { block }),
    });

    it('salva e lê de volta o bloqueio ajustado, e a peça sem ajuste volta sem o campo', async () => {
      const body = draft();
      body.props = [await prop([square]), await prop(), await prop([])];
      body.props[1]!.dx = 5;
      body.props[2]!.dx = -5;
      const id = await create(body);
      const read = (await call('get', `/islands/${id}`).expect(200))
        .body as Draft;
      const byX = (a: DraftProp, b: DraftProp) =>
        (a as { dx: number }).dx - (b as { dx: number }).dx;
      expect([...read.props!].sort(byX)).toEqual([...body.props].sort(byX));
    });

    it('salva e lê de volta a ação da peça (free-objects/03)', async () => {
      const body = draft();
      body.props = [{ ...(await prop([square])), action_type_id: refuge }];
      const id = await create(body);
      const read = (await call('get', `/islands/${id}`).expect(200))
        .body as Draft;
      expect(read.props).toEqual(body.props);
      body.props = [{ ...(await prop()), action_type_id: 999999 }];
      const bad = await call('put', `/islands/${id}/draft`)
        .send(body)
        .expect(400);
      expect(bad.body.message).toBe('A peça 1 tem uma ação que não existe.');
    });

    it('recusa uma linha de bloqueio fora dos limites (400)', async () => {
      const id = await create();
      const body = draft();
      body.props = [await prop([{ closed: true, points: [0, 0, 5, 5] }])];
      const response = await call('put', `/islands/${id}/draft`)
        .send(body)
        .expect(400);
      expect(response.body.message).toBe(
        'A linha de bloqueio 1 da peça 1 fechada precisa ter pelo menos 3 pontos.',
      );
    });

    it('recusa publicar com a chegada tocada por uma linha ou por uma parede (409)', async () => {
      const byLine = draft();
      byLine.props = [{ ...(await prop([square])), q: 0, r: 0 }];
      const first = await create(byLine);
      const response = await call('post', `/islands/${first}/publish`).expect(
        409,
      );
      expect(response.body.message).toBe(
        'A chegada não pode ficar num hexágono bloqueado.',
      );
      const byWall = draft();
      byWall.walls = [{ type: 'invisible_wall', points: [0, 0, 20, 0] }];
      const second = await create(byWall);
      await call('post', `/islands/${second}/publish`).expect(409);
    });
  });

  describe('os NPCs (island-npcs/01)', () => {
    const walker = (): DraftNpc => ({
      npc_id: 1,
      q: 0,
      r: 0,
      still: false,
      tiles: [
        { q: 1, r: -1 },
        { q: -1, r: 1 },
      ],
      dialogue: 'Bem-vindo!\n\nO Refúgio fica ali.',
      action_type_id: refuge,
    });

    it('salva, lê de volta, publica e marca a mudança dos NPCs', async () => {
      const body = draft();
      body.npcs = [walker(), { npc_id: 2, q: -1, r: 0, still: true }];
      const id = await create(body);
      const read = (await call('get', `/islands/${id}`).expect(200))
        .body as Draft;
      expect(read.npcs).toEqual([
        walker(),
        {
          npc_id: 2,
          q: -1,
          r: 0,
          still: true,
          tiles: [],
          dialogue: '',
          action_type_id: null,
        },
      ]);

      await call('post', `/islands/${id}/publish`).expect(200);
      body.npcs[0]!.dialogue = 'Outra fala.';
      const saved = await call('put', `/islands/${id}/draft`)
        .send(body)
        .expect(200);
      expect((saved.body as { status: string }).status).toBe('changed');
    });

    it('sem o campo npcs, devolve a lista vazia e mantém o hash de antes', async () => {
      const id = await create();
      const read = (await call('get', `/islands/${id}`).expect(200))
        .body as Draft;
      expect(read.npcs).toEqual([]);
      await call('post', `/islands/${id}/publish`).expect(200);
      const saved = await call('put', `/islands/${id}/draft`)
        .send({ ...draft(), npcs: [] })
        .expect(200);
      expect((saved.body as { status: string }).status).toBe('published');
    });

    const many = Array.from({ length: 41 }, (_, q) => ({ q: q - 20, r: 30 }));

    it.each<[string, Partial<DraftNpc> | null, string]>([
      [
        'fora do catálogo',
        { npc_id: 999_999 },
        'O NPC 2 não existe no catálogo.',
      ],
      [
        'nascendo fora da ilha',
        { q: 3, r: 1 },
        'O NPC 2 fica em (3, 1), que não é da ilha.',
      ],
      [
        'passeando fora da ilha',
        { tiles: [{ q: 4, r: 1 }] },
        'O NPC 2 passeia por (4, 1), que não é da ilha.',
      ],
      [
        'repetindo o hexágono de nascimento',
        { tiles: [{ q: 0, r: 0 }] },
        'O NPC 2 repete o hexágono (0, 0) no passeio.',
      ],
      [
        'passeando por mais de 40 hexágonos',
        { tiles: many },
        'O NPC 2 passeia por mais de 40 hexágonos.',
      ],
      [
        'com diálogo de mais de 2.000 caracteres',
        { dialogue: 'a'.repeat(2_001) },
        'O diálogo do NPC 2 passa de 2.000 caracteres.',
      ],
      [
        'com uma ação que não existe',
        { action_type_id: 999_999 },
        'O NPC 2 tem uma ação que não existe.',
      ],
      ['a mais na ilha', null, 'A ilha pode ter até 200 NPCs.'],
    ])('recusa salvar um NPC %s (400)', async (_label, change, message) => {
      const id = await create();
      const body = draft();
      body.tiles.push(
        ...many.map(({ q, r }) => ({
          q,
          r,
          biome: 'temperate',
          height: 1,
          variant: 1,
        })),
      );
      body.npcs =
        change === null
          ? Array.from({ length: 201 }, walker)
          : [walker(), { ...walker(), ...change }];
      const response = await call('put', `/islands/${id}/draft`)
        .send(body)
        .expect(400);
      expect(response.body.message).toBe(message);
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

    it('gera o mesmo mapa com a mesma seed e mais água com mais sea_fraction', async () => {
      const ask = (config: object) =>
        call('post', '/map-generator')
          .send({ seed: 42, config: { tile_count: 500, ...config } })
          .expect(200)
          .then((response) => response.body as Generated);
      const first = await ask({ sea_fraction: 0.1 });
      const again = await ask({ sea_fraction: 0.1 });
      const wetter = await ask({ sea_fraction: 0.6 });
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
