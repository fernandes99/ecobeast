import { Module } from '@nestjs/common';
import { BundleController } from './bundle.controller.js';
import { BundleService } from './bundle.service.js';

/** GET /v1/catalog: o catálogo inteiro (backend-api/06). */
@Module({
  controllers: [BundleController],
  providers: [BundleService],
})
export class BundleModule {}
