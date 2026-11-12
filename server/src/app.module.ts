import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AuthModule } from './auth/auth.module.js';
import { BattleModule } from './battle/battle.module.js';
import { BoardBattleModule } from './board-battle/board-battle.module.js';
import { BundleModule } from './catalog/bundle/bundle.module.js';
import { CatalogModule } from './catalog/catalog.module.js';
import { CodexModule } from './codex/codex.module.js';
import { Env, validateEnv } from './config/env.js';
import { EditorModule } from './editor/editor.module.js';
import { ExplorationModule } from './exploration/exploration.module.js';
import { IslandsModule } from './islands/islands.module.js';
import { HealthModule } from './health/health.module.js';
import { InventoryModule } from './inventory/inventory.module.js';
import { PlayerModule } from './player/player.module.js';
import { PrismaModule } from './prisma/prisma.module.js';
import { ProgressionModule } from './progression/progression.module.js';
import { TeamModule } from './team/team.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, validate: validateEnv }),
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
    PlayerModule,
    BattleModule,
    BoardBattleModule,
    ExplorationModule,
    InventoryModule,
    TeamModule,
    ProgressionModule,
    CodexModule,
    EditorModule,
    IslandsModule,
  ],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
