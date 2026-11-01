import {
  CANNOT_USE,
  NO_ITEM,
  resolveItem,
  type ItemEffect,
} from '../items/use-item.js';
import { executeAction, toFieldAction } from './actions.js';
import { chooseEnemyAction } from './ai.js';
import { captureChance, NOT_CAPTURABLE } from './capture.js';
import { hasPp } from './emergency.js';
import { activeOf, hasCreatureStanding, rollChance } from './field.js';
import { noStages } from './stages.js';
import { applyEndOfTurn, clearVolatile, rollSleepTurns } from './status.js';
import { applyEntryTrait } from './traits.js';
import { orderActions } from './turn-order.js';
import type {
  BattleAction,
  BattleBagItem,
  BattleCatalog,
  BattleEvent,
  BattleItem,
  BattleResult,
  BattleSide,
  BattleState,
  Combatant,
  Random,
  SideSlug,
  TurnContext,
} from './types.js';

/** Fixa por enquanto; a regra será revista, talvez com base no inimigo. */
const FLEE_FAIL_CHANCE = 0.2;
const NO_CREATURE = 'Esse Ecobeast não existe.';

type ItemAction = Extract<BattleAction, { type: 'item' }>;
type CaptureAction = Extract<BattleAction, { type: 'capture' }>;

export interface BattleOutcome {
  state: BattleState;
  events: BattleEvent[];
}

export interface BattleRefusal {
  error: string;
}

export function startBattle(
  player: Combatant[],
  enemy: Combatant[],
  canFlee: boolean,
  catalog: BattleCatalog,
  random: Random,
  bag: BattleBagItem[] = [],
): BattleOutcome {
  const context: TurnContext = {
    state: {
      phase: 'choose_action',
      result: null,
      turn: 1,
      canFlee,
      player: newSide(player),
      enemy: newSide(enemy),
      bag: structuredClone(bag),
    },
    catalog,
    random,
    events: [{ type: 'battle_started' }],
  };
  enterField(context, 'player');
  enterField(context, 'enemy');
  return { state: context.state, events: context.events };
}

/** Confere a ação e roda o turno numa cópia do estado recebido. */
export function applyAction(
  state: BattleState,
  action: BattleAction,
  catalog: BattleCatalog,
  random: Random,
): BattleOutcome | BattleRefusal {
  const error = refusalFor(state, action, catalog);
  if (error) return { error };

  const context: TurnContext = {
    state: structuredClone(state),
    catalog,
    random,
    events: [],
  };
  switch (action.type) {
    case 'switch':
      sendNextCreature(context, action.team_index);
      break;
    case 'flee':
      flee(context);
      break;
    case 'item':
      useBagItem(context, action);
      break;
    case 'capture':
      tryCapture(context, action);
      break;
    default:
      playTurn(context, action);
  }
  return { state: context.state, events: context.events };
}

function newSide(team: Combatant[]): BattleSide {
  const copy = structuredClone(team);
  return { team: copy, activeIndex: firstStandingIndex(copy) };
}

function firstStandingIndex(team: Combatant[]): number {
  return team.findIndex((creature) => creature.currentHp > 0);
}

function refusalFor(
  state: BattleState,
  action: BattleAction,
  catalog: BattleCatalog,
): string | null {
  if (state.phase === 'ended') return 'A batalha já terminou.';
  if (state.phase === 'choose_next') {
    return action.type === 'switch'
      ? switchRefusal(state, action.team_index)
      : 'Escolha o próximo Ecobeast.';
  }

  const active = activeOf(state, 'player');
  switch (action.type) {
    case 'skill':
      return skillRefusal(active, action.slot, catalog);
    case 'emergency':
      return hasPp(active) ? 'Ainda há Técnicas com PP.' : null;
    case 'flee':
      return state.canFlee && !active.isTrapped
        ? null
        : 'Não dá para fugir agora.';
    case 'switch':
      return 'Esse Ecobeast não pode lutar.';
    case 'item': {
      const effect = itemEffect(state, action, catalog);
      return 'error' in effect ? effect.error : null;
    }
    case 'capture':
      return captureRefusal(state, action, catalog);
  }
}

/** O item da `bag`, com ao menos uma unidade; nulo sem ele. */
function ownedItem(
  state: BattleState,
  itemId: number,
  catalog: BattleCatalog,
): BattleItem | null {
  const owned = state.bag.some(
    (slot) => slot.itemId === itemId && slot.quantity > 0,
  );
  return owned ? (catalog.items.get(itemId) ?? null) : null;
}

/** Confere o item e o alvo; não muda nada. */
function itemEffect(
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

function captureRefusal(
  state: BattleState,
  action: CaptureAction,
  catalog: BattleCatalog,
): string | null {
  const item = ownedItem(state, action.item_id, catalog);
  if (!item) return NO_ITEM;
  if (item.captureBonus === null) return CANNOT_USE;
  const rate = catalog.captureRates.get(activeOf(state, 'enemy').speciesId);
  return rate ? null : NOT_CAPTURABLE;
}

function skillRefusal(
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

function switchRefusal(state: BattleState, teamIndex: number): string | null {
  const chosen = state.player.team[teamIndex];
  return chosen && chosen.currentHp > 0
    ? null
    : 'Esse Ecobeast não pode lutar.';
}

function playTurn(context: TurnContext, action: BattleAction): void {
  const { state, catalog, random } = context;
  const enemyAction = chooseEnemyAction(state, catalog, random);
  const [first, second] = orderActions(
    toFieldAction(context, 'player', action),
    toFieldAction(context, 'enemy', enemyAction),
    random,
  );
  executeAction(context, first);
  executeAction(context, second);
  finishTurn(context, [first.side, second.side]);
}

function flee(context: TurnContext): void {
  const { events, random } = context;
  if (!rollChance(FLEE_FAIL_CHANCE, random)) {
    endBattle(context, 'fled');
    return;
  }
  events.push({ type: 'flee_failed' });
  playEnemyAlone(context);
}

/** O item gasta a rodada: faz efeito antes de qualquer ação do inimigo. */
function useBagItem(context: TurnContext, action: ItemAction): void {
  const { state, catalog, events } = context;
  // `refusalFor` já recusou o item que não pode ser usado.
  const effect = itemEffect(state, action, catalog) as ItemEffect;
  const target = state.player.team[action.team_index]!;
  const curedStatus = effect.curesStatus ? target.statusSlug : null;

  target.currentHp += effect.healed;
  if (effect.curesStatus) {
    target.statusSlug = null;
    target.sleepTurns = 0;
  }
  spendItem(state, action.item_id);
  events.push({
    type: 'item_used',
    side: 'player',
    item_id: action.item_id,
    team_index: action.team_index,
    healed: effect.healed,
    hp: target.currentHp,
    cured_status: curedStatus,
  });
  playEnemyAlone(context);
}

/** A Esfera é gasta com ou sem sucesso, e a falha gasta a rodada. */
function tryCapture(context: TurnContext, action: CaptureAction): void {
  const { state, catalog, random, events } = context;
  const enemy = activeOf(state, 'enemy');
  // `refusalFor` já recusou o item que não captura e a espécie sem taxa.
  const chance = captureChance({
    currentHp: enemy.currentHp,
    maxHp: enemy.stats.hp,
    captureRate: catalog.captureRates.get(enemy.speciesId)!,
    captureBonus: catalog.items.get(action.item_id)!.captureBonus!,
    statusSlug: enemy.statusSlug,
  });
  spendItem(state, action.item_id);
  const success = rollChance(chance, random);
  events.push({ type: 'capture_attempted', item_id: action.item_id, success });
  if (success) endBattle(context, 'captured');
  else playEnemyAlone(context);
}

function spendItem(state: BattleState, itemId: number): void {
  const slot = state.bag.find((bagItem) => bagItem.itemId === itemId)!;
  slot.quantity -= 1;
  slot.used += 1;
}

function playEnemyAlone(context: TurnContext): void {
  const { state, catalog, random } = context;
  const enemyAction = chooseEnemyAction(state, catalog, random);
  executeAction(context, toFieldAction(context, 'enemy', enemyAction));
  finishTurn(context, ['player', 'enemy']);
}

function sendNextCreature(context: TurnContext, teamIndex: number): void {
  context.state.player.activeIndex = teamIndex;
  context.state.phase = 'choose_action';
  enterField(context, 'player');
}

/** `order` é a ordem em que as criaturas agiram. */
function finishTurn(context: TurnContext, order: SideSlug[]): void {
  order.forEach((side) => applyEndOfTurn(context, side));
  checkEnd(context);
}

function checkEnd(context: TurnContext): void {
  const { state } = context;
  if (!hasCreatureStanding(state, 'enemy')) {
    endBattle(context, 'victory');
    return;
  }
  if (!hasCreatureStanding(state, 'player')) {
    endBattle(context, 'defeat');
    return;
  }

  state.turn += 1;
  if (activeOf(state, 'enemy').currentHp === 0) {
    state.enemy.activeIndex = firstStandingIndex(state.enemy.team);
    enterField(context, 'enemy');
  }
  state.phase =
    activeOf(state, 'player').currentHp === 0 ? 'choose_next' : 'choose_action';
}

function endBattle(context: TurnContext, result: BattleResult): void {
  const { state, events } = context;
  state.phase = 'ended';
  state.result = result;
  clearVolatile(activeOf(state, 'player'));
  clearVolatile(activeOf(state, 'enemy'));
  events.push({ type: 'battle_ended', result });
}

function enterField(context: TurnContext, side: SideSlug): void {
  const creature = activeOf(context.state, side);
  creature.stages = noStages();
  clearVolatile(creature);
  if (creature.statusSlug === 'sleep') {
    creature.sleepTurns = rollSleepTurns(context.random);
  }
  context.events.push({
    type: 'creature_entered',
    side,
    species_id: creature.speciesId,
    level: creature.level,
    max_hp: creature.stats.hp,
  });
  applyEntryTrait(context, side);
}
