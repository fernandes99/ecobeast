import { stageMultiplier } from './stages.js';
import type {
  BattleCatalog,
  BattleSkill,
  BattleStatSlug,
  Combatant,
} from './types.js';

const STAB = 1.5;
const CRITICAL = 1.5;
const BURN_PHYSICAL = 0.5;
const FURY = 1.5;

/** Traços que aumentam um Elemento com o HP em 1/3 ou menos. */
const FURY_ELEMENTS: Record<string, string> = {
  blazing_fury: 'fire',
  tidal_fury: 'water',
  rooted_fury: 'flora',
};

export interface DamageInput {
  attacker: Combatant;
  defender: Combatant;
  skill: BattleSkill;
  catalog: BattleCatalog;
  isCritical: boolean;
  /** De 0,85 a 1. */
  randomFactor: number;
}

/** O produto dos multiplicadores; sem Elemento, ou par sem linha, vale 1. */
export function typeMultiplier(
  skillElementId: number | null,
  defenderElementIds: number[],
  catalog: BattleCatalog,
): number {
  if (skillElementId === null) return 1;
  return defenderElementIds.reduce(
    (product, elementId) =>
      product * (catalog.efficacy.get(`${skillElementId}:${elementId}`) ?? 1),
    1,
  );
}

/** A fórmula de dano do GDD; com Tipo 0, o dano é 0. */
export function calculateDamage(input: DamageInput): number {
  const { attacker, defender, skill, catalog, isCritical, randomFactor } =
    input;
  const type = typeMultiplier(skill.elementId, defender.elementIds, catalog);
  if (type === 0) return 0;

  const isPhysical = skill.category === 'physical';
  const attack = attackValue(
    attacker,
    isPhysical ? 'atk' : 'sp_atk',
    isCritical,
  );
  const defense = defenseValue(
    defender,
    isPhysical ? 'def' : 'sp_def',
    isCritical,
  );
  const base =
    (((2 * attacker.level) / 5 + 2) * skill.power * (attack / defense)) / 50 +
    2;

  const stab =
    skill.elementId !== null && attacker.elementIds.includes(skill.elementId)
      ? STAB
      : 1;
  const critical = isCritical ? CRITICAL : 1;
  const others =
    burnMultiplier(attacker, isPhysical) * furyMultiplier(attacker, skill);
  const damage = base * stab * type * critical * randomFactor * others;
  return Math.max(1, Math.floor(damage));
}

/** Em crítico, um estágio negativo do atacante não conta. */
function attackValue(
  attacker: Combatant,
  slug: BattleStatSlug,
  isCritical: boolean,
): number {
  const stage = attacker.stages[slug];
  return (
    attacker.stats[slug] *
    stageMultiplier(isCritical ? Math.max(stage, 0) : stage)
  );
}

/** Em crítico, um estágio positivo do defensor não conta. */
function defenseValue(
  defender: Combatant,
  slug: BattleStatSlug,
  isCritical: boolean,
): number {
  const stage = defender.stages[slug];
  return (
    defender.stats[slug] *
    stageMultiplier(isCritical ? Math.min(stage, 0) : stage)
  );
}

function burnMultiplier(attacker: Combatant, isPhysical: boolean): number {
  return isPhysical && attacker.statusSlug === 'burn' ? BURN_PHYSICAL : 1;
}

function furyMultiplier(attacker: Combatant, skill: BattleSkill): number {
  const isElement = FURY_ELEMENTS[attacker.traitSlug] === skill.elementSlug;
  const isHurt = attacker.currentHp * 3 <= attacker.stats.hp;
  return skill.elementSlug !== null && isElement && isHurt ? FURY : 1;
}
