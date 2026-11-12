export interface SpawnConfig {
  count: number;
  missingLevelFactor: number;
  pullBelow: number;
  pullAbove: number;
  levelSpread: number;
  unleveledEvolutionGap: number;
}

export const DEFAULT_SPAWN_CONFIG: SpawnConfig = {
  count: 500,
  missingLevelFactor: 0.5,
  pullBelow: 0.25,
  pullAbove: 0.75,
  levelSpread: 5,
  unleveledEvolutionGap: 20,
};
