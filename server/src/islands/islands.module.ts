import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { DiscoveriesService } from './discoveries.service.js';
import { IslandsController } from './islands.controller.js';
import { IslandsService } from './islands.service.js';

@Module({
  imports: [AuthModule],
  controllers: [IslandsController],
  providers: [IslandsService, DiscoveriesService],
  exports: [IslandsService, DiscoveriesService],
})
export class IslandsModule {}
