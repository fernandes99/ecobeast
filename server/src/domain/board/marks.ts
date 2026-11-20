import { combatantAt } from '../battle/field.js';
import { changeStage } from '../battle/effects.js';
import {
  applyStatus,
  faintIfDown,
  hasStatus,
  isImmune,
} from '../battle/status.js';
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
 * primeiro o jogador, em ordem de vaga. Os atributos da marca só mudam em
 * quem acabou de jogar (`actor`).
 */
export function applyMarks(context: BoardContext, actor: Spot): void {
  const { state } = context;
  const spots = [
    ...standingOnBoard(state, 'player'),
    ...standingOnBoard(state, 'enemy'),
  ];
  for (const spot of spots) {
    const mark = markAt(state, cellOf(state, spot)!);
    if (mark) applyMark(context, spot, mark, sameSpot(spot, actor));
  }
}

function sameSpot(a: Spot, b: Spot): boolean {
  return a.side === b.side && a.position === b.position;
}

function applyMark(
  context: BoardContext,
  spot: Spot,
  mark: GroundMark,
  justPlayed: boolean,
): void {
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
  if (effect.healPercent !== null && creature.currentHp > 0) {
    const amount = Math.min(
      Math.max(1, Math.floor((creature.stats.hp * effect.healPercent) / 100)),
      creature.stats.hp - creature.currentHp,
    );
    if (amount > 0) {
      creature.currentHp += amount;
      events.push({
        type: 'ground_heal',
        ...spot,
        amount,
        hp: creature.currentHp,
        ground_effect_id: mark.groundEffectId,
      });
    }
  }
  // Sem tentar de novo quem já tem o status ou é imune: a marca age a cada vez da fila.
  if (
    effect.statusSlug !== null &&
    creature.currentHp > 0 &&
    !hasStatus(creature, effect.statusSlug) &&
    !isImmune(context, creature, effect.statusSlug)
  ) {
    applyStatus(context, spot, effect.statusSlug);
  }
  if (!justPlayed || creature.currentHp <= 0) return;
  for (const { statSlug, stages } of effect.stats) {
    changeStage(context, spot, statSlug, stages);
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
