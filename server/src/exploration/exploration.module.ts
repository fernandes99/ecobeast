import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { ExplorationController } from './exploration.controller.js';
import { ExplorationService } from './exploration.service.js';

/** O mapa de exploração do usuário logado. */
@Module({
  imports: [AuthModule],
  controllers: [ExplorationController],
  providers: [ExplorationService],
})
export class ExplorationModule {}
