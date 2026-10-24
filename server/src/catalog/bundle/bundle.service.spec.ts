import type { PrismaService } from '../../prisma/prisma.service.js';
import { CATALOG_TABLES } from '../catalog-tables.js';
import { BundleService, CATALOG_CACHE_TTL_MS } from './bundle.service.js';
import { catalogVersion } from './catalog-version.js';

const START = new Date('2026-10-24T12:00:00Z').getTime();

/** Um Prisma de mentira: cada tabela tem uma linha e conta as leituras. */
function fakePrisma(options: { fail?: () => boolean } = {}) {
  const reads = { loads: 0, orderBy: {} as Record<string, unknown> };
  const prisma: Record<string, unknown> = {};
  for (const table of CATALOG_TABLES) {
    prisma[table.model] = {
      findMany: async (args: { orderBy: unknown }) => {
        if (table.name === 'elements') reads.loads++;
        reads.orderBy[table.name] = args.orderBy;
        if (options.fail?.()) throw new Error('banco fora do ar');
        return [{ id: 1, growthRateId: reads.loads }];
      },
    };
  }
  return { prisma: prisma as unknown as PrismaService, reads };
}

describe('BundleService', () => {
  beforeEach(() => {
    vi.useFakeTimers({ toFake: ['Date'] });
    vi.setSystemTime(START);
  });

  afterEach(() => vi.useRealTimers());

  it('monta as 23 tabelas em snake_case, com a versão delas', async () => {
    const { prisma } = fakePrisma();
    const bundle = await new BundleService(prisma).get();
    expect(Object.keys(bundle.tables)).toHaveLength(CATALOG_TABLES.length);
    expect(bundle.tables['species']).toEqual([{ id: 1, growth_rate_id: 1 }]);
    expect(bundle.version).toBe(catalogVersion(bundle.tables));
  });

  it('ordena cada tabela pela chave, em camelCase', async () => {
    const { prisma, reads } = fakePrisma();
    await new BundleService(prisma).get();
    expect(reads.orderBy['species']).toEqual([{ id: 'asc' }]);
    expect(reads.orderBy['element_efficacy']).toEqual([
      { attackerElementId: 'asc' },
      { defenderElementId: 'asc' },
    ]);
  });

  it('duas chamadas em menos de 60 s leem o banco uma vez só', async () => {
    const { prisma, reads } = fakePrisma();
    const service = new BundleService(prisma);
    const first = await service.get();
    vi.setSystemTime(START + CATALOG_CACHE_TTL_MS - 1);
    expect(await service.get()).toBe(first);
    expect(reads.loads).toBe(1);
  });

  it('depois de 60 s a chamada seguinte lê o banco de novo', async () => {
    const { prisma, reads } = fakePrisma();
    const service = new BundleService(prisma);
    const first = await service.get();
    vi.setSystemTime(START + CATALOG_CACHE_TTL_MS);
    const second = await service.get();
    expect(reads.loads).toBe(2);
    expect(second.version).not.toBe(first.version);
  });

  it('chamadas ao mesmo tempo, sem cache, leem o banco uma vez só', async () => {
    const { prisma, reads } = fakePrisma();
    const service = new BundleService(prisma);
    await Promise.all([service.get(), service.get(), service.get()]);
    expect(reads.loads).toBe(1);
  });

  it('uma falha do banco não fica no cache', async () => {
    let down = true;
    const { prisma, reads } = fakePrisma({ fail: () => down });
    const service = new BundleService(prisma);
    await expect(service.get()).rejects.toThrow('banco fora do ar');
    down = false;
    await expect(service.get()).resolves.toHaveProperty('version');
    expect(reads.loads).toBe(2);
  });
});
