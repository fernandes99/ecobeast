import { type HexCoord, hexKey, hexNeighbors } from '../exploration/hex.js';
import { flatCenter, gridCoord, type PixelPoint } from './hex-pixels.js';

/**
 * Uma linha de bloqueio (free-objects): `points` é `x0, y0, x1, y1, …`, em
 * pixels da arte, no chão plano, a partir do pé da peça.
 */
export interface BlockLine {
  closed: boolean;
  points: number[];
}

export const MAX_BLOCK_LINES = 8;
export const MAX_BLOCK_POINTS = 64;
export const MAX_BLOCK_COORD = 512;
/** Peças que bloqueiam por ilha: segura o custo do blockedKeys. */
export const MAX_BLOCKING_PROPS = 2000;

/**
 * As linhas de bloqueio padrão dos tipos de peça, por `typeBlockKey(tipo, variante)`.
 * A variante 0 vale para as que não têm linhas próprias (prop-depth-blocks/02).
 */
export type TypeBlocks = ReadonlyMap<string, readonly BlockLine[]>;
export const ALL_VARIANTS = 0;
export const MAX_BLOCK_VARIANT = 99;
/** Um hexágono é bloqueado quando uma linha passa a até isto do centro dele. */
export const CENTER_REACH = 8;

export function typeBlockKey(propTypeId: number, variant: number): string {
  return `${propTypeId}:${variant}`;
}

/** As linhas padrão de uma variante: as próprias dela, ou as da variante 0. */
export function typeLines(
  typeBlocks: TypeBlocks,
  propTypeId: number,
  variant: number,
): readonly BlockLine[] {
  return (
    typeBlocks.get(typeBlockKey(propTypeId, variant)) ??
    typeBlocks.get(typeBlockKey(propTypeId, ALL_VARIANTS)) ??
    []
  );
}

export interface BlockingProp extends HexCoord {
  propTypeId: number;
  dx: number;
  dy: number;
  variant: number;
  mirrored: boolean;
  /** As linhas da própria peça; sem o campo, valem as do tipo. */
  block?: BlockLine[];
}

export function blockLineError(line: BlockLine): string | null {
  const { points } = line;
  const count = points.length / 2;
  if (
    points.length % 2 !== 0 ||
    count < 2 ||
    count > MAX_BLOCK_POINTS ||
    !points.every(Number.isInteger)
  ) {
    return `precisa ter de 2 a ${MAX_BLOCK_POINTS} pontos inteiros`;
  }
  if (line.closed && count < 3)
    return 'fechada precisa ter pelo menos 3 pontos';
  if (points.some((value) => Math.abs(value) > MAX_BLOCK_COORD)) {
    return `tem um ponto a mais de ${MAX_BLOCK_COORD} pixels do pé`;
  }
  return null;
}

export function propLines(
  prop: BlockingProp,
  typeBlocks: TypeBlocks,
): readonly BlockLine[] {
  return prop.block ?? typeLines(typeBlocks, prop.propTypeId, prop.variant);
}

/** As linhas de uma peça no chão plano, com o espelho. */
export function worldLines(
  prop: BlockingProp,
  typeBlocks: TypeBlocks,
): { closed: boolean; points: PixelPoint[] }[] {
  const center = flatCenter(prop);
  const footX = center.x + prop.dx;
  const footY = center.y + prop.dy;
  const sign = prop.mirrored ? -1 : 1;
  return propLines(prop, typeBlocks).map(({ closed, points }) => {
    const world: PixelPoint[] = [];
    for (let at = 0; at < points.length; at += 2) {
      world.push({ x: footX + sign * points[at]!, y: footY + points[at + 1]! });
    }
    return { closed, points: world };
  });
}

/** Uma parede no chão plano: `points` a partir do centro plano de (0, 0). */
export function wallLine(points: readonly number[]): PixelPoint[] {
  const origin = flatCenter({ q: 0, r: 0 });
  const world: PixelPoint[] = [];
  for (let at = 0; at < points.length; at += 2) {
    world.push({ x: origin.x + points[at]!, y: origin.y + points[at + 1]! });
  }
  return world;
}

/**
 * Os hexágonos que uma linha bloqueia: os de centro a até `CENTER_REACH` de um
 * trecho dela e, fechada, os de centro dentro dela (prop-depth-blocks/02). A
 * mesma conta do `IslandBlocks` do jogo.
 */
export function addLineHexes(
  points: readonly PixelPoint[],
  closed: boolean,
  into: Set<string>,
): void {
  const segments = closed ? points.length : points.length - 1;
  for (let index = 0; index < segments; index++) {
    const from = points[index]!;
    const to = points[(index + 1) % points.length]!;
    const seen = new Set<string>();
    const steps = Math.max(
      1,
      Math.ceil(
        Math.max(Math.abs(to.x - from.x), Math.abs(to.y - from.y)) /
          CENTER_REACH,
      ),
    );
    for (let step = 0; step <= steps; step++) {
      const t = step / steps;
      const coord = gridCoord({
        x: from.x + (to.x - from.x) * t,
        y: from.y + (to.y - from.y) * t,
      });
      for (const candidate of [coord, ...hexNeighbors(coord)]) {
        const key = hexKey(candidate);
        if (seen.has(key)) continue;
        seen.add(key);
        if (segmentDistance(flatCenter(candidate), from, to) <= CENTER_REACH) {
          into.add(key);
        }
      }
    }
  }
  if (closed && points.length >= 3) addInsideHexes(points, into);
}

function segmentDistance(
  point: PixelPoint,
  from: PixelPoint,
  to: PixelPoint,
): number {
  const dx = to.x - from.x;
  const dy = to.y - from.y;
  const length = dx * dx + dy * dy;
  const t =
    length === 0
      ? 0
      : Math.max(
          0,
          Math.min(
            1,
            ((point.x - from.x) * dx + (point.y - from.y) * dy) / length,
          ),
        );
  return Math.hypot(point.x - (from.x + dx * t), point.y - (from.y + dy * t));
}

const STEP_X = 64;
const STEP_Y = 42;

function addInsideHexes(points: readonly PixelPoint[], into: Set<string>) {
  const xs = points.map(({ x }) => x);
  const ys = points.map(({ y }) => y);
  const origin = flatCenter({ q: 0, r: 0 });
  const firstRow = Math.floor((Math.min(...ys) - origin.y) / STEP_Y) - 1;
  const lastRow = Math.ceil((Math.max(...ys) - origin.y) / STEP_Y) + 1;
  for (let r = firstRow; r <= lastRow; r++) {
    const shift = origin.x + (STEP_X / 2) * r;
    const firstColumn = Math.floor((Math.min(...xs) - shift) / STEP_X) - 1;
    const lastColumn = Math.ceil((Math.max(...xs) - shift) / STEP_X) + 1;
    for (let q = firstColumn; q <= lastColumn; q++) {
      if (inside(flatCenter({ q, r }), points)) into.add(hexKey({ q, r }));
    }
  }
}

function inside(point: PixelPoint, polygon: readonly PixelPoint[]): boolean {
  let result = false;
  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const a = polygon[i]!;
    const b = polygon[j]!;
    if (
      a.y > point.y !== b.y > point.y &&
      point.x < ((b.x - a.x) * (point.y - a.y)) / (b.y - a.y) + a.x
    ) {
      result = !result;
    }
  }
  return result;
}

/** Os hexágonos que as linhas das peças e as paredes tocam. */
export function lineBlockedKeys(
  props: readonly BlockingProp[],
  walls: readonly { points: readonly number[] }[],
  typeBlocks: TypeBlocks,
): Set<string> {
  const keys = new Set<string>();
  for (const prop of props) {
    for (const line of worldLines(prop, typeBlocks)) {
      addLineHexes(line.points, line.closed, keys);
    }
  }
  for (const wall of walls) addLineHexes(wallLine(wall.points), false, keys);
  return keys;
}
