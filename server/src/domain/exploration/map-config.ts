export interface MapConfig {
  tileCount: number;
  edgeRoughness: number;
  noiseScale: number;
  waterFraction: number;
  deepFraction: number;
  wetLimit: number;
  stoneFraction: number;
  hillFrom: number;
  mountainFrom: number;
  islandChance: number;
  detailChance: number;
  cleanupPasses: number;
}

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

export function withDefaults(config: Partial<MapConfig>): MapConfig {
  return { ...DEFAULT_MAP_CONFIG, ...config };
}
