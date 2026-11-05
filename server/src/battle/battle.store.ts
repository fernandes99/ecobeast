import type { BattleCatalog, BattleState } from '../domain/battle/types.js';
import type { NewCreature } from '../domain/rules/creature-factory.js';
import type { StatSlug } from '../domain/rules/types.js';

const MAX_IDLE_MS = 30 * 60 * 1000;

/** O que o combate não usa, mas a captura grava. Nunca vai para o cliente. */
export interface WildCreature {
  creature: NewCreature;
  statIds: Record<StatSlug, number>;
}

/** O catálogo fica junto: uma edição no painel não muda uma luta em andamento. */
export interface StoredBattle {
  /** A luta de hoje (`classic`) ou a do tabuleiro (`board`); cada rota só vê a sua. */
  kind: 'classic' | 'board';
  state: BattleState;
  catalog: BattleCatalog;
  /** Um por Ecobeast da equipe inimiga, na mesma ordem. */
  wilds: WildCreature[];
}

interface Entry {
  battle: StoredBattle;
  lastActionAt: number;
}

/**
 * Uma batalha por jogador, na memória deste processo: reiniciar o servidor as
 * perde. Quem passa 30 minutos sem agir abandona a sua, sem gravar nada.
 */
export class BattleStore {
  private readonly entries = new Map<string, Entry>();

  constructor(private readonly now: () => number = Date.now) {}

  get(userId: string): StoredBattle | undefined {
    this.removeExpired();
    return this.entries.get(userId)?.battle;
  }

  set(userId: string, battle: StoredBattle): void {
    this.removeExpired();
    this.entries.set(userId, { battle, lastActionAt: this.now() });
  }

  delete(userId: string): void {
    this.removeExpired();
    this.entries.delete(userId);
  }

  private removeExpired(): void {
    const limit = this.now() - MAX_IDLE_MS;
    for (const [userId, entry] of this.entries) {
      if (entry.lastActionAt <= limit) this.entries.delete(userId);
    }
  }
}
