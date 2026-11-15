import type { CombatantSkill } from '../battle/types.js';

export const NOT_READY = 'Essa Técnica ainda não voltou.';

export function cooldownLeft(learned: CombatantSkill, round: number): number {
  return Math.max(0, (learned.readyRound ?? 0) - round);
}

export function isReady(learned: CombatantSkill, round: number): boolean {
  return cooldownLeft(learned, round) === 0;
}

/** Com countdown N, a Técnica usada na rodada R volta na rodada R + N + 1. */
export function startCooldown(
  learned: CombatantSkill,
  round: number,
  cooldown: number,
): void {
  learned.readyRound = round + cooldown + 1;
}
