import { fixedDamage, rollHits } from './actions.js';
import {
  always,
  cast,
  eventsOf,
  makeCatalog,
  makeCombatant,
  makeEffect,
  makeSkill,
  makeState,
} from './testing.js';
import type { Combatant } from './types.js';

const FIXED_15 = makeEffect({ effectSlug: 'fixed_damage', value: 15 });
const VOLLEY = makeSkill({
  id: 57,
  power: 0,
  category: 'special',
  minHits: 2,
  maxHits: 5,
  effects: [FIXED_15],
});
const NEEDLE = makeSkill({
  id: 58,
  power: 0,
  category: 'special',
  effects: [FIXED_15],
});
const catalog = makeCatalog({}, [VOLLEY, NEEDLE]);

function sturdy(overrides: Partial<Combatant> = {}): Combatant {
  return makeCombatant({
    stats: { hp: 200, atk: 10, def: 9, sp_atk: 11, sp_def: 9, spd: 11 },
    currentHp: 200,
    ...overrides,
  });
}

describe('vários golpes e dano fixo (puffcoo-line/01)', () => {
  it('sorteia de min_hits a max_hits, sem gastar sorteio num golpe só', () => {
    expect(rollHits(VOLLEY, always(0))).toBe(2);
    expect(rollHits(VOLLEY, always(0.99))).toBe(5);
    expect(
      rollHits(NEEDLE, () => {
        throw new Error('não sorteia');
      }),
    ).toBe(1);
  });

  it('o dano fixo vem do efeito, e sem ele é nulo', () => {
    expect(fixedDamage(VOLLEY)).toBe(15);
    expect(fixedDamage(makeSkill())).toBeNull();
  });

  it('cada golpe tira 15, e o multi_hit conta os golpes', () => {
    const { state, events } = cast(
      makeState(sturdy(), sturdy()),
      VOLLEY,
      catalog,
      always(0.99),
    );
    const hits = eventsOf(events, 'damage');
    expect(hits).toHaveLength(5);
    expect(hits.map((hit) => hit.damage)).toEqual([15, 15, 15, 15, 15]);
    expect(eventsOf(events, 'multi_hit')).toEqual([
      { type: 'multi_hit', side: 'enemy', position: 0, hits: 5 },
    ]);
    expect(state.enemy.team[0]!.currentHp).toBe(125);
  });

  it('para no golpe que derruba o alvo', () => {
    const { events } = cast(
      makeState(sturdy(), sturdy({ currentHp: 20 })),
      VOLLEY,
      catalog,
      always(0.99),
    );
    expect(eventsOf(events, 'damage').map((hit) => hit.damage)).toEqual([
      15, 5,
    ]);
    expect(eventsOf(events, 'multi_hit')[0]!.hits).toBe(2);
  });

  it('um erro anula todos os golpes', () => {
    const shaky = { ...VOLLEY, accuracy: 50 };
    const { events } = cast(
      makeState(sturdy(), sturdy()),
      shaky,
      catalog,
      always(0.5),
    );
    expect(events).toEqual([{ type: 'missed', side: 'player', position: 0 }]);
  });

  it('o dano fixo ignora o crítico e a vantagem de Elemento', () => {
    const strong = makeCatalog({ '13:1': 2 }, [NEEDLE]);
    const { events } = cast(
      makeState(sturdy(), sturdy()),
      NEEDLE,
      strong,
      always(0),
    );
    expect(events).toEqual([
      {
        type: 'damage',
        side: 'enemy',
        position: 0,
        damage: 15,
        hp: 185,
        multiplier: 1,
        is_critical: false,
      },
    ]);
  });

  it('mas não passa da imunidade', () => {
    const immune = makeCatalog({ '13:1': 0 }, [VOLLEY]);
    const { state, events } = cast(
      makeState(sturdy(), sturdy()),
      VOLLEY,
      immune,
      always(0.99),
    );
    expect(events).toEqual([{ type: 'no_effect', side: 'enemy', position: 0 }]);
    expect(state.enemy.team[0]!.currentHp).toBe(200);
  });
});
