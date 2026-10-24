import { ApiProperty } from '@nestjs/swagger';
import { ref, ResourceRef } from '../../common/resource-ref.js';
import type {
  Element,
  ElementEfficacy,
  StatusCondition,
  StatusConditionImmunity,
} from '../../generated/prisma/client.js';
import { resourceController } from '../resource-controller.js';

export class EfficacyEntryDto {
  @ApiProperty({
    example: { id: 3, slug: 'flora', name: 'Flora', url: '/v1/elements/3' },
  })
  element: ResourceRef;

  @ApiProperty({ description: '0 (imune), 0.5 ou 2.', example: 2 })
  multiplier: number;
}

export class ElementEfficacyDto {
  @ApiProperty({
    type: () => [EfficacyEntryDto],
    description: 'Dano deste Elemento contra os outros.',
  })
  attacking: EfficacyEntryDto[];

  @ApiProperty({
    type: () => [EfficacyEntryDto],
    description: 'Dano dos outros Elementos contra este.',
  })
  defending: EfficacyEntryDto[];
}

export class ElementDetailDto {
  @ApiProperty({ example: 1 })
  id: number;

  @ApiProperty({ example: 'fire' })
  slug: string;

  @ApiProperty({ example: 'Fogo' })
  name: string;

  @ApiProperty({ example: '#E25822' })
  color_hex: string;

  @ApiProperty({
    description: 'Elemento raro (aparece pouco).',
    example: false,
  })
  is_rare: boolean;

  @ApiProperty({
    type: () => ElementEfficacyDto,
    description:
      'Só os multiplicadores diferentes de 1; o que não aparece vale 1.',
  })
  efficacy: ElementEfficacyDto;

  @ApiProperty({
    type: () => [ResourceRef],
    description: 'Status que não pegam neste Elemento.',
  })
  immune_to_status: ResourceRef[];
}

type ElementRow = Element & {
  attacking: (ElementEfficacy & { defender: Element })[];
  defending: (ElementEfficacy & { attacker: Element })[];
  statusImmunities: (StatusConditionImmunity & {
    statusCondition: StatusCondition;
  })[];
};

export const ElementsController = resourceController<
  ElementRow,
  ElementDetailDto
>({
  path: 'elements',
  model: 'element',
  tag: 'Elementos',
  notFound: 'Elemento não encontrado',
  list: {
    summary: 'Lista os Elementos',
    description: 'Os Elementos em ordem de id, paginados.',
  },
  detail: {
    summary: 'Um Elemento',
    description:
      'Cor, raridade, a efetividade como atacante e como defensor e os status a que é imune.',
    example: 'fire',
  },
  dto: ElementDetailDto,
  include: {
    attacking: {
      include: { defender: true },
      orderBy: { defenderElementId: 'asc' },
    },
    defending: {
      include: { attacker: true },
      orderBy: { attackerElementId: 'asc' },
    },
    statusImmunities: {
      include: { statusCondition: true },
      orderBy: { statusConditionId: 'asc' },
    },
  },
  toDto: (element) => ({
    id: element.id,
    slug: element.slug,
    name: element.name,
    color_hex: element.colorHex,
    is_rare: element.isRare,
    efficacy: {
      attacking: element.attacking.map((row) => ({
        element: ref('elements', row.defender),
        multiplier: row.multiplier,
      })),
      defending: element.defending.map((row) => ({
        element: ref('elements', row.attacker),
        multiplier: row.multiplier,
      })),
    },
    immune_to_status: element.statusImmunities.map((row) =>
      ref('status-conditions', row.statusCondition),
    ),
  }),
});
