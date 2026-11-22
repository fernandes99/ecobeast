import {
  acceptedLine,
  type ActiveQuest,
  battleQuestDeltas,
  claimedLine,
  explorePercent,
  progressLine,
  QUEST_TYPES,
  type QuestParams,
  questTarget,
  questTitle,
} from './quests.js';

const names = { island: 'Liora', species: 'Puffcoo', targetNpc: 'Mira' };

function quest(
  slug: keyof typeof QUEST_TYPES,
  extra: Partial<QuestParams> = {},
): QuestParams {
  return {
    questTypeId: QUEST_TYPES[slug],
    amount: null,
    placeName: null,
    title: null,
    ...extra,
  };
}

describe('os títulos das missões (auralis/06)', () => {
  it('saem do tipo e dos parâmetros', () => {
    expect(questTitle(quest('capture_any', { amount: 3 }), names)).toBe(
      'Capture 3 Ecobeasts',
    );
    expect(questTitle(quest('defeat_any', { amount: 1 }), names)).toBe(
      'Derrote 1 Ecobeast',
    );
    expect(questTitle(quest('explore_percent', { amount: 50 }), names)).toBe(
      'Explore 50% de Liora',
    );
    expect(
      questTitle(quest('reach_place', { placeName: 'o Farol' }), names),
    ).toBe('Vá até o Farol');
    expect(questTitle(quest('talk_npc'), names)).toBe('Fale com Mira');
    expect(questTitle(quest('stay_minutes', { amount: 5 }), names)).toBe(
      'Fique em Liora por 5 minutos',
    );
    expect(questTitle(quest('find_species'), names)).toBe('Encontre Puffcoo');
    expect(questTitle(quest('find_species', { amount: 2 }), names)).toBe(
      'Encontre 2 Puffcoo',
    );
    expect(questTitle(quest('defeat_species'), names)).toBe('Derrote Puffcoo');
    expect(questTitle(quest('defeat_tamer'), names)).toBe('Derrote Mira');
  });

  it('o "Encontre X item" usa o nome do item (auralis/09)', () => {
    const withItem = { ...names, targetItem: 'Tônico Leve' };
    expect(questTitle(quest('find_item'), withItem)).toBe(
      'Encontre Tônico Leve',
    );
    expect(questTitle(quest('find_item', { amount: 3 }), withItem)).toBe(
      'Encontre 3 Tônico Leve',
    );
    expect(questTarget(quest('find_item'))).toBe(1);
    expect(questTarget(quest('find_item', { amount: 3 }))).toBe(3);
  });

  it('o título próprio vale no lugar', () => {
    expect(
      questTitle(
        quest('capture_any', { amount: 3, title: 'Ajude o vovô' }),
        names,
      ),
    ).toBe('Ajude o vovô');
  });
});

describe('o alvo e as falas (auralis/06)', () => {
  it('o "Fique" conta em segundos, e "Encontre" sem quantidade pede 1', () => {
    expect(questTarget(quest('stay_minutes', { amount: 5 }))).toBe(300);
    expect(questTarget(quest('find_species'))).toBe(1);
    expect(questTarget(quest('reach_place', { placeName: 'x' }))).toBe(1);
    expect(questTarget(quest('explore_percent', { amount: 40 }))).toBe(40);
  });

  it('mostram o progresso na unidade do tipo', () => {
    expect(
      progressLine(quest('capture_any', { amount: 3 }), 'Capture 3', 1),
    ).toBe('Capture 3: 1 de 3.');
    expect(
      progressLine(quest('explore_percent', { amount: 50 }), 'Explore', 20),
    ).toBe('Explore: 20% de 50%.');
    expect(
      progressLine(quest('stay_minutes', { amount: 5 }), 'Fique', 150),
    ).toBe('Fique: 2 de 5 minutos.');
    expect(acceptedLine('Vá até o Farol')).toBe('Nova missão: Vá até o Farol.');
    expect(claimedLine('Vá até o Farol')).toBe(
      'Missão cumprida: Vá até o Farol!',
    );
  });

  it('o descoberto vira porcentagem, arredondada para baixo', () => {
    expect(explorePercent(1, 3)).toBe(33);
    expect(explorePercent(3, 3)).toBe(100);
    expect(explorePercent(0, 0)).toBe(0);
  });
});

describe('o fim da luta nas missões (auralis/06)', () => {
  const active = (
    questId: number,
    slug: keyof typeof QUEST_TYPES,
    extra: Partial<ActiveQuest> = {},
  ): ActiveQuest => ({
    questId,
    questTypeId: QUEST_TYPES[slug],
    speciesId: null,
    targetTamerId: null,
    ...extra,
  });
  const quests = [
    active(1, 'capture_any'),
    active(2, 'defeat_any'),
    active(3, 'find_species', { speciesId: 15 }),
    active(4, 'defeat_species', { speciesId: 15 }),
    active(5, 'defeat_tamer', { targetTamerId: 9 }),
    active(6, 'talk_npc'),
  ];

  it('soma cada tipo pelo seu acontecimento', () => {
    expect(
      battleQuestDeltas(
        {
          capturedSpeciesIds: [2],
          defeatedSpeciesIds: [15, 15, 3],
          enemySpeciesIds: [15, 3, 2],
          beatenTamerId: 9,
        },
        quests,
      ),
    ).toEqual([
      { questId: 1, amount: 1 },
      { questId: 2, amount: 3 },
      { questId: 3, amount: 1 },
      { questId: 4, amount: 2 },
      { questId: 5, amount: 1 },
    ]);
  });

  it('sem nada que conte, não soma', () => {
    expect(
      battleQuestDeltas(
        {
          capturedSpeciesIds: [],
          defeatedSpeciesIds: [],
          enemySpeciesIds: [3],
          beatenTamerId: 8,
        },
        quests,
      ),
    ).toEqual([]);
  });
});
