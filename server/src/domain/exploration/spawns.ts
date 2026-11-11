import type { Random } from '../battle/types.js';
import { MAX_LEVEL } from '../rules/xp-curve.js';
import type { HexCoord } from './hex.js';
import { BIOMES, type Biome, type MapTile } from './map-generator.js';
import { DEFAULT_SPAWN_CONFIG, SpawnConfig } from './spawn-config.js';

const MIN_LEVEL = 1;
/** A base de uma linha, que não vem de nenhuma evolução. */
const BASE_NATURAL_LEVEL = 1;

/** O bioma de encontro é o próprio bioma do hexágono (terrain-height). */
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
}

/** Um Ecobeast no mapa. O resto dele é sorteado quando a luta começa. */
export interface MapSpawn extends HexCoord {
  id: number;
  speciesId: number;
  level: number;
  /** Posto pelo spawn de depuração (biome-encounters/05), e não pelo sorteio. */
  debug?: boolean;
}

interface WeightedSpecies {
  species: SpawnSpecies;
  weight: number;
}

/** O que o sorteio precisa saber de um bioma que pode receber Ecobeasts. */
interface BiomeRoll {
  tiles: MapTile[];
  candidates: WeightedSpecies[];
  /** Hexágonos do bioma × soma dos pesos: a chance dele levar a vaga. */
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

/** A taxa, reduzida a cada nível que falta ao time para o nível natural. */
export function spawnWeight(
  rate: number,
  natural: number,
  teamAverage: number,
  config: SpawnConfig,
): number {
  if (teamAverage >= natural) return rate;
  return rate * config.missingLevelFactor ** (natural - teamAverage);
}

/** Parte do nível natural e é puxado pela média do time. */
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

/** Um sorteio por peso. Com um arredondamento azarado, fica com o último, que também tem peso. */
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
  const byBiome = new Map<EncounterBiome, MapTile[]>();
  for (const tile of tiles) {
    const biome = tile.biome;
    const group = byBiome.get(biome);
    if (group) group.push(tile);
    else byBiome.set(biome, [tile]);
  }
  return [...byBiome].flatMap(([biome, biomeTiles]) => {
    const candidates = species
      .map((entry) => ({
        species: entry,
        weight: spawnWeight(
          entry.rates[biome] ?? 0,
          entry.naturalLevel,
          teamAverage,
          config,
        ),
      }))
      .filter(({ weight }) => weight > 0);
    const total = candidates.reduce((sum, { weight }) => sum + weight, 0);
    return total > 0
      ? [{ tiles: biomeTiles, candidates, weight: biomeTiles.length * total }]
      : [];
  });
}

/** Os Ecobeasts de um mapa (.specs/biome-encounters/architecture.md, "Sorteio do mapa"). */
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
