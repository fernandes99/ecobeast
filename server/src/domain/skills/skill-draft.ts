/**
 * As conferências de uma Técnica do editor (.specs/skill-editor/architecture.md,
 * "As conferências"). Além dos CHECKs do banco, elas repetem o CatalogValidator
 * do jogo: o que passa aqui, o jogo aceita no catálogo baixado.
 */

export const SKILL_SLUG_PATTERN = /^[a-z0-9_]+$/;
export const MIN_LEARN_LEVEL = 1;
export const MAX_LEARN_LEVEL = 100;
export const EVOLUTION_LEVEL = 0;
export const STARTING_LEVEL = 1;
export const ALLY_TARGET = 'ally';
export const SINGLE_AREA = 'single';

export const EFFECT_COLUMNS = [
  'skill_target_id',
  'status_condition_id',
  'stat_id',
  'stages',
  'percent',
  'value',
  'min_turns',
] as const;
export type EffectColumn = (typeof EFFECT_COLUMNS)[number];

/** Espelho do EFFECT_PARAMS de client/core/data/catalog_schema.gd. */
export const EFFECT_PARAMS: Record<
  string,
  { required: EffectColumn[]; optional: EffectColumn[] }
> = {
  apply_status: { required: ['status_condition_id'], optional: [] },
  modify_stat: {
    required: ['skill_target_id', 'stat_id', 'stages'],
    optional: [],
  },
  heal: { required: ['percent'], optional: [] },
  drain: { required: ['percent'], optional: [] },
  recoil: { required: ['percent'], optional: [] },
  flinch: { required: [], optional: [] },
  multi_turn: { required: [], optional: [] },
  fixed_damage: { required: [], optional: ['value'] },
  protect: { required: [], optional: [] },
  switch: { required: [], optional: [] },
};

/** O jogo exige weather_id, e o banco o obriga nulo. */
export const WEATHER_EFFECT = 'set_weather';

const COLUMN_LABELS: Record<EffectColumn, { need: string; use: string }> = {
  skill_target_id: { need: 'um alvo', use: 'o alvo' },
  status_condition_id: { need: 'um Estado', use: 'o Estado' },
  stat_id: { need: 'um atributo', use: 'o atributo' },
  stages: { need: 'os estágios', use: 'os estágios' },
  percent: { need: 'o %', use: 'o %' },
  value: { need: 'o valor', use: 'o valor' },
  min_turns: { need: 'os turnos', use: 'os turnos' },
};

export interface SkillEffectDraft {
  effect_type_id: number;
  chance: number;
  skill_target_id?: number | null;
  status_condition_id?: number | null;
  stat_id?: number | null;
  stages?: number | null;
  percent?: number | null;
  value?: number | null;
  min_turns?: number | null;
}

export interface SkillLearnerDraft {
  species_id: number;
  skill_learn_method_id: number;
  level?: number | null;
}

export interface SkillDraft {
  slug?: string;
  name: string;
  description: string;
  element_id: number;
  skill_category_id: number;
  skill_target_id: number;
  area_shape_id: number;
  power: number;
  min_hits: number;
  max_hits: number;
  ground_effect_id?: number | null;
  ground_turns?: number | null;
  effects: SkillEffectDraft[];
  learners: SkillLearnerDraft[];
}

export interface SkillDraftTables {
  elementIds: Set<number>;
  skillCategoryIds: Set<number>;
  skillTargetIds: Set<number>;
  areaShapeIds: Set<number>;
  /** id → slug, de `skill_targets` e de `area_shapes`. */
  targetSlugs: Map<number, string>;
  areaSlugs: Map<number, string>;
  groundEffectIds: Set<number>;
  statusConditionIds: Set<number>;
  statIds: Set<number>;
  /** id → slug e nome. */
  effectTypes: Map<number, { slug: string; name: string }>;
  /** id → nome. */
  species: Map<number, string>;
  /** id → slug. */
  learnMethods: Map<number, string>;
  /** As espécies que têm uma Técnica por nível no nível 1 hoje, contando esta. */
  levelOneBefore: Set<number>;
  /** As espécies que têm uma Técnica por nível no nível 1 sem contar esta. */
  levelOneOthers: Set<number>;
}

/** A primeira coisa errada na Técnica, ou null quando ela pode ser gravada. */
export function skillDraftError(
  draft: SkillDraft,
  tables: SkillDraftTables,
  creating: boolean,
): string | null {
  return (
    fieldsError(draft, tables, creating) ??
    effectsError(draft.effects, tables) ??
    learnersError(draft.learners, tables)
  );
}

function fieldsError(
  draft: SkillDraft,
  tables: SkillDraftTables,
  creating: boolean,
): string | null {
  if (creating && !SKILL_SLUG_PATTERN.test(draft.slug ?? '')) {
    return 'O slug só pode ter letras minúsculas, números e _.';
  }
  if (draft.name.trim() === '') return 'O nome não pode ficar vazio.';
  const refs: [Set<number>, number, string][] = [
    [tables.elementIds, draft.element_id, 'O Elemento'],
    [tables.skillCategoryIds, draft.skill_category_id, 'A categoria'],
    [tables.skillTargetIds, draft.skill_target_id, 'O alvo'],
    [tables.areaShapeIds, draft.area_shape_id, 'A área'],
  ];
  for (const [ids, id, label] of refs) {
    if (!ids.has(id)) return `${label} ${id} não existe.`;
  }
  if (tables.targetSlugs.get(draft.skill_target_id) === ALLY_TARGET) {
    if (draft.power !== 0) {
      return 'Uma Técnica para o time não causa dano: o poder fica 0.';
    }
    if (tables.areaSlugs.get(draft.area_shape_id) !== SINGLE_AREA) {
      return 'Uma Técnica para o time atinge um Ecobeast só: a área é Um alvo.';
    }
  }
  if (draft.min_hits > draft.max_hits) {
    return 'O mínimo de golpes não pode passar do máximo.';
  }
  const ground = draft.ground_effect_id ?? null;
  const turns = draft.ground_turns ?? null;
  if ((ground === null) !== (turns === null)) {
    return 'A marca no chão e os turnos dela vêm juntos.';
  }
  if (ground !== null && !tables.groundEffectIds.has(ground)) {
    return `A marca no chão ${ground} não existe.`;
  }
  return null;
}

function effectsError(
  effects: SkillEffectDraft[],
  tables: SkillDraftTables,
): string | null {
  for (const [index, effect] of effects.entries()) {
    const type = tables.effectTypes.get(effect.effect_type_id);
    const position = index + 1;
    if (!type) {
      return `O tipo do efeito ${position} (${effect.effect_type_id}) não existe.`;
    }
    const label = `O efeito ${position} (${type.name})`;
    if (type.slug === WEATHER_EFFECT) return 'O clima ainda não existe.';
    const params = EFFECT_PARAMS[type.slug];
    if (!params) return 'Esse tipo de efeito ainda não tem regra no jogo.';
    for (const column of EFFECT_COLUMNS) {
      const value = effect[column] ?? null;
      const required = params.required.includes(column);
      if (required && value === null) {
        return `${label} precisa de ${COLUMN_LABELS[column].need}.`;
      }
      if (!required && !params.optional.includes(column) && value !== null) {
        return `${label} não usa ${COLUMN_LABELS[column].use}.`;
      }
    }
    if (effect.stages === 0) return `${label} não pode ter 0 estágios.`;
    const refs: [Set<number>, number | null | undefined, string][] = [
      [tables.skillTargetIds, effect.skill_target_id, 'o alvo'],
      [tables.statusConditionIds, effect.status_condition_id, 'o Estado'],
      [tables.statIds, effect.stat_id, 'o atributo'],
    ];
    for (const [ids, id, what] of refs) {
      if (id != null && !ids.has(id)) {
        return `${label} tem ${what} ${id}, que não existe.`;
      }
    }
  }
  return null;
}

function learnersError(
  learners: SkillLearnerDraft[],
  tables: SkillDraftTables,
): string | null {
  const seen = new Set<string>();
  const levelOneAfter = new Set(tables.levelOneOthers);
  for (const learner of learners) {
    const species = tables.species.get(learner.species_id);
    if (species === undefined) {
      return `O Ecobeast ${learner.species_id} não existe.`;
    }
    const method = tables.learnMethods.get(learner.skill_learn_method_id);
    if (method === undefined) {
      return `O método ${learner.skill_learn_method_id} não existe.`;
    }
    const pair = `${learner.species_id}:${learner.skill_learn_method_id}`;
    if (seen.has(pair)) {
      return `O ${species} aparece duas vezes com o mesmo método.`;
    }
    seen.add(pair);
    const level = learner.level ?? null;
    if (method === 'level_up') {
      if (
        level === null ||
        level < MIN_LEARN_LEVEL ||
        level > MAX_LEARN_LEVEL
      ) {
        return `O nível do ${species} vai de ${MIN_LEARN_LEVEL} a ${MAX_LEARN_LEVEL}.`;
      }
      if (level === STARTING_LEVEL) levelOneAfter.add(learner.species_id);
    } else if (method === 'evolution' && level !== EVOLUTION_LEVEL) {
      return `Ao evoluir, o nível do ${species} é ${EVOLUTION_LEVEL}.`;
    } else if (method === 'teachable' && level !== null) {
      return `Ensinável não tem nível (${species}).`;
    }
  }
  for (const speciesId of tables.levelOneBefore) {
    if (!levelOneAfter.has(speciesId)) {
      const name = tables.species.get(speciesId) ?? String(speciesId);
      return `O ${name} ficaria sem Técnica no nível 1.`;
    }
  }
  return null;
}
