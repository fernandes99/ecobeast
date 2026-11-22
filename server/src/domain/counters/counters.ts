/** Os ids estáveis do catálogo `counters` (player-stats/01). */
export const COUNTER_IDS = {
  wins_wild: 1,
  wins_tamer: 2,
  defeats: 3,
  captures: 4,
  spheres_used: 5,
  captures_first_sphere: 6,
  captures_by_element: 7,
  captures_by_day_phase: 8,
  hexes_walked: 9,
  biome_hexes: 10,
  maps_explored: 11,
  xp_gained: 12,
  coins_earned: 13,
  coins_spent: 14,
  heals: 15,
  play_seconds: 16,
  play_days: 17,
  play_streak: 18,
} as const;

export type CounterSlug = keyof typeof COUNTER_IDS;

export interface CounterIncrement {
  counterId: number;
  /** 0 quando o contador não tem recorte. */
  subjectId: number;
  amount: number;
}

export function counterTotal(
  slug: CounterSlug,
  amount: number,
): CounterIncrement {
  return { counterId: COUNTER_IDS[slug], subjectId: 0, amount };
}

/** Soma os iguais e tira os de valor 0. */
export function mergeIncrements(list: CounterIncrement[]): CounterIncrement[] {
  const merged = new Map<string, CounterIncrement>();
  for (const item of list) {
    const key = `${item.counterId}:${item.subjectId}`;
    const found = merged.get(key);
    if (found) found.amount += item.amount;
    else merged.set(key, { ...item });
  }
  return [...merged.values()].filter(({ amount }) => amount > 0);
}
