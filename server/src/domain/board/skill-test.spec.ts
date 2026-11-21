import { makeCombatant } from '../battle/testing.js';
import { borrowedCombatant, SKILL_TEST_UID } from './skill-test.js';

describe('Ecobeast emprestado da luta de teste (skill-test/01)', () => {
  const sorted = makeCombatant({
    creatureUid: null,
    skills: [
      { skillId: 1, currentPp: 35 },
      { skillId: 2, currentPp: 30 },
      { skillId: 3, currentPp: 25 },
    ],
  });

  it('põe a Técnica testada no 1º espaço, com o PP cheio, e as duas últimas sorteadas', () => {
    const borrowed = borrowedCombatant(sorted, { id: 9, maxPp: 15 });
    expect(borrowed.skills).toEqual([
      { skillId: 9, currentPp: 15 },
      { skillId: 2, currentPp: 30 },
      { skillId: 3, currentPp: 25 },
    ]);
    expect(borrowed.creatureUid).toBe(SKILL_TEST_UID);
  });

  it('não repete a Técnica testada quando ele já a sorteou', () => {
    const borrowed = borrowedCombatant(sorted, { id: 2, maxPp: 30 });
    expect(borrowed.skills.map(({ skillId }) => skillId)).toEqual([2, 1, 3]);
  });

  it('não muda o Ecobeast sorteado', () => {
    borrowedCombatant(sorted, { id: 9, maxPp: 15 });
    expect(sorted.skills).toHaveLength(3);
    expect(sorted.creatureUid).toBeNull();
  });
});
