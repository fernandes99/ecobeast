import { STAT_SLUGS, StatBlock } from './types.js';

export interface GeneRank {
  slug: string;
  name: string;
}

const GENE_RANKS: (GeneRank & { minTotal: number })[] = [
  { minTotal: 160, slug: 'exceptional', name: 'Excepcional' },
  { minTotal: 145, slug: 'epic', name: 'Épico' },
  { minTotal: 130, slug: 'rare', name: 'Raro' },
  { minTotal: 110, slug: 'uncommon', name: 'Incomum' },
  { minTotal: 0, slug: 'common', name: 'Comum' },
];

export function genesTotal(genes: StatBlock): number {
  return STAT_SLUGS.reduce((sum, slug) => sum + genes[slug], 0);
}

export function geneRank(total: number): GeneRank {
  const { slug, name } = GENE_RANKS.find((rank) => total >= rank.minTotal)!;
  return { slug, name };
}
