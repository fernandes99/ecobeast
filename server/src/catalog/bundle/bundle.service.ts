import { Injectable } from '@nestjs/common';
import { camelToSnakeKeys, snakeToCamelKeys } from '../../common/case.js';
import { PrismaService } from '../../prisma/prisma.service.js';
import { CATALOG_TABLES } from '../catalog-tables.js';
import { CatalogTables, catalogVersion } from './catalog-version.js';

export const CATALOG_CACHE_TTL_MS = 60_000;

export interface CatalogBundle {
  version: string;
  tables: CatalogTables;
}

interface ReadDelegate {
  findMany(args: { orderBy: object[] }): Promise<Record<string, unknown>[]>;
}

@Injectable()
export class BundleService {
  private cached?: { at: number; bundle: Promise<CatalogBundle> };

  constructor(private readonly prisma: PrismaService) {}

  get(): Promise<CatalogBundle> {
    const now = Date.now();
    if (!this.cached || now - this.cached.at >= CATALOG_CACHE_TTL_MS) {
      // Guarda a promessa, não o resultado: chamadas ao mesmo tempo esperam a
      // mesma leitura. Se ela falhar, sai do cache e a próxima tenta de novo.
      const bundle = this.load();
      this.cached = { at: now, bundle };
      bundle.catch(() => {
        if (this.cached?.bundle === bundle) this.cached = undefined;
      });
    }
    return this.cached.bundle;
  }

  private async load(): Promise<CatalogBundle> {
    const entries = await Promise.all(
      CATALOG_TABLES.map(async (table) => {
        const rows = await this.delegate(table.model).findMany({
          orderBy: table.key.map((column) =>
            snakeToCamelKeys({ [column]: 'asc' }),
          ),
        });
        return [table.name, rows.map(camelToSnakeKeys)] as const;
      }),
    );
    const tables: CatalogTables = Object.fromEntries(entries);
    return { version: catalogVersion(tables), tables };
  }

  private delegate(model: string): ReadDelegate {
    return (this.prisma as unknown as Record<string, ReadDelegate>)[model];
  }
}
