import { DEFAULT_MAP_CONFIG, type MapConfig } from './map-config.js';
import { hexKey, hexNeighbors, type HexCoord } from './hex.js';
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

/** A água doce (os lagos e os rios) fica toda na zona Lago, sem algas (sea-life/07). */
const LAKE_ZONES: Partial<Record<Biome, string>> = {
  wshallow: 'wshallow_lake',
  wdeep: 'wdeep_lake',
};
/** O lago da Geleira fica no Lago gelado, com as placas de gelo (glacier/04). */
const ICE_LAKE_ZONES: Partial<Record<Biome, string>> = {
  wshallow: 'wshallow_ice_lake',
  wdeep: 'wdeep_ice_lake',
};
/**
 * As zonas de lixo não são faixas: são uma mancha no mar, quase toda na Água
 * profunda e encostada na rasa, e, bem raramente, uma pequena num lago ou num rio
 * (sea-life/06 e 07). A revisar.
 */
const PATCH_ZONES: Partial<Record<Biome, string>> = {
  wshallow: 'wshallow_trash',
  wdeep: 'wdeep_trash',
};
const PATCH_SALT = 0x7a54;
const SEA_PATCH_TILES = 10;
/** A chance de o próximo hexágono da mancha do mar ser de Água profunda, quando há. */
const SEA_PATCH_DEEP = 0.8;
/** A chance, por mapa, de uma mancha pequena num lago ou num rio. */
const LAKE_PATCH_CHANCE = 0.08;
const LAKE_PATCH_TILES = 3;

/**
 * Põe `zone` nos hexágonos fora da Comum: os de cada bioma, ordenados por um
 * ruído próprio, viram faixas na ordem das zonas, do tamanho do `share` de cada uma.
 * A água de `inland` (os lagos e os rios do gerador) fica no Lago, e o lixo vem em
 * manchas.
 */
export function assignZones(
  tiles: readonly MapTile[],
  seed: number,
  zones: readonly MapZone[],
  config: MapConfig = DEFAULT_MAP_CONFIG,
  inland: readonly (readonly HexCoord[])[] = [],
  iceLake: readonly HexCoord[] = [],
): MapTile[] {
  const noise = createNoise(seededRandom(seed ^ ZONE_SALT));
  const scale = config.noiseScale * ZONE_SCALE;
  const value = ({ q, r }: MapTile): number =>
    noise((q + r / 2) * scale, r * ROW_HEIGHT * scale);
  const known = new Set(zones.map(({ slug }) => slug));
  const iceKeys = new Set(iceLake.map(hexKey));
  const freshKeys = new Set([...inland.flat().map(hexKey), ...iceKeys]);
  const isLake = (tile: MapTile): boolean =>
    isWater(tile.biome) && freshKeys.has(hexKey(tile));
  const zoneOf = new Map<MapTile, string>();
  for (const biome of new Set(tiles.map((tile) => tile.biome))) {
    const bands = zones
      .filter(
        (zone) =>
          zone.biome === biome &&
          zone.share > 0 &&
          zone.slug !== PATCH_ZONES[zone.biome] &&
          zone.slug !== LAKE_ZONES[zone.biome],
      )
      .sort(
        (a, b) => a.sortOrder - b.sortOrder || a.slug.localeCompare(b.slug),
      );
    const total = bands.reduce((sum, { share }) => sum + share, 0);
    if (total === 0) continue;
    const ranked = tiles
      .filter((tile) => tile.biome === biome && !isLake(tile))
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
  for (const tile of tiles.filter(isLake)) {
    const slug = (iceKeys.has(hexKey(tile)) ? ICE_LAKE_ZONES : LAKE_ZONES)[
      tile.biome
    ];
    if (slug !== undefined && known.has(slug)) zoneOf.set(tile, slug);
  }
  placePatches(tiles, seed, known, isLake, inland, zoneOf);
  return tiles.map((tile) => {
    const zone = zoneOf.get(tile);
    return zone === undefined ? { ...tile } : { ...tile, zone };
  });
}

function placePatches(
  tiles: readonly MapTile[],
  seed: number,
  known: ReadonlySet<string>,
  isLake: (tile: MapTile) => boolean,
  inland: readonly (readonly HexCoord[])[],
  zoneOf: Map<MapTile, string>,
): void {
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
      .filter(
        (other): other is MapTile =>
          other !== undefined && isWater(other.biome),
      );
  const pick = <T>(list: readonly T[]): T =>
    list[Math.floor(random() * list.length)];
  const grow = (
    center: MapTile,
    size: number,
    within: (tile: MapTile) => boolean,
    deep: number,
  ): MapTile[] => {
    const patch = [center];
    const taken = new Set([center]);
    while (patch.length < size) {
      const frontier = patch
        .flatMap(wetNeighbors)
        .filter((other) => within(other) && !taken.has(other));
      if (frontier.length === 0) break;
      const deepOnes = frontier.filter((other) => other.biome === 'wdeep');
      const next =
        deepOnes.length > 0 && random() < deep
          ? pick(deepOnes)
          : pick(frontier);
      taken.add(next);
      patch.push(next);
    }
    return patch;
  };
  const mark = (patch: readonly MapTile[]): void => {
    for (const tile of patch) {
      const slug = patchOf(tile);
      if (slug !== undefined) zoneOf.set(tile, slug);
    }
  };

  const sea = tiles.filter((tile) => isWater(tile.biome) && !isLake(tile));
  const coast = sea.filter(
    (tile) =>
      tile.biome === 'wdeep' &&
      wetNeighbors(tile).some(
        (other) => other.biome === 'wshallow' && !isLake(other),
      ),
  );
  const seaDeep = sea.filter((tile) => tile.biome === 'wdeep');
  const centers = coast.length > 0 ? coast : seaDeep.length > 0 ? seaDeep : sea;
  if (centers.length > 0) {
    const inSea = (tile: MapTile): boolean => !isLake(tile);
    mark(grow(pick(centers), SEA_PATCH_TILES, inSea, SEA_PATCH_DEEP));
  }

  const bodies = inland
    .map((body) =>
      body
        .map((coord) => byKey.get(hexKey(coord)))
        .filter(
          (tile): tile is MapTile => tile !== undefined && isWater(tile.biome),
        ),
    )
    .filter((water) => water.length > 0);
  if (bodies.length === 0 || random() >= LAKE_PATCH_CHANCE) return;
  const water = pick(bodies);
  const inBody = new Set(water);
  mark(grow(pick(water), LAKE_PATCH_TILES, (tile) => inBody.has(tile), 0));
}
