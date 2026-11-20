import type { DayPart } from '../world-clock/world-clock.js';

export interface EvolutionRule {
  id: number;
  speciesId: number;
  evolvedSpeciesId: number;
  trigger: string;
  minLevel: number | null;
  timeOfDay?: string | null;
}

export interface SpeciesTraitRow {
  traitId: number;
  slot: number;
  isHidden: boolean;
}

/**
 * A espécie em que ele pode evoluir, ou nulo. Valem o gatilho de nível e o de
 * horário (na parte do dia `dayPart`), e só para quem subiu de nível; com mais
 * de uma regra, vale a de menor id. Quem cancelou recebe a oferta de novo no
 * próximo nível, porque nada guarda a recusa.
 */
export function evolutionOffer(
  speciesId: number,
  levelBefore: number,
  levelAfter: number,
  rules: EvolutionRule[],
  dayPart: DayPart,
): number | null {
  if (levelAfter <= levelBefore) return null;
  const rule = rules
    .filter((row) => row.speciesId === speciesId && offers(row))
    .sort((a, b) => a.id - b.id)[0];
  return rule?.evolvedSpeciesId ?? null;

  function offers(row: EvolutionRule): boolean {
    if (row.trigger === 'level') {
      return row.minLevel !== null && row.minLevel <= levelAfter;
    }
    if (row.trigger === 'time_of_day') {
      return row.timeOfDay === dayPart && (row.minLevel ?? 1) <= levelAfter;
    }
    return false;
  }
}

/**
 * O Traço na espécie nova: o do mesmo slot e com o mesmo `is_hidden`; sem ele, o
 * de slot 1 não oculto, e depois o primeiro não oculto. Sem nenhum, mantém o atual.
 */
export function evolvedTraitId(
  traitId: number,
  oldTraits: SpeciesTraitRow[],
  newTraits: SpeciesTraitRow[],
): number {
  const old = oldTraits.find((row) => row.traitId === traitId);
  const visible = newTraits
    .filter((row) => !row.isHidden)
    .sort((a, b) => a.slot - b.slot);
  const match =
    (old &&
      newTraits.find(
        (row) => row.slot === old.slot && row.isHidden === old.isHidden,
      )) ??
    visible.find((row) => row.slot === 1) ??
    visible[0];
  return match?.traitId ?? traitId;
}
