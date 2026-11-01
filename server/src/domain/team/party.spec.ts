import { firstFreePartySlot, isSameTeam } from './party.js';

describe('firstFreePartySlot', () => {
  it('sem ninguém, é a primeira', () => {
    expect(firstFreePartySlot([])).toBe(1);
  });

  it('pega a vaga depois da última', () => {
    expect(firstFreePartySlot([1, 2])).toBe(3);
  });

  it('prefere a vaga do meio', () => {
    expect(firstFreePartySlot([1, 3, 4])).toBe(2);
  });

  it('com as 6 ocupadas, não há vaga', () => {
    expect(firstFreePartySlot([1, 2, 3, 4, 5, 6])).toBeNull();
  });
});

describe('isSameTeam', () => {
  const TEAM = ['a', 'b', 'c'];

  it('aceita a mesma equipe em outra ordem', () => {
    expect(isSameTeam(TEAM, ['c', 'a', 'b'])).toBe(true);
  });

  it('aceita a mesma ordem', () => {
    expect(isSameTeam(TEAM, TEAM)).toBe(true);
  });

  it.each([
    ['faltando alguém', ['a', 'b']],
    ['sobrando alguém', ['a', 'b', 'c', 'd']],
    ['com alguém repetido', ['a', 'b', 'b']],
    ['com alguém de fora', ['a', 'b', 'd']],
    ['vazia', []],
  ])('recusa a lista %s', (_name, requested) => {
    expect(isSameTeam(TEAM, requested)).toBe(false);
  });
});
