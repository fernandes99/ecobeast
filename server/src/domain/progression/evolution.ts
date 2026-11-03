/** Uma linha de `evolutions`, com o slug do gatilho. */
export interface EvolutionRule {
  id: number;
  speciesId: number;
  evolvedSpeciesId: number;
  trigger: string;
  minLevel: number | null;
}

export interface SpeciesTraitRow {
  traitId: number;
  slot: number;
  isHidden: boolean;
}

/**
 * A espécie em que ele pode evoluir, ou nulo. Só o gatilho de nível vale, e só
 * para quem subiu de nível; com mais de uma regra, vale a de menor id. Quem
 * cancelou recebe a oferta de novo no próximo nível, porque nada guarda a recusa.
 */
export function evolutionOffer(
  speciesId: number,
  levelBefore: number,
  levelAfter: number,
  rules: EvolutionRule[],
): number | null {
  if (levelAfter <= levelBefore) return null;
  const rule = rules
    .filter(
      (row) =>
        row.speciesId === speciesId &&
        row.trigger === 'level' &&
        row.minLevel !== null &&
        row.minLevel <= levelAfter,
    )
    .sort((a, b) => a.id - b.id)[0];
  return rule?.evolvedSpeciesId ?? null;
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
