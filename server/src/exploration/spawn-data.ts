import type { Biome } from '../domain/exploration/map-generator.js';
import type { MapZone } from '../domain/exploration/map-zones.js';
import { DEFAULT_SPAWN_CONFIG } from '../domain/exploration/spawn-config.js';
import {
  type EncounterBiome,
  naturalLevel,
  type SpawnSpecies,
} from '../domain/exploration/spawns.js';
import type { TamerTexts } from '../domain/tamers/tamers.js';
import { dayPhaseAt } from '../domain/world-clock/world-clock.js';
import type { PrismaService } from '../prisma/prisma.service.js';

export async function loadSpawnSpecies(
  prisma: PrismaService,
): Promise<SpawnSpecies[]> {
  const [rows, evolutions, zoneRows] = await Promise.all([
    prisma.speciesBiome.findMany({ include: { biome: true } }),
    prisma.evolution.findMany({
      select: { speciesId: true, evolvedSpeciesId: true, minLevel: true },
    }),
    prisma.speciesBiomeZone.findMany({
      select: { speciesId: true, ratePercent: true, biomeZone: true },
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
  for (const { speciesId, ratePercent, biomeZone } of zoneRows) {
    const species = bySpecies.get(speciesId);
    if (!species) continue;
    species.zoneRates = { ...species.zoneRates, [biomeZone.slug]: ratePercent };
  }
  return [...bySpecies.values()];
}

export async function loadZones(prisma: PrismaService): Promise<MapZone[]> {
  const rows = await prisma.biomeZone.findMany({
    select: { slug: true, share: true, sortOrder: true, biome: true },
  });
  return rows.map(({ slug, share, sortOrder, biome }) => ({
    slug,
    biome: biome.slug as Biome,
    share,
    sortOrder,
  }));
}

/** Os ids dos Ecobeasts que nascem na parte do dia do `minute` (day-phase-spawns/01). */
export async function speciesBornAt(
  prisma: PrismaService,
  minute: number,
): Promise<ReadonlySet<number>> {
  const phases = await prisma.dayPhase.findMany({
    select: { id: true, startMinute: true },
  });
  if (phases.length === 0) return new Set();
  const rows = await prisma.speciesDayPhase.findMany({
    where: { dayPhaseId: dayPhaseAt(minute, phases).id },
    select: { speciesId: true },
  });
  return new Set(rows.map(({ speciesId }) => speciesId));
}

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
