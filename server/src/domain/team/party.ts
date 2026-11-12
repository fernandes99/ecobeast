export const PARTY_SIZE = 6;

export function firstFreePartySlot(occupied: number[]): number | null {
  for (let slot = 1; slot <= PARTY_SIZE; slot += 1) {
    if (!occupied.includes(slot)) return slot;
  }
  return null;
}

export function isSameTeam(current: string[], requested: string[]): boolean {
  return (
    requested.length === current.length &&
    new Set(requested).size === current.length &&
    requested.every((uid) => current.includes(uid))
  );
}
