/**
 * A sala de um interior (.specs/interiors/architecture.md): o corpo que o editor
 * salva e as regras dele. O servidor não lê as folhas: a parede não bloqueia
 * sozinha, e um quadrado bloqueia sem chão ou em `blocks`.
 */

export const INTERIOR_LAYERS = ['floor', 'floor_detail', 'wall', 'wall_detail'] as const;
export const MIN_SIZE = 4;
export const MAX_SIZE = 64;
export const MAX_NAME_LENGTH = 40;
export const MAX_TILES = 16_384;
export const MAX_OBJECTS = 1_000;
export const MAX_NPCS = 50;
export const MAX_DIALOGUE = 2_000;
export const MAX_OBJECT_SIZE = 8;
export const MAX_SHEET_CELL = 63;

export const NPC_NEEDS_FREE = 'O NPC precisa de um quadrado livre.';
export const DOOR_NEEDS_FLOOR =
  'A porta precisa estar num quadrado de chão, sem bloqueio.';

export interface Cell {
  x: number;
  y: number;
}

export interface InteriorTileBody extends Cell {
  layer: string;
  sheet: string;
  col: number;
  row: number;
}

export interface InteriorObjectBody extends Cell {
  sheet: string;
  col: number;
  row: number;
  width: number;
  height: number;
}

export interface InteriorNpcBody extends Cell {
  npc_id: number;
  dialogue: string;
  action_type_id: number | null;
}

export interface InteriorBody {
  name: string;
  width: number;
  height: number;
  door: Cell;
  tiles: InteriorTileBody[];
  objects: InteriorObjectBody[];
  blocks: Cell[];
  npcs: InteriorNpcBody[];
}

export interface InteriorKnownIds {
  npcIds: ReadonlySet<number>;
  actionTypeIds: ReadonlySet<number>;
}

const SHEET = /^[a-z0-9_]+$/;
const key = ({ x, y }: Cell): string => `${x},${y}`;

function inSheet(sheet: string, col: number, row: number): boolean {
  return (
    SHEET.test(sheet) &&
    Number.isInteger(col) &&
    Number.isInteger(row) &&
    col >= 0 &&
    row >= 0 &&
    col <= MAX_SHEET_CELL &&
    row <= MAX_SHEET_CELL
  );
}

/** A mensagem do primeiro erro da sala, ou `null`. */
export function interiorError(
  body: InteriorBody,
  known: InteriorKnownIds,
): string | null {
  const name = body.name ?? '';
  if (name.length < 1 || name.length > MAX_NAME_LENGTH) {
    return 'O nome precisa ter de 1 a 40 caracteres.';
  }
  const { width, height } = body;
  const sized = (value: number) =>
    Number.isInteger(value) && value >= MIN_SIZE && value <= MAX_SIZE;
  if (!sized(width) || !sized(height)) {
    return 'A largura e a altura vão de 4 a 64 quadrados.';
  }
  if (body.tiles.length > MAX_TILES) return 'A sala pode ter até 16.384 tiles.';
  if (body.objects.length > MAX_OBJECTS) return 'A sala pode ter até 1.000 objetos.';
  if (body.npcs.length > MAX_NPCS) return 'A sala pode ter até 50 NPCs.';

  const inside = ({ x, y }: Cell) =>
    Number.isInteger(x) && Number.isInteger(y) && x >= 0 && y >= 0 && x < width && y < height;

  const floor = new Set<string>();
  const placed = new Set<string>();
  for (const tile of body.tiles) {
    if (
      !(INTERIOR_LAYERS as readonly string[]).includes(tile.layer) ||
      !inSheet(tile.sheet, tile.col, tile.row)
    ) {
      return 'Há um tile inválido.';
    }
  }
  for (const tile of body.tiles) {
    if (!inside(tile)) return 'Há um tile fora da sala.';
  }
  for (const tile of body.tiles) {
    const at = `${tile.layer}:${key(tile)}`;
    if (placed.has(at)) return 'Há dois tiles no mesmo quadrado e camada.';
    placed.add(at);
    if (tile.layer === 'floor') floor.add(key(tile));
  }

  for (const object of body.objects) {
    const sized = (value: number) =>
      Number.isInteger(value) && value >= 1 && value <= MAX_OBJECT_SIZE;
    if (!inSheet(object.sheet, object.col, object.row) || !sized(object.width) || !sized(object.height)) {
      return 'Há um objeto inválido.';
    }
  }
  for (const object of body.objects) {
    const last = { x: object.x + object.width - 1, y: object.y + object.height - 1 };
    if (!inside(object) || !inside(last)) return 'Há um objeto que passa da borda da sala.';
  }

  const blocked = new Set<string>();
  for (const block of body.blocks) {
    if (!inside(block)) return 'Há um bloqueio fora da sala.';
  }
  for (const block of body.blocks) {
    if (blocked.has(key(block))) return 'Há um bloqueio repetido.';
    blocked.add(key(block));
  }

  const free = (cell: Cell) => inside(cell) && floor.has(key(cell)) && !blocked.has(key(cell));
  for (const npc of body.npcs) {
    if ((npc.dialogue ?? '').length > MAX_DIALOGUE) {
      return 'A fala do NPC pode ter até 2.000 caracteres.';
    }
  }
  for (const npc of body.npcs) {
    if (!known.npcIds.has(npc.npc_id)) return 'Esse NPC não existe.';
    if (npc.action_type_id !== null && !known.actionTypeIds.has(npc.action_type_id)) {
      return 'O NPC tem uma ação que não existe.';
    }
  }
  const taken = new Set<string>();
  for (const npc of body.npcs) {
    const at = key(npc);
    if (!free(npc) || at === key(body.door) || taken.has(at)) return NPC_NEEDS_FREE;
    taken.add(at);
  }

  if (!free(body.door)) return DOOR_NEEDS_FLOOR;
  return null;
}
