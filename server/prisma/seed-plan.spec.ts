import { seedPlan } from './seed-plan.js';

describe('seedPlan', () => {
  it('banco vazio: carrega todas as tabelas', () => {
    expect(seedPlan({ elements: 0, species: 0 })).toEqual({
      load: ['elements', 'species'],
    });
  });

  it('todas as tabelas com linhas: não faz nada', () => {
    expect(seedPlan({ elements: 14, species: 9 })).toBe('skip');
  });

  it('umas vazias e outras não: carrega só as vazias', () => {
    expect(seedPlan({ elements: 14, items: 0, species: 9 })).toEqual({
      load: ['items'],
    });
  });
});
