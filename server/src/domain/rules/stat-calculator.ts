import { STAT_SLUGS, StatBlock, StatSlug, TemperamentEffect } from './types.js';

/**
 * Stats de uma criatura (fórmulas do GDD; .specs/auth-google/02-player-rules.md,
 * RF-02):
 * HP = floor((2·base + genes + floor(treino/4)) · nível / 100) + nível + 10
 * Outros = floor((floor((2·base + genes + floor(treino/4)) · nível / 100) + 5) · T),
 * com T = 1,1 no stat aumentado, 0,9 no diminuído e 1,0 nos demais.
 */
export function calculateStats(
  base: StatBlock,
  genes: StatBlock,
  training: StatBlock,
  level: number,
  temperament: TemperamentEffect,
): StatBlock {
  const stats = {} as StatBlock;
  for (const slug of STAT_SLUGS) {
    const points =
      2 * base[slug] + genes[slug] + Math.floor(training[slug] / 4);
    const scaled = Math.floor((points * level) / 100);
    stats[slug] =
      slug === 'hp'
        ? scaled + level + 10
        : applyTemperament(scaled + 5, slug, temperament);
  }
  return stats;
}

/** Conta inteira, para não depender do arredondamento de 1,1 e 0,9. */
function applyTemperament(
  value: number,
  slug: StatSlug,
  { increasedStat, decreasedStat }: TemperamentEffect,
): number {
  if (increasedStat === decreasedStat) return value;
  if (slug === increasedStat) return Math.floor((value * 11) / 10);
  if (slug === decreasedStat) return Math.floor((value * 9) / 10);
  return value;
}
