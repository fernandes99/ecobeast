export interface ArchipelagoIsland {
  id: number;
  order: number;
}

export type IslandState = 'open' | 'next' | 'hidden';

export interface ArchipelagoEntry extends ArchipelagoIsland {
  state: IslandState;
}

/** O estado de cada ilha do Arquipélago, em ordem: a 1ª sempre aberta (auralis/01). */
export function archipelagoStates(
  islands: readonly ArchipelagoIsland[],
  unlocked: ReadonlySet<number>,
): ArchipelagoEntry[] {
  const sorted = [...islands].sort((a, b) => a.order - b.order);
  let nextFound = false;
  return sorted.map((island, index) => {
    if (index === 0 || unlocked.has(island.id)) {
      return { ...island, state: 'open' };
    }
    const state: IslandState = nextFound ? 'hidden' : 'next';
    nextFound = true;
    return { ...island, state };
  });
}

/** Trancada é só a ilha do Arquipélago que não está aberta; as de fora abrem. */
export function isLocked(
  islands: readonly ArchipelagoIsland[],
  unlocked: ReadonlySet<number>,
  islandId: number,
): boolean {
  const entry = archipelagoStates(islands, unlocked).find(
    (island) => island.id === islandId,
  );
  return entry !== undefined && entry.state !== 'open';
}

/** A ilha que abre quando esta fica completa: a de menor ordem acima dela (auralis/04). */
export function nextIslandAfter(
  islands: readonly ArchipelagoIsland[],
  islandId: number,
): number | null {
  const current = islands.find((island) => island.id === islandId);
  if (!current) return null;
  const after = islands
    .filter((island) => island.order > current.order)
    .sort((a, b) => a.order - b.order);
  return after[0]?.id ?? null;
}

/** A ilha completa pelos Domadores; sem nenhum que conta, nunca completa. */
export function tamersComplete(
  countingIds: readonly number[],
  wonIds: ReadonlySet<number>,
  required: number | null,
): boolean {
  if (countingIds.length === 0) return false;
  const won = countingIds.filter((id) => wonIds.has(id)).length;
  return won >= Math.min(required ?? countingIds.length, countingIds.length);
}

export interface IslandArena {
  id: number;
  position: number;
}

/** A Arena abre quando as da ilha de posição menor foram ganhas (auralis/05). */
export function arenaOpen(
  arenas: readonly IslandArena[],
  wonIds: ReadonlySet<number>,
  arenaId: number,
): boolean {
  const arena = arenas.find(({ id }) => id === arenaId);
  if (!arena) return false;
  return arenas
    .filter(({ position }) => position < arena.position)
    .every(({ id }) => wonIds.has(id));
}

export interface IslandConditions {
  countingTamerIds: readonly number[];
  wonTamerIds: ReadonlySet<number>;
  requiredTamerWins: number | null;
  arenaIds: readonly number[];
  wonArenaIds: ReadonlySet<number>;
  /** As missões que contam (auralis/06); ausentes valem como nenhuma. */
  questIds?: readonly number[];
  claimedQuestIds?: ReadonlySet<number>;
  requiredQuests?: number | null;
}

/** A ilha completa: pelo menos uma condição, e todas cumpridas. */
export function islandComplete(conditions: IslandConditions): boolean {
  const { countingTamerIds, arenaIds } = conditions;
  const questIds = conditions.questIds ?? [];
  if (
    countingTamerIds.length === 0 &&
    arenaIds.length === 0 &&
    questIds.length === 0
  ) {
    return false;
  }
  const tamers =
    countingTamerIds.length === 0 ||
    tamersComplete(
      countingTamerIds,
      conditions.wonTamerIds,
      conditions.requiredTamerWins,
    );
  const quests =
    questIds.length === 0 ||
    tamersComplete(
      questIds,
      conditions.claimedQuestIds ?? new Set(),
      conditions.requiredQuests ?? null,
    );
  return (
    tamers && quests && arenaIds.every((id) => conditions.wonArenaIds.has(id))
  );
}
