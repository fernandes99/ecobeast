import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { CodexController } from './codex.controller.js';
import { CodexService } from './codex.service.js';

/** O Bestiário do usuário logado: ler, e os registros que as lutas, a Evolução e o inicial gravam. */
@Module({
  imports: [AuthModule],
  controllers: [CodexController],
  providers: [CodexService],
  exports: [CodexService],
})
export class CodexModule {}
