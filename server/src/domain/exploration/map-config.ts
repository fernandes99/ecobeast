/** Os parâmetros do gerador (.specs/wild-battle/architecture.md, "Gerador"). */
export interface MapConfig {
  /** Quantos hexágonos o mapa tem. */
  tileCount: number;
  /** Quanto o ruído recorta a borda, em hexágonos. */
  edgeRoughness: number;
  /** Tamanho das regiões: quanto menor, maiores elas ficam. */
  noiseScale: number;
  /** Parte do mapa que é água. */
  waterFraction: number;
  /** Parte da água que é funda. */
  deepFraction: number;
  /** Acima disto, a umidade dá floresta. */
  wetLimit: number;
  /** Acima deste valor de crista, o bioma é pedra. */
  stoneFrom: number;
  /** Acima deste valor de crista, a terra é colina. */
  hillFrom: number;
  /** Acima deste valor de crista, a terra é montanha. */
  mountainFrom: number;
  /** Chance de um hexágono de água ser uma ilha. */
  islandChance: number;
  /** Chance de um hexágono plano usar uma variante com mais detalhe. */
  detailChance: number;
  /** Quantas vezes a limpeza junta biomas sozinhos aos vizinhos. */
  cleanupPasses: number;
}

/** Valores iniciais, a revisar. */
export const DEFAULT_MAP_CONFIG: MapConfig = {
  tileCount: 10000,
  edgeRoughness: 0, // 0 = Hexagano perfeito nas bordas
  noiseScale: 0.05,
  waterFraction: 0.20,
  deepFraction: 0.5,
  wetLimit: 0.50,
  stoneFrom: 0.95,
  hillFrom: 0.76,
  mountainFrom: 0.88,
  islandChance: 0.05,
  detailChance: 0.20,
  cleanupPasses: 3,
};
