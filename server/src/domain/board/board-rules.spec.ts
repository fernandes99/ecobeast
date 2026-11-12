import { noStages } from '../battle/stages.js';
import {
  always,
  eventsOf,
  makeEffect,
  makeSkill,
  sequence,
} from '../battle/testing.js';
import type { BattleEvent, Combatant } from '../battle/types.js';
import { applyBoardVez, startBoardBattle } from './board-engine.js';
import {
  at,
  boardCatalog,
  fighter,
  makeBoardState,
  playVez,
  wild,
} from './testing.js';
import type { BoardInput, BoardState, BoardVez } from './types.js';

const ASLEEP: Partial<Combatant> = { statusSlug: 'sleep', sleepTurns: 99 };
const SCRATCH_SLOT = 1;
const TONIC = 4;
const BALM = 6;
const SPHERE = 1;
const RARE_SPECIES = 2;
const WILD_SPECIES = 7;

const SHAKY = makeSkill({ id: 20, accuracy: 50 });
const SHELL = makeSkill({
  id: 21,
  power: 0,
  accuracy: 0,
  category: 'support',
  targetSlug: 'self',
  effects: [makeEffect({ effectSlug: 'protect' })],
});
const BACKFIRE = makeSkill({
  id: 22,
  effects: [makeEffect({ effectSlug: 'recoil', percent: 100 })],
});

const catalog = boardCatalog([SHAKY, SHELL, BACKFIRE]);
catalog.items.set(TONIC, {
  healAmount: 8,
  curesStatus: false,
  captureBonus: null,
});
catalog.items.set(BALM, {
  healAmount: null,
  curesStatus: true,
  captureBonus: null,
});
catalog.items.set(SPHERE, {
  healAmount: null,
  curesStatus: false,
  captureBonus: 1,
});
catalog.captureRates.set(WILD_SPECIES, 45);
catalog.captureRates.set(RARE_SPECIES, 0);

const TARGET = at(2, 4);
const NEAR = { cells: { enemy: [TARGET] } };
const SCRATCH: BoardVez = {
  position: 0,
  action: { type: 'skill', slot: SCRATCH_SLOT, target: TARGET },
};
const WAIT: BoardVez = { position: 0, action: { type: 'wait' } };

const bag = (itemId = TONIC, quantity = 1) => [{ itemId, quantity, used: 0 }];
const knowing = (skillId: number, currentPp = 10) => ({
  skills: [{ skillId, currentPp }],
});

function duel(
  player: Partial<Combatant> = {},
  enemy: Partial<Combatant> = {},
  overrides: Partial<BoardState> = {},
): BoardState {
  return makeBoardState(
    [fighter(30, player)],
    [wild(5, { ...ASLEEP, ...enemy })],
    NEAR,
    overrides,
  );
}

function types(events: BattleEvent[]): string[] {
  return events.map((event) => event.type);
}

describe('vez recusada', () => {
  const bench = (first: Partial<Combatant>, second: Partial<Combatant> = {}) =>
    makeBoardState(
      [fighter(30, first), fighter(20, second)],
      [wild(5, ASLEEP)],
      NEAR,
    );
  const act = (action: BoardVez['action']): BoardVez => ({
    position: 0,
    action,
  });
  const capture = (itemId = SPHERE) =>
    act({ type: 'capture', item_id: itemId, target: TARGET });

  it.each<[string, BoardState, BoardInput, string]>([
    [
      'slot vazio',
      duel(),
      act({ type: 'skill', slot: 5, target: TARGET }),
      'Essa Técnica não existe.',
    ],
    [
      'slot zero',
      duel(),
      act({ type: 'skill', slot: 0, target: TARGET }),
      'Essa Técnica não existe.',
    ],
    [
      'Técnica sem PP',
      duel(knowing(1, 0)),
      SCRATCH,
      'Essa Técnica está sem PP.',
    ],
    [
      'emergência com PP',
      duel(),
      act({ type: 'emergency', target: TARGET }),
      'Ainda há Técnicas com PP.',
    ],
    [
      'fugir sem poder',
      duel({}, {}, { canFlee: false }),
      act({ type: 'flee' }),
      'Não dá para fugir agora.',
    ],
    [
      'fugir estando Preso',
      duel({ isTrapped: true }),
      act({ type: 'flee' }),
      'Não dá para fugir agora.',
    ],
    [
      'agir quando é hora de escolher o próximo',
      duel({}, {}, { phase: 'choose_next', pendingPositions: [0] }),
      SCRATCH,
      'Escolha o próximo Ecobeast.',
    ],
    [
      'trocar para quem caiu',
      bench({}, { currentHp: 0 }),
      act({ type: 'switch', team_index: 1 }),
      'Esse Ecobeast não pode lutar.',
    ],
    [
      'trocar para quem não existe',
      bench({}),
      act({ type: 'switch', team_index: 9 }),
      'Esse Ecobeast não pode lutar.',
    ],
    [
      'trocar para quem está em campo',
      bench({}),
      act({ type: 'switch', team_index: 0 }),
      'Esse Ecobeast já está em campo.',
    ],
    [
      'trocar estando Preso',
      bench({ isTrapped: true }),
      act({ type: 'switch', team_index: 1 }),
      'Não dá para trocar agora.',
    ],
    [
      'agir depois do fim',
      duel({}, {}, { phase: 'ended' }),
      SCRATCH,
      'A batalha já terminou.',
    ],
    ['Esfera fora da Mochila', duel(), capture(), 'Você não tem esse item.'],
    [
      'Esfera zerada',
      duel({}, {}, { bag: [{ itemId: SPHERE, quantity: 0, used: 1 }] }),
      capture(),
      'Você não tem esse item.',
    ],
    [
      'Esfera que não existe',
      duel({}, {}, { bag: bag(99) }),
      capture(99),
      'Você não tem esse item.',
    ],
    [
      'capturar com um item que não captura',
      duel({}, {}, { bag: bag(TONIC) }),
      capture(TONIC),
      'Esse item não pode ser usado agora.',
    ],
    [
      'capturar quem tem capture_rate 0',
      duel({}, { speciesId: RARE_SPECIES }, { bag: bag(SPHERE) }),
      capture(),
      'Esse Ecobeast não pode ser capturado.',
    ],
    [
      'item com HP cheio',
      duel({}, {}, { bag: bag() }),
      act({ type: 'item', item_id: TONIC, team_index: 0 }),
      'Não teria efeito.',
    ],
  ])('%s', (_name, state, input, message) => {
    const copy = structuredClone(state);
    expect(applyBoardVez(state, input, catalog, sequence())).toEqual({
      error: message,
    });
    expect(state).toEqual(copy);
  });
});

describe('começo da luta', () => {
  it('guarda o modo God, as moedas e uma cópia da Mochila', () => {
    const mine = bag(TONIC, 2);
    const { state } = startBoardBattle(
      [fighter(30)],
      [wild(5, ASLEEP)],
      catalog,
      always(0.5),
      mine,
      { godMode: true, coins: 250 },
    );
    expect(state).toMatchObject({ godMode: true, coins: 250, coinsChange: 0 });
    expect(state.bag).toEqual(mine);
    expect(state.bag).not.toBe(mine);
  });

  it('sem opções, começa sem God, sem moedas e com a Mochila vazia', () => {
    const { state } = startBoardBattle(
      [fighter(30)],
      [wild(5, ASLEEP)],
      catalog,
      always(0.5),
    );
    expect(state).toMatchObject({ godMode: false, coins: 0, bag: [] });
  });

  it('não altera as equipes recebidas', () => {
    const player = [fighter(30)];
    const enemy = [wild(5, ASLEEP)];
    const copies = structuredClone([player, enemy]);
    startBoardBattle(player, enemy, catalog, always(0.5));
    expect([player, enemy]).toEqual(copies);
  });

  it('quem entra Adormecido sorteia as vezes de novo', () => {
    const { state } = startBoardBattle(
      [fighter(30, { statusSlug: 'sleep' })],
      [wild(5, ASLEEP)],
      catalog,
      always(0.5),
    );
    expect(state.player.team[0]!.sleepTurns).toBe(2);
  });

  it('a Brisa Ligeira vale logo depois da entrada, primeiro a do jogador', () => {
    const { state, events } = startBoardBattle(
      [fighter(30, { traitSlug: 'tailwind' })],
      [wild(5, { ...ASLEEP, traitSlug: 'tailwind' })],
      catalog,
      always(0.5),
    );
    expect(types(events).slice(0, 5)).toEqual([
      'battle_started',
      'creature_entered',
      'stat_changed',
      'creature_entered',
      'stat_changed',
    ]);
    expect(state.player.team[0]!.stages.spd).toBe(1);
    expect(state.enemy.team[0]!.stages.spd).toBe(1);
  });
});

describe('Técnicas', () => {
  it('usar gasta 1 PP', () => {
    const { state } = playVez(duel(), SCRATCH, catalog);
    expect(state.player.team[0]!.skills[0]!.currentPp).toBe(34);
  });

  it('errar também gasta', () => {
    const { state, events } = playVez(
      duel(knowing(SHAKY.id)),
      SCRATCH,
      catalog,
      always(0.9),
    );
    expect(types(events)).toContain('missed');
    expect(state.player.team[0]!.skills[0]!.currentPp).toBe(9);
  });

  it('o golpe de emergência não tem Técnica no evento nem gasta PP', () => {
    const { state, events } = playVez(
      duel(knowing(1, 0)),
      { position: 0, action: { type: 'emergency', target: TARGET } },
      catalog,
    );
    expect(eventsOf(events, 'skill_used')[0]).toMatchObject({
      side: 'player',
      skill_id: null,
    });
    expect(types(events)).toContain('recoil');
    expect(state.player.team[0]!.skills[0]!.currentPp).toBe(0);
  });

  it('quem está com medo perde a vez sem gastar PP, e o medo passa', () => {
    const { state, events } = playVez(
      duel({ isFeared: true }),
      SCRATCH,
      catalog,
    );
    expect(eventsOf(events, 'cannot_act')).toEqual([
      { type: 'cannot_act', side: 'player', position: 0, reason: 'fear' },
    ]);
    expect(state.player.team[0]).toMatchObject({ isFeared: false });
    expect(state.player.team[0]!.skills[0]!.currentPp).toBe(35);
  });

  it('a proteção bloqueia o golpe da rodada e some na vez seguinte', () => {
    const state = makeBoardState(
      [fighter(30, knowing(SHELL.id))],
      [wild(5, knowing(1))],
      {
        ...NEAR,
        queue: [
          { side: 'player', position: 0 },
          { side: 'enemy', position: 0 },
        ],
      },
    );
    const { state: after, events } = playVez(
      state,
      {
        position: 0,
        action: { type: 'skill', slot: 1 },
      },
      catalog,
    );
    expect(eventsOf(events, 'blocked')).toEqual([
      { type: 'blocked', side: 'player', position: 0 },
    ]);
    expect(after.player.team[0]).toMatchObject({
      currentHp: 200,
      isProtected: false,
    });
  });

  it('o veneno dói no fim da vez de quem o tem', () => {
    const { events } = playVez(duel({ statusSlug: 'poison' }), WAIT, catalog);
    expect(eventsOf(events, 'status_damage')).toMatchObject([
      { side: 'player', position: 0, status: 'poison' },
    ]);
  });
});

describe('Traços na luta', () => {
  it('o Instinto dá +1 de Velocidade a quem derrota um inimigo com uma Técnica', () => {
    const state = makeBoardState(
      [fighter(30, { traitSlug: 'instinct' })],
      [wild(5, { ...ASLEEP, currentHp: 1 }), wild(5, ASLEEP)],
      NEAR,
    );
    const { state: after, events } = playVez(state, SCRATCH, catalog);
    expect(after.player.team[0]!.stages.spd).toBe(1);
    expect(eventsOf(events, 'stat_changed')).toMatchObject([
      { side: 'player', position: 0, stat: 'spd', stages: 1 },
    ]);
  });

  it('não dá nada sem derrotar', () => {
    const { state } = playVez(
      duel({ traitSlug: 'instinct' }),
      SCRATCH,
      catalog,
    );
    expect(state.player.team[0]!.stages.spd).toBe(0);
  });

  it('o recuo que derruba os dois dá a vitória, sem o Instinto', () => {
    const { state, events } = playVez(
      duel(
        { ...knowing(BACKFIRE.id), traitSlug: 'instinct', currentHp: 1 },
        { currentHp: 5 },
      ),
      SCRATCH,
      catalog,
    );
    expect(state.result).toBe('victory');
    expect(eventsOf(events, 'fainted').map((event) => event.side)).toEqual([
      'enemy',
      'player',
    ]);
    expect(eventsOf(events, 'stat_changed')).toEqual([]);
  });

  it('a Brisa Ligeira vale na troca e para o próximo inimigo', () => {
    const state = makeBoardState(
      [fighter(30), fighter(20, { traitSlug: 'tailwind' })],
      [
        wild(5, { ...ASLEEP, currentHp: 1 }),
        wild(5, { ...ASLEEP, traitSlug: 'tailwind' }),
      ],
      NEAR,
    );
    const switched = playVez(
      state,
      { position: 0, action: { type: 'switch', team_index: 1 } },
      catalog,
    );
    expect(switched.state.player.team[1]!.stages.spd).toBe(1);

    const next = playVez(state, SCRATCH, catalog);
    expect(next.state.enemy.activeIndices[0]).toBe(1);
    expect(next.state.enemy.team[1]!.stages.spd).toBe(1);
  });
});

describe('troca', () => {
  it('quem saiu mantém HP, status e PP, e volta sem mudanças de atributos', () => {
    const state = makeBoardState(
      [
        fighter(30, {
          currentHp: 50,
          statusSlug: 'poison',
          stages: { ...noStages(), atk: 2 },
          confusionTurns: 3,
        }),
        fighter(20),
      ],
      [wild(5, ASLEEP)],
      NEAR,
    );
    const out = playVez(
      state,
      { position: 0, action: { type: 'switch', team_index: 1 } },
      catalog,
    );
    expect(out.state.player.team[0]).toMatchObject({
      currentHp: 50,
      statusSlug: 'poison',
    });
    expect(out.state.player.team[0]!.skills[0]!.currentPp).toBe(35);

    const back = playVez(
      out.state,
      { position: 0, action: { type: 'switch', team_index: 0 } },
      catalog,
    );
    expect(back.state.player.team[0]).toMatchObject({
      stages: noStages(),
      confusionTurns: 0,
      statusSlug: 'poison',
    });
  });
});

describe('itens na vez', () => {
  const useItem = (itemId: number): BoardVez => ({
    position: 0,
    action: { type: 'item', item_id: itemId, team_index: 0 },
  });

  it('o Tônico cura, avisa no evento e sai da Mochila', () => {
    const { state, events } = playVez(
      duel({ currentHp: 5 }, {}, { bag: bag(TONIC, 3) }),
      useItem(TONIC),
      catalog,
    );
    expect(eventsOf(events, 'item_used')).toEqual([
      {
        type: 'item_used',
        side: 'player',
        position: 0,
        item_id: TONIC,
        team_index: 0,
        healed: 8,
        hp: 13,
        cured_status: null,
      },
    ]);
    expect(state.bag).toEqual([{ itemId: TONIC, quantity: 2, used: 1 }]);
  });

  it('dormindo, o jogador ainda usa um item, e o Bálsamo acorda', () => {
    const { state, events } = playVez(
      duel(ASLEEP, {}, { bag: bag(BALM) }),
      useItem(BALM),
      catalog,
    );
    expect(eventsOf(events, 'cannot_act')).toEqual([]);
    expect(eventsOf(events, 'item_used')[0]).toMatchObject({
      cured_status: 'sleep',
    });
    expect(state.player.team[0]).toMatchObject({
      statusSlug: null,
      sleepTurns: 0,
    });
  });
});

describe('fuga e fim', () => {
  it('a fuga que falha gasta a vez, e a luta segue', () => {
    const { state, events } = playVez(
      duel(),
      { position: 0, action: { type: 'flee' } },
      catalog,
      always(0.1),
    );
    expect(types(events)).toContain('flee_failed');
    expect(state.phase).toBe('choose_action');
    expect(state.result).toBeNull();
  });

  it('os efeitos temporários somem no fim da luta', () => {
    const { state } = playVez(
      duel({ isTrapped: true }, { currentHp: 1 }),
      SCRATCH,
      catalog,
    );
    expect(state.result).toBe('victory');
    expect(state.player.team[0]!.isTrapped).toBe(false);
  });

  it('todos caídos dão a derrota', () => {
    const { state } = playVez(
      duel({ statusSlug: 'poison', currentHp: 1 }),
      WAIT,
      catalog,
    );
    expect(state.result).toBe('defeat');
  });

  it('não altera o estado recebido', () => {
    const state = duel();
    const copy = structuredClone(state);
    playVez(state, SCRATCH, catalog);
    expect(state).toEqual(copy);
  });
});
