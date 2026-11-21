import { describe, expect, it } from 'vitest';
import { hexKey, hexNeighbors } from './hex.js';
import { generateMap, isWater, type MapTile } from './map-generator.js';
import { assignZones, type MapZone } from './map-zones.js';

const ZONES: MapZone[] = [
  { slug: 'wshallow', biome: 'wshallow', share: 50, sortOrder: 2 },
  { slug: 'wshallow_rocks', biome: 'wshallow', share: 21, sortOrder: 1 },
  { slug: 'wshallow_seagrass', biome: 'wshallow', share: 21, sortOrder: 3 },
  { slug: 'wshallow_trash', biome: 'wshallow', share: 0, sortOrder: 4 },
  { slug: 'wshallow_lake', biome: 'wshallow', share: 0, sortOrder: 5 },
  { slug: 'wdeep', biome: 'wdeep', share: 50, sortOrder: 2 },
  { slug: 'wdeep_rocks', biome: 'wdeep', share: 21, sortOrder: 1 },
  { slug: 'wdeep_kelp', biome: 'wdeep', share: 21, sortOrder: 3 },
  { slug: 'wdeep_trash', biome: 'wdeep', share: 0, sortOrder: 4 },
  { slug: 'wdeep_lake', biome: 'wdeep', share: 0, sortOrder: 5 },
];
const SEEDS = Array.from({ length: 24 }, (_, index) => index * 97 + 5);
const isTrash = (tile: MapTile): boolean =>
  tile.zone?.endsWith('_trash') ?? false;

/** As manchas de lixo: os pedaços ligados de hexágonos de lixo. */
function patches(tiles: readonly MapTile[]): MapTile[][] {
  const byKey = new Map(tiles.map((tile) => [hexKey(tile), tile]));
  const seen = new Set<MapTile>();
  const result: MapTile[][] = [];
  for (const tile of tiles.filter(isTrash)) {
    if (seen.has(tile)) continue;
    const patch = [tile];
    seen.add(tile);
    for (let index = 0; index < patch.length; index++) {
      for (const coord of hexNeighbors(patch[index])) {
        const other = byKey.get(hexKey(coord));
        if (other !== undefined && isTrash(other) && !seen.has(other)) {
          seen.add(other);
          patch.push(other);
        }
      }
    }
    result.push(patch);
  }
  return result;
}

describe('assignZones: o lixo em manchas e os lagos sem algas (sea-life/06 e 07)', () => {
  const maps = SEEDS.map((seed) => {
    const generated = generateMap(seed);
    const fresh = new Set(generated.inland.flat().map(hexKey));
    return {
      seed,
      generated,
      fresh,
      tiles: assignZones(
        generated.tiles,
        seed,
        ZONES,
        undefined,
        generated.inland,
      ),
    };
  });

  it('põe toda a água doce no Lago, e nenhuma zona de algas nela', () => {
    let lakes = 0;
    for (const { tiles, fresh } of maps) {
      for (const tile of tiles) {
        if (!isWater(tile.biome) || !fresh.has(hexKey(tile))) continue;
        lakes += 1;
        expect([
          'wshallow_lake',
          'wdeep_lake',
          'wshallow_trash',
          'wdeep_trash',
        ]).toContain(tile.zone);
      }
    }
    expect(lakes).toBeGreaterThan(0);
  });

  it('põe no mar de todo mapa com mar uma mancha de lixo de 10 hexágonos, quase toda funda', () => {
    let deep = 0;
    let total = 0;
    for (const { tiles, fresh } of maps) {
      const sea = tiles.filter(
        (tile) => tile.biome === 'wdeep' && !fresh.has(hexKey(tile)),
      );
      const big = patches(tiles).filter((patch) => patch.length > 3);
      if (sea.length === 0) continue;
      expect(big.length).toBe(1);
      expect(big[0].length).toBeLessThanOrEqual(10);
      expect(big[0].some((tile) => fresh.has(hexKey(tile)))).toBe(false);
      deep += big[0].filter((tile) => tile.biome === 'wdeep').length;
      total += big[0].length;
    }
    expect(deep / total).toBeGreaterThan(0.6);
  });

  it('quase nunca põe lixo nos lagos e nos rios', () => {
    const small = maps.flatMap(({ tiles }) =>
      patches(tiles).filter((patch) => patch.length <= 3),
    );
    expect(small.length).toBeLessThanOrEqual(SEEDS.length / 4);
  });

  it('não muda as outras zonas nem o terreno, e repete na mesma seed', () => {
    const { seed, generated, tiles } = maps[3];
    const without = assignZones(
      generated.tiles,
      seed,
      ZONES.filter(({ slug }) => !slug.endsWith('_trash')),
      undefined,
      generated.inland,
    );
    tiles.forEach((tile, index) => {
      if (!isTrash(tile)) expect(tile).toEqual(without[index]);
    });
    expect(
      assignZones(generated.tiles, seed, ZONES, undefined, generated.inland),
    ).toEqual(tiles);
    expect(tiles.map(({ zone: _zone, ...tile }) => tile)).toEqual(
      generated.tiles,
    );
  });
});
