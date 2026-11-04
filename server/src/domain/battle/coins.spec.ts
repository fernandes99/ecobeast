import { startBattle } from './engine.js';
import {
  always,
  eventsOf,
  makeCatalog,
  makeCombatant,
  makeSkill,
  makeState,
  play,
} from './testing.js';
import type { Combatant } from './types.js';

const SCRATCH = makeSkill({ id: 1 });
const catalog = makeCatalog({}, [SCRATCH], {}, {}, { 4: 50 });
const ATTACK = { type: 'skill', slot: 1 } as const;

function fighter(overrides: Partial<Combatant> = {}): Combatant {
  return makeCombatant({
    skills: [{ skillId: SCRATCH.id, currentPp: 10 }],
    ...overrides,
  });
}

/** Um selvagem nível 5 com 1 de HP, mais lento que o Ruvo de `fighter`. */
function weakWild(): Combatant {
  return fighter({
    creatureUid: null,
    speciesId: 4,
    stats: { ...fighter().stats, spd: 1 },
    currentHp: 1,
  });
}

/** Um selvagem nível 5 que age antes e derruba o Ruvo com 1 de HP. */
function fastWild(): Combatant {
  return fighter({
    creatureUid: null,
    speciesId: 4,
    stats: { ...fighter().stats, spd: 99 },
  });
}

describe('moedas contra o selvagem', () => {
  it('a vitória sorteia as moedas e as anuncia antes do fim, depois do XP', () => {
    const { state, events } = play(
      makeState(fighter(), weakWild(), { coins: 100 }),
      ATTACK,
      catalog,
    );
    // Níveis iguais: de 10 a 30, e o sorteio do meio dá 20.
    expect(eventsOf(events, 'coins_gained')).toEqual([
      { type: 'coins_gained', amount: 20 },
    ]);
    const types = events.map((event) => event.type);
    expect(types.indexOf('coins_gained')).toBeGreaterThan(
      types.indexOf('xp_gained'),
    );
    expect(types.indexOf('coins_gained')).toBe(
      types.indexOf('battle_ended') - 1,
    );
    expect(state.coinsChange).toBe(20);
  });

  it('usa o nível de quem está em campo no fim', () => {
    const { events } = play(
      makeState(fighter({ level: 10 }), weakWild()),
      ATTACK,
      catalog,
    );
    // Selvagem 5 contra 10: de 5 a 15, e o sorteio do meio dá 10.
    expect(eventsOf(events, 'coins_gained')[0]!.amount).toBe(10);
  });

  it('a derrota tira moedas e as anuncia antes do fim', () => {
    const { state, events } = play(
      makeState(fighter({ currentHp: 1 }), fastWild(), { coins: 100 }),
      ATTACK,
      catalog,
    );
    expect(state.result).toBe('defeat');
    // Níveis iguais: de 2 a 7, e o sorteio do meio dá 5.
    expect(eventsOf(events, 'coins_lost')).toEqual([
      { type: 'coins_lost', amount: 5 },
    ]);
    const types = events.map((event) => event.type);
    expect(types.indexOf('coins_lost')).toBe(
      types.indexOf('battle_ended') - 1,
    );
    expect(state.coinsChange).toBe(-5);
  });

  it('a derrota não tira mais do que o Domador tem', () => {
    const outcome = (coins: number) =>
      play(
        makeState(fighter({ currentHp: 1 }), fastWild(), { coins }),
        ATTACK,
        catalog,
      );
    expect(outcome(3).state.coinsChange).toBe(-3);
    const broke = outcome(0);
    expect(broke.state.coinsChange).toBe(0);
    expect(eventsOf(broke.events, 'coins_lost')).toEqual([]);
  });

  it('a fuga não mexe nas moedas', () => {
    const { state, events } = play(
      makeState(fighter(), fastWild(), { coins: 100 }),
      { type: 'flee' },
      catalog,
      always(0.9),
    );
    expect(state.result).toBe('fled');
    expect(state.coinsChange).toBe(0);
    expect(eventsOf(events, 'coins_gained')).toEqual([]);
    expect(eventsOf(events, 'coins_lost')).toEqual([]);
  });

  it('startBattle guarda as moedas do Domador, e elas começam em 0', () => {
    const start = (options = {}) =>
      startBattle(
        [fighter()],
        [weakWild()],
        true,
        catalog,
        always(0.5),
        [],
        options,
      ).state;
    expect(start({ coins: 250 })).toMatchObject({ coins: 250, coinsChange: 0 });
    expect(start()).toMatchObject({ coins: 0, coinsChange: 0 });
  });
});
