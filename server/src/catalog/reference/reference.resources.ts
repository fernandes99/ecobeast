import { ApiProperty } from '@nestjs/swagger';
import { ref, ResourceRef } from '../../common/resource-ref.js';
import type {
  Element,
  GrowthRate,
  Rarity,
  Stat,
  StatusCondition,
  StatusConditionImmunity,
  Temperament,
} from '../../generated/prisma/client.js';
import {
  named,
  NamedResourceDto,
  NamedRow,
  resourceController,
} from '../resource-controller.js';

// Recursos de referência (.specs/backend-api/05-catalog-api.md, RF-02):
// temperamentos, stats, curvas de XP, raridades, status e os que só têm nome.

export class TemperamentDetailDto extends NamedResourceDto {
  @ApiProperty({
    example: { id: 2, slug: 'atk', name: 'Ataque', url: '/v1/stats/2' },
  })
  increased_stat: ResourceRef;

  @ApiProperty({
    example: {
      id: 4,
      slug: 'sp_atk',
      name: 'Ataque Especial',
      url: '/v1/stats/4',
    },
  })
  decreased_stat: ResourceRef;
}

export class StatDetailDto extends NamedResourceDto {
  @ApiProperty({ example: 'HP' })
  short_name: string;

  @ApiProperty({
    description: 'Só existe durante a batalha (precisão, evasão).',
    example: false,
  })
  is_battle_only: boolean;
}

export class GrowthRateDetailDto extends NamedResourceDto {
  @ApiProperty({
    description: 'XP total de um nível = multiplicador × nível³.',
    example: 1,
  })
  xp_multiplier: number;
}

export class RarityDetailDto extends NamedResourceDto {
  @ApiProperty({
    description: 'Ordem da mais comum para a mais rara.',
    example: 1,
  })
  sort_order: number;
}

export class StatusConditionDetailDto extends NamedResourceDto {
  @ApiProperty({
    description: 'Voláteis acabam ao sair da batalha.',
    example: false,
  })
  is_volatile: boolean;

  @ApiProperty({
    type: () => [ResourceRef],
    description: 'Elementos que não pegam este status.',
  })
  immune_elements: ResourceRef[];
}

export const TemperamentsController = resourceController<
  Temperament & { increasedStat: Stat; decreasedStat: Stat },
  TemperamentDetailDto
>({
  path: 'temperaments',
  model: 'temperament',
  tag: 'Temperamentos',
  notFound: 'Temperamento não encontrado',
  list: {
    summary: 'Lista os Temperamentos',
    description: 'Os 25 Temperamentos em ordem de id, paginados.',
  },
  detail: {
    summary: 'Um Temperamento',
    description: 'O stat que aumenta 10% e o que diminui 10%.',
    example: '1',
  },
  dto: TemperamentDetailDto,
  include: { increasedStat: true, decreasedStat: true },
  toDto: (row) => ({
    ...named(row),
    increased_stat: ref('stats', row.increasedStat),
    decreased_stat: ref('stats', row.decreasedStat),
  }),
});

export const StatsController = resourceController<Stat, StatDetailDto>({
  path: 'stats',
  model: 'stat',
  tag: 'Stats',
  notFound: 'Stat não encontrado',
  list: {
    summary: 'Lista os stats',
    description: 'Os stats em ordem de id, paginados.',
  },
  detail: {
    summary: 'Um stat',
    description: 'Nome curto e se só existe durante a batalha.',
    example: 'hp',
  },
  dto: StatDetailDto,
  toDto: (row) => ({
    ...named(row),
    short_name: row.shortName,
    is_battle_only: row.isBattleOnly,
  }),
});

export const GrowthRatesController = resourceController<
  GrowthRate,
  GrowthRateDetailDto
>({
  path: 'growth-rates',
  model: 'growthRate',
  tag: 'Curvas de XP',
  notFound: 'Curva de XP não encontrada',
  list: {
    summary: 'Lista as curvas de XP',
    description: 'As curvas de XP em ordem de id, paginadas.',
  },
  detail: {
    summary: 'Uma curva de XP',
    description: 'O multiplicador que dá o XP total de cada nível.',
    example: 'medium',
  },
  dto: GrowthRateDetailDto,
  toDto: (row) => ({ ...named(row), xp_multiplier: row.xpMultiplier }),
});

export const RaritiesController = resourceController<Rarity, RarityDetailDto>({
  path: 'rarities',
  model: 'rarity',
  tag: 'Raridades',
  notFound: 'Raridade não encontrada',
  list: {
    summary: 'Lista as raridades',
    description: 'As raridades em ordem de id, paginadas.',
  },
  detail: {
    summary: 'Uma raridade',
    description: 'A posição da raridade, da mais comum à mais rara.',
    example: '1',
  },
  dto: RarityDetailDto,
  toDto: (row) => ({ ...named(row), sort_order: row.sortOrder }),
});

export const StatusConditionsController = resourceController<
  StatusCondition & {
    immunities: (StatusConditionImmunity & { element: Element })[];
  },
  StatusConditionDetailDto
>({
  path: 'status-conditions',
  model: 'statusCondition',
  tag: 'Status',
  notFound: 'Status não encontrado',
  list: {
    summary: 'Lista os status',
    description: 'Os status em ordem de id, paginados.',
  },
  detail: {
    summary: 'Um status',
    description: 'Se é volátil e os Elementos imunes.',
    example: '1',
  },
  dto: StatusConditionDetailDto,
  include: {
    immunities: { include: { element: true }, orderBy: { elementId: 'asc' } },
  },
  toDto: (row) => ({
    ...named(row),
    is_volatile: row.isVolatile,
    immune_elements: row.immunities.map((immunity) =>
      ref('elements', immunity.element),
    ),
  }),
});

/** Recursos que só têm id, slug e nome. */
const namedResource = (
  path: string,
  model: string,
  tag: string,
  notFound: string,
  what: string,
  example: string,
) =>
  resourceController<NamedRow, NamedResourceDto>({
    path,
    model,
    tag,
    notFound,
    list: {
      summary: `Lista: ${what}`,
      description: `${what} em ordem de id, paginados.`,
    },
    detail: {
      summary: tag,
      description: `Um item de ${what.toLowerCase()}.`,
      example,
    },
    dto: NamedResourceDto,
    toDto: named,
  });

export const SkillCategoriesController = namedResource(
  'skill-categories',
  'skillCategory',
  'Categorias de Técnica',
  'Categoria de Técnica não encontrada',
  'Categorias de Técnica (física, especial, status)',
  'physical',
);
export const SkillTargetsController = namedResource(
  'skill-targets',
  'skillTarget',
  'Alvos de Técnica',
  'Alvo de Técnica não encontrado',
  'Alvos de Técnica e de efeito',
  '1',
);
export const SkillLearnMethodsController = namedResource(
  'skill-learn-methods',
  'skillLearnMethod',
  'Métodos de aprendizado',
  'Método de aprendizado não encontrado',
  'Métodos de aprendizado (por nível, ao ascender, ensinável)',
  'level_up',
);
export const EffectTypesController = namedResource(
  'effect-types',
  'effectType',
  'Tipos de efeito',
  'Tipo de efeito não encontrado',
  'Tipos de efeito de Técnica',
  'modify_stat',
);
export const EvolutionTriggersController = namedResource(
  'evolution-triggers',
  'evolutionTrigger',
  'Gatilhos de Ascensão',
  'Gatilho de Ascensão não encontrado',
  'Gatilhos de Ascensão (nível, item, Vínculo…)',
  'level',
);
