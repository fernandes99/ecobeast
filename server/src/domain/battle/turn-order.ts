import { effectiveStat } from './stages.js';
import type { Combatant, Random } from './types.js';

export interface TurnAction {
  priority: number;
  combatant: Combatant;
}

export function orderActions<Action extends TurnAction>(
  first: Action,
  second: Action,
  random: Random,
): [Action, Action] {
  const difference = compare(first, second);
  const firstGoesFirst = difference === 0 ? random() < 0.5 : difference < 0;
  return firstGoesFirst ? [first, second] : [second, first];
}

export function orderTurn<Action extends TurnAction>(
  actions: Action[],
  random: Random,
): Action[] {
  if (actions.length === 2)
    return orderActions(actions[0]!, actions[1]!, random);
  const sorted = [...actions].sort(compare);
  const ordered: Action[] = [];
  while (sorted.length > 0) {
    const tied = sorted.filter((action) => compare(action, sorted[0]!) === 0);
    const pick = tied.length > 1 ? Math.floor(random() * tied.length) : 0;
    const chosen = tied[pick]!;
    ordered.push(chosen);
    sorted.splice(sorted.indexOf(chosen), 1);
  }
  return ordered;
}

/** Negativo quando `a` age antes de `b`. */
function compare(a: TurnAction, b: TurnAction): number {
  return (
    b.priority - a.priority ||
    effectiveStat(b.combatant, 'spd') - effectiveStat(a.combatant, 'spd')
  );
}
