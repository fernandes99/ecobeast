import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { CodexController } from './codex.controller.js';
import { CodexService } from './codex.service.js';

@Module({
  imports: [AuthModule],
  controllers: [CodexController],
  providers: [CodexService],
  exports: [CodexService],
})
export class CodexModule {}
