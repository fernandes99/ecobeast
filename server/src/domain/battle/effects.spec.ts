import {
  always,
  eventsOf,
  FIRE,
  makeCatalog,
  makeCombatant,
  makeEffect,
  makeSkill,
  makeState,
  play,
  sequence,
} from './testing.js';
import type {
  BattleAction,
  BattleSkill,
  Combatant,
  StageSlug,
} from './types.js';

const support = (id: number, overrides: Partial<BattleSkill>): BattleSkill =>
  makeSkill({
    id,
    power: 0,
    accuracy: 0,
    category: 'support',
    targetSlug: 'self',
    ...overrides,
  });

const lowerStat = (statSlug: StageSlug, stages = -1) =>
  makeEffect({
    effectSlug: 'modify_stat',
    targetSlug: 'enemy',
    statSlug,
    stages,
  });

const raiseStat = (statSlug: StageSlug, stages = 1) =>
  makeEffect({
    effectSlug: 'modify_stat',
    targetSlug: 'self',
    statSlug,
    stages,
  });

const SCRATCH = makeSkill({ id: 1 });
const IDLE = support(2, {});
const FLAME_FANG = makeSkill({
  id: 3,
  effects: [
    makeEffect({ effectSlug: 'apply_status', chance: 10, statusSlug: 'burn' }),
  ],
});
const SPORES = support(4, {
  accuracy: 75,
  targetSlug: 'enemy',
  effects: [makeEffect({ effectSlug: 'apply_status', statusSlug: 'sleep' })],
});
const FIERCE_ROAR = support(5, {
  accuracy: 100,
  targetSlug: 'enemy',
  effects: [lowerStat('atk')],
});
const ASH_ARMOR = support(6, {
  effects: [raiseStat('def'), raiseStat('sp_def')],
});
const RESTORE = support(7, {
  effects: [makeEffect({ effectSlug: 'heal', percent: 50 })],
});
const VITAL_SAP = makeSkill({
  id: 8,
  effects: [makeEffect({ effectSlug: 'drain', percent: 50 })],
});
const SOLAR_ERUPTION = makeSkill({
  id: 9,
  power: 120,
  effects: [makeEffect({ effectSlug: 'recoil', percent: 33 })],
});
const CYCLONE = makeSkill({
  id: 10,
  effects: [makeEffect({ effectSlug: 'flinch', chance: 20 })],
});
const CLOSED_SHELL = support(11, {
  priority: 4,
  effects: [makeEffect({ effectSlug: 'protect' })],
});
const CRUSH = makeSkill({ id: 12, effects: [lowerStat('def')] });
const RECKLESS = makeSkill({
  id: 13,
  effects: [
    makeEffect({ effectSlug: 'recoil', percent: 100 }),
    makeEffect({ effectSlug: 'heal', percent: 100 }),
  ],
});
const STORM = makeSkill({
  id: 14,
  effects: [makeEffect({ effectSlug: 'set_weather' })],
});

const catalog = makeCatalog({}, [
  SCRATCH,
  IDLE,
  FLAME_FANG,
  SPORES,
  FIERCE_ROAR,
  ASH_ARMOR,
  RESTORE,
  VITAL_SAP,
  SOLAR_ERUPTION,
  CYCLONE,
  CLOSED_SHELL,
  CRUSH,
  RECKLESS,
  STORM,
]);
const USE_FIRST: BattleAction = { type: 'skill', slot: 1 };
const USE_SECOND: BattleAction = { type: 'skill', slot: 2 };

function knowing(
  skills: BattleSkill[],
  overrides: Partial<Combatant> = {},
): Combatant {
  return makeCombatant({
    skills: skills.map((skill) => ({ skillId: skill.id, currentPp: 20 })),
    stats: { hp: 19, atk: 10, def: 9, sp_atk: 11, sp_def: 9, spd: 20 },
    ...overrides,
  });
}

const idleEnemy = (overrides: Partial<Combatant> = {}) =>
  makeCombatant({ skills: [{ skillId: 2, currentPp: 20 }], ...overrides });

describe('apply_status', () => {
  it('vale com o sorteio abaixo da chance', () => {
    const { state, events } = play(
      makeState(knowing([FLAME_FANG]), idleEnemy({ elementIds: [] })),
      USE_FIRST,
      catalog,
      sequence(0, 0.9, 0.5, 0.09),
    );
    expect(state.enemy.team[0]!.statusSlug).toBe('burn');
    expect(eventsOf(events, 'status_applied')).toEqual([
      { type: 'status_applied', side: 'enemy', status: 'burn' },
    ]);
  });

  it('não vale com o sorteio na chance', () => {
    const { state } = play(
      makeState(knowing([FLAME_FANG]), idleEnemy()),
      USE_FIRST,
      catalog,
      sequence(0, 0.9, 0.5, 0.1),
    );
    expect(state.enemy.team[0]!.statusSlug).toBeNull();
  });

  it('funciona numa Técnica de suporte', () => {
    const { state } = play(
      makeState(knowing([SPORES]), idleEnemy()),
      USE_FIRST,
      catalog,
      sequence(0, 0.7, 0.5),
    );
    // Sorteou 2 turnos, e o primeiro passa aqui, quando o inimigo tenta agir.
    expect(state.enemy.team[0]).toMatchObject({
      statusSlug: 'sleep',
      sleepTurns: 1,
    });
  });

  it('Fogo não queima', () => {
    const immune = makeCatalog({}, [FLAME_FANG, IDLE]);
    immune.statusImmunities.set('burn', [FIRE]);
    const { state, events } = play(
      makeState(knowing([FLAME_FANG]), idleEnemy()),
      USE_FIRST,
      immune,
      sequence(0, 0.9, 0.5, 0),
    );
    expect(state.enemy.team[0]!.statusSlug).toBeNull();
    expect(eventsOf(events, 'effect_failed')).toEqual([
      { type: 'effect_failed', side: 'enemy' },
    ]);
  });

  it('não vale se o alvo desmaiou', () => {
    const { events } = play(
      makeState(knowing([FLAME_FANG]), idleEnemy({ currentHp: 1 })),
      USE_FIRST,
      catalog,
      sequence(0, 0.9, 0.5),
    );
    expect(eventsOf(events, 'status_applied')).toEqual([]);
  });

  it('não vale se a Técnica errou', () => {
    const { state } = play(
      makeState(knowing([SPORES]), idleEnemy()),
      USE_FIRST,
      catalog,
      always(0.8),
    );
    expect(state.enemy.team[0]!.statusSlug).toBeNull();
  });

  it('não vale com efetividade 0', () => {
    const immune = makeCatalog({ '13:1': 0 }, [FLAME_FANG, IDLE]);
    const { state } = play(
      makeState(knowing([FLAME_FANG]), idleEnemy({ elementIds: [FIRE] })),
      USE_FIRST,
      immune,
      always(0),
    );
    expect(state.enemy.team[0]!.statusSlug).toBeNull();
  });
});

describe('flinch', () => {
  it('Ciclone com o sorteio abaixo de 20% faz o alvo perder a vez', () => {
    const { state, events } = play(
      makeState(knowing([CYCLONE]), idleEnemy()),
      USE_FIRST,
      catalog,
      sequence(0, 0.9, 0.5, 0.19),
    );
    expect(eventsOf(events, 'cannot_act')).toEqual([
      { type: 'cannot_act', side: 'enemy', reason: 'fear' },
    ]);
    expect(state.enemy.team[0]!.isFeared).toBe(false);
  });

  it('não vale com o sorteio em 20%', () => {
    const { events } = play(
      makeState(knowing([CYCLONE]), idleEnemy()),
      USE_FIRST,
      catalog,
      sequence(0, 0.9, 0.5, 0.2),
    );
    expect(eventsOf(events, 'cannot_act')).toEqual([]);
  });

  it('não muda nada em quem já agiu', () => {
    const slow = knowing([CYCLONE], {
      stats: { hp: 19, atk: 10, def: 9, sp_atk: 11, sp_def: 9, spd: 1 },
    });
    const { state, events } = play(
      makeState(slow, idleEnemy()),
      USE_FIRST,
      catalog,
      sequence(0, 0.9, 0.5, 0),
    );
    expect(eventsOf(events, 'cannot_act')).toEqual([]);
    expect(state.enemy.team[0]!.isFeared).toBe(false);
  });
});

describe('modify_stat', () => {
  it('Rugido Feroz baixa o Atq do inimigo', () => {
    const { state, events } = play(
      makeState(knowing([FIERCE_ROAR]), idleEnemy()),
      USE_FIRST,
      catalog,
    );
    expect(state.enemy.team[0]!.stages.atk).toBe(-1);
    expect(eventsOf(events, 'stat_changed')).toEqual([
      {
        type: 'stat_changed',
        side: 'enemy',
        stat: 'atk',
        stages: -1,
        value: -1,
      },
    ]);
  });

  it('depois de 6 usos, dá effect_failed', () => {
    let state = makeState(knowing([FIERCE_ROAR]), idleEnemy());
    for (let use = 0; use < 6; use += 1) {
      ({ state } = play(state, USE_FIRST, catalog));
    }
    expect(state.enemy.team[0]!.stages.atk).toBe(-6);

    const { events } = play(state, USE_FIRST, catalog);
    expect(eventsOf(events, 'stat_changed')).toEqual([]);
    expect(eventsOf(events, 'effect_failed')).toEqual([
      { type: 'effect_failed', side: 'enemy' },
    ]);
  });

  it('conta só o que mudou de verdade', () => {
    const big = support(20, { effects: [raiseStat('atk', 2)] });
    const stages = { ...makeCombatant().stages, atk: 5 };
    const { events } = play(
      makeState(knowing([big], { stages }), idleEnemy()),
      USE_FIRST,
      makeCatalog({}, [big, IDLE]),
    );
    expect(eventsOf(events, 'stat_changed')[0]).toMatchObject({
      stages: 1,
      value: 6,
    });
  });

  it('aplica os efeitos em ordem, no alvo de cada um', () => {
    const { state, events } = play(
      makeState(knowing([ASH_ARMOR]), idleEnemy()),
      USE_FIRST,
      catalog,
    );
    expect(state.player.team[0]!.stages).toMatchObject({ def: 1, sp_def: 1 });
    expect(eventsOf(events, 'stat_changed').map((e) => e.stat)).toEqual([
      'def',
      'sp_def',
    ]);
  });

  it('não vale se o alvo desmaiou', () => {
    const { events } = play(
      makeState(knowing([CRUSH]), idleEnemy({ currentHp: 1 })),
      USE_FIRST,
      catalog,
    );
    expect(eventsOf(events, 'stat_changed')).toEqual([]);
  });
});

describe('heal', () => {
  it('cura a porcentagem do HP máximo', () => {
    const { state, events } = play(
      makeState(knowing([RESTORE], { currentHp: 5 }), idleEnemy()),
      USE_FIRST,
      catalog,
    );
    expect(state.player.team[0]!.currentHp).toBe(14);
    expect(eventsOf(events, 'healed')).toEqual([
      { type: 'healed', side: 'player', amount: 9, hp: 14 },
    ]);
  });

  it('não passa do HP máximo', () => {
    const { events } = play(
      makeState(knowing([RESTORE], { currentHp: 15 }), idleEnemy()),
      USE_FIRST,
      catalog,
    );
    expect(eventsOf(events, 'healed')[0]).toMatchObject({ amount: 4, hp: 19 });
  });

  it('com HP cheio, dá effect_failed', () => {
    const { events } = play(
      makeState(knowing([RESTORE]), idleEnemy()),
      USE_FIRST,
      catalog,
    );
    expect(eventsOf(events, 'healed')).toEqual([]);
    expect(eventsOf(events, 'effect_failed')).toEqual([
      { type: 'effect_failed', side: 'player' },
    ]);
  });
});

describe('drain', () => {
  it('Seiva Vital cura metade do dano', () => {
    const { events } = play(
      makeState(knowing([VITAL_SAP], { currentHp: 10 }), idleEnemy()),
      USE_FIRST,
      catalog,
    );
    expect(eventsOf(events, 'damage')[0]).toMatchObject({ damage: 5 });
    expect(eventsOf(events, 'healed')).toEqual([
      { type: 'healed', side: 'player', amount: 2, hp: 12 },
    ]);
  });

  it('cura ao menos 1', () => {
    const { events } = play(
      makeState(
        knowing([VITAL_SAP], { currentHp: 10 }),
        idleEnemy({ currentHp: 1 }),
      ),
      USE_FIRST,
      catalog,
    );
    expect(eventsOf(events, 'healed')[0]).toMatchObject({ amount: 1 });
  });

  it('com HP cheio, não cura nem falha', () => {
    const { events } = play(
      makeState(knowing([VITAL_SAP]), idleEnemy()),
      USE_FIRST,
      catalog,
    );
    expect(eventsOf(events, 'healed')).toEqual([]);
    expect(eventsOf(events, 'effect_failed')).toEqual([]);
  });

  it('cura mesmo se o alvo desmaiou', () => {
    const { state } = play(
      makeState(
        knowing([VITAL_SAP], { currentHp: 10 }),
        idleEnemy({ currentHp: 4 }),
      ),
      USE_FIRST,
      catalog,
    );
    expect(state.player.team[0]!.currentHp).toBe(12);
  });
});

describe('recoil', () => {
  it('Erupção Solar tira 33% do dano do autor', () => {
    const { state, events } = play(
      makeState(knowing([SOLAR_ERUPTION]), idleEnemy()),
      USE_FIRST,
      catalog,
    );
    expect(eventsOf(events, 'damage')[0]).toMatchObject({ damage: 11 });
    expect(eventsOf(events, 'recoil')).toEqual([
      { type: 'recoil', side: 'player', damage: 3, hp: 16 },
    ]);
    expect(state.player.team[0]!.currentHp).toBe(16);
  });

  it('tira ao menos 1', () => {
    const { events } = play(
      makeState(knowing([SOLAR_ERUPTION]), idleEnemy({ currentHp: 1 })),
      USE_FIRST,
      catalog,
    );
    expect(eventsOf(events, 'recoil')[0]).toMatchObject({ damage: 1 });
  });

  it('vale mesmo se o alvo desmaiou', () => {
    const { events } = play(
      makeState(knowing([SOLAR_ERUPTION]), idleEnemy({ currentHp: 3 })),
      USE_FIRST,
      catalog,
    );
    expect(eventsOf(events, 'recoil')).toHaveLength(1);
  });

  it('um efeito no autor não vale depois que ele desmaiou', () => {
    const { state, events } = play(
      makeState(knowing([RECKLESS], { currentHp: 1 }), [idleEnemy()]),
      USE_FIRST,
      catalog,
    );
    expect(state.result).toBe('defeat');
    expect(eventsOf(events, 'healed')).toEqual([]);
  });
});

describe('protect', () => {
  const shell = () =>
    knowing([CLOSED_SHELL, SCRATCH], {
      stats: { hp: 19, atk: 10, def: 9, sp_atk: 11, sp_def: 9, spd: 1 },
    });
  const scratcher = () => knowing([SCRATCH]);

  it('Casca Fechada age antes e bloqueia o golpe do turno', () => {
    const { state, events } = play(
      makeState(shell(), scratcher()),
      USE_FIRST,
      catalog,
    );
    expect(eventsOf(events, 'skill_used').map((e) => e.side)).toEqual([
      'player',
      'enemy',
    ]);
    expect(eventsOf(events, 'blocked')).toEqual([
      { type: 'blocked', side: 'player' },
    ]);
    expect(state.player.team[0]!.currentHp).toBe(19);
    expect(state.enemy.team[0]!.skills[0]!.currentPp).toBe(19);
  });

  it('não bloqueia o golpe do turno seguinte', () => {
    const first = play(makeState(shell(), scratcher()), USE_FIRST, catalog);
    expect(first.state.player.team[0]!.isProtected).toBe(false);

    const { state, events } = play(first.state, USE_SECOND, catalog);
    expect(eventsOf(events, 'blocked')).toEqual([]);
    expect(state.player.team[0]!.currentHp).toBeLessThan(19);
  });

  it('bloqueia também os efeitos', () => {
    const { state } = play(
      makeState(shell(), knowing([FIERCE_ROAR])),
      USE_FIRST,
      catalog,
    );
    expect(state.player.team[0]!.stages.atk).toBe(0);
  });

  it('não impede o adversário de usar uma Técnica em si mesmo', () => {
    const { state, events } = play(
      makeState(shell(), knowing([ASH_ARMOR])),
      USE_FIRST,
      catalog,
    );
    expect(eventsOf(events, 'blocked')).toEqual([]);
    expect(state.enemy.team[0]!.stages.def).toBe(1);
  });
});

it('um efeito que o motor não conhece é ignorado', () => {
  const { events } = play(
    makeState(knowing([STORM]), idleEnemy()),
    USE_FIRST,
    catalog,
  );
  expect(eventsOf(events, 'effect_failed')).toEqual([]);
});
