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

/** O que as regras precisam do catálogo. */
export interface BattleCatalog {
  skills: Map<number, BattleSkill>;
  /** "atacante:defensor" → multiplicador; par ausente vale 1. */
  efficacy: Map<string, number>;
  /** Slug do status → ids dos Elementos imunes. */
  statusImmunities: Map<string, number[]>;
}
