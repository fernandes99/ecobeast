/** Os parâmetros do spawn (.specs/biome-encounters/architecture.md, "Constantes"). */
export interface SpawnConfig {
  /** Quantos Ecobeasts nascem em um mapa. */
  count: number;
  /** Por quanto a taxa é multiplicada a cada nível que falta ao time. */
  missingLevelFactor: number;
  /** Quanto o time puxa o nível do selvagem, abaixo do nível natural. */
  pullBelow: number;
  /** Quanto o time puxa o nível do selvagem, do nível natural para cima. */
  pullAbove: number;
  /** Quantos níveis o sorteio varia para cada lado do centro. */
  levelSpread: number;
  /** Quanto soma ao nível natural de uma evolução sem nível mínimo. */
  unleveledEvolutionGap: number;
}

/** Valores iniciais, a revisar. */
export const DEFAULT_SPAWN_CONFIG: SpawnConfig = {
  count: 500,
  missingLevelFactor: 0.5,
  pullBelow: 0.25,
  pullAbove: 0.75,
  levelSpread: 5,
  unleveledEvolutionGap: 20,
};
