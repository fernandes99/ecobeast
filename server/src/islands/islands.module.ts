import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { ArchipelagoController } from './archipelago.controller.js';
import { ArchipelagoService } from './archipelago.service.js';
import { DiscoveriesService } from './discoveries.service.js';
import { IslandCompletionService } from './island-completion.service.js';
import { IslandTamersService } from './island-tamers.service.js';
import { IslandsController } from './islands.controller.js';
import { IslandsService } from './islands.service.js';

@Module({
  imports: [AuthModule],
  controllers: [IslandsController, ArchipelagoController],
  providers: [
    IslandsService,
    DiscoveriesService,
    ArchipelagoService,
    IslandTamersService,
    IslandCompletionService,
  ],
  exports: [
    IslandsService,
    DiscoveriesService,
    ArchipelagoService,
    IslandTamersService,
    IslandCompletionService,
  ],
})
export class IslandsModule {}
