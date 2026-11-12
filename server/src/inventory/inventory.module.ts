import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { BattleModule } from '../battle/battle.module.js';
import { PlayerModule } from '../player/player.module.js';
import { InventoryController } from './inventory.controller.js';
import { InventoryService } from './inventory.service.js';

@Module({
  imports: [AuthModule, BattleModule, PlayerModule],
  controllers: [InventoryController],
  providers: [InventoryService],
})
export class InventoryModule {}
