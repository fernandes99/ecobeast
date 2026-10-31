import { changeStage } from './effects.js';
import { activeOf } from './field.js';
import type { SideSlug, TurnContext } from './types.js';

const ENTRY_SPEED_TRAIT = 'tailwind';
const DEFEAT_SPEED_TRAIT = 'instinct';

export function applyEntryTrait(context: TurnContext, side: SideSlug): void {
  if (activeOf(context.state, side).traitSlug === ENTRY_SPEED_TRAIT) {
    changeStage(context, side, 'spd', 1);
  }
}

/** Vale para quem derrotou um inimigo com uma Técnica. */
export function applyDefeatTrait(context: TurnContext, side: SideSlug): void {
  if (activeOf(context.state, side).traitSlug === DEFEAT_SPEED_TRAIT) {
    changeStage(context, side, 'spd', 1);
  }
}
