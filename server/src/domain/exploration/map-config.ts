import type { Biome } from './map-generator.js';

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
  /** O quanto a temperatura de um mapa pode desviar da média. */
  climateShift: number;
  /** Abaixo disto, a temperatura dá neve. */
  coldLimit: number;
  /** Acima disto, a temperatura dá deserto ou campo quente. */
  hotLimit: number;
  /** Abaixo disto, a umidade é seca. */
  dryLimit: number;
  /** Acima disto, a umidade dá pântano ou floresta. */
  wetLimit: number;
  /** Acima deste valor de crista, o bioma é pedra. */
  stoneFrom: number;
  /** Faixa de elevação logo acima da água em que pode haver pântano. */
  swampBand: number;
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
  tileCount: 300,
  edgeRoughness: 7,
  noiseScale: 0.14,
  waterFraction: 0.22,
  deepFraction: 0.4,
  climateShift: 0.12,
  coldLimit: 0.12,
  hotLimit: 0.75,
  dryLimit: 0.45,
  wetLimit: 0.6,
  stoneFrom: 0.96,
  swampBand: 0.12,
  hillFrom: 0.8,
  mountainFrom: 0.9,
  islandChance: 0.04,
  detailChance: 0.2,
  cleanupPasses: 3,
};

/** Biomas que não podem ficar lado a lado. */
export const FORBIDDEN_BIOME_PAIRS: readonly (readonly [Biome, Biome])[] = [
  ['desert', 'snow'],
  ['desert', 'swamp'],
  ['desert', 'boreal'],
  ['snow', 'swamp'],
  ['snow', 'warm'],
];
