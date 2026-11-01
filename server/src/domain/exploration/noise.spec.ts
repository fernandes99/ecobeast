import { createNoise } from './noise.js';
import { seededRandom } from './seeded-random.js';

const STEP = 0.05;
const POINTS = 400;

describe('createNoise', () => {
  it('a mesma seed dá o mesmo ruído', () => {
    const first = createNoise(seededRandom(1));
    const second = createNoise(seededRandom(1));
    expect(first(3.3, 7.1)).toBe(second(3.3, 7.1));
  });

  it('seeds diferentes dão ruídos diferentes', () => {
    const first = createNoise(seededRandom(1));
    const second = createNoise(seededRandom(2));
    expect(first(3.3, 7.1)).not.toBe(second(3.3, 7.1));
  });

  it('fica em [0, 1]', () => {
    const noise = createNoise(seededRandom(3));
    for (let index = 0; index < POINTS; index += 1) {
      const value = noise(index * 0.37, -index * 0.19);
      expect(value).toBeGreaterThanOrEqual(0);
      expect(value).toBeLessThanOrEqual(1);
    }
  });

  it('muda aos poucos entre pontos próximos', () => {
    const noise = createNoise(seededRandom(4));
    for (let index = 0; index < POINTS; index += 1) {
      const here = noise(index * STEP, 1);
      const next = noise((index + 1) * STEP, 1);
      expect(Math.abs(next - here)).toBeLessThan(0.25);
    }
  });

  it('não é constante', () => {
    const noise = createNoise(seededRandom(5));
    const values = Array.from({ length: POINTS }, (_, index) =>
      noise(index * 0.37, index * 0.11),
    );
    expect(Math.max(...values) - Math.min(...values)).toBeGreaterThan(0.3);
  });
});
