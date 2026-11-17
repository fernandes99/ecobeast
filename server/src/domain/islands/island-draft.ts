import { createHash } from 'node:crypto';
import { type HexCoord, hexKey } from '../exploration/hex.js';
import {
  BIOMES,
  type Biome,
  isWater,
  MAX_HEIGHT,
  maxVariant,
} from '../exploration/map-generator.js';
import {
  type BlockLine,
  blockLineError,
  lineBlockedKeys,
  MAX_BLOCK_LINES,
  MAX_BLOCKING_PROPS,
  propLines,
  type TypeBlocks,
} from './blocked-hexes.js';
import { flatCenter, gridCoord } from './hex-pixels.js';

export const MAX_ISLAND_TILES = 20_000;
const MAX_NAME_LENGTH = 40;
const MIN_LEVEL = 1;
const MAX_LEVEL = 100;
const COLOR_HEX = /^#[0-9A-Fa-f]{6}$/;
export const MIN_AREA_SPAWNS = 1;
export const MAX_AREA_SPAWNS = 200;
export const MAX_PROPS = 20_000;
export const MAX_PROP_ACTIONS = 500;
export const MAX_TRAILS = 500;
const MAX_TRAIL_POINTS = 256;
const MIN_TRAIL_WIDTH = 8;
const MAX_TRAIL_WIDTH = 64;
export const MAX_WALLS = 2000;
const MAX_WALL_POINTS = 128;
export const MAX_BRIDGES = 500;
const MIN_BRIDGE_LENGTH = 16;
export const DEFAULT_BRIDGE_WIDTH = 28;
const MIN_BRIDGE_WIDTH = 16;
const MAX_BRIDGE_WIDTH = 64;
export const MAX_NPCS = 200;
export const MAX_NPC_TILES = 40;
export const MAX_DIALOGUE_LENGTH = 2_000;

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

/** Uma peça solta: o pé em `(dx, dy)` pixels do centro plano de `(q, r)`. */
export interface DraftProp extends HexCoord {
  propTypeId: number;
  dx: number;
  dy: number;
  variant: number;
  mirrored: boolean;
  /** As linhas de bloqueio ajustadas (free-objects); sem o campo, valem as do tipo. */
  block?: BlockLine[];
  /** A ação que acontece ao encostar no bloqueio (free-objects/03). */
  actionTypeId?: number;
  /** A casa fica sem a fumaça da chaminé (chimney-smoke/01); só existe quando é verdade. */
  noSmoke?: true;
}

/**
 * Um traço de caminho (free-trails/03): `points` é `x0, y0, x1, y1, …`, em pixels
 * da arte no chão plano, a partir do centro plano do hexágono (0, 0).
 */
export interface DraftTrail {
  ground: string;
  width: number;
  points: number[];
}

/**
 * Uma parede (free-fences/01): `type` é o slug de `wall_types`, e `points` é como o
 * de um traço.
 */
export interface DraftWall {
  type: string;
  points: number[];
}

/**
 * Uma ponte (bridges/01): `type` é o slug de `bridge_types`, e `points` são as duas
 * pontas, `x0, y0, x1, y1`, como os de uma parede.
 */
export interface DraftBridge {
  type: string;
  points: number[];
  /** A largura do piso em pixels; sem ela, `DEFAULT_BRIDGE_WIDTH`. */
  width?: number;
}

/** Um NPC do catálogo posto em `(q, r)`, que também faz parte do passeio. */
export interface DraftNpc extends HexCoord {
  npcId: number;
  still: boolean;
  /** O passeio, sem o hexágono de nascimento. */
  tiles: HexCoord[];
  dialogue: string;
  actionTypeId: number | null;
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
  props: DraftProp[];
  trails?: DraftTrail[];
  walls?: DraftWall[];
  bridges?: DraftBridge[];
  npcs?: DraftNpc[];
  areas: DraftArea[];
}

export interface KnownIds {
  actionTypeIds: ReadonlySet<number>;
  groundSlugs: ReadonlySet<string>;
  speciesIds: ReadonlySet<number>;
  /** O máximo de variantes de cada tipo de peça solta. */
  propVariants: ReadonlyMap<number, number>;
  npcIds: ReadonlySet<number>;
  wallSlugs: ReadonlySet<string>;
  bridgeSlugs: ReadonlySet<string>;
  /** As linhas de bloqueio padrão de cada tipo de peça. */
  propBlocks: TypeBlocks;
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

function propsError(
  props: DraftProp[],
  tiles: ReadonlySet<string>,
  known: KnownIds,
): string | null {
  if (props.length > MAX_PROPS) return 'A ilha pode ter até 20.000 peças.';
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
    if (prop.block !== undefined) {
      if (prop.block.length > MAX_BLOCK_LINES) {
        return `A peça ${number} pode ter até ${MAX_BLOCK_LINES} linhas de bloqueio.`;
      }
      for (const [lineIndex, line] of prop.block.entries()) {
        const error = blockLineError(line);
        if (error) {
          return `A linha de bloqueio ${lineIndex + 1} da peça ${number} ${error}.`;
        }
      }
    }
  }
  for (const [index, prop] of props.entries()) {
    if (
      prop.actionTypeId !== undefined &&
      !known.actionTypeIds.has(prop.actionTypeId)
    ) {
      return `A peça ${index + 1} tem uma ação que não existe.`;
    }
  }
  if (
    props.filter(({ actionTypeId }) => actionTypeId !== undefined).length >
    MAX_PROP_ACTIONS
  ) {
    return 'A ilha pode ter até 500 peças com ação.';
  }
  const blocking = props.filter(
    (prop) => propLines(prop, known.propBlocks).length > 0,
  ).length;
  if (blocking > MAX_BLOCKING_PROPS) {
    return 'A ilha pode ter até 2.000 peças que bloqueiam.';
  }
  return null;
}

function trailsError(
  trails: DraftTrail[],
  tiles: ReadonlySet<string>,
  known: KnownIds,
): string | null {
  if (trails.length > MAX_TRAILS) return 'A ilha pode ter até 500 traços.';
  const origin = flatCenter({ q: 0, r: 0 });
  for (const [index, trail] of trails.entries()) {
    const number = index + 1;
    if (!known.groundSlugs.has(trail.ground)) {
      return `O traço ${number} tem um tipo de chão que não existe.`;
    }
    if (
      !Number.isInteger(trail.width) ||
      trail.width < MIN_TRAIL_WIDTH ||
      trail.width > MAX_TRAIL_WIDTH
    ) {
      return `O traço ${number} tem a largura ${trail.width}: vai de ${MIN_TRAIL_WIDTH} a ${MAX_TRAIL_WIDTH}.`;
    }
    const { points } = trail;
    if (
      points.length % 2 !== 0 ||
      points.length < 4 ||
      points.length > MAX_TRAIL_POINTS * 2 ||
      !points.every(Number.isInteger)
    ) {
      return `O traço ${number} precisa ter de 2 a ${MAX_TRAIL_POINTS} pontos inteiros.`;
    }
    for (let at = 0; at < points.length; at += 2) {
      const hex = gridCoord({
        x: origin.x + points[at]!,
        y: origin.y + points[at + 1]!,
      });
      if (!tiles.has(hexKey(hex))) {
        return `O traço ${number} tem um ponto fora da ilha.`;
      }
    }
  }
  return null;
}

function wallsError(
  walls: DraftWall[],
  tiles: ReadonlySet<string>,
  known: KnownIds,
): string | null {
  if (walls.length > MAX_WALLS) return 'A ilha pode ter até 2.000 paredes.';
  const origin = flatCenter({ q: 0, r: 0 });
  for (const [index, wall] of walls.entries()) {
    const number = index + 1;
    if (!known.wallSlugs.has(wall.type)) {
      return `A parede ${number} tem um tipo que não existe.`;
    }
    const { points } = wall;
    if (
      points.length % 2 !== 0 ||
      points.length < 4 ||
      points.length > MAX_WALL_POINTS * 2 ||
      !points.every(Number.isInteger)
    ) {
      return `A parede ${number} precisa ter de 2 a ${MAX_WALL_POINTS} pontos inteiros.`;
    }
    for (let at = 0; at < points.length; at += 2) {
      const hex = gridCoord({
        x: origin.x + points[at]!,
        y: origin.y + points[at + 1]!,
      });
      if (!tiles.has(hexKey(hex))) {
        return `A parede ${number} tem um ponto fora da ilha.`;
      }
    }
  }
  return null;
}

function bridgesError(
  bridges: DraftBridge[],
  biomes: ReadonlyMap<string, Biome>,
  known: KnownIds,
): string | null {
  if (bridges.length > MAX_BRIDGES) return 'A ilha pode ter até 500 pontes.';
  const origin = flatCenter({ q: 0, r: 0 });
  for (const [index, bridge] of bridges.entries()) {
    const number = index + 1;
    if (!known.bridgeSlugs.has(bridge.type)) {
      return `A ponte ${number} tem um tipo que não existe.`;
    }
    const { points, width } = bridge;
    if (points.length !== 4 || !points.every(Number.isInteger)) {
      return `A ponte ${number} precisa ter 2 pontas.`;
    }
    if (
      width !== undefined &&
      (!Number.isInteger(width) ||
        width < MIN_BRIDGE_WIDTH ||
        width > MAX_BRIDGE_WIDTH)
    ) {
      return `A ponte ${number} precisa ter de ${MIN_BRIDGE_WIDTH} a ${MAX_BRIDGE_WIDTH} px de largura.`;
    }
    for (let at = 0; at < points.length; at += 2) {
      const biome = biomes.get(
        hexKey(
          gridCoord({
            x: origin.x + points[at]!,
            y: origin.y + points[at + 1]!,
          }),
        ),
      );
      if (biome === undefined || isWater(biome)) {
        return 'A ponta da ponte precisa ficar em terra.';
      }
    }
    const [x0, y0, x1, y1] = points as [number, number, number, number];
    if (Math.hypot(x1 - x0, y1 - y0) < MIN_BRIDGE_LENGTH) {
      return `A ponte ${number} precisa ter pelo menos ${MIN_BRIDGE_LENGTH} px.`;
    }
  }
  return null;
}

function npcsError(
  npcs: DraftNpc[],
  biomes: ReadonlyMap<string, Biome>,
  known: KnownIds,
): string | null {
  const water = (coord: HexCoord): boolean =>
    isWater(biomes.get(hexKey(coord))!);
  if (npcs.length > MAX_NPCS) return 'A ilha pode ter até 200 NPCs.';
  for (const [index, npc] of npcs.entries()) {
    const number = index + 1;
    if (!known.npcIds.has(npc.npcId)) {
      return `O NPC ${number} não existe no catálogo.`;
    }
    if (!biomes.has(hexKey(npc))) {
      return `O NPC ${number} fica em ${at(npc)}, que não é da ilha.`;
    }
    if (water(npc)) return 'O NPC não pode ficar na água.';
    const walk = new Set([hexKey(npc)]);
    for (const coord of npc.tiles) {
      const key = hexKey(coord);
      if (!biomes.has(key)) {
        return `O NPC ${number} passeia por ${at(coord)}, que não é da ilha.`;
      }
      if (water(coord)) return 'O NPC não pode ficar na água.';
      if (walk.has(key)) {
        return `O NPC ${number} repete o hexágono ${at(coord)} no passeio.`;
      }
      walk.add(key);
    }
    if (npc.tiles.length > MAX_NPC_TILES) {
      return `O NPC ${number} passeia por mais de 40 hexágonos.`;
    }
    // Em code points, como o char_length do banco e o length do Godot.
    if ([...npc.dialogue].length > MAX_DIALOGUE_LENGTH) {
      return `O diálogo do NPC ${number} passa de 2.000 caracteres.`;
    }
    if (
      npc.actionTypeId !== null &&
      !known.actionTypeIds.has(npc.actionTypeId)
    ) {
      return `O NPC ${number} tem uma ação que não existe.`;
    }
  }
  return null;
}

/** Os hexágonos que alguma linha de bloqueio, de peça ou de parede, toca (free-objects). */
export function blockedKeys(
  draft: Pick<IslandDraft, 'props' | 'walls'>,
  typeBlocks: TypeBlocks,
): ReadonlySet<string> {
  return lineBlockedKeys(draft.props, draft.walls ?? [], typeBlocks);
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
  const biomes = new Map<string, Biome>();
  for (const tile of draft.tiles) {
    const key = hexKey(tile);
    if (tiles.has(key)) return `O hexágono ${at(tile)} aparece duas vezes.`;
    tiles.add(key);
    biomes.set(key, tile.biome);
    const error = tileError(tile, known);
    if (error) return error;
  }
  if (!tiles.has(hexKey(draft.start))) {
    return 'A chegada precisa ser um hexágono da ilha.';
  }
  const actions = actionsError(draft.actions, tiles, known);
  if (actions) return actions;
  const props = propsError(draft.props, tiles, known);
  if (props) return props;
  const trails = trailsError(draft.trails ?? [], tiles, known);
  if (trails) return trails;
  const walls = wallsError(draft.walls ?? [], tiles, known);
  if (walls) return walls;
  const bridges = bridgesError(draft.bridges ?? [], biomes, known);
  if (bridges) return bridges;
  const npcs = npcsError(draft.npcs ?? [], biomes, known);
  if (npcs) return npcs;

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
  if (blockedKeys(draft, known.propBlocks).has(startKey)) {
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
 * peças em ordem de (r, q, dy, dx, tipo, variante, espelho), traços na ordem
 * da lista (só quando há algum), paredes na ordem da lista (só quando há alguma),
 * pontes na ordem da lista (só quando há alguma),
 * NPCs em ordem de (r, q, npc_id), cada um com o
 * passeio em (r, q) (só quando há algum),
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
    props: [...draft.props]
      .sort(
        (a, b) =>
          byRowThenColumn(a, b) ||
          a.dy - b.dy ||
          a.dx - b.dx ||
          a.propTypeId - b.propTypeId ||
          a.variant - b.variant ||
          Number(a.mirrored) - Number(b.mirrored) ||
          compareText(blockText(a), blockText(b)),
      )
      .map(
        ({
          propTypeId,
          q,
          r,
          dx,
          dy,
          variant,
          mirrored,
          block,
          actionTypeId,
        }) => ({
          propTypeId,
          q,
          r,
          dx,
          dy,
          variant,
          mirrored,
          // Só quando há: uma ilha sem ajuste nem ação tem o hash de antes.
          ...(block === undefined ? {} : { block: canonicalBlock(block) }),
          ...(actionTypeId === undefined ? {} : { actionTypeId }),
        }),
      ),
    // Só com traços: uma ilha sem traços tem o hash de antes.
    ...(draft.trails?.length
      ? {
          trails: draft.trails.map(({ ground, width, points }) => ({
            ground,
            width,
            points: [...points],
          })),
        }
      : {}),
    // Só com paredes: uma ilha sem paredes tem o hash de antes.
    ...(draft.walls?.length
      ? {
          walls: draft.walls.map(({ type, points }) => ({
            type,
            points: [...points],
          })),
        }
      : {}),
    // Só com pontes: uma ilha sem pontes tem o hash de antes.
    ...(draft.bridges?.length
      ? {
          bridges: draft.bridges.map(({ type, points, width }) => ({
            type,
            points: [...points],
            width: width ?? DEFAULT_BRIDGE_WIDTH,
          })),
        }
      : {}),
    // Só com NPCs: uma ilha sem NPC tem o hash de antes.
    ...(draft.npcs?.length ? { npcs: canonicalNpcs(draft.npcs) } : {}),
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

function canonicalBlock(block: BlockLine[]) {
  return block.map(({ closed, points }) => ({ closed, points: [...points] }));
}

function blockText(prop: DraftProp): string {
  return JSON.stringify([
    prop.block === undefined ? null : canonicalBlock(prop.block),
    prop.actionTypeId ?? null,
  ]);
}

const compareText = (a: string, b: string): number =>
  a < b ? -1 : a > b ? 1 : 0;

function canonicalNpcs(npcs: DraftNpc[]) {
  return npcs
    .map(({ npcId, q, r, still, tiles, dialogue, actionTypeId }) => ({
      npcId,
      q,
      r,
      still,
      tiles: [...tiles].sort(byRowThenColumn).map(({ q, r }) => ({ q, r })),
      dialogue,
      actionTypeId,
    }))
    .map((npc) => ({ npc, text: JSON.stringify(npc) }))
    .sort(
      (a, b) =>
        byRowThenColumn(a.npc, b.npc) ||
        a.npc.npcId - b.npc.npcId ||
        (a.text < b.text ? -1 : a.text > b.text ? 1 : 0),
    )
    .map(({ npc }) => npc);
}

export function draftHash(draft: IslandDraft): string {
  return createHash('sha256').update(canonicalDraft(draft)).digest('hex');
}
