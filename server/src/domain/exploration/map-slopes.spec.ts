import { describe, expect, it } from 'vitest';
import type { HexCoord } from './hex.js';
import { hexKey, hexNeighbors } from './hex.js';
import {
  climbable,
  climbReach,
  MAX_CLIMB,
  openRamps,
  openSlopes,
  raiseAlong,
  stepLevels,
} from './map-slopes.js';
import { seededRandom } from './seeded-random.js';

interface TestCell extends HexCoord {
  height: number;
  water: boolean;
  neighbors: TestCell[];
}

/** Uma faixa de hexágonos de q 0 a `heights.length - 1`, na linha r 0. */
function row(heights: number[], water: number[] = []): TestCell[] {
  const cells = heights.map((height, q): TestCell => ({
    q,
    r: 0,
    height,
    water: water.includes(q),
    neighbors: [],
  }));
  const byKey = new Map(cells.map((cell) => [hexKey(cell), cell]));
  for (const cell of cells) {
    cell.neighbors = hexNeighbors(cell).flatMap((coord) => {
      const next = byKey.get(hexKey(coord));
      return next ? [next] : [];
    });
  }
  return cells;
}

const wet = (cell: TestCell) => cell.water;
const heights = (cells: { height: number }[]) =>
  cells.map(({ height }) => height);

describe('a regra do paredão (terrain-plateaus/01)', () => {
  it('até 2 níveis passa; 3 ou mais é paredão', () => {
    expect(MAX_CLIMB).toBe(2);
    expect(climbable({ height: 1 }, { height: 3 })).toBe(true);
    expect(climbable({ height: 3 }, { height: 1 })).toBe(true);
    expect(climbable({ height: 1 }, { height: 4 })).toBe(false);
    expect(climbable({ height: 7 }, { height: 4 })).toBe(false);
  });

  it('o alcance para no paredão e atravessa pelas pontes', () => {
    const cells = row([1, 2, 5, 5]);
    expect(climbReach(cells[0]!, new Map(), wet).size).toBe(2);
    const links = new Map([
      [cells[1]!, [cells[2]!]],
      [cells[2]!, [cells[1]!]],
    ]);
    expect(climbReach(cells[0]!, links, wet).size).toBe(4);
  });
});

describe('raiseAlong', () => {
  it('só sobe, e cada passo fica com até 2 níveis', () => {
    for (let seed = 1; seed <= 30; seed += 1) {
      const path = [10, 1, 1, 1, 1, 1].map((height) => ({ height }));
      raiseAlong(path, seededRandom(seed));
      for (let index = 1; index < path.length; index += 1) {
        const drop = path[index - 1]!.height - path[index]!.height;
        expect(Math.abs(drop)).toBeLessThanOrEqual(2);
      }
      expect(path[0]!.height).toBe(10);
      expect(path.every(({ height }) => height >= 1 && height <= 10)).toBe(
        true,
      );
    }
  });

  it('mistura degraus de 1 e de 2 ao acaso', () => {
    const drops = new Set<number>();
    for (let seed = 1; seed <= 30; seed += 1) {
      const path = [9, 1, 1, 1, 1, 1].map((height) => ({ height }));
      raiseAlong(path, seededRandom(seed));
      for (let index = 1; index < path.length; index += 1) {
        const drop = path[index - 1]!.height - path[index]!.height;
        if (drop > 0) drops.add(drop);
      }
    }
    expect([...drops].sort()).toEqual([1, 2]);
  });

  it('sobe dos dois lados: o baixo no começo do caminho também', () => {
    const path = [1, 1, 8].map((height) => ({ height }));
    raiseAlong(path, seededRandom(4));
    expect(path[2]!.height).toBe(8);
    expect(path[1]!.height).toBeGreaterThanOrEqual(6);
    expect(path[1]!.height - path[0]!.height).toBeLessThanOrEqual(2);
  });
});

describe('openSlopes', () => {
  it('abre uma encosta até o platô sem baixar ninguém', () => {
    const cells = row([1, 1, 1, 7, 7]);
    openSlopes(cells, cells[0]!, new Map(), wet, seededRandom(9));
    expect(climbReach(cells[0]!, new Map(), wet).size).toBe(5);
    expect(cells[3]!.height).toBe(7);
    expect(cells[4]!.height).toBe(7);
    expect(cells.every((cell, q) => cell.height >= [1, 1, 1, 7, 7][q]!)).toBe(
      true,
    );
  });

  it('não passa pela água', () => {
    const cells = row([1, 1, 7, 7], [1]);
    openSlopes(cells, cells[0]!, new Map(), wet, seededRandom(2));
    expect(heights(cells)).toEqual([1, 1, 7, 7]);
  });

  it('a margem de uma ponte que sobe leva a outra junto', () => {
    const cells = row([1, 1, 7, 1, 1], [2]);
    cells[2]!.height = 0;
    const links = new Map([
      [cells[1]!, [cells[3]!]],
      [cells[3]!, [cells[1]!]],
    ]);
    cells[4]!.height = 9;
    openSlopes(cells, cells[0]!, links, wet, seededRandom(3));
    expect(cells[1]!.height).toBe(cells[3]!.height);
    expect(climbReach(cells[0]!, links, wet).size).toBe(4);
  });

  it('a mesma seed dá a mesma encosta', () => {
    const a = row([1, 1, 1, 1, 9]);
    const b = row([1, 1, 1, 1, 9]);
    openSlopes(a, a[0]!, new Map(), wet, seededRandom(5));
    openSlopes(b, b[0]!, new Map(), wet, seededRandom(5));
    expect(heights(a)).toEqual(heights(b));
  });
});

describe('as encostas extras (terrain-plateaus/02)', () => {
  it('os degraus descem de 1 ou 2 e o último fica a até 2 do chão', () => {
    for (let seed = 1; seed <= 20; seed += 1) {
      const all = [7, ...stepLevels(7, 1, seededRandom(seed)), 1];
      expect(all.length).toBeGreaterThan(2);
      for (let index = 1; index < all.length; index += 1) {
        const drop = all[index - 1]! - all[index]!;
        expect(drop === 1 || drop === 2).toBe(true);
      }
    }
  });

  it('abre uma escadaria de vários degraus no lado baixo do paredão', () => {
    // Uma grade de 12 × 12: as 3 primeiras colunas no 7, o resto no 1.
    const cells: TestCell[] = [];
    for (let q = 0; q < 12; q += 1) {
      for (let r = 0; r < 12; r += 1) {
        cells.push({
          q,
          r,
          height: q < 3 ? 7 : 1,
          water: false,
          neighbors: [],
        });
      }
    }
    const byKey = new Map(cells.map((cell) => [hexKey(cell), cell]));
    for (const cell of cells) {
      cell.neighbors = hexNeighbors(cell).flatMap((coord) => {
        const next = byKey.get(hexKey(coord));
        return next ? [next] : [];
      });
    }
    const opened = openRamps(
      cells,
      1,
      (cell) => cell.height < 7,
      () => true,
      seededRandom(6),
    );
    expect(opened).toBeGreaterThan(0);
    const raised = cells.filter((cell) => cell.height > 1 && cell.height < 7);
    expect(new Set(raised.map(({ height }) => height)).size).toBeGreaterThan(1);
    expect(raised.length).toBeGreaterThan(4);
    for (const cell of raised) {
      const up = cell.neighbors.some(
        (next) => next.height > cell.height && climbable(cell, next),
      );
      expect(up).toBe(true);
    }
  });
});
