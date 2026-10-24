import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import {
  CATALOG_TABLES,
  SEED_DATA_DIR,
} from '../src/catalog/catalog-tables.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { attempt, createTestPrisma } from './support/db.js';

// Depois do seed, toda linha dos JSON existe no banco com a mesma chave.
// Só confere a presença: o dono pode acrescentar linhas e mudar valores.
// (.specs/backend-api/03-catalog-seed.md)

describe('carga inicial do catálogo (e2e)', () => {
  let prisma: PrismaClient;

  beforeAll(() => {
    prisma = createTestPrisma();
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it.each(CATALOG_TABLES.map((table) => [table.name, table] as const))(
    '%s: toda linha do JSON está no banco',
    async (_name, table) => {
      const rows = JSON.parse(
        readFileSync(join(SEED_DATA_DIR, `${table.name}.json`), 'utf8'),
      ) as Record<string, unknown>[];
      const columns = table.key.map((column) => `"${column}"`).join(', ');
      const inDb = await prisma.$queryRawUnsafe<Record<string, unknown>[]>(
        `SELECT ${columns} FROM "ecobeasts"."${table.name}"`,
      );
      const keyOf = (row: Record<string, unknown>) =>
        table.key.map((column) => String(row[column])).join('|');
      const dbKeys = new Set(inDb.map(keyOf));
      const missing = rows.map(keyOf).filter((key) => !dbKeys.has(key));
      expect(missing).toEqual([]);
    },
  );

  it('Brasalobo (id 2) ascende de Fagulho (id 1)', async () => {
    const species = await prisma.species.findUnique({ where: { id: 2 } });
    expect(species?.evolvesFromSpeciesId).toBe(1);
  });

  it('uma linha nova sem id ganha o id seguinte ao maior (sequências ajustadas)', async () => {
    const max = await prisma.growthRate.aggregate({ _max: { id: true } });
    let created = -1;
    const result = await attempt(prisma, async (tx) => {
      const row = await tx.growthRate.create({
        data: { slug: 'zz_test_sequence', name: 'Teste', xpMultiplier: 1 },
      });
      created = row.id;
    });
    expect(result).toBe('accepted');
    expect(created).toBeGreaterThan(max._max.id ?? 0);
  });
});
