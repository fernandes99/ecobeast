import { NO_ITEM, resolveItem, type ItemEffect } from '../items/use-item.js';
import { isStanding, MAX_SLOTS } from './field.js';
import type {
  BattleAction,
  BattleCatalog,
  BattleItem,
  BattleResult,
  BattleSide,
  BattleState,
  Combatant,
} from './types.js';

export const FLEE_FAIL_CHANCE = 0.2;
export const NO_CREATURE = 'Esse Ecobeast não existe.';
export const CHOOSE_TARGET = 'Escolha o alvo.';

type ItemAction = Extract<BattleAction, { type: 'item' }>;

export interface BattleRefusal {
  error: string;
}

export function newSide(team: Combatant[], slots: number): BattleSide {
  const copy = structuredClone(team);
  const standing = copy.flatMap((creature, index) =>
    isStanding(creature) ? [index] : [],
  );
  const count = Math.min(Math.max(slots, 1), MAX_SLOTS);
  const activeIndices = Array.from(
    { length: count },
    (_, position) => standing[position] ?? null,
  );
  return { team: copy, activeIndices };
}

export function ownedItem(
  state: BattleState,
  itemId: number,
  catalog: BattleCatalog,
): BattleItem | null {
  const owned = state.bag.some(
    (slot) => slot.itemId === itemId && slot.quantity > 0,
  );
  return owned ? (catalog.items.get(itemId) ?? null) : null;
}

export function itemEffect(
  state: BattleState,
  action: ItemAction,
  catalog: BattleCatalog,
): ItemEffect | { error: string } {
  const item = ownedItem(state, action.item_id, catalog);
  if (!item) return { error: NO_ITEM };
  const target = state.player.team[action.team_index];
  if (!target) return { error: NO_CREATURE };
  return resolveItem(item, {
    currentHp: target.currentHp,
    maxHp: target.stats.hp,
    hasStatus: target.statusSlug !== null,
  });
}

export function skillRefusal(
  combatant: Combatant,
  slot: number,
  catalog: BattleCatalog,
): string | null {
  const learned = combatant.skills[slot - 1];
  if (!learned || !catalog.skills.has(learned.skillId)) {
    return 'Essa Técnica não existe.';
  }
  return learned.currentPp > 0 ? null : 'Essa Técnica está sem PP.';
}

export function switchRefusal(
  state: BattleState,
  teamIndex: number,
): string | null {
  const chosen = state.player.team[teamIndex];
  return chosen && chosen.currentHp > 0
    ? null
    : 'Esse Ecobeast não pode lutar.';
}

export function inFieldRefusal(
  state: BattleState,
  teamIndex: number,
): string | null {
  return state.player.activeIndices.includes(teamIndex)
    ? 'Esse Ecobeast já está em campo.'
    : null;
}

export function spendItem(state: BattleState, itemId: number): void {
  const slot = state.bag.find((bagItem) => bagItem.itemId === itemId)!;
  slot.quantity -= 1;
  slot.used += 1;
}

export function resultWithoutEnemies(state: BattleState): BattleResult {
  const anyFainted = state.enemy.team.some(
    (enemy) => enemy.currentHp === 0 && !enemy.captured,
  );
  return anyFainted ? 'victory' : 'captured';
}
