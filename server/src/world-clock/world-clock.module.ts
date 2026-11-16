import { Module } from '@nestjs/common';
import { WorldClockController } from './world-clock.controller.js';

@Module({
  controllers: [WorldClockController],
})
export class WorldClockModule {}
