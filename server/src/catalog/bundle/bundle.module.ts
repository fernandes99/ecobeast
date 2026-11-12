import { Module } from '@nestjs/common';
import { BundleController } from './bundle.controller.js';
import { BundleService } from './bundle.service.js';

@Module({
  controllers: [BundleController],
  providers: [BundleService],
})
export class BundleModule {}
