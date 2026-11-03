import { calculateDamage, rollDamageFactor } from './damage.js';
import { awardXp } from './experience.js';
import { activeOf, rollChance } from './field.js';
import type {
  BattleSkill,
  CannotActReason,
  Combatant,
  Random,
  SideSlug,
  TurnContext,
} from './types.js';

const PARALYSIS_CHANCE = 0.25;
const THAW_CHANCE = 0.2;
const CONFUSED_HIT_CHANCE = 0.33;
const MAX_SLEEP_TURNS = 3;
const MIN_CONFUSION_TURNS = 2;
const MAX_CONFUSION_TURNS = 5;

/** Fração do HP máximo perdida no fim do turno. */
const END_OF_TURN_LOSS: Record<string, number> = {
  burn: 1 / 16,
  poison: 1 / 8,
};

/** O golpe de quem se atinge, se Confuso. Valores a revisar. */
const CONFUSED_HIT: BattleSkill = {
  id: 0,
  elementId: null,
  elementSlug: null,
  category: 'physical',
  power: 40,
  accuracy: 0,
  maxPp: 0,
  priority: 0,
  critStage: 0,
  targetSlug: 'self',
  effects: [],
};

export function rollSleepTurns(random: Random): number {
  return 1 + Math.floor(random() * MAX_SLEEP_TURNS);
}

/** Confere, na ordem, o que impede a criatura de agir neste turno. */
export function canAct(context: TurnContext, side: SideSlug): boolean {
  const creature = activeOf(context.state, side);
  if (creature.isFeared) return loseTurn(context, side, 'fear');
  if (creature.statusSlug === 'freeze' && !thaw(context, side)) return false;
  if (creature.statusSlug === 'sleep' && !wakeUp(context, side)) return false;
  if (
    creature.statusSlug === 'paralysis' &&
    rollChance(PARALYSIS_CHANCE, context.random)
  ) {
    return loseTurn(context, side, 'paralysis');
  }
  return creature.confusionTurns === 0 || !hitsItself(context, side);
}

function loseTurn(
  context: TurnContext,
  side: SideSlug,
  reason: CannotActReason,
): false {
  context.events.push({ type: 'cannot_act', side, reason });
  return false;
}

function thaw(context: TurnContext, side: SideSlug): boolean {
  if (!rollChance(THAW_CHANCE, context.random)) {
    return loseTurn(context, side, 'freeze');
  }
  activeOf(context.state, side).statusSlug = null;
  context.events.push({ type: 'thawed', side });
  return true;
}

function wakeUp(context: TurnContext, side: SideSlug): boolean {
  const creature = activeOf(context.state, side);
  if (creature.sleepTurns > 0) {
    creature.sleepTurns -= 1;
    return loseTurn(context, side, 'sleep');
  }
  creature.statusSlug = null;
  context.events.push({ type: 'woke_up', side });
  return true;
}

/** Uma tentativa de agir sob confusão; ela dura esse número de tentativas. */
function hitsItself(context: TurnContext, side: SideSlug): boolean {
  const { catalog, events, random } = context;
  const creature = activeOf(context.state, side);
  creature.confusionTurns -= 1;

  const isHit = rollChance(CONFUSED_HIT_CHANCE, random);
  if (isHit) {
    const damage = calculateDamage({
      attacker: creature,
      defender: creature,
      skill: CONFUSED_HIT,
      catalog,
      isCritical: false,
      randomFactor: rollDamageFactor(random),
    });
    const lost = Math.min(damage, creature.currentHp);
    creature.currentHp -= lost;
    events.push({
      type: 'confused_hit',
      side,
      damage: lost,
      hp: creature.currentHp,
    });
  }
  if (creature.confusionTurns === 0 && creature.currentHp > 0) {
    events.push({ type: 'status_ended', side, status: 'confusion' });
  }
  return isHit;
}

/** Aplica o status; se não pegar, avisa com `effect_failed`. */
export function applyStatus(
  context: TurnContext,
  side: SideSlug,
  statusSlug: string,
): void {
  const { catalog, events, random } = context;
  const creature = activeOf(context.state, side);
  const immuneElementIds = catalog.statusImmunities.get(statusSlug) ?? [];
  const isImmune = creature.elementIds.some((elementId) =>
    immuneElementIds.includes(elementId),
  );
  if (isImmune || !setStatus(creature, statusSlug, random)) {
    events.push({ type: 'effect_failed', side });
    return;
  }
  events.push({ type: 'status_applied', side, status: statusSlug });
}

function setStatus(
  creature: Combatant,
  statusSlug: string,
  random: Random,
): boolean {
  switch (statusSlug) {
    case 'confusion': {
      if (creature.confusionTurns > 0) return false;
      const range = MAX_CONFUSION_TURNS - MIN_CONFUSION_TURNS + 1;
      creature.confusionTurns =
        MIN_CONFUSION_TURNS + Math.floor(random() * range);
      return true;
    }
    case 'fear':
      creature.isFeared = true;
      return true;
    case 'trapped':
      creature.isTrapped = true;
      return true;
    default:
      if (creature.statusSlug !== null) return false;
      creature.statusSlug = statusSlug;
      if (statusSlug === 'sleep') creature.sleepTurns = rollSleepTurns(random);
      return true;
  }
}

export function clearVolatile(creature: Combatant): void {
  creature.confusionTurns = 0;
  creature.isFeared = false;
  creature.isTrapped = false;
  creature.isProtected = false;
}

/** Quem chegou a 0 HP desmaia, e o desmaio limpa todo o status. */
export function faintIfDown(context: TurnContext, side: SideSlug): void {
  const creature = activeOf(context.state, side);
  if (creature.currentHp > 0) return;
  creature.statusSlug = null;
  creature.sleepTurns = 0;
  clearVolatile(creature);
  context.events.push({ type: 'fainted', side });
  if (side === 'enemy') awardXp(context);
}

export function applyEndOfTurn(context: TurnContext, side: SideSlug): void {
  const creature = activeOf(context.state, side);
  const status = creature.statusSlug;
  const loss = status === null ? undefined : END_OF_TURN_LOSS[status];
  if (status !== null && loss !== undefined) {
    const damage = Math.min(
      Math.max(1, Math.floor(creature.stats.hp * loss)),
      creature.currentHp,
    );
    creature.currentHp -= damage;
    context.events.push({
      type: 'status_damage',
      side,
      status,
      damage,
      hp: creature.currentHp,
    });
    faintIfDown(context, side);
  }
  creature.isFeared = false;
  creature.isProtected = false;
}
