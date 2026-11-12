import type { HexCoord } from '../exploration/hex.js';
import type { UsableItem } from '../items/use-item.js';
import type { StatBlock } from '../rules/types.js';

export type Random = () => number;

export type StageSlug =
  'atk' | 'def' | 'sp_atk' | 'sp_def' | 'spd' | 'accuracy' | 'evasion';

export type BattleStatSlug = Exclude<StageSlug, 'accuracy' | 'evasion'>;

export interface CombatantSkill {
  skillId: number;
  currentPp: number;
}

export interface Combatant {
  /** Nulo no inimigo selvagem, que não existe no banco. */
  creatureUid: string | null;
  speciesId: number;
  elementIds: number[];
  level: number;
  traitSlug: string;
  stats: StatBlock;
  currentHp: number;
  statusSlug: string | null;
  sleepTurns: number;
  confusionTurns: number;
  isFeared: boolean;
  isTrapped: boolean;
  isProtected: boolean;
  stages: Record<StageSlug, number>;
  skills: CombatantSkill[];
  foughtBy: number[];
  xpEarned: number;
  captured: boolean;
}

export interface BattleSkillEffect {
  effectSlug: string;
  chance: number;
  targetSlug: string | null;
  statusSlug: string | null;
  statSlug: StageSlug | null;
  stages: number | null;
  percent: number | null;
}

export interface BattleSkill {
  id: number;
  elementId: number | null;
  elementSlug: string | null;
  category: 'physical' | 'special' | 'support';
  power: number;
  /** 0 = nunca erra. */
  accuracy: number;
  maxPp: number;
  priority: number;
  critStage: number;
  targetSlug: string;
  effects: BattleSkillEffect[];
  areaShape: AreaShape;
  range: number;
  pierces: boolean;
  groundEffectId: number | null;
  groundTurns: number | null;
}

export type AreaShape = 'single' | 'line';

export interface BattleGroundEffect {
  damagePercent: number | null;
  statusSlug: string | null;
}

export interface BattleItem extends UsableItem {
  captureBonus: number | null;
}

export interface BattleCatalog {
  skills: Map<number, BattleSkill>;
  efficacy: Map<string, number>;
  statusImmunities: Map<string, number[]>;
  items: Map<number, BattleItem>;
  captureRates: Map<number, number>;
  xpYields: Map<number, number>;
  groundEffects: Map<number, BattleGroundEffect>;
}

export type BattlePhase = 'choose_action' | 'choose_next' | 'ended';
export type BattleResult = 'victory' | 'defeat' | 'fled' | 'captured';
export type SideSlug = 'player' | 'enemy';
export type CapturedTo = 'party' | 'storage';

export interface BattleSide {
  team: Combatant[];
  /**
   * Por posição em campo, da esquerda para a direita: o índice na equipe de
   * quem está ali, ou nulo com a vaga vazia. O tamanho é o número de vagas.
   */
  activeIndices: (number | null)[];
}

export interface Spot {
  side: SideSlug;
  position: number;
}

export interface BattleBagItem {
  itemId: number;
  quantity: number;
  used: number;
}

export type Opponent = 'wild' | 'tamer';

export interface BattleState {
  phase: BattlePhase;
  result: BattleResult | null;
  turn: number;
  canFlee: boolean;
  opponent: Opponent;
  player: BattleSide;
  enemy: BattleSide;
  pendingPositions: number[];
  bag: BattleBagItem[];
  godMode: boolean;
  coins: number;
  coinsChange: number;
  partyFree: number;
}

export type BattleAction = { position?: number } & (
  | { type: 'skill'; slot: number; target?: number }
  | { type: 'emergency'; target?: number }
  | { type: 'flee' }
  | { type: 'switch'; team_index: number }
  | { type: 'item'; item_id: number; team_index: number }
  | { type: 'capture'; item_id: number; target?: number }
);

export type CannotActReason = 'fear' | 'freeze' | 'sleep' | 'paralysis';

/**
 * `side` e `position` são sempre de quem sofre o evento; em `missed`, de quem
 * errou.
 */
export type BattleEvent =
  | { type: 'battle_started' }
  | {
      type: 'creature_entered';
      side: SideSlug;
      position: number;
      team_index: number;
      species_id: number;
      level: number;
      max_hp: number;
      hp: number;
      status: string | null;
      cell?: HexCoord;
    }
  | {
      type: 'skill_used';
      side: SideSlug;
      position: number;
      skill_id: number | null;
      cells?: HexCoord[];
    }
  | {
      type: 'cannot_act';
      side: SideSlug;
      position: number;
      reason: CannotActReason;
    }
  | { type: 'woke_up'; side: SideSlug; position: number }
  | { type: 'thawed'; side: SideSlug; position: number }
  | {
      type: 'confused_hit';
      side: SideSlug;
      position: number;
      damage: number;
      hp: number;
    }
  | { type: 'missed'; side: SideSlug; position: number }
  | { type: 'blocked'; side: SideSlug; position: number }
  | { type: 'no_effect'; side: SideSlug; position: number }
  | { type: 'effect_failed'; side: SideSlug; position: number }
  | {
      type: 'damage';
      side: SideSlug;
      position: number;
      damage: number;
      hp: number;
      multiplier: number;
      is_critical: boolean;
    }
  | {
      type: 'recoil';
      side: SideSlug;
      position: number;
      damage: number;
      hp: number;
    }
  | {
      type: 'healed';
      side: SideSlug;
      position: number;
      amount: number;
      hp: number;
    }
  | { type: 'status_applied'; side: SideSlug; position: number; status: string }
  | {
      type: 'status_damage';
      side: SideSlug;
      position: number;
      status: string;
      damage: number;
      hp: number;
    }
  | { type: 'status_ended'; side: SideSlug; position: number; status: string }
  | {
      type: 'stat_changed';
      side: SideSlug;
      position: number;
      stat: StageSlug;
      stages: number;
      value: number;
    }
  | { type: 'fainted'; side: SideSlug; position: number }
  | { type: 'xp_gained'; team_index: number; amount: number }
  | { type: 'coins_gained'; amount: number; species_id: number }
  | { type: 'coins_lost'; amount: number; species_ids: number[] }
  | {
      type: 'item_used';
      side: 'player';
      position: number;
      item_id: number;
      team_index: number;
      healed: number;
      hp: number;
      cured_status: string | null;
    }
  | {
      type: 'capture_attempted';
      item_id: number;
      success: boolean;
      target: number;
      captured_to: CapturedTo | null;
    }
  | { type: 'creature_left'; side: SideSlug; position: number }
  | { type: 'flee_failed' }
  | { type: 'battle_ended'; result: BattleResult }
  | { type: 'round_started'; round: number; queue: Spot[] }
  | { type: 'vez_started'; side: SideSlug; position: number }
  | { type: 'moved'; side: SideSlug; position: number; path: HexCoord[] }
  | { type: 'waited'; side: SideSlug; position: number }
  | {
      type: 'mark_placed';
      cell: HexCoord;
      ground_effect_id: number;
      remaining: number;
    }
  | { type: 'mark_ended'; cell: HexCoord }
  | {
      type: 'ground_damage';
      side: SideSlug;
      position: number;
      amount: number;
      hp: number;
      ground_effect_id: number;
    };

export interface TurnContext {
  state: BattleState;
  catalog: BattleCatalog;
  random: Random;
  events: BattleEvent[];
}
