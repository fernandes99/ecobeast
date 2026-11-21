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
import { type GeneratedProp, placeGiantRocks } from './map-rocks.js';
import { levelLinks, openRamps, openSlopes } from './map-slopes.js';

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
] as const;
export type ShapedBiome = (typeof SHAPED_BIOMES)[number];

export const TERRAIN_SHAPES = ['flat', 'hill', 'mont'] as const;
export type TerrainShape = (typeof TERRAIN_SHAPES)[number];

export const MAX_HEIGHT = 10;
/** Os patamares da terra, do mais baixo ao mais alto (terrain-plateaus/02). A revisar. */
export const TERRACE_HEIGHTS = [1, 4, 7] as const;
/** A Montanha fica de 8 (na borda) a 10. */
export const MOUNTAIN_HEIGHT = 8;
export const BEACH_HEIGHT = 1;

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
  /** As pedras gigantes das Montanhas (giant-rocks/02). */
  props: GeneratedProp[];
  /**
   * A água doce, cada lago e cada rio um pedaço, só para as zonas (sea-life/07);
   * não vai para a resposta.
   */
  inland: HexCoord[][];
}

export interface ShapedTile extends HexCoord {
  biome: ShapedBiome;
  shape: TerrainShape;
  height: number;
  variant: number;
}

export interface ShapedMap {
  seed: number;
  start: HexCoord;
  tiles: ShapedTile[];
  bridges: GeneratedBridge[];
  /** As pedras gigantes das Montanhas (giant-rocks/02). */
  props: GeneratedProp[];
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
  height: number;
  neighbors: Cell[];
}

/** Os climas do mapa sorteado (map-realism/01): a base do calor e da umidade, e a chance. */
export const CLIMATES = [
  { slug: 'temperate', heat: 0.5, moisture: 0.5, chance: 0.4 },
  { slug: 'cold', heat: 0.24, moisture: 0.5, chance: 0.2 },
  { slug: 'hot', heat: 0.8, moisture: 0.4, chance: 0.2 },
  { slug: 'humid', heat: 0.54, moisture: 0.68, chance: 0.2 },
] as const;
export type Climate = (typeof CLIMATES)[number];

export const SNOW_BELOW = 0.12;
export const COLD_BELOW = 0.26;
export const DESERT_ABOVE = 0.82;
const DESERT_DRY = 0.55;
/** A rampa do calor, de uma ponta do mapa à outra. */
const HEAT_RAMP = 0.44;
const HEAT_NOISE = 0.28;
/** O ruído do calor é mais largo que o do terreno, para não sair em manchas. */
const HEAT_SCALE = 0.5;
const ALTITUDE_COLD = 0.12;
const MOISTURE_SPREAD = 0.6;
const STONE_ROCK = 0.5;
/** Até onde a Neve afasta a Planície, o Deserto e a Praia, e o Deserto afasta a Neve. */
const SNOW_GAP = 2;
const DESERT_SNOW_GAP = 3;
/** O relevo: o ruído de altitude, as cristas e a distância até o mar. */
const RELIEF_NOISE = 0.45;
const RELIEF_RIDGE = 0.35;
const RELIEF_SEA = 0.2;
const RELIEF_SEA_REACH = 25;
const CLIMATE_SALT = 0xc11a7e;

const ORIGIN: HexCoord = { q: 0, r: 0 };
/** Os 6 vizinhos em volta, na ordem do anel. */
const RING: readonly HexCoord[] = [
  { q: 1, r: 0 },
  { q: 1, r: -1 },
  { q: 0, r: -1 },
  { q: -1, r: 0 },
  { q: -1, r: 1 },
  { q: 0, r: 1 },
];
const ROW_HEIGHT = Math.sqrt(3) / 2;
const BASIC_VARIANTS = 3;
/** O calor vem de um sorteio à parte, para os outros ruídos da seed não mudarem (desert-snow/01). */
const TEMPERATURE_SALT = 0x5eed7e;
/** O mar, os lagos e os rios vêm de outro sorteio à parte (coast-rivers/01). */
const WATER_SALT = 0x5ea5a1;
const ROCKS_SALT = 0x60c4b1;
/** As encostas vêm de um sorteio à parte (terrain-plateaus/01). */
const SLOPES_SALT = 0x51095e;
const MEANDER_SCALE = 6;
const BRIDGE_TYPE = 'wood_bridge';
const BRIDGE_WIDTH = 28;
/** O mar nasce na borda que olha até 60 graus para o lado dele. */
const SEA_SIDE = 0.5;

export function isWater(biome: Biome): boolean {
  return biome === 'wshallow' || biome === 'wdeep';
}

export function blocksWalking(biome: Biome): boolean {
  return biome === 'wshallow' || biome === 'wdeep';
}

export function maxVariant(biome: Biome): number {
  return biome === 'hill' || biome === 'mountain'
    ? BASIC_VARIANTS
    : BASIC_VARIANTS * 2;
}

/** O bioma do catálogo pelo bioma e pela forma; a altura vem do relevo (terrain-plateaus/02). */
export function terrainOf(biome: ShapedBiome, shape: TerrainShape): Biome {
  if (shape === 'mont') return 'mountain';
  if (biome === 'stone') return shape === 'hill' ? 'hill' : 'stone';
  if (shape === 'hill') {
    return biome === 'desert' || biome === 'snow' || biome === 'beach'
      ? biome
      : 'hill';
  }
  return biome;
}

export function generateMap(
  seed: number,
  config: MapConfig = DEFAULT_MAP_CONFIG,
): GeneratedMap {
  const map = generateShapedMap(seed, config);
  return {
    seed: map.seed,
    start: map.start,
    tiles: map.tiles.map(({ q, r, biome, shape, height, variant }) => ({
      q,
      r,
      biome: terrainOf(biome, shape),
      height,
      variant,
    })),
    bridges: map.bridges,
    props: map.props,
    inland: [...map.lakes, ...map.rivers.map(({ cells }) => cells)],
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

  const climateRandom = seededRandom(seed ^ CLIMATE_SALT);
  const climate = climateOf(climateRandom, config);
  const heatAngle = climateRandom() * Math.PI * 2;
  const heat = createNoise(climateRandom);

  const coords = growRegion(edge, config);
  const cells = createCells(
    coords,
    { elevation, moisture, temperature, rock, ridge },
    config,
  );
  const edges = placeSea(cells, water, config);
  shapeRelief(cells);
  placeShapes(cells, config);
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
    (cell) => cell.shape !== 'mont',
  );
  for (const { cells: body } of [...lakes, ...ponds]) fillLake(body);
  for (const river of rivers) {
    for (const cell of river.cells) cell.biome = 'wshallow';
  }
  for (const cell of cells) {
    if (isWater(cell.biome)) cell.shape = 'flat';
  }
  gatherMountains(cells);
  placeClimate(cells, climate, heat, heatAngle, config.noiseScale);
  for (const cell of cells) {
    if (!isWater(cell.biome)) cell.biome = landBiome(cell, config);
  }
  gatherBiomes(cells, config);
  placeBeach(
    cells,
    beachWidth,
    new Set(rivers.flatMap(({ cells: body }) => body)),
    config,
  );
  separateBiomes(cells);
  const start = startOf(cells);
  const startCell = cells.find(({ q, r }) => q === start.q && r === start.r)!;
  placeLandHeights(cells, config);
  const { crossings, absorbed } = placeCrossings(
    rivers,
    [...lakes, ...ponds],
    startCell,
    (a, b) => a.shape !== 'mont' && b.shape !== 'mont' && a.height === b.height,
    (a, b) => levelBanks(a, b, config),
    config,
  );
  for (const cell of absorbed) {
    cell.biome = 'wshallow';
    cell.shape = 'flat';
  }
  for (const cell of absorbed) cell.height = 0;
  const mountains = cells.filter((cell) => cell.shape === 'mont');
  gatherMountains(cells);
  for (const cell of mountains) {
    if (cell.shape !== 'mont') cell.height = groundFloor(cell, config);
  }
  placeMountainHeights(cells);
  const links = new Map<Cell, Cell[]>();
  for (const {
    bridge: [a, b],
  } of crossings) {
    links.set(a, [...(links.get(a) ?? []), b]);
    links.set(b, [...(links.get(b) ?? []), a]);
  }
  // Uma margem pode ser de duas pontes, e o `levelBanks` da segunda a subiu.
  levelLinks(links);
  const slopes = seededRandom(seed ^ SLOPES_SALT);
  const banks = new Set(links.keys());
  openRamps(
    cells,
    config.rampEvery,
    (cell) => !isWater(cell.biome) && cell.shape !== 'mont' && !banks.has(cell),
    (cell) => !isWater(cell.biome),
    slopes,
  );
  openSlopes(cells, startCell, links, (cell) => isWater(cell.biome), slopes);

  const plain = (body: Cell[]) => body.map(({ q, r }) => ({ q, r }));
  const origin = flatCenter({ q: 0, r: 0 });
  const tiles = cells.map(({ q, r, biome, shape, height }) => {
    const variant = rollVariant(shape, random, config);
    return {
      q,
      r,
      biome,
      shape,
      height,
      variant: variant > maxVariant(biome) ? variant - BASIC_VARIANTS : variant,
    };
  });
  const bridges = crossings.flatMap(({ bridge }) => {
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
  });
  return {
    seed,
    start,
    tiles,
    bridges,
    props: placeGiantRocks(
      tiles,
      start,
      bridges,
      seededRandom(seed ^ ROCKS_SALT),
    ),
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
 * ruído. Isso dá uma região conectada e de borda irregular. Depois, os buracos que
 * a borda cercou entram, e saem da borda os hexágonos de maior nota que não partem
 * a região, até voltar ao tamanho pedido (map-realism/01).
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

  const inside = new Map(region.map((coord) => [hexKey(coord), coord]));
  for (const hole of holesOf(inside)) inside.set(hexKey(hole), hole);
  const scores = new Map(
    [...inside.values()].map((coord) => [coord, score(coord)]),
  );
  const outside = (coord: HexCoord) => !inside.has(hexKey(coord));
  const byScore = (a: HexCoord, b: HexCoord) => scores.get(b)! - scores.get(a)!;
  const border = [...inside.values()]
    .filter((coord) => hexNeighbors(coord).some(outside))
    .sort(byScore);
  while (inside.size > config.tileCount) {
    const index = border.findIndex(
      (coord) => hexKey(coord) !== hexKey(ORIGIN) && staysWhole(coord, inside),
    );
    if (index < 0) break;
    const [removed] = border.splice(index, 1);
    inside.delete(hexKey(removed!));
    const listed = new Set(border.map(hexKey));
    for (const neighbor of hexNeighbors(removed!)) {
      const coord = inside.get(hexKey(neighbor));
      if (coord && !listed.has(hexKey(coord))) border.push(coord);
    }
    border.sort(byScore);
  }
  return [...inside.values()];
}

/** Os hexágonos de fora da região que ela cerca: os que não chegam até o lado de fora. */
function holesOf(inside: Map<string, HexCoord>): HexCoord[] {
  const coords = [...inside.values()];
  const low = {
    q: Math.min(...coords.map(({ q }) => q)) - 1,
    r: Math.min(...coords.map(({ r }) => r)) - 1,
  };
  const high = {
    q: Math.max(...coords.map(({ q }) => q)) + 1,
    r: Math.max(...coords.map(({ r }) => r)) + 1,
  };
  const within = ({ q, r }: HexCoord) =>
    q >= low.q && q <= high.q && r >= low.r && r <= high.r;
  const outer = new Set([hexKey(low)]);
  const pending = [low];
  while (pending.length > 0) {
    for (const next of hexNeighbors(pending.pop()!)) {
      const key = hexKey(next);
      if (!within(next) || outer.has(key) || inside.has(key)) continue;
      outer.add(key);
      pending.push(next);
    }
  }
  const holes: HexCoord[] = [];
  for (let q = low.q; q <= high.q; q += 1) {
    for (let r = low.r; r <= high.r; r += 1) {
      const key = hexKey({ q, r });
      if (!inside.has(key) && !outer.has(key)) holes.push({ q, r });
    }
  }
  return holes;
}

/** Tirar `coord` não parte a região: os vizinhos dela de dentro ficam num trecho só do anel. */
function staysWhole(coord: HexCoord, inside: Map<string, HexCoord>): boolean {
  const filled = RING.map(({ q, r }) =>
    inside.has(hexKey({ q: coord.q + q, r: coord.r + r })),
  );
  let runs = 0;
  filled.forEach((value, index) => {
    if (value && !filled[(index + RING.length - 1) % RING.length]) runs += 1;
  });
  return runs === 1 || filled.every(Boolean);
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
    height: 0,
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

/**
 * A terra a até `beachMinWidth`–`beachMaxWidth` hexágonos do mar (a largura vem de um
 * ruído ao longo da costa) vira Praia, menos a montanha e a terra que encosta num rio:
 * o rio chega ao mar pela terra dele, sem a faixa de areia. Na costa fria, a faixa é de
 * Pedra (map-realism/01).
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
    if (distance > reach) return;
    cell.biome = cell.temperature < COLD_BELOW ? 'stone' : 'beach';
  });
}

/** O clima do mapa: o de `config.climate`, ou sorteado pela chance de cada um. */
function climateOf(random: Random, config: MapConfig): Climate {
  const roll = random();
  if (config.climate > 0) return CLIMATES[config.climate - 1]!;
  let total = 0;
  for (const climate of CLIMATES) {
    total += climate.chance;
    if (roll < total) return climate;
  }
  return CLIMATES[0];
}

/**
 * O relevo da terra (map-realism/01): o ruído de altitude, as cristas, que fazem as
 * cadeias, e a distância até o mar, para a terra subir longe da costa. Em percentil,
 * de 0 a 1; o mar fica em 0.
 */
function shapeRelief(cells: Cell[]): void {
  const sea = cells.filter((cell) => cell.sea);
  const fromSea = distances(sea, () => true);
  const land = cells.filter((cell) => !cell.sea);
  const coast = (cell: Cell): number =>
    sea.length === 0
      ? 0.5
      : Math.min((fromSea.get(cell) ?? RELIEF_SEA_REACH) / RELIEF_SEA_REACH, 1);
  const relief = percentiles(
    land.map(
      (cell) =>
        RELIEF_NOISE * cell.elevation +
        RELIEF_RIDGE * cell.ridge +
        RELIEF_SEA * coast(cell),
    ),
  );
  for (const cell of sea) cell.elevation = 0;
  land.forEach((cell, index) => {
    cell.elevation = relief[index]!;
  });
}

/**
 * O calor e a umidade de cada hexágono (map-realism/01): a base do clima, uma rampa numa
 * direção sorteada, um ruído largo e o frio do alto. A soma não é ordenada de novo, então
 * um mapa pode ficar sem Neve ou sem Deserto.
 */
function placeClimate(
  cells: Cell[],
  climate: Climate,
  heat: Noise2D,
  angle: number,
  scale: number,
): void {
  const along = percentiles(
    cells.map(
      ({ q, r }) =>
        (q + r / 2) * Math.cos(angle) + r * ROW_HEIGHT * Math.sin(angle),
    ),
  );
  const wide = percentiles(
    cells.map((cell) => sample(heat, cell, scale * HEAT_SCALE)),
  );
  cells.forEach((cell, index) => {
    const high = Math.max(0, (cell.elevation - 0.5) / 0.5);
    cell.temperature =
      climate.heat +
      HEAT_RAMP * (along[index]! - 0.5) +
      HEAT_NOISE * (wide[index]! - 0.5) -
      ALTITUDE_COLD * high;
    cell.moisture = climate.moisture + MOISTURE_SPREAD * (cell.moisture - 0.5);
  });
}

/** O bioma pelo calor e pela umidade, com a Pedra no alto (map-realism/01). */
function landBiome(
  { moisture, temperature, rock, elevation }: Cell,
  config: MapConfig,
): ShapedBiome {
  if (temperature < SNOW_BELOW) return 'snow';
  if (elevation > config.stoneFrom && rock > STONE_ROCK) return 'stone';
  if (temperature < COLD_BELOW) return 'boreal';
  if (temperature > DESERT_ABOVE && moisture < DESERT_DRY) return 'desert';
  return moisture > config.wetLimit ? 'boreal' : 'temperate';
}

/** A terra a até `gap` hexágonos de algum hexágono de `from`. */
function near(cells: Cell[], from: ShapedBiome, gap: number): Cell[] {
  const reach = distances(
    cells.filter(({ biome }) => biome === from),
    () => true,
  );
  return [...reach]
    .filter(([, distance]) => distance <= gap)
    .map(([cell]) => cell);
}

/**
 * As vizinhanças proibidas (map-realism/01): o Deserto perto da Neve vira Planície; a
 * Planície, o Deserto e a Praia perto da Neve viram Boreal (a Praia, Pedra); e o Deserto
 * encostado no Boreal vira Planície.
 */
function separateBiomes(cells: Cell[]): void {
  for (const cell of near(cells, 'snow', DESERT_SNOW_GAP)) {
    if (cell.biome === 'desert') cell.biome = 'temperate';
  }
  for (const cell of near(cells, 'snow', SNOW_GAP)) {
    if (cell.biome === 'beach') cell.biome = 'stone';
    else if (cell.biome === 'temperate' || cell.biome === 'desert') {
      cell.biome = 'boreal';
    }
  }
  for (const cell of cells) {
    if (
      cell.biome === 'desert' &&
      cell.neighbors.some(({ biome }) => biome === 'boreal')
    ) {
      cell.biome = 'temperate';
    }
  }
}

/**
 * As margens de uma ponte que não cabia: terra plana na mesma altura, a da margem mais alta
 * sem a Montanha (terrain-plateaus/02), e a Pedra vira o bioma da outra margem.
 */
function levelBanks(a: Cell, b: Cell, config: MapConfig): void {
  const height = Math.max(groundFloor(a, config), groundFloor(b, config));
  a.height = height;
  b.height = height;
  a.shape = 'flat';
  b.shape = 'flat';
  if (a.biome === 'stone' && b.biome !== 'stone') a.biome = b.biome;
  else if (b.biome === 'stone' && a.biome !== 'stone') b.biome = a.biome;
}

/** O patamar da terra pela altitude do relevo (terrain-plateaus/02 RF-01). */
function terraceOf(cell: Cell, config: MapConfig): number {
  const [low, middle, high] = TERRACE_HEIGHTS;
  if (cell.elevation < config.terraceLow) return low;
  return cell.elevation < config.terraceHigh ? middle : high;
}

/**
 * A altura de um hexágono que deixa de ser Montanha (uma margem de ponte ou uma montanha
 * solta): o patamar dele. A terra que já não era Montanha fica na altura que tinha.
 */
function groundFloor(cell: Cell, config: MapConfig): number {
  const [, , top] = TERRACE_HEIGHTS;
  return cell.shape === 'mont' || cell.height > top
    ? terraceOf(cell, config)
    : cell.height;
}

/** A terra: a Montanha de 8 a 10, a Praia no 1 e o resto nos patamares (RF-01 a 03). */
function placeLandHeights(cells: Cell[], config: MapConfig): void {
  for (const cell of cells) {
    // Toda água fica no 0; as cachoeiras ficam para depois (terrain-plateaus/02).
    if (isWater(cell.biome)) cell.height = 0;
    if (isWater(cell.biome) || cell.shape === 'mont') continue;
    cell.height =
      cell.biome === 'beach' ? BEACH_HEIGHT : terraceOf(cell, config);
  }
  placeMountainHeights(cells);
}

/** A Montanha: 8 encostada em outra coisa, 9 a 2 hexágonos e 10 mais para dentro. */
function placeMountainHeights(cells: Cell[]): void {
  const isMountain = (cell: Cell) => cell.shape === 'mont';
  const around = distances(
    cells.filter((cell) => !isMountain(cell)),
    isMountain,
  );
  for (const cell of cells) {
    if (!isMountain(cell)) continue;
    const reach = around.get(cell) ?? MAX_HEIGHT;
    cell.height = Math.min(MOUNTAIN_HEIGHT + reach - 1, MAX_HEIGHT);
  }
}

/** A forma pelo relevo; a água fica sempre plana, sem ilhotas (coast-rivers). */
function placeShapes(cells: Cell[], config: MapConfig): void {
  for (const cell of cells) {
    if (isWater(cell.biome)) {
      cell.shape = 'flat';
    } else if (cell.elevation > config.mountainFrom) {
      cell.shape = 'mont';
    } else if (cell.elevation > config.hillFrom) {
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
