import { randomInt } from 'node:crypto';

const RANDOM_RANGE = 2 ** 48 - 1;

export function secureRandom(): number {
  return randomInt(RANDOM_RANGE) / RANDOM_RANGE;
}
