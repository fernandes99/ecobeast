import { splitXp, xpYield } from '../progression/xp.js';
import { MAX_LEVEL } from '../rules/xp-curve.js';
import { activeOf } from './field.js';
import type { SideSlug, TurnContext } from './types.js';

/**
 * Anota quem está em campo contra quem. O inimigo que entra começa com o
 * Ecobeast do jogador em campo; o do jogador que entra passa a contar para o
 * inimigo em campo.
 */
export function recordEntry(context: TurnContext, side: SideSlug): void {
  const { state } = context;
  const playerIndex = state.player.activeIndex;
  const enemy = activeOf(state, 'enemy');
  if (side === 'enemy') {
    enemy.foughtBy =
      activeOf(state, 'player').currentHp > 0 ? [playerIndex] : [];
  } else if (!enemy.foughtBy.includes(playerIndex)) {
    enemy.foughtBy.push(playerIndex);
  }
}

/**
 * Reparte o XP do inimigo em campo, que acabou de desmaiar, entre quem
 * esteve em campo contra ele, está de pé e não chegou ao nível 100.
 */
export function awardXp(context: TurnContext): void {
  const { state, catalog, events } = context;
  const enemy = activeOf(state, 'enemy');
  const receivers = [...enemy.foughtBy]
    .sort((a, b) => a - b)
    .filter((index) => {
      const creature = state.player.team[index]!;
      return creature.currentHp > 0 && creature.level < MAX_LEVEL;
    });
  if (receivers.length === 0) return;

  const total = xpYield(
    catalog.xpYields.get(enemy.speciesId) ?? 0,
    enemy.level,
  );
  const amount = splitXp(total, receivers.length);
  for (const index of receivers) {
    state.player.team[index]!.xpEarned += amount;
    events.push({ type: 'xp_gained', team_index: index, amount });
  }
}
