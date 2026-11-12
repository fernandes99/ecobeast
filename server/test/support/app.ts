import { INestApplication } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import type { App } from 'supertest/types.js';
import { AppModule } from '../../src/app.module.js';
import { configureApp } from '../../src/app.setup.js';
import { SupabaseAuthClient } from '../../src/auth/supabase-auth.client.js';
import { TokenVerifier } from '../../src/auth/token-verifier.js';
import { Env, validateEnv } from '../../src/config/env.js';
import { PrismaService } from '../../src/prisma/prisma.service.js';

export interface TestAppOptions {
  prisma?: Partial<PrismaService>;
  env?: Partial<Env>;
  supabaseAuth?: Partial<SupabaseAuthClient>;
  tokenVerifier?: TokenVerifier;
}

export async function createTestApp(
  options: TestAppOptions = {},
): Promise<INestApplication<App>> {
  let builder = Test.createTestingModule({ imports: [AppModule] });
  if (options.prisma) {
    builder = builder.overrideProvider(PrismaService).useValue(options.prisma);
  }
  if (options.supabaseAuth) {
    builder = builder
      .overrideProvider(SupabaseAuthClient)
      .useValue(options.supabaseAuth);
  }
  if (options.tokenVerifier) {
    builder = builder
      .overrideProvider(TokenVerifier)
      .useValue(options.tokenVerifier);
  }
  if (options.env) {
    const env = { ...validateEnv(process.env), ...options.env };
    builder = builder
      .overrideProvider(ConfigService)
      .useValue({ get: (key: keyof Env) => env[key] });
  }
  const app = (await builder.compile()).createNestApplication<
    INestApplication<App>
  >();
  configureApp(app);
  await app.init();
  return app;
}
