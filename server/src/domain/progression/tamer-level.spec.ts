import {
  addTamerXp,
  levelBounds,
  type TamerLevelRow,
  tamerXpFromBattle,
} from './tamer-level.js';

const SOURCES = new Map([
  ['battle_xp_percent', 10],
  ['new_species', 100],
  ['tamer_win', 50],
]);

function row(level: number, xpTotal: number, rewardCoins = 0): TamerLevelRow {
  return {
    level,
    xpTotal,
    rewardCoins,
    rewardItemId: null,
    rewardItemQuantity: null,
  };
}

const LEVELS: TamerLevelRow[] = [
  row(1, 0),
  row(2, 41, 70),
  row(3, 86, 80),
  { ...row(4, 142, 90), rewardItemId: 1, rewardItemQuantity: 3 },
];

describe('tamerXpFromBattle', () => {
  const base = {
    rawEnemyXp: 85,
    victory: true,
    opponentIsTamer: false,
    newSpeciesCount: 0,
  };

  it('dá a porcentagem do XP bruto na vitória, arredondada para baixo', () => {
    expect(tamerXpFromBattle(base, SOURCES)).toBe(8);
  });

  it('não dá a parte da luta sem vitória', () => {
    expect(tamerXpFromBattle({ ...base, victory: false }, SOURCES)).toBe(0);
  });

  it('soma a espécie nova mesmo sem vitória', () => {
    expect(
      tamerXpFromBattle(
        { ...base, victory: false, newSpeciesCount: 2 },
        SOURCES,
      ),
    ).toBe(200);
  });

  it('soma o Domador vencido', () => {
    expect(tamerXpFromBattle({ ...base, opponentIsTamer: true }, SOURCES)).toBe(
      58,
    );
  });

  it('não dá o Domador sem vitória', () => {
    expect(
      tamerXpFromBattle(
        { ...base, victory: false, opponentIsTamer: true },
        SOURCES,
      ),
    ).toBe(0);
  });

  it('vale 0 a fonte que falta', () => {
    expect(
      tamerXpFromBattle(
        { ...base, opponentIsTamer: true, newSpeciesCount: 1 },
        new Map(),
      ),
    ).toBe(0);
  });
});

describe('addTamerXp', () => {
  it('soma sem subir quando não chega ao próximo', () => {
    expect(addTamerXp(10, 1, 20, LEVELS)).toEqual({
      xp: 30,
      level: 1,
      levels: [],
    });
  });

  it('sobe vários níveis de uma vez, com cada recompensa em ordem', () => {
    expect(addTamerXp(30, 1, 60, LEVELS)).toEqual({
      xp: 90,
      level: 3,
      levels: [LEVELS[1], LEVELS[2]],
    });
  });

  it('para no máximo e continua somando o XP', () => {
    expect(addTamerXp(100, 3, 10_000, LEVELS)).toEqual({
      xp: 10_100,
      level: 4,
      levels: [LEVELS[3]],
    });
    expect(addTamerXp(10_100, 4, 50, LEVELS)).toEqual({
      xp: 10_150,
      level: 4,
      levels: [],
    });
  });

  it('não paga de novo um nível que o jogador já tem', () => {
    expect(addTamerXp(90, 3, 0, LEVELS).levels).toEqual([]);
  });
});

describe('levelBounds', () => {
  it('dá o XP do nível e o do próximo', () => {
    expect(levelBounds(2, LEVELS)).toEqual({ levelXp: 41, nextLevelXp: 86 });
  });

  it('não tem próximo no máximo', () => {
    expect(levelBounds(4, LEVELS)).toEqual({
      levelXp: 142,
      nextLevelXp: null,
    });
  });

  it('começa do zero sem níveis no catálogo', () => {
    expect(levelBounds(1, [])).toEqual({ levelXp: 0, nextLevelXp: null });
  });
});
