import type { BattleCatalog, BattleState } from '../domain/battle/types.js';
import type { NewCreature } from '../domain/rules/creature-factory.js';
import type { StatSlug } from '../domain/rules/types.js';

const MAX_IDLE_MS = 30 * 60 * 1000;

export interface WildCreature {
  creature: NewCreature;
  statIds: Record<StatSlug, number>;
}

export interface BattleTamer {
  nameId: number;
  source: 'map' | 'challenge';
}

/** O catálogo fica junto: uma edição no painel não muda uma luta em andamento. */
export interface StoredBattle {
  state: BattleState;
  catalog: BattleCatalog;
  wilds: WildCreature[];
  tamer?: BattleTamer | null;
}

interface Entry {
  battle: StoredBattle;
  lastActionAt: number;
}

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
