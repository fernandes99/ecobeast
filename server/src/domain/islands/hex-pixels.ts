import type { HexCoord } from '../exploration/hex.js';

/**
 * A geometria do mapa em pixels da arte, copiada do `HexMapView` do jogo
 * (`flat_center` e `grid_coord`): as duas contas precisam dar o mesmo hexágono.
 */
const STEP_X = 64;
const STEP_Y = 42;
const ROW_SHIFT = 32;
const SURFACE_CENTER = { x: 32, y: 29 };
const SLOPE_HEIGHT = 16;

export interface PixelPoint {
  x: number;
  y: number;
}

export function flatCenter({ q, r }: HexCoord): PixelPoint {
  return {
    x: STEP_X * q + ROW_SHIFT * r + SURFACE_CENTER.x,
    y: STEP_Y * r + SURFACE_CENTER.y,
  };
}

export function gridCoord({ x: px, y: py }: PixelPoint): HexCoord {
  const r = Math.floor(py / STEP_Y);
  const insideRow = py - r * STEP_Y;
  const x = px - ROW_SHIFT * r;
  const q = Math.floor(x / STEP_X);
  const insideCell = x - q * STEP_X;
  if (insideCell < ROW_SHIFT) {
    if (insideRow < SLOPE_HEIGHT - insideCell / 2) return { q, r: r - 1 };
  } else if (insideRow < (insideCell - ROW_SHIFT) / 2) {
    return { q: q + 1, r: r - 1 };
  }
  return { q, r };
}
