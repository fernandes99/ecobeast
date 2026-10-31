import type { BattleCatalog, BattleState } from '../domain/battle/types.js';

const MAX_IDLE_MS = 30 * 60 * 1000;

/** O catálogo fica junto: uma edição no painel não muda uma luta em andamento. */
export interface StoredBattle {
  state: BattleState;
  catalog: BattleCatalog;
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
