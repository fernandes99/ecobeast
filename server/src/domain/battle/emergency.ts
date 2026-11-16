import type { BattleSkill, Combatant } from './types.js';

export const EMERGENCY_SKILL: BattleSkill = {
  id: 0,
  elementId: null,
  elementSlug: null,
  category: 'physical',
  power: 30,
  accuracy: 0,
  maxPp: 0,
  cooldown: 0,
  priority: 0,
  critStage: 0,
  minHits: 1,
  maxHits: 1,
  targetSlug: 'enemy',
  areaShape: 'single',
  range: 1,
  pierces: false,
  groundEffectId: null,
  groundTurns: null,
  effects: [
    {
      effectSlug: 'self_damage',
      chance: 100,
      targetSlug: 'self',
      statusSlug: null,
      statSlug: null,
      stages: null,
      percent: 12.5,
      value: null,
    },
  ],
};

export function hasPp(combatant: Combatant): boolean {
  return combatant.skills.some((skill) => skill.currentPp > 0);
}
