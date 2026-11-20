import {
  CYCLE_MS,
  EPOCH_MS,
  dayPartOf,
  dayPhaseAt,
  minuteOfDay,
} from './world-clock.js';

const PHASES = [
  { id: 1, startMinute: 360 },
  { id: 2, startMinute: 720 },
  { id: 3, startMinute: 1020 },
  { id: 4, startMinute: 1140 },
];

describe('minuteOfDay', () => {
  it('a EPOCH_MS é a 0h, e 1 segundo real é 1 minuto do jogo', () => {
    expect(EPOCH_MS).toBe(Date.UTC(2026, 0, 1));
    expect(CYCLE_MS).toBe(1_440_000);
    expect(minuteOfDay(EPOCH_MS)).toBe(0);
    expect(minuteOfDay(EPOCH_MS + 90_500)).toBeCloseTo(90.5);
  });

  it('volta a 0 no fim do dia', () => {
    expect(minuteOfDay(EPOCH_MS + CYCLE_MS - 1)).toBeCloseTo(1439.999);
    expect(minuteOfDay(EPOCH_MS + CYCLE_MS)).toBe(0);
    expect(minuteOfDay(EPOCH_MS + 5 * CYCLE_MS + 60_000)).toBe(60);
  });

  it('antes da EPOCH_MS continua entre 0 e 1440', () => {
    expect(minuteOfDay(EPOCH_MS - 1000)).toBe(1439);
    const minute = minuteOfDay(EPOCH_MS - 3 * CYCLE_MS - 123_456);
    expect(minute).toBeGreaterThanOrEqual(0);
    expect(minute).toBeLessThan(1440);
  });
});

describe('dayPhaseAt', () => {
  it('a noite atravessa a 0h', () => {
    expect(dayPhaseAt(0, PHASES).id).toBe(4);
    expect(dayPhaseAt(359, PHASES).id).toBe(4);
    expect(dayPhaseAt(359.9, PHASES).id).toBe(4);
  });

  it('cada parte começa no próprio minuto', () => {
    expect(dayPhaseAt(360, PHASES).id).toBe(1);
    expect(dayPhaseAt(719.5, PHASES).id).toBe(1);
    expect(dayPhaseAt(720, PHASES).id).toBe(2);
    expect(dayPhaseAt(1020, PHASES).id).toBe(3);
    expect(dayPhaseAt(1140, PHASES).id).toBe(4);
    expect(dayPhaseAt(1439.9, PHASES).id).toBe(4);
  });

  it('não depende da ordem da lista', () => {
    expect(dayPhaseAt(800, [...PHASES].reverse()).id).toBe(2);
    expect(dayPhaseAt(100, [...PHASES].reverse()).id).toBe(4);
  });
});

describe('dayPartOf', () => {
  it('a Manhã e a Tarde são o dia', () => {
    expect(dayPartOf('morning')).toBe('day');
    expect(dayPartOf('afternoon')).toBe('day');
  });

  it('o Final de tarde e a Noite são a noite', () => {
    expect(dayPartOf('dusk')).toBe('night');
    expect(dayPartOf('night')).toBe('night');
  });
});
