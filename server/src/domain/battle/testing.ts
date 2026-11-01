import { applyAction, type BattleOutcome } from './engine.js';
import { noStages } from './stages.js';
import type { UsableItem } from '../items/use-item.js';
import type {
  BattleAction,
  BattleCatalog,
  BattleEvent,
  BattleSkill,
  BattleSkillEffect,
  BattleState,
  Combatant,
  Random,
} from './types.js';

/** Ajudantes dos testes da batalha; o código do jogo não usa este arquivo. */

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
    stages: noStages(),
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

export function makeEffect(
  overrides: Partial<BattleSkillEffect> = {},
): BattleSkillEffect {
  return {
    effectSlug: 'heal',
    chance: 100,
    targetSlug: null,
    statusSlug: null,
    statSlug: null,
    stages: null,
    percent: null,
    ...overrides,
  };
}

type TestItem = UsableItem & { captureBonus?: number };

/** `multipliers`: "atacante:defensor" → multiplicador. */
export function makeCatalog(
  multipliers: Record<string, number> = {},
  skills: BattleSkill[] = [],
  items: Record<number, TestItem> = {},
  captureRates: Record<number, number> = {},
): BattleCatalog {
  return {
    skills: new Map(skills.map((skill) => [skill.id, skill])),
    efficacy: new Map(Object.entries(multipliers)),
    statusImmunities: new Map(),
    items: new Map(
      Object.entries(items).map(([id, item]) => [
        Number(id),
        { captureBonus: null, ...item },
      ]),
    ),
    captureRates: new Map(
      Object.entries(captureRates).map(([id, rate]) => [Number(id), rate]),
    ),
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

/** Sempre o mesmo valor: com 0 toda chance vale, e com 0,9 quase nenhuma. */
export function always(value: number): Random {
  return () => value;
}

/** `applyAction` que falha o teste se a ação for recusada. */
export function play(
  state: BattleState,
  action: BattleAction,
  catalog: BattleCatalog,
  random: Random = always(0.5),
): BattleOutcome {
  const outcome = applyAction(state, action, catalog, random);
  if ('error' in outcome) throw new Error(outcome.error);
  return outcome;
}

export function eventsOf<Type extends BattleEvent['type']>(
  events: BattleEvent[],
  type: Type,
): Extract<BattleEvent, { type: Type }>[] {
  return events.filter(
    (event): event is Extract<BattleEvent, { type: Type }> =>
      event.type === type,
  );
}

/** Uma batalha em andamento, com a primeira criatura de cada lado em campo. */
export function makeState(
  player: Combatant | Combatant[],
  enemy: Combatant | Combatant[],
  overrides: Partial<BattleState> = {},
): BattleState {
  return {
    phase: 'choose_action',
    result: null,
    turn: 1,
    canFlee: true,
    player: { team: [player].flat(), activeIndex: 0 },
    enemy: { team: [enemy].flat(), activeIndex: 0 },
    bag: [],
    ...overrides,
  };
}
