export interface HexCoord {
  q: number;
  r: number;
}

export const HEX_DIRECTIONS: readonly HexCoord[] = [
  { q: 1, r: 0 },
  { q: -1, r: 0 },
  { q: 0, r: 1 },
  { q: 0, r: -1 },
  { q: 1, r: -1 },
  { q: -1, r: 1 },
];

export function hexKey({ q, r }: HexCoord): string {
  return `${q},${r}`;
}

export function hexNeighbors({ q, r }: HexCoord): HexCoord[] {
  return HEX_DIRECTIONS.map((direction) => ({
    q: q + direction.q,
    r: r + direction.r,
  }));
}

export function hexDistance(a: HexCoord, b: HexCoord): number {
  const dq = a.q - b.q;
  const dr = a.r - b.r;
  return (Math.abs(dq) + Math.abs(dr) + Math.abs(dq + dr)) / 2;
}
