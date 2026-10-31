import type { BattleState, Combatant, Random, SideSlug } from './types.js';

export function opponentOf(side: SideSlug): SideSlug {
  return side === 'player' ? 'enemy' : 'player';
}

export function activeOf(state: BattleState, side: SideSlug): Combatant {
  const { team, activeIndex } = state[side];
  return team[activeIndex]!;
}

export function hasCreatureStanding(
  state: BattleState,
  side: SideSlug,
): boolean {
  return state[side].team.some((creature) => creature.currentHp > 0);
}

/** Uma chance de 0 a 1; as certas não gastam sorteio. */
export function rollChance(chance: number, random: Random): boolean {
  if (chance >= 1) return true;
  if (chance <= 0) return false;
  return random() < chance;
}
