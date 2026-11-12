import type { StatBlock } from '../rules/types.js';
import { MAX_LEVEL, totalXpForLevel } from '../rules/xp-curve.js';

export function levelForXp(xpMultiplier: number, totalXp: number): number {
  let level = 1;
  while (
    level < MAX_LEVEL &&
    totalXpForLevel(xpMultiplier, level + 1) <= totalXp
  ) {
    level += 1;
  }
  return level;
}

/**
 * Soma `amount` ao XP total, sem passar do total do nível 100. O nível nunca
 * desce, nem quando o XP gravado está abaixo do total do nível atual.
 */
export function gainXp(
  xpMultiplier: number,
  level: number,
  currentXp: number,
  amount: number,
): { level: number; currentXp: number } {
  const total = Math.min(
    currentXp + amount,
    totalXpForLevel(xpMultiplier, MAX_LEVEL),
  );
  return {
    level: Math.max(level, levelForXp(xpMultiplier, total)),
    currentXp: total,
  };
}

export interface CreatureLevelState {
  level: number;
  currentXp: number;
  currentHp: number;
}

export interface CreatureProgress {
  levelBefore: number;
  levelAfter: number;
  currentXp: number;
  currentHp: number;
  levelXp: number;
  nextLevelXp: number | null;
  statsBefore: StatBlock;
  statsAfter: StatBlock;
}

export function progressCreature(
  creature: CreatureLevelState,
  amount: number,
  xpMultiplier: number,
  statsAt: (level: number) => StatBlock,
): CreatureProgress {
  const { level, currentXp } = gainXp(
    xpMultiplier,
    creature.level,
    creature.currentXp,
    amount,
  );
  const statsBefore = statsAt(creature.level);
  const statsAfter = level === creature.level ? statsBefore : statsAt(level);
  const hpGain = statsAfter.hp - statsBefore.hp;
  return {
    levelBefore: creature.level,
    levelAfter: level,
    currentXp,
    currentHp: creature.currentHp > 0 ? creature.currentHp + hpGain : 0,
    levelXp: totalXpForLevel(xpMultiplier, level),
    nextLevelXp:
      level < MAX_LEVEL ? totalXpForLevel(xpMultiplier, level + 1) : null,
    statsBefore,
    statsAfter,
  };
}
