import { resolveSkill } from '../battle/actions.js';
import { captureChance, NOT_CAPTURABLE } from '../battle/capture.js';
import { EMERGENCY_SKILL, hasPp } from '../battle/emergency.js';
import {
  CHOOSE_TARGET,
  FLEE_FAIL_CHANCE,
  inFieldRefusal,
  itemEffect,
  newSide,
  ownedItem,
  resultWithoutEnemies,
  skillRefusal,
  spendItem,
  switchRefusal,
  type BattleRefusal,
} from '../battle/engine.js';
import { recordEntry, settleCoins } from '../battle/experience.js';
import {
  combatantAt,
  hasCreatureStanding,
  isStanding,
  occupiedSpots,
  reserveIndices,
  rollChance,
} from '../battle/field.js';
import { noStages } from '../battle/stages.js';
import {
  applyStatusDamage,
  canAct,
  clearVolatile,
  faintIfDown,
  rollSleepTurns,
} from '../battle/status.js';
import { applyDefeatTrait, applyEntryTrait } from '../battle/traits.js';
import type {
  BattleBagItem,
  BattleCatalog,
  BattleEvent,
  BattleResult,
  BattleSkill,
  Combatant,
  Random,
  SideSlug,
  Spot,
} from '../battle/types.js';
import { CANNOT_USE, NO_ITEM } from '../items/use-item.js';
import { type HexCoord, hexKey } from '../exploration/hex.js';
import { areaOf, NO_ENEMY_THERE } from './areas.js';
import { chooseEnemyVez } from './board-ai.js';
import {
  cellOf,
  entryCellsFor,
  isFree,
  makeBoard,
  MOVE_RANGE,
  reachable,
  sameCell,
  spotAt,
  standingAt,
  standingOnBoard,
  startCell,
} from './board.js';
import { ageMarks, applyMarks, placeMarks } from './marks.js';
import { roundQueue } from './queue.js';
import type {
  BoardAction,
  BoardContext,
  BoardEntry,
  BoardInput,
  BoardState,
  BoardVez,
} from './types.js';

// O juiz da luta no tabuleiro (.specs/board-battle/02-board-engine.md).

export const NOT_YOUR_VEZ = 'Não é a vez desse Ecobeast.';
export const CANNOT_REACH = 'Não dá para chegar lá.';
export const FLEE_NO_MOVE = 'Fugir não combina com andar.';
export const ENTRY_NOT_FREE = 'Esse hexágono não está livre para entrar.';
const CHOOSE_NEXT = 'Escolha o próximo Ecobeast.';
const NOBODY_WAITING = 'Ninguém está esperando para entrar.';

type SkillAction = Extract<BoardAction, { type: 'skill' | 'emergency' }>;

export interface BoardOutcome {
  state: BoardState;
  events: BattleEvent[];
}

export interface BoardOptions {
  godMode?: boolean;
  coins?: number;
  /** Vagas de cada lado, de 1 a 3; 1 e 1 por padrão. */
  slots?: { player: number; enemy: number };
  partyFree?: number;
  canFlee?: boolean;
}

export function startBoardBattle(
  player: Combatant[],
  enemy: Combatant[],
  catalog: BattleCatalog,
  random: Random,
  bag: BattleBagItem[] = [],
  {
    godMode = false,
    coins = 0,
    slots = { player: 1, enemy: 1 },
    partyFree = 0,
    canFlee = true,
  }: BoardOptions = {},
): BoardOutcome {
  const playerSide = newSide(player, slots.player);
  const enemySide = newSide(enemy, slots.enemy);
  const state: BoardState = {
    phase: 'choose_action',
    result: null,
    turn: 0,
    canFlee,
    player: playerSide,
    enemy: enemySide,
    pendingPositions: [],
    bag: structuredClone(bag),
    godMode,
    coins,
    coinsChange: 0,
    partyFree,
    board: makeBoard(),
    cells: { player: [], enemy: [] },
    marks: [],
    round: 0,
    queue: [],
    entryCells: [],
  };
  const context: BoardContext = {
    state,
    catalog,
    random,
    events: [{ type: 'battle_started' }],
  };
  for (const side of ['player', 'enemy'] as SideSlug[]) {
    const count = state[side].activeIndices.length;
    state.cells[side] = state[side].activeIndices.map(() => null);
    for (const spot of occupiedSpots(state, side)) {
      enterBoard(context, spot, startCell(side, spot.position, count));
    }
  }
  advance(context);
  return { state: context.state, events: context.events };
}

/**
 * A vez do jogador, ou quem entra no `choose_next`. Confere tudo, joga numa
 * cópia do estado e segue com os selvagens até a próxima vez do jogador.
 */
export function applyBoardVez(
  state: BoardState,
  input: BoardInput,
  catalog: BattleCatalog,
  random: Random,
): BoardOutcome | BattleRefusal {
  const error = refusalFor(state, input, catalog);
  if (error) return { error };

  const context: BoardContext = {
    state: structuredClone(state),
    catalog,
    random,
    events: [],
  };
  if ('entries' in input) {
    sendEntries(context, input.entries);
  } else {
    playVez(context, { side: 'player', position: input.position }, input);
  }
  advance(context);
  return { state: context.state, events: context.events };
}

// --- Recusas ------------------------------------------------------------------

function refusalFor(
  state: BoardState,
  input: BoardInput,
  catalog: BattleCatalog,
): string | null {
  if (state.phase === 'ended') return 'A batalha já terminou.';
  if ('entries' in input) {
    return state.phase === 'choose_next'
      ? entriesRefusal(state, input.entries)
      : NOBODY_WAITING;
  }
  if (state.phase === 'choose_next') return CHOOSE_NEXT;

  const head = state.queue[0];
  if (!head || head.side !== 'player' || head.position !== input.position) {
    return NOT_YOUR_VEZ;
  }
  const spot: Spot = { side: 'player', position: input.position };
  let from = cellOf(state, spot)!;
  if (input.move) {
    if (input.action.type === 'flee') return FLEE_NO_MOVE;
    if (!sameCell(input.move, from)) {
      if (!reachable(state, from, MOVE_RANGE).has(hexKey(input.move))) {
        return CANNOT_REACH;
      }
      from = input.move;
    }
  }
  return actionRefusal(state, spot, from, input.action, catalog);
}

function actionRefusal(
  state: BoardState,
  spot: Spot,
  from: HexCoord,
  action: BoardAction,
  catalog: BattleCatalog,
): string | null {
  const creature = combatantAt(state, spot);
  switch (action.type) {
    case 'skill': {
      const refusal = skillRefusal(creature, action.slot, catalog);
      if (refusal) return refusal;
      const skill = catalog.skills.get(
        creature.skills[action.slot - 1]!.skillId,
      )!;
      return areaRefusal(state, spot, from, skill, action.target);
    }
    case 'emergency':
      return hasPp(creature)
        ? 'Ainda há Técnicas com PP.'
        : areaRefusal(state, spot, from, EMERGENCY_SKILL, action.target);
    case 'item': {
      const effect = itemEffect(state, action, catalog);
      return 'error' in effect ? effect.error : null;
    }
    case 'switch':
      return (
        switchRefusal(state, action.team_index) ??
        inFieldRefusal(state, action.team_index) ??
        (creature.isTrapped ? 'Não dá para trocar agora.' : null)
      );
    case 'capture':
      return captureRefusal(state, action, catalog);
    case 'flee': {
      const trapped = standingOnBoard(state, 'player').some(
        (other) => combatantAt(state, other).isTrapped,
      );
      return state.canFlee && !trapped ? null : 'Não dá para fugir agora.';
    }
    case 'wait':
      return null;
  }
}

function areaRefusal(
  state: BoardState,
  spot: Spot,
  from: HexCoord,
  skill: BattleSkill,
  target: HexCoord | undefined,
): string | null {
  if (skill.targetSlug === 'self') return null;
  const aim = target ?? onlyEnemyCell(state);
  if (!aim) return CHOOSE_TARGET;
  const area = areaOf(state, spot, from, skill, aim);
  return 'error' in area ? area.error : null;
}

/** Sem alvo escolhido, vale o único selvagem de pé no tabuleiro. */
function onlyEnemyCell(state: BoardState): HexCoord | undefined {
  const enemies = standingOnBoard(state, 'enemy');
  return enemies.length === 1 ? cellOf(state, enemies[0]!)! : undefined;
}

function captureRefusal(
  state: BoardState,
  action: Extract<BoardAction, { type: 'capture' }>,
  catalog: BattleCatalog,
): string | null {
  const item = ownedItem(state, action.item_id, catalog);
  if (!item) return NO_ITEM;
  if (item.captureBonus === null) return CANNOT_USE;
  const foe = spotAt(state, action.target);
  if (!foe || foe.side !== 'enemy' || !standingAt(state, foe)) {
    return NO_ENEMY_THERE;
  }
  const rate = catalog.captureRates.get(combatantAt(state, foe).speciesId);
  return rate ? null : NOT_CAPTURABLE;
}

function entriesRefusal(
  state: BoardState,
  entries: BoardEntry[],
): string | null {
  const sorted = [...entries].sort((a, b) => a.position - b.position);
  if (
    sorted.map((entry) => entry.position).join() !==
    state.pendingPositions.join()
  ) {
    return CHOOSE_NEXT;
  }
  const teamIndices = new Set<number>();
  const cells = new Set<string>();
  for (const entry of sorted) {
    const refusal =
      switchRefusal(state, entry.team_index) ??
      inFieldRefusal(state, entry.team_index);
    if (refusal) return refusal;
    if (teamIndices.has(entry.team_index))
      return 'Esse Ecobeast já vai entrar.';
    teamIndices.add(entry.team_index);
    const key = hexKey(entry.cell);
    const allowed = state.entryCells.some((cell) => sameCell(cell, entry.cell));
    if (!allowed || cells.has(key)) return ENTRY_NOT_FREE;
    cells.add(key);
  }
  return null;
}

// --- Rodada e vez -------------------------------------------------------------

/**
 * Joga as vezes dos selvagens até chegar a uma vez do jogador, um
 * `choose_next` ou o fim. A vez que começa avisa com `vez_started`.
 */
function advance(context: BoardContext): void {
  const { state, catalog, random } = context;
  while (state.phase === 'choose_action') {
    dropStale(state);
    if (state.queue.length === 0) {
      startRound(context);
      if (state.queue.length === 0) return;
      continue;
    }
    const head = state.queue[0]!;
    const spot: Spot = { side: head.side, position: head.position };
    combatantAt(state, spot).isProtected = false;
    context.events.push({ type: 'vez_started', ...spot });
    if (head.side === 'player') return;
    playVez(context, spot, chooseEnemyVez(state, catalog, random, spot));
  }
}

/** Quem caiu, saiu ou foi trocado depois que a rodada começou perde o lugar. */
function dropStale(state: BoardState): void {
  while (state.queue.length > 0) {
    const head = state.queue[0]!;
    const stillThere =
      state[head.side].activeIndices[head.position] === head.teamIndex &&
      standingAt(state, head);
    if (stillThere) return;
    state.queue.shift();
  }
}

function startRound(context: BoardContext): void {
  const { state, random, events } = context;
  state.round += 1;
  state.turn = state.round;
  state.queue = roundQueue(state, random);
  events.push({
    type: 'round_started',
    round: state.round,
    queue: state.queue.map(({ side, position }) => ({ side, position })),
  });
}

/**
 * Andar e depois agir. Quem dorme, está congelado, paralisado ou com medo
 * perde a vez inteira; item, troca, Esfera e fuga sem andar são do Domador e
 * não passam por isso, como na luta de hoje.
 */
function playVez(context: BoardContext, spot: Spot, vez: BoardVez): void {
  const { state, events } = context;
  const { action } = vez;
  const usesBody =
    vez.move !== undefined ||
    action.type === 'skill' ||
    action.type === 'emergency' ||
    action.type === 'wait';
  if (usesBody && !canAct(context, spot)) {
    faintIfDown(context, spot);
    endVez(context, spot);
    return;
  }

  const from = cellOf(state, spot)!;
  if (vez.move && !sameCell(vez.move, from)) {
    const path = reachable(state, from, MOVE_RANGE).get(hexKey(vez.move))!;
    state.cells[spot.side][spot.position] = vez.move;
    events.push({ type: 'moved', ...spot, path });
  }

  switch (action.type) {
    case 'skill':
    case 'emergency':
      useSkill(context, spot, action);
      break;
    case 'item':
      useItem(context, spot, action);
      break;
    case 'switch':
      // Quem entra fica no hexágono de quem saiu.
      state[spot.side].activeIndices[spot.position] = action.team_index;
      enterBoard(context, spot, cellOf(state, spot)!);
      break;
    case 'capture':
      tryCapture(context, action);
      break;
    case 'flee':
      if (!rollChance(FLEE_FAIL_CHANCE, context.random)) {
        endBattle(context, 'fled');
        return;
      }
      events.push({ type: 'flee_failed' });
      break;
    case 'wait':
      events.push({ type: 'waited', ...spot });
      break;
  }
  endVez(context, spot);
}

/**
 * Gasta o PP uma vez e atinge cada inimigo da área, com os próprios sorteios,
 * na ordem do caminho. A marca fica em toda a área.
 */
function useSkill(
  context: BoardContext,
  spot: Spot,
  action: SkillAction,
): void {
  const { state, catalog, events } = context;
  const author = combatantAt(state, spot);
  const learned =
    action.type === 'skill' ? author.skills[action.slot - 1]! : null;
  const skill = learned
    ? catalog.skills.get(learned.skillId)!
    : EMERGENCY_SKILL;
  const aim = action.target ?? onlyEnemyCell(state);
  const area = areaOf(state, spot, cellOf(state, spot)!, skill, aim);
  if ('error' in area) {
    // Só a IA chega aqui, e só se o tabuleiro mudou: ela espera.
    events.push({ type: 'waited', ...spot });
    return;
  }

  if (learned) learned.currentPp -= 1;
  events.push({
    type: 'skill_used',
    ...spot,
    skill_id: learned ? skill.id : null,
    cells: area.cells,
  });
  let defeated = false;
  if (skill.targetSlug === 'self') {
    resolveSkill(context, spot, skill, null);
  } else {
    for (const foe of area.foes) {
      if (!standingAt(state, foe) || !isStanding(author)) continue;
      resolveSkill(context, spot, skill, foe);
      if (combatantAt(state, foe).currentHp === 0) defeated = true;
      faintIfDown(context, foe);
    }
  }
  if (skill.groundEffectId !== null && skill.groundTurns !== null) {
    placeMarks(context, area.cells, skill.groundEffectId, skill.groundTurns);
  }
  faintIfDown(context, spot);
  if (defeated && author.currentHp > 0) applyDefeatTrait(context, spot);
}

function useItem(
  context: BoardContext,
  spot: Spot,
  action: Extract<BoardAction, { type: 'item' }>,
): void {
  const { state, catalog, events } = context;
  const effect = itemEffect(state, action, catalog);
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

/** A Esfera é gasta com ou sem sucesso; o capturado sai no fim da vez. */
function tryCapture(
  context: BoardContext,
  action: Extract<BoardAction, { type: 'capture' }>,
): void {
  const { state, catalog, random, events } = context;
  const foe = spotAt(state, action.target)!;
  const enemy = combatantAt(state, foe);
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
    target: foe.position,
    captured_to: capturedTo,
  });
}

// --- Fim da vez ---------------------------------------------------------------

/**
 * Status de quem jogou, marcas, envelhecer as marcas, quem caiu sai do
 * tabuleiro e as vagas são repostas, e o fim da luta.
 */
function endVez(context: BoardContext, actor: Spot): void {
  const { state } = context;
  state.queue.shift();
  if (standingAt(state, actor)) {
    applyStatusDamage(context, actor);
    combatantAt(state, actor).isFeared = false;
  }
  applyMarks(context);
  ageMarks(context);

  const vacated = leaveFallen(context);
  if (!hasCreatureStanding(state, 'enemy')) {
    endBattle(context, resultWithoutEnemies(state));
    return;
  }
  if (!hasCreatureStanding(state, 'player')) {
    endBattle(context, 'defeat');
    return;
  }
  refillEnemy(context, vacated.enemy);
  const reserves = reserveIndices(state, 'player').length;
  const pending = vacated.player.slice(0, reserves);
  if (pending.length > 0) {
    state.phase = 'choose_next';
    state.pendingPositions = pending;
    state.entryCells = entryCellsFor(state, 'player');
  }
}

/** Quem desmaiou ou foi capturado sai do tabuleiro; devolve as vagas que ficaram vazias. */
function leaveFallen(context: BoardContext): Record<SideSlug, number[]> {
  const { state, events } = context;
  const vacated: Record<SideSlug, number[]> = { player: [], enemy: [] };
  for (const side of ['player', 'enemy'] as SideSlug[]) {
    for (const spot of occupiedSpots(state, side)) {
      if (cellOf(state, spot) === null) continue;
      if (isStanding(combatantAt(state, spot))) continue;
      state.cells[side][spot.position] = null;
      state[side].activeIndices[spot.position] = null;
      events.push({ type: 'creature_left', ...spot });
      vacated[side].push(spot.position);
    }
  }
  return vacated;
}

/** A reserva do inimigo entra no primeiro hexágono livre da área dele. */
function refillEnemy(context: BoardContext, positions: number[]): void {
  const { state } = context;
  for (const position of positions) {
    const next = reserveIndices(state, 'enemy')[0];
    const cell = state.board.zones.enemy.find((zoneCell) =>
      isFree(state, zoneCell),
    );
    if (next === undefined || !cell) return;
    state.enemy.activeIndices[position] = next;
    enterBoard(context, { side: 'enemy', position }, cell);
  }
}

function sendEntries(context: BoardContext, entries: BoardEntry[]): void {
  const { state } = context;
  state.phase = 'choose_action';
  state.pendingPositions = [];
  state.entryCells = [];
  for (const entry of [...entries].sort((a, b) => a.position - b.position)) {
    state.player.activeIndices[entry.position] = entry.team_index;
    enterBoard(
      context,
      { side: 'player', position: entry.position },
      entry.cell,
    );
  }
}

function endBattle(context: BoardContext, result: BattleResult): void {
  const { state, events } = context;
  state.phase = 'ended';
  state.result = result;
  state.pendingPositions = [];
  state.entryCells = [];
  state.queue = [];
  for (const side of ['player', 'enemy'] as SideSlug[]) {
    for (const spot of occupiedSpots(state, side)) {
      clearVolatile(combatantAt(state, spot));
    }
  }
  settleCoins(context, result);
  events.push({ type: 'battle_ended', result });
}

/** Quem entra no tabuleiro, como o `enterField` da luta de hoje, com o hexágono. */
function enterBoard(context: BoardContext, spot: Spot, cell: HexCoord): void {
  const { state } = context;
  state.cells[spot.side][spot.position] = cell;
  recordEntry(context, spot);
  const creature = combatantAt(state, spot);
  creature.stages = noStages();
  clearVolatile(creature);
  if (creature.statusSlug === 'sleep') {
    creature.sleepTurns = rollSleepTurns(context.random);
  }
  context.events.push({
    type: 'creature_entered',
    ...spot,
    team_index: state[spot.side].activeIndices[spot.position]!,
    species_id: creature.speciesId,
    level: creature.level,
    max_hp: creature.stats.hp,
    hp: creature.currentHp,
    status: creature.statusSlug,
    cell,
  });
  applyEntryTrait(context, spot);
}
