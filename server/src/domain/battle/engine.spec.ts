import {
  inFieldRefusal,
  itemEffect,
  newSide,
  ownedItem,
  resultWithoutEnemies,
  skillRefusal,
  spendItem,
  switchRefusal,
} from './engine.js';
import {
  cast,
  eventsOf,
  always,
  makeCatalog,
  makeCombatant,
  makeSkill,
  makeState,
} from './testing.js';
import type { BattleState, Combatant } from './types.js';

const SCRATCH = makeSkill({ id: 1 });
const TONIC = 4;
const BALM = 6;
const SPHERE = 1;
const catalog = makeCatalog({}, [SCRATCH], {
  [TONIC]: { healAmount: 8, curesStatus: false },
  [BALM]: { healAmount: null, curesStatus: true },
  [SPHERE]: { healAmount: null, curesStatus: false, captureBonus: 1 },
});

function fighter(overrides: Partial<Combatant> = {}): Combatant {
  return makeCombatant({
    skills: [{ skillId: SCRATCH.id, currentPp: 10 }],
    ...overrides,
  });
}

const bag = (itemId = TONIC, quantity = 1) => [{ itemId, quantity, used: 0 }];

describe('dano de uma Técnica', () => {
  it('tira HP do alvo e conta no evento', () => {
    const { state, events } = cast(
      makeState(fighter(), fighter()),
      SCRATCH,
      catalog,
    );
    expect(state.enemy.team[0]!.currentHp).toBe(14);
    expect(events).toEqual([
      {
        type: 'damage',
        side: 'enemy',
        position: 0,
        damage: 5,
        hp: 14,
        multiplier: 1,
        is_critical: false,
      },
    ]);
  });

  it('um crítico aparece no evento', () => {
    const { events } = cast(
      makeState(fighter(), fighter()),
      SCRATCH,
      catalog,
      always(0),
    );
    expect(eventsOf(events, 'damage')[0]).toMatchObject({
      damage: 7,
      is_critical: true,
    });
  });

  it('o dano no evento é o HP que o alvo perdeu', () => {
    const { events } = cast(
      makeState(fighter(), fighter({ currentHp: 2 })),
      SCRATCH,
      catalog,
    );
    expect(eventsOf(events, 'damage')[0]).toMatchObject({ damage: 2, hp: 0 });
  });

  it('efetividade 0 dá no_effect e não causa dano', () => {
    const immune = makeCatalog({ '13:1': 0 }, [SCRATCH]);
    const { state, events } = cast(
      makeState(fighter(), fighter()),
      SCRATCH,
      immune,
    );
    expect(state.enemy.team[0]!.currentHp).toBe(19);
    expect(events).toEqual([{ type: 'no_effect', side: 'enemy', position: 0 }]);
  });

  it('errar não causa dano', () => {
    const shaky = makeSkill({ id: 3, accuracy: 50 });
    const { state, events } = cast(
      makeState(fighter(), fighter()),
      shaky,
      catalog,
      always(0.5),
    );
    expect(state.enemy.team[0]!.currentHp).toBe(19);
    expect(events).toEqual([{ type: 'missed', side: 'player', position: 0 }]);
  });
});

describe('newSide', () => {
  it('põe em cada vaga o próximo de pé, em ordem', () => {
    const side = newSide([fighter({ currentHp: 0 }), fighter(), fighter()], 2);
    expect(side.activeIndices).toEqual([1, 2]);
  });

  it('com menos Ecobeasts do que vagas, a que sobra fica vazia', () => {
    expect(newSide([fighter()], 2).activeIndices).toEqual([0, null]);
  });

  it('as vagas vão de 1 a 3', () => {
    const team = [fighter(), fighter(), fighter(), fighter()];
    expect(newSide(team, 0).activeIndices).toHaveLength(1);
    expect(newSide(team, 9).activeIndices).toHaveLength(3);
  });

  it('não altera a equipe recebida', () => {
    const team = [fighter()];
    expect(newSide(team, 1).team[0]).not.toBe(team[0]);
  });
});

describe('Técnica recusada', () => {
  it.each([
    ['slot vazio', fighter(), 2, 'Essa Técnica não existe.'],
    ['slot zero', fighter(), 0, 'Essa Técnica não existe.'],
    [
      'fora do catálogo',
      fighter({ skills: [{ skillId: 99, currentPp: 5 }] }),
      1,
      'Essa Técnica não existe.',
    ],
    [
      'sem PP',
      fighter({ skills: [{ skillId: 1, currentPp: 0 }] }),
      1,
      'Essa Técnica está sem PP.',
    ],
  ])('%s', (_name, creature, slot, message) => {
    expect(skillRefusal(creature, slot, catalog)).toBe(message);
  });

  it('com PP, vale', () => {
    expect(skillRefusal(fighter(), 1, catalog)).toBeNull();
  });
});

describe('quem pode entrar', () => {
  const state = makeState(
    [fighter(), fighter({ currentHp: 0 }), fighter()],
    fighter(),
  );

  it('quem caiu ou não existe não pode lutar', () => {
    expect(switchRefusal(state, 1)).toBe('Esse Ecobeast não pode lutar.');
    expect(switchRefusal(state, 9)).toBe('Esse Ecobeast não pode lutar.');
    expect(switchRefusal(state, 2)).toBeNull();
  });

  it('quem está em campo não entra de novo', () => {
    expect(inFieldRefusal(state, 0)).toBe('Esse Ecobeast já está em campo.');
    expect(inFieldRefusal(state, 2)).toBeNull();
  });
});

describe('itens', () => {
  const useItem = (itemId = TONIC, teamIndex = 0) =>
    ({ type: 'item', item_id: itemId, team_index: teamIndex }) as const;
  const hurt = (overrides: Partial<BattleState>) =>
    makeState(fighter({ currentHp: 5 }), fighter(), overrides);

  it('o Tônico cura sem passar do HP máximo', () => {
    expect(itemEffect(hurt({ bag: bag() }), useItem(), catalog)).toMatchObject({
      healed: 8,
    });
    const almostFull = makeState(fighter({ currentHp: 15 }), fighter(), {
      bag: bag(),
    });
    expect(itemEffect(almostFull, useItem(), catalog)).toMatchObject({
      healed: 4,
    });
  });

  it('o Bálsamo tira o status', () => {
    const poisoned = makeState(fighter({ statusSlug: 'poison' }), fighter(), {
      bag: bag(BALM),
    });
    expect(itemEffect(poisoned, useItem(BALM), catalog)).toMatchObject({
      curesStatus: true,
    });
  });

  it.each([
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
  ])('item %s é recusado', (_name, overrides, action, message) => {
    expect(itemEffect(hurt(overrides), action, catalog)).toEqual({
      error: message,
    });
  });

  it('com HP cheio, é recusado', () => {
    const state = makeState(fighter(), fighter(), { bag: bag() });
    expect(itemEffect(state, useItem(), catalog)).toEqual({
      error: 'Não teria efeito.',
    });
  });

  it('em um reserva com 0 HP, é recusado', () => {
    const state = makeState([fighter(), fighter({ currentHp: 0 })], fighter(), {
      bag: bag(),
    });
    expect(itemEffect(state, useItem(TONIC, 1), catalog)).toEqual({
      error: 'Só o Refúgio recupera um Ecobeast sem HP.',
    });
  });

  it('gastar tira 1 da quantidade e conta o gasto', () => {
    const state = hurt({ bag: bag(TONIC, 3) });
    spendItem(state, TONIC);
    expect(state.bag).toEqual([{ itemId: TONIC, quantity: 2, used: 1 }]);
  });

  it('a última unidade gasta deixa de valer', () => {
    const state = hurt({ bag: bag() });
    expect(ownedItem(state, TONIC, catalog)).not.toBeNull();
    spendItem(state, TONIC);
    expect(ownedItem(state, TONIC, catalog)).toBeNull();
  });
});

describe('resultado sem inimigos de pé', () => {
  const ended = (enemies: Combatant[]) =>
    resultWithoutEnemies(makeState(fighter(), enemies));

  it('com algum desmaiado, é vitória', () => {
    expect(
      ended([fighter({ currentHp: 0 }), fighter({ captured: true })]),
    ).toBe('victory');
  });

  it('com todos capturados, é captura', () => {
    expect(ended([fighter({ captured: true })])).toBe('captured');
  });
});
