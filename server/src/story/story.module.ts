import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { StoryController } from './story.controller.js';
import { StoryService } from './story.service.js';

@Module({
  imports: [AuthModule],
  controllers: [StoryController],
  providers: [StoryService],
})
export class StoryModule {}
