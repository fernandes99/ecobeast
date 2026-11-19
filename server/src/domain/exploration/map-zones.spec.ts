import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { SEED_DATA_DIR } from '../../catalog/catalog-tables.js';
import { generateMap, type MapTile } from './map-generator.js';
import { assignZones, type MapZone } from './map-zones.js';

const biomeSlugs = new Map<number, string>(
  (
    JSON.parse(readFileSync(`${SEED_DATA_DIR}/biomes.json`, 'utf8')) as {
      id: number;
      slug: string;
    }[]
  ).map(({ id, slug }) => [id, slug]),
);
const SEED_ZONES: MapZone[] = (
  JSON.parse(readFileSync(`${SEED_DATA_DIR}/biome_zones.json`, 'utf8')) as {
    slug: string;
    biome_id: number;
    share: number;
    sort_order: number;
  }[]
).map(({ slug, biome_id, share, sort_order }) => ({
  slug,
  biome: biomeSlugs.get(biome_id) as MapZone['biome'],
  share,
  sortOrder: sort_order,
}));

const zoneOf = (tile: MapTile): string => tile.zone ?? tile.biome;

describe('assignZones', () => {
  it.each([1, 7, 42, 1234, 99_999])(
    'divide cada bioma nas partes das zonas, a até 1 hexágono (seed %i)',
    (seed) => {
      const tiles = assignZones(generateMap(seed).tiles, seed, SEED_ZONES);
      for (const biome of new Set(tiles.map(({ biome }) => biome))) {
        const inBiome = tiles.filter((tile) => tile.biome === biome);
        const zones = SEED_ZONES.filter((zone) => zone.biome === biome);
        const total = zones.reduce((sum, { share }) => sum + share, 0);
        for (const zone of zones) {
          const count = inBiome.filter(
            (tile) => zoneOf(tile) === zone.slug,
          ).length;
          expect(
            Math.abs(count - (zone.share / total) * inBiome.length),
          ).toBeLessThanOrEqual(1);
        }
      }
    },
  );

  it('deixa a Montanha, a Praia e as águas sem zona', () => {
    const tiles = assignZones(generateMap(5).tiles, 5, SEED_ZONES);
    const single = ['mountain', 'beach', 'wshallow', 'wdeep', 'wford'];
    expect(
      tiles.filter(
        (tile) => single.includes(tile.biome) && tile.zone !== undefined,
      ),
    ).toEqual([]);
  });

  it('não muda o terreno e dá as mesmas zonas na mesma seed', () => {
    const map = generateMap(77);
    const first = assignZones(map.tiles, 77, SEED_ZONES);
    const second = assignZones(generateMap(77).tiles, 77, SEED_ZONES);
    expect(first).toEqual(second);
    expect(first.map(({ zone: _zone, ...tile }) => tile)).toEqual(map.tiles);
    expect(first.some((tile) => tile.zone !== undefined)).toBe(true);
  });

  it('deixa na Comum um bioma sem zonas e nunca usa zona de share 0', () => {
    const zones = SEED_ZONES.filter((zone) => zone.biome !== 'temperate').map(
      (zone) => (zone.slug === 'boreal_ferns' ? { ...zone, share: 0 } : zone),
    );
    const tiles = assignZones(generateMap(3).tiles, 3, zones);
    expect(
      tiles.filter((tile) => tile.biome === 'temperate' && tile.zone),
    ).toEqual([]);
    expect(tiles.some((tile) => tile.zone === 'boreal_ferns')).toBe(false);
  });

  it('aguenta um bioma de 1 hexágono', () => {
    const tiles: MapTile[] = [
      { q: 0, r: 0, biome: 'stone', height: 3, variant: 1 },
    ];
    expect(assignZones(tiles, 1, SEED_ZONES)).toHaveLength(1);
  });
});
