import {
  COINS_LOSS_BASE,
  COINS_WIN_BASE,
  lostCoins,
  TAMER_COINS_LOSS_BASE,
  TAMER_COINS_WIN_BASE,
  winCoins,
} from '../progression/coins.js';
import { splitXp, TAMER_XP_MULTIPLIER, xpYield } from '../progression/xp.js';
import { MAX_LEVEL } from '../rules/xp-curve.js';
import {
  activeAt,
  combatantAt,
  occupiedSpots,
  standingSpots,
} from './field.js';
import type {
  BattleResult,
  BattleState,
  Combatant,
  SideSlug,
  Spot,
  TurnContext,
} from './types.js';

export function recordEntry(context: TurnContext, spot: Spot): void {
  const { state } = context;
  if (spot.side === 'enemy') {
    combatantAt(state, spot).foughtBy = standingSpots(state, 'player').map(
      ({ position }) => state.player.activeIndices[position]!,
    );
    return;
  }
  const playerIndex = state.player.activeIndices[spot.position]!;
  for (const enemySpot of occupiedSpots(state, 'enemy')) {
    const enemy = combatantAt(state, enemySpot);
    if (!enemy.foughtBy.includes(playerIndex)) enemy.foughtBy.push(playerIndex);
  }
}

export function awardXp(context: TurnContext, enemy: Combatant): void {
  const { state, catalog, events } = context;
  const receivers = [...enemy.foughtBy]
    .sort((a, b) => a - b)
    .filter((index) => {
      const creature = state.player.team[index]!;
      return creature.currentHp > 0 && creature.level < MAX_LEVEL;
    });
  if (receivers.length === 0) return;

  const wildTotal = xpYield(
    catalog.xpYields.get(enemy.speciesId) ?? 0,
    enemy.level,
  );
  const total =
    state.opponent === 'tamer'
      ? Math.floor(wildTotal * TAMER_XP_MULTIPLIER)
      : wildTotal;
  const amount = splitXp(total, receivers.length);
  for (const index of receivers) {
    state.player.team[index]!.xpEarned += amount;
    events.push({ type: 'xp_gained', team_index: index, amount });
  }
}

export function settleCoins(
  context: TurnContext,
  result: BattleResult,
  fielders: Combatant[] = fieldCreatures(context.state, 'player'),
): void {
  const { state, events, random } = context;
  const fielderLevel = averageLevel(fielders);
  const tamer = state.opponent === 'tamer';
  if (result === 'victory') {
    for (const enemy of state.enemy.team) {
      if (enemy.currentHp > 0 || enemy.captured) continue;
      const amount = winCoins(
        enemy.level,
        fielderLevel,
        random,
        tamer ? TAMER_COINS_WIN_BASE : COINS_WIN_BASE,
      );
      state.coinsChange += amount;
      events.push({
        type: 'coins_gained',
        amount,
        species_id: enemy.speciesId,
      });
    }
  } else if (result === 'defeat') {
    const enemies = fieldCreatures(state, 'enemy');
    const amount = lostCoins(
      averageLevel(enemies),
      fielderLevel,
      state.coins,
      random,
      tamer ? TAMER_COINS_LOSS_BASE : COINS_LOSS_BASE,
    );
    if (amount === 0) return;
    state.coinsChange = -amount;
    events.push({
      type: 'coins_lost',
      amount,
      species_ids: enemies.map((enemy) => enemy.speciesId),
    });
  }
}

function fieldCreatures(state: BattleState, side: SideSlug): Combatant[] {
  return occupiedSpots(state, side)
    .map((spot) => activeAt(state, spot)!)
    .filter((creature) => !creature.captured);
}

/** A média dos níveis, arredondada para baixo; 1 sem ninguém, para não dividir por 0. */
function averageLevel(creatures: Combatant[]): number {
  const total = creatures.reduce((sum, creature) => sum + creature.level, 0);
  return Math.max(1, Math.floor(total / Math.max(1, creatures.length)));
}
