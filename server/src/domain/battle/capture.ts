export const NOT_CAPTURABLE = 'Esse Ecobeast não pode ser capturado.';
export const TAMER_CREATURE =
  'Não dá para capturar o Ecobeast de outro Domador.';

/** Provisórios, a revisar (.specs/capture/architecture.md, "Fórmula"). */
const STATUS_BONUS: Record<string, number> = {
  sleep: 2.5,
  freeze: 2.5,
  paralysis: 1.5,
  burn: 1.5,
  poison: 1.5,
};

export interface CaptureInput {
  currentHp: number;
  maxHp: number;
  /** De 0 a 100. */
  captureRate: number;
  captureBonus: number;
  statusSlug: string | null;
}

/** A chance de capturar, de 0 a 1. */
export function captureChance({
  currentHp,
  maxHp,
  captureRate,
  captureBonus,
  statusSlug,
}: CaptureInput): number {
  const statusBonus = statusSlug ? (STATUS_BONUS[statusSlug] ?? 1) : 1;
  const hpShare = (3 * maxHp - 2 * currentHp) / (3 * maxHp);
  return Math.min(
    (hpShare * captureRate * captureBonus * statusBonus) / 100,
    1,
  );
}
