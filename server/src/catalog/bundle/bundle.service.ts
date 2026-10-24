import { Injectable } from '@nestjs/common';
import { camelToSnakeKeys, snakeToCamelKeys } from '../../common/case.js';
import { PrismaService } from '../../prisma/prisma.service.js';
import { CATALOG_TABLES } from '../catalog-tables.js';
import { CatalogTables, catalogVersion } from './catalog-version.js';

/** Por quanto tempo o catálogo montado fica em memória (RF-05). */
export const CATALOG_CACHE_TTL_MS = 60_000;

export interface CatalogBundle {
  version: string;
  tables: CatalogTables;
}

/** O pedaço de cada delegate do Prisma que o catálogo inteiro usa. */
interface ReadDelegate {
  findMany(args: { orderBy: object[] }): Promise<Record<string, unknown>[]>;
}

/**
 * Monta o catálogo inteiro (.specs/backend-api/06-catalog-bundle.md): as 23
 * tabelas no formato dos JSON do cliente, com a versão. Guarda o resultado por
 * 60 s; uma mudança feita no painel aparece em até 1 minuto.
 */
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
