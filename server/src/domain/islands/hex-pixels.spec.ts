import { flatCenter, gridCoord } from './hex-pixels.js';

describe('hex-pixels, a mesma conta do HexMapView do jogo', () => {
  it('o centro plano de um hexágono', () => {
    expect(flatCenter({ q: 2, r: -3 })).toEqual({ x: 64, y: -97 });
    expect(flatCenter({ q: -1, r: 1 })).toEqual({ x: 0, y: 71 });
  });

  // Saídas do HexMapView.grid_coord do Godot para os mesmos pontos.
  it.each([
    [0, 0, 0, -1],
    [32, 29, 0, 0],
    [31, 1, 0, 0],
    [33, 1, 0, 0],
    [1, 15, 0, -1],
    [1, 17, 0, 0],
    [63, 15, 1, -1],
    [63, 17, 0, 0],
    [-1, 30, -1, 0],
    [64, 42, 0, 1],
    [10, 41, 0, 0],
    [-50, -20, -1, -1],
    [200, 130, 1, 3],
    [32, -14, 1, -1],
    [48, 7, 1, -1],
  ])('o ponto (%i, %i) cai no hexágono (%i, %i)', (x, y, q, r) => {
    expect(gridCoord({ x, y })).toEqual({ q, r });
  });
});
