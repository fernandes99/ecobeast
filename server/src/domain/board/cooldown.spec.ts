import { cooldownLeft, isReady, startCooldown } from './cooldown.js';

describe('cooldown', () => {
  it('sem readyRound, a Técnica está livre', () => {
    expect(cooldownLeft({ skillId: 1, currentPp: 5 }, 1)).toBe(0);
  });

  it('com countdown 2, usada na rodada 1, faltam 2 e depois 1, e volta na 4', () => {
    const learned = { skillId: 1, currentPp: 5 };
    startCooldown(learned, 1, 2);
    expect([2, 3, 4].map((round) => cooldownLeft(learned, round))).toEqual([
      2, 1, 0,
    ]);
    expect(isReady(learned, 4)).toBe(true);
  });
});
