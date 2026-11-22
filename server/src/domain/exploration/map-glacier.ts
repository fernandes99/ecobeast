import type { Random } from '../battle/types.js';
import type { MapConfig } from './map-config.js';
import { type HexCoord, hexDistance } from './hex.js';

/** Um hexágono do gerador, no que a Geleira lê e muda (glacier/04). */
export interface GlacierCell extends HexCoord {
  biome: string;
  shape: string;
  height: number;
  neighbors: readonly GlacierCell[];
}

export interface GlacierPatch<C extends GlacierCell> {
  land: C[];
  /** O lago no meio da mancha, vazio quando ela sai sem lago. */
  lake: C[];
}

/** Até onde a Geleira fica longe de qualquer bioma que não seja Neve. */
const SNOW_MARGIN = 2;
/** O lago só cabe numa Geleira baixa: toda água fica na altura 0 (terrain-plateaus). */
const LAKE_MAX_HEIGHT = 1;
const LAKE_RADII = [2, 1] as const;
/** O lago de raio 2 tem a água funda no meio, até esta distância do centro. */
const DEEP_RADIUS = 1;
/** Quanto o sorteio entorta a borda da mancha, em hexágonos. A revisar. */
const EDGE_ROUGHNESS = 1.6;

/**
 * A mancha de Geleira de um mapa frio (glacier/04): um sorteio próprio decide se sai,
 * se tem lago e o tamanho. Ela nasce no hexágono de Neve mais longe da borda da Neve
 * e cresce só pela Neve a pelo menos 2 hexágonos de outro bioma. Muda os hexágonos e
 * devolve a mancha, ou null sem Geleira.
 */
export function placeGlacier<C extends GlacierCell>(
  cells: readonly C[],
  climate: string,
  start: C,
  random: Random,
  config: MapConfig,
): GlacierPatch<C> | null {
  if (climate !== 'cold') return null;
  if (random() >= config.glacierChance) return null;
  const wantsLake = random() < config.glacierLakeChance;
  const sizeRoll = random();

  const margin = snowMargin(cells);
  const candidates = new Set(
    cells.filter(
      (cell) => cell !== start && (margin.get(cell) ?? 0) >= SNOW_MARGIN,
    ),
  );
  const components = new Map<C, Set<C>>();
  const componentOf = (cell: C): Set<C> => {
    let component = components.get(cell);
    if (!component) {
      component = connected(cell, candidates);
      for (const member of component) components.set(member, component);
    }
    return component;
  };
  // Com o lago, o começo é o ponto baixo mais fundo na Neve onde o lago cabe.
  let begin: C | undefined;
  let lake: C[] = [];
  if (wantsLake) {
    const low = [...candidates]
      .filter((cell) => cell.height <= LAKE_MAX_HEIGHT)
      .sort((a, b) => margin.get(b)! - margin.get(a)!);
    for (const cell of low) {
      const component = componentOf(cell);
      if (component.size < config.glacierMin) continue;
      lake = lakeAround(cell, component, config);
      if (lake.length > 0) {
        begin = cell;
        break;
      }
    }
  }
  begin ??= deepest([...candidates], margin);
  if (!begin) return null;
  const component = componentOf(begin);
  if (component.size < config.glacierMin) return null;

  const room = component.size - lake.length;
  const span = config.glacierMax - config.glacierMin + 1;
  const target = Math.min(
    room,
    config.glacierMin + Math.floor(sizeRoll * span),
  );
  const land = grow(begin, lake, component, target, random);

  for (const cell of land) cell.biome = 'glacier';
  for (const cell of lake) {
    const deep = lake.length > 7 && hexDistance(cell, begin) <= DEEP_RADIUS;
    cell.biome = deep ? 'wdeep' : 'wshallow';
    cell.shape = 'flat';
    cell.height = 0;
  }
  return { land, lake };
}

/**
 * A distância de cada hexágono de Neve (fora da Montanha) até o bioma mais perto que
 * não é Neve; a beira do mapa conta como outro bioma.
 */
function snowMargin<C extends GlacierCell>(
  cells: readonly C[],
): Map<C, number> {
  const isSnow = (cell: GlacierCell) =>
    cell.biome === 'snow' && cell.shape !== 'mont';
  const margin = new Map<C, number>();
  let layer: C[] = [];
  for (const cell of cells) {
    if (!isSnow(cell)) margin.set(cell, 0);
  }
  for (const cell of cells) {
    if (isSnow(cell) && cell.neighbors.length < 6) {
      margin.set(cell, 1);
      layer.push(cell);
    }
  }
  for (const cell of cells) {
    if (margin.has(cell)) continue;
    if (cell.neighbors.some((next) => margin.get(next as C) === 0)) {
      margin.set(cell, 1);
      layer.push(cell);
    }
  }
  let distance = 1;
  while (layer.length > 0) {
    distance += 1;
    const next: C[] = [];
    for (const cell of layer) {
      for (const other of cell.neighbors as readonly C[]) {
        if (margin.has(other)) continue;
        margin.set(other, distance);
        next.push(other);
      }
    }
    layer = next;
  }
  return margin;
}

function deepest<C extends GlacierCell>(
  cells: readonly C[],
  margin: ReadonlyMap<C, number>,
): C | undefined {
  let best: C | undefined;
  for (const cell of cells) {
    if (!best || margin.get(cell)! > margin.get(best)!) best = cell;
  }
  return best;
}

function connected<C extends GlacierCell>(
  begin: C,
  allowed: ReadonlySet<C>,
): Set<C> {
  const seen = new Set([begin]);
  const pending = [begin];
  while (pending.length > 0) {
    for (const next of pending.pop()!.neighbors as readonly C[]) {
      if (seen.has(next) || !allowed.has(next)) continue;
      seen.add(next);
      pending.push(next);
    }
  }
  return seen;
}

const diskSize = (radius: number) => 1 + 3 * radius * (radius + 1);

/**
 * O lago redondo em volta do começo: o de raio 2 se ele, o anel de Geleira em volta
 * e a terra mínima couberem, senão o de raio 1, todo na Geleira baixa. Sem lugar, a
 * mancha sai sem lago.
 */
function lakeAround<C extends GlacierCell>(
  begin: C,
  component: ReadonlySet<C>,
  config: MapConfig,
): C[] {
  for (const radius of LAKE_RADII) {
    const disk = [...component].filter(
      (cell) => hexDistance(cell, begin) <= radius,
    );
    const ringed = [...component].filter(
      (cell) => hexDistance(cell, begin) <= radius + 1,
    );
    if (
      disk.length === diskSize(radius) &&
      ringed.length === diskSize(radius + 1) &&
      disk.every((cell) => cell.height <= LAKE_MAX_HEIGHT) &&
      component.size - disk.length >= config.glacierMin
    ) {
      return disk;
    }
  }
  return [];
}

/**
 * Cresce a terra em volta do começo (ou do anel do lago, que entra primeiro): sempre
 * entra o vizinho de menor distância ao começo mais um sorteio, o que deixa a borda
 * irregular.
 */
function grow<C extends GlacierCell>(
  begin: C,
  lake: readonly C[],
  component: ReadonlySet<C>,
  target: number,
  random: Random,
): C[] {
  const taken = new Set<C>(lake.length > 0 ? lake : []);
  const land: C[] = [];
  const score = new Map<C, number>();
  const frontier: C[] = [];
  const offer = (cell: C) => {
    if (taken.has(cell) || score.has(cell) || !component.has(cell)) return;
    score.set(cell, hexDistance(cell, begin) + random() * EDGE_ROUGHNESS);
    frontier.push(cell);
  };
  if (lake.length === 0) offer(begin);
  const ring = lake.length === diskSize(2) ? 3 : 2;
  for (const cell of lake.length > 0 ? component : []) {
    if (hexDistance(cell, begin) !== ring) continue;
    taken.add(cell);
    land.push(cell);
  }
  for (const cell of land) {
    for (const next of cell.neighbors as readonly C[]) offer(next);
  }
  while (land.length < target && frontier.length > 0) {
    let best = 0;
    for (let index = 1; index < frontier.length; index += 1) {
      if (score.get(frontier[index]!)! < score.get(frontier[best]!)!) {
        best = index;
      }
    }
    const cell = frontier.splice(best, 1)[0]!;
    taken.add(cell);
    land.push(cell);
    for (const next of cell.neighbors as readonly C[]) offer(next);
  }
  return land;
}
