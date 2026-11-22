import { Module } from '@nestjs/common';
import { ExplorationStore } from './exploration.store.js';

/** O guarda das explorações num módulo só dele: os contadores o leem sem depender de Explorar, que depende deles. */
@Module({
  providers: [
    { provide: ExplorationStore, useFactory: () => new ExplorationStore() },
  ],
  exports: [ExplorationStore],
})
export class ExplorationStoreModule {}
