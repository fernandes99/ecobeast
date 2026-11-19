import { DEFAULT_MAP_CONFIG, type MapConfig } from './map-config.js';
import type { Biome, MapTile } from './map-generator.js';
import { createNoise } from './noise.js';
import { seededRandom } from './seeded-random.js';

/** Uma linha de `biome_zones` (biome-zones/01). A Comum tem o slug do bioma. */
export interface MapZone {
  slug: string;
  biome: Biome;
  share: number;
  sortOrder: number;
}

/** As zonas vêm de um sorteio à parte, para o terreno da seed não mudar. */
const ZONE_SALT = 0x20ae5;
const ZONE_SCALE = 2;
const ROW_HEIGHT = Math.sqrt(3) / 2;

/**
 * Põe `zone` nos hexágonos fora da Comum: os de cada bioma, ordenados por um
 * ruído próprio, viram faixas na ordem das zonas, do tamanho do `share` de cada uma.
 */
export function assignZones(
  tiles: readonly MapTile[],
  seed: number,
  zones: readonly MapZone[],
  config: MapConfig = DEFAULT_MAP_CONFIG,
): MapTile[] {
  const noise = createNoise(seededRandom(seed ^ ZONE_SALT));
  const scale = config.noiseScale * ZONE_SCALE;
  const value = ({ q, r }: MapTile): number =>
    noise((q + r / 2) * scale, r * ROW_HEIGHT * scale);
  const zoneOf = new Map<MapTile, string>();
  for (const biome of new Set(tiles.map((tile) => tile.biome))) {
    const bands = zones
      .filter((zone) => zone.biome === biome && zone.share > 0)
      .sort(
        (a, b) => a.sortOrder - b.sortOrder || a.slug.localeCompare(b.slug),
      );
    const total = bands.reduce((sum, { share }) => sum + share, 0);
    if (total === 0) continue;
    const ranked = tiles
      .filter((tile) => tile.biome === biome)
      .map((tile) => ({ tile, value: value(tile) }))
      .sort(
        (a, b) =>
          a.value - b.value || a.tile.q - b.tile.q || a.tile.r - b.tile.r,
      );
    let start = 0;
    let shares = 0;
    for (const band of bands) {
      shares += band.share;
      const end = Math.round((shares * ranked.length) / total);
      for (const { tile } of ranked.slice(start, end)) {
        if (band.slug !== biome) zoneOf.set(tile, band.slug);
      }
      start = end;
    }
  }
  return tiles.map((tile) => {
    const zone = zoneOf.get(tile);
    return zone === undefined ? { ...tile } : { ...tile, zone };
  });
}
