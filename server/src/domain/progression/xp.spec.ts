import { splitXp, xpYield } from './xp.js';

describe('xpYield', () => {
  it('é floor(xp base · nível do inimigo ÷ 7)', () => {
    expect(xpYield(62, 5)).toBe(44);
    expect(xpYield(62, 15)).toBe(132);
    expect(xpYield(142, 35)).toBe(710);
  });
});

describe('splitXp', () => {
  it('divide em partes iguais, arredondando para baixo', () => {
    expect(splitXp(44, 1)).toBe(44);
    expect(splitXp(44, 2)).toBe(22);
    expect(splitXp(44, 3)).toBe(14);
  });

  it('dá pelo menos 1 para cada um', () => {
    expect(splitXp(2, 6)).toBe(1);
    expect(splitXp(0, 1)).toBe(1);
  });
});
