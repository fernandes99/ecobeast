import type { LearnsetEntry } from '../rules/creature-factory.js';
import { evolutionSkills, learnNewSkills, skillsBetween } from './learnset.js';

const learnset: LearnsetEntry[] = [
  { skillId: 1, method: 'level_up', level: 1 },
  { skillId: 9, method: 'level_up', level: 7 },
  { skillId: 5, method: 'level_up', level: 7 },
  { skillId: 6, method: 'level_up', level: 10 },
  { skillId: 7, method: 'level_up', level: 12 },
  { skillId: 8, method: 'evolution', level: 0 },
  { skillId: 3, method: 'evolution', level: 0 },
  { skillId: 4, method: 'teachable', level: null },
];

describe('skillsBetween', () => {
  it('pega as de nível depois do antigo e até o novo, por nível e depois por id', () => {
    expect(skillsBetween(learnset, 6, 10)).toEqual([5, 9, 6]);
  });

  it('não pega a do nível de antes', () => {
    expect(skillsBetween(learnset, 7, 11)).toEqual([6]);
  });

  it('sem subir de nível, não pega nada', () => {
    expect(skillsBetween(learnset, 10, 10)).toEqual([]);
  });

  it('ignora as que não são por nível', () => {
    expect(skillsBetween(learnset, 0, 100)).toEqual([1, 5, 9, 6, 7]);
  });
});

describe('evolutionSkills', () => {
  it('pega só as de evolução, por id', () => {
    expect(evolutionSkills(learnset)).toEqual([3, 8]);
  });
});

describe('learnNewSkills', () => {
  it('com vaga, aprende na ordem até completar 4', () => {
    expect(learnNewSkills([1, 2], [5, 6, 7])).toEqual({
      learned: [5, 6],
      pending: [7],
    });
  });

  it('com 4, tudo fica pendente', () => {
    expect(learnNewSkills([1, 2, 3, 4], [5, 6])).toEqual({
      learned: [],
      pending: [5, 6],
    });
  });

  it('tira as que ele já conhece e as repetidas', () => {
    expect(learnNewSkills([1, 2, 3, 4], [2, 5, 5, 6])).toEqual({
      learned: [],
      pending: [5, 6],
    });
  });

  it('sem nada novo, não muda nada', () => {
    expect(learnNewSkills([1], [])).toEqual({ learned: [], pending: [] });
  });
});
