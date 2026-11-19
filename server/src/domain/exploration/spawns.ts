import type { Random } from '../battle/types.js';
import { MAX_LEVEL } from '../rules/xp-curve.js';
import type { HexCoord } from './hex.js';
import { BIOMES, type Biome, type MapTile } from './map-generator.js';
import { DEFAULT_SPAWN_CONFIG, SpawnConfig } from './spawn-config.js';

const MIN_LEVEL = 1;
const BASE_NATURAL_LEVEL = 1;

export const ENCOUNTER_BIOMES = BIOMES;
export type EncounterBiome = Biome;

export interface EvolutionLevel {
  speciesId: number;
  evolvedSpeciesId: number;
  minLevel: number | null;
}

export interface SpawnSpecies {
  speciesId: number;
  naturalLevel: number;
  rates: Partial<Record<EncounterBiome, number>>;
  /** O multiplicador da taxa por slug de zona, em %; sem a zona, 100 (biome-zones/01). */
  zoneRates?: Partial<Record<string, number>>;
}

export interface MapSpawn extends HexCoord {
  id: number;
  speciesId: number;
  level: number;
  debug?: boolean;
}

interface WeightedSpecies {
  species: SpawnSpecies;
  weight: number;
}

interface BiomeRoll {
  tiles: MapTile[];
  candidates: WeightedSpecies[];
  weight: number;
}

/**
 * O nível em que a espécie é comum na natureza. Sem nível mínimo, como na
 * Evolução por Vínculo, ele sai da espécie anterior. A volta é limitada porque
 * as evoluções se editam no painel, e um ciclo não pode travar o servidor.
 */
export function naturalLevel(
  speciesId: number,
  evolutions: EvolutionLevel[],
  config: SpawnConfig,
): number {
  let current = speciesId;
  let gap = 0;
  for (let step = 0; step < evolutions.length; step++) {
    const evolution = evolutions.find(
      ({ evolvedSpeciesId }) => evolvedSpeciesId === current,
    );
    if (!evolution) break;
    if (evolution.minLevel !== null) return evolution.minLevel + gap;
    current = evolution.speciesId;
    gap += config.unleveledEvolutionGap;
  }
  return BASE_NATURAL_LEVEL + gap;
}

export function spawnWeight(
  rate: number,
  natural: number,
  teamAverage: number,
  config: SpawnConfig,
): number {
  if (teamAverage >= natural) return rate;
  return rate * config.missingLevelFactor ** (natural - teamAverage);
}

export function wildLevel(
  natural: number,
  teamAverage: number,
  config: SpawnConfig,
  random: Random,
): number {
  const pull = teamAverage < natural ? config.pullBelow : config.pullAbove;
  const center = Math.round(natural + (teamAverage - natural) * pull);
  const offset = Math.floor(random() * (config.levelSpread * 2 + 1));
  const level = center - config.levelSpread + offset;
  return Math.min(MAX_LEVEL, Math.max(MIN_LEVEL, level));
}

/** Só os Ecobeasts que nascem na parte do dia, cujos ids estão em `born`. */
export function bornIn<T extends { speciesId: number }>(
  items: readonly T[],
  born: ReadonlySet<number>,
): T[] {
  return items.filter(({ speciesId }) => born.has(speciesId));
}

export function pickWeighted<T extends { weight: number }>(
  items: T[],
  random: Random,
): T {
  const total = items.reduce((sum, { weight }) => sum + weight, 0);
  let roll = random() * total;
  for (const item of items) {
    roll -= item.weight;
    if (roll < 0) return item;
  }
  return items.at(-1)!;
}

function biomeRolls(
  tiles: MapTile[],
  species: SpawnSpecies[],
  teamAverage: number,
  config: SpawnConfig,
): BiomeRoll[] {
  const byZone = new Map<string, MapTile[]>();
  for (const tile of tiles) {
    const zone = tile.zone ?? tile.biome;
    const group = byZone.get(zone);
    if (group) group.push(tile);
    else byZone.set(zone, [tile]);
  }
  return [...byZone].flatMap(([zone, zoneTiles]) => {
    const biome = zoneTiles[0]!.biome;
    const candidates = species
      .map((entry) => ({
        species: entry,
        weight: spawnWeight(
          ((entry.rates[biome] ?? 0) * (entry.zoneRates?.[zone] ?? 100)) / 100,
          entry.naturalLevel,
          teamAverage,
          config,
        ),
      }))
      .filter(({ weight }) => weight > 0);
    const total = candidates.reduce((sum, { weight }) => sum + weight, 0);
    return total > 0
      ? [{ tiles: zoneTiles, candidates, weight: zoneTiles.length * total }]
      : [];
  });
}

export function rollSpawns(
  tiles: MapTile[],
  species: SpawnSpecies[],
  teamAverage: number,
  random: Random,
  config: SpawnConfig = DEFAULT_SPAWN_CONFIG,
): MapSpawn[] {
  const rolls = biomeRolls(tiles, species, teamAverage, config);
  if (rolls.length === 0) return [];
  return Array.from({ length: config.count }, (_, index) => {
    const biome = pickWeighted(rolls, random);
    const { species: chosen } = pickWeighted(biome.candidates, random);
    const tile = biome.tiles[Math.floor(random() * biome.tiles.length)]!;
    return {
      id: index + 1,
      speciesId: chosen.speciesId,
      level: wildLevel(chosen.naturalLevel, teamAverage, config, random),
      q: tile.q,
      r: tile.r,
    };
  });
}
