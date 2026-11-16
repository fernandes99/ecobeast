import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { AppModule } from '../src/app.module.js';
import { configureApp } from '../src/app.setup.js';
import { minuteOfDay } from '../src/domain/world-clock/world-clock.js';

describe('relógio do mundo (e2e)', () => {
  let app: INestApplication<App>;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication<INestApplication<App>>();
    configureApp(app);
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /v1/world-clock responde sem login com o minuto do dia', async () => {
    const before = minuteOfDay(Date.now());
    const response = await request(app.getHttpServer())
      .get('/v1/world-clock')
      .expect(200);
    const after = minuteOfDay(Date.now());
    expect(Object.keys(response.body)).toEqual(['minute_of_day']);
    const minute = response.body.minute_of_day as number;
    expect(minute).toBeGreaterThanOrEqual(0);
    expect(minute).toBeLessThan(1440);
    if (after >= before) {
      expect(minute).toBeGreaterThanOrEqual(before);
      expect(minute).toBeLessThanOrEqual(after);
    }
  });

  it('a rota está na documentação', async () => {
    const response = await request(app.getHttpServer())
      .get('/docs/openapi.json')
      .expect(200);
    expect(response.body.paths['/v1/world-clock']).toBeDefined();
  });
});
