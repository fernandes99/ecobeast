import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { AppModule } from '../src/app.module.js';
import { configureApp } from '../src/app.setup.js';
import { PrismaService } from '../src/prisma/prisma.service.js';

async function createApp(
  prisma?: Partial<PrismaService>,
): Promise<INestApplication<App>> {
  let builder = Test.createTestingModule({ imports: [AppModule] });
  if (prisma) {
    builder = builder.overrideProvider(PrismaService).useValue(prisma);
  }
  const app = (await builder.compile()).createNestApplication<
    INestApplication<App>
  >();
  configureApp(app);
  await app.init();
  return app;
}

describe('saúde e documentação (e2e)', () => {
  let app: INestApplication<App>;

  beforeAll(async () => {
    app = await createApp();
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /health responde 200 com o banco ok', async () => {
    const response = await request(app.getHttpServer())
      .get('/health')
      .expect(200);
    expect(response.body).toEqual({ status: 'ok', database: 'ok' });
  });

  it('GET /v1/health não existe (health fica fora do prefixo)', async () => {
    await request(app.getHttpServer()).get('/v1/health').expect(404);
  });

  it('GET /docs/openapi.json traz o título da API', async () => {
    const response = await request(app.getHttpServer())
      .get('/docs/openapi.json')
      .expect(200);
    expect(response.body.info.title).toBe('Ecobeast API');
    expect(response.body.info.version).toBe('1');
  });

  it('GET /docs abre a página da Scalar', async () => {
    const response = await request(app.getHttpServer())
      .get('/docs')
      .expect(200);
    expect(response.headers['content-type']).toMatch(/text\/html/);
  });
});

describe('saúde com o banco fora do ar (e2e)', () => {
  let app: INestApplication<App>;

  beforeAll(async () => {
    const failing: Partial<PrismaService> = {
      $queryRaw: (() => Promise.reject(new Error('sem conexão'))) as never,
      $connect: () => Promise.resolve(),
      $disconnect: () => Promise.resolve(),
    };
    app = await createApp(failing);
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /health responde 503 e o servidor continua no ar', async () => {
    const response = await request(app.getHttpServer())
      .get('/health')
      .expect(503);
    expect(response.body).toEqual({ status: 'error', database: 'error' });
    await request(app.getHttpServer()).get('/docs/openapi.json').expect(200);
  });
});
