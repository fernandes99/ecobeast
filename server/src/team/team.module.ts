import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { BattleModule } from '../battle/battle.module.js';
import { PlayerModule } from '../player/player.module.js';
import { TeamController } from './team.controller.js';
import { TeamService } from './team.service.js';

/** A equipe e o Santuário do usuário logado. */
@Module({
  imports: [AuthModule, BattleModule, PlayerModule],
  controllers: [TeamController],
  providers: [TeamService],
})
export class TeamModule {}
