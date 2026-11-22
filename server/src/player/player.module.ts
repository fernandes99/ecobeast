import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { CountersModule } from '../counters/counters.module.js';
import { CodexModule } from '../codex/codex.module.js';
import { BattleModule } from '../battle/battle.module.js';
import { PlayerController } from './player.controller.js';
import { PlayerService } from './player.service.js';
import { TamerLevelModule } from '../tamer-level/tamer-level.module.js';

@Module({
  imports: [
    AuthModule,
    CodexModule,
    BattleModule,
    CountersModule,
    TamerLevelModule,
  ],
  controllers: [PlayerController],
  providers: [PlayerService],
  exports: [PlayerService],
})
export class PlayerModule {}
