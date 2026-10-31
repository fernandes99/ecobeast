import { executeAction, toFieldAction } from './actions.js';
import { chooseEnemyAction } from './ai.js';
import { hasPp } from './emergency.js';
import { activeOf, hasCreatureStanding, rollChance } from './field.js';
import { noStages } from './stages.js';
import { applyEndOfTurn, clearVolatile, rollSleepTurns } from './status.js';
import { applyEntryTrait } from './traits.js';
import { orderActions } from './turn-order.js';
import type {
  BattleAction,
  BattleCatalog,
  BattleEvent,
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
): BattleOutcome {
  const context: TurnContext = {
    state: {
      phase: 'choose_action',
      result: null,
      turn: 1,
      canFlee,
      player: newSide(player),
      enemy: newSide(enemy),
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
  }
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
  const { state, catalog, events, random } = context;
  if (!rollChance(FLEE_FAIL_CHANCE, random)) {
    endBattle(context, 'fled');
    return;
  }
  events.push({ type: 'flee_failed' });
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
