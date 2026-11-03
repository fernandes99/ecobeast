import type { HexCoord } from '../domain/exploration/hex.js';
import type { MapSpawn } from '../domain/exploration/spawns.js';

const MAX_IDLE_MS = 2 * 60 * 60 * 1000;

/** O que o servidor lembra de uma exploração. Os hexágonos não ficam guardados. */
export interface StoredExploration {
  /** Por id. Um Ecobeast sai daqui quando a luta contra ele começa. */
  spawns: Map<number, MapSpawn>;
  /** A última posição confirmada, e quando. */
  position: HexCoord;
  positionAt: number;
}

interface Entry {
  exploration: StoredExploration;
  lastUsedAt: number;
}

/**
 * Uma exploração por jogador, na memória deste processo: reiniciar o servidor as
 * perde, e o jogador só precisa entrar de novo. Sai depois de 2 horas sem uso.
 */
export class ExplorationStore {
  private readonly entries = new Map<string, Entry>();

  constructor(private readonly now: () => number = Date.now) {}

  get(userId: string): StoredExploration | undefined {
    this.removeExpired();
    return this.entries.get(userId)?.exploration;
  }

  set(userId: string, exploration: StoredExploration): void {
    this.removeExpired();
    this.entries.set(userId, { exploration, lastUsedAt: this.now() });
  }

  private removeExpired(): void {
    const limit = this.now() - MAX_IDLE_MS;
    for (const [userId, entry] of this.entries) {
      if (entry.lastUsedAt <= limit) this.entries.delete(userId);
    }
  }
}
