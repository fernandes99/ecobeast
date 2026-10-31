import { MAX_LEVEL } from '../rules/xp-curve.js';
import type { Random } from './types.js';

const MIN_LEVEL = 1;
/** Provisórios, a revisar: a `wild-battle` troca o sorteio pelas zonas. */
const LEVELS_BELOW = 2;
const LEVELS_ABOVE = 1;

export interface Encounter {
  speciesId: number;
  level: number;
}

/** O inimigo selvagem: a espécie é sorteada primeiro, e o nível depois. */
export function rollEncounter(
  speciesIds: number[],
  referenceLevel: number,
  random: Random,
): Encounter {
  const speciesId = speciesIds[Math.floor(random() * speciesIds.length)]!;
  const levelSpread = LEVELS_BELOW + LEVELS_ABOVE + 1;
  const offset = Math.floor(random() * levelSpread) - LEVELS_BELOW;
  const level = referenceLevel + offset;
  return { speciesId, level: Math.min(MAX_LEVEL, Math.max(MIN_LEVEL, level)) };
}
