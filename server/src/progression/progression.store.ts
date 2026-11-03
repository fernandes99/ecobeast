const MAX_IDLE_MS = 2 * 60 * 60 * 1000;

/** O que falta o jogador escolher para um Ecobeast depois da vitória. */
export interface PendingChoice {
  /** A espécie oferecida; nula depois da escolha ou quando não há evolução. */
  evolutionSpeciesId: number | null;
  levelBefore: number;
  levelAfter: number;
  /** As Técnicas sem vaga, na ordem em que o jogador as vê. */
  pendingSkillIds: number[];
}

interface Entry {
  choices: Map<string, PendingChoice>;
  lastUsedAt: number;
}

/**
 * As escolhas pendentes de cada jogador, por `uid`, na memória deste processo
 * (.specs/progression/architecture.md, "Escolhas pendentes"). Reiniciar o servidor
 * as perde: a evolução volta no próximo nível, e a Técnica conta como não
 * aprendida. Saem depois de 2 horas sem uso.
 */
export class ProgressionStore {
  private readonly entries = new Map<string, Entry>();

  constructor(private readonly now: () => number = Date.now) {}

  get(userId: string, uid: string): PendingChoice | undefined {
    this.removeExpired();
    return this.entries.get(userId)?.choices.get(uid);
  }

  /** O fim de cada vitória troca todas as escolhas do jogador pelas novas. */
  replace(userId: string, choices: Map<string, PendingChoice>): void {
    this.removeExpired();
    if (choices.size === 0) {
      this.entries.delete(userId);
      return;
    }
    this.entries.set(userId, { choices, lastUsedAt: this.now() });
  }

  /** Troca a escolha de um Ecobeast; com `null`, ela sai. */
  update(userId: string, uid: string, choice: PendingChoice | null): void {
    this.removeExpired();
    const entry = this.entries.get(userId);
    if (!entry) return;
    if (choice) entry.choices.set(uid, choice);
    else entry.choices.delete(uid);
    entry.lastUsedAt = this.now();
    if (entry.choices.size === 0) this.entries.delete(userId);
  }

  private removeExpired(): void {
    const limit = this.now() - MAX_IDLE_MS;
    for (const [userId, entry] of this.entries) {
      if (entry.lastUsedAt <= limit) this.entries.delete(userId);
    }
  }
}
