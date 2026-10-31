import { clampStage, effectiveStat, stageMultiplier } from './stages.js';
import { makeCombatant } from './testing.js';

describe('stageMultiplier', () => {
  it.each([
    [0, 1],
    [1, 1.5],
    [2, 2],
    [6, 4],
    [-1, 2 / 3],
    [-2, 1 / 2],
    [-6, 1 / 4],
  ])('estágio %i vale %d', (stage, expected) => {
    expect(stageMultiplier(stage)).toBeCloseTo(expected);
  });
});

describe('clampStage', () => {
  it('fica entre -6 e +6', () => {
    expect(clampStage(7)).toBe(6);
    expect(clampStage(-9)).toBe(-6);
    expect(clampStage(3)).toBe(3);
  });
});

describe('effectiveStat', () => {
  it('multiplica o stat pelo estágio', () => {
    const combatant = makeCombatant();
    combatant.stages.atk = 2;
    expect(effectiveStat(combatant, 'atk')).toBe(20);
  });

  it('Paralisado tem metade da Velocidade', () => {
    const combatant = makeCombatant({ statusSlug: 'paralysis' });
    expect(effectiveStat(combatant, 'spd')).toBe(5.5);
  });

  it('a paralisia só muda a Velocidade', () => {
    const combatant = makeCombatant({ statusSlug: 'paralysis' });
    expect(effectiveStat(combatant, 'atk')).toBe(10);
  });
});
