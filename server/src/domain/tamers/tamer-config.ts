export type TamerSize = 1 | 2 | 3;

export interface TamerConfig {
  count: number;
  minStartDistance: number;
  sizeWeights: Record<TamerSize, number>;
}

export const TAMER_CONFIG: TamerConfig = {
  count: 25,
  minStartDistance: 3,
  sizeWeights: { 1: 1, 2: 1, 3: 1 },
};
