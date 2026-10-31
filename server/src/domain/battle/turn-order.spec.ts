import { makeCombatant, sequence } from './testing.js';
import { orderActions } from './turn-order.js';

const stats = (spd: number) => ({
  hp: 19,
  atk: 10,
  def: 9,
  sp_atk: 11,
  sp_def: 9,
  spd,
});

function action(spd: number, priority = 0, statusSlug: string | null = null) {
  return {
    priority,
    combatant: makeCombatant({ stats: stats(spd), statusSlug }),
  };
}

describe('orderActions', () => {
  it('a maior Velocidade age primeiro', () => {
    const slow = action(5);
    const fast = action(20);
    expect(orderActions(slow, fast, sequence())).toEqual([fast, slow]);
  });

  it('prioridade vem antes da Velocidade', () => {
    const slow = action(5, 1);
    const fast = action(20);
    expect(orderActions(fast, slow, sequence())).toEqual([slow, fast]);
  });

  it('um Paralisado com Velocidade 20 perde para Velocidade 11', () => {
    const paralyzed = action(20, 0, 'paralysis');
    const normal = action(11);
    expect(orderActions(paralyzed, normal, sequence())).toEqual([
      normal,
      paralyzed,
    ]);
  });

  it('considera os estágios de Velocidade', () => {
    const boosted = action(10);
    boosted.combatant.stages.spd = 2;
    const fast = action(15);
    expect(orderActions(fast, boosted, sequence())).toEqual([boosted, fast]);
  });

  it('um empate total obedece ao sorteio', () => {
    const one = action(10);
    const two = action(10);
    expect(orderActions(one, two, sequence(0.2))).toEqual([one, two]);
    expect(orderActions(one, two, sequence(0.8))).toEqual([two, one]);
  });

  it('sem empate, não sorteia', () => {
    expect(() => orderActions(action(1), action(2), sequence())).not.toThrow();
  });
});
