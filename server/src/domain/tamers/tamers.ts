import type { Random } from '../battle/types.js';
import { type HexCoord, hexDistance } from '../exploration/hex.js';
import type { Biome, MapTile } from '../exploration/map-generator.js';
import {
  DEFAULT_SPAWN_CONFIG,
  type SpawnConfig,
} from '../exploration/spawn-config.js';
import {
  ENCOUNTER_BIOMES,
  type EncounterBiome,
  pickWeighted,
  spawnWeight,
  type SpawnSpecies,
  wildLevel,
} from '../exploration/spawns.js';
import {
  TAMER_CONFIG,
  type TamerConfig,
  type TamerSize,
} from './tamer-config.js';

const WATER: ReadonlySet<Biome> = new Set(['wshallow', 'wdeep']);
const SIZES: readonly TamerSize[] = [1, 2, 3];

export interface TamerTexts {
  nameIds: number[];
  greetingIds: number[];
}

export interface TamerCreature {
  speciesId: number;
  level: number;
}

/**
 * Um Domador sorteado (.specs/npc-tamers/architecture.md, "Domador sorteado").
 * A equipe nasce junto, para o Domador não mudar entre o mapa e a luta.
 */
export interface RolledTamer {
  id: number;
  nameId: number;
  greetingId: number;
  size: TamerSize;
  team: TamerCreature[];
}

export interface MapTamer extends RolledTamer, HexCoord {
  debug?: boolean;
}

export interface TamerRollOptions {
  config?: TamerConfig;
  spawnConfig?: SpawnConfig;
}

interface WeightedSpecies {
  species: SpawnSpecies;
  weight: number;
}

function candidates(
  species: SpawnSpecies[],
  weightOf: (entry: SpawnSpecies) => number,
): WeightedSpecies[] {
  return species
    .map((entry) => ({ species: entry, weight: weightOf(entry) }))
    .filter(({ weight }) => weight > 0);
}

function pickId(ids: number[], random: Random): number {
  return ids[Math.floor(random() * ids.length)]!;
}

function pickSize(config: TamerConfig, random: Random): TamerSize {
  const sizes = SIZES.map((size) => ({
    size,
    weight: config.sizeWeights[size],
  })).filter(({ weight }) => weight > 0);
  return pickWeighted(sizes, random).size;
}

function hasTexts({ nameIds, greetingIds }: TamerTexts): boolean {
  return nameIds.length > 0 && greetingIds.length > 0;
}

/** O tamanho, a equipe, o nome e a fala, nesta ordem de sorteio. */
function rollTamer(
  id: number,
  pool: WeightedSpecies[],
  teamAverage: number,
  texts: TamerTexts,
  random: Random,
  config: TamerConfig,
  spawnConfig: SpawnConfig,
  size: TamerSize = pickSize(config, random),
): RolledTamer {
  const team = Array.from({ length: size }, () => {
    const { species } = pickWeighted(pool, random);
    return {
      speciesId: species.speciesId,
      level: wildLevel(species.naturalLevel, teamAverage, spawnConfig, random),
    };
  });
  return {
    id,
    nameId: pickId(texts.nameIds, random),
    greetingId: pickId(texts.greetingIds, random),
    size,
    team,
  };
}

export function rollMapTamers(
  tiles: MapTile[],
  start: HexCoord,
  species: SpawnSpecies[],
  teamAverage: number,
  texts: TamerTexts,
  random: Random,
  {
    config = TAMER_CONFIG,
    spawnConfig = DEFAULT_SPAWN_CONFIG,
  }: TamerRollOptions = {},
): MapTamer[] {
  if (!hasTexts(texts)) return [];
  const pools = new Map<EncounterBiome, WeightedSpecies[]>();
  const poolOf = (biome: EncounterBiome): WeightedSpecies[] => {
    let pool = pools.get(biome);
    if (!pool) {
      pool = candidates(species, (entry) =>
        spawnWeight(
          entry.rates[biome] ?? 0,
          entry.naturalLevel,
          teamAverage,
          spawnConfig,
        ),
      );
      pools.set(biome, pool);
    }
    return pool;
  };
  const open = tiles.filter(
    (tile) =>
      !WATER.has(tile.biome) &&
      hexDistance(tile, start) > config.minStartDistance &&
      poolOf(tile.biome).length > 0,
  );

  const tamers: MapTamer[] = [];
  for (let id = 1; id <= config.count && open.length > 0; id++) {
    // Tira o hexágono escolhido da lista: um Domador por hexágono.
    const index = Math.floor(random() * open.length);
    const tile = open[index]!;
    open[index] = open.at(-1)!;
    open.pop();
    tamers.push({
      ...rollTamer(
        id,
        poolOf(tile.biome),
        teamAverage,
        texts,
        random,
        config,
        spawnConfig,
      ),
      q: tile.q,
      r: tile.r,
    });
  }
  return tamers;
}

export interface ChallengerOptions extends TamerRollOptions {
  size?: TamerSize;
}

export function rollChallenger(
  species: SpawnSpecies[],
  teamAverage: number,
  texts: TamerTexts,
  random: Random,
  {
    config = TAMER_CONFIG,
    spawnConfig = DEFAULT_SPAWN_CONFIG,
    size,
  }: ChallengerOptions = {},
): RolledTamer | null {
  if (!hasTexts(texts)) return null;
  const pool = candidates(species, (entry) =>
    ENCOUNTER_BIOMES.reduce(
      (sum, biome) =>
        sum +
        spawnWeight(
          entry.rates[biome] ?? 0,
          entry.naturalLevel,
          teamAverage,
          spawnConfig,
        ),
      0,
    ),
  );
  if (pool.length === 0) return null;
  return rollTamer(
    0,
    pool,
    teamAverage,
    texts,
    random,
    config,
    spawnConfig,
    size,
  );
}
