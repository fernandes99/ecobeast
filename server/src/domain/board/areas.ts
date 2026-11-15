import { opponentOf } from '../battle/field.js';
import type { BattleSkill, Spot } from '../battle/types.js';
import {
  HEX_DIRECTIONS,
  type HexCoord,
  hexDistance,
} from '../exploration/hex.js';
import { hasCell, sameCell, spotAt, standingAt } from './board.js';
import type { BoardState } from './types.js';

export const OUT_OF_RANGE = 'Esse hexágono está fora do alcance.';
export const NO_ENEMY_THERE = 'Não há inimigo nesse hexágono.';
export const STRAIGHT_LINE = 'A linha só anda em linha reta.';
export const ALLY_ONLY = 'Não há Ecobeast do seu time nesse hexágono.';
export const ALLY_TARGET = 'ally';

export interface SkillArea {
  cells: HexCoord[];
  foes: Spot[];
}

export function areaOf(
  state: BoardState,
  spot: Spot,
  from: HexCoord,
  skill: BattleSkill,
  target: HexCoord | undefined,
): SkillArea | { error: string } {
  if (skill.targetSlug === 'self') return { cells: [], foes: [] };
  if (!target || !hasCell(state, target)) return { error: OUT_OF_RANGE };
  const distance = hexDistance(from, target);
  if (skill.targetSlug === ALLY_TARGET) {
    return allyArea(state, spot, from, skill, target, distance);
  }
  if (distance === 0 || distance > skill.range) return { error: OUT_OF_RANGE };
  return skill.areaShape === 'line'
    ? lineArea(state, spot, from, skill, target)
    : singleArea(state, spot, skill, target);
}

/** O autor conta em `from`, para onde andou nesta vez, e não onde estava. */
function allyArea(
  state: BoardState,
  spot: Spot,
  from: HexCoord,
  skill: BattleSkill,
  target: HexCoord,
  distance: number,
): SkillArea | { error: string } {
  if (distance > skill.range) return { error: OUT_OF_RANGE };
  if (distance === 0) return { cells: [target], foes: [spot] };
  const occupant = spotAt(state, target);
  const isAlly =
    occupant !== null &&
    occupant.side === spot.side &&
    occupant.position !== spot.position &&
    standingAt(state, occupant);
  return isAlly ? { cells: [target], foes: [occupant] } : { error: ALLY_ONLY };
}

function foeAt(state: BoardState, spot: Spot, cell: HexCoord): Spot | null {
  const occupant = spotAt(state, cell);
  return occupant &&
    occupant.side === opponentOf(spot.side) &&
    standingAt(state, occupant)
    ? occupant
    : null;
}

function singleArea(
  state: BoardState,
  spot: Spot,
  skill: BattleSkill,
  target: HexCoord,
): SkillArea | { error: string } {
  const foe = foeAt(state, spot, target);
  if (!foe && skill.groundEffectId === null) return { error: NO_ENEMY_THERE };
  return { cells: [target], foes: foe ? [foe] : [] };
}

function lineArea(
  state: BoardState,
  spot: Spot,
  from: HexCoord,
  skill: BattleSkill,
  target: HexCoord,
): SkillArea | { error: string } {
  const steps = hexDistance(from, target);
  const direction = HEX_DIRECTIONS.find((dir) =>
    sameCell({ q: from.q + dir.q * steps, r: from.r + dir.r * steps }, target),
  );
  if (!direction) return { error: STRAIGHT_LINE };

  const cells: HexCoord[] = [];
  const foes: Spot[] = [];
  for (let step = 1; step <= skill.range; step++) {
    const cell = {
      q: from.q + direction.q * step,
      r: from.r + direction.r * step,
    };
    if (!hasCell(state, cell)) break;
    cells.push(cell);
    const foe = foeAt(state, spot, cell);
    if (!foe) continue;
    foes.push(foe);
    if (!skill.pierces) break;
  }
  return { cells, foes };
}
