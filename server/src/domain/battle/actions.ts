import { critChance, hitChance } from './accuracy.js';
import { calculateDamage, rollDamageFactor, typeMultiplier } from './damage.js';
import { applyEffects } from './effects.js';
import {
  combatantAt,
  rollChance,
} from './field.js';
import type {
  BattleSkill,
  Spot,
  TurnContext,
} from './types.js';

const PROTECT_EFFECT = 'protect';

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
