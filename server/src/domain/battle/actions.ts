import { critChance, hitChance } from './accuracy.js';
import { calculateDamage, rollDamageFactor, typeMultiplier } from './damage.js';
import { applyEffects } from './effects.js';
import { EMERGENCY_SKILL } from './emergency.js';
import { activeOf, opponentOf, rollChance } from './field.js';
import { canAct, faintIfDown } from './status.js';
import { applyDefeatTrait } from './traits.js';
import type { TurnAction } from './turn-order.js';
import type {
  BattleAction,
  BattleSkill,
  CombatantSkill,
  SideSlug,
  TurnContext,
} from './types.js';

const PROTECT_EFFECT = 'protect';

export interface FieldAction extends TurnAction {
  side: SideSlug;
  skill: BattleSkill;
  /** Nulo no golpe de emergência, que não gasta PP. */
  learned: CombatantSkill | null;
}

export function toFieldAction(
  context: TurnContext,
  side: SideSlug,
  action: BattleAction,
): FieldAction {
  const combatant = activeOf(context.state, side);
  if (action.type !== 'skill') {
    const skill = EMERGENCY_SKILL;
    return { side, combatant, skill, priority: skill.priority, learned: null };
  }
  const learned = combatant.skills[action.slot - 1]!;
  const skill = context.catalog.skills.get(learned.skillId)!;
  return { side, combatant, skill, priority: skill.priority, learned };
}

/**
 * Uma ação em campo, do "pode agir?" ao desmaio. Sem alvo de pé, a ação não
 * acontece e não gasta PP: o outro lado pode ter caído com o próprio recuo.
 */
export function executeAction(context: TurnContext, action: FieldAction): void {
  const { state } = context;
  const { side, skill } = action;
  const author = activeOf(state, side);
  const targetSide = opponentOf(side);
  const target = activeOf(state, targetSide);
  const aimsAtTarget = skill.targetSlug !== 'self';
  if (author.currentHp === 0) return;
  if (aimsAtTarget && target.currentHp === 0) return;

  if (canAct(context, side)) useSkill(context, action);
  const defeatedTarget = aimsAtTarget && target.currentHp === 0;
  if (aimsAtTarget) faintIfDown(context, targetSide);
  faintIfDown(context, side);
  if (defeatedTarget && author.currentHp > 0) applyDefeatTrait(context, side);
}

function useSkill(context: TurnContext, action: FieldAction): void {
  const { state, events, random } = context;
  const { side, skill, learned } = action;
  const author = activeOf(state, side);
  const target = activeOf(state, opponentOf(side));
  const aimsAtTarget = skill.targetSlug !== 'self';

  if (learned) learned.currentPp -= 1;
  events.push({
    type: 'skill_used',
    side,
    skill_id: learned ? skill.id : null,
  });

  if (skill.effects.some((effect) => effect.effectSlug === PROTECT_EFFECT)) {
    author.isProtected = true;
    return;
  }
  if (aimsAtTarget && target.isProtected) {
    events.push({ type: 'blocked', side: opponentOf(side) });
    return;
  }

  const chance = hitChance(
    skill.accuracy,
    author.stages.accuracy,
    target.stages.evasion,
  );
  if (aimsAtTarget && !rollChance(chance, random)) {
    events.push({ type: 'missed', side });
    return;
  }

  const dealt = skill.power > 0 ? strike(context, action) : 0;
  if (dealt !== null) applyEffects(context, side, skill, dealt);
}

/** Aplica o dano no alvo; devolve o HP que ele perdeu, ou nulo se for imune. */
function strike(context: TurnContext, action: FieldAction): number | null {
  const { state, catalog, events, random } = context;
  const { side, skill } = action;
  const attacker = activeOf(state, side);
  const targetSide = opponentOf(side);
  const defender = activeOf(state, targetSide);

  const multiplier = typeMultiplier(
    skill.elementId,
    defender.elementIds,
    catalog,
  );
  if (multiplier === 0) {
    events.push({ type: 'no_effect', side: targetSide });
    return null;
  }

  const isCritical = rollChance(
    critChance(skill.critStage, defender.traitSlug),
    random,
  );
  const damage = calculateDamage({
    attacker,
    defender,
    skill,
    catalog,
    isCritical,
    randomFactor: rollDamageFactor(random),
  });
  const godStrike = state.godMode && side === 'player';
  const dealt = godStrike
    ? defender.currentHp
    : Math.min(damage, defender.currentHp);
  defender.currentHp -= dealt;
  events.push({
    type: 'damage',
    side: targetSide,
    damage: dealt,
    hp: defender.currentHp,
    multiplier,
    is_critical: isCritical,
  });
  return dealt;
}
