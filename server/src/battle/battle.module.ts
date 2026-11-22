import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { CodexModule } from '../codex/codex.module.js';
import { CountersModule } from '../counters/counters.module.js';
import { ExplorationModule } from '../exploration/exploration.module.js';
import { ProgressionModule } from '../progression/progression.module.js';
import { TamerLevelModule } from '../tamer-level/tamer-level.module.js';
import { BattleRecordsService } from './battle-records.service.js';
import { BattleStore } from './battle.store.js';

@Module({
  imports: [
    AuthModule,
    CodexModule,
    CountersModule,
    ExplorationModule,
    ProgressionModule,
    TamerLevelModule,
  ],
  providers: [
    BattleRecordsService,
    { provide: BattleStore, useFactory: () => new BattleStore() },
  ],
  exports: [BattleStore, BattleRecordsService],
})
export class BattleModule {}
