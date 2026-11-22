import { hexKey, hexNeighbors } from './hex.js';
import { DEFAULT_MAP_CONFIG, type MapConfig } from './map-config.js';
import {
  generateShapedMap,
  isVolcanicIsland,
  type ShapedMap,
} from './map-generator.js';
import { rockHexes } from './map-rocks.js';
import { climbable } from './map-slopes.js';
import { FLOOR_HEIGHT, LAVA_HEIGHT, RIM_HEIGHT } from './map-volcano.js';

const SEEDS = [3, 11, 29, 47];
const ISLAND: MapConfig = { ...DEFAULT_MAP_CONFIG, volcanoIslandChance: 1 };
const SLOW = 120_000;
const WATER = new Set(['wshallow', 'wdeep']);
const LAVA = new Set(['lshallow', 'ldeep']);
const CONE = new Set(['volcano', ...LAVA]);
const ALLOWED = new Set([...WATER, ...CONE, 'beach', 'temperate', 'boreal']);

/** O que se alcança a pé de `from`, sem paredão, água, lava nem os hexágonos de `blocked`. */
function spread(
  map: ShapedMap,
  from: string,
  blocked: ReadonlySet<string>,
): Set<string> {
  const byKey = new Map(map.tiles.map((tile) => [hexKey(tile), tile]));
  const seen = new Set([from]);
  const pending = [from];
  while (pending.length > 0) {
    const tile = byKey.get(pending.pop()!)!;
    for (const next of hexNeighbors(tile)) {
      const key = hexKey(next);
      const other = byKey.get(key);
      if (!other || seen.has(key) || blocked.has(key)) continue;
      if (WATER.has(other.biome) || LAVA.has(other.biome)) continue;
      if (!climbable(tile, other)) continue;
      seen.add(key);
      pending.push(key);
    }
  }
  return seen;
}

function groups(map: ShapedMap, inside: (biome: string) => boolean): number {
  const byKey = new Map(map.tiles.map((tile) => [hexKey(tile), tile]));
  const seen = new Set<string>();
  let count = 0;
  for (const tile of map.tiles) {
    if (!inside(tile.biome) || seen.has(hexKey(tile))) continue;
    count += 1;
    const pending = [hexKey(tile)];
    seen.add(hexKey(tile));
    while (pending.length > 0) {
      for (const next of hexNeighbors(byKey.get(pending.pop()!)!)) {
        const key = hexKey(next);
        const other = byKey.get(key);
        if (!other || seen.has(key) || !inside(other.biome)) continue;
        seen.add(key);
        pending.push(key);
      }
    }
  }
  return count;
}

describe('a ilha vulcânica (volcano/05)', () => {
  let maps: ShapedMap[];

  beforeAll(() => {
    maps = SEEDS.map((seed) => generateShapedMap(seed, ISLAND));
  }, SLOW);

  it('sai em perto de 2% das seeds, e nunca com o clima fixado em Frio', () => {
    const seeds = Array.from({ length: 4000 }, (_, index) => index * 31 + 7);
    const share =
      seeds.filter((seed) => isVolcanicIsland(seed, DEFAULT_MAP_CONFIG))
        .length / seeds.length;
    expect(share).toBeGreaterThanOrEqual(0.01);
    expect(share).toBeLessThanOrEqual(0.035);
    expect(
      seeds.some((seed) => isVolcanicIsland(seed, { ...ISLAND, climate: 2 })),
    ).toBe(false);
  });

  it('a terra é uma ilha só, cercada de água, sem lago, rio nem ponte', () => {
    for (const map of maps) {
      const byKey = new Map(map.tiles.map((tile) => [hexKey(tile), tile]));
      expect(groups(map, (biome) => !WATER.has(biome))).toBe(1);
      expect(groups(map, (biome) => WATER.has(biome))).toBe(1);
      for (const tile of map.tiles) {
        const onEdge = hexNeighbors(tile).some(
          (next) => !byKey.has(hexKey(next)),
        );
        if (onEdge) expect(WATER.has(tile.biome)).toBe(true);
      }
      expect(map.bridges).toEqual([]);
      expect(map.lakes).toEqual([]);
      expect(map.rivers).toEqual([]);
    }
  });

  it('tem só a água, a Praia, o cinto de floresta e o Vulcão', () => {
    for (const map of maps) {
      for (const tile of map.tiles) expect(ALLOWED.has(tile.biome)).toBe(true);
      expect(map.tiles.some(({ shape }) => shape !== 'flat')).toBe(false);
    }
  });

  it('a Praia faz a costa, e o cinto tem pelo menos 3 hexágonos', () => {
    for (const map of maps) {
      const byKey = new Map(map.tiles.map((tile) => [hexKey(tile), tile]));
      const fromBeach = new Map<string, number>();
      let layer = map.tiles
        .filter(({ biome }) => biome === 'beach')
        .map(hexKey);
      for (const key of layer) fromBeach.set(key, 0);
      for (let step = 1; layer.length > 0; step += 1) {
        const next: string[] = [];
        for (const key of layer) {
          for (const coord of hexNeighbors(byKey.get(key)!)) {
            const other = hexKey(coord);
            if (!byKey.has(other) || fromBeach.has(other)) continue;
            fromBeach.set(other, step);
            next.push(other);
          }
        }
        layer = next;
      }
      for (const tile of map.tiles) {
        if (WATER.has(tile.biome)) continue;
        const coast = hexNeighbors(tile).some((next) =>
          WATER.has(byKey.get(hexKey(next))?.biome ?? 'wdeep'),
        );
        if (coast) expect(tile.biome).toBe('beach');
        if (CONE.has(tile.biome)) {
          expect(fromBeach.get(hexKey(tile))!).toBeGreaterThan(3);
        }
      }
    }
  });

  it('a terra é de 45% a 62% do mapa, e o cone, de 35% a 62% da terra', () => {
    for (const map of maps) {
      const land = map.tiles.filter(({ biome }) => !WATER.has(biome));
      const cone = land.filter(({ biome }) => CONE.has(biome));
      expect(land.length / map.tiles.length).toBeGreaterThanOrEqual(0.45);
      expect(land.length / map.tiles.length).toBeLessThanOrEqual(0.62);
      expect(cone.length / land.length).toBeGreaterThanOrEqual(0.35);
      expect(cone.length / land.length).toBeLessThanOrEqual(0.62);
    }
  });

  it('o cone tem a borda no 10, o piso no 6 e a lava no 5', () => {
    for (const map of maps) {
      const cone = map.tiles.filter(({ biome }) => CONE.has(biome));
      const heights = new Set(cone.map(({ height }) => height));
      expect(heights.has(RIM_HEIGHT)).toBe(true);
      expect(heights.has(FLOOR_HEIGHT)).toBe(true);
      for (const tile of cone.filter(({ biome }) => LAVA.has(biome))) {
        expect(tile.height).toBe(LAVA_HEIGHT);
      }
    }
  });

  it('da chegada se alcança toda a terra de fora do cone e o piso da cratera; sem as escadarias, a borda não', () => {
    for (const map of maps) {
      const start = map.tiles.find(
        ({ q, r }) => q === map.start.q && r === map.start.r,
      )!;
      expect(['temperate', 'boreal']).toContain(start.biome);
      const rocks = new Set(map.props.flatMap((prop) => [...rockHexes(prop)]));
      const reach = spread(map, hexKey(start), rocks);
      for (const tile of map.tiles) {
        if (WATER.has(tile.biome) || CONE.has(tile.biome)) continue;
        expect(reach.has(hexKey(tile)), hexKey(tile)).toBe(true);
      }
      const floor = map.tiles.filter(
        (tile) =>
          tile.biome === 'volcano' &&
          tile.height === FLOOR_HEIGHT &&
          !rocks.has(hexKey(tile)),
      );
      expect(floor.some((tile) => reach.has(hexKey(tile)))).toBe(true);
      expect(map.volcanoStairs.length).toBeGreaterThanOrEqual(3);
      const closed = spread(
        map,
        hexKey(start),
        new Set([...rocks, ...map.volcanoStairs.map(hexKey)]),
      );
      const rim = map.tiles.filter(
        ({ biome, height }) => biome === 'volcano' && height === RIM_HEIGHT,
      );
      expect(rim.filter((tile) => closed.has(hexKey(tile)))).toEqual([]);
    }
  });
});
