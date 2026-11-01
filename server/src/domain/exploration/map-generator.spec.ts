import { hexKey, hexNeighbors } from './hex.js';
import {
  DEFAULT_MAP_CONFIG,
  FORBIDDEN_BIOME_PAIRS,
  MapConfig,
} from './map-config.js';
import {
  Biome,
  BIOMES,
  GeneratedMap,
  generateMap,
  isWater,
  MapTile,
  TERRAIN_SHAPES,
} from './map-generator.js';

const SEEDS = Array.from({ length: 200 }, (_, index) => index * 7919 + 1);
const MAX_LONELY_LAND = 0.05;
/** A grama é a base da região e passa de 30%; nenhum bioma deve ir além disto. */
const MAX_BIOME_SHARE = 0.35;

function indexed(map: GeneratedMap): Map<string, MapTile> {
  return new Map(map.tiles.map((tile) => [hexKey(tile), tile]));
}

function neighborsOf(tile: MapTile, byKey: Map<string, MapTile>): MapTile[] {
  return hexNeighbors(tile).flatMap((coord) => {
    const neighbor = byKey.get(hexKey(coord));
    return neighbor ? [neighbor] : [];
  });
}

function reachableFrom(map: GeneratedMap): number {
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

const waterShare = (map: GeneratedMap) =>
  map.tiles.filter((tile) => isWater(tile.biome)).length / map.tiles.length;

describe('generateMap', () => {
  let maps: GeneratedMap[];

  beforeAll(() => {
    maps = SEEDS.map((seed) => generateMap(seed));
  });

  it('devolve a seed recebida', () => {
    expect(generateMap(123).seed).toBe(123);
  });

  it('a mesma seed dá o mesmo mapa', () => {
    expect(generateMap(555)).toEqual(generateMap(555));
  });

  it('seeds diferentes dão mapas diferentes', () => {
    expect(generateMap(555).tiles).not.toEqual(generateMap(556).tiles);
  });

  it('o recorte do mapa muda com a seed', () => {
    const shape = (map: GeneratedMap) => map.tiles.map(hexKey).sort().join('|');
    expect(new Set(maps.map(shape)).size).toBeGreaterThan(190);
  });

  it('tem a quantidade pedida, sem posições repetidas', () => {
    for (const map of maps) {
      expect(map.tiles).toHaveLength(DEFAULT_MAP_CONFIG.tileCount);
      expect(new Set(map.tiles.map(hexKey)).size).toBe(map.tiles.length);
    }
  });

  it('muda de tamanho com `tileCount`', () => {
    const config = { ...DEFAULT_MAP_CONFIG, tileCount: 120 };
    expect(generateMap(9, config).tiles).toHaveLength(120);
  });

  it('todas as posições são alcançáveis', () => {
    for (const map of maps) {
      expect(reachableFrom(map)).toBe(map.tiles.length);
    }
  });

  it('só usa biomas, formas e variantes que têm sprite', () => {
    for (const { tiles } of maps) {
      for (const tile of tiles) {
        expect(BIOMES).toContain(tile.biome);
        expect(TERRAIN_SHAPES).toContain(tile.shape);
        expect(tile.variant).toBeGreaterThanOrEqual(1);
        expect(tile.variant).toBeLessThanOrEqual(tile.shape === 'flat' ? 6 : 3);
      }
    }
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

  it('nenhum par proibido fica lado a lado', () => {
    const forbidden = new Set(
      FORBIDDEN_BIOME_PAIRS.flatMap(([first, second]) => [
        `${first}-${second}`,
        `${second}-${first}`,
      ]),
    );
    for (const map of maps) {
      const byKey = indexed(map);
      for (const tile of map.tiles) {
        for (const neighbor of neighborsOf(tile, byKey)) {
          expect(forbidden.has(`${tile.biome}-${neighbor.biome}`)).toBe(false);
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
    expect(mean).toBeGreaterThan(DEFAULT_MAP_CONFIG.waterFraction - 0.03);
    expect(mean).toBeLessThan(DEFAULT_MAP_CONFIG.waterFraction + 0.03);
  });

  it('aparecem todos os biomas ao longo das seeds', () => {
    const seen = new Set<Biome>(
      maps.flatMap(({ tiles }) => tiles.map((tile) => tile.biome)),
    );
    expect([...seen].sort()).toEqual([...BIOMES].sort());
  });

  it('nenhum bioma de terra é raridade ao longo das seeds', () => {
    for (const biome of BIOMES.filter((slug) => !isWater(slug))) {
      const containing = maps.filter(({ tiles }) =>
        tiles.some((tile) => tile.biome === biome),
      );
      expect(containing.length / maps.length).toBeGreaterThan(0.25);
    }
  });

  it('nenhum bioma domina os mapas', () => {
    for (const biome of BIOMES) {
      const tiles = maps.flatMap((map) => map.tiles);
      const share = tiles.filter((tile) => tile.biome === biome).length;
      expect(share / tiles.length).toBeLessThan(MAX_BIOME_SHARE);
    }
  });

  it('há montanhas em vários biomas de terra', () => {
    const biomes = new Set(
      maps.flatMap(({ tiles }) =>
        tiles
          .filter(({ shape, biome }) => shape === 'mont' && !isWater(biome))
          .map((tile) => tile.biome),
      ),
    );
    expect(biomes.size).toBeGreaterThanOrEqual(5);
  });

  it('as ilhas são raras', () => {
    const water = maps.flatMap(({ tiles }) =>
      tiles.filter((tile) => isWater(tile.biome)),
    );
    const islands = water.filter((tile) => tile.shape !== 'flat');
    expect(islands.length).toBeGreaterThan(0);
    expect(islands.length / water.length).toBeLessThan(
      DEFAULT_MAP_CONFIG.islandChance * 2,
    );
  });

  it('mais `waterFraction` dá mais água', () => {
    const wetter: MapConfig = { ...DEFAULT_MAP_CONFIG, waterFraction: 0.4 };
    expect(waterShare(generateMap(9, wetter))).toBeGreaterThan(
      waterShare(generateMap(9)),
    );
  });
});
