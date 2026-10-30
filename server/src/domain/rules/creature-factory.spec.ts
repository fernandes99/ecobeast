import {
  createCreature,
  CreateCreatureParams,
  LearnsetEntry,
} from './creature-factory.js';

/** Devolve os valores na ordem; acabar a sequência é erro do teste. */
function sequence(...values: number[]): () => number {
  const queue = [...values];
  return () => {
    const next = queue.shift();
    if (next === undefined) throw new Error('sequência acabou');
    return next;
  };
}

function learned(skillId: number, level: number): LearnsetEntry {
  return { skillId, method: 'level_up', level };
}

const PARAMS: CreateCreatureParams = {
  species: {
    id: 1,
    genderRatio: 0.5,
    baseStats: { hp: 40, atk: 52, def: 43, sp_atk: 60, sp_def: 50, spd: 65 },
  },
  level: 5,
  learnset: [
    learned(1, 1),
    learned(2, 1),
    { skillId: 3, method: 'teachable', level: 1 },
    learned(4, 5),
    learned(5, 6),
  ],
  maxPpBySkill: new Map([
    [1, 35],
    [2, 25],
    [3, 20],
    [4, 15],
    [5, 10],
  ]),
  traitIds: [7, 9],
  temperaments: [
    { id: 10, increasedStat: 'atk', decreasedStat: 'atk' },
    { id: 11, increasedStat: 'atk', decreasedStat: 'def' },
    { id: 12, increasedStat: 'sp_atk', decreasedStat: 'atk' },
    { id: 13, increasedStat: 'spd', decreasedStat: 'sp_def' },
  ],
  xpMultiplier: 1,
};

// 6 Genes, Temperamento, Traço e gênero, nessa ordem.
const DRAWS = [0.5, 0, 0.999, 0.25, 0.75, 0.125, 0.5, 0.6, 0.4];

describe('createCreature', () => {
  it('com uma sequência fixa, cada campo bate com a conta na mão', () => {
    const creature = createCreature(PARAMS, sequence(...DRAWS));

    expect(creature).toEqual({
      speciesId: 1,
      level: 5,
      genes: { hp: 16, atk: 0, def: 31, sp_atk: 8, sp_def: 24, spd: 4 },
      trainingPoints: { hp: 0, atk: 0, def: 0, sp_atk: 0, sp_def: 0, spd: 0 },
      temperamentId: 12,
      traitId: 9,
      gender: 'male',
      skills: [
        { skillId: 1, slot: 1, currentPp: 35 },
        { skillId: 2, slot: 2, currentPp: 25 },
        { skillId: 4, slot: 3, currentPp: 15 },
      ],
      currentXp: 125,
      // Atq.E +10% (11 → 12) e Atq −10% (10 → 9).
      stats: { hp: 19, atk: 9, def: 10, sp_atk: 12, sp_def: 11, spd: 11 },
      currentHp: 19,
      bond: 70,
      isPrismatic: false,
    });
  });

  it('a mesma sequência dá sempre a mesma criatura', () => {
    expect(createCreature(PARAMS, sequence(...DRAWS))).toEqual(
      createCreature(PARAMS, sequence(...DRAWS)),
    );
  });

  it('os Genes vão de 0 a 31', () => {
    const low = createCreature(PARAMS, sequence(0, 0, 0, 0, 0, 0, 0, 0, 0));
    expect(low.genes.hp).toBe(0);
    const high = createCreature(
      PARAMS,
      sequence(0.9999, 0.9999, 0.9999, 0.9999, 0.9999, 0.9999, 0, 0, 0),
    );
    expect(high.genes.hp).toBe(31);
  });

  it('o último Temperamento e o último Traço podem sair', () => {
    const creature = createCreature(
      PARAMS,
      sequence(0, 0, 0, 0, 0, 0, 0.9999, 0.9999, 0),
    );
    expect(creature.temperamentId).toBe(13);
    expect(creature.traitId).toBe(9);
  });

  it('o gênero segue a proporção da espécie', () => {
    const draws = (gender: number) => sequence(0, 0, 0, 0, 0, 0, 0, 0, gender);
    expect(createCreature(PARAMS, draws(0.49)).gender).toBe('male');
    expect(createCreature(PARAMS, draws(0.5)).gender).toBe('female');
  });

  it('espécie sem gênero (proporção negativa) dá none e não sorteia', () => {
    const creature = createCreature(
      { ...PARAMS, species: { ...PARAMS.species, genderRatio: -1 } },
      sequence(0, 0, 0, 0, 0, 0, 0, 0),
    );
    expect(creature.gender).toBe('none');
  });

  it('de um learnset com 6 Técnicas até o nível, ficam as 4 últimas', () => {
    const ids = [1, 2, 3, 4, 5, 6];
    const creature = createCreature(
      {
        ...PARAMS,
        learnset: ids.map((id) => learned(id, id === 6 ? 5 : 1)),
        maxPpBySkill: new Map(ids.map((id) => [id, 10])),
      },
      sequence(...DRAWS),
    );
    expect(creature.skills.map((skill) => skill.skillId)).toEqual([3, 4, 5, 6]);
    expect(creature.skills.map((skill) => skill.slot)).toEqual([1, 2, 3, 4]);
  });

  it('Técnica de outro método ou de nível maior não entra', () => {
    const creature = createCreature(PARAMS, sequence(...DRAWS));
    const ids = creature.skills.map((skill) => skill.skillId);
    expect(ids).not.toContain(3);
    expect(ids).not.toContain(5);
  });

  it('entrada sem nível (ensinável, no banco) não entra', () => {
    const creature = createCreature(
      {
        ...PARAMS,
        learnset: [
          learned(1, 1),
          { skillId: 2, method: 'teachable', level: null },
          { skillId: 4, method: 'level_up', level: null },
        ],
      },
      sequence(...DRAWS),
    );
    expect(creature.skills.map((skill) => skill.skillId)).toEqual([1]);
  });

  it('o XP inicial segue a curva da espécie', () => {
    const creature = createCreature(
      { ...PARAMS, xpMultiplier: 1.25 },
      sequence(...DRAWS),
    );
    expect(creature.currentXp).toBe(156);
  });

  it('o Traço sai só da lista recebida (a dos normais)', () => {
    const creature = createCreature(
      { ...PARAMS, traitIds: [7] },
      sequence(0, 0, 0, 0, 0, 0, 0, 0.9999, 0),
    );
    expect(creature.traitId).toBe(7);
  });

  it('recusa espécie sem Traço normal, com mensagem clara', () => {
    expect(() =>
      createCreature({ ...PARAMS, traitIds: [] }, sequence(...DRAWS)),
    ).toThrow(/Traço normal/);
  });

  it('recusa lista de Temperamentos vazia, com mensagem clara', () => {
    expect(() =>
      createCreature({ ...PARAMS, temperaments: [] }, sequence(...DRAWS)),
    ).toThrow(/Temperamento/);
  });

  it('recusa Técnica aprendida sem PP conhecido, com mensagem clara', () => {
    expect(() =>
      createCreature(
        { ...PARAMS, maxPpBySkill: new Map() },
        sequence(...DRAWS),
      ),
    ).toThrow(/PP/);
  });
});
