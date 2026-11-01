import { seededRandom } from './seeded-random.js';

const SAMPLES = 1000;

function take(seed: number, count: number): number[] {
  const random = seededRandom(seed);
  return Array.from({ length: count }, () => random());
}

describe('seededRandom', () => {
  it('a mesma seed dá a mesma sequência', () => {
    expect(take(42, 20)).toEqual(take(42, 20));
  });

  it('seeds diferentes dão sequências diferentes', () => {
    expect(take(42, 20)).not.toEqual(take(43, 20));
  });

  it('fica em [0, 1)', () => {
    for (const value of take(7, SAMPLES)) {
      expect(value).toBeGreaterThanOrEqual(0);
      expect(value).toBeLessThan(1);
    }
  });

  it('se espalha pela faixa', () => {
    const mean = take(7, SAMPLES).reduce((sum, value) => sum + value) / SAMPLES;
    expect(mean).toBeGreaterThan(0.45);
    expect(mean).toBeLessThan(0.55);
  });
});
