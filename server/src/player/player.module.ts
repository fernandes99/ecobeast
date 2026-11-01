import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { BattleModule } from '../battle/battle.module.js';
import { PlayerController } from './player.controller.js';
import { PlayerService } from './player.service.js';

/** O Domador do usuário logado: ler, criar, curar e apagar. */
@Module({
  imports: [AuthModule, BattleModule],
  controllers: [PlayerController],
  providers: [PlayerService],
  exports: [PlayerService],
})
export class PlayerModule {}
