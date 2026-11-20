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
    expect(evolutionOffer(RUVO, 15, 16, rules, 'day')).toBe(RUVAK);
  });

  it('oferece de novo a quem já passou do nível e subiu outra vez', () => {
    expect(evolutionOffer(RUVO, 17, 18, rules, 'day')).toBe(RUVAK);
  });

  it('não oferece abaixo do nível mínimo', () => {
    expect(evolutionOffer(RUVO, 14, 15, rules, 'day')).toBeNull();
  });

  it('não oferece sem subir de nível', () => {
    expect(evolutionOffer(RUVO, 20, 20, rules, 'day')).toBeNull();
  });

  it('só olha o gatilho de nível', () => {
    expect(evolutionOffer(7, 1, 50, rules, 'day')).toBeNull();
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
    expect(evolutionOffer(RUVO, 15, 16, twoWays, 'day')).toBe(RUVAK);
  });

  describe('por horário', () => {
    const MANTORN = 26;
    const branched: EvolutionRule[] = [
      {
        id: 58,
        speciesId: MANTORN,
        evolvedSpeciesId: 27,
        trigger: 'time_of_day',
        minLevel: 36,
        timeOfDay: 'day',
      },
      {
        id: 59,
        speciesId: MANTORN,
        evolvedSpeciesId: 28,
        trigger: 'time_of_day',
        minLevel: 36,
        timeOfDay: 'night',
      },
    ];

    it('de dia, oferece a regra do dia', () => {
      expect(evolutionOffer(MANTORN, 35, 36, branched, 'day')).toBe(27);
    });

    it('à noite, oferece a regra da noite', () => {
      expect(evolutionOffer(MANTORN, 35, 36, branched, 'night')).toBe(28);
    });

    it('não oferece abaixo do nível mínimo', () => {
      expect(evolutionOffer(MANTORN, 34, 35, branched, 'day')).toBeNull();
    });

    it('sem nível mínimo, vale em qualquer nível', () => {
      const anyLevel: EvolutionRule[] = [
        { ...branched[1]!, minLevel: null },
      ];
      expect(evolutionOffer(MANTORN, 1, 2, anyLevel, 'night')).toBe(28);
      expect(evolutionOffer(MANTORN, 1, 2, anyLevel, 'day')).toBeNull();
    });

    it('com a regra de nível e a de horário, vale a de menor id', () => {
      const mixed: EvolutionRule[] = [
        ...branched,
        {
          id: 60,
          speciesId: MANTORN,
          evolvedSpeciesId: 99,
          trigger: 'level',
          minLevel: 30,
        },
      ];
      expect(evolutionOffer(MANTORN, 35, 36, mixed, 'night')).toBe(28);
    });
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
