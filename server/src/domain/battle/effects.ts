import { activeAt, combatantAt, isStanding, rollChance } from './field.js';
import { clampStage } from './stages.js';
import { applyStatus } from './status.js';
import type {
  BattleSkill,
  BattleSkillEffect,
  Spot,
  StageSlug,
  TurnContext,
} from './types.js';

/** Efeitos que valem sempre no autor, sem coluna de alvo no catálogo. */
const AUTHOR_EFFECTS = new Set(['heal', 'drain', 'recoil', 'self_damage']);

/**
 * `dealt` é o HP que a Técnica tirou do alvo. `foe` é o adversário que ela
 * atingiu; nulo sem nenhum de pé.
 */
export function applyEffects(
  context: TurnContext,
  author: Spot,
  foe: Spot | null,
  skill: BattleSkill,
  dealt: number,
): void {
  for (const effect of skill.effects) {
    const affected = isOnAuthor(effect, skill) ? author : foe;
    const creature = affected && activeAt(context.state, affected);
    if (!creature || !isStanding(creature)) continue;
    if (!rollChance(effect.chance / 100, context.random)) continue;
    applyEffect(context, effect, affected!, dealt);
  }
}

function isOnAuthor(effect: BattleSkillEffect, skill: BattleSkill): boolean {
  return (
    AUTHOR_EFFECTS.has(effect.effectSlug) ||
    (effect.targetSlug ?? skill.targetSlug) === 'self'
  );
}

function applyEffect(
  context: TurnContext,
  effect: BattleSkillEffect,
  spot: Spot,
  dealt: number,
): void {
  const creature = combatantAt(context.state, spot);
  const percent = effect.percent ?? 0;
  switch (effect.effectSlug) {
    case 'apply_status':
      applyStatus(context, spot, effect.statusSlug!);
      break;
    case 'flinch':
      creature.isFeared = true;
      break;
    case 'modify_stat':
      if (!changeStage(context, spot, effect.statSlug!, effect.stages!)) {
        context.events.push({ type: 'effect_failed', ...spot });
      }
      break;
    case 'heal':
      if (!restoreHp(context, spot, portion(creature.stats.hp, percent))) {
        context.events.push({ type: 'effect_failed', ...spot });
      }
      break;
    case 'drain':
      restoreHp(context, spot, portion(dealt, percent));
      break;
    case 'recoil':
      hurtAuthor(context, spot, portion(dealt, percent));
      break;
    case 'self_damage':
      hurtAuthor(context, spot, portion(creature.stats.hp, percent));
      break;
  }
}

/** Muda o estágio dentro dos limites; devolve falso se já estava no limite. */
export function changeStage(
  context: TurnContext,
  spot: Spot,
  stat: StageSlug,
  stages: number,
): boolean {
  const creature = combatantAt(context.state, spot);
  const value = clampStage(creature.stages[stat] + stages);
  const change = value - creature.stages[stat];
  if (change === 0) return false;
  creature.stages[stat] = value;
  context.events.push({
    type: 'stat_changed',
    ...spot,
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
function restoreHp(context: TurnContext, spot: Spot, amount: number): boolean {
  const creature = combatantAt(context.state, spot);
  const healed = Math.min(amount, creature.stats.hp - creature.currentHp);
  // Um ajuste no painel pode deixar o HP atual acima do novo máximo.
  if (healed <= 0) return false;
  creature.currentHp += healed;
  context.events.push({
    type: 'healed',
    ...spot,
    amount: healed,
    hp: creature.currentHp,
  });
  return true;
}

function hurtAuthor(context: TurnContext, spot: Spot, amount: number): void {
  const creature = combatantAt(context.state, spot);
  const damage = Math.min(amount, creature.currentHp);
  creature.currentHp -= damage;
  context.events.push({
    type: 'recoil',
    ...spot,
    damage,
    hp: creature.currentHp,
  });
}
