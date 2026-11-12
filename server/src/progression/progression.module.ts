import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { CodexModule } from '../codex/codex.module.js';
import { ProgressionController } from './progression.controller.js';
import { ProgressionService } from './progression.service.js';
import { ProgressionStore } from './progression.store.js';

@Module({
  imports: [AuthModule, CodexModule],
  controllers: [ProgressionController],
  providers: [
    ProgressionService,
    { provide: ProgressionStore, useFactory: () => new ProgressionStore() },
  ],
  exports: [ProgressionService],
})
export class ProgressionModule {}
