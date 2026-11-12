import type { Random } from '../battle/types.js';

export const COINS_WIN_BASE = 20;
export const COINS_LOSS_BASE = 5;
export const TAMER_COINS_WIN_BASE = 60;
export const TAMER_COINS_LOSS_BASE = 15;

function rollCoins(
  base: number,
  enemyLevel: number,
  fielderLevel: number,
  random: Random,
): number {
  const target = (base * enemyLevel) / fielderLevel;
  const min = Math.floor(target * 0.5);
  const max = Math.floor(target * 1.5);
  return min + Math.floor(random() * (max - min + 1));
}

export function winCoins(
  enemyLevel: number,
  fielderLevel: number,
  random: Random,
  base = COINS_WIN_BASE,
): number {
  return Math.max(1, rollCoins(base, enemyLevel, fielderLevel, random));
}

export function lostCoins(
  enemyLevel: number,
  fielderLevel: number,
  coins: number,
  random: Random,
  base = COINS_LOSS_BASE,
): number {
  if (coins <= 0) return 0;
  return Math.min(coins, rollCoins(base, enemyLevel, fielderLevel, random));
}
