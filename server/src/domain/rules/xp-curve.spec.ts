import { MAX_LEVEL, totalXpForLevel } from './xp-curve.js';

describe('MAX_LEVEL', () => {
  it('é 100', () => {
    expect(MAX_LEVEL).toBe(100);
  });
});

describe('totalXpForLevel', () => {
  it('é floor(multiplicador · nível³)', () => {
    expect(totalXpForLevel(1.0, 5)).toBe(125);
    expect(totalXpForLevel(0.8, 5)).toBe(100);
    expect(totalXpForLevel(1.25, 5)).toBe(156);
  });

  it('dá 1 no nível 1 com a curva média', () => {
    expect(totalXpForLevel(1.0, 1)).toBe(1);
  });
});
