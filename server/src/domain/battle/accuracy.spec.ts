import { critChance, hitChance } from './accuracy.js';

describe('hitChance', () => {
  it('Precisão 0 nunca erra, mesmo com Evasão alta', () => {
    expect(hitChance(0, -6, 6)).toBe(1);
  });

  it('usa a Precisão da Técnica sem estágios', () => {
    expect(hitChance(85, 0, 0)).toBeCloseTo(0.85);
  });

  it('Precisão do atacante soma, e Evasão do alvo subtrai', () => {
    expect(hitChance(60, 1, 0)).toBeCloseTo(0.9);
    expect(hitChance(90, 0, 1)).toBeCloseTo(0.6);
    expect(hitChance(60, 2, 1)).toBeCloseTo(0.9);
  });

  it('o estágio somado fica entre -6 e +6', () => {
    expect(hitChance(100, -6, 6)).toBeCloseTo(0.25);
  });

  it('nunca passa de 1', () => {
    expect(hitChance(100, 6, 0)).toBe(1);
  });
});

describe('critChance', () => {
  it.each([
    [0, 1 / 24],
    [1, 1 / 8],
    [2, 1 / 2],
    [3, 1],
    [5, 1],
  ])('estágio %i vale %d', (stage, expected) => {
    expect(critChance(stage, 'none')).toBeCloseTo(expected);
  });

  it('Casca Dura não sofre crítico', () => {
    expect(critChance(3, 'hard_shell')).toBe(0);
  });
});
