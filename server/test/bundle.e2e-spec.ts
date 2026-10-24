import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import {
  CATALOG_TABLES,
  SEED_DATA_DIR,
} from '../src/catalog/catalog-tables.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';

// Catálogo inteiro (.specs/backend-api/06-catalog-bundle.md). Confere o formato
// contra os JSON de SEED_DATA_DIR, não os valores: o dono pode mudá-los no banco.

type Row = Record<string, unknown>;

interface CountDelegate {
  count(): Promise<number>;
}

const readJson = (name: string): Row[] =>
  JSON.parse(
    readFileSync(join(SEED_DATA_DIR, `${name}.json`), 'utf8'),
  ) as Row[];

describe('GET /v1/catalog (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let body: { version: string; tables: Record<string, Row[]> };
  let etag: string | undefined;

  beforeAll(async () => {
    app = await createTestApp();
    prisma = createTestPrisma();
    const response = await request(app.getHttpServer())
      .get('/v1/catalog')
      .expect(200);
    body = response.body;
    etag = response.headers['etag'];
  });

  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  it('devolve version e as 23 tabelas', () => {
    expect(Object.keys(body)).toEqual(['version', 'tables']);
    expect(body.version).toMatch(/^[0-9a-f]{64}$/);
    expect(Object.keys(body.tables).sort()).toEqual(
      CATALOG_TABLES.map((t) => t.name).sort(),
    );
  });

  it('o total de linhas é a soma do count() das 23 tabelas', async () => {
    let total = 0;
    for (const table of CATALOG_TABLES) {
      const count = await (prisma as unknown as Record<string, CountDelegate>)[
        table.model
      ].count();
      expect(body.tables[table.name], table.name).toHaveLength(count);
      total += count;
    }
    const rows = Object.values(body.tables).reduce((n, t) => n + t.length, 0);
    expect(rows).toBe(total);
  });

  it.each(CATALOG_TABLES.map((t) => t.name))(
    '%s tem as colunas do JSON, na mesma ordem',
    (name) => {
      const columns = Object.keys(readJson(name)[0]);
      for (const row of body.tables[name]) {
        expect(Object.keys(row)).toEqual(columns);
      }
    },
  );

  it.each(CATALOG_TABLES.map((t) => [t.name, t.key] as const))(
    '%s vem em ordem crescente da chave',
    (name, key) => {
      const keyOf = (row: Row) => key.map((column) => row[column] as number);
      const rows = body.tables[name];
      for (let i = 1; i < rows.length; i++) {
        const [a, b] = [keyOf(rows[i - 1]), keyOf(rows[i])];
        const diff = a.map((v, j) => v - b[j]).find((d) => d !== 0) ?? 0;
        expect(diff, `${name} linha ${i}`).toBeLessThan(0);
      }
    },
  );

  it('números e null chegam sem transformação', () => {
    const fagulho = body.tables['species'].find((s) => s['id'] === 1)!;
    expect(typeof fagulho['gender_ratio']).toBe('number');
    expect(fagulho['evolves_from_species_id']).toBeNull();
  });

  it('o ETag é a versão entre aspas', () => {
    expect(etag).toBe(`"${body.version}"`);
  });

  it('If-None-Match igual ao ETag devolve 304 sem corpo', async () => {
    const response = await request(app.getHttpServer())
      .get('/v1/catalog')
      .set('If-None-Match', etag!)
      .expect(304);
    expect(response.text ?? '').toBe('');
  });

  it('If-None-Match de outra versão devolve 200 com o catálogo', async () => {
    const response = await request(app.getHttpServer())
      .get('/v1/catalog')
      .set('If-None-Match', '"outra"')
      .expect(200);
    expect(response.body.version).toBe(body.version);
  });

  it('a rota aparece no OpenAPI na tag Catálogo', async () => {
    const { body: doc } = await request(app.getHttpServer())
      .get('/docs/openapi.json')
      .expect(200);
    const route = doc.paths['/v1/catalog']?.get;
    expect(route?.tags).toEqual(['Catálogo']);
    expect(route?.description).toContain('If-None-Match');
    expect(route?.responses?.['304']).toBeDefined();
  });
});
