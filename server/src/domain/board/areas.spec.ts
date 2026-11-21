import { makeSkill } from '../battle/testing.js';
import type { Spot } from '../battle/types.js';
import type { HexCoord } from '../exploration/hex.js';
import { areaOf, NO_ENEMY_THERE, OUT_OF_RANGE } from './areas.js';
import { makeBoard } from './board.js';
import { fighter, FIRE_GROUND, makeBoardState, wild } from './testing.js';

const TRIANGLE = makeSkill({
  id: 90,
  category: 'special',
  areaShape: 'triangle',
  range: 3,
});
const BURNING_TRIANGLE = {
  ...TRIANGLE,
  groundEffectId: FIRE_GROUND,
  groundTurns: 6,
};
const ME: Spot = { side: 'player', position: 0 };
const FROM: HexCoord = { q: 2, r: 6 };

function board(enemies: HexCoord[] = []) {
  return makeBoardState(
    [fighter(30)],
    enemies.map(() => wild(5)),
    {
      slots: { player: 1, enemy: Math.max(1, enemies.length) },
      cells: { player: [FROM], enemy: enemies },
    },
    { board: makeBoard({ columns: 8, rows: 8 }) },
  );
}

describe('a área Triângulo (board-battle/33)', () => {
  it('fora das retas, o vértice e os 2 vizinhos mais longe, com o vértice por último', () => {
    const area = areaOf(board(), ME, FROM, BURNING_TRIANGLE, { q: 4, r: 5 });
    expect(area).toEqual({
      cells: [
        { q: 5, r: 5 },
        { q: 5, r: 4 },
        { q: 4, r: 5 },
      ],
      foes: [],
    });
  });

  it('numa reta, sem inimigos, fica o triângulo que gira no sentido horário', () => {
    const area = areaOf(board(), ME, FROM, BURNING_TRIANGLE, { q: 2, r: 4 });
    expect(area).toMatchObject({
      cells: [
        { q: 2, r: 3 },
        { q: 3, r: 3 },
        { q: 2, r: 4 },
      ],
    });
  });

  it('numa reta, fica o triângulo com mais inimigos', () => {
    const state = board([{ q: 1, r: 4 }]);
    const area = areaOf(state, ME, FROM, TRIANGLE, { q: 2, r: 4 });
    expect(area).toEqual({
      cells: [
        { q: 2, r: 3 },
        { q: 1, r: 4 },
        { q: 2, r: 4 },
      ],
      foes: [{ side: 'enemy', position: 0 }],
    });
  });

  it('os hexágonos fora do tabuleiro saem, e no empate fica o que tem mais', () => {
    const area = areaOf(board(), ME, { q: 3, r: 2 }, BURNING_TRIANGLE, {
      q: 3,
      r: 0,
    });
    expect(area).toEqual({
      cells: [
        { q: 2, r: 0 },
        { q: 3, r: 0 },
      ],
      foes: [],
    });
  });

  it('sem marca no chão e sem inimigo no triângulo, é recusada', () => {
    const area = areaOf(board([{ q: 0, r: 0 }]), ME, FROM, TRIANGLE, {
      q: 2,
      r: 4,
    });
    expect(area).toEqual({ error: NO_ENEMY_THERE });
  });

  it('o vértice longe demais é recusado', () => {
    const area = areaOf(board(), ME, FROM, BURNING_TRIANGLE, { q: 2, r: 2 });
    expect(area).toEqual({ error: OUT_OF_RANGE });
  });
});
