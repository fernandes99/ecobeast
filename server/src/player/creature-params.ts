import {
  CreateCreatureParams,
  NewCreature,
} from '../domain/rules/creature-factory.js';
import { STAT_SLUGS, StatSlug } from '../domain/rules/types.js';
import { Prisma } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { toStatBlock } from './player.mapper.js';

export interface CreatureBlueprint {
  params: CreateCreatureParams;
  statIds: Record<StatSlug, number>;
  /** Na ordem dos slots da espécie. */
  elementIds: number[];
  traitSlugs: ReadonlyMap<number, string>;
}

export type CreaturePlace =
  | { location: 'party'; partySlot: number }
  | { location: 'storage'; partySlot: null };

/** A linha de uma criatura nova do jogador, com Genes, Treino e Técnicas. */
export function newCreatureData(
  playerId: string,
  creature: NewCreature,
  statIds: Record<StatSlug, number>,
  place: CreaturePlace,
) {
  return {
    playerId,
    speciesId: creature.speciesId,
    level: creature.level,
    currentXp: creature.currentXp,
    currentHp: creature.currentHp,
    temperamentId: creature.temperamentId,
    traitId: creature.traitId,
    gender: creature.gender,
    isPrismatic: creature.isPrismatic,
    bond: creature.bond,
    ...place,
    originalPlayerId: playerId,
    caughtAt: new Date(),
    stats: {
      create: STAT_SLUGS.map((slug) => ({
        statId: statIds[slug],
        genes: creature.genes[slug],
        trainingPoints: creature.trainingPoints[slug],
      })),
    },
    skills: { create: creature.skills },
  } satisfies Prisma.CreatureInstanceUncheckedCreateInput;
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
        // Os normais e o oculto: a chance de nascer com o oculto (hidden-traits/01).
        traits: {
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
      traitIds: species.traits
        .filter((row) => !row.isHidden)
        .map((row) => row.traitId),
      hiddenTraitId:
        species.traits.find((row) => row.isHidden)?.traitId ?? null,
      temperaments: temperaments.map((row) => ({
        id: row.id,
        increasedStat: row.increasedStat.slug as StatSlug,
        decreasedStat: row.decreasedStat.slug as StatSlug,
      })),
      xpMultiplier: species.growthRate.xpMultiplier,
    },
  };
}
