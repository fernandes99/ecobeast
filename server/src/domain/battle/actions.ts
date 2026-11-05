import { critChance, hitChance } from './accuracy.js';
import { calculateDamage, rollDamageFactor, typeMultiplier } from './damage.js';
import { applyEffects } from './effects.js';
import { EMERGENCY_SKILL } from './emergency.js';
import {
  activeAt,
  combatantAt,
  isStanding,
  opponentOf,
  rollChance,
  standingSpots,
} from './field.js';
import { canAct, faintIfDown } from './status.js';
import { applyDefeatTrait } from './traits.js';
import type { TurnAction } from './turn-order.js';
import type {
  BattleAction,
  BattleSkill,
  CombatantSkill,
  Spot,
  TurnContext,
} from './types.js';

const PROTECT_EFFECT = 'protect';

export interface FieldAction extends TurnAction {
  spot: Spot;
  skill: BattleSkill;
  /** Nulo no golpe de emergência, que não gasta PP. */
  learned: CombatantSkill | null;
  /** A posição do adversário escolhido; nula sem escolha, e então vale o primeiro de pé. */
  target: number | null;
}

export function toFieldAction(
  context: TurnContext,
  spot: Spot,
  action: BattleAction,
): FieldAction {
  const combatant = combatantAt(context.state, spot);
  const target = 'target' in action ? (action.target ?? null) : null;
  if (action.type !== 'skill') {
    const skill = EMERGENCY_SKILL;
    const priority = skill.priority;
    return { spot, combatant, skill, priority, learned: null, target };
  }
  const learned = combatant.skills[action.slot - 1]!;
  const skill = context.catalog.skills.get(learned.skillId)!;
  return { spot, combatant, skill, priority: skill.priority, learned, target };
}

/**
 * O adversário que a ação atinge: o escolhido, se seguir de pé, ou o de pé de
 * menor posição. Nulo sem nenhum.
 */
function foeOf(context: TurnContext, action: FieldAction): Spot | null {
  const side = opponentOf(action.spot.side);
  if (action.target !== null) {
    const chosen = { side, position: action.target };
    const creature = activeAt(context.state, chosen);
    if (creature && isStanding(creature)) return chosen;
  }
  return standingSpots(context.state, side)[0] ?? null;
}

/**
 * Uma ação em campo, do "pode agir?" ao desmaio. Sem alvo de pé, a ação não
 * acontece e não gasta PP: o outro lado pode ter caído com o próprio recuo.
 */
export function executeAction(context: TurnContext, action: FieldAction): void {
  const { state } = context;
  const { spot, skill } = action;
  const author = combatantAt(state, spot);
  const aimsAtTarget = skill.targetSlug !== 'self';
  if (!isStanding(author)) return;
  const foe = foeOf(context, action);
  if (aimsAtTarget && foe === null) return;

  if (canAct(context, spot)) useSkill(context, action, foe);
  const target = aimsAtTarget ? combatantAt(state, foe!) : null;
  const defeatedTarget = target !== null && target.currentHp === 0;
  if (aimsAtTarget) faintIfDown(context, foe!);
  faintIfDown(context, spot);
  if (defeatedTarget && author.currentHp > 0) applyDefeatTrait(context, spot);
}

/** `foe` é o adversário atingido; nulo numa Técnica em si mesmo sem adversário de pé. */
function useSkill(
  context: TurnContext,
  action: FieldAction,
  foe: Spot | null,
): void {
  const { events } = context;
  const { spot, skill, learned } = action;

  if (learned) learned.currentPp -= 1;
  events.push({
    type: 'skill_used',
    ...spot,
    skill_id: learned ? skill.id : null,
  });
  resolveSkill(context, spot, skill, foe);
}

/**
 * O que a Técnica faz depois de anunciada: proteção, bloqueio, precisão, dano
 * e efeitos, contra um adversário. `foe` é nulo numa Técnica em si mesmo sem
 * adversário. Não gasta PP nem confere desmaio.
 */
export function resolveSkill(
  context: TurnContext,
  spot: Spot,
  skill: BattleSkill,
  foe: Spot | null,
): void {
  const { state, events, random } = context;
  const author = combatantAt(state, spot);
  const target = foe && combatantAt(state, foe);
  const aimsAtTarget = skill.targetSlug !== 'self';

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

  const dealt = skill.power > 0 ? strike(context, spot, skill, foe!) : 0;
  if (dealt !== null) applyEffects(context, spot, foe, skill, dealt);
}

/** Aplica o dano no alvo; devolve o HP que ele perdeu, ou nulo se for imune. */
function strike(
  context: TurnContext,
  spot: Spot,
  skill: BattleSkill,
  foe: Spot,
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
    multiplier,
    is_critical: isCritical,
  });
  return dealt;
}
