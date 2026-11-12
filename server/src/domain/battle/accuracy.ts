import { clampStage, stageMultiplier } from './stages.js';

/** Chance de crítico por estágio; do último em diante, é sempre crítico. */
const CRIT_CHANCES = [1 / 24, 1 / 8, 1 / 2, 1];
const NO_CRIT_TRAIT = 'hard_shell';

/** Chance de acertar, de 0 a 1. Precisão 0 nunca erra. */
export function hitChance(
  accuracy: number,
  accuracyStage: number,
  evasionStage: number,
): number {
  if (accuracy === 0) return 1;
  const stage = clampStage(accuracyStage - evasionStage);
  return Math.min(1, (accuracy / 100) * stageMultiplier(stage));
}

export function critChance(critStage: number, targetTraitSlug: string): number {
  if (targetTraitSlug === NO_CRIT_TRAIT) return 0;
  return CRIT_CHANCES[Math.min(critStage, CRIT_CHANCES.length - 1)]!;
}
