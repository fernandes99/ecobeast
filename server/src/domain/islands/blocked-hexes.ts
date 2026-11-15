import { type HexCoord, hexKey } from '../exploration/hex.js';
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

/** As linhas de bloqueio padrão de cada tipo de peça, pelo id do tipo. */
export type TypeBlocks = ReadonlyMap<number, readonly BlockLine[]>;

export interface BlockingProp extends HexCoord {
  propTypeId: number;
  dx: number;
  dy: number;
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
  return prop.block ?? typeBlocks.get(prop.propTypeId) ?? [];
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
 * Os hexágonos que uma linha toca: os do caminho dela, em passos de 1 px, e,
 * fechada, os de centro dentro dela. A mesma conta do `IslandBlocks` do jogo.
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
    const steps = Math.max(
      1,
      Math.ceil(Math.max(Math.abs(to.x - from.x), Math.abs(to.y - from.y))),
    );
    for (let step = 0; step <= steps; step++) {
      const t = step / steps;
      into.add(
        hexKey(
          gridCoord({
            x: from.x + (to.x - from.x) * t,
            y: from.y + (to.y - from.y) * t,
          }),
        ),
      );
    }
  }
  if (closed && points.length >= 3) addInsideHexes(points, into);
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
