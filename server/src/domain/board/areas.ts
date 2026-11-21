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
export const ANY_TARGET = 'any';
export const NOBODY_THERE = 'Não há Ecobeast nesse hexágono.';
export const TELEPORT_EFFECT = 'teleport';

/** O Teleporte (veilmoth-line/03) leva quem está no alvo para um destino livre. */
export function isTeleport(skill: BattleSkill): boolean {
  return skill.effects.some((effect) => effect.effectSlug === TELEPORT_EFFECT);
}

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
  if (skill.targetSlug === ANY_TARGET)
    return anyArea(state, spot, from, target);
  const distance = hexDistance(from, target);
  if (skill.targetSlug === ALLY_TARGET) {
    return allyArea(state, spot, from, skill, target, distance);
  }
  if (distance === 0 || distance > skill.range) return { error: OUT_OF_RANGE };
  if (skill.areaShape === 'line') {
    return lineArea(state, spot, from, skill, target);
  }
  if (skill.areaShape === 'triangle') {
    return triangleArea(state, spot, from, skill, target);
  }
  return singleArea(state, spot, skill, target);
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

/** Qualquer Ecobeast de pé, de qualquer lado e a qualquer distância; o autor conta em `from`. */
function anyArea(
  state: BoardState,
  spot: Spot,
  from: HexCoord,
  target: HexCoord,
): SkillArea | { error: string } {
  if (sameCell(from, target)) return { cells: [target], foes: [spot] };
  const occupant = spotAt(state, target);
  const isAuthor =
    occupant !== null &&
    occupant.side === spot.side &&
    occupant.position === spot.position;
  return occupant && !isAuthor && standingAt(state, occupant)
    ? { cells: [target], foes: [occupant] }
    : { error: NOBODY_THERE };
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

/** As 6 direções no sentido horário da tela, com o y para baixo (board-battle/33). */
const CLOCKWISE: readonly HexCoord[] = [
  { q: 1, r: 0 },
  { q: 0, r: 1 },
  { q: -1, r: 1 },
  { q: -1, r: 0 },
  { q: 0, r: -1 },
  { q: 1, r: -1 },
];

const plus = (a: HexCoord, b: HexCoord): HexCoord => ({
  q: a.q + b.q,
  r: a.r + b.r,
});

/** Os 2 vizinhos do vértice que fecham o triângulo, longe de quem usa. */
export function trianglePairs(from: HexCoord, vertex: HexCoord): HexCoord[][] {
  const steps = hexDistance(from, vertex);
  const axis = CLOCKWISE.findIndex((dir) =>
    sameCell(plus(from, { q: dir.q * steps, r: dir.r * steps }), vertex),
  );
  if (axis === -1) {
    const far = CLOCKWISE.map((dir) => plus(vertex, dir)).filter(
      (cell) => hexDistance(from, cell) === steps + 1,
    );
    return [far];
  }
  const ahead = plus(vertex, CLOCKWISE[axis]!);
  const turned = (offset: number) =>
    plus(
      vertex,
      CLOCKWISE[(axis + offset + CLOCKWISE.length) % CLOCKWISE.length]!,
    );
  return [
    [ahead, turned(1)],
    [ahead, turned(-1)],
  ];
}

function triangleArea(
  state: BoardState,
  spot: Spot,
  from: HexCoord,
  skill: BattleSkill,
  vertex: HexCoord,
): SkillArea | { error: string } {
  const options = trianglePairs(from, vertex).map((pair) => {
    const cells = [...pair, vertex].filter((cell) => hasCell(state, cell));
    const foes = [vertex, ...pair]
      .filter((cell) => hasCell(state, cell))
      .map((cell) => foeAt(state, spot, cell))
      .filter((foe): foe is Spot => foe !== null);
    return { cells, foes };
  });
  // No empate, fica o primeiro: o que gira no sentido horário.
  const best = options.reduce((chosen, option) =>
    option.foes.length > chosen.foes.length ||
    (option.foes.length === chosen.foes.length &&
      option.cells.length > chosen.cells.length)
      ? option
      : chosen,
  );
  if (best.foes.length === 0 && skill.groundEffectId === null) {
    return { error: NO_ENEMY_THERE };
  }
  return best;
}
