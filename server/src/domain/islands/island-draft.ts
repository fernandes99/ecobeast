import { createHash } from 'node:crypto';
import { type HexCoord, hexKey } from '../exploration/hex.js';
import {
  BIOMES,
  type Biome,
  isWater,
  MAX_HEIGHT,
  maxVariant,
} from '../exploration/map-generator.js';
import { flatCenter, gridCoord } from './hex-pixels.js';

export const MAX_ISLAND_TILES = 20_000;
const MAX_NAME_LENGTH = 40;
const MIN_LEVEL = 1;
const MAX_LEVEL = 100;
const COLOR_HEX = /^#[0-9A-Fa-f]{6}$/;
export const MIN_AREA_SPAWNS = 1;
export const MAX_AREA_SPAWNS = 200;
export const MAX_PROPS = 6_000;

export interface DraftTile extends HexCoord {
  biome: Biome;
  height: number;
  variant: number;
  ground?: string;
  area?: number;
  /** Sem as decorações naturais sorteadas (free-props/05). */
  bare?: boolean;
}

export interface DraftAction {
  actionTypeId: number;
  tiles: HexCoord[];
}

export interface DraftObjectTile extends HexCoord {
  blocks: boolean;
}

export interface DraftObject extends HexCoord {
  objectTypeId: number;
  variant: number;
  mirrored: boolean;
  tiles: DraftObjectTile[];
}

/** Uma peça solta: o pé em `(dx, dy)` pixels do centro plano de `(q, r)`. */
export interface DraftProp extends HexCoord {
  propTypeId: number;
  dx: number;
  dy: number;
  variant: number;
  mirrored: boolean;
}

export interface DraftAreaSpecies {
  speciesId: number;
  weight: number;
  minLevel: number;
  maxLevel: number;
}

export interface DraftArea {
  key: number;
  name: string;
  colorHex: string;
  spawnCount: number;
  species: DraftAreaSpecies[];
}

export interface IslandDraft {
  name: string;
  start: HexCoord;
  tiles: DraftTile[];
  actions: DraftAction[];
  objects: DraftObject[];
  props: DraftProp[];
  areas: DraftArea[];
}

export interface KnownIds {
  actionTypeIds: ReadonlySet<number>;
  objectTypeIds: ReadonlySet<number>;
  groundSlugs: ReadonlySet<string>;
  speciesIds: ReadonlySet<number>;
  /** O máximo de variantes de cada tipo de peça solta. */
  propVariants: ReadonlyMap<number, number>;
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

function tileError(tile: DraftTile, known: KnownIds): string | null {
  if (!(BIOMES as readonly string[]).includes(tile.biome)) {
    return `O hexágono ${at(tile)} tem um bioma que não é de terreno.`;
  }
  if (!validHeight(tile.height)) {
    return `O hexágono ${at(tile)} tem a altura ${tile.height}: vai de 0 a ${MAX_HEIGHT}.`;
  }
  if (!validVariant(tile)) {
    return `O hexágono ${at(tile)} tem a variante ${tile.variant}: vai de 1 a 3 na Colina e na Montanha, e de 1 a 6 nos outros biomas.`;
  }
  if (tile.ground !== undefined && !known.groundSlugs.has(tile.ground)) {
    return `O hexágono ${at(tile)} tem um chão que não existe.`;
  }
  if (tile.bare !== undefined && typeof tile.bare !== 'boolean') {
    return `O hexágono ${at(tile)} tem a marca bare que não é verdadeira nem falsa.`;
  }
  return null;
}

function actionsError(
  actions: DraftAction[],
  tiles: ReadonlySet<string>,
  known: KnownIds,
): string | null {
  const taken = new Set<string>();
  for (const [index, action] of actions.entries()) {
    const number = index + 1;
    if (!known.actionTypeIds.has(action.actionTypeId)) {
      return `A ação ${number} tem um tipo que não existe.`;
    }
    if (action.tiles.length === 0) {
      return `A ação ${number} precisa de pelo menos 1 hexágono.`;
    }
    for (const coord of action.tiles) {
      const key = hexKey(coord);
      if (!tiles.has(key)) {
        return `A ação ${number} ocupa ${at(coord)}, que não é da ilha.`;
      }
      if (taken.has(key)) return `O hexágono ${at(coord)} é de duas ações.`;
      taken.add(key);
    }
  }
  return null;
}

function objectsError(
  objects: DraftObject[],
  tiles: ReadonlySet<string>,
  known: KnownIds,
): string | null {
  const taken = new Set<string>();
  for (const [index, object] of objects.entries()) {
    const number = index + 1;
    if (!known.objectTypeIds.has(object.objectTypeId)) {
      return `O objeto ${number} tem um tipo que não existe.`;
    }
    if (!Number.isInteger(object.variant) || object.variant < 1) {
      return `O objeto ${number} tem a variante ${object.variant}: começa em 1.`;
    }
    if (!object.tiles.some((tile) => hexKey(tile) === hexKey(object))) {
      return `O objeto ${number} precisa ocupar o hexágono de apoio ${at(object)}.`;
    }
    for (const coord of object.tiles) {
      const key = hexKey(coord);
      if (!tiles.has(key)) {
        return `O objeto ${number} ocupa ${at(coord)}, que não é da ilha.`;
      }
      if (taken.has(key)) return `O hexágono ${at(coord)} é de dois objetos.`;
      taken.add(key);
    }
  }
  return null;
}

function propsError(
  props: DraftProp[],
  tiles: ReadonlySet<string>,
  known: KnownIds,
): string | null {
  if (props.length > MAX_PROPS) return 'A ilha pode ter até 6.000 peças.';
  for (const [index, prop] of props.entries()) {
    const number = index + 1;
    const variants = known.propVariants.get(prop.propTypeId);
    if (variants === undefined) {
      return `A peça ${number} tem um tipo que não existe.`;
    }
    if (
      !Number.isInteger(prop.variant) ||
      prop.variant < 1 ||
      prop.variant > variants
    ) {
      return `A peça ${number} tem a variante ${prop.variant}: vai de 1 a ${variants}.`;
    }
    if (!tiles.has(hexKey(prop))) {
      return `A peça ${number} fica em ${at(prop)}, que não é da ilha.`;
    }
    const center = flatCenter(prop);
    const foot = gridCoord({ x: center.x + prop.dx, y: center.y + prop.dy });
    if (
      !Number.isInteger(prop.dx) ||
      !Number.isInteger(prop.dy) ||
      hexKey(foot) !== hexKey(prop)
    ) {
      return `A peça ${number} tem o pé fora do hexágono ${at(prop)}.`;
    }
  }
  return null;
}

export function blockedKeys(
  draft: Pick<IslandDraft, 'objects'>,
): ReadonlySet<string> {
  return new Set(
    draft.objects.flatMap(({ tiles }) =>
      tiles.filter(({ blocks }) => blocks).map(hexKey),
    ),
  );
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
    const error = tileError(tile, known);
    if (error) return error;
  }
  if (!tiles.has(hexKey(draft.start))) {
    return 'A chegada precisa ser um hexágono da ilha.';
  }
  const actions = actionsError(draft.actions, tiles, known);
  if (actions) return actions;
  const objects = objectsError(draft.objects, tiles, known);
  if (objects) return objects;
  const props = propsError(draft.props, tiles, known);
  if (props) return props;

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

export function publishError(
  draft: IslandDraft,
  known: KnownIds,
): string | null {
  const error = draftError(draft, known);
  if (error) return error;
  const startKey = hexKey(draft.start);
  const start = draft.tiles.find((tile) => hexKey(tile) === startKey)!;
  if (isWater(start.biome)) return 'A chegada não pode ficar na água.';
  const inAction = draft.actions.some((action) =>
    action.tiles.some((coord) => hexKey(coord) === startKey),
  );
  if (inAction) return 'A chegada não pode ficar numa ação.';
  if (blockedKeys(draft).has(startKey)) {
    return 'A chegada não pode ficar num hexágono bloqueado.';
  }
  const empty = draft.areas.find((area) => area.species.length === 0);
  if (empty) return `A área "${empty.name}" não tem nenhuma espécie.`;
  return null;
}

const byRowThenColumn = (a: HexCoord, b: HexCoord): number =>
  a.r - b.r || a.q - b.q;

/**
 * O rascunho em JSON, sempre igual para o mesmo conteúdo: hexágonos em ordem de
 * (r, q), ações na ordem da lista (cada uma com os hexágonos em (r, q)),
 * objetos em ordem de (r, q) do apoio (cada um com os hexágonos em (r, q)),
 * peças em ordem de (r, q, dy, dx, tipo, variante, espelho),
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
      .map(({ q, r, biome, height, variant, ground, area, bare }) => ({
        q,
        r,
        biome,
        height,
        variant,
        ground: ground ?? null,
        area: area === undefined ? null : renumber.get(area),
        // Só quando verdadeira: uma ilha sem marcas tem o hash de antes.
        ...(bare === true ? { bare: true } : {}),
      })),
    actions: draft.actions.map(({ actionTypeId, tiles }) => ({
      actionTypeId,
      tiles: [...tiles].sort(byRowThenColumn).map(({ q, r }) => ({ q, r })),
    })),
    objects: [...draft.objects]
      .sort(byRowThenColumn)
      .map(({ objectTypeId, q, r, variant, mirrored, tiles }) => ({
        objectTypeId,
        q,
        r,
        variant,
        mirrored,
        tiles: [...tiles]
          .sort(byRowThenColumn)
          .map(({ q: tq, r: tr, blocks }) => ({ q: tq, r: tr, blocks })),
      })),
    props: [...draft.props]
      .sort(
        (a, b) =>
          byRowThenColumn(a, b) ||
          a.dy - b.dy ||
          a.dx - b.dx ||
          a.propTypeId - b.propTypeId ||
          a.variant - b.variant ||
          Number(a.mirrored) - Number(b.mirrored),
      )
      .map(({ propTypeId, q, r, dx, dy, variant, mirrored }) => ({
        propTypeId,
        q,
        r,
        dx,
        dy,
        variant,
        mirrored,
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

export function draftHash(draft: IslandDraft): string {
  return createHash('sha256').update(canonicalDraft(draft)).digest('hex');
}
