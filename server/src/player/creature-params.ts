import { CreateCreatureParams } from '../domain/rules/creature-factory.js';
import { StatSlug } from '../domain/rules/types.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { toStatBlock } from './player.mapper.js';

export interface CreatureBlueprint {
  params: CreateCreatureParams;
  statIds: Record<StatSlug, number>;
  /** Na ordem dos slots da espécie. */
  elementIds: number[];
  traitSlugs: ReadonlyMap<number, string>;
}

/** O que as regras precisam do catálogo para criar uma criatura; nulo sem a espécie. */
export async function loadCreatureBlueprint(
  prisma: PrismaService,
  speciesId: number,
  level: number,
): Promise<CreatureBlueprint | null> {
  const [species, temperaments] = await Promise.all([
    prisma.species.findUnique({
      where: { id: speciesId },
      include: {
        growthRate: true,
        elements: { orderBy: { slot: 'asc' } },
        stats: { include: { stat: true } },
        traits: {
          where: { isHidden: false },
          orderBy: { slot: 'asc' },
          include: { trait: true },
        },
        skills: {
          // Mesma ordem do catálogo que o cliente lê.
          orderBy: [{ level: 'asc' }, { skillId: 'asc' }],
          include: { skill: true, skillLearnMethod: true },
        },
      },
    }),
    prisma.temperament.findMany({
      orderBy: { id: 'asc' },
      include: { increasedStat: true, decreasedStat: true },
    }),
  ]);
  if (!species) return null;

  return {
    statIds: toStatBlock(species.stats, (row) => row.statId),
    elementIds: species.elements.map((row) => row.elementId),
    traitSlugs: new Map(
      species.traits.map((row) => [row.traitId, row.trait.slug]),
    ),
    params: {
      species: {
        id: species.id,
        genderRatio: species.genderRatio,
        baseStats: toStatBlock(species.stats, (row) => row.baseValue),
      },
      level,
      learnset: species.skills.map((row) => ({
        skillId: row.skillId,
        method: row.skillLearnMethod.slug,
        level: row.level,
      })),
      maxPpBySkill: new Map(
        species.skills.map((row) => [row.skillId, row.skill.maxPp]),
      ),
      traitIds: species.traits.map((row) => row.traitId),
      temperaments: temperaments.map((row) => ({
        id: row.id,
        increasedStat: row.increasedStat.slug as StatSlug,
        decreasedStat: row.decreasedStat.slug as StatSlug,
      })),
      xpMultiplier: species.growthRate.xpMultiplier,
    },
  };
}
