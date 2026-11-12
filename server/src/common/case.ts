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

export function snakeToCamelKeys(row: Row): Row {
  return renameKeys(row, toCamel);
}

export function camelToSnakeKeys(row: Row): Row {
  return renameKeys(row, toSnake);
}
