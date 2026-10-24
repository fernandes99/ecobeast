import { ApiProperty } from '@nestjs/swagger';
import { ref, ResourceRef } from '../../common/resource-ref.js';
import type {
  EffectType,
  Element,
  Skill,
  SkillCategory,
  SkillEffect,
  SkillTarget,
  Stat,
  StatusCondition,
} from '../../generated/prisma/client.js';
import { resourceController } from '../resource-controller.js';

export class SkillEffectDto {
  @ApiProperty({ description: 'Ordem em que o efeito acontece.', example: 1 })
  sort_order: number;

  @ApiProperty({
    example: {
      id: 2,
      slug: 'modify_stat',
      name: 'Alterar atributo',
      url: '/v1/effect-types/2',
    },
  })
  effect_type: ResourceRef;

  @ApiProperty({
    description: 'Chance, em %, de o efeito acontecer.',
    example: 100,
  })
  chance: number;

  @ApiProperty({
    type: () => ResourceRef,
    nullable: true,
    description: 'Em quem o efeito age.',
  })
  target: ResourceRef | null;

  @ApiProperty({ type: () => ResourceRef, nullable: true })
  status_condition: ResourceRef | null;

  @ApiProperty({ type: () => ResourceRef, nullable: true })
  stat: ResourceRef | null;

  @ApiProperty({
    nullable: true,
    type: Number,
    description: 'Estágios de stat, de −6 a +6.',
    example: -1,
  })
  stages: number | null;

  @ApiProperty({
    nullable: true,
    type: Number,
    description: 'Porcentagem (cura, dreno, recuo).',
    example: null,
  })
  percent: number | null;

  @ApiProperty({
    nullable: true,
    type: Number,
    description: 'Dano fixo.',
    example: null,
  })
  value: number | null;

  @ApiProperty({
    nullable: true,
    type: Number,
    description: 'Clima (tabela futura).',
    example: null,
  })
  weather_id: number | null;

  @ApiProperty({ nullable: true, type: Number, example: null })
  min_turns: number | null;
}

export class SkillDetailDto {
  @ApiProperty({ example: 1 })
  id: number;

  @ApiProperty({ example: 'arranhao' })
  slug: string;

  @ApiProperty({ example: 'Arranhão' })
  name: string;

  @ApiProperty({ example: 'Arranha o alvo com garras afiadas.' })
  description: string;

  @ApiProperty({ type: () => ResourceRef })
  element: ResourceRef;

  @ApiProperty({
    example: {
      id: 1,
      slug: 'physical',
      name: 'Física',
      url: '/v1/skill-categories/1',
    },
  })
  category: ResourceRef;

  @ApiProperty({ type: () => ResourceRef })
  target: ResourceRef;

  @ApiProperty({ example: 40 })
  power: number;

  @ApiProperty({ description: 'Precisão, de 0 a 100.', example: 100 })
  accuracy: number;

  @ApiProperty({ example: 35 })
  max_pp: number;

  @ApiProperty({
    description: 'Quem tem prioridade maior age primeiro.',
    example: 0,
  })
  priority: number;

  @ApiProperty({ description: 'Estágio de crítico, de 0 a 3.', example: 0 })
  crit_stage: number;

  @ApiProperty({ example: true })
  makes_contact: boolean;

  @ApiProperty({ example: 1 })
  min_hits: number;

  @ApiProperty({ example: 1 })
  max_hits: number;

  @ApiProperty({ type: () => [SkillEffectDto] })
  effects: SkillEffectDto[];
}

type EffectRow = SkillEffect & {
  effectType: EffectType;
  skillTarget: SkillTarget | null;
  statusCondition: StatusCondition | null;
  stat: Stat | null;
};
type SkillRow = Skill & {
  element: Element;
  skillCategory: SkillCategory;
  skillTarget: SkillTarget;
  effects: EffectRow[];
};

export const SkillsController = resourceController<SkillRow, SkillDetailDto>({
  path: 'skills',
  model: 'skill',
  tag: 'Técnicas',
  notFound: 'Técnica não encontrada',
  list: {
    summary: 'Lista as Técnicas',
    description: 'As Técnicas em ordem de id, paginadas.',
  },
  detail: {
    summary: 'Uma Técnica',
    description:
      'Elemento, categoria, alvo, poder, precisão, PP, prioridade e os efeitos, em ordem.',
    example: 'arranhao',
  },
  dto: SkillDetailDto,
  include: {
    element: true,
    skillCategory: true,
    skillTarget: true,
    effects: {
      include: {
        effectType: true,
        skillTarget: true,
        statusCondition: true,
        stat: true,
      },
      orderBy: { sortOrder: 'asc' },
    },
  },
  toDto: (skill) => ({
    id: skill.id,
    slug: skill.slug,
    name: skill.name,
    description: skill.description,
    element: ref('elements', skill.element),
    category: ref('skill-categories', skill.skillCategory),
    target: ref('skill-targets', skill.skillTarget),
    power: skill.power,
    accuracy: skill.accuracy,
    max_pp: skill.maxPp,
    priority: skill.priority,
    crit_stage: skill.critStage,
    makes_contact: skill.makesContact,
    min_hits: skill.minHits,
    max_hits: skill.maxHits,
    effects: skill.effects.map((effect) => ({
      sort_order: effect.sortOrder,
      effect_type: ref('effect-types', effect.effectType),
      chance: effect.chance,
      target: effect.skillTarget
        ? ref('skill-targets', effect.skillTarget)
        : null,
      status_condition: effect.statusCondition
        ? ref('status-conditions', effect.statusCondition)
        : null,
      stat: effect.stat ? ref('stats', effect.stat) : null,
      stages: effect.stages,
      percent: effect.percent,
      value: effect.value,
      weather_id: effect.weatherId,
      min_turns: effect.minTurns,
    })),
  }),
});
