import { describe, expect, it } from 'vitest';
import {
  cappedHexes,
  nextStreak,
  playDayOf,
  playSecondsFor,
} from './ping.js';

const NOW = new Date('2026-11-21T15:00:00Z');
const ago = (seconds: number) => new Date(NOW.getTime() - seconds * 1000);

describe('playSecondsFor', () => {
  it('não conta tempo no primeiro sinal', () => {
    expect(playSecondsFor(null, NOW)).toBe(0);
  });

  it('conta o tempo desde o último sinal', () => {
    expect(playSecondsFor(ago(60), NOW)).toBe(60);
  });

  it('não conta nada depois de mais de 90 s parado', () => {
    expect(playSecondsFor(ago(91), NOW)).toBe(0);
  });
});

describe('playDayOf', () => {
  it('usa o dia de Brasília', () => {
    expect(playDayOf(new Date('2026-11-22T02:30:00Z'))).toBe('2026-11-21');
    expect(playDayOf(new Date('2026-11-22T03:30:00Z'))).toBe('2026-11-22');
  });
});

describe('nextStreak', () => {
  it('o primeiro dia começa a sequência', () => {
    expect(nextStreak(null, '2026-11-21', 0)).toEqual({
      newDay: true,
      streak: 1,
    });
  });

  it('o dia seguinte soma 1', () => {
    expect(nextStreak('2026-11-20', '2026-11-21', 3)).toEqual({
      newDay: true,
      streak: 4,
    });
  });

  it('pular um dia volta a 1', () => {
    expect(nextStreak('2026-11-19', '2026-11-21', 3)).toEqual({
      newDay: true,
      streak: 1,
    });
  });

  it('o mesmo dia não muda nada', () => {
    expect(nextStreak('2026-11-21', '2026-11-21', 4)).toEqual({
      newDay: false,
      streak: 4,
    });
  });

  it('a virada do mês e do ano conta como dia seguinte', () => {
    expect(nextStreak('2026-12-31', '2027-01-01', 2).streak).toBe(3);
  });
});

describe('cappedHexes', () => {
  it('corta cada bioma na mesma proporção acima do teto', () => {
    expect(
      cappedHexes(
        [
          { biomeId: 1, count: 30 },
          { biomeId: 2, count: 10 },
        ],
        20,
      ),
    ).toEqual([
      { biomeId: 1, count: 15 },
      { biomeId: 2, count: 5 },
    ]);
  });

  it('abaixo do teto, sai igual', () => {
    const hexes = [{ biomeId: 1, count: 5 }];
    expect(cappedHexes(hexes, 20)).toEqual(hexes);
  });

  it('com teto 0, nada conta', () => {
    expect(cappedHexes([{ biomeId: 1, count: 5 }], 0)).toEqual([]);
  });
});
