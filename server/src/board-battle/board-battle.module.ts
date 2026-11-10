import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { CodexModule } from '../codex/codex.module.js';
import { BattleModule } from '../battle/battle.module.js';
import { BoardBattleController } from './board-battle.controller.js';
import { BoardBattleService } from './board-battle.service.js';

/** A luta no tabuleiro do usuário logado: começar, jogar a vez e gravar o fim. */
@Module({
  imports: [AuthModule, CodexModule, BattleModule],
  controllers: [BoardBattleController],
  providers: [BoardBattleService],
})
export class BoardBattleModule {}
