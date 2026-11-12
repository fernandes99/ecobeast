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
  if (distance === 0 || distance > skill.range) return { error: OUT_OF_RANGE };
  return skill.areaShape === 'line'
    ? lineArea(state, spot, from, skill, target)
    : singleArea(state, spot, skill, target);
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
