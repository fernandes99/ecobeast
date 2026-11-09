import type { HexCoord } from '../exploration/hex.js';
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
  /** Só no inimigo: capturado nesta luta; ele sai dela, como um desmaiado. */
  captured: boolean;
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
  /** No tabuleiro (board-battle/01): um hexágono a até `range`, ou linha reta. */
  areaShape: AreaShape;
  range: number;
  /** Só na linha: atravessa os inimigos em vez de parar no primeiro. */
  pierces: boolean;
  /** A marca que fica no chão; nulos juntos sem marca. */
  groundEffectId: number | null;
  groundTurns: number | null;
}

export type AreaShape = 'single' | 'line';

/** O que uma marca no chão faz a quem está nela, depois de cada vez da fila. */
export interface BattleGroundEffect {
  /** % do HP máximo; nulo sem dano. */
  damagePercent: number | null;
  statusSlug: string | null;
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

/** Um lugar em campo (.specs/battle-slots/architecture.md, "Vagas"). */
export interface Spot {
  side: SideSlug;
  position: number;
}

/** Um item da Mochila na luta; `used` é o que o fim dela grava no banco. */
export interface BattleBagItem {
  itemId: number;
  quantity: number;
  used: number;
}

/** Contra quem é a luta: um selvagem ou um Domador NPC (npc-tamers/02). */
export type Opponent = 'wild' | 'tamer';

export interface BattleState {
  phase: BattlePhase;
  result: BattleResult | null;
  turn: number;
  /** Falso contra Domadores. */
  canFlee: boolean;
  /** Contra Domador: sem Esfera, sem fuga, XP e moedas maiores. */
  opponent: Opponent;
  player: BattleSide;
  enemy: BattleSide;
  /** No `choose_next`: as vagas do jogador que esperam quem entra. */
  pendingPositions: number[];
  bag: BattleBagItem[];
  /** Depuração: todo golpe do jogador que acerta derruba o inimigo. */
  godMode: boolean;
  /** As moedas do Domador no começo: a derrota não tira mais do que isso. */
  coins: number;
  /** O que o fim da luta soma às moedas; negativo na derrota. */
  coinsChange: number;
  /** Vagas livres na equipe: cada captura ocupa uma, e depois vai para o Santuário. */
  partyFree: number;
}

/**
 * Ações e eventos já têm o formato da API: passam sem tradução. `position` é a
 * vaga de quem age, 0 por padrão. `target` é a posição do adversário e só é
 * obrigatório com mais de um de pé.
 */
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
      /** Só no tabuleiro: onde ele entrou. */
      cell?: HexCoord;
    }
  | {
      type: 'skill_used';
      side: SideSlug;
      position: number;
      skill_id: number | null;
      /** Só no tabuleiro: os hexágonos da área. */
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
  // Só na luta no tabuleiro (.specs/board-battle/architecture.md, "Eventos").
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

/** O que cada passo do turno recebe; `state` já é uma cópia. */
export interface TurnContext {
  state: BattleState;
  catalog: BattleCatalog;
  random: Random;
  events: BattleEvent[];
}
