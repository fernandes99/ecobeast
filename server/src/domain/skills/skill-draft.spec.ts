import { describe, expect, it } from 'vitest';
import {
  type SkillDraft,
  type SkillDraftTables,
  skillDraftError,
} from './skill-draft.js';

const LEVEL_UP = 1;
const EVOLUTION = 2;
const TEACHABLE = 3;
const RUVO = 1;
const NILU = 2;

function tables(overrides: Partial<SkillDraftTables> = {}): SkillDraftTables {
  return {
    elementIds: new Set([1, 2]),
    skillCategoryIds: new Set([1, 2, 3]),
    skillTargetIds: new Set([1, 2, 4]),
    areaShapeIds: new Set([1, 2]),
    targetSlugs: new Map([
      [1, 'enemy'],
      [2, 'self'],
      [4, 'ally'],
    ]),
    areaSlugs: new Map([
      [1, 'single'],
      [2, 'line'],
    ]),
    groundEffectIds: new Set([1]),
    statusConditionIds: new Set([1]),
    statIds: new Set([1]),
    effectTypes: new Map([
      [1, { slug: 'apply_status', name: 'Aplicar status' }],
      [2, { slug: 'modify_stat', name: 'Alterar atributo' }],
      [3, { slug: 'heal', name: 'Curar' }],
      [8, { slug: 'fixed_damage', name: 'Dano fixo' }],
      [9, { slug: 'set_weather', name: 'Mudar clima' }],
      [12, { slug: 'new_thing', name: 'Novo' }],
    ]),
    species: new Map([
      [RUVO, 'Ruvo'],
      [NILU, 'Nilu'],
    ]),
    learnMethods: new Map([
      [LEVEL_UP, 'level_up'],
      [EVOLUTION, 'evolution'],
      [TEACHABLE, 'teachable'],
    ]),
    levelOneBefore: new Set([RUVO, NILU]),
    levelOneOthers: new Set([RUVO, NILU]),
    ...overrides,
  };
}

function draft(overrides: Partial<SkillDraft> = {}): SkillDraft {
  return {
    slug: 'zz_teste',
    name: 'Teste',
    description: '',
    element_id: 1,
    skill_category_id: 1,
    skill_target_id: 1,
    area_shape_id: 1,
    power: 40,
    min_hits: 1,
    max_hits: 1,
    ground_effect_id: null,
    ground_turns: null,
    effects: [],
    learners: [],
    ...overrides,
  };
}

describe('skillDraftError', () => {
  it('aceita uma Técnica certa', () => {
    expect(skillDraftError(draft(), tables(), true)).toBeNull();
  });

  it('confere o slug só ao criar', () => {
    const bad = draft({ slug: 'Com Espaço' });
    expect(skillDraftError(bad, tables(), true)).toBe(
      'O slug só pode ter letras minúsculas, números e _.',
    );
    expect(skillDraftError(bad, tables(), false)).toBeNull();
  });

  it('recusa o nome vazio', () => {
    expect(skillDraftError(draft({ name: '  ' }), tables(), false)).toBe(
      'O nome não pode ficar vazio.',
    );
  });

  it('recusa um Elemento que não existe', () => {
    expect(skillDraftError(draft({ element_id: 99 }), tables(), false)).toBe(
      'O Elemento 99 não existe.',
    );
  });

  it('pede poder 0 e um alvo só numa Técnica para o time', () => {
    const team = { skill_target_id: 4, power: 0 };
    expect(skillDraftError(draft(team), tables(), false)).toBeNull();
    expect(
      skillDraftError(draft({ ...team, power: 30 }), tables(), false),
    ).toBe('Uma Técnica para o time não causa dano: o poder fica 0.');
    expect(
      skillDraftError(draft({ ...team, area_shape_id: 2 }), tables(), false),
    ).toBe('Uma Técnica para o time atinge um Ecobeast só: a área é Um alvo.');
  });

  it('recusa mais golpes no mínimo que no máximo', () => {
    expect(
      skillDraftError(draft({ min_hits: 3, max_hits: 2 }), tables(), false),
    ).toBe('O mínimo de golpes não pode passar do máximo.');
  });

  it('pede a marca no chão e os turnos juntos', () => {
    expect(
      skillDraftError(draft({ ground_effect_id: 1 }), tables(), false),
    ).toBe('A marca no chão e os turnos dela vêm juntos.');
    expect(
      skillDraftError(
        draft({ ground_effect_id: 1, ground_turns: 3 }),
        tables(),
        false,
      ),
    ).toBeNull();
  });

  describe('efeitos', () => {
    it('pede o Estado no apply_status', () => {
      const effects = [{ effect_type_id: 3, chance: 100, percent: 50 }];
      const missing = [{ effect_type_id: 1, chance: 30 }];
      expect(
        skillDraftError(
          draft({ effects: [...effects, ...missing] }),
          tables(),
          false,
        ),
      ).toBe('O efeito 2 (Aplicar status) precisa de um Estado.');
    });

    it('recusa uma coluna que o tipo não usa', () => {
      const effects = [
        { effect_type_id: 3, chance: 100, percent: 50, stat_id: 1 },
      ];
      expect(skillDraftError(draft({ effects }), tables(), false)).toBe(
        'O efeito 1 (Curar) não usa o atributo.',
      );
    });

    it('pede o alvo, o atributo e os estágios no modify_stat, sem 0', () => {
      const base = {
        effect_type_id: 2,
        chance: 100,
        skill_target_id: 1,
        stat_id: 1,
      };
      expect(
        skillDraftError(
          draft({ effects: [{ ...base, stages: 1 }] }),
          tables(),
          false,
        ),
      ).toBeNull();
      expect(
        skillDraftError(
          draft({ effects: [{ ...base, stages: 0 }] }),
          tables(),
          false,
        ),
      ).toBe('O efeito 1 (Alterar atributo) não pode ter 0 estágios.');
      expect(
        skillDraftError(
          draft({
            effects: [
              { effect_type_id: 2, chance: 100, stat_id: 1, stages: 1 },
            ],
          }),
          tables(),
          false,
        ),
      ).toBe('O efeito 1 (Alterar atributo) precisa de um alvo.');
    });

    it('aceita o valor opcional do fixed_damage', () => {
      const effects = [{ effect_type_id: 8, chance: 100, value: 20 }];
      expect(skillDraftError(draft({ effects }), tables(), false)).toBeNull();
    });

    it('recusa o set_weather e um tipo sem regra', () => {
      expect(
        skillDraftError(
          draft({ effects: [{ effect_type_id: 9, chance: 100 }] }),
          tables(),
          false,
        ),
      ).toBe('O clima ainda não existe.');
      expect(
        skillDraftError(
          draft({ effects: [{ effect_type_id: 12, chance: 100 }] }),
          tables(),
          false,
        ),
      ).toBe('Esse tipo de efeito ainda não tem regra no jogo.');
    });

    it('recusa um Estado que não existe', () => {
      const effects = [
        { effect_type_id: 1, chance: 100, status_condition_id: 7 },
      ];
      expect(skillDraftError(draft({ effects }), tables(), false)).toBe(
        'O efeito 1 (Aplicar status) tem o Estado 7, que não existe.',
      );
    });
  });

  describe('quem aprende', () => {
    it('pede o nível de 1 a 100 por nível', () => {
      const learners = [
        { species_id: RUVO, skill_learn_method_id: LEVEL_UP, level: 0 },
      ];
      expect(skillDraftError(draft({ learners }), tables(), false)).toBe(
        'O nível do Ruvo vai de 1 a 100.',
      );
    });

    it('pede o nível 0 ao evoluir e nenhum no ensinável', () => {
      expect(
        skillDraftError(
          draft({
            learners: [
              {
                species_id: RUVO,
                skill_learn_method_id: EVOLUTION,
                level: null,
              },
            ],
          }),
          tables(),
          false,
        ),
      ).toBe('Ao evoluir, o nível do Ruvo é 0.');
      expect(
        skillDraftError(
          draft({
            learners: [
              { species_id: RUVO, skill_learn_method_id: EVOLUTION, level: 0 },
              {
                species_id: NILU,
                skill_learn_method_id: TEACHABLE,
                level: null,
              },
            ],
          }),
          tables(),
          false,
        ),
      ).toBeNull();
      expect(
        skillDraftError(
          draft({
            learners: [
              { species_id: NILU, skill_learn_method_id: TEACHABLE, level: 5 },
            ],
          }),
          tables(),
          false,
        ),
      ).toBe('Ensinável não tem nível (Nilu).');
    });

    it('recusa a mesma espécie duas vezes com o mesmo método', () => {
      const learners = [
        { species_id: RUVO, skill_learn_method_id: LEVEL_UP, level: 5 },
        { species_id: RUVO, skill_learn_method_id: LEVEL_UP, level: 9 },
      ];
      expect(skillDraftError(draft({ learners }), tables(), false)).toBe(
        'O Ruvo aparece duas vezes com o mesmo método.',
      );
    });

    it('não deixa uma espécie sem Técnica no nível 1', () => {
      const onlyThis = tables({ levelOneOthers: new Set([NILU]) });
      expect(skillDraftError(draft(), onlyThis, false)).toBe(
        'O Ruvo ficaria sem Técnica no nível 1.',
      );
      const kept = draft({
        learners: [
          { species_id: RUVO, skill_learn_method_id: LEVEL_UP, level: 1 },
        ],
      });
      expect(skillDraftError(kept, onlyThis, false)).toBeNull();
    });
  });
});
