import type { Random } from '../battle/types.js';
import {
  type BlockLine,
  addLineHexes,
  worldLines,
} from '../islands/blocked-hexes.js';
import { flatCenter, gridCoord } from '../islands/hex-pixels.js';
import { type HexCoord, hexKey, hexNeighbors } from './hex.js';
import { climbable } from './map-slopes.js';

/** A água e a lava (volcano/03), sem importar o gerador, que importa este arquivo. */
const WALL_BIOMES: ReadonlySet<string> = new Set([
  'wshallow',
  'wdeep',
  'lshallow',
  'ldeep',
]);

/** Uma pedra gigante do mapa sorteado, no formato de peça solta (giant-rocks/02). */
export interface GeneratedProp extends HexCoord {
  propTypeId: number;
  dx: number;
  dy: number;
  variant: number;
  mirrored: boolean;
  block: BlockLine[];
}

export interface RockTile extends HexCoord {
  biome: string;
  shape: string;
  height: number;
}

interface RockKind {
  propTypeId: number;
  variants: number[];
  /** A linha fechada do pé, igual à de `prop_type_blocks` (migration giant_rocks). */
  points: number[];
  /** As linhas do pé, quando são mais de uma (o Arco de gelo, uma em cada perna). */
  lines?: number[][];
  /** Ocupa este hexágono e o da direita (q + 1). */
  wide?: true;
}

const CRAG = [-30, -20, -15, -8, 15, -8, 30, -20, 15, -32, -15, -32];
const PINNACLES = [-22, -14, -11, -5, 11, -5, 22, -14, 11, -23, -11, -23];
const SLAB = [-42, -27, -21, -13, 21, -13, 42, -27, 21, -41, -21, -41];
const RIDGE = [-54, -31, -27, -17, 27, -17, 54, -31, 27, -45, -27, -45];

const KINDS = {
  crag: { propTypeId: 131, variants: [1, 2, 3], points: CRAG },
  dryCrag: { propTypeId: 131, variants: [1, 3], points: CRAG },
  pinnacles: { propTypeId: 132, variants: [1], points: PINNACLES },
  slab: { propTypeId: 133, variants: [1], points: SLAB },
  boulders: { propTypeId: 134, variants: [1], points: CRAG },
  ridge: { propTypeId: 135, variants: [1], points: RIDGE, wide: true },
  snowyCrag: { propTypeId: 136, variants: [1], points: CRAG },
  snowyPinnacles: { propTypeId: 137, variants: [1], points: PINNACLES },
  snowyBoulders: { propTypeId: 138, variants: [1], points: CRAG },
} satisfies Record<string, RockKind>;

/** Os tipos de pedra pelo bioma do hexágono de Montanha (giant-rocks/02 RF-02). */
export const ROCKS_BY_BIOME: Record<string, RockKind[]> = {
  snow: [KINDS.snowyCrag, KINDS.snowyPinnacles, KINDS.snowyBoulders],
  desert: [KINDS.dryCrag, KINDS.pinnacles, KINDS.slab, KINDS.ridge],
  other: [KINDS.crag, KINDS.pinnacles, KINDS.slab, KINDS.boulders, KINDS.ridge],
};
export const SNOWY_ROCK_TYPES = [136, 137, 138];
/** A chance de um hexágono de Montanha ganhar uma pedra. A revisar. */
export const ROCK_CHANCE = 0.35;

const ICE_FOOT = [-28, -19, -14, -8, 14, -8, 28, -19, 14, -30, -14, -30];
const ARCH_LEFT = [-41, -16, -36, -10, -26, -10, -21, -16, -26, -22, -36, -22];
const ARCH_RIGHT = [21, -16, 26, -10, 36, -10, 41, -16, 36, -22, 26, -22];
/** As pedras de gelo da Geleira (glacier/02), com as linhas da migration ice_rocks. */
export const ICE_ROCKS: RockKind[] = [
  {
    propTypeId: 171,
    variants: [1, 2],
    points: [-26, -18, -13, -7, 13, -7, 26, -18, 13, -29, -13, -29],
  },
  {
    propTypeId: 172,
    variants: [1],
    points: [-29, -20, -15, -8, 14, -8, 29, -20, 14, -32, -15, -32],
  },
  {
    propTypeId: 173,
    variants: [1],
    points: [...ARCH_LEFT, ...ARCH_RIGHT],
    lines: [ARCH_LEFT, ARCH_RIGHT],
  },
  { propTypeId: 174, variants: [1], points: ICE_FOOT },
  { propTypeId: 175, variants: [1], points: ICE_FOOT },
  {
    propTypeId: 176,
    variants: [1],
    points: [-42, -26, -21, -12, 21, -12, 42, -26, 21, -40, -21, -40],
  },
];
export const ICE_ROCK_TYPES = ICE_ROCKS.map(({ propTypeId }) => propTypeId);
/** A chance de um hexágono de Geleira ganhar uma pedra de gelo; ela é plana e se anda nela. A revisar. */
export const ICE_ROCK_CHANCE = 0.15;

/** Os picos de basalto (volcano/02), com as linhas da migration basalt_spires. */
export const BASALT_SPIRES: RockKind[] = [
  {
    propTypeId: 184,
    variants: [1],
    points: [-22, -14, -11, -5, 11, -5, 22, -14, 11, -23, -11, -23],
  },
  {
    propTypeId: 185,
    variants: [1],
    points: [-25, -16, -13, -6, 12, -6, 25, -16, 12, -26, -13, -26],
  },
  {
    propTypeId: 186,
    variants: [1],
    points: [-34, -24, -17, -10, 17, -10, 34, -24, 17, -38, -17, -38],
  },
  {
    propTypeId: 187,
    variants: [1],
    points: [-33, -22, -17, -9, 16, -9, 33, -22, 16, -35, -17, -35],
  },
  {
    propTypeId: 188,
    variants: [1],
    points: [-24, -16, -12, -6, 12, -6, 24, -16, 12, -26, -12, -26],
  },
  {
    propTypeId: 189,
    variants: [1],
    points: [-32, -22, -16, -9, 16, -9, 32, -22, 16, -35, -16, -35],
  },
];
/** As rachaduras de lava (volcano/01), uma linha por variante, as da migration volcano_props. */
export const LAVA_CRACKS: RockKind[] = [
  {
    propTypeId: 178,
    variants: [1],
    points: [
      -22, -11, -17, -14, -12, -17, -7, -19, -2, -20, 3, -22, 8, -24, 13, -25,
      18, -27, 21, -26, 21, -21, 18, -19, 13, -16, 8, -13, 3, -11, -2, -8, -7,
      -8, -12, -6, -17, -5, -22, -7,
    ],
  },
  {
    propTypeId: 178,
    variants: [2],
    points: [
      -20, -11, -15, -13, -10, -15, -5, -17, 0, -18, 5, -20, 10, -22, 15, -23,
      19, -22, 19, -18, 15, -14, 10, -10, 5, -5, 0, -5, -5, -7, -10, -6, -15,
      -6, -20, -7,
    ],
  },
  {
    propTypeId: 178,
    variants: [3],
    points: [
      -17, -11, -12, -14, -7, -14, -2, -14, 3, -13, 8, -13, 13, -11, 16, -9, 16,
      -4, 13, -2, 8, -1, 3, 0, -2, 0, -7, -2, -12, -3, -17, -6,
    ],
  },
  {
    propTypeId: 178,
    variants: [4],
    points: [
      -23, -10, -18, -11, -13, -10, -8, -10, -3, -10, 2, -13, 7, -14, 12, -16,
      17, -15, 22, -14, 22, -10, 17, -8, 12, -7, 7, -4, 2, -2, -3, -1, -8, 0,
      -13, -1, -18, -3, -23, -6,
    ],
  },
];
export const BASALT_SPIRE_TYPES = BASALT_SPIRES.map(
  ({ propTypeId }) => propTypeId,
);
export const LAVA_CRACK_TYPE = 178;
/** A chance de um pico por hexágono da borda e da encosta, e a de uma rachadura. A revisar. */
export const RIM_SPIRE_CHANCE = 0.33;
export const SLOPE_SPIRE_CHANCE = 0.04;
export const LAVA_CRACK_CHANCE = 1 / 30;

export interface VolcanoKeys {
  rim: ReadonlySet<string>;
  slope: ReadonlySet<string>;
  floor: ReadonlySet<string>;
  stairs: ReadonlySet<string>;
}

/**
 * Os picos de basalto na borda e na encosta do vulcão e as rachaduras de lava nos
 * patamares e no piso (volcano/04), pelas regras das pedras gigantes: nunca numa
 * escadaria nem fechando o caminho de ninguém.
 */
export function placeVolcanoRocks(
  tiles: readonly RockTile[],
  start: HexCoord,
  bridges: readonly { points: readonly number[] }[],
  random: Random,
  taken: readonly GeneratedProp[],
  volcano: VolcanoKeys,
): GeneratedProp[] {
  const off = (tile: RockTile) => !volcano.stairs.has(hexKey(tile));
  const rim = placeRocks(tiles, start, bridges, random, {
    allowed: (tile) => off(tile) && volcano.rim.has(hexKey(tile)),
    kindsOf: () => BASALT_SPIRES,
    chance: RIM_SPIRE_CHANCE,
    taken,
  });
  const slope = placeRocks(tiles, start, bridges, random, {
    allowed: (tile) => off(tile) && volcano.slope.has(hexKey(tile)),
    kindsOf: () => BASALT_SPIRES,
    chance: SLOPE_SPIRE_CHANCE,
    taken: [...taken, ...rim],
  });
  const cracks = placeRocks(tiles, start, bridges, random, {
    allowed: (tile) =>
      off(tile) &&
      (volcano.slope.has(hexKey(tile)) || volcano.floor.has(hexKey(tile))),
    kindsOf: () => LAVA_CRACKS,
    chance: LAVA_CRACK_CHANCE,
    taken: [...taken, ...rim, ...slope],
  });
  return [...rim, ...slope, ...cracks];
}

/** Os hexágonos que as linhas de uma pedra fecham. */
export function rockHexes(prop: GeneratedProp): Set<string> {
  const keys = new Set<string>();
  for (const line of worldLines(prop, new Map())) {
    addLineHexes(line.points, line.closed, keys);
  }
  return keys;
}

/**
 * As pedras gigantes nas Montanhas: uma por hexágono sorteado, sem encostar em
 * outra, fora da chegada e sem tirar terra do alcance da chegada.
 */
export function placeGiantRocks(
  tiles: readonly RockTile[],
  start: HexCoord,
  bridges: readonly { points: readonly number[] }[],
  random: Random,
): GeneratedProp[] {
  return placeRocks(tiles, start, bridges, random, {
    allowed: ({ shape }) => shape === 'mont',
    kindsOf: (tile) => ROCKS_BY_BIOME[tile.biome] ?? ROCKS_BY_BIOME.other!,
    chance: ROCK_CHANCE,
    taken: [],
  });
}

/**
 * As pedras de gelo só na Geleira (glacier/04), pelas regras das gigantes e longe
 * das que já estão no mapa (`taken`). O sorteio é próprio, para as da Montanha não mudarem.
 */
export function placeIceRocks(
  tiles: readonly RockTile[],
  start: HexCoord,
  bridges: readonly { points: readonly number[] }[],
  random: Random,
  taken: readonly GeneratedProp[],
): GeneratedProp[] {
  return placeRocks(tiles, start, bridges, random, {
    allowed: ({ biome, shape }) => biome === 'glacier' && shape !== 'mont',
    kindsOf: () => ICE_ROCKS,
    chance: ICE_ROCK_CHANCE,
    taken,
  });
}

interface RockRule {
  allowed: (tile: RockTile) => boolean;
  kindsOf: (tile: RockTile) => readonly RockKind[];
  chance: number;
  taken: readonly GeneratedProp[];
}

function placeRocks(
  tiles: readonly RockTile[],
  start: HexCoord,
  bridges: readonly { points: readonly number[] }[],
  random: Random,
  rule: RockRule,
): GeneratedProp[] {
  const byKey = new Map(tiles.map((tile) => [hexKey(tile), tile]));
  const links = bridgeLinks(bridges);
  const startKey = hexKey(start);
  const blocked = new Set(rule.taken.flatMap((prop) => [...rockHexes(prop)]));
  const reach = reachable(byKey, links, startKey, blocked);
  const order = tiles
    .filter(rule.allowed)
    .map((tile) => ({ tile, roll: random() }))
    .sort((a, b) => a.roll - b.roll)
    .map(({ tile }) => tile);
  const props: GeneratedProp[] = [];
  for (const tile of order) {
    if (random() >= rule.chance) continue;
    const kinds = rule.kindsOf(tile);
    const kind = kinds[Math.floor(random() * kinds.length)]!;
    const variant = kind.variants[Math.floor(random() * kind.variants.length)]!;
    const mirrored = random() < 0.5;
    const prop = rockAt(tile, kind, variant, mirrored);
    const hexes = rockHexes(prop);
    if (!fits(hexes, byKey, blocked, startKey, rule.allowed)) continue;
    if (!staysConnected(hexes, byKey, links, blocked, reach)) continue;
    for (const key of hexes) blocked.add(key);
    props.push(prop);
  }
  return props;
}

/**
 * Os vizinhos alcançáveis dos hexágonos da pedra continuam ligados entre si: um
 * caminho que passava pela pedra dá a volta por eles, então ninguém sai do alcance.
 */
function staysConnected(
  hexes: ReadonlySet<string>,
  byKey: ReadonlyMap<string, RockTile>,
  links: ReadonlyMap<string, string[]>,
  blocked: ReadonlySet<string>,
  reach: ReadonlySet<string>,
): boolean {
  const around = (key: string) => [
    ...steps(byKey, key),
    ...(links.get(key) ?? []),
  ];
  const open = (key: string) =>
    reach.has(key) && !hexes.has(key) && !blocked.has(key);
  const targets = new Set(
    [...hexes].flatMap(around).filter((key) => open(key)),
  );
  if (targets.size <= 1) return true;
  const first = targets.values().next().value!;
  const seen = new Set([first]);
  const pending = [first];
  let found = 1;
  while (pending.length > 0 && found < targets.size) {
    for (const next of around(pending.pop()!)) {
      if (seen.has(next) || !open(next)) continue;
      seen.add(next);
      pending.push(next);
      if (targets.has(next)) found += 1;
    }
  }
  return found === targets.size;
}

function rockAt(
  tile: HexCoord,
  kind: RockKind,
  variant: number,
  mirrored: boolean,
): GeneratedProp {
  const xs = kind.points.filter((_, index) => index % 2 === 0);
  const ys = kind.points.filter((_, index) => index % 2 === 1);
  const middleY = (Math.min(...ys) + Math.max(...ys)) / 2;
  const middleX = (Math.min(...xs) + Math.max(...xs)) / 2;
  return {
    q: tile.q,
    r: tile.r,
    propTypeId: kind.propTypeId,
    dx: (kind.wide ? 32 : 0) - Math.round(middleX),
    dy: -Math.round(middleY),
    variant,
    mirrored,
    block: (kind.lines ?? [kind.points]).map((points) => ({
      closed: true,
      points: [...points],
    })),
  };
}

function fits(
  hexes: Set<string>,
  byKey: ReadonlyMap<string, RockTile>,
  blocked: ReadonlySet<string>,
  startKey: string,
  allowed: (tile: RockTile) => boolean,
): boolean {
  for (const key of hexes) {
    const tile = byKey.get(key);
    if (!tile || !allowed(tile) || key === startKey) return false;
    if (blocked.has(key)) return false;
    if (hexNeighbors(tile).some((next) => blocked.has(hexKey(next)))) {
      return false;
    }
  }
  return hexes.size > 0;
}

export function bridgeLinks(
  bridges: readonly { points: readonly number[] }[],
): Map<string, string[]> {
  const origin = flatCenter({ q: 0, r: 0 });
  const links = new Map<string, string[]>();
  for (const { points } of bridges) {
    const at = (x: number, y: number) =>
      hexKey(gridCoord({ x: origin.x + x, y: origin.y + y }));
    const a = at(points[0]!, points[1]!);
    const b = at(points[2]!, points[3]!);
    links.set(a, [...(links.get(a) ?? []), b]);
    links.set(b, [...(links.get(b) ?? []), a]);
  }
  return links;
}

/** Os vizinhos de `key` aonde se anda sem passar por paredão (terrain-plateaus/01). */
function steps(byKey: ReadonlyMap<string, RockTile>, key: string): string[] {
  const tile = byKey.get(key)!;
  return hexNeighbors(tile)
    .map(hexKey)
    .filter((other) => {
      const neighbor = byKey.get(other);
      return neighbor !== undefined && climbable(tile, neighbor);
    });
}

/**
 * A terra que se alcança da chegada, andando sem passar por paredão e pelas pontes,
 * fora de `blocked`.
 */
export function reachable(
  byKey: ReadonlyMap<string, RockTile>,
  links: ReadonlyMap<string, string[]>,
  startKey: string,
  blocked: ReadonlySet<string>,
): Set<string> {
  const seen = new Set([startKey]);
  const pending = [startKey];
  while (pending.length > 0) {
    const key = pending.pop()!;
    const next = [...steps(byKey, key), ...(links.get(key) ?? [])];
    for (const other of next) {
      const neighbor = byKey.get(other);
      if (!neighbor || seen.has(other) || blocked.has(other)) continue;
      if (WALL_BIOMES.has(neighbor.biome)) continue;
      seen.add(other);
      pending.push(other);
    }
  }
  return seen;
}
