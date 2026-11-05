import { changeStage } from './effects.js';
import { combatantAt } from './field.js';
import type { Spot, TurnContext } from './types.js';

const ENTRY_SPEED_TRAIT = 'tailwind';
const DEFEAT_SPEED_TRAIT = 'instinct';

export function applyEntryTrait(context: TurnContext, spot: Spot): void {
  if (combatantAt(context.state, spot).traitSlug === ENTRY_SPEED_TRAIT) {
    changeStage(context, spot, 'spd', 1);
  }
}

/** Vale para quem derrotou um inimigo com uma Técnica. */
export function applyDefeatTrait(context: TurnContext, spot: Spot): void {
  if (combatantAt(context.state, spot).traitSlug === DEFEAT_SPEED_TRAIT) {
    changeStage(context, spot, 'spd', 1);
  }
}
