import { describe, expect, it } from 'vitest';
import {
  arenaOpen,
  archipelagoStates,
  islandComplete,
  isLocked,
  nextIslandAfter,
  tamersComplete,
} from './archipelago.js';

const islands = [
  { id: 30, order: 3 },
  { id: 10, order: 1 },
  { id: 20, order: 2 },
];

describe('archipelagoStates', () => {
  it('um jogador novo tem a 1ª aberta, a 2ª como próxima e o resto escondido', () => {
    expect(archipelagoStates(islands, new Set())).toEqual([
      { id: 10, order: 1, state: 'open' },
      { id: 20, order: 2, state: 'next' },
      { id: 30, order: 3, state: 'hidden' },
    ]);
  });

  it('a ilha aberta pelo jogador conta, e a próxima é a de menor ordem que falta', () => {
    expect(
      archipelagoStates(islands, new Set([20])).map((i) => i.state),
    ).toEqual(['open', 'open', 'next']);
  });

  it('a próxima é a menor que falta, mesmo com uma mais adiante aberta', () => {
    expect(
      archipelagoStates(islands, new Set([30])).map((i) => i.state),
    ).toEqual(['open', 'next', 'open']);
  });

  it('com tudo aberto, não há próxima', () => {
    expect(
      archipelagoStates(islands, new Set([20, 30])).map((i) => i.state),
    ).toEqual(['open', 'open', 'open']);
  });

  it('uma linha de ilha fora do Arquipélago não muda nada', () => {
    expect(
      archipelagoStates(islands, new Set([99])).map((i) => i.state),
    ).toEqual(['open', 'next', 'hidden']);
  });

  it('sem ilhas, devolve vazio', () => {
    expect(archipelagoStates([], new Set([1]))).toEqual([]);
  });
});

describe('isLocked', () => {
  it('só a ilha do Arquipélago que não está aberta é trancada', () => {
    expect(isLocked(islands, new Set(), 10)).toBe(false);
    expect(isLocked(islands, new Set(), 20)).toBe(true);
    expect(isLocked(islands, new Set(), 30)).toBe(true);
    expect(isLocked(islands, new Set([20]), 20)).toBe(false);
    expect(isLocked(islands, new Set(), 99)).toBe(false);
  });
});

describe('nextIslandAfter', () => {
  it('é a de menor ordem acima da ilha', () => {
    expect(nextIslandAfter(islands, 10)).toBe(20);
    expect(nextIslandAfter(islands, 20)).toBe(30);
  });

  it('a última e a de fora do Arquipélago não têm seguinte', () => {
    expect(nextIslandAfter(islands, 30)).toBeNull();
    expect(nextIslandAfter(islands, 99)).toBeNull();
  });
});

describe('tamersComplete', () => {
  it('sem Domador que conta, a ilha não completa', () => {
    expect(tamersComplete([], new Set(), null)).toBe(false);
  });

  it('sem número, pede todos os que contam', () => {
    expect(tamersComplete([1, 2], new Set([1]), null)).toBe(false);
    expect(tamersComplete([1, 2], new Set([1, 2]), null)).toBe(true);
  });

  it('com número, pede só aquela quantidade', () => {
    expect(tamersComplete([1, 2, 3], new Set([2]), 1)).toBe(true);
    expect(tamersComplete([1, 2, 3], new Set([2]), 2)).toBe(false);
  });

  it('um número maior que o de Domadores pede todos', () => {
    expect(tamersComplete([1, 2], new Set([1, 2]), 5)).toBe(true);
  });

  it('vitórias contra Domadores que não contam não somam', () => {
    expect(tamersComplete([1], new Set([7, 8]), 1)).toBe(false);
  });
});

describe('arenaOpen', () => {
  const arenas = [
    { id: 7, position: 2 },
    { id: 5, position: 1 },
    { id: 9, position: 3 },
  ];

  it('a primeira está sempre aberta', () => {
    expect(arenaOpen(arenas, new Set(), 5)).toBe(true);
  });

  it('as seguintes pedem todas as de antes', () => {
    expect(arenaOpen(arenas, new Set(), 7)).toBe(false);
    expect(arenaOpen(arenas, new Set([5]), 7)).toBe(true);
    expect(arenaOpen(arenas, new Set([5]), 9)).toBe(false);
    expect(arenaOpen(arenas, new Set([5, 7]), 9)).toBe(true);
  });

  it('uma Arena que não é da ilha não abre', () => {
    expect(arenaOpen(arenas, new Set([5, 7, 9]), 99)).toBe(false);
  });
});

describe('islandComplete', () => {
  const none = {
    countingTamerIds: [],
    wonTamerIds: new Set<number>(),
    requiredTamerWins: null,
    arenaIds: [],
    wonArenaIds: new Set<number>(),
  };

  it('sem condição, nunca completa', () => {
    expect(islandComplete(none)).toBe(false);
  });

  it('só com Arenas, pede todas ganhas', () => {
    expect(islandComplete({ ...none, arenaIds: [1, 2] })).toBe(false);
    expect(
      islandComplete({ ...none, arenaIds: [1, 2], wonArenaIds: new Set([1]) }),
    ).toBe(false);
    expect(
      islandComplete({
        ...none,
        arenaIds: [1, 2],
        wonArenaIds: new Set([1, 2]),
      }),
    ).toBe(true);
  });

  it('com Domadores e Arena, pede os dois', () => {
    const both = {
      ...none,
      countingTamerIds: [3],
      arenaIds: [1],
    };
    expect(islandComplete({ ...both, wonTamerIds: new Set([3]) })).toBe(false);
    expect(islandComplete({ ...both, wonArenaIds: new Set([1]) })).toBe(false);
    expect(
      islandComplete({
        ...both,
        wonTamerIds: new Set([3]),
        wonArenaIds: new Set([1]),
      }),
    ).toBe(true);
  });

  it('só com Domadores, segue a regra deles', () => {
    expect(
      islandComplete({
        ...none,
        countingTamerIds: [3, 4],
        wonTamerIds: new Set([4]),
        requiredTamerWins: 1,
      }),
    ).toBe(true);
  });
});
