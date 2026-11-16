import { critChance, hitChance } from './accuracy.js';
import { calculateDamage, rollDamageFactor, typeMultiplier } from './damage.js';
import { applyEffects } from './effects.js';
import { combatantAt, rollChance } from './field.js';
import type { BattleSkill, Random, Spot, TurnContext } from './types.js';

const PROTECT_EFFECT = 'protect';
export const FIXED_DAMAGE_EFFECT = 'fixed_damage';

export function resolveSkill(
  context: TurnContext,
  spot: Spot,
  skill: BattleSkill,
  foe: Spot | null,
): void {
  const { state, events, random } = context;
  const author = combatantAt(state, spot);
  const target = foe && combatantAt(state, foe);
  const aimsAtTarget =
    skill.targetSlug !== 'self' && skill.targetSlug !== 'ally';

  if (skill.effects.some((effect) => effect.effectSlug === PROTECT_EFFECT)) {
    author.isProtected = true;
    return;
  }
  if (aimsAtTarget && target!.isProtected) {
    events.push({ type: 'blocked', ...foe! });
    return;
  }

  if (aimsAtTarget) {
    const chance = hitChance(
      skill.accuracy,
      author.stages.accuracy,
      target!.stages.evasion,
    );
    if (!rollChance(chance, random)) {
      events.push({ type: 'missed', ...spot });
      return;
    }
  }

  const fixed = fixedDamage(skill);
  if (skill.power === 0 && fixed === null) {
    applyEffects(context, spot, foe, skill, 0);
    return;
  }
  const dealt = strikeAll(context, spot, skill, foe!, fixed);
  if (dealt !== null) applyEffects(context, spot, foe, skill, dealt);
}

/** O dano por golpe do efeito `fixed_damage`, ou nulo sem ele. */
export function fixedDamage(skill: BattleSkill): number | null {
  const effect = skill.effects.find(
    (candidate) => candidate.effectSlug === FIXED_DAMAGE_EFFECT,
  );
  return effect ? (effect.value ?? 0) : null;
}

/** Uma Técnica de um golpe só não gasta sorteio. */
export function rollHits(skill: BattleSkill, random: Random): number {
  const min = Math.max(1, skill.minHits);
  const max = Math.max(min, skill.maxHits);
  if (max === 1) return 1;
  return min + Math.floor(random() * (max - min + 1));
}

function strikeAll(
  context: TurnContext,
  spot: Spot,
  skill: BattleSkill,
  foe: Spot,
  fixed: number | null,
): number | null {
  const defender = combatantAt(context.state, foe);
  const hits = rollHits(skill, context.random);
  let dealt = 0;
  let landed = 0;
  while (landed < hits && defender.currentHp > 0) {
    const damage = strike(context, spot, skill, foe, fixed);
    if (damage === null) return null;
    dealt += damage;
    landed += 1;
  }
  if (skill.maxHits > 1) {
    context.events.push({ type: 'multi_hit', ...foe, hits: landed });
  }
  return dealt;
}

function strike(
  context: TurnContext,
  spot: Spot,
  skill: BattleSkill,
  foe: Spot,
  fixed: number | null,
): number | null {
  const { state, catalog, events, random } = context;
  const attacker = combatantAt(state, spot);
  const defender = combatantAt(state, foe);

  const multiplier = typeMultiplier(
    skill.elementId,
    defender.elementIds,
    catalog,
  );
  if (multiplier === 0) {
    events.push({ type: 'no_effect', ...foe });
    return null;
  }

  const isCritical =
    fixed === null &&
    rollChance(critChance(skill.critStage, defender.traitSlug), random);
  const damage =
    fixed ??
    calculateDamage({
      attacker,
      defender,
      skill,
      catalog,
      isCritical,
      randomFactor: rollDamageFactor(random),
    });
  const godStrike = state.godMode && spot.side === 'player';
  const dealt = godStrike
    ? defender.currentHp
    : Math.min(damage, defender.currentHp);
  defender.currentHp -= dealt;
  events.push({
    type: 'damage',
    ...foe,
    damage: dealt,
    hp: defender.currentHp,
    multiplier: fixed === null ? multiplier : 1,
    is_critical: isCritical,
  });
  return dealt;
}
