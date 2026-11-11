import { pickSlot, skillWeight } from './ai.js';
import {
  always,
  makeCatalog,
  makeCombatant,
  makeSkill,
  sequence,
} from './testing.js';

const SCRATCH = makeSkill({ id: 1 });
const BLAST = makeSkill({ id: 2, power: 120 });
const GROWL = makeSkill({ id: 3, power: 0, category: 'support' });
const catalog = makeCatalog({}, [SCRATCH, BLAST, GROWL]);

function weight(skill = SCRATCH, targetHp = 100, usedCatalog = catalog) {
  return skillWeight(
    makeCombatant(),
    makeCombatant({ currentHp: targetHp }),
    skill,
    usedCatalog,
  );
}

describe('skillWeight', () => {
  it('é o dano como porcentagem do HP atual do alvo', () => {
    // Arranhão causa 5 em 100 de HP.
    expect(weight()).toBe(5);
  });

  it('o suporte vale 20', () => {
    expect(weight(GROWL)).toBe(20);
  });

  it('não passa de 100', () => {
    expect(weight(BLAST, 1)).toBe(100);
  });

  it('não fica abaixo de 1', () => {
    expect(weight(SCRATCH, 100000)).toBe(1);
  });

  it('efetividade 0 tem peso 1', () => {
    const immune = makeCatalog({ '13:1': 0 }, [SCRATCH]);
    expect(weight(SCRATCH, 19, immune)).toBe(1);
  });
});

describe('pickSlot', () => {
  const options = [
    { slot: 1, weight: 5 },
    { slot: 2, weight: 20 },
  ];

  it('sorteia pelo peso', () => {
    expect(pickSlot(options, sequence(0.19))).toBe(1);
    expect(pickSlot(options, sequence(0.21))).toBe(2);
  });

  it('escolhe mais a de maior peso', () => {
    const picks = { 1: 0, 2: 0 };
    for (let draw = 0; draw < 1000; draw += 1) {
      picks[pickSlot(options, always(draw / 1000)) as 1 | 2] += 1;
    }
    expect(picks[2]).toBe(picks[1] * 4);
  });
});
