export type SeedPlan = 'skip' | { load: string[] };

/**
 * Decide o que o seed faz a partir da contagem de linhas de cada tabela do
 * catálogo (.specs/backend-api/03-catalog-seed.md, RF-04): carrega só as tabelas
 * vazias, e com tudo preenchido não faz nada. Assim, uma tabela nova entra num
 * banco já em uso sem tocar nas linhas que o dono editou.
 */
export function seedPlan(counts: Record<string, number>): SeedPlan {
  const empty = Object.keys(counts).filter((name) => counts[name] === 0);
  return empty.length === 0 ? 'skip' : { load: empty };
}
