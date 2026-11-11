import { EMERGENCY_SKILL, hasPp } from './emergency.js';
import {
  always,
  cast,
  eventsOf,
  makeCatalog,
  makeCombatant,
  makeSkill,
  makeState,
} from './testing.js';
import type { Combatant } from './types.js';

const SCRATCH = makeSkill({ id: 1 });
const catalog = makeCatalog({}, [SCRATCH]);

function outOfPp(overrides: Partial<Combatant> = {}): Combatant {
  return makeCombatant({
    skills: [{ skillId: 1, currentPp: 0 }],
    ...overrides,
  });
}

function strike(
  author: Combatant,
  target: Combatant = makeCombatant(),
  usedCatalog = catalog,
  random = always(0.5),
) {
  return cast(makeState(author, target), EMERGENCY_SKILL, usedCatalog, random);
}

describe('golpe de emergência', () => {
  it('causa dano', () => {
    const { state } = strike(outOfPp());
    expect(state.enemy.team[0]!.currentHp).toBe(15);
  });

  it('tira 1/8 do HP máximo do autor, depois do golpe', () => {
    const { state, events } = strike(outOfPp());
    expect(state.player.team[0]!.currentHp).toBe(17);
    const types = events.map((event) => event.type);
    expect(types.indexOf('recoil')).toBeGreaterThan(types.indexOf('damage'));
    expect(eventsOf(events, 'recoil')).toEqual([
      { type: 'recoil', side: 'player', position: 0, damage: 2, hp: 17 },
    ]);
  });

  it('o dano em si mesmo é ao menos 1', () => {
    const stats = { hp: 7, atk: 10, def: 9, sp_atk: 11, sp_def: 9, spd: 20 };
    const { events } = strike(outOfPp({ stats, currentHp: 7 }));
    expect(eventsOf(events, 'recoil')[0]).toMatchObject({ damage: 1, hp: 6 });
  });

  it('nunca erra', () => {
    const dodgy = makeCombatant();
    dodgy.stages.evasion = 6;
    const { events } = strike(outOfPp(), dodgy, catalog, always(0.99));
    expect(eventsOf(events, 'missed')).toEqual([]);
    expect(eventsOf(events, 'damage')).toHaveLength(1);
  });

  it('não tem Elemento: nada é imune, e não há STAB', () => {
    const immune = makeCatalog({ '13:1': 0 }, [SCRATCH]);
    const { events } = strike(
      outOfPp({ elementIds: [13] }),
      makeCombatant(),
      immune,
    );
    expect(eventsOf(events, 'damage')[0]).toMatchObject({
      damage: 4,
      multiplier: 1,
    });
  });

  it('tem prioridade 0', () => {
    expect(EMERGENCY_SKILL.priority).toBe(0);
  });

  it('pode deixar sem HP quem o usa', () => {
    const { state } = strike(outOfPp({ currentHp: 1 }));
    expect(state.player.team[0]!.currentHp).toBe(0);
  });

  it('bloqueado, não tira HP do autor', () => {
    const { state, events } = strike(
      outOfPp(),
      makeCombatant({ isProtected: true }),
    );
    expect(eventsOf(events, 'blocked')).toHaveLength(1);
    expect(state.player.team[0]!.currentHp).toBe(19);
  });
});

describe('hasPp', () => {
  it('é falso só com todas as Técnicas zeradas', () => {
    expect(hasPp(outOfPp())).toBe(false);
    expect(
      hasPp(
        makeCombatant({
          skills: [
            { skillId: 1, currentPp: 0 },
            { skillId: 1, currentPp: 1 },
          ],
        }),
      ),
    ).toBe(true);
  });
});
