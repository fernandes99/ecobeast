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
  /** Troca o PrismaService (ex.: um banco que falha). */
  prisma?: Partial<PrismaService>;
  /** Sobrescreve variáveis do config (ex.: THROTTLE_LIMIT baixo). */
  env?: Partial<Env>;
  /** Troca o cliente do Supabase Auth (os e2e nunca falam com o de verdade). */
  supabaseAuth?: Partial<SupabaseAuthClient>;
  /** Troca o verificador de tokens (ex.: o de test/support/tokens.ts). */
  tokenVerifier?: TokenVerifier;
}

/**
 * Sobe a aplicação como o main.ts (prefixo e docs). Os e2e rodam com
 * THROTTLE_LIMIT alto (vitest.config.e2e.ts), menos o teste do próprio limite.
 */
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
