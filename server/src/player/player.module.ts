import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { PlayerController } from './player.controller.js';
import { PlayerService } from './player.service.js';

/** O Domador do usuário logado: ler, criar, escolher o inicial e apagar. */
@Module({
  imports: [AuthModule],
  controllers: [PlayerController],
  providers: [PlayerService],
})
export class PlayerModule {}
