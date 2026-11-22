import { createHash } from 'node:crypto';
import { type HexCoord, hexKey, hexNeighbors } from './hex.js';
import { DEFAULT_MAP_CONFIG, type MapConfig } from './map-config.js';
import {
  type GeneratedMap,
  generateMap,
  generateShapedMap,
  type ShapedMap,
} from './map-generator.js';
import {
  BASALT_SPIRE_TYPES,
  bridgeLinks,
  LAVA_CRACK_TYPE,
  reachable,
  rockHexes,
} from './map-rocks.js';
import { climbable } from './map-slopes.js';
import { FLOOR_HEIGHT, LAVA_HEIGHT, RIM_HEIGHT } from './map-volcano.js';

const SEEDS = Array.from({ length: 6 }, (_, index) => index * 7919 + 5);
const WARM: MapConfig = {
  ...DEFAULT_MAP_CONFIG,
  tileCount: 10000,
  climate: 1,
  volcanoChance: 1,
  volcanoIslandChance: 0,
};
const SLOW = 120_000;
const CONE = new Set(['volcano', 'lshallow', 'ldeep']);
const LAVA = new Set(['lshallow', 'ldeep']);
const WATER = new Set(['wshallow', 'wdeep']);

interface Sample {
  map: ShapedMap;
  plain: ShapedMap;
}

function walkOf(
  map: ShapedMap | GeneratedMap,
  extra: ReadonlySet<string> = new Set(),
) {
  const byKey = new Map(
    map.tiles.map((tile) => [hexKey(tile), { ...tile, shape: 'flat' }]),
  );
  const blocked = new Set([
    ...map.props.flatMap((prop) => [...rockHexes(prop)]),
    ...extra,
  ]);
  return reachable(byKey, bridgeLinks(map.bridges), hexKey(map.start), blocked);
}

/**
 * Andando de `from` (a pé, sem paredão, sem água nem lava, fora de `blocked`): o que se
 * alcança. Parte da terra em volta do cone, porque a chegada de um mapa pode ficar
 * presa numa faixa de praia (um caso do gerador de antes do vulcão).
 */
function spread(
  map: ShapedMap,
  from: readonly HexCoord[],
  blocked: ReadonlySet<string>,
): Set<string> {
  const byKey = new Map(map.tiles.map((tile) => [hexKey(tile), tile]));
  const seen = new Set(from.map(hexKey));
  const pending = [...seen];
  while (pending.length > 0) {
    const tile = byKey.get(pending.pop()!)!;
    for (const next of hexNeighbors(tile)) {
      const key = hexKey(next);
      const other = byKey.get(key);
      if (!other || seen.has(key) || blocked.has(key)) continue;
      if (['wshallow', 'wdeep', 'lshallow', 'ldeep'].includes(other.biome))
        continue;
      if (!climbable(tile, other)) continue;
      seen.add(key);
      pending.push(key);
    }
  }
  return seen;
}

/** A terra encostada no cone, de fora dele. */
function aroundCone(map: ShapedMap): HexCoord[] {
  const cone = new Set(
    map.tiles.filter(({ biome }) => CONE.has(biome)).map(hexKey),
  );
  return map.tiles.filter(
    (tile) =>
      !cone.has(hexKey(tile)) &&
      !['wshallow', 'wdeep'].includes(tile.biome) &&
      hexNeighbors(tile).some((next) => cone.has(hexKey(next))),
  );
}

function rocksOf(map: ShapedMap): Set<string> {
  return new Set(map.props.flatMap((prop) => [...rockHexes(prop)]));
}

function hashOf(map: GeneratedMap): string {
  const { start, tiles, bridges, props, inland } = map;
  return createHash('sha256')
    .update(JSON.stringify({ start, tiles, bridges, props, inland }))
    .digest('hex')
    .slice(0, 16);
}

describe('placeVolcano (volcano/04)', () => {
  let samples: Sample[];

  beforeAll(() => {
    samples = SEEDS.map((seed) => ({
      map: generateShapedMap(seed, WARM),
      plain: generateShapedMap(seed, { ...WARM, volcanoChance: 0 }),
    })).filter(({ map }) => map.tiles.some(({ biome }) => CONE.has(biome)));
  }, SLOW);

  it('com a chance em 1, quase todo mapa que não é frio ganha o vulcão', () => {
    expect(samples.length / SEEDS.length).toBeGreaterThanOrEqual(0.8);
  });

  it('o mapa frio nunca tem vulcão', () => {
    for (const seed of SEEDS.slice(0, 3)) {
      const map = generateShapedMap(seed, { ...WARM, climate: 2 });
      expect(map.tiles.some(({ biome }) => CONE.has(biome))).toBe(false);
    }
  });

  it('tem a borda no 10, o piso no 6 e a lava no 5, só dentro da cratera', () => {
    for (const { map } of samples) {
      const byKey = new Map(map.tiles.map((tile) => [hexKey(tile), tile]));
      const cone = map.tiles.filter(({ biome }) => CONE.has(biome));
      const heights = new Set(cone.map(({ height }) => height));
      expect(heights.has(RIM_HEIGHT)).toBe(true);
      expect(heights.has(FLOOR_HEIGHT)).toBe(true);
      for (const tile of cone.filter(({ biome }) => LAVA.has(biome))) {
        expect(tile.height).toBe(LAVA_HEIGHT);
        for (const next of hexNeighbors(tile)) {
          const other = byKey.get(hexKey(next))!;
          // A lava só encosta em lava ou no piso da cratera.
          if (!LAVA.has(other.biome)) {
            expect(other).toMatchObject({
              biome: 'volcano',
              height: FLOOR_HEIGHT,
            });
          }
          if (tile.biome === 'ldeep') expect(LAVA.has(other.biome)).toBe(true);
        }
      }
    }
  });

  it('o piso da cratera se alcança da terra de fora pelas escadarias', () => {
    for (const { map } of samples) {
      const rocks = rocksOf(map);
      const reach = spread(map, aroundCone(map), rocks);
      const floor = map.tiles.filter(
        (tile) =>
          tile.biome === 'volcano' &&
          tile.height === FLOOR_HEIGHT &&
          hexNeighbors(tile).some((next) =>
            map.tiles.some(
              (other) =>
                hexKey(other) === hexKey(next) && LAVA.has(other.biome),
            ),
          ),
      );
      expect(floor.length).toBeGreaterThan(0);
      for (const tile of floor) {
        if (rocks.has(hexKey(tile))) continue;
        expect(reach.has(hexKey(tile)), hexKey(tile)).toBe(true);
      }
    }
  });

  it('sem as escadarias, a borda não se alcança de fora', () => {
    for (const { map } of samples) {
      expect(map.volcanoStairs.length).toBeGreaterThan(0);
      const stairs = new Set(map.volcanoStairs.map(hexKey));
      const reach = spread(
        map,
        aroundCone(map).filter((tile) => !stairs.has(hexKey(tile))),
        new Set([...rocksOf(map), ...stairs]),
      );
      const rim = map.tiles.filter(
        ({ biome, height }) => biome === 'volcano' && height === RIM_HEIGHT,
      );
      expect(rim.filter((tile) => reach.has(hexKey(tile)))).toEqual([]);
    }
  });

  it('toda terra que se alcançava continua alcançável', () => {
    for (const { map, plain } of samples) {
      const before = walkOf(plain);
      const after = walkOf(map);
      const cone = new Set(
        map.tiles.filter(({ biome }) => CONE.has(biome)).map(hexKey),
      );
      const lost = [...before].filter(
        (key) => !cone.has(key) && !after.has(key),
      );
      expect(lost).toEqual([]);
    }
  });

  it(
    'um cone grande não cobre nem rebaixa água, Montanha ou terreno de 8 para cima',
    () => {
      const big: MapConfig = {
        ...WARM,
        volcanoMinRadius: 14,
        volcanoMaxRadius: 20,
        lakeCount: 0,
        riverCount: 0,
      };
      let cones = 0;
      // A 39.600 é a que o cone grande quebrava antes da conferência em linha reta.
      for (const seed of [39600, 7924, 23762]) {
        const map = generateShapedMap(seed, big);
        const plain = generateShapedMap(seed, { ...big, volcanoChance: 0 });
        if (!map.tiles.some(({ biome }) => CONE.has(biome))) continue;
        cones += 1;
        const after = new Map(map.tiles.map((tile) => [hexKey(tile), tile]));
        for (const tile of plain.tiles) {
          const kept =
            WATER.has(tile.biome) || tile.shape === 'mont' || tile.height >= 8;
          if (!kept) continue;
          const now = after.get(hexKey(tile))!;
          expect([now.biome, now.height], hexKey(tile)).toEqual([
            tile.biome,
            tile.height,
          ]);
        }
      }
      expect(cones).toBeGreaterThan(0);
    },
    SLOW,
  );

  it('fora do cone e da terra encostada nele, os biomas ficam iguais', () => {
    for (const { map, plain } of samples) {
      const near = new Set<string>();
      for (const tile of map.tiles) {
        if (!CONE.has(tile.biome)) continue;
        near.add(hexKey(tile));
        for (const next of hexNeighbors(tile)) near.add(hexKey(next));
      }
      const before = new Map(plain.tiles.map((tile) => [hexKey(tile), tile]));
      for (const tile of map.tiles) {
        if (near.has(hexKey(tile))) continue;
        expect(tile.biome).toBe(before.get(hexKey(tile))!.biome);
      }
      expect(map.start).toEqual(plain.start);
      expect(map.bridges).toEqual(plain.bridges);
    }
  });

  it('os picos e as rachaduras ficam no cone, fora das escadarias', () => {
    for (const { map } of samples) {
      const byKey = new Map(map.tiles.map((tile) => [hexKey(tile), tile]));
      const stairs = new Set(map.volcanoStairs.map(hexKey));
      const mine = map.props.filter(
        ({ propTypeId }) =>
          BASALT_SPIRE_TYPES.includes(propTypeId) ||
          propTypeId === LAVA_CRACK_TYPE,
      );
      expect(mine.length).toBeGreaterThan(0);
      for (const prop of mine) {
        for (const key of rockHexes(prop)) {
          const tile = byKey.get(key)!;
          expect(tile.biome).toBe('volcano');
          expect(stairs.has(key)).toBe(false);
          if (prop.propTypeId === LAVA_CRACK_TYPE) {
            expect(tile.height).not.toBe(RIM_HEIGHT);
          } else {
            expect(tile.height).not.toBe(FLOOR_HEIGHT);
          }
        }
      }
    }
  });

  it(
    'com a chance em 0, o mapa de 5 seeds é o do commit da fase 3',
    () => {
      const before: Record<number, string> = {
        11: 'f08dcb2ad8d7e372',
        104740: 'de3a95e7d6794e81',
        209469: 'e83c5634323f11ab',
        314198: 'efa306902e2a149e',
        // A start-island/01 levou a chegada para o pedaço maior, do outro lado do mar.
        418927: '4273bba486e0f68d',
      };
      for (const [seed, hash] of Object.entries(before)) {
        const map = generateMap(Number(seed), {
          ...DEFAULT_MAP_CONFIG,
          volcanoChance: 0,
          volcanoIslandChance: 0,
        });
        expect(hashOf(map), seed).toBe(hash);
      }
    },
    SLOW,
  );
});
