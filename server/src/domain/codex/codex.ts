import type { BattleEvent } from '../battle/types.js';

/**
 * Regras do Bestiário (.specs/codex/architecture.md): o que uma resposta da
 * luta deixa o jogador ver.
 */

/** Os ids sem repetição, na ordem da primeira vez de cada um. */
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
