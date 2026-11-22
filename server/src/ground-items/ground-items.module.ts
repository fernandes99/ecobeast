import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { ExplorationStoreModule } from '../exploration/exploration-store.module.js';
import { GroundItemsController } from './ground-items.controller.js';
import { GroundItemsService } from './ground-items.service.js';

@Module({
  imports: [AuthModule, ExplorationStoreModule],
  controllers: [GroundItemsController],
  providers: [GroundItemsService],
  exports: [GroundItemsService],
})
export class GroundItemsModule {}
