import type { UsableItem } from '../items/use-item.js';
import type { StatBlock } from '../rules/types.js';

/** Número em [0, 1): em produção vem do `crypto.randomInt`; nos testes, é fixo. */
export type Random = () => number;

/** Stats que aceitam estágios em batalha. */
export type StageSlug =
  'atk' | 'def' | 'sp_atk' | 'sp_def' | 'spd' | 'accuracy' | 'evasion';

/** Os stats de uma criatura que os estágios mudam. */
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
  /** Calculados ao começar a luta. */
  stats: StatBlock;
  currentHp: number;
  /** burn, poison, paralysis, sleep ou freeze. */
  statusSlug: string | null;
  sleepTurns: number;
  /** 0 = não está confuso. */
  confusionTurns: number;
  isFeared: boolean;
  isTrapped: boolean;
  isProtected: boolean;
  stages: Record<StageSlug, number>;
  skills: CombatantSkill[];
  /** Só no inimigo: os índices da equipe do jogador que estiveram em campo contra ele. */
  foughtBy: number[];
  /** Só no jogador: o XP somado nesta luta, gravado no fim da vitória. */
  xpEarned: number;
}

export interface BattleSkillEffect {
  effectSlug: string;
  /** Porcentagem, de 0 a 100. */
  chance: number;
  targetSlug: string | null;
  statusSlug: string | null;
  statSlug: StageSlug | null;
  stages: number | null;
  percent: number | null;
}

export interface BattleSkill {
  id: number;
  /** Nulos só no golpe de emergência, que não tem Elemento. */
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
}

export interface BattleItem extends UsableItem {
  /** Nulo em quem não é Esfera. */
  captureBonus: number | null;
}

/** O que as regras precisam do catálogo. */
export interface BattleCatalog {
  skills: Map<number, BattleSkill>;
  /** "atacante:defensor" → multiplicador; par ausente vale 1. */
  efficacy: Map<string, number>;
  /** Slug do status → ids dos Elementos imunes. */
  statusImmunities: Map<string, number[]>;
  items: Map<number, BattleItem>;
  /** Id da espécie → `capture_rate`, de 0 a 100. */
  captureRates: Map<number, number>;
  /** Id da espécie → `base_xp_yield`. */
  xpYields: Map<number, number>;
}

export type BattlePhase = 'choose_action' | 'choose_next' | 'ended';
export type BattleResult = 'victory' | 'defeat' | 'fled' | 'captured';
export type SideSlug = 'player' | 'enemy';

export interface BattleSide {
  team: Combatant[];
  activeIndex: number;
}

/** Um item da Mochila na luta; `used` é o que o fim dela grava no banco. */
export interface BattleBagItem {
  itemId: number;
  quantity: number;
  used: number;
}

export interface BattleState {
  phase: BattlePhase;
  result: BattleResult | null;
  turn: number;
  /** Falso contra Domadores. */
  canFlee: boolean;
  player: BattleSide;
  enemy: BattleSide;
  bag: BattleBagItem[];
  /** Depuração: todo golpe do jogador que acerta derruba o inimigo. */
  godMode: boolean;
}

/** Ações e eventos já têm o formato da API: passam sem tradução. */
export type BattleAction =
  | { type: 'skill'; slot: number }
  | { type: 'emergency' }
  | { type: 'flee' }
  | { type: 'switch'; team_index: number }
  | { type: 'item'; item_id: number; team_index: number }
  | { type: 'capture'; item_id: number };

export type CannotActReason = 'fear' | 'freeze' | 'sleep' | 'paralysis';

/** `side` é sempre quem sofre o evento; em `missed`, quem errou. */
export type BattleEvent =
  | { type: 'battle_started' }
  | {
      type: 'creature_entered';
      side: SideSlug;
      species_id: number;
      level: number;
      max_hp: number;
      hp: number;
      status: string | null;
    }
  | { type: 'skill_used'; side: SideSlug; skill_id: number | null }
  | { type: 'cannot_act'; side: SideSlug; reason: CannotActReason }
  | { type: 'woke_up'; side: SideSlug }
  | { type: 'thawed'; side: SideSlug }
  | { type: 'confused_hit'; side: SideSlug; damage: number; hp: number }
  | { type: 'missed'; side: SideSlug }
  | { type: 'blocked'; side: SideSlug }
  | { type: 'no_effect'; side: SideSlug }
  | { type: 'effect_failed'; side: SideSlug }
  | {
      type: 'damage';
      side: SideSlug;
      damage: number;
      hp: number;
      multiplier: number;
      is_critical: boolean;
    }
  | { type: 'recoil'; side: SideSlug; damage: number; hp: number }
  | { type: 'healed'; side: SideSlug; amount: number; hp: number }
  | { type: 'status_applied'; side: SideSlug; status: string }
  | {
      type: 'status_damage';
      side: SideSlug;
      status: string;
      damage: number;
      hp: number;
    }
  | { type: 'status_ended'; side: SideSlug; status: string }
  | {
      type: 'stat_changed';
      side: SideSlug;
      stat: StageSlug;
      stages: number;
      value: number;
    }
  | { type: 'fainted'; side: SideSlug }
  | { type: 'xp_gained'; team_index: number; amount: number }
  | {
      type: 'item_used';
      side: 'player';
      item_id: number;
      team_index: number;
      healed: number;
      hp: number;
      cured_status: string | null;
    }
  | { type: 'capture_attempted'; item_id: number; success: boolean }
  | { type: 'flee_failed' }
  | { type: 'battle_ended'; result: BattleResult };

/** O que cada passo do turno recebe; `state` já é uma cópia. */
export interface TurnContext {
  state: BattleState;
  catalog: BattleCatalog;
  random: Random;
  events: BattleEvent[];
}
