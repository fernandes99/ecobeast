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
} from './testing.js';
import type { BattleAction, BattleState, Combatant } from './types.js';

/** Lutas com mais de uma vaga (battle-slots/01). */

const SCRATCH = makeSkill({ id: 1 });
const GROWL = makeSkill({
  id: 2,
  power: 0,
  category: 'support',
  targetSlug: 'self',
  effects: [],
});
const SPHERE = 50;
const WILD_A = 7;
const WILD_B = 8;
const catalog = makeCatalog(
  {},
  [SCRATCH, GROWL],
  { [SPHERE]: { healAmount: null, curesStatus: false, captureBonus: 1 } },
  { [WILD_A]: 100, [WILD_B]: 100 },
  { [WILD_A]: 70, [WILD_B]: 70 },
);
const TWO = { player: 2, enemy: 2 };

function fighter(spd: number, overrides: Partial<Combatant> = {}): Combatant {
  return makeCombatant({
    stats: { hp: 200, atk: 10, def: 9, sp_atk: 11, sp_def: 9, spd },
    currentHp: 200,
    skills: [
      { skillId: SCRATCH.id, currentPp: 35 },
      { skillId: GROWL.id, currentPp: 35 },
    ],
    ...overrides,
  });
}

function wild(
  speciesId: number,
  spd: number,
  overrides: Partial<Combatant> = {},
) {
  return fighter(spd, { creatureUid: null, speciesId, ...overrides });
}

function scratch(position: number, target: number): BattleAction {
  return { type: 'skill', slot: 1, position, target };
}

function growl(position: number): BattleAction {
  return { type: 'skill', slot: 2, position };
}

/** Rápido na vaga 0, lento na 1, contra dois de Velocidade no meio. */
function twoOnTwo(enemyOverrides: Partial<Combatant>[] = []): BattleState {
  return makeState(
    [fighter(30), fighter(5)],
    [wild(WILD_A, 20, enemyOverrides[0]), wild(WILD_B, 10, enemyOverrides[1])],
    {},
    TWO,
  );
}

describe('vagas', () => {
  it('o começo põe os primeiros de pé em cada vaga, primeiro o jogador', () => {
    const { state, events } = startBattle(
      [fighter(10, { currentHp: 0 }), fighter(10), fighter(10)],
      [wild(WILD_A, 10), wild(WILD_B, 10)],
      true,
      catalog,
      always(0.5),
      [],
      { slots: TWO },
    );
    expect(state.player.activeIndices).toEqual([1, 2]);
    expect(state.enemy.activeIndices).toEqual([0, 1]);
    expect(
      eventsOf(events, 'creature_entered').map(
        ({ side, position, team_index }) => [side, position, team_index],
      ),
    ).toEqual([
      ['player', 0, 1],
      ['player', 1, 2],
      ['enemy', 0, 0],
      ['enemy', 1, 1],
    ]);
  });

  it('com menos Ecobeasts do que vagas, a que sobra começa vazia', () => {
    const { state } = startBattle(
      [fighter(10)],
      [wild(WILD_A, 10)],
      true,
      catalog,
      always(0.5),
      [],
      { slots: TWO },
    );
    expect(state.player.activeIndices).toEqual([0, null]);
  });

  it('cada um age uma vez, na ordem de Velocidade, e o alvo escolhido apanha', () => {
    const { events } = play(
      twoOnTwo(),
      [scratch(0, 1), scratch(1, 0)],
      catalog,
    );
    expect(
      eventsOf(events, 'skill_used').map(({ side, position }) => [
        side,
        position,
      ]),
    ).toEqual([
      ['player', 0],
      ['enemy', 0],
      ['enemy', 1],
      ['player', 1],
    ]);
    const playerHits = eventsOf(events, 'damage').filter(
      (event) => event.side === 'enemy',
    );
    expect(playerHits.map((event) => event.position)).toEqual([1, 0]);
  });

  it('quem desmaia antes de agir perde a vez', () => {
    const { events } = play(
      twoOnTwo([{ currentHp: 1 }]),
      [scratch(0, 0), growl(1)],
      catalog,
    );
    expect(eventsOf(events, 'fainted')).toEqual([
      { type: 'fainted', side: 'enemy', position: 0 },
    ]);
    expect(
      eventsOf(events, 'skill_used').filter(
        (event) => event.side === 'enemy' && event.position === 0,
      ),
    ).toEqual([]);
  });

  it('o alvo que caiu no meio do turno passa para o adversário de pé', () => {
    const { events } = play(
      twoOnTwo([{ currentHp: 1 }]),
      [scratch(0, 0), scratch(1, 0)],
      catalog,
    );
    const playerHits = eventsOf(events, 'damage').filter(
      (event) => event.side === 'enemy',
    );
    expect(playerHits.map((event) => event.position)).toEqual([0, 1]);
  });

  it.each<[string, BattleAction[], string]>([
    [
      'falta a ação de uma vaga',
      [scratch(0, 1)],
      'Escolha uma ação para cada Ecobeast em campo.',
    ],
    [
      'ação para uma vaga que não existe',
      [scratch(0, 1), scratch(1, 0), scratch(2, 0)],
      'Escolha uma ação para cada Ecobeast em campo.',
    ],
    [
      'sem alvo com dois adversários',
      [{ type: 'skill', slot: 1, position: 0 }, scratch(1, 0)],
      'Escolha o alvo.',
    ],
    [
      'alvo fora da luta',
      [scratch(0, 2), scratch(1, 0)],
      'Esse alvo não está na luta.',
    ],
    [
      'fugir junto com outra ação',
      [{ type: 'flee' }, scratch(1, 0)],
      'Fugir vale para a equipe toda.',
    ],
  ])('recusa: %s', (_, actions, error) => {
    const state = twoOnTwo();
    expect(applyAction(state, actions, catalog, always(0.5))).toEqual({
      error,
    });
  });

  it('recusa duas trocas para o mesmo Ecobeast', () => {
    const state = makeState(
      [fighter(30), fighter(5), fighter(5)],
      [wild(WILD_A, 20), wild(WILD_B, 10)],
      {},
      TWO,
    );
    const actions: BattleAction[] = [
      { type: 'switch', team_index: 2, position: 0 },
      { type: 'switch', team_index: 2, position: 1 },
    ];
    expect(applyAction(state, actions, catalog, always(0.5))).toEqual({
      error: 'Esse Ecobeast já vai entrar.',
    });
  });

  it('fugir sozinho vale para a equipe toda', () => {
    const { state } = play(
      twoOnTwo(),
      [{ type: 'flee' }],
      catalog,
      always(0.9),
    );
    expect(state.result).toBe('fled');
  });
});

describe('vaga vazia e quem entra', () => {
  /** O da vaga 0 cai com o veneno no fim do turno. */
  function poisoned(bench: Combatant[]): BattleState {
    return makeState(
      [
        fighter(30, { currentHp: 1, statusSlug: 'poison' }),
        fighter(5),
        ...bench,
      ],
      [
        wild(WILD_A, 20, { skills: [{ skillId: GROWL.id, currentPp: 35 }] }),
        wild(WILD_B, 10, { skills: [{ skillId: GROWL.id, currentPp: 35 }] }),
      ],
      {},
      TWO,
    );
  }

  it('com reserva, a vaga espera quem entra', () => {
    const { state } = play(
      poisoned([fighter(5)]),
      [growl(0), growl(1)],
      catalog,
    );
    expect(state.phase).toBe('choose_next');
    expect(state.pendingPositions).toEqual([0]);
  });

  it('quem o jogador escolhe entra naquela vaga', () => {
    const fainted = play(poisoned([fighter(5)]), [growl(0), growl(1)], catalog);
    const { state, events } = play(
      fainted.state,
      [{ type: 'switch', team_index: 2, position: 0 }],
      catalog,
    );
    expect(state.player.activeIndices).toEqual([2, 1]);
    expect(state.phase).toBe('choose_action');
    expect(eventsOf(events, 'creature_entered')[0]).toMatchObject({
      side: 'player',
      position: 0,
      team_index: 2,
    });
  });

  it('sem reserva, a vaga fica vazia e a luta continua', () => {
    const { state, events } = play(poisoned([]), [growl(0), growl(1)], catalog);
    expect(eventsOf(events, 'creature_left')).toEqual([
      { type: 'creature_left', side: 'player', position: 0 },
    ]);
    expect(state.player.activeIndices).toEqual([null, 1]);
    expect(state.phase).toBe('choose_action');
    expect(state.result).toBeNull();
  });

  it('a derrota só vem quando todos caem', () => {
    const { state } = play(poisoned([]), [growl(0), growl(1)], catalog);
    const { state: after } = play(
      { ...state, player: { ...state.player } },
      [growl(1)],
      catalog,
    );
    expect(after.result).toBeNull();
    expect(after.player.activeIndices).toEqual([null, 1]);
  });
});

describe('captura e recompensas com vários selvagens', () => {
  it('capturar um de dois mantém a luta, e o outro continua agindo', () => {
    const state = makeState(
      [fighter(30), fighter(5)],
      [wild(WILD_A, 20), wild(WILD_B, 10)],
      { bag: [{ itemId: SPHERE, quantity: 1, used: 0 }], partyFree: 1 },
      TWO,
    );
    const { state: after, events } = play(
      state,
      [
        { type: 'capture', item_id: SPHERE, position: 0, target: 1 },
        scratch(1, 0),
      ],
      catalog,
      always(0),
    );
    expect(eventsOf(events, 'capture_attempted')).toEqual([
      {
        type: 'capture_attempted',
        item_id: SPHERE,
        success: true,
        target: 1,
        captured_to: 'party',
      },
    ]);
    expect(after.enemy.team[1]!.captured).toBe(true);
    expect(after.phase).toBe('choose_action');
    expect(
      eventsOf(events, 'skill_used').some(
        (event) => event.side === 'enemy' && event.position === 0,
      ),
    ).toBe(true);
    expect(after.enemy.activeIndices).toEqual([0, null]);
  });

  it('dois selvagens derrubados pagam XP e moedas cada um', () => {
    const { state, events } = play(
      twoOnTwo([{ currentHp: 1 }, { currentHp: 1 }]),
      [scratch(0, 0), scratch(1, 1)],
      catalog,
    );
    expect(state.result).toBe('victory');
    expect(
      eventsOf(events, 'coins_gained').map((event) => event.species_id),
    ).toEqual([WILD_A, WILD_B]);
    expect(
      eventsOf(events, 'xp_gained').map((event) => event.team_index),
    ).toEqual([0, 1, 0, 1]);
  });

  it('a Técnica em si mesmo leva o efeito no adversário ao primeiro de pé', () => {
    const lowerAtk = makeSkill({
      id: 3,
      power: 0,
      category: 'support',
      targetSlug: 'self',
      effects: [
        makeEffect({
          effectSlug: 'modify_stat',
          targetSlug: 'enemy',
          statSlug: 'atk',
          stages: -1,
        }),
      ],
    });
    const withLower = makeCatalog({}, [SCRATCH, GROWL, lowerAtk]);
    const state = makeState(
      [fighter(30, { skills: [{ skillId: 3, currentPp: 5 }] })],
      [wild(WILD_A, 20, { currentHp: 0 }), wild(WILD_B, 10)],
      {},
      { player: 1, enemy: 2 },
    );
    const { events } = play(
      state,
      { type: 'skill', slot: 1, position: 0 },
      withLower,
    );
    expect(eventsOf(events, 'stat_changed')[0]).toMatchObject({
      side: 'enemy',
      position: 1,
    });
  });
});
