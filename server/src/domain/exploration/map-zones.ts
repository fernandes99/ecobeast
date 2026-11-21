import { DEFAULT_MAP_CONFIG, type MapConfig } from './map-config.js';
import { hexKey, hexNeighbors } from './hex.js';
import { isWater, type Biome, type MapTile } from './map-generator.js';
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
 * As zonas de lixo não são faixas: são uma mancha pequena e junta no mar, com a parte
 * rasa e a funda lado a lado, e, bem raramente, uma menor num lago ou num rio
 * (sea-life/06). A revisar.
 */
const PATCH_ZONES: Partial<Record<Biome, string>> = {
  wshallow: 'wshallow_trash',
  wdeep: 'wdeep_trash',
};
const PATCH_SALT = 0x7a54;
/** A água ligada à borda com mais hexágonos é o mar, se tiver pelo menos tantos. */
const SEA_MIN_TILES = 40;
const SEA_PATCH_CHANCE = 0.75;
const SEA_PATCH_TILES = 8;
const LAKE_PATCH_CHANCE = 0.04;
const LAKE_PATCH_TILES = 3;

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
      .filter(
        (zone) =>
          zone.biome === biome &&
          zone.share > 0 &&
          zone.slug !== PATCH_ZONES[zone.biome],
      )
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
  placePatches(tiles, seed, zones, zoneOf);
  return tiles.map((tile) => {
    const zone = zoneOf.get(tile);
    return zone === undefined ? { ...tile } : { ...tile, zone };
  });
}

function placePatches(
  tiles: readonly MapTile[],
  seed: number,
  zones: readonly MapZone[],
  zoneOf: Map<MapTile, string>,
): void {
  const known = new Set(zones.map(({ slug }) => slug));
  const patchOf = (tile: MapTile): string | undefined => {
    const slug = PATCH_ZONES[tile.biome];
    return slug !== undefined && known.has(slug) ? slug : undefined;
  };
  if (!tiles.some((tile) => patchOf(tile) !== undefined)) return;
  const random = seededRandom(seed ^ PATCH_SALT);
  const byKey = new Map(tiles.map((tile) => [hexKey(tile), tile]));
  const wetNeighbors = (tile: MapTile): MapTile[] =>
    hexNeighbors(tile)
      .map((coord) => byKey.get(hexKey(coord)))
      .filter((other): other is MapTile => other !== undefined && isWater(other.biome));
  const onEdge = (tile: MapTile): boolean =>
    hexNeighbors(tile).some((coord) => !byKey.has(hexKey(coord)));
  const seen = new Set<MapTile>();
  const bodies: MapTile[][] = [];
  for (const tile of tiles) {
    if (!isWater(tile.biome) || seen.has(tile)) continue;
    const body = [tile];
    seen.add(tile);
    for (let index = 0; index < body.length; index++) {
      for (const other of wetNeighbors(body[index])) {
        if (!seen.has(other)) {
          seen.add(other);
          body.push(other);
        }
      }
    }
    bodies.push(body);
  }
  const sea = bodies
    .filter((body) => body.length >= SEA_MIN_TILES && body.some(onEdge))
    .sort((a, b) => b.length - a.length)[0];
  for (const body of bodies) {
    const isSea = body === sea;
    const chance = isSea ? SEA_PATCH_CHANCE : LAKE_PATCH_CHANCE;
    if (random() >= chance) continue;
    const coast = isSea
      ? body.filter(
          (tile) =>
            tile.biome === 'wdeep' &&
            wetNeighbors(tile).some((other) => other.biome === 'wshallow'),
        )
      : body;
    const centers = coast.length > 0 ? coast : body;
    const center = centers[Math.floor(random() * centers.length)];
    const size = isSea ? SEA_PATCH_TILES : LAKE_PATCH_TILES;
    const patch = [center];
    const taken = new Set([center]);
    while (patch.length < size) {
      const frontier = patch
        .flatMap(wetNeighbors)
        .filter((other) => !taken.has(other));
      if (frontier.length === 0) break;
      const next = frontier[Math.floor(random() * frontier.length)];
      taken.add(next);
      patch.push(next);
    }
    for (const tile of patch) {
      const slug = patchOf(tile);
      if (slug !== undefined) zoneOf.set(tile, slug);
    }
  }
}
