import { gainXp, levelForXp, progressCreature } from './levels.js';

const MEDIUM = 1.0;

describe('levelForXp', () => {
  it('é o maior nível cujo XP total cabe no XP', () => {
    expect(levelForXp(MEDIUM, 1727)).toBe(11);
    expect(levelForXp(MEDIUM, 1728)).toBe(12);
    expect(levelForXp(MEDIUM, 2196)).toBe(12);
  });

  it('não passa de 100', () => {
    expect(levelForXp(MEDIUM, 5_000_000)).toBe(100);
  });

  it('não fica abaixo de 1', () => {
    expect(levelForXp(MEDIUM, 0)).toBe(1);
  });
});

describe('gainXp', () => {
  it('soma o XP e sobe o nível', () => {
    expect(gainXp(MEDIUM, 11, 1708, 42)).toEqual({
      level: 12,
      currentXp: 1750,
    });
  });

  it('fica no mesmo nível quando não chega ao próximo', () => {
    expect(gainXp(MEDIUM, 5, 125, 44)).toEqual({ level: 5, currentXp: 169 });
  });

  it('pula vários níveis de uma vez', () => {
    expect(gainXp(MEDIUM, 5, 125, 1000)).toEqual({
      level: 10,
      currentXp: 1125,
    });
  });

  it('para no XP total do nível 100', () => {
    expect(gainXp(MEDIUM, 99, 970_299, 50_000)).toEqual({
      level: 100,
      currentXp: 1_000_000,
    });
  });

  it('usa a curva da espécie', () => {
    expect(gainXp(1.25, 5, 156, 114)).toEqual({ level: 6, currentXp: 270 });
  });

  it('não desce de nível com XP abaixo do nível atual', () => {
    expect(gainXp(MEDIUM, 5, 0, 10)).toEqual({ level: 5, currentXp: 10 });
  });
});

describe('progressCreature', () => {
  const statsAt = (level: number) => ({
    hp: 3 * level,
    atk: 2 * level,
    def: 2 * level,
    sp_atk: 2 * level,
    sp_def: 2 * level,
    spd: 2 * level,
  });

  it('sobe o nível, recalcula os stats e sobe o HP o mesmo tanto que o máximo', () => {
    expect(
      progressCreature(
        { level: 11, currentXp: 1708, currentHp: 10 },
        42,
        MEDIUM,
        statsAt,
      ),
    ).toEqual({
      levelBefore: 11,
      levelAfter: 12,
      currentXp: 1750,
      currentHp: 13,
      levelXp: 1728,
      nextLevelXp: 2197,
      statsBefore: statsAt(11),
      statsAfter: statsAt(12),
    });
  });

  it('sem subir de nível, o HP não muda', () => {
    const result = progressCreature(
      { level: 5, currentXp: 125, currentHp: 7 },
      44,
      MEDIUM,
      statsAt,
    );
    expect(result.levelAfter).toBe(5);
    expect(result.currentHp).toBe(7);
    expect(result.statsAfter).toEqual(result.statsBefore);
  });

  it('quem desmaiou depois de ganhar XP continua com 0 de HP', () => {
    const result = progressCreature(
      { level: 11, currentXp: 1708, currentHp: 0 },
      42,
      MEDIUM,
      statsAt,
    );
    expect(result.levelAfter).toBe(12);
    expect(result.currentHp).toBe(0);
  });

  it('no nível 100, não há próximo nível', () => {
    const result = progressCreature(
      { level: 99, currentXp: 999_000, currentHp: 5 },
      5_000,
      MEDIUM,
      statsAt,
    );
    expect(result.levelAfter).toBe(100);
    expect(result.levelXp).toBe(1_000_000);
    expect(result.nextLevelXp).toBeNull();
  });
});
