import { calculateDamage, typeMultiplier } from './damage.js';
import {
  BEAST,
  FIRE,
  FLORA,
  makeCatalog,
  makeCombatant,
  makeSkill,
  WATER,
} from './testing.js';
import type { Combatant } from './types.js';

const NO_CATALOG = makeCatalog();

/** Atq 10 contra Def 9, nível 5, Arranhão, sem nada mais. */
function damage(
  options: {
    attacker?: Partial<Combatant>;
    defender?: Partial<Combatant>;
    skill?: Parameters<typeof makeSkill>[0];
    catalog?: typeof NO_CATALOG;
    isCritical?: boolean;
    randomFactor?: number;
  } = {},
): number {
  return calculateDamage({
    attacker: makeCombatant(options.attacker),
    defender: makeCombatant({ elementIds: [FLORA], ...options.defender }),
    skill: makeSkill(options.skill),
    catalog: options.catalog ?? NO_CATALOG,
    isCritical: options.isCritical ?? false,
    randomFactor: options.randomFactor ?? 1,
  });
}

describe('typeMultiplier', () => {
  const catalog = makeCatalog({ '1:3': 2, '1:2': 0.5, '4:5': 0 });

  it('par sem linha vale 1', () => {
    expect(typeMultiplier(BEAST, [FLORA], catalog)).toBe(1);
  });

  it('multiplica os dois Elementos do defensor', () => {
    expect(typeMultiplier(FIRE, [FLORA, WATER], catalog)).toBe(1);
    expect(typeMultiplier(FIRE, [FLORA, FLORA], catalog)).toBe(4);
  });

  it('sem Elemento, vale 1', () => {
    expect(typeMultiplier(null, [FLORA], catalog)).toBe(1);
  });
});

describe('calculateDamage', () => {
  it('Arranhão de um Fagulho nível 5 causa 5', () => {
    expect(damage()).toBe(5);
  });

  it('com STAB, causa 8', () => {
    expect(damage({ attacker: { elementIds: [BEAST] } })).toBe(8);
  });

  it('com Tipo 2, causa 11', () => {
    const catalog = makeCatalog({ '13:3': 2 });
    expect(damage({ catalog })).toBe(11);
  });

  it('com Aleatório 0,85, causa 4', () => {
    expect(damage({ randomFactor: 0.85 })).toBe(4);
  });

  it('crítico multiplica por 1,5', () => {
    expect(damage({ isCritical: true })).toBe(8);
  });

  it('especial usa Atq.E e Def.E', () => {
    const stats = { hp: 19, atk: 1, def: 200, sp_atk: 10, sp_def: 9, spd: 11 };
    expect(
      damage({
        attacker: { stats },
        defender: { stats },
        skill: { category: 'special' },
      }),
    ).toBe(5);
  });

  it('considera os estágios', () => {
    const attacker = makeCombatant();
    attacker.stages.atk = 2;
    expect(damage({ attacker })).toBe(9);
  });

  it('crítico ignora estágio negativo do atacante', () => {
    const attacker = makeCombatant();
    attacker.stages.atk = -6;
    expect(damage({ attacker, isCritical: true })).toBe(8);
  });

  it('crítico ignora estágio positivo do defensor', () => {
    const defender = makeCombatant({ elementIds: [FLORA] });
    defender.stages.def = 6;
    expect(damage({ defender, isCritical: true })).toBe(8);
  });

  it('crítico mantém estágio positivo do atacante', () => {
    const attacker = makeCombatant();
    attacker.stages.atk = 2;
    expect(damage({ attacker, isCritical: true })).toBe(13);
  });

  it('Queimado causa metade com Técnica física', () => {
    expect(damage({ attacker: { statusSlug: 'burn' } })).toBe(2);
  });

  it('Queimado causa o normal com Técnica especial', () => {
    const stats = { hp: 19, atk: 10, def: 9, sp_atk: 10, sp_def: 9, spd: 11 };
    expect(
      damage({
        attacker: { statusSlug: 'burn', stats },
        defender: { stats },
        skill: { category: 'special' },
      }),
    ).toBe(5);
  });

  describe('Fúrias', () => {
    const fury = {
      traitSlug: 'blazing_fury',
      stats: { hp: 21, atk: 10, def: 9, sp_atk: 10, sp_def: 9, spd: 11 },
    };
    const fire = { elementId: FIRE, elementSlug: 'fire' };

    it('vale com o HP exatamente em 1/3', () => {
      expect(damage({ attacker: { ...fury, currentHp: 7 }, skill: fire })).toBe(
        12,
      );
    });

    it('não vale com um HP acima', () => {
      expect(damage({ attacker: { ...fury, currentHp: 8 }, skill: fire })).toBe(
        8,
      );
    });

    it('só vale no Elemento do Traço', () => {
      expect(damage({ attacker: { ...fury, currentHp: 7 } })).toBe(5);
    });

    it.each([
      ['tidal_fury', WATER, 'water'],
      ['rooted_fury', FLORA, 'flora'],
    ])('%s vale no seu Elemento', (traitSlug, elementId, elementSlug) => {
      expect(
        damage({
          attacker: { ...fury, traitSlug, elementIds: [], currentHp: 7 },
          skill: { elementId, elementSlug },
        }),
      ).toBe(8);
    });
  });

  it('Tipo 0 causa 0', () => {
    const catalog = makeCatalog({ '13:3': 0 });
    expect(damage({ catalog })).toBe(0);
  });

  it('o mínimo é 1 quando há efetividade', () => {
    const catalog = makeCatalog({ '13:3': 0.25 });
    const attacker = makeCombatant({ statusSlug: 'burn' });
    expect(damage({ attacker, catalog })).toBe(1);
  });

  it('não altera o que recebe', () => {
    const attacker = makeCombatant();
    const copy = structuredClone(attacker);
    damage({ attacker });
    expect(attacker).toEqual(copy);
  });
});
