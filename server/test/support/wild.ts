import { INestApplication } from '@nestjs/common';
import type { App } from 'supertest/types.js';
import type { MapTamer } from '../../src/domain/tamers/tamers.js';
import { ExplorationStore } from '../../src/exploration/exploration.store.js';

export const HERE = { q: 0, r: 0 };

export type PlacedTamer = Partial<MapTamer>;

interface WildCreature {
  speciesId?: number;
  level?: number;
  q?: number;
  r?: number;
}

/**
 * Deixa uma exploração pronta, com o Domador em `HERE` e os Ecobeasts e os
 * Domadores NPC dados, sem passar pelo sorteio: assim, o teste sabe quem vem.
 * Por padrão, um Ruvo de nível 5 e nenhum Domador.
 */
export function placeWild(
  app: INestApplication<App>,
  userId: string,
  creatures: WildCreature[] = [{}],
  placedTamers: PlacedTamer[] = [],
): ExplorationStore {
  const store = app.get(ExplorationStore);
  const spawns = creatures.map((creature, index) => ({
    id: index + 1,
    speciesId: 1,
    level: 5,
    ...HERE,
    ...creature,
  }));
  const tamers: MapTamer[] = placedTamers.map((tamer, index) => ({
    id: index + 1,
    nameId: 1,
    greetingId: 1,
    size: 1,
    team: [{ speciesId: 1, level: 5 }],
    ...HERE,
    ...tamer,
  }));
  store.set(userId, {
    spawns: new Map(spawns.map((spawn) => [spawn.id, spawn])),
    tamers: new Map(tamers.map((tamer) => [tamer.id, tamer])),
    position: HERE,
    positionAt: Date.now(),
  });
  return store;
}
