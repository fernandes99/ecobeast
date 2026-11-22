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
