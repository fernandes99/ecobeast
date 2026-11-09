/** Quanto o XP de um Ecobeast de Domador NPC vale a mais, _a revisar_ (npc-tamers/02). */
export const TAMER_XP_MULTIPLIER = 1.5;

/** O XP que um inimigo derrubado dá: floor(xp base · nível ÷ 7). */
export function xpYield(baseXpYield: number, enemyLevel: number): number {
  return Math.floor((baseXpYield * enemyLevel) / 7);
}

/** A parte de cada um que recebe; ninguém recebe menos de 1. */
export function splitXp(total: number, receivers: number): number {
  return Math.max(1, Math.floor(total / receivers));
}
