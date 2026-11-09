/** Os tamanhos de luta de um Domador NPC: 1×1, 2×2 ou 3×3. */
export type TamerSize = 1 | 2 | 3;

/** Os parâmetros dos Domadores NPC (.specs/npc-tamers/architecture.md, "Constantes"). */
export interface TamerConfig {
  /** Quantos Domadores nascem em um mapa. */
  count: number;
  /** Até quantos hexágonos da largada nenhum Domador nasce. */
  minStartDistance: number;
  /** O peso de cada tamanho de luta no sorteio. */
  sizeWeights: Record<TamerSize, number>;
}

/** Valores iniciais, a revisar. */
export const TAMER_CONFIG: TamerConfig = {
  count: 25,
  minStartDistance: 3,
  sizeWeights: { 1: 1, 2: 1, 3: 1 },
};
