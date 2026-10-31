import { startBattle } from './engine.js';
import {
  eventsOf,
  makeCatalog,
  makeCombatant,
  makeEffect,
  makeSkill,
  makeState,
  play,
  sequence,
} from './testing.js';
import type { BattleAction, Combatant } from './types.js';

const SCRATCH = makeSkill({ id: 1 });
const IDLE = makeSkill({
  id: 2,
  power: 0,
  accuracy: 0,
  category: 'support',
  targetSlug: 'self',
});
const BACKFIRE = makeSkill({
  id: 3,
  effects: [makeEffect({ effectSlug: 'recoil', percent: 100 })],
});
const catalog = makeCatalog({}, [SCRATCH, IDLE, BACKFIRE]);
const USE_FIRST: BattleAction = { type: 'skill', slot: 1 };

function attacker(overrides: Partial<Combatant> = {}): Combatant {
  return makeCombatant({
    skills: [{ skillId: 1, currentPp: 10 }],
    stats: { hp: 19, atk: 10, def: 9, sp_atk: 11, sp_def: 9, spd: 20 },
    ...overrides,
  });
}

function idle(overrides: Partial<Combatant> = {}): Combatant {
  return makeCombatant({
    skills: [{ skillId: 2, currentPp: 10 }],
    ...overrides,
  });
}

describe('Instinto', () => {
  const instinct = (overrides: Partial<Combatant> = {}) =>
    attacker({ traitSlug: 'instinct', ...overrides });

  it('dá +1 de Velocidade ao derrotar um inimigo com uma Técnica', () => {
    const { state, events } = play(
      makeState(instinct(), [idle({ currentHp: 1 }), idle()]),
      USE_FIRST,
      catalog,
    );
    expect(state.player.team[0]!.stages.spd).toBe(1);
    expect(eventsOf(events, 'stat_changed')).toEqual([
      {
        type: 'stat_changed',
        side: 'player',
        stat: 'spd',
        stages: 1,
        value: 1,
      },
    ]);
  });

  it('não dá nada sem derrotar', () => {
    const { state } = play(makeState(instinct(), idle()), USE_FIRST, catalog);
    expect(state.player.team[0]!.stages.spd).toBe(0);
  });

  it('não dá nada se o inimigo cair por status', () => {
    const { state } = play(
      makeState(instinct({ skills: [{ skillId: 2, currentPp: 10 }] }), [
        idle({ statusSlug: 'poison', currentHp: 1 }),
        idle(),
      ]),
      USE_FIRST,
      catalog,
    );
    expect(state.player.team[0]!.stages.spd).toBe(0);
  });

  it('não dá nada para quem caiu junto', () => {
    const { events } = play(
      makeState(
        instinct({
          skills: [{ skillId: 3, currentPp: 10 }],
          currentHp: 1,
        }),
        idle({ currentHp: 5 }),
      ),
      USE_FIRST,
      catalog,
      sequence(0, 0.9, 0.5),
    );
    expect(eventsOf(events, 'stat_changed')).toEqual([]);
  });
});

describe('Brisa Ligeira', () => {
  const tailwind = (overrides: Partial<Combatant> = {}) =>
    idle({ traitSlug: 'tailwind', ...overrides });

  it('dá +1 de Velocidade ao entrar, logo depois da entrada', () => {
    const { state, events } = startBattle(
      [tailwind()],
      [idle()],
      true,
      catalog,
      sequence(),
    );
    expect(state.player.team[0]!.stages.spd).toBe(1);
    expect(events.map((event) => event.type)).toEqual([
      'battle_started',
      'creature_entered',
      'stat_changed',
      'creature_entered',
    ]);
  });

  it('vale para os dois lados, primeiro o do jogador', () => {
    const { events } = startBattle(
      [tailwind()],
      [tailwind()],
      true,
      catalog,
      sequence(),
    );
    expect(eventsOf(events, 'stat_changed').map((e) => e.side)).toEqual([
      'player',
      'enemy',
    ]);
  });

  it('vale para o próximo inimigo', () => {
    const { state } = play(
      makeState(attacker(), [idle({ currentHp: 1 }), tailwind()]),
      USE_FIRST,
      catalog,
    );
    expect(state.enemy.team[1]!.stages.spd).toBe(1);
  });

  it('vale para o próximo do jogador', () => {
    const { state } = play(
      makeState([idle({ currentHp: 0 }), tailwind()], idle(), {
        phase: 'choose_next',
      }),
      { type: 'switch', team_index: 1 },
      catalog,
    );
    expect(state.player.team[1]!.stages.spd).toBe(1);
  });
});

it('um Traço sem efeito no motor é ignorado', () => {
  const { events } = startBattle(
    [idle({ traitSlug: 'hard_shell' })],
    [idle({ traitSlug: 'novo_traco' })],
    true,
    catalog,
    sequence(),
  );
  expect(eventsOf(events, 'stat_changed')).toEqual([]);
});
