import { seedPlan } from './seed-plan.js';

describe('seedPlan', () => {
  it('banco vazio: carrega', () => {
    expect(seedPlan({ elements: 0, species: 0 })).toBe('load');
  });

  it('todas as tabelas com linhas: não faz nada', () => {
    expect(seedPlan({ elements: 14, species: 9 })).toBe('skip');
  });

  it('umas vazias e outras não: incompleto, com os nomes das que têm linhas', () => {
    expect(seedPlan({ elements: 14, stats: 0, species: 9 })).toEqual({
      incomplete: ['elements', 'species'],
    });
  });
});
