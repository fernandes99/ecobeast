import { startBattle } from './engine.js';
import { applyStatus } from './status.js';
import {
  always,
  eventsOf,
  FIRE,
  makeCatalog,
  makeCombatant,
  makeSkill,
  makeState,
  play,
  sequence,
  WATER,
} from './testing.js';
import type {
  BattleAction,
  BattleCatalog,
  Combatant,
  Random,
  TurnContext,
} from './types.js';

const SCRATCH = makeSkill({ id: 1 });
const IDLE = makeSkill({
  id: 2,
  power: 0,
  accuracy: 0,
  category: 'support',
  targetSlug: 'self',
});
const catalog = makeCatalog({}, [SCRATCH, IDLE]);
const USE_FIRST: BattleAction = { type: 'skill', slot: 1 };

function attacker(overrides: Partial<Combatant> = {}): Combatant {
  return makeCombatant({
    skills: [{ skillId: 1, currentPp: 10 }],
    ...overrides,
  });
}

function idle(overrides: Partial<Combatant> = {}): Combatant {
  return makeCombatant({
    skills: [{ skillId: 2, currentPp: 10 }],
    ...overrides,
  });
}

function withMaxHp(hp: number, spd = 11): Combatant['stats'] {
  return { hp, atk: 10, def: 9, sp_atk: 11, sp_def: 9, spd };
}

function context(
  target: Combatant,
  random: Random = sequence(),
  usedCatalog: BattleCatalog = catalog,
): TurnContext {
  return {
    state: makeState(idle(), target),
    catalog: usedCatalog,
    random,
    events: [],
  };
}

describe('dano de status no fim do turno', () => {
  it.each([
    ['burn', 19, 18],
    ['burn', 160, 150],
    ['burn', 7, 6],
    ['poison', 19, 17],
    ['poison', 7, 6],
  ])('%s com HP máximo %i fica com %i', (statusSlug, maxHp, hp) => {
    const player = idle({
      statusSlug,
      stats: withMaxHp(maxHp),
      currentHp: maxHp,
    });
    const { state, events } = play(
      makeState(player, idle()),
      USE_FIRST,
      catalog,
    );
    expect(state.player.team[0]!.currentHp).toBe(hp);
    expect(eventsOf(events, 'status_damage')).toEqual([
      {
        type: 'status_damage',
        side: 'player',
        position: 0,
        status: statusSlug,
        damage: maxHp - hp,
        hp,
      },
    ]);
  });

  it('vem na ordem em que as criaturas agiram', () => {
    const fast = idle({ statusSlug: 'poison', stats: withMaxHp(19, 20) });
    const slow = idle({ statusSlug: 'poison', stats: withMaxHp(19, 5) });
    const sides = (player: Combatant, enemy: Combatant) =>
      eventsOf(
        play(makeState(player, enemy), USE_FIRST, catalog).events,
        'status_damage',
      ).map((event) => event.side);

    expect(sides(fast, slow)).toEqual(['player', 'enemy']);
    expect(sides(slow, fast)).toEqual(['enemy', 'player']);
  });

  it('pode derrubar quem o sofre', () => {
    const player = idle({ statusSlug: 'burn', currentHp: 1 });
    const { state, events } = play(
      makeState(player, idle()),
      USE_FIRST,
      catalog,
    );
    expect(state.result).toBe('defeat');
    expect(eventsOf(events, 'fainted')).toEqual([
      { type: 'fainted', side: 'player', position: 0 },
    ]);
  });

  it('não pega em quem já caiu no turno', () => {
    const enemy = idle({
      statusSlug: 'burn',
      currentHp: 1,
      stats: withMaxHp(19, 5),
    });
    const { events } = play(
      makeState(attacker({ stats: withMaxHp(19, 20) }), enemy),
      USE_FIRST,
      catalog,
    );
    expect(eventsOf(events, 'status_damage')).toEqual([]);
  });
});

describe('Paralisado', () => {
  const paralyzed = () => attacker({ statusSlug: 'paralysis' });

  it('perde a vez com o sorteio abaixo de 25%, sem gastar PP', () => {
    const { state, events } = play(
      makeState(paralyzed(), idle()),
      USE_FIRST,
      catalog,
      sequence(0, 0.24),
    );
    expect(eventsOf(events, 'cannot_act')).toEqual([
      { type: 'cannot_act', side: 'player', position: 0, reason: 'paralysis' },
    ]);
    expect(state.player.team[0]!.skills[0]!.currentPp).toBe(10);
  });

  it('age com o sorteio em 25%', () => {
    const { events } = play(
      makeState(paralyzed(), idle()),
      USE_FIRST,
      catalog,
      sequence(0, 0.25, 0.9, 0.5),
    );
    expect(eventsOf(events, 'cannot_act')).toEqual([]);
    expect(eventsOf(events, 'damage')).toHaveLength(1);
  });
});

describe('Adormecido', () => {
  it('não age nos turnos sorteados e age no turno em que acorda', () => {
    const asleep = attacker({ statusSlug: 'sleep', sleepTurns: 2 });
    const first = play(makeState(asleep, idle()), USE_FIRST, catalog);
    expect(eventsOf(first.events, 'cannot_act')).toEqual([
      { type: 'cannot_act', side: 'player', position: 0, reason: 'sleep' },
    ]);

    const second = play(first.state, USE_FIRST, catalog);
    expect(eventsOf(second.events, 'cannot_act')).toHaveLength(1);
    expect(second.state.player.team[0]!.skills[0]!.currentPp).toBe(10);

    const third = play(second.state, USE_FIRST, catalog);
    expect(eventsOf(third.events, 'woke_up')).toEqual([
      { type: 'woke_up', side: 'player', position: 0 },
    ]);
    expect(eventsOf(third.events, 'cannot_act')).toEqual([]);
    expect(third.state.player.team[0]).toMatchObject({
      statusSlug: null,
      sleepTurns: 0,
    });
    expect(third.state.player.team[0]!.skills[0]!.currentPp).toBe(9);
  });

  it('quem entra Adormecido sorteia os turnos de novo', () => {
    const { state } = startBattle(
      [idle({ statusSlug: 'sleep' })],
      [idle()],
      true,
      catalog,
      sequence(0.5),
    );
    expect(state.player.team[0]!.sleepTurns).toBe(2);
  });
});

describe('Congelado', () => {
  const frozen = () => attacker({ statusSlug: 'freeze' });

  it('descongela com o sorteio abaixo de 20% e age no mesmo turno', () => {
    const { state, events } = play(
      makeState(frozen(), idle()),
      USE_FIRST,
      catalog,
      always(0.19),
    );
    expect(eventsOf(events, 'thawed')).toEqual([
      { type: 'thawed', side: 'player', position: 0 },
    ]);
    expect(eventsOf(events, 'skill_used').map((e) => e.side)).toContain(
      'player',
    );
    expect(state.player.team[0]!.statusSlug).toBeNull();
  });

  it('não age com o sorteio em 20%', () => {
    const { state, events } = play(
      makeState(frozen(), idle()),
      USE_FIRST,
      catalog,
      always(0.2),
    );
    expect(eventsOf(events, 'cannot_act')).toEqual([
      { type: 'cannot_act', side: 'player', position: 0, reason: 'freeze' },
    ]);
    expect(state.player.team[0]!.statusSlug).toBe('freeze');
  });
});

describe('Confuso', () => {
  const confused = (overrides: Partial<Combatant> = {}) =>
    attacker({ confusionTurns: 3, stats: withMaxHp(19, 20), ...overrides });

  it('se atinge com o sorteio abaixo de 33%, sem gastar PP', () => {
    const { state, events } = play(
      makeState(confused(), idle()),
      USE_FIRST,
      catalog,
      sequence(0, 0.32, 0),
    );
    const creature = state.player.team[0]!;
    expect(eventsOf(events, 'confused_hit')).toEqual([
      { type: 'confused_hit', side: 'player', position: 0, damage: 4, hp: 15 },
    ]);
    expect(eventsOf(events, 'skill_used').map((e) => e.side)).toEqual([
      'enemy',
    ]);
    expect(creature.skills[0]!.currentPp).toBe(10);
    expect(creature.confusionTurns).toBe(2);
  });

  it('age com o sorteio em 33%', () => {
    const { events } = play(
      makeState(confused(), idle()),
      USE_FIRST,
      catalog,
      sequence(0, 0.33, 0.9, 0.5),
    );
    expect(eventsOf(events, 'confused_hit')).toEqual([]);
    expect(eventsOf(events, 'damage')).toHaveLength(1);
  });

  it('avisa quando passa', () => {
    const { state, events } = play(
      makeState(confused({ confusionTurns: 1 }), idle()),
      USE_FIRST,
      catalog,
      sequence(0, 0.5, 0.9, 0.5),
    );
    expect(eventsOf(events, 'status_ended')).toEqual([
      {
        type: 'status_ended',
        side: 'player',
        position: 0,
        status: 'confusion',
      },
    ]);
    expect(state.player.team[0]!.confusionTurns).toBe(0);
  });

  it('pode se derrubar', () => {
    const { state, events } = play(
      makeState(confused({ currentHp: 1, confusionTurns: 1 }), idle()),
      USE_FIRST,
      catalog,
      always(0),
    );
    expect(state.result).toBe('defeat');
    expect(eventsOf(events, 'fainted')).toHaveLength(1);
    expect(eventsOf(events, 'status_ended')).toEqual([]);
  });
});

describe('Amedrontado', () => {
  it('perde a ação sem gastar PP, e o efeito some no fim do turno', () => {
    const { state, events } = play(
      makeState(attacker({ isFeared: true }), idle()),
      USE_FIRST,
      catalog,
    );
    expect(eventsOf(events, 'cannot_act')).toEqual([
      { type: 'cannot_act', side: 'player', position: 0, reason: 'fear' },
    ]);
    expect(state.player.team[0]).toMatchObject({ isFeared: false });
    expect(state.player.team[0]!.skills[0]!.currentPp).toBe(10);
  });

  it('vem antes dos outros motivos', () => {
    const player = attacker({
      isFeared: true,
      statusSlug: 'sleep',
      sleepTurns: 2,
    });
    const { state, events } = play(
      makeState(player, idle()),
      USE_FIRST,
      catalog,
    );
    expect(eventsOf(events, 'cannot_act')).toEqual([
      { type: 'cannot_act', side: 'player', position: 0, reason: 'fear' },
    ]);
    expect(state.player.team[0]!.sleepTurns).toBe(2);
  });
});

describe('voláteis', () => {
  it('somem no fim da batalha', () => {
    const player = attacker({
      confusionTurns: 3,
      isTrapped: true,
      stats: withMaxHp(19, 20),
    });
    const { state } = play(
      makeState(player, idle({ currentHp: 1 })),
      USE_FIRST,
      catalog,
      // O último é o das moedas da vitória.
      sequence(0, 0.5, 0.9, 0.5, 0.5),
    );
    expect(state.result).toBe('victory');
    expect(state.player.team[0]).toMatchObject({
      confusionTurns: 0,
      isTrapped: false,
    });
  });
});

describe('applyStatus', () => {
  it('aplica um status principal', () => {
    const turn = context(idle());
    applyStatus(turn, { side: 'enemy', position: 0 }, 'poison');
    expect(turn.state.enemy.team[0]!.statusSlug).toBe('poison');
    expect(turn.events).toEqual([
      { type: 'status_applied', side: 'enemy', position: 0, status: 'poison' },
    ]);
  });

  it('não pega em quem tem outro status principal', () => {
    const turn = context(idle({ statusSlug: 'burn' }));
    applyStatus(turn, { side: 'enemy', position: 0 }, 'poison');
    expect(turn.state.enemy.team[0]!.statusSlug).toBe('burn');
    expect(turn.events).toEqual([
      { type: 'effect_failed', side: 'enemy', position: 0 },
    ]);
  });

  it('não pega em quem é imune pelo Elemento', () => {
    const immune = makeCatalog();
    immune.statusImmunities.set('burn', [WATER, FIRE]);
    const turn = context(idle(), sequence(), immune);
    applyStatus(turn, { side: 'enemy', position: 0 }, 'burn');
    expect(turn.state.enemy.team[0]!.statusSlug).toBeNull();
    expect(turn.events).toEqual([
      { type: 'effect_failed', side: 'enemy', position: 0 },
    ]);
  });

  it.each([
    [0, 1],
    [0.5, 2],
    [0.99, 3],
  ])('Adormecido com o sorteio %f dura %i turnos', (roll, turns) => {
    const turn = context(idle(), sequence(roll));
    applyStatus(turn, { side: 'enemy', position: 0 }, 'sleep');
    expect(turn.state.enemy.team[0]!.sleepTurns).toBe(turns);
  });

  it.each([
    [0, 2],
    [0.99, 5],
  ])('Confuso com o sorteio %f dura %i turnos', (roll, turns) => {
    const turn = context(idle({ statusSlug: 'burn' }), sequence(roll));
    applyStatus(turn, { side: 'enemy', position: 0 }, 'confusion');
    expect(turn.state.enemy.team[0]!.confusionTurns).toBe(turns);
    expect(turn.events).toEqual([
      {
        type: 'status_applied',
        side: 'enemy',
        position: 0,
        status: 'confusion',
      },
    ]);
  });

  it('não confunde quem já está Confuso', () => {
    const turn = context(idle({ confusionTurns: 2 }));
    applyStatus(turn, { side: 'enemy', position: 0 }, 'confusion');
    expect(turn.state.enemy.team[0]!.confusionTurns).toBe(2);
    expect(turn.events).toEqual([
      { type: 'effect_failed', side: 'enemy', position: 0 },
    ]);
  });

  it('prende', () => {
    const turn = context(idle());
    applyStatus(turn, { side: 'enemy', position: 0 }, 'trapped');
    expect(turn.state.enemy.team[0]!.isTrapped).toBe(true);
  });

  it('amedronta', () => {
    const turn = context(idle());
    applyStatus(turn, { side: 'enemy', position: 0 }, 'fear');
    expect(turn.state.enemy.team[0]!.isFeared).toBe(true);
  });
});
