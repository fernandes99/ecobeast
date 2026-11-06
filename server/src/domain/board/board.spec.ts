import { always } from '../battle/testing.js';
import { hexDistance } from '../exploration/hex.js';
import {
  areaOf,
  NO_ENEMY_THERE,
  OUT_OF_RANGE,
  STRAIGHT_LINE,
} from './areas.js';
import {
  BOARD_COLUMNS,
  BOARD_ROWS,
  makeBoard,
  MOVE_RANGE,
  reachable,
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
    expect(BOARD_COLUMNS * BOARD_ROWS).toBe(18);
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
    const enemy = startCell('enemy', 0, 1);
    const player = startCell('player', 0, 1);
    expect(enemy).toEqual(at(1, 1));
    expect(player).toEqual(at(1, 4));
    expect(hexDistance(enemy, player)).toBe(3);
  });

  it('num 2×2, cada lado ocupa as colunas 0 e 2; num 3×3, as 3', () => {
    expect([0, 1].map((p) => startCell('player', p, 2))).toEqual([
      at(0, 4),
      at(2, 4),
    ]);
    expect([0, 1, 2].map((p) => startCell('player', p, 3))).toEqual([
      at(0, 4),
      at(1, 4),
      at(2, 4),
    ]);
  });
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
