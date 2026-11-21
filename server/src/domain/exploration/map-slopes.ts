import type { Random } from '../battle/types.js';
import { type HexCoord, hexDistance } from './hex.js';

/** Até 2 níveis passa; 3 ou mais é paredão (terrain-plateaus/01). */
export const MAX_CLIMB = 2;

export function climbable(
  a: { height: number },
  b: { height: number },
): boolean {
  return Math.abs(a.height - b.height) <= MAX_CLIMB;
}

export interface SlopeCell<C> extends HexCoord {
  height: number;
  neighbors: C[];
}

/** A terra que se alcança de `start`, a pé pela regra do paredão e pelas pontes. */
export function climbReach<C extends SlopeCell<C>>(
  start: C,
  links: ReadonlyMap<C, readonly C[]>,
  isWater: (cell: C) => boolean,
): Set<C> {
  const seen = new Set([start]);
  const pending = [start];
  while (pending.length > 0) {
    const cell = pending.pop()!;
    const next = [
      ...cell.neighbors.filter((other) => climbable(cell, other)),
      ...(links.get(cell) ?? []),
    ];
    for (const other of next) {
      if (seen.has(other) || isWater(other)) continue;
      seen.add(other);
      pending.push(other);
    }
  }
  return seen;
}

/**
 * A garantia de alcance (terrain-plateaus/01 RF-05): enquanto houver terra fora do
 * alcance, o caminho mais curto pela terra até ela vira encosta. Só sobe hexágonos; a
 * margem de uma ponte que sobe leva a outra junto (`levelLinks`).
 */
export function openSlopes<C extends SlopeCell<C>>(
  cells: readonly C[],
  start: C,
  links: ReadonlyMap<C, readonly C[]>,
  isWater: (cell: C) => boolean,
  random: Random,
): void {
  for (;;) {
    const reach = climbReach(start, links, isWater);
    const path = pathOut(cells, reach, isWater);
    if (!path) return;
    raiseAlong(path, random);
    levelLinks(links);
  }
}

/** As margens de cada ponte na mesma altura: a mais baixa sobe até a mais alta. */
export function levelLinks<C extends { height: number }>(
  links: ReadonlyMap<C, readonly C[]>,
): void {
  let changed = true;
  while (changed) {
    changed = false;
    for (const [bank, others] of links) {
      for (const other of others) {
        if (other.height === bank.height) continue;
        const height = Math.max(other.height, bank.height);
        bank.height = height;
        other.height = height;
        changed = true;
      }
    }
  }
}

/** Do alcance até o primeiro hexágono de terra fora dele, pela terra, sem a regra. */
function pathOut<C extends SlopeCell<C>>(
  cells: readonly C[],
  reach: ReadonlySet<C>,
  isWater: (cell: C) => boolean,
): C[] | undefined {
  if (!cells.some((cell) => !isWater(cell) && !reach.has(cell))) return;
  const came = new Map<C, C | undefined>();
  const pending: C[] = [];
  for (const cell of reach) {
    came.set(cell, undefined);
    pending.push(cell);
  }
  for (let index = 0; index < pending.length; index += 1) {
    const cell = pending[index]!;
    for (const next of cell.neighbors) {
      if (came.has(next) || isWater(next)) continue;
      came.set(next, cell);
      if (!reach.has(next)) {
        const path = [next];
        for (let back = came.get(next); back; back = came.get(back)) {
          path.unshift(back);
        }
        return path;
      }
      pending.push(next);
    }
  }
  return undefined;
}

/**
 * Sobe os hexágonos do caminho até cada passo ter no máximo 2 níveis: na ida e na
 * volta, quem está mais de 2 abaixo do anterior sobe até 1 ou 2 abaixo dele.
 */
export function raiseAlong<C extends { height: number }>(
  path: readonly C[],
  random: Random,
): void {
  const step = () => (random() < 0.5 ? 1 : 2);
  for (let index = 1; index < path.length; index += 1) {
    const before = path[index - 1]!;
    const cell = path[index]!;
    if (cell.height < before.height - MAX_CLIMB) {
      cell.height = before.height - step();
    }
  }
  for (let index = path.length - 2; index >= 0; index -= 1) {
    const after = path[index + 1]!;
    const cell = path[index]!;
    if (cell.height < after.height - MAX_CLIMB) {
      cell.height = after.height - step();
    }
  }
}

/** As encostas extras ficam a pelo menos isto uma da outra (terrain-plateaus/02). A revisar. */
export const RAMP_GAP = 8;
/** Quantos hexágonos a encosta se abre para os lados, do pé dela. A revisar. */
export const RAMP_MIN_WIDTH = 2;
export const RAMP_MAX_WIDTH = 5;
/** A chance de um degrau ter 1 nível; o resto tem 2. A revisar. */
export const SINGLE_STEP_CHANCE = 0.7;

/**
 * As encostas extras (terrain-plateaus/02 RF-10): uma a cada `every` bordas de paredão,
 * sorteadas longe umas das outras. Cada uma é uma escadaria de vários degraus no lado
 * baixo do paredão, aberta em leque a partir dele.
 */
export function openRamps<C extends SlopeCell<C>>(
  cells: readonly C[],
  every: number,
  canRaise: (cell: C) => boolean,
  isLand: (cell: C) => boolean,
  random: Random,
): number {
  if (every <= 0) return 0;
  const edges: [C, C][] = [];
  for (const high of cells) {
    if (!isLand(high)) continue;
    for (const low of high.neighbors) {
      if (isLand(low) && !climbable(high, low) && high.height > low.height) {
        edges.push([high, low]);
      }
    }
  }
  const wanted = Math.floor(edges.length / every);
  for (let index = edges.length - 1; index > 0; index -= 1) {
    const other = Math.floor(random() * (index + 1));
    [edges[index], edges[other]] = [edges[other]!, edges[index]!];
  }
  const starts: C[] = [];
  for (const [high, low] of edges) {
    if (starts.length >= wanted) break;
    if (climbable(high, low) || !canRaise(low)) continue;
    if (starts.some((start) => hexDistance(start, high) < RAMP_GAP)) continue;
    stairsFrom(high, low, canRaise, random);
    starts.push(high);
  }
  return starts.length;
}

/**
 * Os degraus, do alto ao pé: cada um 1 ou 2 abaixo do anterior, até o último ficar a
 * até 2 do chão de baixo.
 */
export function stepLevels(
  top: number,
  base: number,
  random: Random,
): number[] {
  const levels: number[] = [];
  let height = top;
  for (;;) {
    height -= random() < SINGLE_STEP_CHANCE ? 1 : 2;
    if (height <= base) return levels;
    levels.push(height);
  }
}

/**
 * A escadaria: os hexágonos do chão de baixo em volta do pé (`low`), até a largura
 * sorteada mais a fundura, sobem pelo degrau da distância até o alto, um anel por
 * degrau.
 */
function stairsFrom<C extends SlopeCell<C>>(
  high: C,
  low: C,
  canRaise: (cell: C) => boolean,
  random: Random,
): void {
  const base = low.height;
  const levels = stepLevels(high.height, base, random);
  const width =
    RAMP_MIN_WIDTH +
    Math.floor(random() * (RAMP_MAX_WIDTH - RAMP_MIN_WIDTH + 1));
  const reach = width + levels.length;
  const fits = (cell: C) => cell.height === base && canRaise(cell);
  const band = new Set([low]);
  const pending = [low];
  for (let index = 0; index < pending.length; index += 1) {
    for (const next of pending[index]!.neighbors) {
      if (band.has(next) || !fits(next) || hexDistance(next, low) > reach) {
        continue;
      }
      band.add(next);
      pending.push(next);
    }
  }
  const ring = new Map<C, number>();
  const queue: C[] = [];
  for (const cell of band) {
    if (cell.neighbors.some((next) => next.height >= high.height)) {
      ring.set(cell, 0);
      queue.push(cell);
    }
  }
  for (let index = 0; index < queue.length; index += 1) {
    const cell = queue[index]!;
    const depth = ring.get(cell)! + 1;
    if (depth >= levels.length) continue;
    for (const next of cell.neighbors) {
      if (!band.has(next) || ring.has(next)) continue;
      ring.set(next, depth);
      queue.push(next);
    }
  }
  for (const [cell, depth] of ring) cell.height = levels[depth]!;
}
