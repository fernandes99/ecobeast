import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { CATALOG_TABLES, SEED_DATA_DIR } from './catalog-tables.js';

describe('CATALOG_TABLES', () => {
  const names = CATALOG_TABLES.map((table) => table.name);

  it('tem as 41 tabelas, sem repetição', () => {
    expect(names).toHaveLength(41);
    expect(new Set(names).size).toBe(41);
  });

  it('casa com os arquivos .json da pasta de dados do seed', () => {
    const files = readdirSync(SEED_DATA_DIR)
      .filter((file) => file.endsWith('.json'))
      .map((file) => file.replace(/\.json$/, ''));
    expect([...names].sort()).toEqual(files.sort());
  });

  it('começa pelas referências e termina nos iniciais (ordem de dependência)', () => {
    expect(names[0]).toBe('elements');
    expect(names.indexOf('species')).toBeLessThan(
      names.indexOf('species_elements'),
    );
    expect(names.indexOf('skills')).toBeLessThan(
      names.indexOf('species_skills'),
    );
    expect(names.indexOf('item_categories')).toBeLessThan(
      names.indexOf('items'),
    );
    expect(names.indexOf('biomes')).toBeLessThan(
      names.indexOf('species_biomes'),
    );
    expect(names.indexOf('species')).toBeLessThan(
      names.indexOf('species_biomes'),
    );
    expect(names.indexOf('area_shapes')).toBeLessThan(names.indexOf('skills'));
    expect(names.indexOf('status_conditions')).toBeLessThan(
      names.indexOf('ground_effects'),
    );
    expect(names.indexOf('ground_effects')).toBeLessThan(
      names.indexOf('skills'),
    );
    expect(names.at(-1)).toBe('starter_options');
  });

  it('guarda o delegate do Prisma e a chave em snake_case', () => {
    const efficacy = CATALOG_TABLES.find(
      (table) => table.name === 'element_efficacy',
    );
    expect(efficacy).toEqual({
      name: 'element_efficacy',
      model: 'elementEfficacy',
      key: ['attacker_element_id', 'defender_element_id'],
    });
  });
});

describe('carga inicial dos biomas (biome-encounters/01)', () => {
  const read = <T>(name: string) =>
    JSON.parse(
      readFileSync(join(SEED_DATA_DIR, `${name}.json`), 'utf8'),
    ) as T[];
  const biomes = read<{ id: number; slug: string }>('biomes');
  const rates = read<{ species_id: number; biome_id: number; rate: number }>(
    'species_biomes',
  );
  const biomeId = (slug: string) => biomes.find((b) => b.slug === slug)!.id;
  const ELU = 7;

  it('tem os 7 biomas de encontro', () => {
    expect(biomes.map(({ slug }) => slug).sort()).toEqual(
      [
        'boreal',
        'hill',
        'mountain',
        'stone',
        'temperate',
        'wdeep',
        'wshallow',
      ].sort(),
    );
  });

  it('não grava taxa 0: sem linha, a espécie não nasce no bioma', () => {
    expect(rates.every(({ rate }) => rate >= 1 && rate <= 100)).toBe(true);
  });

  it('dá taxas aos 9 Ecobeasts, sem pares repetidos', () => {
    const species = new Set(rates.map(({ species_id }) => species_id));
    expect([...species].sort((a, b) => a - b)).toEqual([
      1, 2, 3, 4, 5, 6, 7, 8, 9,
    ]);
    const pairs = rates.map((row) => `${row.species_id}|${row.biome_id}`);
    expect(new Set(pairs).size).toBe(pairs.length);
  });

  it('o Elu é bem mais comum no boreal que na montanha, e não está na água', () => {
    const rate = (slug: string) =>
      rates.find(
        (row) => row.species_id === ELU && row.biome_id === biomeId(slug),
      )?.rate;
    expect(rate('boreal')).toBeGreaterThan(rate('mountain')! * 10);
    expect(rate('wshallow')).toBeUndefined();
    expect(rate('wdeep')).toBeUndefined();
  });
});

describe('carga inicial das Técnicas no tabuleiro (board-battle/01)', () => {
  const read = <T>(name: string) =>
    JSON.parse(
      readFileSync(join(SEED_DATA_DIR, `${name}.json`), 'utf8'),
    ) as T[];
  interface SkillRow {
    slug: string;
    area_shape_id: number;
    range: number;
    pierces: boolean;
    ground_effect_id: number | null;
    ground_turns: number | null;
  }
  const shapes = read<{ id: number; slug: string }>('area_shapes');
  const grounds = read<{
    id: number;
    slug: string;
    damage_percent: number | null;
    status_condition_id: number | null;
  }>('ground_effects');
  const skills = read<SkillRow>('skills');
  const shapeId = (slug: string) => shapes.find((s) => s.slug === slug)!.id;
  const FIRE = grounds.find((g) => g.slug === 'fire')!;
  const SPECIAL = ['faisca_rapida', 'chama_espiral'];

  const board = (row: SkillRow) => ({
    area_shape_id: row.area_shape_id,
    range: row.range,
    pierces: row.pierces,
    ground_effect_id: row.ground_effect_id,
    ground_turns: row.ground_turns,
  });
  const skill = (slug: string) => skills.find((row) => row.slug === slug)!;

  it('tem as formas single e line, e o chão em chamas', () => {
    expect(shapes.map(({ slug }) => slug)).toEqual(['single', 'line']);
    expect(FIRE).toMatchObject({
      damage_percent: 6,
      status_condition_id: null,
    });
  });

  it('deixa as outras 36 Técnicas no corpo a corpo, com alcance 1', () => {
    const others = skills.filter((row) => !SPECIAL.includes(row.slug));
    expect(others).toHaveLength(36);
    for (const row of others) {
      expect(board(row), row.slug).toEqual({
        area_shape_id: shapeId('single'),
        range: 1,
        pierces: false,
        ground_effect_id: null,
        ground_turns: null,
      });
    }
  });

  it('Faísca Rápida anda em linha reta por 3, sem atravessar', () => {
    expect(board(skill('faisca_rapida'))).toEqual({
      area_shape_id: shapeId('line'),
      range: 3,
      pierces: false,
      ground_effect_id: null,
      ground_turns: null,
    });
  });

  it('Chama Espiral acerta a até 3 e deixa o chão em chamas por 6 vezes', () => {
    expect(board(skill('chama_espiral'))).toEqual({
      area_shape_id: shapeId('single'),
      range: 3,
      pierces: false,
      ground_effect_id: FIRE.id,
      ground_turns: 6,
    });
  });
});

describe('CATALOG_TABLES e o cliente do Prisma', () => {
  it('cada model é um delegate do cliente (nome do modelo, no singular)', async () => {
    const { PrismaClient } = await import('../generated/prisma/client.js');
    const { PrismaPg } = await import('@prisma/adapter-pg');
    // Não conecta: só cria o cliente para ver os delegates.
    const client = new PrismaClient({
      adapter: new PrismaPg({
        connectionString: 'postgresql://x@localhost:1/x',
      }),
    });
    const missing = CATALOG_TABLES.filter(
      (table) =>
        typeof (client as unknown as Record<string, { findMany?: unknown }>)[
          table.model
        ]?.findMany !== 'function',
    ).map((table) => `${table.name} → ${table.model}`);
    expect(missing).toEqual([]);
  });
});

describe('carga inicial dos nomes e falas dos Domadores (npc-tamers/01)', () => {
  const read = <T>(name: string) =>
    JSON.parse(
      readFileSync(join(SEED_DATA_DIR, `${name}.json`), 'utf8'),
    ) as T[];
  const names = read<{ id: number; name: string }>('npc_tamer_names');
  const greetings = read<{ id: number; text: string }>('npc_tamer_greetings');

  it('tem 12 nomes, de 1 a 20 caracteres, começando por Lia', () => {
    expect(names).toHaveLength(12);
    expect(names[0]).toEqual({ id: 1, name: 'Lia' });
    expect(
      names.every(({ name }) => name.length >= 1 && name.length <= 20),
    ).toBe(true);
  });

  it('tem as 3 falas, de 1 a 120 caracteres, sem o nome na frente', () => {
    expect(greetings.map(({ id }) => id)).toEqual([1, 2, 3]);
    expect(greetings[0]!.text).toBe(
      'O que está fazendo aqui? Vamos nos enfrentar!',
    );
    expect(
      greetings.every(({ text }) => text.length >= 1 && text.length <= 120),
    ).toBe(true);
  });
});

describe('carga inicial dos tipos de ação (island-villages/01)', () => {
  const types = JSON.parse(
    readFileSync(join(SEED_DATA_DIR, 'action_types.json'), 'utf8'),
  ) as {
    id: number;
    slug: string;
    name: string;
    color_hex: string;
    kind: string;
  }[];

  it('todos abrem uma tela', () => {
    expect(types.every(({ kind }) => kind === 'open_screen')).toBe(true);
  });

  it('tem Refúgio, Loja, Arena e Casa, nessa ordem', () => {
    expect(types.map(({ slug, name }) => [slug, name])).toEqual([
      ['refuge', 'Refúgio'],
      ['shop', 'Loja'],
      ['arena', 'Arena'],
      ['house', 'Casa'],
    ]);
  });

  it('cada um tem uma cor #RRGGBB', () => {
    for (const { color_hex } of types) {
      expect(color_hex).toMatch(/^#[0-9A-Fa-f]{6}$/);
    }
  });
});

describe('carga inicial dos tipos de parede (free-fences/01)', () => {
  const walls = JSON.parse(
    readFileSync(join(SEED_DATA_DIR, 'wall_types.json'), 'utf8'),
  ) as { id: number; slug: string; name: string; visible: boolean }[];

  it('tem a cerca de madeira, o muro de pedra e a parede invisível, com ids estáveis', () => {
    expect(walls.map(({ id, slug, visible }) => [id, slug, visible])).toEqual([
      [1, 'wood_fence', true],
      [2, 'stone_fence', true],
      [3, 'invisible_wall', false],
    ]);
  });
});

describe('carga inicial do chão (island-villages/01)', () => {
  const read = <T>(file: string): T =>
    JSON.parse(readFileSync(join(SEED_DATA_DIR, file), 'utf8')) as T;
  const grounds =
    read<{ slug: string; kind: string; hardness: number }[]>(
      'ground_types.json',
    );

  it('tem seis trilhas e dois pisos, cada um com a dureza (free-trails/01)', () => {
    expect(grounds.map(({ kind }) => kind)).toEqual([
      'trail',
      'trail',
      'floor',
      'floor',
      'trail',
      'trail',
      'trail',
      'trail',
    ]);
    for (const { hardness } of grounds) {
      expect(hardness).toBeGreaterThanOrEqual(1);
      expect(hardness).toBeLessThanOrEqual(3);
    }
  });
});

describe('carga inicial das peças soltas (free-props/01, free-objects/04)', () => {
  const read = <T>(file: string): T =>
    JSON.parse(readFileSync(join(SEED_DATA_DIR, file), 'utf8')) as T;
  const props =
    read<{ id: number; slug: string; variants: number }[]>('prop_types.json');
  const blocks = read<
    {
      prop_type_id: number;
      position: number;
      closed: boolean;
      points: number[];
    }[]
  >('prop_type_blocks.json');

  it('tem os 27 tipos, de 1 a 27, com pelo menos 1 variante', () => {
    expect(props.map(({ id }) => id)).toEqual(
      Array.from({ length: 27 }, (_, index) => index + 1),
    );
    for (const { variants } of props)
      expect(variants).toBeGreaterThanOrEqual(1);
  });

  it('as decorações de rua e os prédios da cidade são peças', () => {
    expect(props.slice(17).map(({ slug }) => slug)).toEqual([
      'lamp_post',
      'sign',
      'flower_bed',
      'bench',
      'refuge_building',
      'shop_building',
      'town_house',
      'town_house_medium',
      'town_house_large',
      'observatory',
    ]);
  });

  it('só os prédios bloqueiam, cada um com uma linha fechada de pontos pares', () => {
    expect(blocks.map(({ prop_type_id }) => prop_type_id)).toEqual([
      22, 23, 24, 25, 26, 27,
    ]);
    for (const { closed, points } of blocks) {
      expect(closed).toBe(true);
      expect(points.length % 2).toBe(0);
      expect(points.length).toBeGreaterThanOrEqual(6);
    }
  });
});

describe('carga inicial dos NPCs (island-npcs/01)', () => {
  const read = <T>(file: string): T =>
    JSON.parse(readFileSync(join(SEED_DATA_DIR, file), 'utf8')) as T;
  const npcs =
    read<{ id: number; slug: string; sprite: string }[]>('npcs.json');
  const species = read<{ slug: string }[]>('species.json');

  it('tem os 2 NPCs de teste, com o sprite de um Ecobeast', () => {
    expect(npcs.map(({ id, slug }) => [id, slug])).toEqual([
      [1, 'village_ruvo'],
      [2, 'guard_ruvak'],
    ]);
    for (const { sprite } of npcs) {
      expect(species.some(({ slug }) => slug === sprite)).toBe(true);
    }
  });
});

describe('carga inicial da aparência (tamer-appearance/01)', () => {
  const read = <T>(file: string): T =>
    JSON.parse(readFileSync(join(SEED_DATA_DIR, file), 'utf8')) as T;
  const bodies = read<{ id: number; slug: string }[]>('body_types.json');
  const slots = read<{ id: number; slug: string; layer: number }[]>(
    'appearance_slots.json',
  );
  const palettes = read<Record<string, string | number>[]>('palettes.json');
  const parts = read<{ id: number; appearance_slot_id: number }[]>(
    'appearance_parts.json',
  );

  it('tem os 2 corpos e os 6 lugares na ordem de desenho, com ids estáveis', () => {
    expect(bodies.map(({ id, slug }) => [id, slug])).toEqual([
      [1, 'male'],
      [2, 'female'],
    ]);
    expect(slots.map(({ id, slug, layer }) => [id, slug, layer])).toEqual([
      [1, 'face', 1],
      [2, 'bottom', 2],
      [3, 'shoes', 3],
      [4, 'top', 4],
      [5, 'hair', 5],
      [6, 'headwear', 6],
    ]);
  });

  it('a aparência padrão existe: a pele 1 e o rosto 1', () => {
    expect(palettes[0]).toMatchObject({ id: 1, kind: 'skin' });
    expect(parts[0]).toEqual(
      expect.objectContaining({ id: 1, appearance_slot_id: 1 }),
    );
  });

  it('cada paleta tem 4 cores #rrggbb', () => {
    for (const palette of palettes) {
      for (const shade of [1, 2, 3, 4]) {
        expect(palette[`color${shade}_hex`]).toMatch(/^#[0-9a-f]{6}$/);
      }
    }
  });
});

describe('carga inicial do guarda-roupa (tamer-appearance/04)', () => {
  const read = <T>(file: string): T =>
    JSON.parse(readFileSync(join(SEED_DATA_DIR, file), 'utf8')) as T;
  const parts = read<
    {
      slug: string;
      appearance_slot_id: number;
      body_type_id: number | null;
      hair_cut: string;
    }[]
  >('appearance_parts.json');
  const palettes = read<{ kind: string }[]>('palettes.json');

  it('tem as 17 peças, só a saia presa a um corpo e só os chapéus escondendo cabelo', () => {
    expect(parts).toHaveLength(17);
    expect(parts.filter(({ body_type_id }) => body_type_id !== null)).toEqual([
      expect.objectContaining({ slug: 'skirt', body_type_id: 2 }),
    ]);
    for (const { appearance_slot_id, hair_cut } of parts) {
      if (appearance_slot_id !== 6) expect(hair_cut).toBe('none');
    }
  });

  it('tem 6 peles, 8 cores de cabelo e 10 de roupa', () => {
    const count = (kind: string) =>
      palettes.filter((palette) => palette.kind === kind).length;
    expect([count('skin'), count('hair'), count('cloth')]).toEqual([6, 8, 10]);
  });
});
