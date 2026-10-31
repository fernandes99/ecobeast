import { secureRandom } from './secure-random.js';

describe('secureRandom', () => {
  it('fica em [0, 1) e varia', () => {
    const values = Array.from({ length: 100 }, () => secureRandom());
    expect(values.every((value) => value >= 0 && value < 1)).toBe(true);
    expect(new Set(values).size).toBeGreaterThan(1);
  });
});
