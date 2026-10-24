import { ApiProperty } from '@nestjs/swagger';
import { ref, ResourceRef } from '../../common/resource-ref.js';
import type {
  Species,
  SpeciesTrait,
  Trait,
} from '../../generated/prisma/client.js';
import { resourceController } from '../resource-controller.js';

export class TraitSpeciesDto {
  @ApiProperty({ type: () => ResourceRef })
  species: ResourceRef;

  @ApiProperty({ description: '1 e 2 são normais; 3 é o oculto.', example: 1 })
  slot: number;

  @ApiProperty({ example: false })
  is_hidden: boolean;
}

export class TraitDetailDto {
  @ApiProperty({ example: 1 })
  id: number;

  @ApiProperty({ example: 'blazing_fury' })
  slug: string;

  @ApiProperty({ example: 'Fúria Ardente' })
  name: string;

  @ApiProperty({
    example: 'Técnicas de Fogo causam 50% a mais com o HP em 1/3 ou menos.',
  })
  description: string;

  @ApiProperty({
    type: () => [TraitSpeciesDto],
    description: 'Espécies que podem ter este Traço.',
  })
  species: TraitSpeciesDto[];
}

type TraitRow = Trait & { species: (SpeciesTrait & { species: Species })[] };

export const TraitsController = resourceController<TraitRow, TraitDetailDto>({
  path: 'traits',
  model: 'trait',
  tag: 'Traços',
  notFound: 'Traço não encontrado',
  list: {
    summary: 'Lista os Traços',
    description: 'Os Traços em ordem de id, paginados.',
  },
  detail: {
    summary: 'Um Traço',
    description:
      'A descrição e as espécies que podem ter o Traço (normal ou oculto).',
    example: '1',
  },
  dto: TraitDetailDto,
  include: {
    species: {
      include: { species: true },
      orderBy: [{ speciesId: 'asc' }, { slot: 'asc' }],
    },
  },
  toDto: (trait) => ({
    id: trait.id,
    slug: trait.slug,
    name: trait.name,
    description: trait.description,
    species: trait.species.map((row) => ({
      species: ref('species', row.species),
      slot: row.slot,
      is_hidden: row.isHidden,
    })),
  }),
});
