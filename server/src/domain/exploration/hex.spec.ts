import { hexDistance, hexKey, hexNeighbors } from './hex.js';

describe('hexKey', () => {
  it('é a mesma para a mesma posição', () => {
    expect(hexKey({ q: 2, r: -1 })).toBe(hexKey({ q: 2, r: -1 }));
  });

  it('distingue posições diferentes', () => {
    expect(hexKey({ q: 1, r: 12 })).not.toBe(hexKey({ q: 11, r: 2 }));
  });
});

describe('hexNeighbors', () => {
  it('devolve as seis posições vizinhas', () => {
    expect(hexNeighbors({ q: 0, r: 0 })).toEqual(
      expect.arrayContaining([
        { q: 1, r: 0 },
        { q: -1, r: 0 },
        { q: 0, r: 1 },
        { q: 0, r: -1 },
        { q: 1, r: -1 },
        { q: -1, r: 1 },
      ]),
    );
    expect(hexNeighbors({ q: 0, r: 0 })).toHaveLength(6);
  });

  it('parte da posição dada', () => {
    expect(hexNeighbors({ q: 3, r: 5 })).toContainEqual({ q: 4, r: 5 });
  });
});

describe('hexDistance', () => {
  it('é 0 na mesma posição', () => {
    expect(hexDistance({ q: 2, r: 2 }, { q: 2, r: 2 })).toBe(0);
  });

  it('é 1 para todos os vizinhos', () => {
    const center = { q: 4, r: -2 };
    for (const neighbor of hexNeighbors(center)) {
      expect(hexDistance(center, neighbor)).toBe(1);
    }
  });

  it('conta os passos pela grade', () => {
    expect(hexDistance({ q: 0, r: 0 }, { q: 2, r: 1 })).toBe(3);
    expect(hexDistance({ q: 0, r: 0 }, { q: 2, r: -2 })).toBe(2);
  });
});
