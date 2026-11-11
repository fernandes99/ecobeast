import { createHash } from 'node:crypto';
import { type HexCoord, hexKey } from '../exploration/hex.js';
import {
  BIOMES,
  type Biome,
  isWater,
  MAX_HEIGHT,
  maxVariant,
} from '../exploration/map-generator.js';

/**
 * O rascunho de uma ilha e as conferências de salvar e de publicar
 * (.specs/map-editor/architecture.md, "Contrato").
 */

export const MAX_ISLAND_TILES = 20_000;
const MAX_NAME_LENGTH = 40;
const MIN_LEVEL = 1;
const MAX_LEVEL = 100;
const COLOR_HEX = /^#[0-9A-Fa-f]{6}$/;
/** Quantos Ecobeasts uma área pode ter (islands/01). */
export const MIN_AREA_SPAWNS = 1;
export const MAX_AREA_SPAWNS = 200;

export interface DraftTile extends HexCoord {
  biome: Biome;
  height: number;
  variant: number;
  /** A `key` da área do hexágono; sem ela, o hexágono não tem área. */
  area?: number;
}

export interface DraftBuilding {
  buildingTypeId: number;
  tiles: HexCoord[];
}

export interface DraftAreaSpecies {
  speciesId: number;
  weight: number;
  minLevel: number;
  maxLevel: number;
}

export interface DraftArea {
  /** Um número do próprio rascunho, só para os hexágonos apontarem para a área. */
  key: number;
  name: string;
  colorHex: string;
  /** Quantos Ecobeasts nascem nela a cada entrada na ilha (islands/01). */
  spawnCount: number;
  species: DraftAreaSpecies[];
}

export interface IslandDraft {
  name: string;
  start: HexCoord;
  tiles: DraftTile[];
  buildings: DraftBuilding[];
  areas: DraftArea[];
}

/** Os ids do catálogo que o rascunho pode usar. */
export interface KnownIds {
  buildingTypeIds: ReadonlySet<number>;
  speciesIds: ReadonlySet<number>;
}

const at = ({ q, r }: HexCoord): string => `(${q}, ${r})`;

function validName(name: string): boolean {
  return name.length >= 1 && name.length <= MAX_NAME_LENGTH;
}

function validVariant({ biome, variant }: DraftTile): boolean {
  return (
    Number.isInteger(variant) && variant >= 1 && variant <= maxVariant(biome)
  );
}

function validHeight(height: number): boolean {
  return Number.isInteger(height) && height >= 0 && height <= MAX_HEIGHT;
}

function validLevel(level: number): boolean {
  return Number.isInteger(level) && level >= MIN_LEVEL && level <= MAX_LEVEL;
}

function tileError(tile: DraftTile): string | null {
  if (!(BIOMES as readonly string[]).includes(tile.biome)) {
    return `O hexágono ${at(tile)} tem um bioma que não é de terreno.`;
  }
  if (!validHeight(tile.height)) {
    return `O hexágono ${at(tile)} tem a altura ${tile.height}: vai de 0 a ${MAX_HEIGHT}.`;
  }
  if (!validVariant(tile)) {
    return `O hexágono ${at(tile)} tem a variante ${tile.variant}: vai de 1 a 3 na Colina e na Montanha, e de 1 a 6 nos outros biomas.`;
  }
  return null;
}

function buildingsError(
  buildings: DraftBuilding[],
  tiles: ReadonlySet<string>,
  known: KnownIds,
): string | null {
  const taken = new Set<string>();
  for (const [index, building] of buildings.entries()) {
    const number = index + 1;
    if (!known.buildingTypeIds.has(building.buildingTypeId)) {
      return `A construção ${number} tem um tipo que não existe.`;
    }
    if (building.tiles.length === 0) {
      return `A construção ${number} precisa de pelo menos 1 hexágono.`;
    }
    for (const coord of building.tiles) {
      const key = hexKey(coord);
      if (!tiles.has(key)) {
        return `A construção ${number} ocupa ${at(coord)}, que não é da ilha.`;
      }
      if (taken.has(key))
        return `O hexágono ${at(coord)} é de duas construções.`;
      taken.add(key);
    }
  }
  return null;
}

function areaError(area: DraftArea, known: KnownIds): string | null {
  if (!validName(area.name)) {
    return `O nome da área ${area.key} precisa ter de 1 a 40 caracteres.`;
  }
  if (!COLOR_HEX.test(area.colorHex)) {
    return `A cor da área ${area.key} precisa ser #RRGGBB.`;
  }
  if (
    !Number.isInteger(area.spawnCount) ||
    area.spawnCount < MIN_AREA_SPAWNS ||
    area.spawnCount > MAX_AREA_SPAWNS
  ) {
    return `Na área ${area.key}, a quantidade de Ecobeasts precisa ir de ${MIN_AREA_SPAWNS} a ${MAX_AREA_SPAWNS}.`;
  }
  const seen = new Set<number>();
  for (const entry of area.species) {
    const { speciesId } = entry;
    if (!known.speciesIds.has(speciesId)) {
      return `A área ${area.key} tem uma espécie que não existe (${speciesId}).`;
    }
    if (seen.has(speciesId)) {
      return `A área ${area.key} repete a espécie ${speciesId}.`;
    }
    seen.add(speciesId);
    if (!Number.isInteger(entry.weight) || entry.weight <= 0) {
      return `Na área ${area.key}, o peso da espécie ${speciesId} precisa ser um inteiro maior que 0.`;
    }
    if (
      !validLevel(entry.minLevel) ||
      !validLevel(entry.maxLevel) ||
      entry.minLevel > entry.maxLevel
    ) {
      return `Na área ${area.key}, os níveis da espécie ${speciesId} precisam ir de 1 a 100, com o mínimo até o máximo.`;
    }
  }
  return null;
}

/**
 * A primeira coisa errada para salvar o rascunho, ou `null`. Uma ilha pela
 * metade pode ser salva: aqui só se confere que os dados fazem sentido.
 */
export function draftError(draft: IslandDraft, known: KnownIds): string | null {
  if (!validName(draft.name)) {
    return 'O nome da ilha precisa ter de 1 a 40 caracteres.';
  }
  if (draft.tiles.length < 1 || draft.tiles.length > MAX_ISLAND_TILES) {
    return 'A ilha precisa ter de 1 a 20.000 hexágonos.';
  }
  const tiles = new Set<string>();
  for (const tile of draft.tiles) {
    const key = hexKey(tile);
    if (tiles.has(key)) return `O hexágono ${at(tile)} aparece duas vezes.`;
    tiles.add(key);
    const error = tileError(tile);
    if (error) return error;
  }
  if (!tiles.has(hexKey(draft.start))) {
    return 'A chegada precisa ser um hexágono da ilha.';
  }
  const buildings = buildingsError(draft.buildings, tiles, known);
  if (buildings) return buildings;

  const keys = new Set<number>();
  for (const { key } of draft.areas) {
    if (keys.has(key)) return `Duas áreas têm a key ${key}.`;
    keys.add(key);
  }
  for (const tile of draft.tiles) {
    if (tile.area !== undefined && !keys.has(tile.area)) {
      return `O hexágono ${at(tile)} aponta para a área ${tile.area}, que não existe.`;
    }
  }
  for (const area of draft.areas) {
    const error = areaError(area, known);
    if (error) return error;
  }
  return null;
}

/** A primeira coisa errada para publicar: tudo de salvar, e a ilha pronta para jogar. */
export function publishError(
  draft: IslandDraft,
  known: KnownIds,
): string | null {
  const error = draftError(draft, known);
  if (error) return error;
  const startKey = hexKey(draft.start);
  const start = draft.tiles.find((tile) => hexKey(tile) === startKey)!;
  if (isWater(start.biome)) return 'A chegada não pode ficar na água.';
  const inBuilding = draft.buildings.some((building) =>
    building.tiles.some((coord) => hexKey(coord) === startKey),
  );
  if (inBuilding) return 'A chegada não pode ficar numa construção.';
  const empty = draft.areas.find((area) => area.species.length === 0);
  if (empty) return `A área "${empty.name}" não tem nenhuma espécie.`;
  return null;
}

const byRowThenColumn = (a: HexCoord, b: HexCoord): number =>
  a.r - b.r || a.q - b.q;

/**
 * O rascunho em JSON, sempre igual para o mesmo conteúdo: hexágonos em ordem de
 * (r, q), construções na ordem da lista (cada uma com os hexágonos em (r, q)),
 * áreas na ordem da `key`, numeradas de novo de 1 em diante, e espécies em
 * ordem de id. É o que o `content_hash` resume.
 */
export function canonicalDraft(draft: IslandDraft): string {
  const areas = [...draft.areas].sort((a, b) => a.key - b.key);
  const renumber = new Map(areas.map((area, index) => [area.key, index + 1]));
  return JSON.stringify({
    name: draft.name,
    start: { q: draft.start.q, r: draft.start.r },
    tiles: [...draft.tiles]
      .sort(byRowThenColumn)
      .map(({ q, r, biome, height, variant, area }) => ({
        q,
        r,
        biome,
        height,
        variant,
        area: area === undefined ? null : renumber.get(area),
      })),
    buildings: draft.buildings.map(({ buildingTypeId, tiles }) => ({
      buildingTypeId,
      tiles: [...tiles].sort(byRowThenColumn).map(({ q, r }) => ({ q, r })),
    })),
    areas: areas.map(({ key, name, colorHex, spawnCount, species }) => ({
      key: renumber.get(key),
      name,
      colorHex,
      spawnCount,
      species: [...species]
        .sort((a, b) => a.speciesId - b.speciesId)
        .map(({ speciesId, weight, minLevel, maxLevel }) => ({
          speciesId,
          weight,
          minLevel,
          maxLevel,
        })),
    })),
  });
}

/** O sha-256, em hexadecimal, do JSON canônico do rascunho. */
export function draftHash(draft: IslandDraft): string {
  return createHash('sha256').update(canonicalDraft(draft)).digest('hex');
}
