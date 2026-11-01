export const PARTY_SIZE = 6;

/** A primeira vaga da equipe, de 1 a 6; nulo com a equipe cheia. */
export function firstFreePartySlot(occupied: number[]): number | null {
  for (let slot = 1; slot <= PARTY_SIZE; slot += 1) {
    if (!occupied.includes(slot)) return slot;
  }
  return null;
}

/** `requested` é `current` em qualquer ordem, sem faltar nem repetir ninguém. */
export function isSameTeam(current: string[], requested: string[]): boolean {
  return (
    requested.length === current.length &&
    new Set(requested).size === current.length &&
    requested.every((uid) => current.includes(uid))
  );
}
