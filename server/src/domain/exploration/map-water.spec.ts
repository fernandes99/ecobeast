import { hexKey, hexNeighbors } from './hex.js';
import { descend, flowDown, WaterCell } from './map-water.js';

interface TestCell extends WaterCell<TestCell> {
  key: string;
}

/** Uma faixa de 9 × 3, com a saída na coluna 0 e um buraco na coluna 5. */
function valley(): {
  cells: TestCell[];
  at: (q: number, r: number) => TestCell;
} {
  const cells: TestCell[] = [];
  for (let r = 0; r < 3; r += 1) {
    for (let q = 0; q < 9; q += 1) {
      cells.push({
        q,
        r,
        key: hexKey({ q, r }),
        elevation: q === 5 ? 0.05 : q / 10,
        sea: q === 0,
        wet: q === 0,
        neighbors: [],
      });
    }
  }
  const byKey = new Map(cells.map((cell) => [cell.key, cell]));
  for (const cell of cells) {
    cell.neighbors = hexNeighbors(cell).flatMap((coord) => {
      const neighbor = byKey.get(hexKey(coord));
      return neighbor ? [neighbor] : [];
    });
  }
  return { cells, at: (q, r) => byKey.get(hexKey({ q, r }))! };
}

describe('flowDown (coast-rivers/02)', () => {
  it('todo hexágono de terra tem um caminho até a saída', () => {
    const { cells } = valley();
    const drain = new Map(cells.map((cell) => [cell, cell.elevation]));
    const { down } = flowDown(
      drain,
      cells.filter((cell) => cell.wet),
    );
    for (const cell of cells.filter((c) => !c.wet)) {
      let step: TestCell | undefined = cell;
      for (let hops = 0; step && !step.wet; hops += 1) {
        expect(hops).toBeLessThan(cells.length);
        step = down.get(step);
      }
      expect(step?.wet).toBe(true);
    }
  });

  it('o nível de saída nunca sobe no caminho, e o buraco é enchido até transbordar', () => {
    const { cells, at } = valley();
    const drain = new Map(cells.map((cell) => [cell, cell.elevation]));
    const { down, level } = flowDown(
      drain,
      cells.filter((cell) => cell.wet),
    );
    let step: TestCell | undefined = at(8, 1);
    while (step && !step.wet) {
      const next: TestCell = down.get(step)!;
      expect(level.get(next)!).toBeLessThanOrEqual(level.get(step)!);
      step = next;
    }
    expect(level.get(at(5, 1))).toBeCloseTo(0.4);
  });

  it('o rio desce até encostar na água e para ali', () => {
    const { cells, at } = valley();
    const drain = new Map(cells.map((cell) => [cell, cell.elevation]));
    const { down } = flowDown(
      drain,
      cells.filter((cell) => cell.wet),
    );
    const river = descend(at(8, 1), down, new Set());
    expect(river[0]).toBe(at(8, 1));
    const last = river.at(-1)!;
    expect(last.neighbors.some((neighbor) => neighbor.wet)).toBe(true);
    expect(
      river.slice(0, -1).every((cell) => !cell.neighbors.some((n) => n.wet)),
    ).toBe(true);
    for (let index = 1; index < river.length; index += 1) {
      expect(river[index - 1]!.neighbors).toContain(river[index]);
    }
  });
});
