import {
  always,
  makeCatalog,
  makeCombatant,
  makeSkill,
} from '../battle/testing.js';
import type {
  BattleCatalog,
  BattleSkill,
  Combatant,
  Random,
  SideSlug,
  Spot,
} from '../battle/types.js';
import type { HexCoord } from '../exploration/hex.js';
import { cellAt, makeBoard, startCell } from './board.js';
import { applyBoardVez, type BoardOutcome } from './board-engine.js';
import type { BoardInput, BoardState } from './types.js';

export const at = cellAt;

export const SCRATCH = makeSkill({ id: 1 });
export const SPARK = makeSkill({
  id: 5,
  category: 'special',
  areaShape: 'line',
  range: 3,
});
export const SPIRAL = makeSkill({
  id: 9,
  category: 'special',
  range: 3,
  groundEffectId: 1,
  groundTurns: 6,
});
export const GROWL = makeSkill({
  id: 2,
  power: 0,
  category: 'support',
  targetSlug: 'self',
});
export const FIRE_GROUND = 1;

export function boardCatalog(skills: BattleSkill[] = []): BattleCatalog {
  const catalog = makeCatalog({}, [SCRATCH, SPARK, SPIRAL, GROWL, ...skills]);
  catalog.groundEffects.set(FIRE_GROUND, {
    damagePercent: 6,
    statusSlug: null,
  });
  return catalog;
}

export function fighter(
  spd: number,
  overrides: Partial<Combatant> = {},
): Combatant {
  return makeCombatant({
    stats: { hp: 200, atk: 10, def: 9, sp_atk: 11, sp_def: 9, spd },
    currentHp: 200,
    skills: [
      { skillId: SCRATCH.id, currentPp: 35 },
      { skillId: SPARK.id, currentPp: 20 },
      { skillId: SPIRAL.id, currentPp: 10 },
      { skillId: GROWL.id, currentPp: 30 },
    ],
    ...overrides,
  });
}

export function wild(
  spd: number,
  overrides: Partial<Combatant> = {},
): Combatant {
  return fighter(spd, { creatureUid: null, speciesId: 7, ...overrides });
}

export interface BoardSetup {
  slots?: { player: number; enemy: number };
  cells?: Partial<Record<SideSlug, (HexCoord | null)[]>>;
  queue?: Spot[];
}

export function makeBoardState(
  player: Combatant[],
  enemy: Combatant[],
  { slots = { player: 1, enemy: 1 }, cells = {}, queue }: BoardSetup = {},
  overrides: Partial<BoardState> = {},
): BoardState {
  const side = (team: Combatant[], count: number) => ({
    team: structuredClone(team),
    activeIndices: Array.from({ length: count }, (_, position) =>
      position < team.length ? position : null,
    ),
  });
  const placed = (which: SideSlug, count: number, team: Combatant[]) =>
    Array.from({ length: count }, (_, position) =>
      position < team.length
        ? (cells[which]?.[position] ?? startCell(which, position, count))
        : null,
    );
  const state: BoardState = {
    phase: 'choose_action',
    result: null,
    turn: 1,
    canFlee: true,
    opponent: 'wild',
    player: side(player, slots.player),
    enemy: side(enemy, slots.enemy),
    pendingPositions: [],
    bag: [],
    godMode: false,
    coins: 0,
    coinsChange: 0,
    partyFree: 0,
    board: makeBoard(),
    cells: {
      player: placed('player', slots.player, player),
      enemy: placed('enemy', slots.enemy, enemy),
    },
    marks: [],
    round: 1,
    queue: (queue ?? [{ side: 'player', position: 0 }]).map((spot) => ({
      ...spot,
      teamIndex: spot.position,
    })),
    entryCells: [],
    ...overrides,
  };
  const facing = state.player.activeIndices.filter(
    (index): index is number => index !== null,
  );
  for (const enemyCreature of state.enemy.team) {
    if (enemyCreature.foughtBy.length === 0)
      enemyCreature.foughtBy = [...facing];
  }
  return state;
}

export function playVez(
  state: BoardState,
  input: BoardInput,
  catalog: BattleCatalog,
  random: Random = always(0.5),
): BoardOutcome {
  const outcome = applyBoardVez(state, input, catalog, random);
  if ('error' in outcome) throw new Error(outcome.error);
  return outcome;
}
