/** O nível máximo de uma criatura. */
export const MAX_LEVEL = 100;

/** XP total para chegar a um nível: floor(multiplicador · nível³). */
export function totalXpForLevel(xpMultiplier: number, level: number): number {
  return Math.floor(xpMultiplier * level ** 3);
}
