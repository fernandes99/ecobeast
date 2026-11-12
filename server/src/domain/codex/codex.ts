import type { BattleEvent } from '../battle/types.js';

export function uniqueIds(ids: readonly number[]): number[] {
  return [...new Set(ids)];
}

/**
 * As espécies inimigas que entraram em campo nestes eventos: é o que conta
 * como visto. Passear no mapa, ou ficar na reserva, não conta.
 */
export function enemySpeciesEntered(events: readonly BattleEvent[]): number[] {
  return uniqueIds(
    events.flatMap((event) =>
      event.type === 'creature_entered' && event.side === 'enemy'
        ? [event.species_id]
        : [],
    ),
  );
}
