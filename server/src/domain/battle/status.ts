import { calculateDamage, rollDamageFactor } from './damage.js';
import { awardXp } from './experience.js';
import { combatantAt, rollChance } from './field.js';
import type {
  BattleSkill,
  CannotActReason,
  Combatant,
  Random,
  Spot,
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
  areaShape: 'single',
  range: 1,
  pierces: false,
  groundEffectId: null,
  groundTurns: null,
};

export function rollSleepTurns(random: Random): number {
  return 1 + Math.floor(random() * MAX_SLEEP_TURNS);
}

/** Confere, na ordem, o que impede a criatura de agir neste turno. */
export function canAct(context: TurnContext, spot: Spot): boolean {
  const creature = combatantAt(context.state, spot);
  if (creature.isFeared) return loseTurn(context, spot, 'fear');
  if (creature.statusSlug === 'freeze' && !thaw(context, spot)) return false;
  if (creature.statusSlug === 'sleep' && !wakeUp(context, spot)) return false;
  if (
    creature.statusSlug === 'paralysis' &&
    rollChance(PARALYSIS_CHANCE, context.random)
  ) {
    return loseTurn(context, spot, 'paralysis');
  }
  return creature.confusionTurns === 0 || !hitsItself(context, spot);
}

function loseTurn(
  context: TurnContext,
  spot: Spot,
  reason: CannotActReason,
): false {
  context.events.push({ type: 'cannot_act', ...spot, reason });
  return false;
}

function thaw(context: TurnContext, spot: Spot): boolean {
  if (!rollChance(THAW_CHANCE, context.random)) {
    return loseTurn(context, spot, 'freeze');
  }
  combatantAt(context.state, spot).statusSlug = null;
  context.events.push({ type: 'thawed', ...spot });
  return true;
}

function wakeUp(context: TurnContext, spot: Spot): boolean {
  const creature = combatantAt(context.state, spot);
  if (creature.sleepTurns > 0) {
    creature.sleepTurns -= 1;
    return loseTurn(context, spot, 'sleep');
  }
  creature.statusSlug = null;
  context.events.push({ type: 'woke_up', ...spot });
  return true;
}

/** Uma tentativa de agir sob confusão; ela dura esse número de tentativas. */
function hitsItself(context: TurnContext, spot: Spot): boolean {
  const { catalog, events, random } = context;
  const creature = combatantAt(context.state, spot);
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
      ...spot,
      damage: lost,
      hp: creature.currentHp,
    });
  }
  if (creature.confusionTurns === 0 && creature.currentHp > 0) {
    events.push({ type: 'status_ended', ...spot, status: 'confusion' });
  }
  return isHit;
}

/** Aplica o status; se não pegar, avisa com `effect_failed`. */
export function applyStatus(
  context: TurnContext,
  spot: Spot,
  statusSlug: string,
): void {
  const { catalog, events, random } = context;
  const creature = combatantAt(context.state, spot);
  const immuneElementIds = catalog.statusImmunities.get(statusSlug) ?? [];
  const isImmune = creature.elementIds.some((elementId) =>
    immuneElementIds.includes(elementId),
  );
  if (isImmune || !setStatus(creature, statusSlug, random)) {
    events.push({ type: 'effect_failed', ...spot });
    return;
  }
  events.push({ type: 'status_applied', ...spot, status: statusSlug });
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
export function faintIfDown(context: TurnContext, spot: Spot): void {
  const creature = combatantAt(context.state, spot);
  if (creature.currentHp > 0) return;
  creature.statusSlug = null;
  creature.sleepTurns = 0;
  clearVolatile(creature);
  context.events.push({ type: 'fainted', ...spot });
  if (spot.side === 'enemy') awardXp(context, creature);
}

/** A perda de HP da queimadura e do veneno, com o desmaio. */
export function applyStatusDamage(context: TurnContext, spot: Spot): void {
  const creature = combatantAt(context.state, spot);
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
      ...spot,
      status,
      damage,
      hp: creature.currentHp,
    });
    faintIfDown(context, spot);
  }
}
