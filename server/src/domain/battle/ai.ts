import { calculateDamage } from './damage.js';
import { activeOf } from './field.js';
import type {
  BattleAction,
  BattleCatalog,
  BattleSkill,
  BattleState,
  Combatant,
  Random,
} from './types.js';

const SUPPORT_WEIGHT = 20;
const MIN_WEIGHT = 1;
const MAX_WEIGHT = 100;

interface SkillOption {
  slot: number;
  weight: number;
}

/** Sorteia entre as Técnicas com PP, com mais chance para as de mais dano. */
export function chooseEnemyAction(
  state: BattleState,
  catalog: BattleCatalog,
  random: Random,
): BattleAction {
  const attacker = activeOf(state, 'enemy');
  const target = activeOf(state, 'player');
  const options = attacker.skills.flatMap((learned, index) => {
    const skill = catalog.skills.get(learned.skillId);
    if (!skill || learned.currentPp === 0) return [];
    const weight = skillWeight(attacker, target, skill, catalog);
    return [{ slot: index + 1, weight }];
  });
  if (options.length === 0) return { type: 'emergency' };
  return { type: 'skill', slot: pickSlot(options, random) };
}

/** O dano estimado como porcentagem do HP atual do alvo. */
function skillWeight(
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

function pickSlot(options: SkillOption[], random: Random): number {
  const total = options.reduce((sum, option) => sum + option.weight, 0);
  let roll = random() * total;
  for (const option of options) {
    roll -= option.weight;
    if (roll < 0) return option.slot;
  }
  return options.at(-1)!.slot;
}
