import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { IslandsController } from './islands.controller.js';
import { IslandsService } from './islands.service.js';

/** As ilhas publicadas: a lista do jogador e a leitura que o editor e a exploração usam. */
@Module({
  imports: [AuthModule],
  controllers: [IslandsController],
  providers: [IslandsService],
  exports: [IslandsService],
})
export class IslandsModule {}
