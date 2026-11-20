import type { Random } from '../battle/types.js';
import {
  type BlockLine,
  addLineHexes,
  worldLines,
} from '../islands/blocked-hexes.js';
import { flatCenter, gridCoord } from '../islands/hex-pixels.js';
import { type HexCoord, hexKey, hexNeighbors } from './hex.js';

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
}

interface RockKind {
  propTypeId: number;
  variants: number[];
  /** A linha fechada do pé, igual à de `prop_type_blocks` (migration giant_rocks). */
  points: number[];
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
  const byKey = new Map(tiles.map((tile) => [hexKey(tile), tile]));
  const links = bridgeLinks(bridges);
  const startKey = hexKey(start);
  const blocked = new Set<string>();
  const reach = reachable(byKey, links, startKey, blocked);
  const mountains = tiles.filter(({ shape }) => shape === 'mont');
  const order = mountains
    .map((tile) => ({ tile, roll: random() }))
    .sort((a, b) => a.roll - b.roll)
    .map(({ tile }) => tile);
  const props: GeneratedProp[] = [];
  for (const tile of order) {
    if (random() >= ROCK_CHANCE) continue;
    const kinds = ROCKS_BY_BIOME[tile.biome] ?? ROCKS_BY_BIOME.other!;
    const kind = kinds[Math.floor(random() * kinds.length)]!;
    const variant = kind.variants[Math.floor(random() * kind.variants.length)]!;
    const mirrored = random() < 0.5;
    const prop = rockAt(tile, kind, variant, mirrored);
    const hexes = rockHexes(prop);
    if (!fits(hexes, byKey, blocked, startKey)) continue;
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
    ...hexNeighbors(byKey.get(key)!).map(hexKey),
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
    block: [{ closed: true, points: [...kind.points] }],
  };
}

function fits(
  hexes: Set<string>,
  byKey: ReadonlyMap<string, RockTile>,
  blocked: ReadonlySet<string>,
  startKey: string,
): boolean {
  for (const key of hexes) {
    const tile = byKey.get(key);
    if (!tile || tile.shape !== 'mont' || key === startKey) return false;
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

/** A terra que se alcança da chegada, andando e pelas pontes, fora de `blocked`. */
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
    const tile = byKey.get(key)!;
    const next = [...hexNeighbors(tile).map(hexKey), ...(links.get(key) ?? [])];
    for (const other of next) {
      const neighbor = byKey.get(other);
      if (!neighbor || seen.has(other) || blocked.has(other)) continue;
      if (neighbor.biome === 'wshallow' || neighbor.biome === 'wdeep') continue;
      seen.add(other);
      pending.push(other);
    }
  }
  return seen;
}
