import { describe, expect, it } from 'vitest';
import {
  archipelagoStates,
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
