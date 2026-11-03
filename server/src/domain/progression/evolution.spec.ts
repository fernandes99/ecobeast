import {
  type EvolutionRule,
  evolutionOffer,
  evolvedTraitId,
  type SpeciesTraitRow,
} from './evolution.js';

const RUVO = 1;
const RUVAK = 2;

const rules: EvolutionRule[] = [
  {
    id: 1,
    speciesId: RUVO,
    evolvedSpeciesId: RUVAK,
    trigger: 'level',
    minLevel: 16,
  },
  {
    id: 2,
    speciesId: RUVAK,
    evolvedSpeciesId: 3,
    trigger: 'level',
    minLevel: 36,
  },
  { id: 3, speciesId: 7, evolvedSpeciesId: 8, trigger: 'item', minLevel: null },
];

describe('evolutionOffer', () => {
  it('oferece ao chegar ao nível mínimo', () => {
    expect(evolutionOffer(RUVO, 15, 16, rules)).toBe(RUVAK);
  });

  it('oferece de novo a quem já passou do nível e subiu outra vez', () => {
    expect(evolutionOffer(RUVO, 17, 18, rules)).toBe(RUVAK);
  });

  it('não oferece abaixo do nível mínimo', () => {
    expect(evolutionOffer(RUVO, 14, 15, rules)).toBeNull();
  });

  it('não oferece sem subir de nível', () => {
    expect(evolutionOffer(RUVO, 20, 20, rules)).toBeNull();
  });

  it('só olha o gatilho de nível', () => {
    expect(evolutionOffer(7, 1, 50, rules)).toBeNull();
  });

  it('com duas regras, vale a de menor id', () => {
    const twoWays: EvolutionRule[] = [
      {
        id: 9,
        speciesId: RUVO,
        evolvedSpeciesId: 5,
        trigger: 'level',
        minLevel: 10,
      },
      ...rules,
    ];
    expect(evolutionOffer(RUVO, 15, 16, twoWays)).toBe(RUVAK);
  });
});

describe('evolvedTraitId', () => {
  const ruvo: SpeciesTraitRow[] = [
    { traitId: 10, slot: 1, isHidden: false },
    { traitId: 11, slot: 2, isHidden: false },
    { traitId: 12, slot: 3, isHidden: true },
  ];
  const ruvak: SpeciesTraitRow[] = [
    { traitId: 20, slot: 1, isHidden: false },
    { traitId: 21, slot: 2, isHidden: false },
    { traitId: 22, slot: 3, isHidden: true },
  ];

  it('vai para o mesmo slot da espécie nova', () => {
    expect(evolvedTraitId(11, ruvo, ruvak)).toBe(21);
    expect(evolvedTraitId(12, ruvo, ruvak)).toBe(22);
  });

  it('sem o slot equivalente, vai para o de slot 1 não oculto', () => {
    expect(evolvedTraitId(11, ruvo, [ruvak[0]!])).toBe(20);
  });

  it('sem o slot equivalente nem o slot 1, vai para o primeiro não oculto', () => {
    const onlySlot2 = [{ traitId: 30, slot: 2, isHidden: false }];
    expect(evolvedTraitId(12, ruvo, onlySlot2)).toBe(30);
  });

  it('sem Traço nenhum na espécie nova, mantém o atual', () => {
    expect(evolvedTraitId(10, ruvo, [])).toBe(10);
  });
});
