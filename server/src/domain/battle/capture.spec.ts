import { captureChance, firstFreePartySlot } from './capture.js';

const FULL = { currentHp: 300, maxHp: 300 };
const BASE = { ...FULL, captureRate: 45, captureBonus: 1, statusSlug: null };

describe('captureChance', () => {
  it('com HP cheio, a vida não ajuda', () => {
    expect(captureChance(BASE)).toBeCloseTo(0.15);
  });

  it('com HP mínimo, chega quase ao triplo', () => {
    const chance = captureChance({ ...BASE, currentHp: 1, captureBonus: 2 });
    expect(chance).toBeGreaterThan(0.89);
    expect(chance).toBeLessThan(0.9);
  });

  it('multiplica pelo bônus da Esfera', () => {
    expect(captureChance({ ...BASE, captureBonus: 1.5 })).toBeCloseTo(0.225);
  });

  it.each([
    ['sleep', 2.5],
    ['freeze', 2.5],
    ['paralysis', 1.5],
    ['burn', 1.5],
    ['poison', 1.5],
  ])('%s multiplica por %d', (statusSlug, bonus) => {
    expect(captureChance({ ...BASE, statusSlug })).toBeCloseTo(0.15 * bonus);
  });

  it('um status sem bônus não muda a chance', () => {
    expect(captureChance({ ...BASE, statusSlug: 'confusion' })).toBeCloseTo(
      0.15,
    );
  });

  it('nunca passa de 1', () => {
    const best = {
      currentHp: 1,
      maxHp: 300,
      captureRate: 100,
      captureBonus: 2,
      statusSlug: 'sleep',
    };
    expect(captureChance(best)).toBe(1);
  });

  it('com capture_rate 0, a chance é 0', () => {
    expect(captureChance({ ...BASE, captureRate: 0 })).toBe(0);
  });
});

describe('firstFreePartySlot', () => {
  it('sem ninguém, é a primeira', () => {
    expect(firstFreePartySlot([])).toBe(1);
  });

  it('pega a vaga depois da última', () => {
    expect(firstFreePartySlot([1, 2])).toBe(3);
  });

  it('prefere a vaga do meio', () => {
    expect(firstFreePartySlot([1, 3, 4])).toBe(2);
  });

  it('com as 6 ocupadas, não há vaga', () => {
    expect(firstFreePartySlot([1, 2, 3, 4, 5, 6])).toBeNull();
  });
});
