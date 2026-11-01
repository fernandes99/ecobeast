import type { Random } from '../battle/types.js';

const INT32_RANGE = 2 ** 32;

/** Gerador mulberry32: a mesma seed sempre dá a mesma sequência em [0, 1). */
export function seededRandom(seed: number): Random {
  let state = seed | 0;
  return () => {
    state = (state + 0x6d2b79f5) | 0;
    let mixed = Math.imul(state ^ (state >>> 15), 1 | state);
    mixed = (mixed + Math.imul(mixed ^ (mixed >>> 7), 61 | mixed)) ^ mixed;
    return ((mixed ^ (mixed >>> 14)) >>> 0) / INT32_RANGE;
  };
}
