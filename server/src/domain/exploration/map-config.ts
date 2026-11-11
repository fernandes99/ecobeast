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
  /** Parte da terra que é pedra. */
  stoneFraction: number;
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
  edgeRoughness: 200, // 0 = Hexagano perfeito nas bordas
  noiseScale: 0.05,
  waterFraction: 0.2,
  deepFraction: 0.5,
  wetLimit: 0.5,
  stoneFraction: 0.15,
  hillFrom: 0.6,
  mountainFrom: 0.95,
  islandChance: 0.05,
  detailChance: 0.2,
  cleanupPasses: 3,
};

/** A faixa aceita de um parâmetro, e se ele precisa ser inteiro. */
export interface ConfigRange {
  min: number;
  max: number;
  integer: boolean;
}

const fraction: ConfigRange = { min: 0, max: 1, integer: false };

/**
 * O que o editor de ilhas pode pedir ao gerador (.specs/map-editor/architecture.md,
 * "Rotas"). _A revisar._
 */
export const MAP_CONFIG_RANGES: Record<keyof MapConfig, ConfigRange> = {
  tileCount: { min: 100, max: 20_000, integer: true },
  edgeRoughness: { min: 0, max: 500, integer: false },
  noiseScale: { min: 0.005, max: 0.5, integer: false },
  waterFraction: fraction,
  deepFraction: fraction,
  wetLimit: fraction,
  stoneFraction: fraction,
  hillFrom: fraction,
  mountainFrom: fraction,
  islandChance: fraction,
  detailChance: fraction,
  cleanupPasses: { min: 0, max: 10, integer: true },
};

/**
 * O primeiro parâmetro fora da faixa, ou `null`. `label` dá o nome do campo na
 * mensagem (a API usa o nome em snake_case).
 */
export function mapConfigError(
  config: Partial<MapConfig>,
  label: (field: keyof MapConfig) => string = (field) => field,
): string | null {
  for (const [key, value] of Object.entries(config)) {
    const field = key as keyof MapConfig;
    const range = MAP_CONFIG_RANGES[field];
    if (range.integer && !Number.isInteger(value)) {
      return `${label(field)} precisa ser um número inteiro.`;
    }
    if (value < range.min || value > range.max) {
      return `${label(field)} precisa ficar entre ${range.min} e ${range.max}.`;
    }
  }
  return null;
}

/** Os parâmetros pedidos, com o padrão no que faltar. */
export function withDefaults(config: Partial<MapConfig>): MapConfig {
  return { ...DEFAULT_MAP_CONFIG, ...config };
}
