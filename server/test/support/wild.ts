import { INestApplication } from '@nestjs/common';
import type { App } from 'supertest/types.js';
import { ExplorationStore } from '../../src/exploration/exploration.store.js';

/** Onde os testes deixam o Domador e o Ecobeast. */
export const HERE = { q: 0, r: 0 };

interface WildCreature {
  speciesId?: number;
  level?: number;
  q?: number;
  r?: number;
}

/**
 * Deixa uma exploração pronta, com o Domador em `HERE` e os Ecobeasts dados, sem
 * passar pelo sorteio: assim, o teste sabe quem vem. Por padrão, um Ruvo de nível 5.
 */
export function placeWild(
  app: INestApplication<App>,
  userId: string,
  creatures: WildCreature[] = [{}],
): ExplorationStore {
  const store = app.get(ExplorationStore);
  const spawns = creatures.map((creature, index) => ({
    id: index + 1,
    speciesId: 1,
    level: 5,
    ...HERE,
    ...creature,
  }));
  store.set(userId, {
    spawns: new Map(spawns.map((spawn) => [spawn.id, spawn])),
    position: HERE,
    positionAt: Date.now(),
  });
  return store;
}
