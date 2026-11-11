import { hexKey, hexNeighbors } from './hex.js';
import { DEFAULT_MAP_CONFIG, MapConfig } from './map-config.js';
import {
  BIOMES,
  generateMap,
  generateShapedMap,
  isWater,
  MAX_HEIGHT,
  maxVariant,
  SHAPED_BIOMES,
  ShapedBiome,
  ShapedMap,
  ShapedTile,
  TERRAIN_SHAPES,
  terrainOf,
} from './map-generator.js';

const SEEDS = Array.from({ length: 200 }, (_, index) => index * 7919 + 1);
const MAX_LONELY_LAND = 0.05;
/** A grama é a base da região; nenhum bioma deve ir além disto. */
const MAX_BIOME_SHARE = 0.6;
/**
 * Fixa, separada de `DEFAULT_MAP_CONFIG`: o dono ajusta os valores do jogo sem
 * reprovar estes testes, que conferem o algoritmo, e não o balanceamento.
 */
const CONFIG: MapConfig = {
  tileCount: 300,
  edgeRoughness: 7,
  noiseScale: 0.14,
  waterFraction: 0.22,
  deepFraction: 0.4,
  wetLimit: 0.6,
  stoneFraction: 0.15,
  hillFrom: 0.8,
  mountainFrom: 0.9,
  islandChance: 0.04,
  detailChance: 0.2,
  cleanupPasses: 3,
};

function indexed(map: ShapedMap): Map<string, ShapedTile> {
  return new Map(map.tiles.map((tile) => [hexKey(tile), tile]));
}

function neighborsOf(
  tile: ShapedTile,
  byKey: Map<string, ShapedTile>,
): ShapedTile[] {
  return hexNeighbors(tile).flatMap((coord) => {
    const neighbor = byKey.get(hexKey(coord));
    return neighbor ? [neighbor] : [];
  });
}

function reachableFrom(map: ShapedMap): number {
  const byKey = indexed(map);
  const seen = new Set([hexKey(map.tiles[0]!)]);
  const pending = [map.tiles[0]!];
  while (pending.length > 0) {
    for (const neighbor of neighborsOf(pending.pop()!, byKey)) {
      if (!seen.has(hexKey(neighbor))) {
        seen.add(hexKey(neighbor));
        pending.push(neighbor);
      }
    }
  }
  return seen.size;
}

const waterShare = (map: ShapedMap) =>
  map.tiles.filter((tile) => isWater(tile.biome)).length / map.tiles.length;

describe('generateShapedMap', () => {
  let maps: ShapedMap[];

  beforeAll(() => {
    maps = SEEDS.map((seed) => generateShapedMap(seed, CONFIG));
  });

  it('só existem as cinco regiões', () => {
    expect([...SHAPED_BIOMES].sort()).toEqual(
      ['boreal', 'stone', 'temperate', 'wdeep', 'wshallow'].sort(),
    );
  });

  it('a configuração do jogo gera um mapa válido', () => {
    const map = generateShapedMap(1);
    expect(map.tiles).toHaveLength(DEFAULT_MAP_CONFIG.tileCount);
    expect(new Set(map.tiles.map(hexKey)).size).toBe(map.tiles.length);
    for (const tile of map.tiles) {
      expect(SHAPED_BIOMES).toContain(tile.biome);
      expect(TERRAIN_SHAPES).toContain(tile.shape);
    }
    const start = indexed(map).get(hexKey(map.start));
    expect(isWater(start!.biome)).toBe(false);
    expect(start!.shape).toBe('flat');
  });

  it('devolve a seed recebida', () => {
    expect(generateShapedMap(123, CONFIG).seed).toBe(123);
  });

  it('a mesma seed dá o mesmo mapa', () => {
    expect(generateShapedMap(555, CONFIG)).toEqual(
      generateShapedMap(555, CONFIG),
    );
  });

  it('seeds diferentes dão mapas diferentes', () => {
    expect(generateShapedMap(555, CONFIG).tiles).not.toEqual(
      generateShapedMap(556, CONFIG).tiles,
    );
  });

  it('o recorte do mapa muda com a seed', () => {
    const shape = (map: ShapedMap) => map.tiles.map(hexKey).sort().join('|');
    expect(new Set(maps.map(shape)).size).toBeGreaterThan(190);
  });

  it('tem a quantidade pedida, sem posições repetidas', () => {
    for (const map of maps) {
      expect(map.tiles).toHaveLength(CONFIG.tileCount);
      expect(new Set(map.tiles.map(hexKey)).size).toBe(map.tiles.length);
    }
  });

  it('muda de tamanho com `tileCount`', () => {
    const config = { ...CONFIG, tileCount: 120 };
    expect(generateShapedMap(9, config).tiles).toHaveLength(120);
  });

  it('todas as posições são alcançáveis', () => {
    for (const map of maps) {
      expect(reachableFrom(map)).toBe(map.tiles.length);
    }
  });

  it('só usa biomas, formas e variantes que têm sprite', () => {
    // Um `expect` por tile estoura o tempo do teste: são milhares em cada mapa.
    const withoutSprite = maps
      .flatMap(({ tiles }) => tiles)
      .filter(
        ({ biome, shape, variant }) =>
          !SHAPED_BIOMES.includes(biome) ||
          !TERRAIN_SHAPES.includes(shape) ||
          variant < 1 ||
          variant > (shape === 'flat' ? 6 : 3),
      );
    expect(withoutSprite).toEqual([]);
  });

  it('água funda só encosta em água', () => {
    for (const map of maps) {
      const byKey = indexed(map);
      for (const tile of map.tiles.filter(({ biome }) => biome === 'wdeep')) {
        for (const neighbor of neighborsOf(tile, byKey)) {
          expect(isWater(neighbor.biome)).toBe(true);
        }
      }
    }
  });

  it('os biomas de terra formam grupos', () => {
    for (const map of maps) {
      const byKey = indexed(map);
      const land = map.tiles.filter((tile) => !isWater(tile.biome));
      const lonely = land.filter(
        (tile) =>
          !neighborsOf(tile, byKey).some(({ biome }) => biome === tile.biome),
      );
      expect(lonely.length / land.length).toBeLessThan(MAX_LONELY_LAND);
    }
  });

  it('as montanhas de terra formam conjuntos', () => {
    for (const map of maps) {
      const byKey = indexed(map);
      const mountains = map.tiles.filter(
        (tile) => tile.shape === 'mont' && !isWater(tile.biome),
      );
      for (const tile of mountains) {
        expect(
          neighborsOf(tile, byKey).some(({ shape }) => shape === 'mont'),
        ).toBe(true);
      }
    }
  });

  it('começa em terra plana, dentro do mapa', () => {
    for (const map of maps) {
      const start = indexed(map).get(hexKey(map.start));
      expect(start).toBeDefined();
      expect(isWater(start!.biome)).toBe(false);
      expect(start!.shape).toBe('flat');
    }
  });

  it('a terra é a maior parte de todo mapa', () => {
    for (const map of maps) {
      expect(waterShare(map)).toBeLessThan(0.5);
    }
  });

  it('a água fica perto de `waterFraction`', () => {
    const mean =
      maps.map(waterShare).reduce((sum, share) => sum + share) / maps.length;
    expect(mean).toBeGreaterThan(CONFIG.waterFraction - 0.03);
    expect(mean).toBeLessThan(CONFIG.waterFraction + 0.03);
  });

  it('aparecem todos os biomas ao longo das seeds', () => {
    const seen = new Set<ShapedBiome>(
      maps.flatMap(({ tiles }) => tiles.map((tile) => tile.biome)),
    );
    expect([...seen].sort()).toEqual([...SHAPED_BIOMES].sort());
  });

  it('nenhum bioma de terra é raridade ao longo das seeds', () => {
    for (const biome of SHAPED_BIOMES.filter((slug) => !isWater(slug))) {
      const containing = maps.filter(({ tiles }) =>
        tiles.some((tile) => tile.biome === biome),
      );
      expect(containing.length / maps.length).toBeGreaterThan(0.25);
    }
  });

  it('nenhum bioma domina os mapas', () => {
    for (const biome of SHAPED_BIOMES) {
      const tiles = maps.flatMap((map) => map.tiles);
      const share = tiles.filter((tile) => tile.biome === biome).length;
      expect(share / tiles.length).toBeLessThan(MAX_BIOME_SHARE);
    }
  });

  it('a pedra é uma região, com plano, colina e montanha', () => {
    const shapes = new Set(
      maps.flatMap(({ tiles }) =>
        tiles
          .filter(({ biome }) => biome === 'stone')
          .map((tile) => tile.shape),
      ),
    );
    expect([...shapes].sort()).toEqual([...TERRAIN_SHAPES].sort());
  });

  it('a pedra é principalmente chão plano', () => {
    const stone = maps.flatMap(({ tiles }) =>
      tiles.filter(({ biome }) => biome === 'stone'),
    );
    const flat = stone.filter(({ shape }) => shape === 'flat');
    expect(flat.length / stone.length).toBeGreaterThan(0.5);
  });

  it('a pedra fica perto de `stoneFraction` da terra', () => {
    const land = maps.flatMap(({ tiles }) =>
      tiles.filter(({ biome }) => !isWater(biome)),
    );
    const stone = land.filter(({ biome }) => biome === 'stone');
    expect(stone.length / land.length).toBeGreaterThan(
      CONFIG.stoneFraction - 0.05,
    );
    expect(stone.length / land.length).toBeLessThan(
      CONFIG.stoneFraction + 0.05,
    );
  });

  it('mais `stoneFraction` dá mais pedra', () => {
    const stoneCount = (config: MapConfig) =>
      generateShapedMap(9, config).tiles.filter(
        ({ biome }) => biome === 'stone',
      ).length;
    expect(stoneCount({ ...CONFIG, stoneFraction: 0.4 })).toBeGreaterThan(
      stoneCount(CONFIG),
    );
  });

  it('há montanhas em vários biomas de terra', () => {
    const biomes = new Set(
      maps.flatMap(({ tiles }) =>
        tiles
          .filter(({ shape, biome }) => shape === 'mont' && !isWater(biome))
          .map((tile) => tile.biome),
      ),
    );
    expect(biomes.size).toBe(3);
  });

  it('as ilhas são raras', () => {
    const water = maps.flatMap(({ tiles }) =>
      tiles.filter((tile) => isWater(tile.biome)),
    );
    const islands = water.filter((tile) => tile.shape !== 'flat');
    expect(islands.length).toBeGreaterThan(0);
    expect(islands.length / water.length).toBeLessThan(CONFIG.islandChance * 2);
  });

  it('mais `waterFraction` dá mais água', () => {
    const wetter: MapConfig = { ...CONFIG, waterFraction: 0.4 };
    expect(waterShare(generateShapedMap(9, wetter))).toBeGreaterThan(
      waterShare(generateShapedMap(9, CONFIG)),
    );
  });
});

describe('terrainOf', () => {
  it.each([
    ['temperate', 'flat', 'temperate', 1],
    ['boreal', 'flat', 'boreal', 1],
    ['stone', 'flat', 'stone', 3],
    ['wshallow', 'flat', 'wshallow', 0],
    ['wdeep', 'flat', 'wdeep', 0],
    ['temperate', 'hill', 'hill', 2],
    ['boreal', 'hill', 'hill', 2],
    ['stone', 'hill', 'hill', 3],
    ['wshallow', 'hill', 'hill', 2],
    ['temperate', 'mont', 'mountain', 4],
    ['stone', 'mont', 'mountain', 4],
    ['wdeep', 'mont', 'mountain', 4],
  ] as const)('%s com %s vira %s na altura %d', (biome, shape, to, height) => {
    expect(terrainOf(biome, shape)).toEqual({ biome: to, height });
  });
});

describe('generateMap', () => {
  let maps: ReturnType<typeof generateMap>[];

  beforeAll(() => {
    maps = SEEDS.slice(0, 40).map((seed) => generateMap(seed, CONFIG));
  });

  it('são os 7 biomas do catálogo', () => {
    expect([...BIOMES].sort()).toEqual(
      [
        'boreal',
        'hill',
        'mountain',
        'stone',
        'temperate',
        'wdeep',
        'wshallow',
      ].sort(),
    );
  });

  it('é o mapa com forma convertido, hexágono por hexágono', () => {
    const shaped = generateShapedMap(77, CONFIG);
    const map = generateMap(77, CONFIG);
    expect(map.seed).toBe(shaped.seed);
    expect(map.start).toEqual(shaped.start);
    expect(map.tiles).toEqual(
      shaped.tiles.map(({ q, r, biome, shape, variant }) => ({
        q,
        r,
        ...terrainOf(biome, shape),
        variant,
      })),
    );
  });

  it('todo hexágono tem bioma, altura e variante válidos', () => {
    const invalid = maps
      .flatMap(({ tiles }) => tiles)
      .filter(
        ({ biome, height, variant }) =>
          !BIOMES.includes(biome) ||
          !Number.isInteger(height) ||
          height < 0 ||
          height > MAX_HEIGHT ||
          variant < 1 ||
          variant > maxVariant(biome),
      );
    expect(invalid).toEqual([]);
  });

  it('cada bioma fica na altura de antes', () => {
    const heights = new Map<string, Set<number>>();
    for (const { biome, height } of maps.flatMap(({ tiles }) => tiles)) {
      heights.set(biome, (heights.get(biome) ?? new Set()).add(height));
    }
    const sorted = (biome: string) => [...(heights.get(biome) ?? [])].sort();
    expect(sorted('mountain')).toEqual([4]);
    expect(sorted('stone')).toEqual([3]);
    expect(sorted('hill')).toEqual([2, 3]);
    expect(sorted('temperate')).toEqual([1]);
    expect(sorted('boreal')).toEqual([1]);
    expect(sorted('wshallow')).toEqual([0]);
    expect(sorted('wdeep')).toEqual([0]);
  });

  it('começa em terra plana', () => {
    for (const map of maps) {
      const start = map.tiles.find(
        ({ q, r }) => q === map.start.q && r === map.start.r,
      );
      expect(['temperate', 'boreal', 'stone']).toContain(start!.biome);
    }
  });
});
