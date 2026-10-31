import { applyAction, startBattle } from './engine.js';
import {
  always,
  eventsOf,
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
  BattleEvent,
  BattleSkill,
  BattleState,
  Combatant,
  Random,
} from './types.js';

const SCRATCH = makeSkill({ id: 1 });
const QUICK = makeSkill({ id: 2, priority: 1 });
const SHAKY = makeSkill({ id: 3, accuracy: 50 });
const IDLE = makeSkill({
  id: 4,
  power: 0,
  accuracy: 0,
  category: 'support',
  targetSlug: 'self',
});
const BACKFIRE = makeSkill({
  id: 5,
  effects: [makeEffect({ effectSlug: 'recoil', percent: 100 })],
});
const catalog = makeCatalog({}, [SCRATCH, QUICK, SHAKY, IDLE, BACKFIRE]);
const USE_FIRST: BattleAction = { type: 'skill', slot: 1 };

function knower(
  skill: BattleSkill,
  overrides: Partial<Combatant> = {},
): Combatant {
  return makeCombatant({
    skills: [{ skillId: skill.id, currentPp: 10 }],
    ...overrides,
  });
}

function fighter(overrides: Partial<Combatant> = {}): Combatant {
  return knower(SCRATCH, overrides);
}

function idler(overrides: Partial<Combatant> = {}): Combatant {
  return knower(IDLE, overrides);
}

function withSpeed(spd: number, overrides: Partial<Combatant> = {}): Combatant {
  return fighter({
    stats: { hp: 19, atk: 10, def: 9, sp_atk: 11, sp_def: 9, spd },
    ...overrides,
  });
}

function actingOrder(events: BattleEvent[]): string[] {
  return eventsOf(events, 'skill_used').map((event) => event.side);
}

/** Uma fonte de sorteio previsível, para jogar uma batalha inteira. */
function seeded(seed: number): Random {
  let current = seed;
  return () => {
    current = (current * 16807) % 2147483647;
    return current / 2147483647;
  };
}

function playUntilEnd(random: Random): {
  state: BattleState;
  events: BattleEvent[];
} {
  let { state, events } = startBattle(
    [fighter()],
    [fighter()],
    true,
    catalog,
    random,
  );
  while (state.phase === 'choose_action') {
    const outcome = play(state, USE_FIRST, catalog, random);
    state = outcome.state;
    events = [...events, ...outcome.events];
  }
  return { state, events };
}

describe('fuga', () => {
  const FLEE: BattleAction = { type: 'flee' };

  it('com sucesso, termina a batalha com fled', () => {
    const { state, events } = play(
      makeState(fighter(), fighter()),
      FLEE,
      catalog,
      sequence(0.2),
    );
    expect(state).toMatchObject({ phase: 'ended', result: 'fled', turn: 1 });
    expect(events).toEqual([{ type: 'battle_ended', result: 'fled' }]);
  });

  it('com falha, o inimigo age e o turno avança', () => {
    const { state, events } = play(
      makeState(fighter(), fighter()),
      FLEE,
      catalog,
      sequence(0.19, 0, 0.9, 0.5),
    );
    expect(events[0]).toEqual({ type: 'flee_failed' });
    expect(actingOrder(events)).toEqual(['enemy']);
    expect(state.player.team[0]!.currentHp).toBe(14);
    expect(state).toMatchObject({ phase: 'choose_action', turn: 2 });
  });

  it('com falha, o fim do turno acontece', () => {
    const { events } = play(
      makeState(fighter({ statusSlug: 'poison' }), idler()),
      FLEE,
      catalog,
      sequence(0.19, 0),
    );
    expect(eventsOf(events, 'status_damage')).toHaveLength(1);
  });

  it('com falha, o inimigo pode vencer', () => {
    const { state } = play(
      makeState(fighter({ currentHp: 1 }), fighter()),
      FLEE,
      catalog,
      sequence(0.19, 0, 0.9, 0.5),
    );
    expect(state.result).toBe('defeat');
  });
});

describe('desmaio', () => {
  const BENCH_TURN = { type: 'skill', slot: 1 } as const;
  const recklessAtOneHp = () =>
    knower(BACKFIRE, { currentHp: 1, stats: withSpeed(20).stats });

  it('a fase vira choose_next, e quem caiu não age', () => {
    const { state, events } = play(
      makeState([withSpeed(5, { currentHp: 1 }), fighter()], withSpeed(20)),
      BENCH_TURN,
      catalog,
    );
    expect(state.phase).toBe('choose_next');
    expect(state.result).toBeNull();
    expect(actingOrder(events)).toEqual(['enemy']);
    expect(eventsOf(events, 'fainted')).toEqual([
      { type: 'fainted', side: 'player' },
    ]);
  });

  it('a escolhida entra sem gastar turno nem dar ação ao inimigo', () => {
    const fainted = play(
      makeState(
        [withSpeed(5, { currentHp: 1 }), fighter({ speciesId: 4 })],
        withSpeed(20),
      ),
      BENCH_TURN,
      catalog,
    );
    const { state, events } = play(
      fainted.state,
      { type: 'switch', team_index: 1 },
      catalog,
      sequence(),
    );
    expect(state.player.activeIndex).toBe(1);
    expect(state.phase).toBe('choose_action');
    expect(state.turn).toBe(fainted.state.turn);
    expect(events).toEqual([
      {
        type: 'creature_entered',
        side: 'player',
        species_id: 4,
        level: 5,
        max_hp: 19,
      },
    ]);
  });

  it('a escolhida entra com estágios zerados', () => {
    const next = fighter();
    next.stages.atk = 3;
    const { state } = play(
      makeState([fighter({ currentHp: 0 }), next], fighter(), {
        phase: 'choose_next',
      }),
      { type: 'switch', team_index: 1 },
      catalog,
    );
    expect(state.player.team[1]!.stages.atk).toBe(0);
  });

  it('a escolhida Adormecida sorteia os turnos de novo', () => {
    const { state } = play(
      makeState(
        [fighter({ currentHp: 0 }), fighter({ statusSlug: 'sleep' })],
        fighter(),
        { phase: 'choose_next' },
      ),
      { type: 'switch', team_index: 1 },
      catalog,
      sequence(0.99),
    );
    expect(state.player.team[1]!.sleepTurns).toBe(3);
  });

  it('limpa todo o status', () => {
    const { state } = play(
      makeState(
        [
          withSpeed(5, {
            currentHp: 1,
            statusSlug: 'poison',
            confusionTurns: 3,
          }),
          fighter(),
        ],
        withSpeed(20),
      ),
      BENCH_TURN,
      catalog,
    );
    expect(state.player.team[0]).toMatchObject({
      statusSlug: null,
      confusionTurns: 0,
    });
  });

  it('todos caídos dão defeat', () => {
    const { state, events } = play(
      makeState(withSpeed(5, { currentHp: 1 }), withSpeed(20)),
      BENCH_TURN,
      catalog,
    );
    expect(state).toMatchObject({ phase: 'ended', result: 'defeat' });
    expect(events.at(-1)).toEqual({ type: 'battle_ended', result: 'defeat' });
  });

  it('recuo que derruba os dois dá victory', () => {
    const { state, events } = play(
      makeState(recklessAtOneHp(), fighter({ currentHp: 1 })),
      BENCH_TURN,
      catalog,
    );
    expect(state.result).toBe('victory');
    expect(eventsOf(events, 'fainted').map((e) => e.side)).toEqual([
      'enemy',
      'player',
    ]);
  });

  it('os dois sem criaturas no fim do turno dá victory', () => {
    const { state } = play(
      makeState(
        idler({ statusSlug: 'burn', currentHp: 1 }),
        idler({ statusSlug: 'burn', currentHp: 1 }),
      ),
      BENCH_TURN,
      catalog,
    );
    expect(state.result).toBe('victory');
  });

  it('recuo que derruba os dois, com reserva do jogador, ainda é victory', () => {
    const { state } = play(
      makeState([recklessAtOneHp(), fighter()], fighter({ currentHp: 1 })),
      BENCH_TURN,
      catalog,
    );
    expect(state.result).toBe('victory');
  });

  it('com equipe de inimigos, o próximo entra sozinho', () => {
    const { state, events } = play(
      makeState(withSpeed(20), [
        withSpeed(5, { currentHp: 1 }),
        withSpeed(5, { speciesId: 9 }),
      ]),
      BENCH_TURN,
      catalog,
    );
    expect(state.enemy.activeIndex).toBe(1);
    expect(state).toMatchObject({ phase: 'choose_action', turn: 2 });
    expect(eventsOf(events, 'creature_entered')[0]).toMatchObject({
      side: 'enemy',
      species_id: 9,
    });
  });

  it('o inimigo pula quem já caiu', () => {
    const { state } = play(
      makeState(withSpeed(20), [
        withSpeed(5, { currentHp: 1 }),
        withSpeed(5, { currentHp: 0 }),
        withSpeed(5),
      ]),
      BENCH_TURN,
      catalog,
    );
    expect(state.enemy.activeIndex).toBe(2);
  });

  it('caindo os dois, o próximo inimigo entra e o jogador escolhe', () => {
    const { state } = play(
      makeState(
        [recklessAtOneHp(), fighter()],
        [fighter({ currentHp: 1 }), fighter()],
      ),
      BENCH_TURN,
      catalog,
    );
    expect(state.enemy.activeIndex).toBe(1);
    expect(state.phase).toBe('choose_next');
  });

  it('sem alvo de pé, a ação não acontece e não gasta PP', () => {
    const enemy = knower(BACKFIRE, {
      currentHp: 1,
      stats: { hp: 19, atk: 10, def: 9, sp_atk: 11, sp_def: 9, spd: 20 },
    });
    const { state, events } = play(
      makeState(withSpeed(5), [enemy, fighter()]),
      BENCH_TURN,
      catalog,
    );
    expect(actingOrder(events)).toEqual(['enemy']);
    expect(state.player.team[0]!.skills[0]!.currentPp).toBe(10);
  });

  it('uma Técnica em si mesmo vale mesmo sem alvo de pé', () => {
    const enemy = knower(BACKFIRE, {
      currentHp: 1,
      stats: { hp: 19, atk: 10, def: 9, sp_atk: 11, sp_def: 9, spd: 20 },
    });
    const { state } = play(
      makeState(idler({ stats: withSpeed(5).stats }), [enemy, fighter()]),
      BENCH_TURN,
      catalog,
    );
    expect(state.player.team[0]!.skills[0]!.currentPp).toBe(9);
  });
});

describe('startBattle', () => {
  it('põe em campo a primeira criatura de pé de cada lado', () => {
    const fallen = fighter({ currentHp: 0 });
    const { state } = startBattle(
      [fallen, fighter()],
      [fighter()],
      true,
      catalog,
      sequence(),
    );
    expect(state.player.activeIndex).toBe(1);
    expect(state.enemy.activeIndex).toBe(0);
  });

  it('começa no turno 1, na fase de escolher a ação', () => {
    const { state } = startBattle(
      [fighter()],
      [fighter()],
      false,
      catalog,
      sequence(),
    );
    expect(state).toMatchObject({
      phase: 'choose_action',
      result: null,
      turn: 1,
      canFlee: false,
    });
  });

  it('avisa o começo e a entrada das duas criaturas', () => {
    const { events } = startBattle(
      [fighter()],
      [fighter({ speciesId: 7, level: 4 })],
      true,
      catalog,
      sequence(),
    );
    expect(events).toEqual([
      { type: 'battle_started' },
      {
        type: 'creature_entered',
        side: 'player',
        species_id: 1,
        level: 5,
        max_hp: 19,
      },
      {
        type: 'creature_entered',
        side: 'enemy',
        species_id: 7,
        level: 4,
        max_hp: 19,
      },
    ]);
  });

  it('não altera as equipes recebidas', () => {
    const team = [fighter()];
    const copy = structuredClone(team);
    const { state } = startBattle(team, [fighter()], true, catalog, sequence());
    state.player.team[0]!.currentHp = 1;
    expect(team).toEqual(copy);
  });
});

describe('applyAction', () => {
  describe('ordem', () => {
    it('quem tem mais Velocidade age primeiro', () => {
      const state = makeState(withSpeed(20), withSpeed(5));
      expect(actingOrder(play(state, USE_FIRST, catalog).events)).toEqual([
        'player',
        'enemy',
      ]);

      const reversed = makeState(withSpeed(5), withSpeed(20));
      expect(actingOrder(play(reversed, USE_FIRST, catalog).events)).toEqual([
        'enemy',
        'player',
      ]);
    });

    it('Técnica de prioridade passa na frente', () => {
      const player = withSpeed(5, {
        skills: [{ skillId: 2, currentPp: 10 }],
      });
      const state = makeState(player, withSpeed(20));
      expect(actingOrder(play(state, USE_FIRST, catalog).events)).toEqual([
        'player',
        'enemy',
      ]);
    });
  });

  describe('dano', () => {
    it('tira HP do alvo e conta no evento', () => {
      const { state, events } = play(
        makeState(withSpeed(20), withSpeed(5)),
        USE_FIRST,
        catalog,
      );
      expect(state.enemy.team[0]!.currentHp).toBe(14);
      expect(eventsOf(events, 'damage')[0]).toEqual({
        type: 'damage',
        side: 'enemy',
        damage: 5,
        hp: 14,
        multiplier: 1,
        is_critical: false,
      });
    });

    it('um crítico aparece no evento', () => {
      const { events } = play(
        makeState(withSpeed(20), withSpeed(5)),
        USE_FIRST,
        catalog,
        always(0),
      );
      expect(eventsOf(events, 'damage')[0]).toMatchObject({
        damage: 7,
        is_critical: true,
      });
    });

    it('o dano no evento é o HP que o alvo perdeu', () => {
      const { events } = play(
        makeState(withSpeed(20), withSpeed(5, { currentHp: 2 })),
        USE_FIRST,
        catalog,
      );
      expect(eventsOf(events, 'damage')[0]).toMatchObject({
        damage: 2,
        hp: 0,
      });
    });

    it('efetividade 0 dá no_effect e não causa dano', () => {
      const immune = makeCatalog({ '13:1': 0 }, [SCRATCH]);
      const { state, events } = play(
        makeState(withSpeed(20), withSpeed(5)),
        USE_FIRST,
        immune,
      );
      expect(state.enemy.team[0]!.currentHp).toBe(19);
      expect(eventsOf(events, 'no_effect')[0]).toEqual({
        type: 'no_effect',
        side: 'enemy',
      });
    });
  });

  describe('PP', () => {
    it('usar gasta 1 PP', () => {
      const { state } = play(
        makeState(fighter(), fighter()),
        USE_FIRST,
        catalog,
      );
      expect(state.player.team[0]!.skills[0]!.currentPp).toBe(9);
      expect(state.enemy.team[0]!.skills[0]!.currentPp).toBe(9);
    });

    it('errar também gasta', () => {
      const player = fighter({ skills: [{ skillId: 3, currentPp: 10 }] });
      const { state, events } = play(
        makeState(player, fighter()),
        USE_FIRST,
        catalog,
        always(0.9),
      );
      expect(state.player.team[0]!.skills[0]!.currentPp).toBe(9);
      expect(eventsOf(events, 'missed')).toEqual([
        { type: 'missed', side: 'player' },
      ]);
    });
  });

  describe('o fim', () => {
    it('atacar até vencer dá victory, com battle_ended por último', () => {
      let state = makeState(withSpeed(20), withSpeed(5));
      let events: BattleEvent[] = [];
      while (state.phase === 'choose_action') {
        ({ state, events } = play(state, USE_FIRST, catalog));
      }
      expect(state.phase).toBe('ended');
      expect(state.result).toBe('victory');
      expect(events.at(-1)).toEqual({
        type: 'battle_ended',
        result: 'victory',
      });
    });

    it('quem caiu não age', () => {
      const { events } = play(
        makeState(withSpeed(20), withSpeed(5, { currentHp: 1 })),
        USE_FIRST,
        catalog,
      );
      expect(actingOrder(events)).toEqual(['player']);
      expect(eventsOf(events, 'fainted')).toEqual([
        { type: 'fainted', side: 'enemy' },
      ]);
    });

    it('o turno avança', () => {
      const { state } = play(
        makeState(fighter(), fighter()),
        USE_FIRST,
        catalog,
      );
      expect(state.turn).toBe(2);
    });
  });

  it('com a mesma fonte de sorteio, termina sempre igual', () => {
    expect(playUntilEnd(seeded(42))).toEqual(playUntilEnd(seeded(42)));
    expect(playUntilEnd(seeded(42)).state.result).not.toBeNull();
  });

  it('sem PP dos dois lados, a luta termina', () => {
    const noPp = () => fighter({ skills: [{ skillId: 1, currentPp: 0 }] });
    let state = makeState(noPp(), noPp());
    for (let turn = 0; state.phase !== 'ended' && turn < 20; turn += 1) {
      ({ state } = play(state, { type: 'emergency' }, catalog));
    }
    expect(state.phase).toBe('ended');
  });

  it('não altera o estado recebido', () => {
    const state = makeState(fighter(), fighter());
    const copy = structuredClone(state);
    play(state, USE_FIRST, catalog);
    expect(state).toEqual(copy);
  });

  describe('ações inválidas', () => {
    const noPp = fighter({ skills: [{ skillId: 1, currentPp: 0 }] });
    const ongoing = makeState(fighter(), fighter());
    const benchFallen = makeState(
      [fighter({ currentHp: 0 }), fighter({ currentHp: 0 }), fighter()],
      fighter(),
      { phase: 'choose_next' },
    );

    it.each<[string, BattleState, BattleAction, string]>([
      [
        'slot vazio',
        ongoing,
        { type: 'skill', slot: 2 },
        'Essa Técnica não existe.',
      ],
      [
        'slot zero',
        ongoing,
        { type: 'skill', slot: 0 },
        'Essa Técnica não existe.',
      ],
      [
        'Técnica sem PP',
        makeState(noPp, fighter()),
        USE_FIRST,
        'Essa Técnica está sem PP.',
      ],
      [
        'emergência com PP',
        ongoing,
        { type: 'emergency' },
        'Ainda há Técnicas com PP.',
      ],
      [
        'fugir de um Domador',
        makeState(fighter(), fighter(), { canFlee: false }),
        { type: 'flee' },
        'Não dá para fugir agora.',
      ],
      [
        'fugir estando Preso',
        makeState(fighter({ isTrapped: true }), fighter()),
        { type: 'flee' },
        'Não dá para fugir agora.',
      ],
      [
        'agir quando é hora de escolher o próximo',
        benchFallen,
        USE_FIRST,
        'Escolha o próximo Ecobeast.',
      ],
      [
        'trocar para quem caiu',
        benchFallen,
        { type: 'switch', team_index: 1 },
        'Esse Ecobeast não pode lutar.',
      ],
      [
        'trocar para quem não existe',
        benchFallen,
        { type: 'switch', team_index: 9 },
        'Esse Ecobeast não pode lutar.',
      ],
      [
        'trocar por vontade própria',
        makeState([fighter(), fighter()], fighter()),
        { type: 'switch', team_index: 1 },
        'Esse Ecobeast não pode lutar.',
      ],
      [
        'agir depois do fim',
        makeState(fighter(), fighter(), { phase: 'ended' }),
        USE_FIRST,
        'A batalha já terminou.',
      ],
    ])('%s', (_name, state, action, message) => {
      const copy = structuredClone(state);
      expect(applyAction(state, action, catalog, sequence())).toEqual({
        error: message,
      });
      expect(state).toEqual(copy);
    });
  });
});
