import { calculateStats } from './stat-calculator.js';
import { STAT_SLUGS, StatBlock, TemperamentEffect } from './types.js';
import { totalXpForLevel } from './xp-curve.js';

const MAX_GENE = 31;
const MAX_SKILLS = 4;
const START_BOND = 70;
export const HIDDEN_TRAIT_CHANCE = 1 / 20;

export interface LearnsetEntry {
  skillId: number;
  method: string;
  level: number | null;
}

export interface CreateCreatureParams {
  species: { id: number; genderRatio: number; baseStats: StatBlock };
  level: number;
  learnset: LearnsetEntry[];
  maxPpBySkill: ReadonlyMap<number, number>;
  traitIds: number[];
  hiddenTraitId?: number | null;
  temperaments: (TemperamentEffect & { id: number })[];
  xpMultiplier: number;
}

export interface NewCreature {
  speciesId: number;
  level: number;
  genes: StatBlock;
  trainingPoints: StatBlock;
  temperamentId: number;
  traitId: number;
  gender: 'male' | 'female' | 'none';
  skills: { skillId: number; slot: number; currentPp: number }[];
  currentXp: number;
  stats: StatBlock;
  currentHp: number;
  bond: number;
  isPrismatic: boolean;
}

/**
 * Cria uma criatura nova (.specs/auth-google/02-player-rules.md, RF-03).
 * `random` devolve um número em [0, 1): em produção vem do `crypto.randomInt`;
 * nos testes, de uma sequência fixa. A ordem dos sorteios é: Genes (na ordem de
 * STAT_SLUGS), Temperamento, chance do Traço oculto (só se a espécie tem um),
 * Traço normal (só sem o oculto) e gênero.
 */
export function createCreature(
  params: CreateCreatureParams,
  random: () => number,
): NewCreature {
  const { species, level, temperaments, traitIds } = params;
  if (temperaments.length === 0) {
    throw new Error('Nenhum Temperamento no catálogo.');
  }
  if (traitIds.length === 0) {
    throw new Error(`A espécie ${species.id} não tem Traço normal.`);
  }

  const genes = {} as StatBlock;
  const trainingPoints = {} as StatBlock;
  for (const slug of STAT_SLUGS) {
    genes[slug] = pickInt(MAX_GENE + 1, random);
    trainingPoints[slug] = 0;
  }
  const temperament = temperaments[pickInt(temperaments.length, random)]!;
  const traitId = pickTrait(traitIds, params.hiddenTraitId ?? null, random);
  const gender = pickGender(species.genderRatio, random);
  const stats = calculateStats(
    species.baseStats,
    genes,
    trainingPoints,
    level,
    temperament,
  );

  return {
    speciesId: species.id,
    level,
    genes,
    trainingPoints,
    temperamentId: temperament.id,
    traitId,
    gender,
    skills: startingSkills(params),
    currentXp: totalXpForLevel(params.xpMultiplier, level),
    stats,
    currentHp: stats.hp,
    bond: START_BOND,
    isPrismatic: false,
  };
}

function pickTrait(
  traitIds: number[],
  hiddenTraitId: number | null,
  random: () => number,
): number {
  if (hiddenTraitId !== null && random() < HIDDEN_TRAIT_CHANCE) {
    return hiddenTraitId;
  }
  return traitIds[pickInt(traitIds.length, random)]!;
}

function pickInt(count: number, random: () => number): number {
  return Math.floor(random() * count);
}

function pickGender(
  genderRatio: number,
  random: () => number,
): NewCreature['gender'] {
  if (genderRatio < 0) return 'none';
  return random() < genderRatio ? 'male' : 'female';
}

function startingSkills({
  learnset,
  level,
  maxPpBySkill,
}: CreateCreatureParams): NewCreature['skills'] {
  return learnset
    .filter(
      (entry) =>
        entry.method === 'level_up' &&
        entry.level !== null &&
        entry.level <= level,
    )
    .slice(-MAX_SKILLS)
    .map(({ skillId }, index) => {
      const currentPp = maxPpBySkill.get(skillId);
      if (currentPp === undefined) {
        throw new Error(`A Técnica ${skillId} não tem PP conhecido.`);
      }
      return { skillId, slot: index + 1, currentPp };
    });
}
