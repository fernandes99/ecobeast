import {
  checkQuestDraft,
  type QuestDraft,
  QUEST_INPUT_ERRORS,
} from './quest-input.js';

const empty: QuestDraft = {
  questTypeId: 1,
  amount: null,
  speciesId: null,
  targetNpcId: null,
  placeName: null,
  title: null,
  coins: null,
  itemId: null,
  itemQuantity: null,
  countsForUnlock: null,
  tiles: null,
};

describe('a missão do editor (auralis/07)', () => {
  it('limpa os parâmetros que o tipo não usa e põe os padrões', () => {
    expect(
      checkQuestDraft({
        ...empty,
        amount: 3,
        speciesId: 15,
        placeName: 'o Farol',
        tiles: [{ q: 1, r: 0 }],
        title: '  ',
      }),
    ).toEqual({
      quest: {
        questTypeId: 1,
        amount: 3,
        speciesId: null,
        targetNpcId: null,
        placeName: null,
        title: null,
        coins: 0,
        itemId: null,
        itemQuantity: null,
        countsForUnlock: true,
        tiles: [],
      },
    });
  });

  it('pede o parâmetro de cada tipo', () => {
    const errorOf = (draft: Partial<QuestDraft>) => {
      const result = checkQuestDraft({ ...empty, ...draft });
      return 'error' in result ? result.error : null;
    };
    expect(errorOf({ questTypeId: 10 })).toBe(QUEST_INPUT_ERRORS.type);
    expect(errorOf({ questTypeId: 2 })).toBe(QUEST_INPUT_ERRORS.amount);
    expect(errorOf({ questTypeId: 3, amount: 101 })).toBe(
      QUEST_INPUT_ERRORS.percent,
    );
    expect(errorOf({ questTypeId: 4, placeName: 'Farol' })).toBe(
      QUEST_INPUT_ERRORS.tiles,
    );
    expect(errorOf({ questTypeId: 4, tiles: [{ q: 0, r: 0 }] })).toBe(
      QUEST_INPUT_ERRORS.placeName,
    );
    expect(errorOf({ questTypeId: 5 })).toBe(QUEST_INPUT_ERRORS.targetNpc);
    expect(errorOf({ questTypeId: 6, amount: 0 })).toBe(
      QUEST_INPUT_ERRORS.minutes,
    );
    expect(errorOf({ questTypeId: 7 })).toBe(QUEST_INPUT_ERRORS.species);
    expect(errorOf({ questTypeId: 8, speciesId: 1, amount: 0 })).toBe(
      QUEST_INPUT_ERRORS.amount,
    );
    expect(errorOf({ questTypeId: 9 })).toBe(QUEST_INPUT_ERRORS.targetNpc);
    expect(errorOf({ amount: 1, title: 'x'.repeat(61) })).toBe(
      QUEST_INPUT_ERRORS.title,
    );
    expect(errorOf({ amount: 1, coins: -1 })).toBe(QUEST_INPUT_ERRORS.coins);
    expect(errorOf({ amount: 1, itemId: 2, itemQuantity: 100 })).toBe(
      QUEST_INPUT_ERRORS.itemQuantity,
    );
  });

  it('no "Vá até", tira os hexágonos repetidos e recusa os inválidos', () => {
    const place = { questTypeId: 4, placeName: ' o Farol ' };
    const result = checkQuestDraft({
      ...empty,
      ...place,
      tiles: [
        { q: 1, r: 0 },
        { q: 1, r: 0 },
        { q: 2, r: -1 },
      ],
    });
    expect('quest' in result && result.quest).toMatchObject({
      placeName: 'o Farol',
      tiles: [
        { q: 1, r: 0 },
        { q: 2, r: -1 },
      ],
    });
    expect(
      checkQuestDraft({ ...empty, ...place, tiles: [{ q: 'a', r: 0 }] }),
    ).toEqual({ error: QUEST_INPUT_ERRORS.tiles });
  });

  it('o item sem quantidade vale 1', () => {
    const result = checkQuestDraft({ ...empty, amount: 1, itemId: 4 });
    expect('quest' in result && result.quest.itemQuantity).toBe(1);
  });
});
