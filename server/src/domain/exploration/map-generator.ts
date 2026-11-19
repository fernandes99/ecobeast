import type { Random } from '../battle/types.js';
import { flatCenter } from '../islands/hex-pixels.js';
import { HexCoord, hexDistance, hexKey, hexNeighbors } from './hex.js';
import { DEFAULT_MAP_CONFIG, MapConfig } from './map-config.js';
import { createNoise, Noise2D } from './noise.js';
import { seededRandom } from './seeded-random.js';
import {
  DEEP_LAKE_FROM,
  distances,
  drainOf,
  flowDown,
  MinHeap,
  placeCrossings,
  placeLakes,
  placeRivers,
  RiverSource,
} from './map-water.js';

export const BIOMES = [
  'temperate',
  'boreal',
  'stone',
  'hill',
  'mountain',
  'wshallow',
  'wdeep',
  'desert',
  'snow',
  'beach',
  'wford',
] as const;
export type Biome = (typeof BIOMES)[number];

export const SHAPED_BIOMES = [
  'temperate',
  'boreal',
  'stone',
  'wshallow',
  'wdeep',
  'desert',
  'snow',
  'beach',
  'wford',
] as const;
export type ShapedBiome = (typeof SHAPED_BIOMES)[number];

export const TERRAIN_SHAPES = ['flat', 'hill', 'mont'] as const;
export type TerrainShape = (typeof TERRAIN_SHAPES)[number];

export const MAX_HEIGHT = 10;
/** O nível da montanha do mapa sorteado, abaixo do máximo das ilhas (terrain-height/02). */
export const MOUNTAIN_HEIGHT = 4;

export interface MapTile extends HexCoord {
  biome: Biome;
  height: number;
  variant: number;
  /** O slug da zona, só fora da Comum (biome-zones/01). */
  zone?: string;
}

/** Uma ponte no formato de `MapBridgeDto` (bridges/01). */
export interface GeneratedBridge {
  type: string;
  points: number[];
  width: number;
}

export interface GeneratedMap {
  seed: number;
  start: HexCoord;
  tiles: MapTile[];
  bridges: GeneratedBridge[];
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
  bridges: GeneratedBridge[];
  /** Os lagos e os rios, só para quem gera o mapa (coast-rivers/02). */
  lakes: HexCoord[][];
  rivers: { path: HexCoord[]; cells: HexCoord[]; source: RiverSource }[];
}

interface Cell extends HexCoord {
  elevation: number;
  moisture: number;
  temperature: number;
  rock: number;
  ridge: number;
  sea: boolean;
  wet: boolean;
  biome: ShapedBiome;
  shape: TerrainShape;
  neighbors: Cell[];
}

const ORIGIN: HexCoord = { q: 0, r: 0 };
const ROW_HEIGHT = Math.sqrt(3) / 2;
const BASIC_VARIANTS = 3;
/** O calor vem de um sorteio à parte, para os outros ruídos da seed não mudarem (desert-snow/01). */
const TEMPERATURE_SALT = 0x5eed7e;
/** O mar, os lagos e os rios vêm de outro sorteio à parte (coast-rivers/01). */
const WATER_SALT = 0x5ea5a1;
const MEANDER_SCALE = 6;
const BRIDGE_TYPE = 'wood_bridge';
const BRIDGE_WIDTH = 28;
/** O mar nasce na borda que olha até 60 graus para o lado dele. */
const SEA_SIDE = 0.5;

/** O vau é água no desenho, mas não bloqueia o andar (coast-rivers/03). */
export function isWater(biome: Biome): boolean {
  return biome === 'wshallow' || biome === 'wdeep' || biome === 'wford';
}

export function blocksWalking(biome: Biome): boolean {
  return biome === 'wshallow' || biome === 'wdeep';
}

export function maxVariant(biome: Biome): number {
  return biome === 'hill' || biome === 'mountain' || biome === 'wford'
    ? BASIC_VARIANTS
    : BASIC_VARIANTS * 2;
}

export function terrainOf(
  biome: ShapedBiome,
  shape: TerrainShape,
): { biome: Biome; height: number } {
  if (shape === 'mont') return { biome: 'mountain', height: MOUNTAIN_HEIGHT };
  if (biome === 'stone')
    return { biome: shape === 'hill' ? 'hill' : 'stone', height: 3 };
  if (shape === 'hill')
    return {
      biome:
        biome === 'desert' || biome === 'snow' || biome === 'beach'
          ? biome
          : 'hill',
      height: 2,
    };
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
    bridges: map.bridges,
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
  const temperature = createNoise(seededRandom(seed ^ TEMPERATURE_SALT));
  const water = seededRandom(seed ^ WATER_SALT);

  const coords = growRegion(edge, config);
  const cells = createCells(
    coords,
    { elevation, moisture, temperature, rock, ridge },
    config,
  );
  const edges = placeSea(cells, water, config);
  const beachWidth = createNoise(water);
  const meander = createNoise(water);
  const drain = drainOf(cells, (cell) =>
    sample(meander, cell, config.noiseScale * MEANDER_SCALE),
  );
  const shore = createNoise(water);
  const wobble = (cell: Cell) =>
    sample(shore, cell, config.noiseScale * MEANDER_SCALE);
  const lakes = placeLakes(cells, drain, wobble, water, config);
  const wet = cells.filter((cell) => cell.wet);
  const { down } = flowDown(
    drain,
    wet.length > 0 ? wet : cells.filter((cell) => cell.neighbors.length < 6),
  );
  const { rivers, ponds } = placeRivers(
    cells,
    drain,
    down,
    edges,
    wobble,
    water,
    config,
  );
  for (const { cells: body } of [...lakes, ...ponds]) fillLake(body);
  for (const river of rivers) {
    for (const cell of river.cells) cell.biome = 'wshallow';
  }
  for (const cell of cells) {
    if (!isWater(cell.biome)) cell.biome = landBiome(cell, config);
  }
  placeShapes(cells, config);
  gatherMountains(cells);
  gatherBiomes(cells, config);
  placeBeach(
    cells,
    beachWidth,
    new Set(rivers.flatMap(({ cells: body }) => body)),
    config,
  );
  const start = startOf(cells);
  const startCell = cells.find(({ q, r }) => q === start.q && r === start.r)!;
  const { crossings, absorbed } = placeCrossings(
    rivers,
    [...lakes, ...ponds],
    startCell,
    (a, b) =>
      a.shape !== 'mont' &&
      b.shape !== 'mont' &&
      terrainOf(a.biome, a.shape).height === terrainOf(b.biome, b.shape).height,
    water,
    config,
  );
  for (const { cells: line, bridge } of crossings) {
    if (!bridge) for (const cell of line) cell.biome = 'wford';
  }
  for (const cell of absorbed) {
    cell.biome = 'wshallow';
    cell.shape = 'flat';
  }

  const plain = (body: Cell[]) => body.map(({ q, r }) => ({ q, r }));
  const origin = flatCenter({ q: 0, r: 0 });
  return {
    seed,
    start,
    tiles: cells.map(({ q, r, biome, shape }) => {
      const variant = rollVariant(shape, random, config);
      return {
        q,
        r,
        biome,
        shape,
        variant:
          variant > maxVariant(biome) ? variant - BASIC_VARIANTS : variant,
      };
    }),
    bridges: crossings.flatMap(({ bridge }) => {
      if (!bridge) return [];
      const [a, b] = bridge.map(flatCenter);
      return [
        {
          type: BRIDGE_TYPE,
          points: [
            a!.x - origin.x,
            a!.y - origin.y,
            b!.x - origin.x,
            b!.y - origin.y,
          ],
          width: BRIDGE_WIDTH,
        },
      ];
    }),
    lakes: [...lakes, ...ponds].map(({ cells: body }) => plain(body)),
    rivers: rivers.map(({ path, cells: body, source }) => ({
      path: plain(path),
      cells: plain(body),
      source,
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
  noises: Record<
    'elevation' | 'moisture' | 'temperature' | 'rock' | 'ridge',
    Noise2D
  >,
  config: MapConfig,
): Cell[] {
  const raw = (noise: Noise2D): number[] =>
    coords.map((coord) => sample(noise, coord, config.noiseScale));
  const field = (noise: Noise2D): number[] => percentiles(raw(noise));
  const elevation = field(noises.elevation);
  const moisture = field(noises.moisture);
  const temperature = field(noises.temperature);
  const rock = field(noises.rock);
  // Perto do meio da faixa, o ruído desenha linhas: é daí que saem as cadeias.
  const ridge = percentiles(
    raw(noises.ridge).map((value) => 1 - Math.abs(value * 2 - 1)),
  );

  const cells = coords.map((coord, index): Cell => ({
    ...coord,
    elevation: elevation[index]!,
    moisture: moisture[index]!,
    temperature: temperature[index]!,
    rock: rock[index]!,
    ridge: ridge[index]!,
    sea: false,
    wet: false,
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

/**
 * O mar cresce, hexágono a hexágono, a partir da borda do lado que um ângulo sorteado
 * aponta: sempre entra o vizinho mais perto daquela borda, com a costa recortada por
 * um ruído. Crescendo pelos vizinhos, ele passa pelos estreitos do recorte do mapa e
 * fica um só, com uma costa longa.
 */
function placeSea(cells: Cell[], random: Random, config: MapConfig): Cell[] {
  const coast = createNoise(random);
  const angle = random() * Math.PI * 2;
  const target = Math.round(cells.length * config.seaFraction);
  const border = cells.filter((cell) => cell.neighbors.length < 6);
  if (target <= 0) return border;
  const point = ({ q, r }: HexCoord) => ({ x: q + r / 2, y: r * ROW_HEIGHT });
  const middle = cells.reduce(
    (sum, cell) => ({
      x: sum.x + point(cell).x / cells.length,
      y: sum.y + point(cell).y / cells.length,
    }),
    { x: 0, y: 0 },
  );
  const facing = (cell: Cell): number => {
    const { x, y } = point(cell);
    return Math.cos(Math.atan2(y - middle.y, x - middle.x) - angle);
  };
  const shore = border.filter((cell) => facing(cell) > SEA_SIDE);
  const sources =
    shore.length > 0
      ? shore
      : [
          border.reduce((best, cell) =>
            facing(cell) > facing(best) ? cell : best,
          ),
        ];
  const hops = distances(sources, () => true);
  const span = Math.max(1, ...hops.values());
  const score = new Map(
    cells.map((cell) => [
      cell,
      hops.get(cell)! +
        (sample(coast, cell, config.noiseScale) - 0.5) *
          config.coastRoughness *
          span,
    ]),
  );
  const frontier = new MinHeap<Cell>();
  for (const cell of sources) frontier.push(cell, score.get(cell)!);
  let count = 0;
  while (count < target && frontier.size > 0) {
    const { item: best } = frontier.pop();
    if (best.sea) continue;
    best.sea = true;
    best.wet = true;
    count += 1;
    for (const neighbor of best.neighbors) {
      if (!neighbor.sea) frontier.push(neighbor, score.get(neighbor)!);
    }
  }
  const fromLand = distances(
    cells.filter((cell) => !cell.sea),
    (cell) => cell.sea,
  );
  for (const cell of cells) {
    if (!cell.sea) continue;
    const distance = fromLand.get(cell) ?? Infinity;
    cell.biome = distance <= config.shallowWidth ? 'wshallow' : 'wdeep';
  }
  const inland = border.filter((cell) => !cell.sea && facing(cell) < -SEA_SIDE);
  return inland.length > 0 ? inland : border.filter((cell) => !cell.sea);
}

/** Um lago grande tem o meio fundo: a água sem terra vizinha. */
function fillLake(body: Cell[]): void {
  const inside = new Set(body);
  for (const cell of body) {
    const middle =
      body.length >= DEEP_LAKE_FROM &&
      cell.neighbors.length === 6 &&
      cell.neighbors.every((neighbor) => inside.has(neighbor));
    cell.biome = middle ? 'wdeep' : 'wshallow';
  }
}

/** A terra a 1 ou 2 hexágonos do mar vira Praia, menos a montanha. */
/**
 * A terra a até `beachMinWidth`–`beachMaxWidth` hexágonos do mar (a largura vem de um
 * ruído ao longo da costa) vira Praia, menos a montanha e a terra que encosta num rio:
 * o rio chega ao mar pela terra dele, sem a faixa de areia.
 */
function placeBeach(
  cells: Cell[],
  width: Noise2D,
  river: Set<Cell>,
  config: MapConfig,
): void {
  const fromSea = distances(
    cells.filter((cell) => cell.sea),
    (cell) => !isWater(cell.biome),
  );
  const spread = percentiles(
    cells.map((cell) => sample(width, cell, config.noiseScale * 2)),
  );
  const low = Math.min(config.beachMinWidth, config.beachMaxWidth);
  const high = Math.max(config.beachMinWidth, config.beachMaxWidth);
  cells.forEach((cell, index) => {
    const distance = fromSea.get(cell);
    if (distance === undefined || distance === 0 || cell.shape === 'mont') {
      return;
    }
    if (cell.neighbors.some((neighbor) => river.has(neighbor))) return;
    const reach =
      low + Math.min(high - low, Math.floor(spread[index]! * (high - low + 1)));
    if (distance <= reach) cell.biome = 'beach';
  });
}

/** O bioma não olha a crista: plano, colina e montanha existem em todos. */
function landBiome(
  { moisture, temperature, rock }: Cell,
  config: MapConfig,
): ShapedBiome {
  if (rock > 1 - config.stoneFraction) return 'stone';
  if (temperature > 1 - config.desertFraction) return 'desert';
  if (temperature < config.snowFraction) return 'snow';
  return moisture > config.wetLimit ? 'boreal' : 'temperate';
}

/** A água fica sempre plana: o mapa não tem ilhotas (coast-rivers). */
function placeShapes(cells: Cell[], config: MapConfig): void {
  for (const cell of cells) {
    if (isWater(cell.biome)) {
      continue;
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

/** O hexágono de chegada: terra plana, senão terra, e só sem terra nenhuma a água. */
export function startOf(
  cells: readonly Pick<ShapedTile, 'q' | 'r' | 'biome' | 'shape'>[],
): HexCoord {
  const land = cells.filter(({ biome }) => !isWater(biome));
  const flatLand = land.filter(({ shape }) => shape === 'flat');
  const options =
    flatLand.length > 0 ? flatLand : land.length > 0 ? land : cells;
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
