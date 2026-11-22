import { describe, expect, it } from 'vitest';
import { makeCombatant, makeState, WATER } from '../battle/testing.js';
import { battleCounters, foughtCreatureIndices } from './battle-counters.js';
import { COUNTER_IDS, type CounterIncrement } from './counters.js';

const VOLT = 4;
const SPHERE = 10;
const POTION = 4;
const NIGHT = 4;
const input = { dayPhaseId: NIGHT, sphereItemIds: new Set([SPHERE]) };

const total = (id: number, amount: number): CounterIncrement => ({
  counterId: id,
  subjectId: 0,
  amount,
});

function counter(
  list: CounterIncrement[],
  id: number,
  subjectId = 0,
): number | undefined {
  return list.find(
    (item) => item.counterId === id && item.subjectId === subjectId,
  )?.amount;
}

describe('battleCounters', () => {
  it('conta a vitória contra um selvagem, o XP e as moedas ganhas', () => {
    const player = makeCombatant({ xpEarned: 40 });
    const state = makeState(player, makeCombatant(), {
      result: 'victory',
      coinsChange: 25,
    });

    expect(battleCounters(state, input)).toEqual(
      expect.arrayContaining([
        total(COUNTER_IDS.wins_wild, 1),
        total(COUNTER_IDS.xp_gained, 40),
        total(COUNTER_IDS.coins_earned, 25),
      ]),
    );
    expect(counter(battleCounters(state, input), COUNTER_IDS.wins_tamer)).toBe(
      undefined,
    );
  });

  it('conta a vitória contra um Domador como wins_tamer', () => {
    const state = makeState(makeCombatant(), makeCombatant(), {
      result: 'victory',
      opponent: 'tamer',
    });

    const list = battleCounters(state, input);

    expect(counter(list, COUNTER_IDS.wins_tamer)).toBe(1);
    expect(counter(list, COUNTER_IDS.wins_wild)).toBe(undefined);
  });

  it('conta a derrota e não conta moedas perdidas', () => {
    const state = makeState(makeCombatant(), makeCombatant(), {
      result: 'defeat',
      coinsChange: -30,
    });

    expect(battleCounters(state, input)).toEqual([
      total(COUNTER_IDS.defeats, 1),
    ]);
  });

  it('não conta vitória nem derrota na fuga', () => {
    const state = makeState(makeCombatant(), makeCombatant(), {
      result: 'fled',
    });

    expect(battleCounters(state, input)).toEqual([]);
  });

  it('conta a captura na primeira Esfera, por Elemento e por parte do dia', () => {
    const enemy = makeCombatant({ captured: true, elementIds: [WATER, VOLT] });
    const state = makeState(makeCombatant(), enemy, {
      result: 'captured',
      bag: [
        { itemId: SPHERE, quantity: 2, used: 1 },
        { itemId: POTION, quantity: 1, used: 1 },
      ],
    });

    const list = battleCounters(state, input);

    expect(counter(list, COUNTER_IDS.captures)).toBe(1);
    expect(counter(list, COUNTER_IDS.captures_first_sphere)).toBe(1);
    expect(counter(list, COUNTER_IDS.spheres_used)).toBe(1);
    expect(counter(list, COUNTER_IDS.captures_by_element, WATER)).toBe(1);
    expect(counter(list, COUNTER_IDS.captures_by_element, VOLT)).toBe(1);
    expect(counter(list, COUNTER_IDS.captures_by_day_phase, NIGHT)).toBe(1);
  });

  it('não conta a primeira Esfera quando a luta gastou duas', () => {
    const enemy = makeCombatant({ captured: true });
    const state = makeState(makeCombatant(), enemy, {
      result: 'captured',
      bag: [{ itemId: SPHERE, quantity: 3, used: 2 }],
    });

    const list = battleCounters(state, input);

    expect(counter(list, COUNTER_IDS.spheres_used)).toBe(2);
    expect(counter(list, COUNTER_IDS.captures_first_sphere)).toBe(undefined);
  });

  it('conta as Esferas gastas mesmo sem captura', () => {
    const state = makeState(makeCombatant(), makeCombatant(), {
      result: 'fled',
      bag: [{ itemId: SPHERE, quantity: 1, used: 1 }],
    });

    expect(battleCounters(state, input)).toEqual([
      total(COUNTER_IDS.spheres_used, 1),
    ]);
  });
});

describe('foughtCreatureIndices', () => {
  it('junta quem enfrentou cada inimigo, sem repetir', () => {
    const state = makeState(
      [makeCombatant(), makeCombatant(), makeCombatant()],
      [makeCombatant({ foughtBy: [0, 2] }), makeCombatant({ foughtBy: [2] })],
    );

    expect(foughtCreatureIndices(state)).toEqual([0, 2]);
  });
});
