import type { HexCoord } from '../exploration/hex.js';
import { always, sequence } from '../battle/testing.js';
import { hexDistance, hexKey, hexNeighbors } from '../exploration/hex.js';
import { seededRandom } from '../exploration/seeded-random.js';
import {
  areaOf,
  NO_ENEMY_THERE,
  OUT_OF_RANGE,
  STRAIGHT_LINE,
} from './areas.js';
import {
  DEFAULT_BOARD_SIZE,
  makeBoard,
  MOVE_RANGE,
  reachable,
  rollBoard,
  rollBoardSize,
  startCell,
} from './board.js';
import { roundQueue } from './queue.js';
import {
  at,
  fighter,
  GROWL,
  makeBoardState,
  SCRATCH,
  SPARK,
  SPIRAL,
  wild,
} from './testing.js';

describe('tabuleiro', () => {
  it('tem 3 × 6 hexágonos, com duas linhas em cada área', () => {
    const board = makeBoard();
    expect(DEFAULT_BOARD_SIZE).toEqual({ columns: 3, rows: 6 });
    expect(board.size).toEqual(DEFAULT_BOARD_SIZE);
    expect(board.cells).toHaveLength(18);
    expect(board.zones.enemy).toHaveLength(6);
    expect(board.zones.player).toHaveLength(6);
    expect(board.zones.enemy.every(({ r }) => r <= 1)).toBe(true);
    expect(board.zones.player.every(({ r }) => r >= 4)).toBe(true);
  });

  it('a área do inimigo começa pela linha da frente', () => {
    expect(makeBoard().zones.enemy[0]).toEqual(at(0, 1));
  });

  it('num 1×1, os dois começam na coluna 1, a 3 hexágonos, nas linhas 1 e 4', () => {
    const enemy = startCell('enemy', 0, 1, makeBoard());
    const player = startCell('player', 0, 1, makeBoard());
    expect(enemy).toEqual(at(1, 1));
    expect(player).toEqual(at(1, 4));
    expect(hexDistance(enemy, player)).toBe(3);
  });

  it('num 2×2, cada lado ocupa as colunas 0 e 2; num 3×3, as 3', () => {
    expect([0, 1].map((p) => startCell('player', p, 2, makeBoard()))).toEqual([
      at(0, 4),
      at(2, 4),
    ]);
    expect(
      [0, 1, 2].map((p) => startCell('player', p, 3, makeBoard())),
    ).toEqual([at(0, 4), at(1, 4), at(2, 4)]);
  });
});

describe('tamanho sorteado (board-size/01)', () => {
  it('sorteia as duas pontas de cada faixa e nunca sai delas', () => {
    expect([1, 2, 3].map((slots) => rollBoardSize(slots, always(0)))).toEqual([
      { columns: 4, rows: 4 },
      { columns: 6, rows: 6 },
      { columns: 8, rows: 8 },
    ]);
    expect(
      [1, 2, 3].map((slots) => rollBoardSize(slots, always(0.999))),
    ).toEqual([
      { columns: 10, rows: 10 },
      { columns: 12, rows: 12 },
      { columns: 16, rows: 16 },
    ]);
  });

  it('um formato fora da tabela usa a faixa do 1', () => {
    expect(rollBoardSize(7, always(0.999))).toEqual({ columns: 10, rows: 10 });
  });

  it('sorteia as colunas antes das linhas, cada eixo sozinho', () => {
    expect(rollBoardSize(1, sequence(0, 0.999))).toEqual({
      columns: 4,
      rows: 10,
    });
  });

  it('num 7 × 5, as zonas ficam em volta das linhas de frente 0 e 3', () => {
    const board = makeBoard({ columns: 7, rows: 5 });
    expect(board.cells).toHaveLength(35);
    expect(board.size).toEqual({ columns: 7, rows: 5 });
    expect(board.zones.enemy.map(({ r }) => r)).toEqual(Array(7).fill(0));
    expect(board.zones.player.map(({ r }) => r)).toEqual([
      ...Array(7).fill(3),
      ...Array(7).fill(4),
    ]);
  });

  it('num 4 × 4, nenhuma casa de zona fica fora do tabuleiro', () => {
    const board = makeBoard({ columns: 4, rows: 4 });
    const keys = new Set(board.cells.map(({ q, r }) => `${q},${r}`));
    const zones = [...board.zones.enemy, ...board.zones.player];
    expect(zones.every(({ q, r }) => keys.has(`${q},${r}`))).toBe(true);
    expect(board.zones.enemy.every(({ r }) => r === 0)).toBe(true);
    expect(board.zones.player.every(({ r }) => r === 3)).toBe(true);
  });

  it('num 10 × 10, os lados começam nas colunas centrais, a 3 hexágonos', () => {
    const board = makeBoard({ columns: 10, rows: 10 });
    const starts = (side: 'player' | 'enemy', slots: number) =>
      Array.from({ length: slots }, (_, p) => startCell(side, p, slots, board));
    expect(starts('enemy', 1)).toEqual([at(4, 3)]);
    expect(starts('player', 1)).toEqual([at(4, 6)]);
    expect(starts('player', 2)).toEqual([at(3, 6), at(5, 6)]);
    expect(starts('enemy', 3)).toEqual([at(2, 3), at(4, 3), at(6, 3)]);
    expect(hexDistance(starts('enemy', 1)[0]!, starts('player', 1)[0]!)).toBe(
      3,
    );
  });
});

describe('mordidas na borda (board-size/03)', () => {
  const connected = (cells: HexCoord[]) => {
    const keys = new Set(cells.map(hexKey));
    const seen = new Set([hexKey(cells[0]!)]);
    const queue = [cells[0]!];
    while (queue.length > 0) {
      for (const next of hexNeighbors(queue.pop()!)) {
        const key = hexKey(next);
        if (keys.has(key) && !seen.has(key)) {
          seen.add(key);
          queue.push(next);
        }
      }
    }
    return seen.size === keys.size;
  };

  for (const slots of [1, 2, 3]) {
    it(`num ${slots}×${slots}, o campo mordido continua inteiro e jogável`, () => {
      let bitten = 0;
      let big = 0;
      for (let seed = 1; seed <= 300; seed++) {
        const board = rollBoard(slots, seededRandom(seed));
        const { columns, rows } = board.size;
        const keys = new Set(board.cells.map(hexKey));
        const full = columns * rows;
        expect(connected(board.cells)).toBe(true);
        expect(board.cells.length).toBeGreaterThanOrEqual(
          Math.ceil(full * 0.8),
        );
        expect(board.cells.length).toBeLessThanOrEqual(full);
        for (const zone of [board.zones.player, board.zones.enemy]) {
          expect(zone.every((cell) => keys.has(hexKey(cell)))).toBe(true);
        }
        for (const count of [1, 2, 3]) {
          for (const side of ['player', 'enemy'] as const) {
            for (let position = 0; position < count; position++) {
              const start = startCell(side, position, count, board);
              expect(keys.has(hexKey(start))).toBe(true);
              for (const near of hexNeighbors(start)) {
                const inside =
                  near.r >= 0 &&
                  near.r < rows &&
                  near.q + Math.floor(near.r / 2) >= 0 &&
                  near.q + Math.floor(near.r / 2) < columns;
                if (inside) expect(keys.has(hexKey(near))).toBe(true);
              }
            }
          }
        }
        if (columns * rows === 16) {
          expect(full - board.cells.length).toBeLessThanOrEqual(3);
        }
        if (columns >= 6 && rows >= 6) {
          big++;
          if (board.cells.length < full) bitten++;
        }
      }
      if (big > 0) expect(bitten / big).toBeGreaterThan(0.9);
    });
  }
});

describe('andar', () => {
  // at(1, 2) fica no meio do tabuleiro, com os 6 vizinhos.
  const from = at(1, 2);
  const state = makeBoardState([fighter(10)], [wild(5)], {
    cells: { player: [from], enemy: [at(2, 3)] },
  });

  it('anda 1 hexágono por vez: só os vizinhos', () => {
    expect(MOVE_RANGE).toBe(1);
    const paths = reachable(state, from, MOVE_RANGE);
    const destinations = [...paths.values()].map((path) => path.at(-1)!);
    expect(destinations).toHaveLength(6);
    expect(destinations.every((cell) => hexDistance(cell, from) === 1)).toBe(
      true,
    );
  });

  it('com mais passos, chega a até essa distância, por hexágonos livres', () => {
    const paths = reachable(state, from, 3);
    const destinations = [...paths.values()].map((path) => path.at(-1)!);
    expect(destinations.every((cell) => hexDistance(cell, from) <= 3)).toBe(
      true,
    );
  });

  it('não para nem passa pelo hexágono de outro Ecobeast', () => {
    const paths = reachable(state, from, 3);
    const enemyCell = at(2, 3);
    for (const path of paths.values()) {
      expect(
        path.some((cell) => cell.q === enemyCell.q && cell.r === enemyCell.r),
      ).toBe(false);
    }
  });

  it('o caminho é um dos mais curtos, sem a origem', () => {
    const paths = reachable(state, from, 3);
    for (const path of paths.values()) {
      expect(path.length).toBe(hexDistance(from, path.at(-1)!));
    }
  });
});

describe('áreas das Técnicas', () => {
  const player = { side: 'player', position: 0 } as const;

  function twoInLine() {
    return makeBoardState([fighter(10)], [wild(5), wild(5)], {
      slots: { player: 1, enemy: 2 },
      cells: { player: [at(2, 5)], enemy: [at(2, 4), at(1, 3)] },
    });
  }

  it('Arranhão atinge o inimigo ao lado e recusa o que está a 2', () => {
    const state = makeBoardState([fighter(10)], [wild(5)], {
      cells: { player: [at(2, 5)], enemy: [at(2, 4)] },
    });
    expect(areaOf(state, player, at(2, 5), SCRATCH, at(2, 4))).toEqual({
      cells: [at(2, 4)],
      foes: [{ side: 'enemy', position: 0 }],
    });
    const far = makeBoardState([fighter(10)], [wild(5)], {
      cells: { player: [at(2, 5)], enemy: [at(2, 3)] },
    });
    expect(areaOf(far, player, at(2, 5), SCRATCH, at(2, 3))).toEqual({
      error: OUT_OF_RANGE,
    });
  });

  it('Arranhão num hexágono vazio é recusado', () => {
    const state = twoInLine();
    expect(areaOf(state, player, at(2, 5), SCRATCH, at(1, 5))).toEqual({
      error: NO_ENEMY_THERE,
    });
  });

  it('Faísca Rápida para no primeiro inimigo da linha', () => {
    const state = twoInLine();
    const area = areaOf(state, player, at(2, 5), SPARK, at(1, 3));
    expect(area).toEqual({
      cells: [at(2, 4)],
      foes: [{ side: 'enemy', position: 0 }],
    });
  });

  it('com pierces, a linha atinge os dois e anda os 3 hexágonos', () => {
    const state = twoInLine();
    const area = areaOf(
      state,
      player,
      at(2, 5),
      { ...SPARK, pierces: true },
      at(2, 4),
    );
    expect(area).toEqual({
      cells: [at(2, 4), at(1, 3), at(1, 2)],
      foes: [
        { side: 'enemy', position: 0 },
        { side: 'enemy', position: 1 },
      ],
    });
  });

  it('a linha recusa um alvo fora das 6 retas', () => {
    const state = twoInLine();
    expect(areaOf(state, player, at(2, 5), SPARK, at(2, 3))).toEqual({
      error: STRAIGHT_LINE,
    });
  });

  it('a linha passa pelo aliado sem atingi-lo', () => {
    const state = makeBoardState([fighter(10), fighter(10)], [wild(5)], {
      slots: { player: 2, enemy: 1 },
      cells: { player: [at(2, 5), at(2, 4)], enemy: [at(1, 3)] },
    });
    expect(areaOf(state, player, at(2, 5), SPARK, at(1, 3))).toEqual({
      cells: [at(2, 4), at(1, 3)],
      foes: [{ side: 'enemy', position: 0 }],
    });
  });

  it('Chama Espiral aceita um hexágono vazio a até 3, e recusa a 4', () => {
    const state = twoInLine();
    expect(areaOf(state, player, at(2, 5), SPIRAL, at(0, 5))).toEqual({
      cells: [at(0, 5)],
      foes: [],
    });
    expect(areaOf(state, player, at(2, 5), SPIRAL, at(2, 1))).toEqual({
      error: OUT_OF_RANGE,
    });
  });

  it('a Técnica em si mesmo não tem área', () => {
    const state = twoInLine();
    expect(areaOf(state, player, at(2, 5), GROWL, undefined)).toEqual({
      cells: [],
      foes: [],
    });
  });
});

describe('fila', () => {
  it('põe todos de pé no tabuleiro pela Velocidade, o mais rápido primeiro', () => {
    const state = makeBoardState([fighter(10), fighter(30)], [wild(20)], {
      slots: { player: 2, enemy: 1 },
    });
    expect(roundQueue(state, always(0.5))).toEqual([
      { side: 'player', position: 1, teamIndex: 1 },
      { side: 'enemy', position: 0, teamIndex: 0 },
      { side: 'player', position: 0, teamIndex: 0 },
    ]);
  });

  it('a prioridade das Técnicas não conta, e o empate é sorteado', () => {
    const state = makeBoardState([fighter(10)], [wild(10)]);
    const first = roundQueue(state, always(0.1))[0]!.side;
    const second = roundQueue(state, always(0.9))[0]!.side;
    expect(first).not.toBe(second);
  });
});
