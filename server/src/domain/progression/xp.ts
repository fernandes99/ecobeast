export const TAMER_XP_MULTIPLIER = 1.5;

export function xpYield(baseXpYield: number, enemyLevel: number): number {
  return Math.floor((baseXpYield * enemyLevel) / 7);
}

export function splitXp(total: number, receivers: number): number {
  return Math.max(1, Math.floor(total / receivers));
}
