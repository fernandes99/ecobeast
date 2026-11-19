import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { InteriorsController } from './interiors.controller.js';
import { InteriorsService } from './interiors.service.js';

@Module({
  imports: [AuthModule],
  controllers: [InteriorsController],
  providers: [InteriorsService],
  exports: [InteriorsService],
})
export class InteriorsModule {}
