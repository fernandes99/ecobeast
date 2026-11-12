export const MAX_LEVEL = 100;

export function totalXpForLevel(xpMultiplier: number, level: number): number {
  return Math.floor(xpMultiplier * level ** 3);
}
