import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AuthModule } from './auth/auth.module.js';
import { BundleModule } from './catalog/bundle/bundle.module.js';
import { CatalogModule } from './catalog/catalog.module.js';
import { Env, validateEnv } from './config/env.js';
import { HealthModule } from './health/health.module.js';
import { PrismaModule } from './prisma/prisma.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, validate: validateEnv }),
    // THROTTLE_LIMIT chamadas por IP a cada 60 s; acima disso, 429.
    ThrottlerModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>) => ({
        throttlers: [
          { ttl: 60_000, limit: config.get('THROTTLE_LIMIT', { infer: true }) },
        ],
      }),
    }),
    PrismaModule,
    HealthModule,
    CatalogModule,
    BundleModule,
    AuthModule,
  ],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
