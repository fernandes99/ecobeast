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
        hp: 19,
        status: null,
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
        hp: 19,
        status: null,
      },
      {
        type: 'creature_entered',
        side: 'enemy',
        species_id: 7,
        level: 4,
        max_hp: 19,
        hp: 19,
        status: null,
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
        'trocar para quem está em campo',
        makeState([fighter(), fighter()], fighter()),
        { type: 'switch', team_index: 0 },
        'Esse Ecobeast já está em campo.',
      ],
      [
        'trocar no turno para quem tem 0 HP',
        makeState([fighter(), fighter({ currentHp: 0 })], fighter()),
        { type: 'switch', team_index: 1 },
        'Esse Ecobeast não pode lutar.',
      ],
      [
        'trocar no turno para quem não existe',
        makeState([fighter(), fighter()], fighter()),
        { type: 'switch', team_index: 9 },
        'Esse Ecobeast não pode lutar.',
      ],
      [
        'trocar estando Preso',
        makeState([fighter({ isTrapped: true }), fighter()], fighter()),
        { type: 'switch', team_index: 1 },
        'Não dá para trocar agora.',
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

describe('troca durante a luta', () => {
  const SWITCH: BattleAction = { type: 'switch', team_index: 1 };

  it('põe o outro em campo, e o turno avança', () => {
    const { state } = play(
      makeState([idler(), idler({ speciesId: 4 })], idler()),
      SWITCH,
      catalog,
    );
    expect(state.player.activeIndex).toBe(1);
    expect(state.phase).toBe('choose_action');
    expect(state.turn).toBe(2);
  });

  it('quem entra chega antes de um inimigo mais rápido', () => {
    const { events } = play(
      makeState([idler(), withSpeed(1)], withSpeed(99)),
      SWITCH,
      catalog,
    );
    expect(events.map((event) => event.type).slice(0, 2)).toEqual([
      'creature_entered',
      'skill_used',
    ]);
  });

  it('só o inimigo age no turno', () => {
    const { events } = play(
      makeState([idler(), fighter()], fighter()),
      SWITCH,
      catalog,
    );
    expect(actingOrder(events)).toEqual(['enemy']);
  });

  it('o ataque do inimigo acerta quem entrou', () => {
    const { state } = play(
      makeState([idler(), idler()], fighter()),
      SWITCH,
      catalog,
    );
    expect(state.player.team[0]!.currentHp).toBe(19);
    expect(state.player.team[1]!.currentHp).toBeLessThan(19);
  });

  it('creature_entered traz o HP e o status de antes do ataque', () => {
    const { events } = play(
      makeState(
        [idler(), idler({ currentHp: 12, statusSlug: 'poison' })],
        fighter(),
      ),
      SWITCH,
      catalog,
    );
    expect(eventsOf(events, 'creature_entered')).toEqual([
      {
        type: 'creature_entered',
        side: 'player',
        species_id: 1,
        level: 5,
        max_hp: 19,
        hp: 12,
        status: 'poison',
      },
    ]);
  });

  it('quem saiu mantém HP, status e PP', () => {
    const leaving = idler({
      currentHp: 7,
      statusSlug: 'poison',
      skills: [{ skillId: IDLE.id, currentPp: 3 }],
    });
    const { state } = play(
      makeState([leaving, idler()], idler()),
      SWITCH,
      catalog,
    );
    expect(state.player.team[0]).toMatchObject({
      currentHp: 7,
      statusSlug: 'poison',
      skills: [{ skillId: IDLE.id, currentPp: 3 }],
    });
  });

  it('quem volta vem sem mudanças de atributos nem efeitos temporários', () => {
    const back = idler({ confusionTurns: 3, isTrapped: true });
    back.stages.atk = 2;
    const { state } = play(
      makeState([idler(), back], idler()),
      SWITCH,
      catalog,
    );
    expect(state.player.team[1]).toMatchObject({
      confusionTurns: 0,
      isTrapped: false,
    });
    expect(state.player.team[1]!.stages.atk).toBe(0);
  });

  it('o veneno de quem entrou dói no fim do turno', () => {
    const { events, state } = play(
      makeState([idler(), idler({ statusSlug: 'poison' })], idler()),
      SWITCH,
      catalog,
    );
    expect(eventsOf(events, 'status_damage')[0]).toMatchObject({
      side: 'player',
    });
    expect(state.player.team[1]!.currentHp).toBeLessThan(19);
  });

  it('se o inimigo derrubar quem entrou, o jogador escolhe o próximo', () => {
    const { state } = play(
      makeState([idler(), idler({ currentHp: 1 })], fighter()),
      SWITCH,
      catalog,
    );
    expect(state.player.team[1]!.currentHp).toBe(0);
    expect(state.phase).toBe('choose_next');
  });

  it('o inimigo que cai no fim do turno dá a vitória', () => {
    const { state } = play(
      makeState(
        [idler(), idler()],
        idler({ currentHp: 1, statusSlug: 'poison' }),
      ),
      SWITCH,
      catalog,
    );
    expect(state.result).toBe('victory');
  });
});

describe('captura', () => {
  const SPHERE = 1;
  const TONIC = 4;
  const FAGULHO = 1;
  const RARE_SPECIES = 2;
  const SUCCESS = always(0.1);
  const FAILURE = always(0.9);
  const STRONG = { hp: 19, atk: 500, def: 9, sp_atk: 11, sp_def: 9, spd: 11 };
  const spheres = makeCatalog(
    {},
    [SCRATCH, IDLE],
    {
      [SPHERE]: { healAmount: null, curesStatus: false, captureBonus: 1 },
      [TONIC]: { healAmount: 8, curesStatus: false },
    },
    { [FAGULHO]: 45, [RARE_SPECIES]: 0 },
  );
  const bag = (itemId = SPHERE, quantity = 1) => [
    { itemId, quantity, used: 0 },
  ];
  const capture = (itemId = SPHERE): BattleAction => ({
    type: 'capture',
    item_id: itemId,
  });
  const refusal = (state: BattleState, action: BattleAction) => {
    const outcome = applyAction(state, action, spheres, always(0.5));
    return 'error' in outcome ? outcome.error : null;
  };

  it('com sucesso, a luta termina sem o inimigo agir', () => {
    const state = makeState(idler(), idler(), { bag: bag() });
    const { state: after, events } = play(state, capture(), spheres, SUCCESS);

    expect(events).toEqual([
      { type: 'capture_attempted', item_id: SPHERE, success: true },
      { type: 'battle_ended', result: 'captured' },
    ]);
    expect(after.phase).toBe('ended');
    expect(after.result).toBe('captured');
  });

  it('com sucesso, não há dano de fim de turno', () => {
    const state = makeState(idler({ statusSlug: 'poison' }), idler(), {
      bag: bag(),
    });
    const { state: after, events } = play(state, capture(), spheres, SUCCESS);
    expect(eventsOf(events, 'status_damage')).toEqual([]);
    expect(after.player.team[0]!.currentHp).toBe(19);
  });

  it('com falha, o inimigo age e a luta segue', () => {
    const state = makeState(idler(), idler(), { bag: bag() });
    const { state: after, events } = play(state, capture(), spheres, FAILURE);

    expect(events[0]).toEqual({
      type: 'capture_attempted',
      item_id: SPHERE,
      success: false,
    });
    expect(eventsOf(events, 'skill_used')).toEqual([
      { type: 'skill_used', side: 'enemy', skill_id: IDLE.id },
    ]);
    expect(after.phase).toBe('choose_action');
    expect(after.turn).toBe(2);
  });

  it('a tentativa vem antes do inimigo, mesmo com ele mais rápido', () => {
    const fast = { ...STRONG, spd: 500 };
    const state = makeState(idler(), idler({ stats: fast }), { bag: bag() });
    const { events } = play(state, capture(), spheres, FAILURE);
    expect(events[0]!.type).toBe('capture_attempted');
  });

  it.each([
    ['sucesso', SUCCESS],
    ['falha', FAILURE],
  ])('a Esfera é gasta com %s', (_name, random) => {
    const state = makeState(idler(), idler(), { bag: bag(SPHERE, 3) });
    const { state: after } = play(state, capture(), spheres, random);
    expect(after.bag).toEqual([{ itemId: SPHERE, quantity: 2, used: 1 }]);
  });

  it('a chance usa o HP e o status do inimigo naquele momento', () => {
    const weak = idler({ currentHp: 1, statusSlug: 'sleep' });
    const state = makeState(idler(), weak, { bag: bag() });
    // Com chance certa, nenhum sorteio é pedido.
    const { state: after } = play(state, capture(), spheres, sequence());
    expect(after.result).toBe('captured');
  });

  it('se o inimigo derrotar o último Ecobeast depois da falha, é derrota', () => {
    const hitter = knower(SCRATCH, { stats: STRONG });
    const state = makeState(idler({ currentHp: 1 }), hitter, { bag: bag() });
    const { state: after } = play(state, capture(), spheres, FAILURE);
    expect(after.result).toBe('defeat');
    expect(after.bag[0]!.used).toBe(1);
  });

  it('a última Esfera deixa de valer', () => {
    const state = makeState(idler(), idler(), { bag: bag() });
    const { state: after } = play(state, capture(), spheres, FAILURE);
    expect(refusal(after, capture())).toBe('Você não tem esse item.');
  });

  describe('recusas não gastam a rodada nem a Esfera', () => {
    it.each<[string, Partial<BattleState>, BattleAction, string]>([
      ['fora da Mochila', { bag: [] }, capture(), 'Você não tem esse item.'],
      [
        'zerada',
        { bag: [{ itemId: SPHERE, quantity: 0, used: 1 }] },
        capture(),
        'Você não tem esse item.',
      ],
      [
        'que não existe',
        { bag: bag(99) },
        capture(99),
        'Você não tem esse item.',
      ],
      [
        'que não captura',
        { bag: bag(TONIC) },
        capture(TONIC),
        'Esse item não pode ser usado agora.',
      ],
    ])('item %s', (_name, overrides, action, message) => {
      expect(refusal(makeState(idler(), idler(), overrides), action)).toBe(
        message,
      );
    });

    it('inimigo com capture_rate 0', () => {
      const state = makeState(idler(), idler({ speciesId: RARE_SPECIES }), {
        bag: bag(),
      });
      expect(refusal(state, capture())).toBe(
        'Esse Ecobeast não pode ser capturado.',
      );
    });

    it('enquanto escolhe o próximo Ecobeast', () => {
      const state = makeState([idler({ currentHp: 0 }), idler()], idler(), {
        bag: bag(),
        phase: 'choose_next',
      });
      expect(refusal(state, capture())).toBe('Escolha o próximo Ecobeast.');
    });

    it('com a luta encerrada', () => {
      const state = makeState(idler(), idler(), {
        bag: bag(),
        phase: 'ended',
        result: 'fled',
      });
      expect(refusal(state, capture())).toBe('A batalha já terminou.');
    });
  });
});

describe('itens', () => {
  const TONIC = 4;
  const BALM = 6;
  const SPHERE = 1;
  const STRONG = { hp: 19, atk: 500, def: 9, sp_atk: 11, sp_def: 9, spd: 11 };
  const items = makeCatalog({}, [SCRATCH, IDLE], {
    [TONIC]: { healAmount: 8, curesStatus: false },
    [BALM]: { healAmount: null, curesStatus: true },
    [SPHERE]: { healAmount: null, curesStatus: false },
  });
  const bag = (itemId = TONIC, quantity = 1) => [{ itemId, quantity, used: 0 }];
  const useItem = (itemId = TONIC, teamIndex = 0): BattleAction => ({
    type: 'item',
    item_id: itemId,
    team_index: teamIndex,
  });
  const refusal = (state: BattleState, action: BattleAction) => {
    const outcome = applyAction(state, action, items, always(0.5));
    return 'error' in outcome ? outcome.error : null;
  };

  it('cura quem está em campo e avisa no evento', () => {
    const state = makeState(idler({ currentHp: 5 }), idler(), { bag: bag() });
    const { state: after, events } = play(state, useItem(), items);
    expect(after.player.team[0]!.currentHp).toBe(13);
    expect(eventsOf(events, 'item_used')).toEqual([
      {
        type: 'item_used',
        side: 'player',
        item_id: TONIC,
        team_index: 0,
        healed: 8,
        hp: 13,
        cured_status: null,
      },
    ]);
  });

  it('o item vem antes do inimigo, mesmo com ele mais rápido', () => {
    const state = makeState(idler({ currentHp: 5 }), withSpeed(99), {
      bag: bag(),
    });
    const { events } = play(state, useItem(), items);
    const types = events.map((event) => event.type);
    expect(types.indexOf('item_used')).toBeLessThan(
      types.indexOf('skill_used'),
    );
  });

  it('gasta a rodada: o inimigo ataca, e o turno avança', () => {
    const state = makeState(idler({ currentHp: 5 }), fighter(), {
      bag: bag(),
    });
    const { state: after, events } = play(state, useItem(), items);
    expect(actingOrder(events)).toEqual(['enemy']);
    expect(after.player.team[0]!.currentHp).toBeLessThan(13);
    expect(after.turn).toBe(2);
    expect(after.phase).toBe('choose_action');
  });

  it('cura um reserva, sem mudar quem está em campo', () => {
    const state = makeState([idler(), idler({ currentHp: 3 })], idler(), {
      bag: bag(),
    });
    const { state: after, events } = play(state, useItem(TONIC, 1), items);
    expect(after.player.team[1]!.currentHp).toBe(11);
    expect(after.player.activeIndex).toBe(0);
    expect(eventsOf(events, 'item_used')[0]!.team_index).toBe(1);
  });

  it('não passa do HP máximo', () => {
    const state = makeState(idler({ currentHp: 17 }), idler(), { bag: bag() });
    const { state: after, events } = play(state, useItem(), items);
    expect(after.player.team[0]!.currentHp).toBe(19);
    expect(eventsOf(events, 'item_used')[0]!.healed).toBe(2);
  });

  it('o Bálsamo tira o status e acorda quem dormia', () => {
    const state = makeState(
      idler({ statusSlug: 'sleep', sleepTurns: 3 }),
      idler(),
      { bag: bag(BALM) },
    );
    const { state: after, events } = play(state, useItem(BALM), items);
    expect(after.player.team[0]!.statusSlug).toBeNull();
    expect(after.player.team[0]!.sleepTurns).toBe(0);
    expect(eventsOf(events, 'item_used')[0]!.cured_status).toBe('sleep');
  });

  it('dormindo, o jogador ainda pode usar um item', () => {
    const state = makeState(
      idler({ currentHp: 5, statusSlug: 'sleep', sleepTurns: 3 }),
      idler(),
      { bag: bag() },
    );
    expect(refusal(state, useItem())).toBeNull();
  });

  it('o veneno ainda dói depois do item', () => {
    const state = makeState(
      idler({ currentHp: 5, statusSlug: 'poison' }),
      idler(),
      { bag: bag() },
    );
    const { events } = play(state, useItem(), items);
    const types = events.map((event) => event.type);
    expect(types.indexOf('item_used')).toBeLessThan(
      types.indexOf('status_damage'),
    );
  });

  it('tira 1 da quantidade e conta o gasto', () => {
    const state = makeState(idler({ currentHp: 1 }), idler(), {
      bag: bag(TONIC, 3),
    });
    const { state: after } = play(state, useItem(), items);
    expect(after.bag).toEqual([{ itemId: TONIC, quantity: 2, used: 1 }]);
  });

  it('a unidade gasta não pode ser usada de novo', () => {
    const state = makeState(idler({ currentHp: 1 }), idler(), { bag: bag() });
    const { state: after } = play(state, useItem(), items);
    expect(refusal(after, useItem())).toBe('Você não tem esse item.');
  });

  it('não altera o estado recebido', () => {
    const state = makeState(idler({ currentHp: 5 }), idler(), { bag: bag() });
    const copy = structuredClone(state);
    play(state, useItem(), items);
    expect(state).toEqual(copy);
  });

  it('se o inimigo derrubar o alvo depois do item, a luta segue', () => {
    const state = makeState(
      [idler({ currentHp: 1 }), idler()],
      fighter({ stats: STRONG }),
      { bag: bag() },
    );
    const { state: after } = play(state, useItem(), items);
    expect(after.player.team[0]!.currentHp).toBe(0);
    expect(after.phase).toBe('choose_next');
  });

  it('se o inimigo derrubar o último, a luta acaba em derrota', () => {
    const state = makeState(
      idler({ currentHp: 1 }),
      fighter({ stats: STRONG }),
      { bag: bag() },
    );
    const { state: after } = play(state, useItem(), items);
    expect(after.result).toBe('defeat');
    expect(after.bag[0]!.used).toBe(1);
  });

  describe('recusas não gastam a rodada', () => {
    it.each<[string, Partial<BattleState>, BattleAction, string]>([
      ['fora da Mochila', { bag: [] }, useItem(), 'Você não tem esse item.'],
      [
        'com quantidade zero',
        { bag: [{ itemId: TONIC, quantity: 0, used: 1 }] },
        useItem(),
        'Você não tem esse item.',
      ],
      [
        'que não está no catálogo',
        { bag: bag(99) },
        useItem(99),
        'Você não tem esse item.',
      ],
      [
        'em um Ecobeast que não existe',
        { bag: bag() },
        useItem(TONIC, 5),
        'Esse Ecobeast não existe.',
      ],
      [
        'de captura',
        { bag: bag(SPHERE) },
        useItem(SPHERE),
        'Esse item não pode ser usado agora.',
      ],
    ])('item %s', (_name, overrides, action, message) => {
      const state = makeState(idler({ currentHp: 5 }), idler(), overrides);
      expect(refusal(state, action)).toBe(message);
    });

    it('com HP cheio', () => {
      const state = makeState(idler(), idler(), { bag: bag() });
      expect(refusal(state, useItem())).toBe('Não teria efeito.');
    });

    it('em um reserva com 0 HP', () => {
      const state = makeState([idler(), idler({ currentHp: 0 })], idler(), {
        bag: bag(),
      });
      expect(refusal(state, useItem(TONIC, 1))).toBe(
        'Só o Refúgio recupera um Ecobeast sem HP.',
      );
    });

    it('enquanto escolhe o próximo Ecobeast', () => {
      const state = makeState(
        [idler({ currentHp: 0 }), idler({ currentHp: 5 })],
        idler(),
        { bag: bag(), phase: 'choose_next' },
      );
      expect(refusal(state, useItem(TONIC, 1))).toBe(
        'Escolha o próximo Ecobeast.',
      );
    });
  });

  it('startBattle guarda uma cópia da Mochila', () => {
    const mine = bag(TONIC, 2);
    const { state } = startBattle(
      [idler()],
      [idler()],
      true,
      items,
      always(0.5),
      mine,
    );
    expect(state.bag).toEqual(mine);
    expect(state.bag).not.toBe(mine);
  });

  it('sem Mochila, a luta começa com ela vazia', () => {
    const { state } = startBattle(
      [idler()],
      [idler()],
      true,
      items,
      always(0.5),
    );
    expect(state.bag).toEqual([]);
  });
});
