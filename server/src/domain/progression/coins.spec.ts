import { always } from '../battle/testing.js';
import { lostCoins, winCoins } from './coins.js';

const LOWEST = always(0);
const HIGHEST = always(0.999);

describe('winCoins', () => {
  it('sorteia de 50% a 150% de 20 com os níveis iguais', () => {
    expect(winCoins(5, 5, LOWEST)).toBe(10);
    expect(winCoins(5, 5, HIGHEST)).toBe(30);
    expect(winCoins(30, 30, HIGHEST)).toBe(30);
  });

  it('paga mais por um selvagem mais forte e menos por um mais fraco', () => {
    expect([winCoins(10, 5, LOWEST), winCoins(10, 5, HIGHEST)]).toEqual([
      20, 60,
    ]);
    expect([winCoins(5, 10, LOWEST), winCoins(5, 10, HIGHEST)]).toEqual([
      5, 15,
    ]);
  });

  it('dá pelo menos 1', () => {
    expect(winCoins(1, 100, LOWEST)).toBe(1);
  });
});

describe('lostCoins', () => {
  it('sorteia de 50% a 150% de 5 com os níveis iguais', () => {
    expect(lostCoins(5, 5, 100, LOWEST)).toBe(2);
    expect(lostCoins(5, 5, 100, HIGHEST)).toBe(7);
  });

  it('sobe com o nível do selvagem', () => {
    expect(lostCoins(10, 5, 100, HIGHEST)).toBe(15);
    expect(lostCoins(5, 10, 100, LOWEST)).toBe(1);
  });

  it('nunca tira mais do que o Domador tem', () => {
    expect(lostCoins(5, 5, 3, HIGHEST)).toBe(3);
    expect(lostCoins(5, 5, 0, HIGHEST)).toBe(0);
  });
});
