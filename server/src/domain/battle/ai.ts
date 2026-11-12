import { calculateDamage } from './damage.js';
import type { BattleCatalog, BattleSkill, Combatant, Random } from './types.js';

const SUPPORT_WEIGHT = 20;
const MIN_WEIGHT = 1;
const MAX_WEIGHT = 100;

export interface SkillOption {
  slot: number;
  weight: number;
}

export function skillWeight(
  attacker: Combatant,
  defender: Combatant,
  skill: BattleSkill,
  catalog: BattleCatalog,
): number {
  if (skill.power === 0) return SUPPORT_WEIGHT;
  const damage = calculateDamage({
    attacker,
    defender,
    skill,
    catalog,
    isCritical: false,
    randomFactor: 1,
  });
  const percent = (damage / defender.currentHp) * 100;
  return Math.min(MAX_WEIGHT, Math.max(MIN_WEIGHT, percent));
}

export function pickSlot(options: SkillOption[], random: Random): number {
  const total = options.reduce((sum, option) => sum + option.weight, 0);
  let roll = random() * total;
  for (const option of options) {
    roll -= option.weight;
    if (roll < 0) return option.slot;
  }
  return options.at(-1)!.slot;
}
