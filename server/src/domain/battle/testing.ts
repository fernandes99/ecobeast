import { resolveSkill } from './actions.js';
import { noStages } from './stages.js';
import type { UsableItem } from '../items/use-item.js';
import type {
  BattleCatalog,
  BattleEvent,
  BattleSkill,
  BattleSkillEffect,
  BattleState,
  Combatant,
  Random,
  Spot,
  TurnContext,
} from './types.js';

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
    foughtBy: [],
    xpEarned: 0,
    captured: false,
    ...overrides,
  };
}

export const FIRE = 1;
export const WATER = 2;
export const FLORA = 3;
export const INSTINCT = 13;

export function makeSkill(overrides: Partial<BattleSkill> = {}): BattleSkill {
  return {
    id: 1,
    elementId: INSTINCT,
    elementSlug: 'instinct',
    category: 'physical',
    power: 40,
    accuracy: 100,
    maxPp: 35,
    priority: 0,
    critStage: 0,
    targetSlug: 'enemy',
    effects: [],
    areaShape: 'single',
    range: 1,
    pierces: false,
    groundEffectId: null,
    groundTurns: null,
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

export function makeCatalog(
  multipliers: Record<string, number> = {},
  skills: BattleSkill[] = [],
  items: Record<number, TestItem> = {},
  captureRates: Record<number, number> = {},
  xpYields: Record<number, number> = {},
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
    xpYields: new Map(
      Object.entries(xpYields).map(([id, xp]) => [Number(id), xp]),
    ),
    groundEffects: new Map(),
  };
}

export function sequence(...values: number[]): Random {
  const queue = [...values];
  return () => {
    const value = queue.shift();
    if (value === undefined) throw new Error('Faltou um valor de sorteio.');
    return value;
  };
}

export function always(value: number): Random {
  return () => value;
}

export const PLAYER: Spot = { side: 'player', position: 0 };
export const ENEMY: Spot = { side: 'enemy', position: 0 };

export function contextOf(
  state: BattleState,
  catalog: BattleCatalog,
  random: Random = always(0.5),
): TurnContext {
  return { state: structuredClone(state), catalog, random, events: [] };
}

export function cast(
  state: BattleState,
  skill: BattleSkill,
  catalog: BattleCatalog,
  random: Random = always(0.5),
  from: Spot = PLAYER,
  to: Spot = ENEMY,
): TurnContext {
  const context = contextOf(state, catalog, random);
  resolveSkill(context, from, skill, to);
  return context;
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

export function makeState(
  player: Combatant | Combatant[],
  enemy: Combatant | Combatant[],
  overrides: Partial<BattleState> = {},
  slots: { player: number; enemy: number } = { player: 1, enemy: 1 },
): BattleState {
  const side = (team: Combatant[], count: number) => ({
    team,
    activeIndices: Array.from({ length: count }, (_, position) =>
      position < team.length ? position : null,
    ),
  });
  const state: BattleState = {
    phase: 'choose_action',
    result: null,
    turn: 1,
    canFlee: true,
    opponent: 'wild',
    player: side([player].flat(), slots.player),
    enemy: side([enemy].flat(), slots.enemy),
    pendingPositions: [],
    bag: [],
    godMode: false,
    coins: 0,
    coinsChange: 0,
    partyFree: 0,
    ...overrides,
  };
  if (state.phase === 'choose_next' && !overrides.pendingPositions) {
    // Como no fim do turno: as vagas de quem desmaiou esperam quem entra.
    state.pendingPositions = state.player.activeIndices.flatMap(
      (index, position) =>
        index !== null && state.player.team[index]!.currentHp === 0
          ? [position]
          : [],
    );
  }
  const facing = state.player.activeIndices.filter(
    (index): index is number => index !== null,
  );
  for (const index of state.enemy.activeIndices) {
    const creature = index === null ? undefined : state.enemy.team[index];
    if (creature && creature.foughtBy.length === 0) {
      // Uma cópia: a criatura recebida pode estar em outros testes.
      state.enemy.team[index!] = { ...creature, foughtBy: [...facing] };
    }
  }
  return state;
}
