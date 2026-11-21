import type { Combatant } from '../battle/types.js';

/** Não é de nenhum Ecobeast do banco: a luta de teste não grava nada. */
export const SKILL_TEST_UID = 'skill-test';

const OTHER_SKILLS = 2;

export interface TestedSkill {
  id: number;
  maxPp: number;
}

/** A Técnica testada no 1º espaço e as duas últimas que ele sorteou (skill-test/01, RF-02). */
export function borrowedCombatant(
  sorted: Combatant,
  skill: TestedSkill,
): Combatant {
  const copy = structuredClone(sorted);
  const others = copy.skills
    .filter(({ skillId }) => skillId !== skill.id)
    .slice(-OTHER_SKILLS);
  return {
    ...copy,
    creatureUid: SKILL_TEST_UID,
    skills: [{ skillId: skill.id, currentPp: skill.maxPp }, ...others],
  };
}
