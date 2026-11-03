import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { ProgressionController } from './progression.controller.js';
import { ProgressionService } from './progression.service.js';
import { ProgressionStore } from './progression.store.js';

/** Técnicas novas, evolução e as escolhas do jogador depois da vitória. */
@Module({
  imports: [AuthModule],
  controllers: [ProgressionController],
  providers: [
    ProgressionService,
    { provide: ProgressionStore, useFactory: () => new ProgressionStore() },
  ],
  exports: [ProgressionService],
})
export class ProgressionModule {}
