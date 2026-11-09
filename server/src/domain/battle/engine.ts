import {
  CANNOT_USE,
  NO_ITEM,
  resolveItem,
  type ItemEffect,
} from '../items/use-item.js';
import { executeAction, toFieldAction, type FieldAction } from './actions.js';
import { chooseEnemyAction } from './ai.js';
import { captureChance, NOT_CAPTURABLE } from './capture.js';
import { hasPp } from './emergency.js';
import { recordEntry, settleCoins } from './experience.js';
import {
  activeAt,
  combatantAt,
  hasCreatureStanding,
  isStanding,
  MAX_SLOTS,
  occupiedSpots,
  reserveIndices,
  rollChance,
  standingSpots,
} from './field.js';
import { noStages } from './stages.js';
import { applyEndOfTurn, clearVolatile, rollSleepTurns } from './status.js';
import { applyEntryTrait } from './traits.js';
import { orderTurn } from './turn-order.js';
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
  Spot,
  TurnContext,
} from './types.js';

/** Fixa por enquanto; a regra será revista, talvez com base no inimigo. */
export const FLEE_FAIL_CHANCE = 0.2;
export const NO_CREATURE = 'Esse Ecobeast não existe.';
export const EVERY_SLOT = 'Escolha uma ação para cada Ecobeast em campo.';
export const CHOOSE_TARGET = 'Escolha o alvo.';
export const NO_TARGET = 'Esse alvo não está na luta.';
export const FLEE_ALONE = 'Fugir vale para a equipe toda.';
export const ALREADY_ENTERING = 'Esse Ecobeast já vai entrar.';

type ItemAction = Extract<BattleAction, { type: 'item' }>;
type CaptureAction = Extract<BattleAction, { type: 'capture' }>;
/** Uma ação com a posição de quem age já preenchida. */
type PlacedAction = BattleAction & { position: number };

export interface BattleOutcome {
  state: BattleState;
  events: BattleEvent[];
}

export interface BattleRefusal {
  error: string;
}

export interface BattleOptions {
  godMode?: boolean;
  coins?: number;
  /** Vagas de cada lado, de 1 a `MAX_SLOTS`; 1 e 1 por padrão. */
  slots?: { player: number; enemy: number };
  /** Vagas livres na equipe do jogador, para onde vão os capturados. */
  partyFree?: number;
}

export function startBattle(
  player: Combatant[],
  enemy: Combatant[],
  canFlee: boolean,
  catalog: BattleCatalog,
  random: Random,
  bag: BattleBagItem[] = [],
  {
    godMode = false,
    coins = 0,
    slots = { player: 1, enemy: 1 },
    partyFree = 0,
  }: BattleOptions = {},
): BattleOutcome {
  const context: TurnContext = {
    state: {
      phase: 'choose_action',
      result: null,
      turn: 1,
      canFlee,
      // A luta antiga não tem tela, e continua só contra selvagens.
      opponent: 'wild',
      player: newSide(player, slots.player),
      enemy: newSide(enemy, slots.enemy),
      pendingPositions: [],
      bag: structuredClone(bag),
      godMode,
      coins,
      coinsChange: 0,
      partyFree,
    },
    catalog,
    random,
    events: [{ type: 'battle_started' }],
  };
  for (const side of ['player', 'enemy'] as const) {
    for (const spot of occupiedSpots(context.state, side)) {
      enterField(context, spot);
    }
  }
  return { state: context.state, events: context.events };
}

/**
 * Confere as ações e roda o turno numa cópia do estado recebido. Uma ação
 * sozinha vale como a lista dela, na posição 0.
 */
export function applyAction(
  state: BattleState,
  received: BattleAction | BattleAction[],
  catalog: BattleCatalog,
  random: Random,
): BattleOutcome | BattleRefusal {
  const actions: PlacedAction[] = [received]
    .flat()
    .map((action) => ({ ...action, position: action.position ?? 0 }))
    .sort((a, b) => a.position - b.position);
  const error = refusalFor(state, actions, catalog);
  if (error) return { error };

  const context: TurnContext = {
    state: structuredClone(state),
    catalog,
    random,
    events: [],
  };
  if (state.phase === 'choose_next') {
    sendNextCreatures(context, actions);
  } else if (actions[0]!.type === 'flee') {
    flee(context);
  } else {
    playTurn(context, actions);
  }
  return { state: context.state, events: context.events };
}

/** Cada vaga recebe, em ordem, o próximo de pé da equipe; sobrando vaga, ela fica vazia. */
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

function playerSpot(position: number): Spot {
  return { side: 'player', position };
}

function refusalFor(
  state: BattleState,
  actions: PlacedAction[],
  catalog: BattleCatalog,
): string | null {
  if (state.phase === 'ended') return 'A batalha já terminou.';
  if (state.phase === 'choose_next') return nextRefusal(state, actions);

  if (actions.some((action) => action.type === 'flee')) {
    if (actions.length !== 1) return FLEE_ALONE;
    const trapped = standingSpots(state, 'player').some(
      (spot) => combatantAt(state, spot).isTrapped,
    );
    return state.canFlee && !trapped ? null : 'Não dá para fugir agora.';
  }
  const expected = standingSpots(state, 'player').map((spot) => spot.position);
  const positions = actions.map((action) => action.position);
  if (positions.join() !== expected.join()) return EVERY_SLOT;

  for (const action of actions) {
    const error = actionRefusal(state, action, catalog);
    if (error) return error;
  }
  const entering = actions.flatMap((action) =>
    action.type === 'switch' ? [action.team_index] : [],
  );
  if (new Set(entering).size !== entering.length) return ALREADY_ENTERING;
  return itemsRefusal(state, actions);
}

function actionRefusal(
  state: BattleState,
  action: PlacedAction,
  catalog: BattleCatalog,
): string | null {
  const active = combatantAt(state, playerSpot(action.position));
  switch (action.type) {
    case 'skill': {
      const refusal = skillRefusal(active, action.slot, catalog);
      if (refusal) return refusal;
      const skill = catalog.skills.get(
        active.skills[action.slot - 1]!.skillId,
      )!;
      return skill.targetSlug === 'self'
        ? null
        : targetRefusal(state, action.target);
    }
    case 'emergency':
      return hasPp(active)
        ? 'Ainda há Técnicas com PP.'
        : targetRefusal(state, action.target);
    case 'flee':
      return FLEE_ALONE;
    case 'switch':
      return fieldSwitchRefusal(state, action);
    case 'item': {
      const effect = itemEffect(state, action, catalog);
      return 'error' in effect ? effect.error : null;
    }
    case 'capture':
      return captureRefusal(state, action, catalog);
  }
}

/** O alvo escolhido, obrigatório só com mais de um adversário de pé. */
function targetRefusal(
  state: BattleState,
  target: number | undefined,
): string | null {
  const standing = standingSpots(state, 'enemy').map((spot) => spot.position);
  if (target === undefined) return standing.length > 1 ? CHOOSE_TARGET : null;
  return standing.includes(target) ? null : NO_TARGET;
}

/** Dois do mesmo item no mesmo turno precisam de duas unidades. */
function itemsRefusal(
  state: BattleState,
  actions: PlacedAction[],
): string | null {
  const wanted = new Map<number, number>();
  for (const action of actions) {
    if (action.type !== 'item' && action.type !== 'capture') continue;
    wanted.set(action.item_id, (wanted.get(action.item_id) ?? 0) + 1);
  }
  for (const [itemId, count] of wanted) {
    const slot = state.bag.find((bagItem) => bagItem.itemId === itemId);
    if (!slot || slot.quantity < count) return NO_ITEM;
  }
  return null;
}

/** Um `switch` por vaga que espera quem entra, e só isso. */
function nextRefusal(
  state: BattleState,
  actions: PlacedAction[],
): string | null {
  if (actions.some((action) => action.type !== 'switch')) {
    return 'Escolha o próximo Ecobeast.';
  }
  const positions = actions.map((action) => action.position);
  if (positions.join() !== state.pendingPositions.join()) {
    return 'Escolha o próximo Ecobeast.';
  }
  const entering: number[] = [];
  for (const action of actions as Extract<PlacedAction, { type: 'switch' }>[]) {
    const refusal =
      switchRefusal(state, action.team_index) ??
      inFieldRefusal(state, action.team_index);
    if (refusal) return refusal;
    if (entering.includes(action.team_index)) return ALREADY_ENTERING;
    entering.push(action.team_index);
  }
  return null;
}

/** O item da `bag`, com ao menos uma unidade; nulo sem ele. */
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

/** Confere o item e o alvo; não muda nada. */
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

function captureRefusal(
  state: BattleState,
  action: CaptureAction,
  catalog: BattleCatalog,
): string | null {
  const item = ownedItem(state, action.item_id, catalog);
  if (!item) return NO_ITEM;
  if (item.captureBonus === null) return CANNOT_USE;
  const refusal = targetRefusal(state, action.target);
  if (refusal) return refusal;
  const rate = catalog.captureRates.get(captureTarget(state, action).speciesId);
  return rate ? null : NOT_CAPTURABLE;
}

/** O inimigo que a Esfera mira: o escolhido ou o único de pé. */
function captureTarget(state: BattleState, action: CaptureAction): Combatant {
  const position = action.target ?? standingSpots(state, 'enemy')[0]!.position;
  return combatantAt(state, { side: 'enemy', position });
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

/** A troca por vontade própria, com alguém de pé na vaga. */
function fieldSwitchRefusal(
  state: BattleState,
  action: Extract<PlacedAction, { type: 'switch' }>,
): string | null {
  const refusal =
    switchRefusal(state, action.team_index) ??
    inFieldRefusal(state, action.team_index);
  if (refusal) return refusal;
  return combatantAt(state, playerSpot(action.position)).isTrapped
    ? 'Não dá para trocar agora.'
    : null;
}

/**
 * Troca, item e Esfera vêm antes de qualquer Técnica, em ordem de posição.
 * Depois, as Técnicas dos dois lados são ordenadas juntas.
 */
function playTurn(context: TurnContext, actions: PlacedAction[]): void {
  const acted: Spot[] = [];
  const skills: FieldAction[] = [];
  for (const action of actions) {
    const spot = playerSpot(action.position);
    switch (action.type) {
      case 'switch':
        switchCreature(context, spot, action.team_index);
        acted.push(spot);
        break;
      case 'item':
        useBagItem(context, spot, action);
        acted.push(spot);
        break;
      case 'capture':
        tryCapture(context, action);
        acted.push(spot);
        if (context.state.phase === 'ended') return;
        break;
      default:
        skills.push(toFieldAction(context, spot, action));
    }
  }
  runSkills(context, acted, skills);
}

/** Os inimigos escolhem, e todas as Técnicas acontecem na ordem do turno. */
function runSkills(
  context: TurnContext,
  acted: Spot[],
  playerSkills: FieldAction[],
): void {
  const { state, catalog, random } = context;
  const skills = [...playerSkills];
  for (const spot of standingSpots(state, 'enemy')) {
    const enemyAction = chooseEnemyAction(state, catalog, random, spot);
    skills.push(toFieldAction(context, spot, enemyAction));
  }
  const ordered = orderTurn(skills, random);
  for (const action of ordered) executeAction(context, action);
  finishTurn(context, [...acted, ...ordered.map((action) => action.spot)]);
}

function flee(context: TurnContext): void {
  const { events, random } = context;
  if (!rollChance(FLEE_FAIL_CHANCE, random)) {
    endBattle(context, 'fled');
    return;
  }
  events.push({ type: 'flee_failed' });
  runSkills(context, [playerSpot(0)], []);
}

/** O item gasta a ação: faz efeito antes de qualquer Técnica. */
function useBagItem(
  context: TurnContext,
  spot: Spot,
  action: ItemAction,
): void {
  const { state, catalog, events } = context;
  const effect = itemEffect(state, action, catalog);
  // Outro item do mesmo turno pode ter deixado este sem efeito.
  if ('error' in effect) return;
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
    position: spot.position,
    item_id: action.item_id,
    team_index: action.team_index,
    healed: effect.healed,
    hp: target.currentHp,
    cured_status: curedStatus,
  });
}

/**
 * A Esfera é gasta com ou sem sucesso. O capturado sai da luta, que só
 * termina, sem fim de turno, se não sobrar inimigo de pé.
 */
function tryCapture(context: TurnContext, action: CaptureAction): void {
  const { state, catalog, random, events } = context;
  // Outra Esfera do mesmo turno pode já ter capturado o alvo.
  if (!standingSpots(state, 'enemy').length) return;
  const enemy = captureTarget(state, action);
  if (!isStanding(enemy)) return;
  const target = state.enemy.activeIndices.indexOf(
    state.enemy.team.indexOf(enemy),
  );
  const chance = captureChance({
    currentHp: enemy.currentHp,
    maxHp: enemy.stats.hp,
    captureRate: catalog.captureRates.get(enemy.speciesId)!,
    captureBonus: catalog.items.get(action.item_id)!.captureBonus!,
    statusSlug: enemy.statusSlug,
  });
  spendItem(state, action.item_id);
  const success = rollChance(chance, random);
  let capturedTo: 'party' | 'storage' | null = null;
  if (success) {
    enemy.captured = true;
    capturedTo = state.partyFree > 0 ? 'party' : 'storage';
    if (capturedTo === 'party') state.partyFree -= 1;
  }
  events.push({
    type: 'capture_attempted',
    item_id: action.item_id,
    success,
    target,
    captured_to: capturedTo,
  });
  if (success && !hasCreatureStanding(state, 'enemy')) {
    endBattle(context, resultWithoutEnemies(state));
  }
}

export function spendItem(state: BattleState, itemId: number): void {
  const slot = state.bag.find((bagItem) => bagItem.itemId === itemId)!;
  slot.quantity -= 1;
  slot.used += 1;
}

/** No `choose_next`, cada vaga recebe quem o jogador escolheu, sem gastar turno. */
function sendNextCreatures(
  context: TurnContext,
  actions: PlacedAction[],
): void {
  const { state } = context;
  state.phase = 'choose_action';
  state.pendingPositions = [];
  for (const action of actions as Extract<PlacedAction, { type: 'switch' }>[]) {
    state.player.activeIndices[action.position] = action.team_index;
    enterField(context, playerSpot(action.position));
  }
}

/** A troca gasta a ação: quem entra chega antes de qualquer Técnica. */
function switchCreature(
  context: TurnContext,
  spot: Spot,
  teamIndex: number,
): void {
  context.state.player.activeIndices[spot.position] = teamIndex;
  enterField(context, spot);
}

/**
 * `order` é a ordem em que as criaturas agiram. Quem não agiu entra depois,
 * primeiro o jogador, em ordem de posição.
 */
function finishTurn(context: TurnContext, order: Spot[]): void {
  const { state } = context;
  const all = [
    ...order,
    ...occupiedSpots(state, 'player'),
    ...occupiedSpots(state, 'enemy'),
  ];
  const seen = new Set<string>();
  for (const spot of all) {
    const key = `${spot.side}:${spot.position}`;
    const creature = activeAt(state, spot);
    if (seen.has(key) || !creature || creature.captured) continue;
    seen.add(key);
    applyEndOfTurn(context, spot);
  }
  checkEnd(context);
}

function checkEnd(context: TurnContext): void {
  const { state } = context;
  if (!hasCreatureStanding(state, 'enemy')) {
    endBattle(context, resultWithoutEnemies(state));
    return;
  }
  if (!hasCreatureStanding(state, 'player')) {
    endBattle(context, 'defeat');
    return;
  }

  state.turn += 1;
  refillEnemy(context);
  state.pendingPositions = playerVacancies(context);
  state.phase =
    state.pendingPositions.length > 0 ? 'choose_next' : 'choose_action';
}

/** Vitória se algum inimigo desmaiou; com todos capturados, captura. */
export function resultWithoutEnemies(state: BattleState): BattleResult {
  const anyFainted = state.enemy.team.some(
    (enemy) => enemy.currentHp === 0 && !enemy.captured,
  );
  return anyFainted ? 'victory' : 'captured';
}

/** Cada vaga do inimigo sem ninguém de pé recebe o próximo da reserva, ou fica vazia. */
function refillEnemy(context: TurnContext): void {
  const { state } = context;
  for (const spot of occupiedSpots(state, 'enemy')) {
    if (isStanding(combatantAt(state, spot))) continue;
    const next = reserveIndices(state, 'enemy')[0];
    if (next === undefined) {
      leaveField(context, spot);
    } else {
      state.enemy.activeIndices[spot.position] = next;
      enterField(context, spot);
    }
  }
}

/**
 * As vagas do jogador sem ninguém de pé, uma por reserva de pé, em ordem de
 * posição. As que sobram ficam vazias.
 */
function playerVacancies(context: TurnContext): number[] {
  const { state } = context;
  const reserves = reserveIndices(state, 'player').length;
  const pending: number[] = [];
  for (const spot of occupiedSpots(state, 'player')) {
    if (isStanding(combatantAt(state, spot))) continue;
    if (pending.length < reserves) pending.push(spot.position);
    else leaveField(context, spot);
  }
  return pending;
}

function leaveField(context: TurnContext, spot: Spot): void {
  context.state[spot.side].activeIndices[spot.position] = null;
  context.events.push({ type: 'creature_left', ...spot });
}

function endBattle(context: TurnContext, result: BattleResult): void {
  const { state, events } = context;
  state.phase = 'ended';
  state.result = result;
  state.pendingPositions = [];
  for (const side of ['player', 'enemy'] as SideSlug[]) {
    for (const spot of occupiedSpots(state, side)) {
      clearVolatile(combatantAt(state, spot));
    }
  }
  settleCoins(context, result);
  events.push({ type: 'battle_ended', result });
}

function enterField(context: TurnContext, spot: Spot): void {
  recordEntry(context, spot);
  const creature = combatantAt(context.state, spot);
  creature.stages = noStages();
  clearVolatile(creature);
  if (creature.statusSlug === 'sleep') {
    creature.sleepTurns = rollSleepTurns(context.random);
  }
  context.events.push({
    type: 'creature_entered',
    ...spot,
    team_index: context.state[spot.side].activeIndices[spot.position]!,
    species_id: creature.speciesId,
    level: creature.level,
    max_hp: creature.stats.hp,
    hp: creature.currentHp,
    status: creature.statusSlug,
  });
  applyEntryTrait(context, spot);
}
