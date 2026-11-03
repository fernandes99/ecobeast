import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { ExplorationModule } from '../exploration/exploration.module.js';
import { BattleController } from './battle.controller.js';
import { BattleService } from './battle.service.js';
import { BattleStore } from './battle.store.js';

/** A batalha do usuário logado: começar, agir e gravar o fim. */
@Module({
  imports: [AuthModule, ExplorationModule],
  controllers: [BattleController],
  providers: [
    BattleService,
    { provide: BattleStore, useFactory: () => new BattleStore() },
  ],
  exports: [BattleStore],
})
export class BattleModule {}
