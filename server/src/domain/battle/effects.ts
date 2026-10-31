import { activeOf, opponentOf, rollChance } from './field.js';
import { clampStage } from './stages.js';
import { applyStatus } from './status.js';
import type {
  BattleSkill,
  BattleSkillEffect,
  SideSlug,
  StageSlug,
  TurnContext,
} from './types.js';

/** Efeitos que valem sempre no autor, sem coluna de alvo no catálogo. */
const AUTHOR_EFFECTS = new Set(['heal', 'drain', 'recoil', 'self_damage']);

/** `dealt` é o HP que a Técnica tirou do alvo. */
export function applyEffects(
  context: TurnContext,
  side: SideSlug,
  skill: BattleSkill,
  dealt: number,
): void {
  for (const effect of skill.effects) {
    const affected = affectedSide(effect, skill, side);
    if (activeOf(context.state, affected).currentHp === 0) continue;
    if (!rollChance(effect.chance / 100, context.random)) continue;
    applyEffect(context, effect, affected, dealt);
  }
}

function affectedSide(
  effect: BattleSkillEffect,
  skill: BattleSkill,
  side: SideSlug,
): SideSlug {
  const isOnAuthor =
    AUTHOR_EFFECTS.has(effect.effectSlug) ||
    (effect.targetSlug ?? skill.targetSlug) === 'self';
  return isOnAuthor ? side : opponentOf(side);
}

function applyEffect(
  context: TurnContext,
  effect: BattleSkillEffect,
  side: SideSlug,
  dealt: number,
): void {
  const creature = activeOf(context.state, side);
  const percent = effect.percent ?? 0;
  switch (effect.effectSlug) {
    case 'apply_status':
      applyStatus(context, side, effect.statusSlug!);
      break;
    case 'flinch':
      creature.isFeared = true;
      break;
    case 'modify_stat':
      if (!changeStage(context, side, effect.statSlug!, effect.stages!)) {
        context.events.push({ type: 'effect_failed', side });
      }
      break;
    case 'heal':
      if (!restoreHp(context, side, portion(creature.stats.hp, percent))) {
        context.events.push({ type: 'effect_failed', side });
      }
      break;
    case 'drain':
      restoreHp(context, side, portion(dealt, percent));
      break;
    case 'recoil':
      hurtAuthor(context, side, portion(dealt, percent));
      break;
    case 'self_damage':
      hurtAuthor(context, side, portion(creature.stats.hp, percent));
      break;
  }
}

/** Muda o estágio dentro dos limites; devolve falso se já estava no limite. */
export function changeStage(
  context: TurnContext,
  side: SideSlug,
  stat: StageSlug,
  stages: number,
): boolean {
  const creature = activeOf(context.state, side);
  const value = clampStage(creature.stages[stat] + stages);
  const change = value - creature.stages[stat];
  if (change === 0) return false;
  creature.stages[stat] = value;
  context.events.push({
    type: 'stat_changed',
    side,
    stat,
    stages: change,
    value,
  });
  return true;
}

function portion(value: number, percent: number): number {
  return Math.max(1, Math.floor((value * percent) / 100));
}

/** Devolve falso se a criatura já estava com o HP cheio. */
function restoreHp(
  context: TurnContext,
  side: SideSlug,
  amount: number,
): boolean {
  const creature = activeOf(context.state, side);
  const healed = Math.min(amount, creature.stats.hp - creature.currentHp);
  if (healed === 0) return false;
  creature.currentHp += healed;
  context.events.push({
    type: 'healed',
    side,
    amount: healed,
    hp: creature.currentHp,
  });
  return true;
}

function hurtAuthor(
  context: TurnContext,
  side: SideSlug,
  amount: number,
): void {
  const creature = activeOf(context.state, side);
  const damage = Math.min(amount, creature.currentHp);
  creature.currentHp -= damage;
  context.events.push({
    type: 'recoil',
    side,
    damage,
    hp: creature.currentHp,
  });
}
