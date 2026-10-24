// Carga inicial do catálogo (.specs/backend-api/03-catalog-seed.md).
// Copia os JSON de SEED_DATA_DIR para o banco uma única vez: só roda com o
// catálogo vazio e nunca apaga nem sobrescreve linhas. Depois dela, o banco é
// o dono do catálogo. Rodar com: npm run db:seed
import 'dotenv/config';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../src/generated/prisma/client.js';
import {
  CATALOG_TABLES,
  SEED_DATA_DIR,
} from '../src/catalog/catalog-tables.js';
import { snakeToCamelKeys } from '../src/common/case.js';
import { seedPlan } from './seed-plan.js';

type Row = Record<string, unknown>;
/** O pedaço de cada delegate do Prisma que o seed usa. */
interface Delegate {
  count(): Promise<number>;
  createMany(args: { data: Row[] }): Promise<unknown>;
}

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString: process.env['DIRECT_URL'] }),
});

const delegate = (client: object, model: string): Delegate =>
  (client as Record<string, Delegate>)[model];

function readTable(name: string): Row[] {
  return JSON.parse(
    readFileSync(join(SEED_DATA_DIR, `${name}.json`), 'utf8'),
  ) as Row[];
}

async function countTables(): Promise<Record<string, number>> {
  const counts: Record<string, number> = {};
  for (const table of CATALOG_TABLES) {
    counts[table.name] = await delegate(prisma, table.model).count();
  }
  return counts;
}

async function load(): Promise<number> {
  let current = '';
  let inserted = 0;
  try {
    await prisma.$transaction(
      async (tx) => {
        for (const table of CATALOG_TABLES) {
          current = table.name;
          const rows = readTable(table.name).map(snakeToCamelKeys);
          if (table.name === 'species') {
            // Autorreferência: primeiro todas sem "de quem ascende", depois o valor.
            await delegate(tx, table.model).createMany({
              data: rows.map((row) => ({ ...row, evolvesFromSpeciesId: null })),
            });
            for (const row of rows.filter(
              (r) => r['evolvesFromSpeciesId'] !== null,
            )) {
              await tx.species.update({
                where: { id: row['id'] as number },
                data: {
                  evolvesFromSpeciesId: row['evolvesFromSpeciesId'] as number,
                },
              });
            }
          } else {
            await delegate(tx, table.model).createMany({ data: rows });
          }
          inserted += rows.length;
        }
        current = 'sequências';
        // Uma linha criada depois no painel ganha o id seguinte ao maior.
        for (const table of CATALOG_TABLES.filter(
          (t) => t.key.length === 1 && t.key[0] === 'id',
        )) {
          await tx.$queryRawUnsafe(
            `SELECT setval(pg_get_serial_sequence('"ecobeasts"."${table.name}"', 'id'), (SELECT max("id") FROM "ecobeasts"."${table.name}"))`,
          );
        }
      },
      { maxWait: 10_000, timeout: 120_000 },
    );
  } catch (error) {
    throw new Error(`${current}: ${(error as Error).message}`);
  }
  return inserted;
}

async function main(): Promise<number> {
  const plan = seedPlan(await countTables());
  if (plan === 'skip') {
    console.log('Banco já tem catálogo; nada foi feito.');
    return 0;
  }
  if (plan !== 'load') {
    console.error(
      `Catálogo incompleto no banco (${plan.incomplete.join(', ')}); nada foi feito.`,
    );
    return 1;
  }
  try {
    const rows = await load();
    console.log(
      `Catálogo carregado: ${CATALOG_TABLES.length} tabelas, ${rows} linhas`,
    );
    return 0;
  } catch (error) {
    console.error(`Falha na carga do catálogo: ${(error as Error).message}`);
    return 1;
  }
}

process.exitCode = await main();
await prisma.$disconnect();
