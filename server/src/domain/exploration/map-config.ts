export interface MapConfig {
  tileCount: number;
  edgeRoughness: number;
  noiseScale: number;
  seaFraction: number;
  coastRoughness: number;
  shallowWidth: number;
  beachMinWidth: number;
  beachMaxWidth: number;
  lakeCount: number;
  lakeMinWidth: number;
  lakeMaxWidth: number;
  riverCount: number;
  riverMinWidth: number;
  riverMaxWidth: number;
  springLakeChance: number;
  throughRiverChance: number;
  crossingSpacing: number;
  wetLimit: number;
  climate: number;
  stoneFrom: number;
  /** A parte da terra que o ruído das colinas soltas pega (rolling-hills/01). */
  hillFraction: number;
  /** A chance de cada cadeia de montanha ganhar a faixa de Colina ao pé. */
  foothillChance: number;
  mountainFrom: number;
  /** Os limites de altitude dos patamares 1, 4 e 7 (terrain-plateaus/02). */
  terraceLow: number;
  terraceHigh: number;
  /** Uma encosta extra a cada tantas bordas de paredão; 0 não abre nenhuma. */
  rampEvery: number;
  detailChance: number;
  cleanupPasses: number;
}

export const DEFAULT_MAP_CONFIG: MapConfig = {
  tileCount: 10000,
  edgeRoughness: 200, // 0 = Hexagano perfeito nas bordas
  noiseScale: 0.05,
  seaFraction: 0.3,
  coastRoughness: 0.25,
  shallowWidth: 2,
  beachMinWidth: 2,
  beachMaxWidth: 4,
  lakeCount: 4,
  lakeMinWidth: 6,
  lakeMaxWidth: 12,
  riverCount: 5,
  riverMinWidth: 2,
  riverMaxWidth: 4,
  springLakeChance: 0.35,
  throughRiverChance: 0.3,
  crossingSpacing: 14,
  wetLimit: 0.58,
  climate: 0,
  stoneFrom: 0.72,
  hillFraction: 0.1,
  foothillChance: 0.5,
  mountainFrom: 0.96,
  terraceLow: 0.45,
  terraceHigh: 0.75,
  rampEvery: 25,
  detailChance: 0.2,
  cleanupPasses: 3,
};

export interface ConfigRange {
  min: number;
  max: number;
  integer: boolean;
}

const fraction: ConfigRange = { min: 0, max: 1, integer: false };

export const MAP_CONFIG_RANGES: Record<keyof MapConfig, ConfigRange> = {
  tileCount: { min: 100, max: 20_000, integer: true },
  edgeRoughness: { min: 0, max: 500, integer: false },
  noiseScale: { min: 0.005, max: 0.5, integer: false },
  seaFraction: { min: 0, max: 0.8, integer: false },
  coastRoughness: fraction,
  shallowWidth: { min: 1, max: 6, integer: true },
  beachMinWidth: { min: 1, max: 8, integer: true },
  beachMaxWidth: { min: 1, max: 8, integer: true },
  lakeCount: { min: 0, max: 20, integer: true },
  lakeMinWidth: { min: 6, max: 40, integer: true },
  lakeMaxWidth: { min: 6, max: 40, integer: true },
  riverCount: { min: 0, max: 20, integer: true },
  riverMinWidth: { min: 1, max: 6, integer: true },
  riverMaxWidth: { min: 1, max: 6, integer: true },
  springLakeChance: fraction,
  throughRiverChance: fraction,
  crossingSpacing: { min: 4, max: 60, integer: true },
  wetLimit: fraction,
  climate: { min: 0, max: 4, integer: true },
  stoneFrom: fraction,
  hillFraction: fraction,
  foothillChance: fraction,
  mountainFrom: fraction,
  terraceLow: fraction,
  terraceHigh: fraction,
  rampEvery: { min: 0, max: 500, integer: true },
  detailChance: fraction,
  cleanupPasses: { min: 0, max: 10, integer: true },
};

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
  const { terraceLow, terraceHigh } = withDefaults(config);
  if (terraceLow >= terraceHigh) {
    return `${label('terraceLow')} precisa ser menor que ${label('terraceHigh')}.`;
  }
  return null;
}

export function withDefaults(config: Partial<MapConfig>): MapConfig {
  return { ...DEFAULT_MAP_CONFIG, ...config };
}
