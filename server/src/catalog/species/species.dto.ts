import { ApiProperty } from '@nestjs/swagger';
import { ResourceRef } from '../../common/resource-ref.js';

// Formatos das respostas de espécies (.specs/backend-api/04-species-api.md,
// RF-07 a RF-09). Campos em snake_case, como a PokeAPI.

export class SpeciesElementDto {
  @ApiProperty({ example: 1 })
  slot: number;

  @ApiProperty({
    example: { id: 1, slug: 'fire', name: 'Fogo', url: '/v1/elements/1' },
  })
  element: ResourceRef;
}

export class SpeciesStatDto {
  @ApiProperty({
    example: { id: 1, slug: 'hp', name: 'HP', url: '/v1/stats/1' },
  })
  stat: ResourceRef;

  @ApiProperty({ description: 'Valor base do stat.', example: 39 })
  base_value: number;

  @ApiProperty({
    description: 'Treino que a espécie dá ao ser derrotada.',
    example: 0,
  })
  training_yield: number;
}

export class SpeciesTraitDto {
  @ApiProperty({ description: '1 e 2 são normais; 3 é o oculto.', example: 1 })
  slot: number;

  @ApiProperty({ example: false })
  is_hidden: boolean;

  @ApiProperty({ type: () => ResourceRef })
  trait: ResourceRef;
}

export class SpeciesDetailDto {
  @ApiProperty({ description: 'Número no Bestiário.', example: 1 })
  id: number;

  @ApiProperty({ example: 'fagulho' })
  slug: string;

  @ApiProperty({ example: 'Fagulho' })
  name: string;

  @ApiProperty({ example: 'Filhote de lobo com brasas no pelo.' })
  description: string;

  @ApiProperty({ example: 0.5 })
  height_m: number;

  @ApiProperty({ example: 9 })
  weight_kg: number;

  @ApiProperty({
    description: 'Chance de ser macho (0 a 1); −1 = sem gênero.',
    example: 0.5,
  })
  gender_ratio: number;

  @ApiProperty({
    description: '3 a 255; maior é mais fácil de capturar.',
    example: 45,
  })
  capture_rate: number;

  @ApiProperty({ description: 'XP base que dá ao ser derrotada.', example: 62 })
  base_xp_yield: number;

  @ApiProperty({
    example: {
      id: 2,
      slug: 'medium',
      name: 'Médio',
      url: '/v1/growth-rates/2',
    },
  })
  growth_rate: ResourceRef;

  @ApiProperty({ type: () => ResourceRef })
  rarity: ResourceRef;

  @ApiProperty({
    type: () => ResourceRef,
    nullable: true,
    description: 'De quem ascende; null na primeira forma.',
  })
  evolves_from: ResourceRef | null;

  @ApiProperty({ type: () => [SpeciesElementDto] })
  elements: SpeciesElementDto[];

  @ApiProperty({ type: () => [SpeciesStatDto] })
  stats: SpeciesStatDto[];

  @ApiProperty({ type: () => [SpeciesTraitDto] })
  traits: SpeciesTraitDto[];
}

export class SpeciesSkillEntryDto {
  @ApiProperty({ type: () => ResourceRef })
  skill: ResourceRef;

  @ApiProperty({
    example: {
      id: 1,
      slug: 'level_up',
      name: 'Por nível',
      url: '/v1/skill-learn-methods/1',
    },
  })
  learn_method: ResourceRef;

  @ApiProperty({
    description: 'Nível em que aprende; 0 = ao ascender; null = ensinável.',
    example: 1,
    nullable: true,
    type: Number,
  })
  level: number | null;
}

export class SpeciesSkillsDto {
  @ApiProperty({ type: () => ResourceRef })
  species: ResourceRef;

  @ApiProperty({ type: () => [SpeciesSkillEntryDto] })
  skills: SpeciesSkillEntryDto[];
}

// EvolutionNodeDto vem antes: o metadado de tipo do campo "node" em EvolutionStepDto
// precisa da classe já definida (a lista em evolves_to não precisa).
export class EvolutionNodeDto {
  @ApiProperty({ type: () => ResourceRef })
  species: ResourceRef;

  @ApiProperty({ type: () => [EvolutionStepDto] })
  evolves_to: EvolutionStepDto[];
}

export class EvolutionStepDto {
  @ApiProperty({
    example: {
      id: 1,
      slug: 'level',
      name: 'Nível',
      url: '/v1/evolution-triggers/1',
    },
  })
  trigger: ResourceRef;

  @ApiProperty({ nullable: true, type: Number, example: 16 })
  min_level: number | null;

  @ApiProperty({ nullable: true, type: Number, example: null })
  min_bond: number | null;

  @ApiProperty({
    nullable: true,
    type: String,
    example: null,
    description: '"day" ou "night".',
  })
  time_of_day: string | null;

  @ApiProperty({
    nullable: true,
    type: Number,
    example: null,
    description: 'Item (tabela futura).',
  })
  item_id: number | null;

  @ApiProperty({
    nullable: true,
    type: Number,
    example: null,
    description: 'Zona (tabela futura).',
  })
  zone_id: number | null;

  @ApiProperty({ type: () => EvolutionNodeDto })
  node: EvolutionNodeDto;
}

export class EvolutionChainDto {
  @ApiProperty({
    type: () => EvolutionNodeDto,
    description: 'A primeira forma da linha e, dentro dela, as Ascensões.',
  })
  chain: EvolutionNodeDto;
}
