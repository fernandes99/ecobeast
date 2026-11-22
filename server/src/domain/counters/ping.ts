/** O sinal de cada minuto (player-stats/02). */
export const PING_MAX_GAP_MS = 90_000;
export const PLAY_TIME_ZONE = 'America/Sao_Paulo';
const DAY_MS = 24 * 60 * 60 * 1000;

const dayFormat = new Intl.DateTimeFormat('en-CA', {
  timeZone: PLAY_TIME_ZONE,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
});

export interface BiomeHexes {
  biomeId: number;
  count: number;
}

/** Acima de `PING_MAX_GAP_MS`, o app ficou parado ou fechado: não conta. */
export function playSecondsFor(lastPingAt: Date | null, now: Date): number {
  if (!lastPingAt) return 0;
  const elapsed = now.getTime() - lastPingAt.getTime();
  if (elapsed < 0 || elapsed > PING_MAX_GAP_MS) return 0;
  return Math.round(elapsed / 1000);
}

/** O dia `AAAA-MM-DD` na hora de Brasília. */
export function playDayOf(now: Date): string {
  return dayFormat.format(now);
}

export function nextStreak(
  lastPlayDay: string | null,
  today: string,
  streak: number,
): { newDay: boolean; streak: number } {
  if (lastPlayDay === today) return { newDay: false, streak };
  const gap = Date.parse(today) - (lastPlayDay ? Date.parse(lastPlayDay) : 0);
  return { newDay: true, streak: gap === DAY_MS ? streak + 1 : 1 };
}

/** Acima do teto, cada bioma é cortado na mesma proporção. */
export function cappedHexes(hexes: BiomeHexes[], limit: number): BiomeHexes[] {
  const total = hexes.reduce((sum, { count }) => sum + count, 0);
  const scaled =
    total <= limit
      ? hexes
      : hexes.map(({ biomeId, count }) => ({
          biomeId,
          count: Math.floor((count * limit) / total),
        }));
  return scaled.filter(({ count }) => count > 0);
}
