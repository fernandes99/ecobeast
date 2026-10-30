/** Os 6 stats de uma criatura, com os slugs da tabela `stats`. */
export const STAT_SLUGS = [
  'hp',
  'atk',
  'def',
  'sp_atk',
  'sp_def',
  'spd',
] as const;

export type StatSlug = (typeof STAT_SLUGS)[number];

export type StatBlock = Record<StatSlug, number>;

/** O efeito de um Temperamento; aumentado igual ao diminuído (ou nulos) é neutro. */
export interface TemperamentEffect {
  increasedStat: StatSlug | null;
  decreasedStat: StatSlug | null;
}
