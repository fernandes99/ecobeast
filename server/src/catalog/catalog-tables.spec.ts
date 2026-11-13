import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { CATALOG_TABLES, SEED_DATA_DIR } from './catalog-tables.js';

describe('CATALOG_TABLES', () => {
  const names = CATALOG_TABLES.map((table) => table.name);

  it('tem as 35 tabelas, sem repetição', () => {
    expect(names).toHaveLength(35);
    expect(new Set(names).size).toBe(35);
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

describe('carga inicial do chão e dos objetos (island-villages/01)', () => {
  const read = <T>(file: string): T =>
    JSON.parse(readFileSync(join(SEED_DATA_DIR, file), 'utf8')) as T;
  const grounds = read<{ slug: string; kind: string }[]>('ground_types.json');
  const objects = read<{ id: number; slug: string; variants: number }[]>(
    'map_object_types.json',
  );
  const tiles = read<
    { object_type_id: number; dq: number; dr: number; blocks: boolean }[]
  >('map_object_type_tiles.json');

  it('tem duas trilhas e dois pisos', () => {
    expect(grounds.map(({ kind }) => kind)).toEqual([
      'trail',
      'trail',
      'floor',
      'floor',
    ]);
  });

  it('tem os 34 objetos, cada um com o hexágono de apoio e pelo menos 1 variante', () => {
    expect(objects).toHaveLength(34);
    for (const { id, variants } of objects) {
      expect(variants).toBeGreaterThanOrEqual(1);
      expect(
        tiles.some(
          (tile) =>
            tile.object_type_id === id && tile.dq === 0 && tile.dr === 0,
        ),
      ).toBe(true);
    }
  });

  it('as casas têm 1, 2 e 3 hexágonos; a árvore e a pedra, 1', () => {
    const size = (slug: string) => {
      const { id } = objects.find((object) => object.slug === slug)!;
      return tiles.filter(({ object_type_id }) => object_type_id === id).length;
    };
    expect(
      ['house', 'house_medium', 'house_large', 'tree', 'rock'].map(size),
    ).toEqual([1, 2, 3, 1, 1]);
  });

  it('a Vegetação ocupa 1 hexágono sem bloquear, e a casa na árvore saiu', () => {
    const plants = objects.find((object) => object.slug === 'plants')!;
    expect(
      tiles.filter(({ object_type_id }) => object_type_id === plants.id),
    ).toEqual([{ object_type_id: plants.id, dq: 0, dr: 0, blocks: false }]);
    expect(objects.some(({ slug }) => slug === 'treehouse')).toBe(false);
  });
});
