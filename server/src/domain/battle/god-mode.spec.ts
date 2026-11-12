import {
  always,
  cast,
  ENEMY,
  eventsOf,
  makeCatalog,
  makeCombatant,
  makeSkill,
  makeState,
  PLAYER,
} from './testing.js';
import type { Combatant } from './types.js';

const SCRATCH = makeSkill({ id: 1 });
const catalog = makeCatalog({}, [SCRATCH]);

function fighter(overrides: Partial<Combatant> = {}): Combatant {
  return makeCombatant({
    skills: [{ skillId: SCRATCH.id, currentPp: 10 }],
    ...overrides,
  });
}

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
    const { events } = cast(
      makeState(fighter(), tank(), { godMode: true }),
      SCRATCH,
      catalog,
    );
    expect(eventsOf(events, 'damage')[0]).toMatchObject({
      side: 'enemy',
      position: 0,
      damage: 999,
      hp: 0,
    });
  });

  it('o golpe do inimigo continua normal', () => {
    const { events } = cast(
      makeState(fighter(), tank(), { godMode: true }),
      SCRATCH,
      catalog,
      always(0.5),
      ENEMY,
      PLAYER,
    );
    const [enemyHit] = eventsOf(events, 'damage');
    expect(enemyHit!.side).toBe('player');
    expect(enemyHit!.hp).toBeGreaterThan(0);
  });

  it('desligado, o dano é o normal', () => {
    const { state } = cast(makeState(fighter(), tank()), SCRATCH, catalog);
    expect(state.enemy.team[0]!.currentHp).toBeGreaterThan(900);
  });
});
