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

export interface TemperamentEffect {
  increasedStat: StatSlug | null;
  decreasedStat: StatSlug | null;
}
