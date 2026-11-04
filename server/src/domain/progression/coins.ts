import type { Random } from '../battle/types.js';

/** As bases das moedas contra um selvagem, _a revisar_ (progression/05). */
export const COINS_WIN_BASE = 20;
export const COINS_LOSS_BASE = 5;

/**
 * Um sorteio de 50% a 150% de `base × (nível do selvagem ÷ nível de quem
 * está em campo)`, com os dois limites incluídos.
 */
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

/** As moedas da vitória; ninguém vence sem ganhar pelo menos 1. */
export function winCoins(
  enemyLevel: number,
  fielderLevel: number,
  random: Random,
): number {
  return Math.max(
    1,
    rollCoins(COINS_WIN_BASE, enemyLevel, fielderLevel, random),
  );
}

/** As moedas da derrota, sem passar do que o Domador tem; sem moedas, nem sorteia. */
export function lostCoins(
  enemyLevel: number,
  fielderLevel: number,
  coins: number,
  random: Random,
): number {
  if (coins <= 0) return 0;
  return Math.min(
    coins,
    rollCoins(COINS_LOSS_BASE, enemyLevel, fielderLevel, random),
  );
}
