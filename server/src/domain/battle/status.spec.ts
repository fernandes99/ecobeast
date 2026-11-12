import {
  applyStatus,
  applyStatusDamage,
  canAct,
  faintIfDown,
} from './status.js';
import {
  always,
  contextOf,
  FIRE,
  makeCatalog,
  makeCombatant,
  makeSkill,
  makeState,
  PLAYER,
  sequence,
  WATER,
} from './testing.js';
import type { BattleCatalog, Combatant, Random, TurnContext } from './types.js';

const SCRATCH = makeSkill({ id: 1 });
const IDLE = makeSkill({
  id: 2,
  power: 0,
  accuracy: 0,
  category: 'support',
  targetSlug: 'self',
});
const catalog = makeCatalog({}, [SCRATCH, IDLE]);

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

function tryToAct(player: Combatant, random: Random = sequence()) {
  const turn = contextOf(makeState(player, idle()), catalog, random);
  const acts = canAct(turn, PLAYER);
  return { acts, events: turn.events, creature: turn.state.player.team[0]! };
}

describe('dano de status', () => {
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
    const turn = contextOf(makeState(player, idle()), catalog);
    applyStatusDamage(turn, PLAYER);
    expect(turn.state.player.team[0]!.currentHp).toBe(hp);
    expect(turn.events).toEqual([
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

  it('pode derrubar quem o sofre', () => {
    const player = idle({ statusSlug: 'burn', currentHp: 1 });
    const turn = contextOf(makeState(player, idle()), catalog);
    applyStatusDamage(turn, PLAYER);
    expect(turn.events.at(-1)).toEqual({
      type: 'fainted',
      side: 'player',
      position: 0,
    });
    expect(turn.state.player.team[0]!.statusSlug).toBeNull();
  });

  it('sem status, não faz nada', () => {
    const turn = contextOf(makeState(idle(), idle()), catalog);
    applyStatusDamage(turn, PLAYER);
    expect(turn.events).toEqual([]);
  });
});

describe('Paralisado', () => {
  const paralyzed = () => attacker({ statusSlug: 'paralysis' });

  it('perde a vez com o sorteio abaixo de 25%', () => {
    const { acts, events } = tryToAct(paralyzed(), sequence(0.24));
    expect(acts).toBe(false);
    expect(events).toEqual([
      { type: 'cannot_act', side: 'player', position: 0, reason: 'paralysis' },
    ]);
  });

  it('age com o sorteio em 25%', () => {
    const { acts, events } = tryToAct(paralyzed(), sequence(0.25));
    expect(acts).toBe(true);
    expect(events).toEqual([]);
  });
});

describe('Adormecido', () => {
  it('não age nas vezes sorteadas e age na vez em que acorda', () => {
    const turn = contextOf(
      makeState(attacker({ statusSlug: 'sleep', sleepTurns: 2 }), idle()),
      catalog,
      sequence(),
    );
    expect(canAct(turn, PLAYER)).toBe(false);
    expect(canAct(turn, PLAYER)).toBe(false);
    expect(turn.events).toEqual([
      { type: 'cannot_act', side: 'player', position: 0, reason: 'sleep' },
      { type: 'cannot_act', side: 'player', position: 0, reason: 'sleep' },
    ]);

    expect(canAct(turn, PLAYER)).toBe(true);
    expect(turn.events.at(-1)).toEqual({
      type: 'woke_up',
      side: 'player',
      position: 0,
    });
    expect(turn.state.player.team[0]).toMatchObject({
      statusSlug: null,
      sleepTurns: 0,
    });
  });
});

describe('Congelado', () => {
  const frozen = () => attacker({ statusSlug: 'freeze' });

  it('descongela com o sorteio abaixo de 20% e age na mesma vez', () => {
    const { acts, events, creature } = tryToAct(frozen(), always(0.19));
    expect(acts).toBe(true);
    expect(events).toEqual([{ type: 'thawed', side: 'player', position: 0 }]);
    expect(creature.statusSlug).toBeNull();
  });

  it('não age com o sorteio em 20%', () => {
    const { acts, events, creature } = tryToAct(frozen(), always(0.2));
    expect(acts).toBe(false);
    expect(events).toEqual([
      { type: 'cannot_act', side: 'player', position: 0, reason: 'freeze' },
    ]);
    expect(creature.statusSlug).toBe('freeze');
  });
});

describe('Confuso', () => {
  const confused = (overrides: Partial<Combatant> = {}) =>
    attacker({ confusionTurns: 3, ...overrides });

  it('se atinge com o sorteio abaixo de 33% e perde a vez', () => {
    const { acts, events, creature } = tryToAct(confused(), sequence(0.32, 0));
    expect(acts).toBe(false);
    expect(events).toEqual([
      { type: 'confused_hit', side: 'player', position: 0, damage: 4, hp: 15 },
    ]);
    expect(creature.confusionTurns).toBe(2);
  });

  it('age com o sorteio em 33%', () => {
    const { acts, events } = tryToAct(confused(), sequence(0.33));
    expect(acts).toBe(true);
    expect(events).toEqual([]);
  });

  it('avisa quando passa', () => {
    const { acts, events, creature } = tryToAct(
      confused({ confusionTurns: 1 }),
      sequence(0.5),
    );
    expect(acts).toBe(true);
    expect(events).toEqual([
      {
        type: 'status_ended',
        side: 'player',
        position: 0,
        status: 'confusion',
      },
    ]);
    expect(creature.confusionTurns).toBe(0);
  });

  it('pode se derrubar', () => {
    const turn = contextOf(
      makeState(confused({ currentHp: 1, confusionTurns: 1 }), idle()),
      catalog,
      always(0),
    );
    expect(canAct(turn, PLAYER)).toBe(false);
    faintIfDown(turn, PLAYER);
    expect(turn.events.map((event) => event.type)).toEqual([
      'confused_hit',
      'fainted',
    ]);
  });
});

describe('Amedrontado', () => {
  it('perde a vez', () => {
    const { acts, events } = tryToAct(attacker({ isFeared: true }));
    expect(acts).toBe(false);
    expect(events).toEqual([
      { type: 'cannot_act', side: 'player', position: 0, reason: 'fear' },
    ]);
  });

  it('vem antes dos outros motivos', () => {
    const { events, creature } = tryToAct(
      attacker({ isFeared: true, statusSlug: 'sleep', sleepTurns: 2 }),
    );
    expect(events).toEqual([
      { type: 'cannot_act', side: 'player', position: 0, reason: 'fear' },
    ]);
    expect(creature.sleepTurns).toBe(2);
  });
});

describe('desmaio', () => {
  it('limpa o status e os voláteis', () => {
    const player = attacker({
      currentHp: 0,
      statusSlug: 'poison',
      confusionTurns: 3,
      isTrapped: true,
    });
    const turn = contextOf(makeState(player, idle()), catalog);
    faintIfDown(turn, PLAYER);
    expect(turn.state.player.team[0]).toMatchObject({
      statusSlug: null,
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
