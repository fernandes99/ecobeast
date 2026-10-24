import { readdirSync } from 'node:fs';
import { CATALOG_TABLES, SEED_DATA_DIR } from './catalog-tables.js';

describe('CATALOG_TABLES', () => {
  const names = CATALOG_TABLES.map((table) => table.name);

  it('tem as 23 tabelas, sem repetição', () => {
    expect(names).toHaveLength(23);
    expect(new Set(names).size).toBe(23);
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
