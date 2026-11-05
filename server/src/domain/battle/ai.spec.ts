import { chooseEnemyAction } from './ai.js';
import {
  always,
  makeCatalog,
  makeCombatant,
  makeSkill,
  makeState,
  sequence,
} from './testing.js';
import type { Combatant } from './types.js';

const SCRATCH = makeSkill({ id: 1 });
const BLAST = makeSkill({ id: 2, power: 120 });
const GROWL = makeSkill({ id: 3, power: 0, category: 'support' });
const catalog = makeCatalog({}, [SCRATCH, BLAST, GROWL]);

function enemy(...skillIds: number[]): Combatant {
  return makeCombatant({
    skills: skillIds.map((skillId) => ({ skillId, currentPp: 5 })),
  });
}

function choose(
  attacker: Combatant,
  targetHp: number,
  roll: number,
  usedCatalog = catalog,
) {
  const target = makeCombatant({ currentHp: targetHp });
  return chooseEnemyAction(
    makeState(target, attacker),
    usedCatalog,
    sequence(roll),
  );
}

describe('chooseEnemyAction', () => {
  it('escolhe mais a Técnica de maior dano', () => {
    const state = makeState(makeCombatant({ currentHp: 100 }), enemy(1, 2));
    const picks = { 1: 0, 2: 0 };
    for (let draw = 0; draw < 10000; draw += 1) {
      const action = chooseEnemyAction(state, catalog, always(draw / 10000));
      if (action.type === 'skill') picks[action.slot as 1 | 2] += 1;
    }
    expect(picks[1] + picks[2]).toBe(10000);
    expect(picks[2]).toBeGreaterThan(picks[1] * 2);
  });

  it('nunca escolhe uma Técnica sem PP', () => {
    const attacker = enemy(2, 1);
    attacker.skills[0]!.currentPp = 0;
    for (const roll of [0, 0.5, 0.99]) {
      expect(choose(attacker, 19, roll)).toEqual({
        type: 'skill',
        slot: 2,
        position: 0,
        target: 0,
      });
    }
  });

  it('o peso é o dano como porcentagem do HP atual do alvo', () => {
    // Arranhão causa 5 em 100 de HP: peso 5, contra 20 do suporte.
    const attacker = enemy(1, 3);
    expect(choose(attacker, 100, 0.19)).toEqual({
      type: 'skill',
      slot: 1,
      position: 0,
      target: 0,
    });
    expect(choose(attacker, 100, 0.21)).toEqual({
      type: 'skill',
      slot: 2,
      position: 0,
      target: 0,
    });
  });

  it('o peso não passa de 100', () => {
    const attacker = enemy(2, 3);
    expect(choose(attacker, 1, 0.82)).toEqual({
      type: 'skill',
      slot: 1,
      position: 0,
      target: 0,
    });
    expect(choose(attacker, 1, 0.84)).toEqual({
      type: 'skill',
      slot: 2,
      position: 0,
      target: 0,
    });
  });

  it('o peso não fica abaixo de 1', () => {
    const attacker = enemy(1, 3);
    expect(choose(attacker, 100000, 0.04)).toEqual({
      type: 'skill',
      slot: 1,
      position: 0,
      target: 0,
    });
    expect(choose(attacker, 100000, 0.05)).toEqual({
      type: 'skill',
      slot: 2,
      position: 0,
      target: 0,
    });
  });

  it('efetividade 0 tem peso 1', () => {
    const immune = makeCatalog({ '13:1': 0 }, [SCRATCH, GROWL]);
    const attacker = enemy(1, 3);
    expect(choose(attacker, 19, 0.04, immune)).toEqual({
      type: 'skill',
      slot: 1,
      position: 0,
      target: 0,
    });
    expect(choose(attacker, 19, 0.05, immune)).toEqual({
      type: 'skill',
      slot: 2,
      position: 0,
      target: 0,
    });
  });

  it('sem PP em todas as Técnicas, usa o golpe de emergência', () => {
    const attacker = enemy(1, 2);
    attacker.skills.forEach((skill) => (skill.currentPp = 0));
    expect(
      chooseEnemyAction(
        makeState(makeCombatant(), attacker),
        catalog,
        sequence(),
      ),
    ).toEqual({ type: 'emergency', position: 0, target: 0 });
  });
});
