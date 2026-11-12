const MAX_IDLE_MS = 2 * 60 * 60 * 1000;

export interface PendingChoice {
  evolutionSpeciesId: number | null;
  levelBefore: number;
  levelAfter: number;
  pendingSkillIds: number[];
}

interface Entry {
  choices: Map<string, PendingChoice>;
  lastUsedAt: number;
}

export class ProgressionStore {
  private readonly entries = new Map<string, Entry>();

  constructor(private readonly now: () => number = Date.now) {}

  get(userId: string, uid: string): PendingChoice | undefined {
    this.removeExpired();
    return this.entries.get(userId)?.choices.get(uid);
  }

  replace(userId: string, choices: Map<string, PendingChoice>): void {
    this.removeExpired();
    if (choices.size === 0) {
      this.entries.delete(userId);
      return;
    }
    this.entries.set(userId, { choices, lastUsedAt: this.now() });
  }

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
