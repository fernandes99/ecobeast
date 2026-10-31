import type { BattleSkill, Combatant } from './types.js';

/** O "Golpe de Esforço": a saída de quem ficou sem PP. Valores a revisar. */
export const EMERGENCY_SKILL: BattleSkill = {
  id: 0,
  elementId: null,
  elementSlug: null,
  category: 'physical',
  power: 30,
  accuracy: 0,
  maxPp: 0,
  priority: 0,
  critStage: 0,
  targetSlug: 'enemy',
  effects: [
    {
      effectSlug: 'self_damage',
      chance: 100,
      targetSlug: 'self',
      statusSlug: null,
      statSlug: null,
      stages: null,
      percent: 12.5,
    },
  ],
};

export function hasPp(combatant: Combatant): boolean {
  return combatant.skills.some((skill) => skill.currentPp > 0);
}
