import { fixedDamage } from './actions.js';
import { calculateDamage, typeMultiplier } from './damage.js';
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
  if (!dealsDamage(skill)) return SUPPORT_WEIGHT;
  const fixed = fixedDamage(skill);
  const damage =
    fixed === null
      ? calculateDamage({
          attacker,
          defender,
          skill,
          catalog,
          isCritical: false,
          randomFactor: 1,
        })
      : fixedEstimate(skill, fixed, defender, catalog);
  const percent = (damage / defender.currentHp) * 100;
  return Math.min(MAX_WEIGHT, Math.max(MIN_WEIGHT, percent));
}

export function dealsDamage(skill: BattleSkill): boolean {
  return skill.power > 0 || fixedDamage(skill) !== null;
}

/** O dano fixo vezes a média de golpes, ou 0 contra um Elemento imune. */
function fixedEstimate(
  skill: BattleSkill,
  fixed: number,
  defender: Combatant,
  catalog: BattleCatalog,
): number {
  if (typeMultiplier(skill.elementId, defender.elementIds, catalog) === 0) {
    return 0;
  }
  return (fixed * (skill.minHits + skill.maxHits)) / 2;
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
