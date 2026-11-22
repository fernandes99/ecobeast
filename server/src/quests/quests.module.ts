import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { ExplorationStoreModule } from '../exploration/exploration-store.module.js';
import { IslandsModule } from '../islands/islands.module.js';
import { TamerLevelModule } from '../tamer-level/tamer-level.module.js';
import { QuestsController } from './quests.controller.js';
import { QuestsService } from './quests.service.js';

@Module({
  imports: [
    AuthModule,
    ExplorationStoreModule,
    IslandsModule,
    TamerLevelModule,
  ],
  controllers: [QuestsController],
  providers: [QuestsService],
  exports: [QuestsService],
})
export class QuestsModule {}
