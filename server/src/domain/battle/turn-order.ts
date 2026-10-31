import { effectiveStat } from './stages.js';
import type { Combatant, Random } from './types.js';

export interface TurnAction {
  priority: number;
  combatant: Combatant;
}

/** Maior prioridade, depois maior Velocidade; um empate total é sorteado. */
export function orderActions<Action extends TurnAction>(
  first: Action,
  second: Action,
  random: Random,
): [Action, Action] {
  const difference =
    second.priority - first.priority ||
    effectiveStat(second.combatant, 'spd') -
      effectiveStat(first.combatant, 'spd');
  const firstGoesFirst = difference === 0 ? random() < 0.5 : difference < 0;
  return firstGoesFirst ? [first, second] : [second, first];
}
