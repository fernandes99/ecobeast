import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { PlayerModule } from '../player/player.module.js';
import { InventoryController } from './inventory.controller.js';
import { InventoryService } from './inventory.service.js';

/** A Loja e a Mochila do usuário logado. */
@Module({
  imports: [AuthModule, PlayerModule],
  controllers: [InventoryController],
  providers: [InventoryService],
})
export class InventoryModule {}
