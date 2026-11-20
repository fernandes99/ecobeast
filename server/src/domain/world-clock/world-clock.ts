/** 0h do jogo: 2026-01-01T00:00:00Z (.specs/day-night/architecture.md). */
export const EPOCH_MS = Date.UTC(2026, 0, 1);

/** Um dia do jogo: 24 minutos reais, 1 segundo real por minuto do jogo. */
export const CYCLE_MS = 1_440_000;

/** O minuto do dia do jogo, de 0 (inclusive) a 1440. */
export function minuteOfDay(nowMs: number): number {
  const elapsed = (((nowMs - EPOCH_MS) % CYCLE_MS) + CYCLE_MS) % CYCLE_MS;
  return elapsed / 1000;
}

/**
 * A parte do dia de maior início até `minute`; sem nenhuma, a de maior início
 * (a noite atravessa a 0h).
 */
export function dayPhaseAt<T extends { startMinute: number }>(
  minute: number,
  phases: readonly T[],
): T {
  if (phases.length === 0) throw new Error('nenhuma parte do dia');
  const sorted = [...phases].sort((a, b) => a.startMinute - b.startMinute);
  return (
    sorted.findLast((phase) => phase.startMinute <= minute) ?? sorted.at(-1)!
  );
}

export type DayPart = 'day' | 'night';

/** A Manhã e a Tarde são o dia; o Final de tarde e a Noite, a noite (prayling-line/01). */
export function dayPartOf(phaseSlug: string): DayPart {
  return phaseSlug === 'morning' || phaseSlug === 'afternoon' ? 'day' : 'night';
}
