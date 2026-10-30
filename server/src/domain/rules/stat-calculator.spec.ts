import { calculateStats } from './stat-calculator.js';
import { StatBlock } from './types.js';

function block(values: Partial<StatBlock> = {}): StatBlock {
  return { hp: 0, atk: 0, def: 0, sp_atk: 0, sp_def: 0, spd: 0, ...values };
}

const NEUTRAL = { increasedStat: null, decreasedStat: null };

describe('calculateStats', () => {
  it('HP: base 39, Genes 31, Treino 0, nível 5 dá 20', () => {
    const stats = calculateStats(
      block({ hp: 39 }),
      block({ hp: 31 }),
      block(),
      5,
      NEUTRAL,
    );
    expect(stats.hp).toBe(20);
  });

  it('outro stat: base 52, Genes 0, nível 5 dá 10 no neutro', () => {
    const stats = calculateStats(
      block({ atk: 52 }),
      block(),
      block(),
      5,
      NEUTRAL,
    );
    expect(stats.atk).toBe(10);
  });

  it('o Temperamento aumenta um stat em 10% e diminui outro em 10%', () => {
    const base = block({ atk: 52, def: 52 });
    const up = calculateStats(base, block(), block(), 5, {
      increasedStat: 'atk',
      decreasedStat: 'def',
    });
    expect(up.atk).toBe(11);
    expect(up.def).toBe(9);
  });

  it('Temperamento com aumentado igual ao diminuído é neutro', () => {
    const stats = calculateStats(block({ atk: 52 }), block(), block(), 5, {
      increasedStat: 'atk',
      decreasedStat: 'atk',
    });
    expect(stats.atk).toBe(10);
  });

  it('o Temperamento não muda o HP', () => {
    const stats = calculateStats(block({ hp: 39 }), block(), block(), 5, {
      increasedStat: 'hp',
      decreasedStat: 'atk',
    });
    expect(stats.hp).toBe(18);
  });

  it('Treino 252 soma floor(252/4) = 63 antes da fórmula', () => {
    const stats = calculateStats(
      block({ atk: 52 }),
      block(),
      block({ atk: 252 }),
      100,
      NEUTRAL,
    );
    // (2·52 + 0 + 63) · 100 / 100 + 5
    expect(stats.atk).toBe(172);
  });

  it('Treino que não fecha múltiplo de 4 é arredondado para baixo', () => {
    const three = calculateStats(
      block({ atk: 50 }),
      block(),
      block({ atk: 3 }),
      100,
      NEUTRAL,
    );
    const zero = calculateStats(
      block({ atk: 50 }),
      block(),
      block(),
      100,
      NEUTRAL,
    );
    expect(three.atk).toBe(zero.atk);
  });

  it('a multiplicação do Temperamento é inteira, sem erro de ponto flutuante', () => {
    // 172 · 1,1 = 189,2 e 172 · 0,9 = 154,8.
    const stats = calculateStats(
      block({ atk: 52, def: 52 }),
      block(),
      block({ atk: 252, def: 252 }),
      100,
      { increasedStat: 'atk', decreasedStat: 'def' },
    );
    expect(stats.atk).toBe(189);
    expect(stats.def).toBe(154);
    // Stat 110 antes do Temperamento: 121 e 99 exatos.
    const exact = calculateStats(
      block({ atk: 52, def: 52 }),
      block({ atk: 1, def: 1 }),
      block(),
      100,
      { increasedStat: 'atk', decreasedStat: 'def' },
    );
    expect(exact.atk).toBe(121);
    expect(exact.def).toBe(99);
  });

  it('devolve os 6 stats', () => {
    const stats = calculateStats(block(), block(), block(), 5, NEUTRAL);
    expect(Object.keys(stats).sort()).toEqual(
      ['atk', 'def', 'hp', 'sp_atk', 'sp_def', 'spd'].sort(),
    );
  });
});
