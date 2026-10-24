import { Injectable } from '@nestjs/common';
import { notFound, parseIdOrSlug } from '../../common/id-or-slug.js';
import { page, Page, PaginationQueryDto } from '../../common/pagination.js';
import { ref, ResourceRef } from '../../common/resource-ref.js';
import { PrismaService } from '../../prisma/prisma.service.js';
import {
  EvolutionChainDto,
  EvolutionNodeDto,
  SpeciesDetailDto,
  SpeciesSkillsDto,
} from './species.dto.js';

const NOT_FOUND = 'Espécie não encontrada';
const NAME = { id: true, slug: true, name: true } as const;

@Injectable()
export class SpeciesService {
  constructor(private readonly prisma: PrismaService) {}

  async list(query: PaginationQueryDto): Promise<Page<ResourceRef>> {
    const [total, rows] = await Promise.all([
      this.prisma.species.count(),
      this.prisma.species.findMany({
        select: NAME,
        orderBy: { id: 'asc' },
        skip: query.offset,
        take: query.limit,
      }),
    ]);
    return page(
      '/v1/species',
      total,
      query,
      rows.map((row) => ref('species', row)),
    );
  }

  async detail(param: string): Promise<SpeciesDetailDto> {
    const species = await this.prisma.species.findUnique({
      where: parseIdOrSlug(param) as { id: number } & { slug: string },
      include: {
        growthRate: true,
        rarity: true,
        evolvesFrom: true,
        elements: { include: { element: true }, orderBy: { slot: 'asc' } },
        stats: { include: { stat: true }, orderBy: { statId: 'asc' } },
        traits: { include: { trait: true }, orderBy: { slot: 'asc' } },
      },
    });
    if (!species) throw notFound(NOT_FOUND, param);
    return {
      id: species.id,
      slug: species.slug,
      name: species.name,
      description: species.description,
      height_m: species.heightM,
      weight_kg: species.weightKg,
      gender_ratio: species.genderRatio,
      capture_rate: species.captureRate,
      base_xp_yield: species.baseXpYield,
      growth_rate: ref('growth-rates', species.growthRate),
      rarity: ref('rarities', species.rarity),
      evolves_from: species.evolvesFrom
        ? ref('species', species.evolvesFrom)
        : null,
      elements: species.elements.map((row) => ({
        slot: row.slot,
        element: ref('elements', row.element),
      })),
      stats: species.stats.map((row) => ({
        stat: ref('stats', row.stat),
        base_value: row.baseValue,
        training_yield: row.trainingYield,
      })),
      traits: species.traits.map((row) => ({
        slot: row.slot,
        is_hidden: row.isHidden,
        trait: ref('traits', row.trait),
      })),
    };
  }

  async skills(param: string): Promise<SpeciesSkillsDto> {
    const species = await this.findName(param);
    const rows = await this.prisma.speciesSkill.findMany({
      where: { speciesId: species.id },
      include: { skill: true, skillLearnMethod: true },
      orderBy: [
        { skillLearnMethodId: 'asc' },
        { level: { sort: 'asc', nulls: 'last' } },
        { skillId: 'asc' },
      ],
    });
    return {
      species: ref('species', species),
      skills: rows.map((row) => ({
        skill: ref('skills', row.skill),
        learn_method: ref('skill-learn-methods', row.skillLearnMethod),
        level: row.level,
      })),
    };
  }

  /** A linha inteira, a partir da forma que não ascende de nenhuma outra (RF-09). */
  async evolutions(param: string): Promise<EvolutionChainDto> {
    let current = await this.findName(param);
    const seen = new Set<number>([current.id]);
    for (;;) {
      const parent = await this.prisma.species.findUnique({
        where: { id: current.id },
        select: { evolvesFrom: { select: NAME } },
      });
      if (!parent?.evolvesFrom || seen.has(parent.evolvesFrom.id)) break;
      current = parent.evolvesFrom;
      seen.add(current.id);
    }
    return { chain: await this.node(current, new Set()) };
  }

  private async node(
    species: { id: number; slug: string; name: string },
    visited: Set<number>,
  ): Promise<EvolutionNodeDto> {
    visited.add(species.id);
    const rules = await this.prisma.evolution.findMany({
      where: { speciesId: species.id },
      include: { evolutionTrigger: true, evolvedSpecies: { select: NAME } },
      orderBy: { id: 'asc' },
    });
    const evolvesTo = [];
    for (const rule of rules.filter((r) => !visited.has(r.evolvedSpeciesId))) {
      evolvesTo.push({
        trigger: ref('evolution-triggers', rule.evolutionTrigger),
        min_level: rule.minLevel,
        min_bond: rule.minBond,
        time_of_day: rule.timeOfDay,
        item_id: rule.itemId,
        zone_id: rule.zoneId,
        node: await this.node(rule.evolvedSpecies, visited),
      });
    }
    return { species: ref('species', species), evolves_to: evolvesTo };
  }

  private async findName(
    param: string,
  ): Promise<{ id: number; slug: string; name: string }> {
    const species = await this.prisma.species.findUnique({
      where: parseIdOrSlug(param) as { id: number } & { slug: string },
      select: NAME,
    });
    if (!species) throw notFound(NOT_FOUND, param);
    return species;
  }
}
