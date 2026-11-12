import type {
  BattleState,
  Combatant,
  Random,
  SideSlug,
  Spot,
} from './types.js';

export const MAX_SLOTS = 3;

export function opponentOf(side: SideSlug): SideSlug {
  return side === 'player' ? 'enemy' : 'player';
}

export function activeAt(state: BattleState, spot: Spot): Combatant | null {
  const index = state[spot.side].activeIndices[spot.position];
  return index === null || index === undefined
    ? null
    : state[spot.side].team[index]!;
}

export function combatantAt(state: BattleState, spot: Spot): Combatant {
  return activeAt(state, spot)!;
}

export function isStanding(creature: Combatant): boolean {
  return creature.currentHp > 0 && !creature.captured;
}

export function occupiedSpots(state: BattleState, side: SideSlug): Spot[] {
  return state[side].activeIndices.flatMap((index, position) =>
    index === null ? [] : [{ side, position }],
  );
}

export function standingSpots(state: BattleState, side: SideSlug): Spot[] {
  return occupiedSpots(state, side).filter((spot) =>
    isStanding(combatantAt(state, spot)),
  );
}

export function hasCreatureStanding(
  state: BattleState,
  side: SideSlug,
): boolean {
  return state[side].team.some(isStanding);
}

export function reserveIndices(state: BattleState, side: SideSlug): number[] {
  const { team, activeIndices } = state[side];
  return team.flatMap((creature, index) =>
    isStanding(creature) && !activeIndices.includes(index) ? [index] : [],
  );
}

/** Uma chance de 0 a 1; as certas não gastam sorteio. */
export function rollChance(chance: number, random: Random): boolean {
  if (chance >= 1) return true;
  if (chance <= 0) return false;
  return random() < chance;
}
