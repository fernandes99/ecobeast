import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { CodexModule } from '../codex/codex.module.js';
import { ExplorationModule } from '../exploration/exploration.module.js';
import { ProgressionModule } from '../progression/progression.module.js';
import { BattleRecordsService } from './battle-records.service.js';
import { BattleStore } from './battle.store.js';

/** A batalha do usuário logado: começar, agir e gravar o fim. */
@Module({
  imports: [AuthModule, CodexModule, ExplorationModule, ProgressionModule],
  providers: [
    BattleRecordsService,
    { provide: BattleStore, useFactory: () => new BattleStore() },
  ],
  exports: [BattleStore, BattleRecordsService],
})
export class BattleModule {}
