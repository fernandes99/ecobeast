import { describe, expect, it } from 'vitest';
import { hexKey, hexNeighbors } from './hex.js';
import { generateMap, isWater, type MapTile } from './map-generator.js';
import { assignZones, type MapZone } from './map-zones.js';

const ZONES: MapZone[] = [
  { slug: 'wshallow', biome: 'wshallow', share: 50, sortOrder: 2 },
  { slug: 'wshallow_rocks', biome: 'wshallow', share: 21, sortOrder: 1 },
  { slug: 'wshallow_seagrass', biome: 'wshallow', share: 21, sortOrder: 3 },
  { slug: 'wshallow_trash', biome: 'wshallow', share: 8, sortOrder: 4 },
  { slug: 'wdeep', biome: 'wdeep', share: 50, sortOrder: 2 },
  { slug: 'wdeep_rocks', biome: 'wdeep', share: 21, sortOrder: 1 },
  { slug: 'wdeep_kelp', biome: 'wdeep', share: 21, sortOrder: 3 },
  { slug: 'wdeep_trash', biome: 'wdeep', share: 8, sortOrder: 4 },
];
const SEEDS = Array.from({ length: 24 }, (_, index) => index * 97 + 5);
const isTrash = (tile: MapTile): boolean =>
  tile.zone === 'wshallow_trash' || tile.zone === 'wdeep_trash';

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

describe('assignZones: o lixo em manchas (sea-life/06)', () => {
  const maps = SEEDS.map((seed) => ({
    seed,
    tiles: assignZones(generateMap(seed).tiles, seed, ZONES),
  }));

  it('põe o lixo só em manchas pequenas, de até 8 hexágonos', () => {
    for (const { tiles } of maps) {
      for (const patch of patches(tiles)) {
        expect(patch.length).toBeLessThanOrEqual(8);
        expect(patch.every((tile) => isWater(tile.biome))).toBe(true);
      }
    }
  });

  it('junta a parte rasa e a funda do lixo do mar numa mancha só', () => {
    let mixed = 0;
    for (const { tiles } of maps) {
      const big = patches(tiles).filter((patch) => patch.length > 3);
      expect(big.length).toBeLessThanOrEqual(1);
      const patch = big[0];
      if (
        patch?.some((tile) => tile.biome === 'wdeep') &&
        patch.some((tile) => tile.biome === 'wshallow')
      ) {
        mixed += 1;
      }
    }
    expect(mixed).toBeGreaterThan(SEEDS.length / 3);
  });

  it('quase nunca põe lixo fora do mar', () => {
    const small = maps.flatMap(({ tiles }) =>
      patches(tiles).filter((patch) => patch.length <= 3),
    );
    expect(small.length).toBeLessThanOrEqual(SEEDS.length / 4);
  });

  it('não muda as outras zonas nem o terreno, e repete na mesma seed', () => {
    const seed = SEEDS[3];
    const map = generateMap(seed).tiles;
    const withTrash = assignZones(map, seed, ZONES);
    const without = assignZones(
      map,
      seed,
      ZONES.filter(({ slug }) => !slug.endsWith('_trash')),
    );
    withTrash.forEach((tile, index) => {
      if (!isTrash(tile)) expect(tile).toEqual(without[index]);
    });
    expect(assignZones(map, seed, ZONES)).toEqual(withTrash);
    expect(withTrash.map(({ zone: _zone, ...tile }) => tile)).toEqual(map);
  });
});
