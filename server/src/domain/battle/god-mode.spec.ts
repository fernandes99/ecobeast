import { startBattle } from './engine.js';
import {
  always,
  eventsOf,
  makeCatalog,
  makeCombatant,
  makeSkill,
  makeState,
  play,
} from './testing.js';
import type { Combatant } from './types.js';

const SCRATCH = makeSkill({ id: 1 });
const catalog = makeCatalog({}, [SCRATCH]);
const ATTACK = { type: 'skill', slot: 1 } as const;

function fighter(overrides: Partial<Combatant> = {}): Combatant {
  return makeCombatant({
    skills: [{ skillId: SCRATCH.id, currentPp: 10 }],
    ...overrides,
  });
}

/** Um inimigo que aguenta muitos golpes normais e é mais lento. */
function tank(): Combatant {
  return fighter({
    creatureUid: null,
    speciesId: 4,
    stats: { hp: 999, atk: 10, def: 999, sp_atk: 10, sp_def: 999, spd: 1 },
    currentHp: 999,
  });
}

describe('modo God (depuração)', () => {
  it('o golpe do jogador que acerta derruba o inimigo de uma vez', () => {
    const { state, events } = play(
      makeState(fighter(), tank(), { godMode: true }),
      ATTACK,
      catalog,
    );
    expect(eventsOf(events, 'damage')[0]).toMatchObject({
      side: 'enemy',
      damage: 999,
      hp: 0,
    });
    expect(state.result).toBe('victory');
  });

  it('o golpe do inimigo continua normal', () => {
    const { events } = play(
      makeState(
        fighter({ stats: { ...fighter().stats, spd: 1 } }),
        {
          ...tank(),
          stats: { ...tank().stats, spd: 99 },
        },
        { godMode: true },
      ),
      ATTACK,
      catalog,
    );
    const [enemyHit] = eventsOf(events, 'damage');
    expect(enemyHit!.side).toBe('player');
    expect(enemyHit!.hp).toBeGreaterThan(0);
  });

  it('desligado, o dano é o normal', () => {
    const { state } = play(makeState(fighter(), tank()), ATTACK, catalog);
    expect(state.enemy.team[0]!.currentHp).toBeGreaterThan(900);
  });

  it('startBattle guarda o modo, e ele começa desligado', () => {
    const on = startBattle(
      [fighter()],
      [tank()],
      true,
      catalog,
      always(0.5),
      [],
      {
        godMode: true,
      },
    );
    const off = startBattle([fighter()], [tank()], true, catalog, always(0.5));
    expect(on.state.godMode).toBe(true);
    expect(off.state.godMode).toBe(false);
  });
});
