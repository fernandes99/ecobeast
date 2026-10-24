import { createHash } from 'node:crypto';

/** As tabelas do catálogo como o jogo recebe: nome → linhas em snake_case. */
export type CatalogTables = Record<string, Record<string, unknown>[]>;

/**
 * A versão do catálogo (.specs/backend-api/06-catalog-bundle.md, RF-03): o
 * SHA-256, em hex, das tabelas com os nomes em ordem alfabética. As linhas já
 * chegam na ordem da chave, então qualquer valor diferente muda a versão.
 */
export function catalogVersion(tables: CatalogTables): string {
  const sorted: CatalogTables = {};
  for (const name of Object.keys(tables).sort()) {
    sorted[name] = tables[name];
  }
  return createHash('sha256').update(JSON.stringify(sorted)).digest('hex');
}
