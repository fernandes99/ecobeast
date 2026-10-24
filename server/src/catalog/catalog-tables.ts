import { fileURLToPath } from 'node:url';

/** Uma tabela do catálogo: nome no banco, delegate do Prisma e colunas da chave. */
export interface CatalogTable {
  name: string;
  /** O delegate do Prisma: o nome do modelo, no singular (Element → element). */
  model: string;
  key: readonly string[];
}

const table = (
  name: string,
  model: string,
  key: readonly string[] = ['id'],
): CatalogTable => ({
  name,
  model,
  key,
});

/**
 * As 23 tabelas do catálogo em ordem de dependência: cada FK aponta para uma
 * tabela que vem antes (a autorreferência de species é tratada no seed).
 * Usada pelo seed e pelo catálogo inteiro (GET /v1/catalog).
 */
export const CATALOG_TABLES: readonly CatalogTable[] = [
  table('elements', 'element'),
  table('stats', 'stat'),
  table('growth_rates', 'growthRate'),
  table('rarities', 'rarity'),
  table('skill_categories', 'skillCategory'),
  table('skill_targets', 'skillTarget'),
  table('skill_learn_methods', 'skillLearnMethod'),
  table('status_conditions', 'statusCondition'),
  table('effect_types', 'effectType'),
  table('evolution_triggers', 'evolutionTrigger'),
  table('element_efficacy', 'elementEfficacy', [
    'attacker_element_id',
    'defender_element_id',
  ]),
  table('temperaments', 'temperament'),
  table('status_condition_immunities', 'statusConditionImmunity', [
    'status_condition_id',
    'element_id',
  ]),
  table('traits', 'trait'),
  table('species', 'species'),
  table('species_elements', 'speciesElement', ['species_id', 'slot']),
  table('species_stats', 'speciesStat', ['species_id', 'stat_id']),
  table('species_traits', 'speciesTrait', ['species_id', 'slot']),
  table('skills', 'skill'),
  table('skill_effects', 'skillEffect'),
  table('species_skills', 'speciesSkill', [
    'species_id',
    'skill_id',
    'skill_learn_method_id',
  ]),
  table('evolutions', 'evolution'),
  table('starter_options', 'starterOption', ['species_id']),
];

/** Os JSON do catálogo que alimentam o seed (até a backend-api/07: client/data/). */
export const SEED_DATA_DIR = fileURLToPath(
  new URL('../../../client/data/', import.meta.url),
);
