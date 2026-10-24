/**
 * Conversão mecânica entre os nomes de coluna do banco e dos JSON (snake_case)
 * e os campos do Prisma (camelCase). Funciona porque todo @map do
 * schema.prisma segue essa regra (.specs/backend-api/02-database-schema.md, RF-01).
 */

type Row = Record<string, unknown>;

const toCamel = (key: string): string =>
  key.replace(/_([a-z0-9])/g, (_match, char: string) => char.toUpperCase());
const toSnake = (key: string): string =>
  key.replace(/[A-Z]/g, (char) => `_${char.toLowerCase()}`);

function renameKeys(row: Row, rename: (key: string) => string): Row {
  const result: Row = {};
  for (const [key, value] of Object.entries(row)) {
    result[rename(key)] = value;
  }
  return result;
}

/** `{ growth_rate_id: 2 }` → `{ growthRateId: 2 }`; valores e ordem iguais. */
export function snakeToCamelKeys(row: Row): Row {
  return renameKeys(row, toCamel);
}

/** `{ growthRateId: 2 }` → `{ growth_rate_id: 2 }`; valores e ordem iguais. */
export function camelToSnakeKeys(row: Row): Row {
  return renameKeys(row, toSnake);
}
