import type { Random } from '../battle/types.js';
import { HexCoord, hexDistance, hexKey, hexNeighbors } from './hex.js';
import { DEFAULT_MAP_CONFIG, MapConfig } from './map-config.js';
import { createNoise, Noise2D } from './noise.js';
import { seededRandom } from './seeded-random.js';

export const BIOMES = [
  'temperate',
  'boreal',
  'stone',
  'hill',
  'mountain',
  'wshallow',
  'wdeep',
] as const;
export type Biome = (typeof BIOMES)[number];

export const SHAPED_BIOMES = [
  'temperate',
  'boreal',
  'stone',
  'wshallow',
  'wdeep',
] as const;
export type ShapedBiome = (typeof SHAPED_BIOMES)[number];

export const TERRAIN_SHAPES = ['flat', 'hill', 'mont'] as const;
export type TerrainShape = (typeof TERRAIN_SHAPES)[number];

export const MAX_HEIGHT = 4;

export interface MapTile extends HexCoord {
  biome: Biome;
  height: number;
  variant: number;
}

export interface GeneratedMap {
  seed: number;
  start: HexCoord;
  tiles: MapTile[];
}

export interface ShapedTile extends HexCoord {
  biome: ShapedBiome;
  shape: TerrainShape;
  variant: number;
}

export interface ShapedMap {
  seed: number;
  start: HexCoord;
  tiles: ShapedTile[];
}

interface Cell extends HexCoord {
  elevation: number;
  moisture: number;
  rock: number;
  ridge: number;
  biome: ShapedBiome;
  shape: TerrainShape;
  neighbors: Cell[];
}

const ORIGIN: HexCoord = { q: 0, r: 0 };
const ROW_HEIGHT = Math.sqrt(3) / 2;
const BASIC_VARIANTS = 3;

export function isWater(biome: Biome): boolean {
  return biome === 'wshallow' || biome === 'wdeep';
}

export function maxVariant(biome: Biome): number {
  return biome === 'hill' || biome === 'mountain'
    ? BASIC_VARIANTS
    : BASIC_VARIANTS * 2;
}

export function terrainOf(
  biome: ShapedBiome,
  shape: TerrainShape,
): { biome: Biome; height: number } {
  if (shape === 'mont') return { biome: 'mountain', height: MAX_HEIGHT };
  if (biome === 'stone')
    return { biome: shape === 'hill' ? 'hill' : 'stone', height: 3 };
  if (shape === 'hill') return { biome: 'hill', height: 2 };
  return { biome, height: isWater(biome) ? 0 : 1 };
}

export function generateMap(
  seed: number,
  config: MapConfig = DEFAULT_MAP_CONFIG,
): GeneratedMap {
  const map = generateShapedMap(seed, config);
  return {
    seed: map.seed,
    start: map.start,
    tiles: map.tiles.map(({ q, r, biome, shape, variant }) => ({
      q,
      r,
      ...terrainOf(biome, shape),
      variant,
    })),
  };
}

export function generateShapedMap(
  seed: number,
  config: MapConfig = DEFAULT_MAP_CONFIG,
): ShapedMap {
  const random = seededRandom(seed);
  const edge = createNoise(random);
  const elevation = createNoise(random);
  const moisture = createNoise(random);
  const rock = createNoise(random);
  const ridge = createNoise(random);

  const coords = growRegion(edge, config);
  const cells = createCells(
    coords,
    { elevation, moisture, rock, ridge },
    config,
  );
  placeWater(cells, config);
  for (const cell of cells) {
    if (!isWater(cell.biome)) cell.biome = landBiome(cell, config);
  }
  placeShapes(cells, random, config);
  gatherMountains(cells);
  gatherBiomes(cells, config);

  return {
    seed,
    start: startOf(cells),
    tiles: cells.map(({ q, r, biome, shape }) => ({
      q,
      r,
      biome,
      shape,
      variant: rollVariant(shape, random, config),
    })),
  };
}

function sample(noise: Noise2D, { q, r }: HexCoord, scale: number): number {
  return noise((q + r / 2) * scale, r * ROW_HEIGHT * scale);
}

/**
 * Cresce a partir da origem: sempre entra a vizinha de menor distância mais
 * ruído. Isso dá uma região conectada, do tamanho pedido e de borda irregular.
 */
function growRegion(edge: Noise2D, config: MapConfig): HexCoord[] {
  const score = (coord: HexCoord): number =>
    hexDistance(coord, ORIGIN) +
    sample(edge, coord, config.noiseScale) * config.edgeRoughness;
  const region: HexCoord[] = [];
  const known = new Set([hexKey(ORIGIN)]);
  const frontier = [{ coord: ORIGIN, score: 0 }];

  while (region.length < config.tileCount) {
    let best = 0;
    frontier.forEach((entry, index) => {
      if (entry.score < frontier[best]!.score) best = index;
    });
    const { coord } = frontier.splice(best, 1)[0]!;
    region.push(coord);
    for (const neighbor of hexNeighbors(coord)) {
      if (!known.has(hexKey(neighbor))) {
        known.add(hexKey(neighbor));
        frontier.push({ coord: neighbor, score: score(neighbor) });
      }
    }
  }
  return region;
}

function percentiles(values: number[]): number[] {
  const result = values.map(() => 0);
  values
    .map((value, index) => ({ value, index }))
    .sort((a, b) => a.value - b.value)
    .forEach(({ index }, rank) => {
      result[index] = rank / values.length;
    });
  return result;
}

function createCells(
  coords: HexCoord[],
  noises: Record<'elevation' | 'moisture' | 'rock' | 'ridge', Noise2D>,
  config: MapConfig,
): Cell[] {
  const raw = (noise: Noise2D): number[] =>
    coords.map((coord) => sample(noise, coord, config.noiseScale));
  const field = (noise: Noise2D): number[] => percentiles(raw(noise));
  const elevation = field(noises.elevation);
  const moisture = field(noises.moisture);
  const rock = field(noises.rock);
  // Perto do meio da faixa, o ruído desenha linhas: é daí que saem as cadeias.
  const ridge = percentiles(
    raw(noises.ridge).map((value) => 1 - Math.abs(value * 2 - 1)),
  );

  const cells = coords.map((coord, index): Cell => ({
    ...coord,
    elevation: elevation[index]!,
    moisture: moisture[index]!,
    rock: rock[index]!,
    ridge: ridge[index]!,
    biome: 'temperate',
    shape: 'flat',
    neighbors: [],
  }));
  const byKey = new Map(cells.map((cell) => [hexKey(cell), cell]));
  for (const cell of cells) {
    cell.neighbors = hexNeighbors(cell).flatMap((coord) => {
      const neighbor = byKey.get(hexKey(coord));
      return neighbor ? [neighbor] : [];
    });
  }
  return cells;
}

function placeWater(cells: Cell[], config: MapConfig): void {
  const deepLimit = config.waterFraction * config.deepFraction;
  for (const cell of cells) {
    if (cell.elevation < deepLimit) cell.biome = 'wdeep';
    else if (cell.elevation < config.waterFraction) cell.biome = 'wshallow';
  }
  for (const cell of cells) {
    const touchesLand = cell.neighbors.some(({ biome }) => !isWater(biome));
    if (cell.biome === 'wdeep' && touchesLand) cell.biome = 'wshallow';
  }
}

/** O bioma não olha a crista: plano, colina e montanha existem em todos. */
function landBiome({ moisture, rock }: Cell, config: MapConfig): ShapedBiome {
  if (rock > 1 - config.stoneFraction) return 'stone';
  return moisture > config.wetLimit ? 'boreal' : 'temperate';
}

function placeShapes(cells: Cell[], random: Random, config: MapConfig): void {
  for (const cell of cells) {
    if (isWater(cell.biome)) {
      if (random() < config.islandChance) {
        cell.shape = random() < 0.5 ? 'hill' : 'mont';
      }
    } else if (cell.ridge > config.mountainFrom) {
      cell.shape = 'mont';
    } else if (cell.ridge > config.hillFrom) {
      cell.shape = 'hill';
    }
  }
}

function gatherMountains(cells: Cell[]): void {
  const isLonely = (cell: Cell): boolean =>
    cell.shape === 'mont' &&
    !isWater(cell.biome) &&
    !cell.neighbors.some(({ shape }) => shape === 'mont');
  let changed = true;
  while (changed) {
    const lonely = cells.filter(isLonely);
    for (const cell of lonely) cell.shape = 'hill';
    changed = lonely.length > 0;
  }
}

function gatherBiomes(cells: Cell[], config: MapConfig): void {
  for (let pass = 0; pass < config.cleanupPasses; pass += 1) {
    for (const cell of cells) {
      if (
        !isWater(cell.biome) &&
        !cell.neighbors.some(({ biome }) => biome === cell.biome)
      ) {
        cell.biome = commonLandBiome(cell.neighbors) ?? cell.biome;
      }
    }
  }
}

function commonLandBiome(cells: Cell[]): ShapedBiome | undefined {
  const counts = countBiomes(cells.filter(({ biome }) => !isWater(biome)));
  let common: ShapedBiome | undefined;
  for (const [biome, count] of counts) {
    if (!common || count > counts.get(common)!) common = biome;
  }
  return common;
}

function countBiomes(cells: Cell[]): Map<ShapedBiome, number> {
  const counts = new Map<ShapedBiome, number>();
  for (const { biome } of cells) {
    counts.set(biome, (counts.get(biome) ?? 0) + 1);
  }
  return counts;
}

function startOf(cells: Cell[]): HexCoord {
  const flatLand = cells.filter(
    ({ biome, shape }) => !isWater(biome) && shape === 'flat',
  );
  const options = flatLand.length > 0 ? flatLand : cells;
  const nearest = options.reduce((best, cell) =>
    hexDistance(cell, ORIGIN) < hexDistance(best, ORIGIN) ? cell : best,
  );
  return { q: nearest.q, r: nearest.r };
}

/** No plano, as variantes de 4 a 6 são as de mais detalhe (`O_flat`). */
function rollVariant(
  shape: TerrainShape,
  random: Random,
  config: MapConfig,
): number {
  const base = 1 + Math.floor(random() * BASIC_VARIANTS);
  const detailed = shape === 'flat' && random() < config.detailChance;
  return detailed ? base + BASIC_VARIANTS : base;
}
