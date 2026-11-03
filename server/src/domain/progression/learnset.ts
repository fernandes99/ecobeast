import type { LearnsetEntry } from '../rules/creature-factory.js';

const MAX_SKILLS = 4;

function byLevelThenId(a: LearnsetEntry, b: LearnsetEntry): number {
  return (a.level ?? 0) - (b.level ?? 0) || a.skillId - b.skillId;
}

/** As Técnicas por nível em `levelBefore < nível ≤ levelAfter`, por nível e id. */
export function skillsBetween(
  learnset: LearnsetEntry[],
  levelBefore: number,
  levelAfter: number,
): number[] {
  return learnset
    .filter(
      ({ method, level }) =>
        method === 'level_up' &&
        level !== null &&
        level > levelBefore &&
        level <= levelAfter,
    )
    .sort(byLevelThenId)
    .map(({ skillId }) => skillId);
}

/** As Técnicas que a espécie aprende ao evoluir para ela, por id. */
export function evolutionSkills(learnset: LearnsetEntry[]): number[] {
  return learnset
    .filter(({ method }) => method === 'evolution')
    .sort(byLevelThenId)
    .map(({ skillId }) => skillId);
}

/**
 * Sem as que ele já conhece e sem repetição, as primeiras entram nas vagas
 * livres; as que sobram esperam a escolha do jogador.
 */
export function learnNewSkills(
  known: number[],
  candidates: number[],
): { learned: number[]; pending: number[] } {
  const fresh = [...new Set(candidates)].filter((id) => !known.includes(id));
  const free = Math.max(0, MAX_SKILLS - known.length);
  return { learned: fresh.slice(0, free), pending: fresh.slice(free) };
}
