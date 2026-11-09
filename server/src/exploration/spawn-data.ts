import { DEFAULT_SPAWN_CONFIG } from '../domain/exploration/spawn-config.js';
import {
  type EncounterBiome,
  naturalLevel,
  type SpawnSpecies,
} from '../domain/exploration/spawns.js';
import type { TamerTexts } from '../domain/tamers/tamers.js';
import type { PrismaService } from '../prisma/prisma.service.js';

/**
 * O que os sorteios de Ecobeasts e de Domadores leem do banco: a exploração
 * (biome-encounters/03) e o Desafiar (npc-tamers/03) usam as mesmas leituras.
 */

/** As espécies com taxa em algum bioma, com o nível natural de cada uma. */
export async function loadSpawnSpecies(
  prisma: PrismaService,
): Promise<SpawnSpecies[]> {
  const [rows, evolutions] = await Promise.all([
    prisma.speciesBiome.findMany({ include: { biome: true } }),
    prisma.evolution.findMany({
      select: { speciesId: true, evolvedSpeciesId: true, minLevel: true },
    }),
  ]);
  const bySpecies = new Map<number, SpawnSpecies>();
  for (const { speciesId, biome, rate } of rows) {
    const species = bySpecies.get(speciesId) ?? {
      speciesId,
      naturalLevel: naturalLevel(speciesId, evolutions, DEFAULT_SPAWN_CONFIG),
      rates: {},
    };
    species.rates[biome.slug as EncounterBiome] = rate;
    bySpecies.set(speciesId, species);
  }
  return [...bySpecies.values()];
}

/** Os ids dos nomes e das falas que um Domador NPC pode receber. */
export async function loadTamerTexts(
  prisma: PrismaService,
): Promise<TamerTexts> {
  const [names, greetings] = await Promise.all([
    prisma.npcTamerName.findMany({ select: { id: true } }),
    prisma.npcTamerGreeting.findMany({ select: { id: true } }),
  ]);
  return {
    nameIds: names.map(({ id }) => id),
    greetingIds: greetings.map(({ id }) => id),
  };
}

/** A média de nível da equipe principal, sem arredondar; nula sem equipe. */
export async function partyAverageLevel(
  prisma: PrismaService,
  userId: string,
): Promise<number | null> {
  const team = await prisma.creatureInstance.findMany({
    where: { playerId: userId, location: 'party' },
    select: { level: true },
  });
  if (team.length === 0) return null;
  return team.reduce((sum, { level }) => sum + level, 0) / team.length;
}
