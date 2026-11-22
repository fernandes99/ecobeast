import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { ArchipelagoController } from './archipelago.controller.js';
import { ArchipelagoService } from './archipelago.service.js';
import { DiscoveriesService } from './discoveries.service.js';
import { IslandsController } from './islands.controller.js';
import { IslandsService } from './islands.service.js';

@Module({
  imports: [AuthModule],
  controllers: [IslandsController, ArchipelagoController],
  providers: [IslandsService, DiscoveriesService, ArchipelagoService],
  exports: [IslandsService, DiscoveriesService, ArchipelagoService],
})
export class IslandsModule {}
