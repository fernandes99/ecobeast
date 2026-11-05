import { isStanding } from '../battle/field.js';
import type { SideSlug, Spot } from '../battle/types.js';
import {
  type HexCoord,
  hexDistance,
  hexKey,
  hexNeighbors,
} from '../exploration/hex.js';
import type { Board, BoardState } from './types.js';

/** O tabuleiro de agora, fixo (.specs/board-battle/architecture.md). A revisar. */
export const BOARD_COLUMNS = 6;
export const BOARD_ROWS = 7;
export const MOVE_RANGE = 3;

/** As linhas de cada área, a da frente primeiro. */
const ZONE_ROWS: Record<SideSlug, number[]> = {
  enemy: [1, 0],
  player: [5, 6],
};

/** As colunas de largada na linha da frente, por número de vagas. A revisar. */
const START_COLUMNS: Record<number, number[]> = {
  1: [2],
  2: [2, 3],
  3: [1, 2, 3],
};

/** A casa da coluna e da linha: as linhas ímpares ficam meio hexágono à direita. */
export function cellAt(column: number, row: number): HexCoord {
  return { q: column - Math.floor(row / 2), r: row };
}

export function makeBoard(): Board {
  const cells: HexCoord[] = [];
  for (let row = 0; row < BOARD_ROWS; row++) {
    for (let column = 0; column < BOARD_COLUMNS; column++) {
      cells.push(cellAt(column, row));
    }
  }
  const zone = (side: SideSlug) =>
    ZONE_ROWS[side].flatMap((row) =>
      Array.from({ length: BOARD_COLUMNS }, (_, column) => cellAt(column, row)),
    );
  return { cells, zones: { player: zone('player'), enemy: zone('enemy') } };
}

/** O hexágono de largada da vaga, na linha da frente da área do lado. */
export function startCell(
  side: SideSlug,
  position: number,
  slots: number,
): HexCoord {
  const columns = START_COLUMNS[slots] ?? START_COLUMNS[1]!;
  return cellAt(columns[position]!, ZONE_ROWS[side][0]!);
}

export function sameCell(a: HexCoord, b: HexCoord): boolean {
  return a.q === b.q && a.r === b.r;
}

export function hasCell(state: BoardState, cell: HexCoord): boolean {
  return state.board.cells.some((boardCell) => sameCell(boardCell, cell));
}

/** Onde está quem ocupa a vaga; nulo fora do tabuleiro. */
export function cellOf(state: BoardState, spot: Spot): HexCoord | null {
  return state.cells[spot.side][spot.position] ?? null;
}

/** Quem está no hexágono, dos dois lados; nulo com ele livre. */
export function spotAt(state: BoardState, cell: HexCoord): Spot | null {
  for (const side of ['player', 'enemy'] as const) {
    const position = state.cells[side].findIndex(
      (occupied) => occupied !== null && sameCell(occupied, cell),
    );
    if (position !== -1) return { side, position };
  }
  return null;
}

/** Quem ocupa a vaga, se estiver de pé no tabuleiro. */
export function standingAt(state: BoardState, spot: Spot): boolean {
  const index = state[spot.side].activeIndices[spot.position];
  if (index === null || index === undefined) return false;
  return (
    cellOf(state, spot) !== null && isStanding(state[spot.side].team[index]!)
  );
}

/** As vagas de quem está de pé no tabuleiro, em ordem de posição. */
export function standingOnBoard(state: BoardState, side: SideSlug): Spot[] {
  return state.cells[side].flatMap((_, position) =>
    standingAt(state, { side, position }) ? [{ side, position }] : [],
  );
}

export function isFree(state: BoardState, cell: HexCoord): boolean {
  return hasCell(state, cell) && spotAt(state, cell) === null;
}

/**
 * Os hexágonos aonde se chega em até `steps` passos por hexágonos livres,
 * pela chave do `hexKey`, com um dos caminhos mais curtos, sem a origem.
 */
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

/**
 * Onde quem entra depois de uma queda pode ficar: os hexágonos livres da área
 * do lado, ou, com ela cheia, os livres mais perto dela.
 */
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
