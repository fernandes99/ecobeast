import { combatantAt } from '../battle/field.js';
import { applyStatus, faintIfDown } from '../battle/status.js';
import type { Spot } from '../battle/types.js';
import type { HexCoord } from '../exploration/hex.js';
import { cellOf, sameCell, standingOnBoard } from './board.js';
import type { BoardContext, BoardState, GroundMark } from './types.js';

export function markAt(
  state: BoardState,
  cell: HexCoord,
): GroundMark | undefined {
  return state.marks.find((mark) => sameCell(mark.cell, cell));
}

export function placeMarks(
  context: BoardContext,
  cells: HexCoord[],
  groundEffectId: number,
  turns: number,
): void {
  const { state, events } = context;
  for (const cell of cells) {
    state.marks = state.marks.filter((mark) => !sameCell(mark.cell, cell));
    state.marks.push({ cell, groundEffectId, remaining: turns });
    events.push({
      type: 'mark_placed',
      cell,
      ground_effect_id: groundEffectId,
      remaining: turns,
    });
  }
}

/**
 * Depois de cada vez: a marca age em quem está de pé nela, dos dois lados,
 * primeiro o jogador, em ordem de vaga.
 */
export function applyMarks(context: BoardContext): void {
  const { state } = context;
  const spots = [
    ...standingOnBoard(state, 'player'),
    ...standingOnBoard(state, 'enemy'),
  ];
  for (const spot of spots) {
    const mark = markAt(state, cellOf(state, spot)!);
    if (mark) applyMark(context, spot, mark);
  }
}

function applyMark(context: BoardContext, spot: Spot, mark: GroundMark): void {
  const { state, catalog, events } = context;
  const effect = catalog.groundEffects.get(mark.groundEffectId);
  if (!effect) return;
  const creature = combatantAt(state, spot);
  if (effect.damagePercent !== null) {
    const amount = Math.min(
      Math.max(1, Math.floor((creature.stats.hp * effect.damagePercent) / 100)),
      creature.currentHp,
    );
    creature.currentHp -= amount;
    events.push({
      type: 'ground_damage',
      ...spot,
      amount,
      hp: creature.currentHp,
      ground_effect_id: mark.groundEffectId,
    });
    faintIfDown(context, spot);
  }
  // Sem tentar de novo quem já tem status: a marca age a cada vez da fila.
  if (
    effect.statusSlug !== null &&
    creature.currentHp > 0 &&
    creature.statusSlug === null
  ) {
    applyStatus(context, spot, effect.statusSlug);
  }
}

export function ageMarks(context: BoardContext): void {
  const { state, events } = context;
  const kept: GroundMark[] = [];
  for (const mark of state.marks) {
    mark.remaining -= 1;
    if (mark.remaining > 0) kept.push(mark);
    else events.push({ type: 'mark_ended', cell: mark.cell });
  }
  state.marks = kept;
}
