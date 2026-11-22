import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { ExplorationStoreModule } from '../exploration/exploration-store.module.js';
import { CountersController } from './counters.controller.js';
import { CountersService } from './counters.service.js';

@Module({
  imports: [AuthModule, ExplorationStoreModule],
  controllers: [CountersController],
  providers: [CountersService],
  exports: [CountersService],
})
export class CountersModule {}
