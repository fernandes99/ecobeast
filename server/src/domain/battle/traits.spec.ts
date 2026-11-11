import {
  contextOf,
  ENEMY,
  makeCatalog,
  makeCombatant,
  makeState,
  PLAYER,
} from './testing.js';
import { applyDefeatTrait, applyEntryTrait } from './traits.js';
import type { Combatant, Spot, TurnContext } from './types.js';

const catalog = makeCatalog();

function turnWith(player: Combatant, enemy: Combatant = makeCombatant()) {
  return contextOf(makeState(player, enemy), catalog);
}

function speedOf(turn: TurnContext, spot: Spot): number {
  return turn.state[spot.side].team[0]!.stages.spd;
}

describe('Instinto', () => {
  it('dá +1 de Velocidade a quem derrotou um inimigo', () => {
    const turn = turnWith(makeCombatant({ traitSlug: 'instinct' }));
    applyDefeatTrait(turn, PLAYER);
    expect(speedOf(turn, PLAYER)).toBe(1);
    expect(turn.events).toEqual([
      {
        type: 'stat_changed',
        side: 'player',
        position: 0,
        stat: 'spd',
        stages: 1,
        value: 1,
      },
    ]);
  });

  it('não vale ao entrar', () => {
    const turn = turnWith(makeCombatant({ traitSlug: 'instinct' }));
    applyEntryTrait(turn, PLAYER);
    expect(turn.events).toEqual([]);
  });
});

describe('Brisa Ligeira', () => {
  it('dá +1 de Velocidade ao entrar', () => {
    const turn = turnWith(makeCombatant({ traitSlug: 'tailwind' }));
    applyEntryTrait(turn, PLAYER);
    expect(speedOf(turn, PLAYER)).toBe(1);
  });

  it('vale para o inimigo', () => {
    const turn = turnWith(
      makeCombatant(),
      makeCombatant({ traitSlug: 'tailwind' }),
    );
    applyEntryTrait(turn, ENEMY);
    expect(speedOf(turn, ENEMY)).toBe(1);
    expect(speedOf(turn, PLAYER)).toBe(0);
  });

  it('não vale ao derrotar', () => {
    const turn = turnWith(makeCombatant({ traitSlug: 'tailwind' }));
    applyDefeatTrait(turn, PLAYER);
    expect(turn.events).toEqual([]);
  });
});

it('um Traço sem efeito no motor é ignorado', () => {
  for (const traitSlug of ['hard_shell', 'novo_traco']) {
    const turn = turnWith(makeCombatant({ traitSlug }));
    applyEntryTrait(turn, PLAYER);
    applyDefeatTrait(turn, PLAYER);
    expect(turn.events).toEqual([]);
  }
});
