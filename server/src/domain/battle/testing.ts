import type {
  BattleCatalog,
  BattleSkill,
  Combatant,
  Random,
  StageSlug,
} from './types.js';

/** Ajudantes dos testes da batalha; o código do jogo não usa este arquivo. */

const NO_STAGES: Record<StageSlug, number> = {
  atk: 0,
  def: 0,
  sp_atk: 0,
  sp_def: 0,
  spd: 0,
  accuracy: 0,
  evasion: 0,
};

/** Um Fagulho nível 5, sem Genes nem Temperamento, com HP cheio. */
export function makeCombatant(overrides: Partial<Combatant> = {}): Combatant {
  return {
    creatureUid: 'c1',
    speciesId: 1,
    elementIds: [FIRE],
    level: 5,
    traitSlug: 'none',
    stats: { hp: 19, atk: 10, def: 9, sp_atk: 11, sp_def: 9, spd: 11 },
    currentHp: 19,
    statusSlug: null,
    sleepTurns: 0,
    confusionTurns: 0,
    isFeared: false,
    isTrapped: false,
    isProtected: false,
    stages: { ...NO_STAGES },
    skills: [],
    ...overrides,
  };
}

export const FIRE = 1;
export const WATER = 2;
export const FLORA = 3;
export const BEAST = 13;

/** Arranhão: físico, Poder 40, Fera. */
export function makeSkill(overrides: Partial<BattleSkill> = {}): BattleSkill {
  return {
    id: 1,
    elementId: BEAST,
    elementSlug: 'beast',
    category: 'physical',
    power: 40,
    accuracy: 100,
    maxPp: 35,
    priority: 0,
    critStage: 0,
    targetSlug: 'enemy',
    effects: [],
    ...overrides,
  };
}

/** `multipliers`: "atacante:defensor" → multiplicador. */
export function makeCatalog(
  multipliers: Record<string, number> = {},
  skills: BattleSkill[] = [],
): BattleCatalog {
  return {
    skills: new Map(skills.map((skill) => [skill.id, skill])),
    efficacy: new Map(Object.entries(multipliers)),
    statusImmunities: new Map(),
  };
}

/** Devolve os valores na ordem dada e falha se faltar sorteio. */
export function sequence(...values: number[]): Random {
  const queue = [...values];
  return () => {
    const value = queue.shift();
    if (value === undefined) throw new Error('Faltou um valor de sorteio.');
    return value;
  };
}
