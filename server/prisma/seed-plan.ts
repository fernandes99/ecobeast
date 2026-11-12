export type SeedPlan = 'skip' | { load: string[] };

export function seedPlan(counts: Record<string, number>): SeedPlan {
  const empty = Object.keys(counts).filter((name) => counts[name] === 0);
  return empty.length === 0 ? 'skip' : { load: empty };
}
