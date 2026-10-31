import type { BattleStatSlug, Combatant, StageSlug } from './types.js';

const MIN_STAGE = -6;
const MAX_STAGE = 6;
const PARALYSIS_SPEED = 0.5;

export function noStages(): Record<StageSlug, number> {
  return {
    atk: 0,
    def: 0,
    sp_atk: 0,
    sp_def: 0,
    spd: 0,
    accuracy: 0,
    evasion: 0,
  };
}

export function clampStage(stage: number): number {
  return Math.min(MAX_STAGE, Math.max(MIN_STAGE, stage));
}

/** +n vale (2 + n) / 2; -n vale 2 / (2 + n). */
export function stageMultiplier(stage: number): number {
  return stage >= 0 ? (2 + stage) / 2 : 2 / (2 - stage);
}

/** O stat em campo: estágios e, na Velocidade, a paralisia. */
export function effectiveStat(
  combatant: Combatant,
  slug: BattleStatSlug,
): number {
  const value = combatant.stats[slug] * stageMultiplier(combatant.stages[slug]);
  const isSlowed = slug === 'spd' && combatant.statusSlug === 'paralysis';
  return isSlowed ? value * PARALYSIS_SPEED : value;
}
