import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { CATALOG_TABLES, SEED_DATA_DIR } from './catalog-tables.js';

describe('CATALOG_TABLES', () => {
  const names = CATALOG_TABLES.map((table) => table.name);

  it('tem as 27 tabelas, sem repetição', () => {
    expect(names).toHaveLength(27);
    expect(new Set(names).size).toBe(27);
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
    JSON.parse(readFileSync(join(SEED_DATA_DIR, `${name}.json`), 'utf8')) as T[];
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
