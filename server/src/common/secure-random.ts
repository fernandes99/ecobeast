import { randomInt } from 'node:crypto';

/** O maior intervalo aceito pelo `crypto.randomInt`. */
const RANDOM_RANGE = 2 ** 48 - 1;

/** Número em [0, 1) de uma fonte segura, para os sorteios das regras. */
export function secureRandom(): number {
  return randomInt(RANDOM_RANGE) / RANDOM_RANGE;
}
