export interface TamerLevelRow {
  level: number;
  xpTotal: number;
  rewardCoins: number;
  rewardItemId: number | null;
  rewardItemQuantity: number | null;
}

export type TamerXpSources = ReadonlyMap<string, number>;

export interface TamerBattleInput {
  rawEnemyXp: number;
  victory: boolean;
  opponentIsTamer: boolean;
  newSpeciesCount: number;
  /** O Domador da ilha (auralis/04): a primeira vitória ou uma revanche, no lugar do `tamer_win`. */
  islandTamer?: 'first' | 'rematch';
  islandUnlocked?: boolean;
}

export interface TamerLevelUp {
  xp: number;
  level: number;
  levels: TamerLevelRow[];
}

export function tamerXpFromBattle(
  input: TamerBattleInput,
  sources: TamerXpSources,
): number {
  const source = (slug: string): number => sources.get(slug) ?? 0;
  let xp = input.newSpeciesCount * source('new_species');
  if (input.victory) {
    xp += Math.floor((input.rawEnemyXp * source('battle_xp_percent')) / 100);
    if (input.islandTamer === 'first') xp += source('island_tamer_win');
    else if (input.islandTamer === 'rematch') {
      xp += source('island_tamer_rematch');
    } else if (input.opponentIsTamer) xp += source('tamer_win');
    if (input.islandUnlocked) xp += source('island_unlocked');
  }
  return xp;
}

export function addTamerXp(
  xp: number,
  level: number,
  gained: number,
  levels: readonly TamerLevelRow[],
): TamerLevelUp {
  const total = xp + gained;
  const reached = levels.filter(
    (row) => row.level > level && row.xpTotal <= total,
  );
  return {
    xp: total,
    level: reached.at(-1)?.level ?? level,
    levels: reached,
  };
}

export function levelBounds(
  level: number,
  levels: readonly TamerLevelRow[],
): { levelXp: number; nextLevelXp: number | null } {
  return {
    levelXp: levels.find((row) => row.level === level)?.xpTotal ?? 0,
    nextLevelXp: levels.find((row) => row.level === level + 1)?.xpTotal ?? null,
  };
}
