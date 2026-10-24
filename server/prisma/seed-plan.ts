export type SeedPlan = 'load' | 'skip' | { incomplete: string[] };

/**
 * Decide o que o seed faz a partir da contagem de linhas de cada tabela do
 * catálogo (.specs/backend-api/03-catalog-seed.md, RF-04): tudo vazio carrega,
 * tudo cheio não faz nada, e o meio-termo é um erro que lista as tabelas com linhas.
 */
export function seedPlan(counts: Record<string, number>): SeedPlan {
  const filled = Object.keys(counts).filter((name) => counts[name] > 0);
  if (filled.length === 0) return 'load';
  if (filled.length === Object.keys(counts).length) return 'skip';
  return { incomplete: filled };
}
