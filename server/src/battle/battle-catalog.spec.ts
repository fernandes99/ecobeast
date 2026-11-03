import { CatalogRows, toBattleCatalog } from './battle-catalog.js';

type SkillRow = CatalogRows['skills'][number];

function skill(overrides: Partial<SkillRow> = {}): SkillRow {
  return {
    id: 2,
    slug: 'rugido_feroz',
    name: 'Rugido Feroz',
    description: '',
    elementId: 13,
    skillCategoryId: 3,
    power: 0,
    accuracy: 100,
    maxPp: 40,
    priority: 0,
    critStage: 0,
    skillTargetId: 1,
    makesContact: false,
    minHits: 1,
    maxHits: 1,
    element: { slug: 'instinct' },
    skillCategory: { slug: 'support' },
    skillTarget: { slug: 'enemy' },
    effects: [],
    ...overrides,
  };
}

function effect(
  overrides: Partial<SkillRow['effects'][number]> = {},
): SkillRow['effects'][number] {
  return {
    id: 1,
    skillId: 2,
    effectTypeId: 2,
    sortOrder: 1,
    chance: 100,
    skillTargetId: null,
    statusConditionId: null,
    statId: null,
    stages: null,
    percent: null,
    value: null,
    weatherId: null,
    minTurns: null,
    effectType: { slug: 'heal' },
    skillTarget: null,
    statusCondition: null,
    stat: null,
    ...overrides,
  };
}

const NO_ROWS: CatalogRows = {
  skills: [],
  efficacy: [],
  immunities: [],
  items: [],
  species: [],
};

describe('toBattleCatalog', () => {
  it('monta os itens com o que a regra de uso precisa', () => {
    const { items } = toBattleCatalog({
      ...NO_ROWS,
      items: [
        { id: 4, healAmount: 20, curesStatus: false, captureBonus: null },
      ],
    });
    expect(items.get(4)).toEqual({
      healAmount: 20,
      curesStatus: false,
      captureBonus: null,
    });
  });

  it('traz o bônus das Esferas e a taxa de cada espécie', () => {
    const { items, captureRates } = toBattleCatalog({
      ...NO_ROWS,
      items: [{ id: 1, healAmount: null, curesStatus: false, captureBonus: 2 }],
      species: [{ id: 7, captureRate: 45 }],
    });
    expect(items.get(1)!.captureBonus).toBe(2);
    expect(captureRates.get(7)).toBe(45);
  });

  it('monta a Técnica com os slugs que as regras usam', () => {
    const { skills } = toBattleCatalog({ ...NO_ROWS, skills: [skill()] });
    expect(skills.get(2)).toEqual({
      id: 2,
      elementId: 13,
      elementSlug: 'instinct',
      category: 'support',
      power: 0,
      accuracy: 100,
      maxPp: 40,
      priority: 0,
      critStage: 0,
      targetSlug: 'enemy',
      effects: [],
    });
  });

  it('monta os efeitos na ordem das linhas', () => {
    const rows = [
      effect({
        effectType: { slug: 'modify_stat' },
        chance: 20,
        skillTarget: { slug: 'enemy' },
        stat: { slug: 'atk' },
        stages: -1,
      }),
      effect({
        effectType: { slug: 'apply_status' },
        statusCondition: { slug: 'burn' },
      }),
      effect({ effectType: { slug: 'recoil' }, percent: 33 }),
    ];
    const { skills } = toBattleCatalog({
      ...NO_ROWS,
      skills: [skill({ effects: rows })],
    });
    expect(skills.get(2)!.effects).toEqual([
      {
        effectSlug: 'modify_stat',
        chance: 20,
        targetSlug: 'enemy',
        statusSlug: null,
        statSlug: 'atk',
        stages: -1,
        percent: null,
      },
      {
        effectSlug: 'apply_status',
        chance: 100,
        targetSlug: null,
        statusSlug: 'burn',
        statSlug: null,
        stages: null,
        percent: null,
      },
      {
        effectSlug: 'recoil',
        chance: 100,
        targetSlug: null,
        statusSlug: null,
        statSlug: null,
        stages: null,
        percent: 33,
      },
    ]);
  });

  it('indexa a efetividade por atacante e defensor', () => {
    const { efficacy } = toBattleCatalog({
      ...NO_ROWS,
      efficacy: [
        { attackerElementId: 1, defenderElementId: 3, multiplier: 2 },
        { attackerElementId: 4, defenderElementId: 5, multiplier: 0 },
      ],
    });
    expect(efficacy.get('1:3')).toBe(2);
    expect(efficacy.get('4:5')).toBe(0);
  });

  it('junta os Elementos imunes de cada status', () => {
    const { statusImmunities } = toBattleCatalog({
      ...NO_ROWS,
      immunities: [
        { elementId: 1, statusCondition: { slug: 'burn' } },
        { elementId: 9, statusCondition: { slug: 'poison' } },
        { elementId: 8, statusCondition: { slug: 'poison' } },
      ],
    });
    expect(statusImmunities.get('burn')).toEqual([1]);
    expect(statusImmunities.get('poison')).toEqual([9, 8]);
  });
});
