import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../../src/generated/prisma/client.js';

/** Cliente do Prisma para os testes e2e, ligado ao banco do .env. */
export function createTestPrisma(): PrismaClient {
  return new PrismaClient({
    adapter: new PrismaPg({ connectionString: process.env['DATABASE_URL'] }),
  });
}

export type Tx = Parameters<Parameters<PrismaClient['$transaction']>[0]>[0];

const ROLLBACK = Symbol('rollback');

/**
 * Roda `work` numa transação que é sempre desfeita. Devolve 'accepted' se o
 * banco aceitou tudo, ou o erro que o banco levantou. O banco fica como estava.
 */
export async function attempt(
  prisma: PrismaClient,
  work: (tx: Tx) => Promise<unknown>,
): Promise<'accepted' | Error> {
  try {
    await prisma.$transaction(async (tx) => {
      await work(tx);
      throw ROLLBACK;
    });
  } catch (error) {
    if (error === ROLLBACK) return 'accepted';
    return error as Error;
  }
  throw new Error('a transação deveria ter sido desfeita');
}

let counter = 0;
/** Slug único dentro da execução, para não colidir com dados reais. */
export function testSlug(prefix: string): string {
  counter += 1;
  return `zz_test_${prefix}_${Date.now()}_${counter}`;
}
