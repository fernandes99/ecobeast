import type { BattleState } from '../battle/types.js';
import {
  COUNTER_IDS,
  counterTotal,
  mergeIncrements,
  type CounterIncrement,
} from './counters.js';

export interface BattleCounterInput {
  dayPhaseId: number;
  /** Os itens com `captureBonus`. */
  sphereItemIds: Set<number>;
}

/** Os contadores que o fim de uma luta sobe (player-stats/01, RF-02 a RF-05). */
export function battleCounters(
  state: BattleState,
  { dayPhaseId, sphereItemIds }: BattleCounterInput,
): CounterIncrement[] {
  const list: CounterIncrement[] = [];
  if (state.result === 'victory') {
    list.push(
      counterTotal(state.opponent === 'tamer' ? 'wins_tamer' : 'wins_wild', 1),
    );
  } else if (state.result === 'defeat') {
    list.push(counterTotal('defeats', 1));
  }

  const spheres = state.bag
    .filter(({ itemId }) => sphereItemIds.has(itemId))
    .reduce((sum, { used }) => sum + used, 0);
  list.push(counterTotal('spheres_used', spheres));

  const captured = state.enemy.team.filter((creature) => creature.captured);
  if (captured.length > 0) {
    list.push(counterTotal('captures', captured.length));
    if (spheres === 1) list.push(counterTotal('captures_first_sphere', 1));
    for (const creature of captured) {
      for (const elementId of creature.elementIds) {
        list.push({
          counterId: COUNTER_IDS.captures_by_element,
          subjectId: elementId,
          amount: 1,
        });
      }
      list.push({
        counterId: COUNTER_IDS.captures_by_day_phase,
        subjectId: dayPhaseId,
        amount: 1,
      });
    }
  }

  const xp = state.player.team.reduce((sum, { xpEarned }) => sum + xpEarned, 0);
  list.push(counterTotal('xp_gained', xp));
  list.push(counterTotal('coins_earned', Math.max(0, state.coinsChange)));
  return mergeIncrements(list);
}

/** Os índices da equipe que lutaram, pelo critério da divisão de XP. */
export function foughtCreatureIndices(state: BattleState): number[] {
  const indices = new Set(state.enemy.team.flatMap(({ foughtBy }) => foughtBy));
  return [...indices].sort((a, b) => a - b);
}
