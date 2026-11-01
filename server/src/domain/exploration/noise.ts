import type { Random } from '../battle/types.js';

export type Noise2D = (x: number, y: number) => number;

const TABLE_SIZE = 256;
const TABLE_MASK = TABLE_SIZE - 1;
const OCTAVES = 3;

function smooth(t: number): number {
  return t * t * (3 - 2 * t);
}

function lerp(from: number, to: number, t: number): number {
  return from + (to - from) * t;
}

/**
 * Ruído suave em [0, 1]: valores sorteados numa grade, misturados entre os
 * pontos, somando oitavas cada vez mais finas. Consome `random` só aqui.
 */
export function createNoise(random: Random): Noise2D {
  const values = Array.from({ length: TABLE_SIZE }, () => random());
  const order = values.map((_, index) => index);
  for (let index = TABLE_SIZE - 1; index > 0; index -= 1) {
    const other = Math.floor(random() * (index + 1));
    [order[index], order[other]] = [order[other]!, order[index]!];
  }

  const valueAt = (x: number, y: number): number =>
    values[order[(order[x & TABLE_MASK]! + y) & TABLE_MASK]!]!;

  const layer = (x: number, y: number): number => {
    const left = Math.floor(x);
    const top = Math.floor(y);
    const tx = smooth(x - left);
    const ty = smooth(y - top);
    return lerp(
      lerp(valueAt(left, top), valueAt(left + 1, top), tx),
      lerp(valueAt(left, top + 1), valueAt(left + 1, top + 1), tx),
      ty,
    );
  };

  return (x, y) => {
    let total = 0;
    let weight = 0;
    for (let octave = 0; octave < OCTAVES; octave += 1) {
      const amplitude = 1 / 2 ** octave;
      total += layer(x * 2 ** octave, y * 2 ** octave) * amplitude;
      weight += amplitude;
    }
    return total / weight;
  };
}
