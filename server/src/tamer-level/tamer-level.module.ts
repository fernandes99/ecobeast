import { Module } from '@nestjs/common';
import { TamerLevelService } from './tamer-level.service.js';

@Module({
  providers: [TamerLevelService],
  exports: [TamerLevelService],
})
export class TamerLevelModule {}
