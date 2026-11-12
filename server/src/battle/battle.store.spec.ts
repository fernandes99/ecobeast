import {
  makeCatalog,
  makeCombatant,
  makeState,
} from '../domain/battle/testing.js';
import { BattleStore, StoredBattle } from './battle.store.js';

const MINUTE = 60_000;

function battle(): StoredBattle {
  return {
    state: makeState(makeCombatant(), makeCombatant()),
    catalog: makeCatalog(),
    wilds: [],
  };
}

describe('BattleStore', () => {
  let now: number;
  let store: BattleStore;

  beforeEach(() => {
    now = 0;
    store = new BattleStore(() => now);
  });

  it('guarda uma batalha por jogador', () => {
    const first = battle();
    const second = battle();
    store.set('a', first);
    store.set('b', second);
    expect(store.get('a')).toBe(first);
    expect(store.get('b')).toBe(second);
  });

  it('a batalha nova substitui a anterior', () => {
    const newer = battle();
    store.set('a', battle());
    store.set('a', newer);
    expect(store.get('a')).toBe(newer);
  });

  it('sem batalha, não devolve nada', () => {
    expect(store.get('a')).toBeUndefined();
  });

  it('apaga', () => {
    store.set('a', battle());
    store.delete('a');
    expect(store.get('a')).toBeUndefined();
  });

  it('mantém a batalha até os 30 minutos', () => {
    store.set('a', battle());
    now = 30 * MINUTE - 1;
    expect(store.get('a')).toBeDefined();
  });

  it('a batalha some aos 30 minutos sem ação', () => {
    store.set('a', battle());
    now = 30 * MINUTE;
    expect(store.get('a')).toBeUndefined();
  });

  it('uma ação renova o prazo', () => {
    const stored = battle();
    store.set('a', stored);
    now = 20 * MINUTE;
    store.set('a', stored);
    now = 40 * MINUTE;
    expect(store.get('a')).toBe(stored);
  });

  it('cada acesso confere todas as batalhas', () => {
    store.set('a', battle());
    now = 30 * MINUTE;
    store.get('outro');
    now = 0;
    expect(store.get('a')).toBeUndefined();
  });
});
