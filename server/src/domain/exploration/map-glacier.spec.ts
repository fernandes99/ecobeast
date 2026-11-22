import { createHash } from 'node:crypto';
import { type HexCoord, hexDistance, hexKey, hexNeighbors } from './hex.js';
import { DEFAULT_MAP_CONFIG, type MapConfig } from './map-config.js';
import { type GeneratedMap, generateMap, isWater } from './map-generator.js';
import {
  bridgeLinks,
  ICE_ROCK_TYPES,
  reachable,
  rockHexes,
} from './map-rocks.js';
import { assignZones, type MapZone } from './map-zones.js';

const SEEDS = Array.from({ length: 400 }, (_, index) => index * 7919 + 5);
const COLD: MapConfig = { ...DEFAULT_MAP_CONFIG, tileCount: 2000, climate: 2 };
const SLOW = 120_000;

interface Glacier {
  map: GeneratedMap;
  land: HexCoord[];
  /** O mesmo mapa sem a Geleira. */
  plain: GeneratedMap;
}

function glacierOf(map: GeneratedMap): Glacier | null {
  const land = map.tiles.filter(({ biome }) => biome === 'glacier');
  if (land.length === 0) return null;
  const plain = generateMap(map.seed, { ...COLD, glacierChance: 0 });
  return { map, land, plain };
}

/** A terra que se alcança da chegada sem paredão, pelas pontes e fora das pedras. */
function reachOf(map: GeneratedMap): Set<string> {
  const byKey = new Map(
    map.tiles.map((tile) => [hexKey(tile), { ...tile, shape: 'flat' }]),
  );
  const rocks = new Set(map.props.flatMap((prop) => [...rockHexes(prop)]));
  return reachable(byKey, bridgeLinks(map.bridges), hexKey(map.start), rocks);
}

function hashOf(map: GeneratedMap): string {
  const { start, tiles, bridges, props, inland } = map;
  return createHash('sha256')
    .update(JSON.stringify({ start, tiles, bridges, props, inland }))
    .digest('hex')
    .slice(0, 16);
}

describe('placeGlacier (glacier/04)', () => {
  let glaciers: Glacier[];

  beforeAll(() => {
    glaciers = SEEDS.map((seed) => generateMap(seed, COLD))
      .map(glacierOf)
      .filter((glacier): glacier is Glacier => glacier !== null);
  }, SLOW);

  it('sai em 15% a 35% dos mapas frios', () => {
    const share = glaciers.length / SEEDS.length;
    expect(share).toBeGreaterThanOrEqual(0.15);
    expect(share).toBeLessThanOrEqual(0.35);
  });

  it('tem de glacierMin a glacierMax hexágonos de terra', () => {
    for (const { land } of glaciers) {
      expect(land.length).toBeGreaterThanOrEqual(COLD.glacierMin);
      expect(land.length).toBeLessThanOrEqual(COLD.glacierMax);
    }
  });

  it('só encosta na Neve, em si mesma e no lago dela', () => {
    for (const { map } of glaciers) {
      const byKey = new Map(map.tiles.map((tile) => [hexKey(tile), tile]));
      const lake = new Set(map.iceLake.map(hexKey));
      for (const tile of map.tiles.filter(({ biome }) => biome === 'glacier')) {
        for (const next of hexNeighbors(tile)) {
          const other = byKey.get(hexKey(next));
          expect(other, `beira do mapa em ${hexKey(tile)}`).toBeDefined();
          const ok =
            other!.biome === 'glacier' ||
            other!.biome === 'snow' ||
            lake.has(hexKey(next));
          expect(ok, `${other!.biome} ao lado da Geleira`).toBe(true);
        }
      }
    }
  });

  it(
    'o lago sai em parte das Geleiras, e só com o sorteio dele',
    () => {
      // No tamanho do jogo (10.000 hexágonos), 38% das Geleiras saíram com lago. Aqui,
      // com 2.000, a Neve baixa é menor, então o teste confere onde o lago cabe.
      const withLake = glaciers.filter(({ map }) => map.iceLake.length > 0);
      expect(withLake.length / glaciers.length).toBeLessThanOrEqual(0.7);
      const always = glaciers.map(({ map }) =>
        generateMap(map.seed, { ...COLD, glacierLakeChance: 1 }),
      );
      const fits = always.filter((map) => map.iceLake.length > 0).length;
      expect(fits / always.length).toBeGreaterThanOrEqual(0.25);
      for (const { map } of glaciers.slice(0, 10)) {
        const never = generateMap(map.seed, { ...COLD, glacierLakeChance: 0 });
        expect(never.iceLake).toEqual([]);
      }
    },
    SLOW,
  );

  it('o lago é redondo, cercado pela Geleira, com a água funda só no de raio 2', () => {
    for (const { map } of glaciers.filter(({ map }) => map.iceLake.length)) {
      const byKey = new Map(map.tiles.map((tile) => [hexKey(tile), tile]));
      const lake = map.iceLake;
      expect([7, 19]).toContain(lake.length);
      const radius = lake.length === 19 ? 2 : 1;
      const center = lake.find((cell) =>
        lake.every((other) => hexDistance(cell, other) <= radius),
      )!;
      expect(center).toBeDefined();
      const keys = new Set(lake.map(hexKey));
      for (const cell of lake) {
        const tile = byKey.get(hexKey(cell))!;
        expect(tile.height).toBe(0);
        const deep = radius === 2 && hexDistance(cell, center) <= 1;
        expect(tile.biome).toBe(deep ? 'wdeep' : 'wshallow');
        for (const next of hexNeighbors(cell)) {
          if (keys.has(hexKey(next))) continue;
          expect(byKey.get(hexKey(next))?.biome).toBe('glacier');
        }
      }
    }
  });

  it(
    'a chegada não cai na Geleira nem no lago, e a terra que se alcançava continua alcançável',
    () => {
      for (const { map, plain } of glaciers) {
        const start = map.tiles.find(
          (tile) => hexKey(tile) === hexKey(map.start),
        )!;
        expect(start.biome).not.toBe('glacier');
        expect(isWater(start.biome)).toBe(false);
        const before = reachOf(plain);
        const after = reachOf(map);
        const rocks = new Set(
          map.props.flatMap((prop) => [...rockHexes(prop)]),
        );
        const lake = new Set(map.iceLake.map(hexKey));
        const lost = [...before].filter(
          (key) => !after.has(key) && !rocks.has(key) && !lake.has(key),
        );
        expect(lost).toEqual([]);
      }
    },
    SLOW,
  );

  it('as pedras de gelo só caem na Geleira', () => {
    let count = 0;
    for (const { map } of glaciers) {
      const byKey = new Map(map.tiles.map((tile) => [hexKey(tile), tile]));
      for (const prop of map.props) {
        const ice = ICE_ROCK_TYPES.includes(prop.propTypeId);
        for (const key of rockHexes(prop)) {
          const biome = byKey.get(key)?.biome;
          if (ice) expect(biome).toBe('glacier');
          else expect(biome).toBe('mountain');
        }
        if (ice) count += 1;
      }
    }
    expect(count).toBeGreaterThan(0);
  });

  it('o lago fica na zona Lago gelado, e não no Lago', () => {
    const zones: MapZone[] = [
      { slug: 'wshallow', biome: 'wshallow', share: 100, sortOrder: 1 },
      { slug: 'wdeep', biome: 'wdeep', share: 100, sortOrder: 1 },
      { slug: 'wshallow_lake', biome: 'wshallow', share: 0, sortOrder: 5 },
      { slug: 'wdeep_lake', biome: 'wdeep', share: 0, sortOrder: 5 },
      { slug: 'wshallow_ice_lake', biome: 'wshallow', share: 0, sortOrder: 6 },
      { slug: 'wdeep_ice_lake', biome: 'wdeep', share: 0, sortOrder: 6 },
    ];
    const { map } = glaciers.find(({ map }) => map.iceLake.length === 19)!;
    const tiles = assignZones(
      map.tiles,
      map.seed,
      zones,
      COLD,
      map.inland,
      map.iceLake,
    );
    const lake = new Set(map.iceLake.map(hexKey));
    for (const tile of tiles) {
      if (lake.has(hexKey(tile))) {
        expect(tile.zone).toBe(`${tile.biome}_ice_lake`);
      } else {
        expect(tile.zone ?? '').not.toMatch(/_ice_lake$/);
      }
    }
  });

  it('fora da mancha, o mapa é o mesmo sem a Geleira', () => {
    for (const { map, plain } of glaciers) {
      const patch = new Set([
        ...map.tiles.filter(({ biome }) => biome === 'glacier').map(hexKey),
        ...map.iceLake.map(hexKey),
      ]);
      const changed = plain.tiles.filter((tile, index) => {
        const now = map.tiles[index]!;
        return (
          !patch.has(hexKey(tile)) &&
          (now.biome !== tile.biome || now.height !== tile.height)
        );
      });
      expect(changed).toEqual([]);
      expect(map.bridges).toEqual(plain.bridges);
      expect(
        map.props.filter(
          ({ propTypeId }) => !ICE_ROCK_TYPES.includes(propTypeId),
        ),
      ).toEqual(plain.props);
    }
  });
});

describe('a Geleira fora do frio (glacier/04)', () => {
  it.each([1, 3, 4])('nenhum mapa do clima %i tem Geleira', (climate) => {
    const config = {
      ...COLD,
      tileCount: 600,
      climate,
      glacierChance: 1,
    };
    for (const seed of SEEDS.slice(0, 30)) {
      const map = generateMap(seed, config);
      expect(map.tiles.some(({ biome }) => biome === 'glacier')).toBe(false);
      expect(map.iceLake).toEqual([]);
    }
  });

  it('com glacierChance em 0, o mapa de 5 seeds é o de antes', () => {
    // As impressões vêm do map-generator.ts de antes da Geleira (glacier 03).
    const before: Record<number, string> = {
      11: 'ccdc03c7e2487386',
      2024: '99ef71e5c3104bcd',
      31337: '92fee27c12bbbe10',
      77777: '5a1c9f130b7bc05e',
      123456: '9b6a89b6758d81c9',
    };
    for (const [seed, hash] of Object.entries(before)) {
      const map = generateMap(Number(seed), { ...COLD, glacierChance: 0 });
      expect(hashOf(map), seed).toBe(hash);
    }
  });
});
