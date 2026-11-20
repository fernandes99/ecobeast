import { isStanding } from '../battle/field.js';
import type { Random, SideSlug, Spot } from '../battle/types.js';
import {
  type HexCoord,
  hexDistance,
  hexKey,
  hexNeighbors,
} from '../exploration/hex.js';
import type { Board, BoardSize, BoardState } from './types.js';

export const MOVE_RANGE = 1;
export const DEFAULT_BOARD_SIZE: BoardSize = { columns: 3, rows: 6 };
export const BOARD_SIZE_RANGES: Record<number, { min: number; max: number }> = {
  1: { min: 4, max: 10 },
  2: { min: 6, max: 12 },
  3: { min: 8, max: 16 },
};
const FRONT_GAP = 3;

export function cellAt(column: number, row: number): HexCoord {
  return { q: column - Math.floor(row / 2), r: row };
}

export function rollBoardSize(slots: number, random: Random): BoardSize {
  const { min, max } = BOARD_SIZE_RANGES[slots] ?? BOARD_SIZE_RANGES[1]!;
  const roll = () => min + Math.floor(random() * (max - min + 1));
  const columns = roll();
  return { columns, rows: roll() };
}

function frontRow(side: SideSlug, rows: number): number {
  const enemy = Math.floor((rows - FRONT_GAP - 1) / 2);
  return side === 'enemy' ? enemy : enemy + FRONT_GAP;
}

function zoneRows(side: SideSlug, rows: number): number[] {
  const front = frontRow(side, rows);
  const back = side === 'enemy' ? front - 1 : front + 1;
  return back >= 0 && back < rows ? [front, back] : [front];
}

function startColumns(slots: number, columns: number): number[] {
  const center = Math.floor((columns - 1) / 2);
  if (slots === 2) return [center - 1, center + 1];
  if (slots === 3) {
    const step = center - 2 >= 0 && center + 2 < columns ? 2 : 1;
    return [center - step, center, center + step];
  }
  return [center];
}

export function makeBoard(size: BoardSize = DEFAULT_BOARD_SIZE): Board {
  const { columns, rows } = size;
  const cells: HexCoord[] = [];
  for (let row = 0; row < rows; row++) {
    for (let column = 0; column < columns; column++) {
      cells.push(cellAt(column, row));
    }
  }
  const zone = (side: SideSlug) =>
    zoneRows(side, rows).flatMap((row) =>
      Array.from({ length: columns }, (_, column) => cellAt(column, row)),
    );
  return {
    cells,
    size: { columns, rows },
    zones: { player: zone('player'), enemy: zone('enemy') },
  };
}

export function startCell(
  side: SideSlug,
  position: number,
  slots: number,
  board: Board,
): HexCoord {
  const { columns, rows } = board.size;
  return cellAt(startColumns(slots, columns)[position]!, frontRow(side, rows));
}

export const MIN_KEPT = 0.8;
export const CELLS_PER_BITE = 20;
export const MAX_BITES = 5;
export const MAX_BITE = 3;

export function rollBoard(slots: number, random: Random): Board {
  return biteBoard(makeBoard(rollBoardSize(slots, random)), random);
}

function protectedKeys(board: Board): Set<string> {
  const keys = new Set<string>();
  for (const count of [1, 2, 3]) {
    for (const side of ['player', 'enemy'] as const) {
      for (let position = 0; position < count; position++) {
        const start = startCell(side, position, count, board);
        keys.add(hexKey(start));
        for (const near of hexNeighbors(start)) keys.add(hexKey(near));
      }
    }
  }
  return keys;
}

function staysWhole(
  keys: Set<string>,
  cells: HexCoord[],
  gone: string,
): boolean {
  const left = cells.filter((cell) => hexKey(cell) !== gone);
  if (left.length === 0) return false;
  const seen = new Set([hexKey(left[0]!)]);
  const queue = [left[0]!];
  while (queue.length > 0) {
    for (const next of hexNeighbors(queue.pop()!)) {
      const key = hexKey(next);
      if (key !== gone && keys.has(key) && !seen.has(key)) {
        seen.add(key);
        queue.push(next);
      }
    }
  }
  return seen.size === left.length;
}

export function biteBoard(board: Board, random: Random): Board {
  const full = board.cells.length;
  const minimum = Math.ceil(full * MIN_KEPT);
  const most = Math.min(
    MAX_BITES,
    Math.max(1, Math.round(full / CELLS_PER_BITE)),
  );
  const fewest = Math.min(2, most);
  const bites = fewest + Math.floor(random() * (most - fewest + 1));
  const guarded = protectedKeys(board);
  let cells = [...board.cells];
  const keys = new Set(cells.map(hexKey));
  const open = (cell: HexCoord) =>
    keys.has(hexKey(cell)) && !guarded.has(hexKey(cell));
  const pick = (options: HexCoord[]): HexCoord | null => {
    const left = [...options];
    while (left.length > 0 && cells.length > minimum) {
      const [cell] = left.splice(Math.floor(random() * left.length), 1);
      if (staysWhole(keys, cells, hexKey(cell!))) return cell!;
    }
    return null;
  };
  const remove = (cell: HexCoord) => {
    keys.delete(hexKey(cell));
    cells = cells.filter((other) => !sameCell(other, cell));
  };
  for (let bite = 0; bite < bites; bite++) {
    const first = pick(
      cells.filter(
        (cell) =>
          open(cell) &&
          hexNeighbors(cell).some((near) => !keys.has(hexKey(near))),
      ),
    );
    if (first === null) break;
    remove(first);
    const eaten = [first];
    const size = 1 + Math.floor(random() * MAX_BITE);
    while (eaten.length < size) {
      const next = pick(
        hexNeighbors(first).filter(
          (cell) =>
            open(cell) && eaten.some((done) => hexDistance(done, cell) === 1),
        ),
      );
      if (next === null) break;
      remove(next);
      eaten.push(next);
    }
  }
  const kept = (zone: HexCoord[]) =>
    zone.filter((cell) => keys.has(hexKey(cell)));
  return {
    cells,
    size: board.size,
    zones: { player: kept(board.zones.player), enemy: kept(board.zones.enemy) },
  };
}

export function sameCell(a: HexCoord, b: HexCoord): boolean {
  return a.q === b.q && a.r === b.r;
}

export function hasCell(state: BoardState, cell: HexCoord): boolean {
  return state.board.cells.some((boardCell) => sameCell(boardCell, cell));
}

export function cellOf(state: BoardState, spot: Spot): HexCoord | null {
  return state.cells[spot.side][spot.position] ?? null;
}

export function spotAt(state: BoardState, cell: HexCoord): Spot | null {
  for (const side of ['player', 'enemy'] as const) {
    const position = state.cells[side].findIndex(
      (occupied) => occupied !== null && sameCell(occupied, cell),
    );
    if (position !== -1) return { side, position };
  }
  return null;
}

export function standingAt(state: BoardState, spot: Spot): boolean {
  const index = state[spot.side].activeIndices[spot.position];
  if (index === null || index === undefined) return false;
  return (
    cellOf(state, spot) !== null && isStanding(state[spot.side].team[index]!)
  );
}

export function standingOnBoard(state: BoardState, side: SideSlug): Spot[] {
  return state.cells[side].flatMap((_, position) =>
    standingAt(state, { side, position }) ? [{ side, position }] : [],
  );
}

export function isFree(state: BoardState, cell: HexCoord): boolean {
  return hasCell(state, cell) && spotAt(state, cell) === null;
}

export function reachable(
  state: BoardState,
  from: HexCoord,
  steps: number,
): Map<string, HexCoord[]> {
  const paths = new Map<string, HexCoord[]>();
  let frontier: { cell: HexCoord; path: HexCoord[] }[] = [
    { cell: from, path: [] },
  ];
  const seen = new Set([hexKey(from)]);
  for (let step = 0; step < steps; step++) {
    const next: typeof frontier = [];
    for (const { cell, path } of frontier) {
      for (const neighbor of hexNeighbors(cell)) {
        const key = hexKey(neighbor);
        if (seen.has(key) || !isFree(state, neighbor)) continue;
        seen.add(key);
        const walked = [...path, neighbor];
        paths.set(key, walked);
        next.push({ cell: neighbor, path: walked });
      }
    }
    frontier = next;
  }
  return paths;
}

export function entryCellsFor(state: BoardState, side: SideSlug): HexCoord[] {
  const zone = state.board.zones[side];
  const free = zone.filter((cell) => isFree(state, cell));
  if (free.length > 0) return free;
  const others = state.board.cells.filter((cell) => isFree(state, cell));
  const distance = (cell: HexCoord) =>
    Math.min(...zone.map((zoneCell) => hexDistance(cell, zoneCell)));
  const nearest = Math.min(...others.map(distance));
  return others.filter((cell) => distance(cell) === nearest);
}
