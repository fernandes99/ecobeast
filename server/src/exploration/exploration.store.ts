import { cappedHexes, type BiomeHexes } from '../domain/counters/ping.js';
import {
  type HexCoord,
  hexDistance,
  MIN_STEP_MS,
} from '../domain/exploration/hex.js';
import type { MapSpawn } from '../domain/exploration/spawns.js';
import type { MapTamer } from '../domain/tamers/tamers.js';

const MAX_IDLE_MS = 2 * 60 * 60 * 1000;

export interface StoredExploration {
  spawns: Map<number, MapSpawn>;
  tamers: Map<number, MapTamer>;
  position: HexCoord;
  positionAt: number;
  /** A ilha da exploração; ausente no mapa sorteado. */
  islandId?: number;
  /** Os biomas do mapa e o último crédito de hexágonos andados (player-stats/02). */
  biomeIds: Set<number>;
  hexesCreditedAt: number;
  /** Os itens do chão que voltam, já pegos nesta entrada (auralis/09). */
  pickedItemKeys?: Set<number>;
}

interface Entry {
  exploration: StoredExploration;
  lastUsedAt: number;
}

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

  /**
   * Confere o passo até `position` (o Procurar, as missões): quem mente a
   * posição não chega antes de quem anda. Aceito, a posição vira a de agora.
   */
  confirmPosition(
    userId: string,
    position: HexCoord,
  ): StoredExploration | 'none' | 'unreachable' {
    const exploration = this.get(userId);
    if (!exploration) return 'none';
    const now = this.now();
    const walked = hexDistance(exploration.position, position);
    if (walked * MIN_STEP_MS > now - exploration.positionAt) {
      return 'unreachable';
    }
    this.set(userId, { ...exploration, position, positionAt: now });
    return exploration;
  }

  /** Os hexágonos aceitos: só dos biomas do mapa e no máximo um por passo mínimo desde o último crédito. */
  creditHexes(userId: string, hexes: BiomeHexes[]): BiomeHexes[] {
    const exploration = this.get(userId);
    if (!exploration) return [];
    const now = this.now();
    const limit = Math.floor((now - exploration.hexesCreditedAt) / MIN_STEP_MS);
    const accepted = cappedHexes(
      hexes.filter(({ biomeId }) => exploration.biomeIds.has(biomeId)),
      Math.max(0, limit),
    );
    exploration.hexesCreditedAt = now;
    return accepted;
  }

  delete(userId: string): void {
    this.entries.delete(userId);
  }

  private removeExpired(): void {
    const limit = this.now() - MAX_IDLE_MS;
    for (const [userId, entry] of this.entries) {
      if (entry.lastUsedAt <= limit) this.entries.delete(userId);
    }
  }
}
