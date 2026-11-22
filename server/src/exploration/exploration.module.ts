import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { CountersModule } from '../counters/counters.module.js';
import { IslandsModule } from '../islands/islands.module.js';
import { ExplorationController } from './exploration.controller.js';
import { ExplorationService } from './exploration.service.js';
import { ExplorationStoreModule } from './exploration-store.module.js';

@Module({
  imports: [AuthModule, IslandsModule, CountersModule, ExplorationStoreModule],
  controllers: [ExplorationController],
  providers: [ExplorationService],
  exports: [ExplorationStoreModule],
})
export class ExplorationModule {}
