import {
  always,
  eventsOf,
  makeCatalog,
  makeCombatant,
  makeEffect,
  makeSkill,
  makeState,
  play,
} from './testing.js';
import type { BattleAction, Combatant } from './types.js';

const SCRATCH = makeSkill({ id: 1 });
const IDLE = makeSkill({
  id: 2,
  power: 0,
  accuracy: 0,
  category: 'support',
  targetSlug: 'self',
});
const QUICK = makeSkill({ id: 3, priority: 1 });
const SHELL = makeSkill({
  id: 4,
  power: 0,
  accuracy: 0,
  category: 'support',
  targetSlug: 'self',
  priority: 4,
  effects: [makeEffect({ effectSlug: 'protect' })],
});
const catalog = makeCatalog({}, [SCRATCH, IDLE, QUICK, SHELL]);
const EMERGENCY: BattleAction = { type: 'emergency' };

function outOfPp(overrides: Partial<Combatant> = {}): Combatant {
  return makeCombatant({
    skills: [{ skillId: 1, currentPp: 0 }],
    stats: { hp: 19, atk: 10, def: 9, sp_atk: 11, sp_def: 9, spd: 20 },
    ...overrides,
  });
}

function knowing(skillId: number, overrides: Partial<Combatant> = {}) {
  return makeCombatant({
    skills: [{ skillId, currentPp: 10 }],
    ...overrides,
  });
}

describe('golpe de emergência', () => {
  it('causa dano, sem Técnica no evento', () => {
    const { state, events } = play(
      makeState(outOfPp(), knowing(2)),
      EMERGENCY,
      catalog,
    );
    expect(eventsOf(events, 'skill_used')[0]).toEqual({
      type: 'skill_used',
      side: 'player',
      position: 0,
      skill_id: null,
    });
    expect(state.enemy.team[0]!.currentHp).toBe(15);
  });

  it('tira 1/8 do HP máximo do autor, depois do golpe', () => {
    const { state, events } = play(
      makeState(outOfPp(), knowing(2)),
      EMERGENCY,
      catalog,
    );
    expect(state.player.team[0]!.currentHp).toBe(17);
    const types = events.map((event) => event.type);
    expect(types.indexOf('recoil')).toBeGreaterThan(types.indexOf('damage'));
    expect(eventsOf(events, 'recoil')).toEqual([
      { type: 'recoil', side: 'player', position: 0, damage: 2, hp: 17 },
    ]);
  });

  it('o dano em si mesmo é ao menos 1', () => {
    const stats = { hp: 7, atk: 10, def: 9, sp_atk: 11, sp_def: 9, spd: 20 };
    const { events } = play(
      makeState(outOfPp({ stats, currentHp: 7 }), knowing(2)),
      EMERGENCY,
      catalog,
    );
    expect(eventsOf(events, 'recoil')[0]).toMatchObject({ damage: 1, hp: 6 });
  });

  it('não gasta PP', () => {
    const { state } = play(
      makeState(outOfPp(), knowing(2)),
      EMERGENCY,
      catalog,
    );
    expect(state.player.team[0]!.skills[0]!.currentPp).toBe(0);
  });

  it('nunca erra', () => {
    const dodgy = knowing(2);
    dodgy.stages.evasion = 6;
    const { events } = play(
      makeState(outOfPp(), dodgy),
      EMERGENCY,
      catalog,
      always(0.99),
    );
    expect(eventsOf(events, 'missed')).toEqual([]);
    expect(eventsOf(events, 'damage')).toHaveLength(1);
  });

  it('não tem Elemento: nada é imune, e não há STAB', () => {
    const immune = makeCatalog({ '13:1': 0 }, [SCRATCH, IDLE]);
    const { events } = play(
      makeState(outOfPp({ elementIds: [13] }), knowing(2)),
      EMERGENCY,
      immune,
    );
    expect(eventsOf(events, 'damage')[0]).toMatchObject({
      damage: 4,
      multiplier: 1,
    });
  });

  it('tem prioridade 0', () => {
    const { events } = play(
      makeState(outOfPp(), knowing(3)),
      EMERGENCY,
      catalog,
    );
    expect(eventsOf(events, 'skill_used').map((e) => e.side)).toEqual([
      'enemy',
      'player',
    ]);
  });

  it('pode desmaiar quem o usa', () => {
    const { state, events } = play(
      makeState(outOfPp({ currentHp: 1 }), knowing(2)),
      EMERGENCY,
      catalog,
    );
    expect(state.result).toBe('defeat');
    expect(eventsOf(events, 'fainted')).toEqual([
      { type: 'fainted', side: 'player', position: 0 },
    ]);
  });

  it('bloqueado, não tira HP do autor', () => {
    const { state, events } = play(
      makeState(outOfPp(), knowing(4)),
      EMERGENCY,
      catalog,
    );
    expect(eventsOf(events, 'blocked')).toHaveLength(1);
    expect(state.player.team[0]!.currentHp).toBe(19);
  });

  it('o inimigo sem PP também o usa', () => {
    const enemy = outOfPp();
    const { state, events } = play(
      makeState(knowing(2), enemy),
      { type: 'skill', slot: 1 },
      catalog,
    );
    expect(eventsOf(events, 'skill_used')[0]).toEqual({
      type: 'skill_used',
      side: 'enemy',
      position: 0,
      skill_id: null,
    });
    expect(state.enemy.team[0]!.currentHp).toBe(17);
  });

  it('o Instinto vale ao derrotar com ele', () => {
    const { state } = play(
      makeState(outOfPp({ traitSlug: 'instinct' }), [
        knowing(2, { currentHp: 1 }),
        knowing(2),
      ]),
      EMERGENCY,
      catalog,
    );
    expect(state.player.team[0]!.stages.spd).toBe(1);
  });
});
