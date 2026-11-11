import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { IslandsModule } from '../islands/islands.module.js';
import { ExplorationController } from './exploration.controller.js';
import { ExplorationService } from './exploration.service.js';
import { ExplorationStore } from './exploration.store.js';

/** O mapa de exploração do usuário logado. */
@Module({
  imports: [AuthModule, IslandsModule],
  controllers: [ExplorationController],
  providers: [
    ExplorationService,
    { provide: ExplorationStore, useFactory: () => new ExplorationStore() },
  ],
  exports: [ExplorationStore],
})
export class ExplorationModule {}
