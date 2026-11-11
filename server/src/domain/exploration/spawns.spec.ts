import { generateMap, MapTile } from './map-generator.js';
import { seededRandom } from './seeded-random.js';
import { DEFAULT_SPAWN_CONFIG, SpawnConfig } from './spawn-config.js';
import {
  EvolutionLevel,
  naturalLevel,
  rollSpawns,
  spawnWeight,
  SpawnSpecies,
  wildLevel,
} from './spawns.js';

/**
 * Fixa, separada de `DEFAULT_SPAWN_CONFIG`: o dono ajusta os valores do jogo sem
 * reprovar estes testes, que conferem o algoritmo, e não o balanceamento.
 */
const CONFIG: SpawnConfig = {
  count: 500,
  missingLevelFactor: 0.5,
  pullBelow: 0.25,
  pullAbove: 0.75,
  levelSpread: 5,
  unleveledEvolutionGap: 20,
};

const RUVO = 1;
const RUVAK = 2;
const RUVAROTH = 3;
const HUSHLING = 10;
const ECHOFROST = 11;
const EVOLUTIONS: EvolutionLevel[] = [
  { speciesId: RUVO, evolvedSpeciesId: RUVAK, minLevel: 16 },
  { speciesId: RUVAK, evolvedSpeciesId: RUVAROTH, minLevel: 36 },
  { speciesId: HUSHLING, evolvedSpeciesId: ECHOFROST, minLevel: null },
];

const ALWAYS_LOW = () => 0;
const ALWAYS_HIGH = () => 0.999999;

function tiles(biome: MapTile['biome'], count: number, r = 0): MapTile[] {
  return Array.from({ length: count }, (_, q) => ({
    q,
    r,
    biome,
    height: 1,
    variant: 1,
  }));
}

function count<T>(items: T[], matches: (item: T) => boolean): number {
  return items.filter(matches).length;
}

describe('bioma de encontro', () => {
  it('é o próprio bioma, em qualquer altura', () => {
    const spawns = rollSpawns(
      [
        ...tiles('hill', 20, 0).map((tile) => ({ ...tile, height: 0 })),
        ...tiles('wdeep', 20, 1).map((tile) => ({ ...tile, height: 4 })),
      ],
      [
        { speciesId: 1, naturalLevel: 1, rates: { hill: 1 } },
        { speciesId: 2, naturalLevel: 1, rates: { wdeep: 1 } },
      ],
      10,
      seededRandom(5),
      { ...CONFIG, count: 200 },
    );
    expect(spawns.every(({ speciesId, r }) => speciesId === r + 1)).toBe(true);
    expect(new Set(spawns.map(({ speciesId }) => speciesId)).size).toBe(2);
  });
});

describe('naturalLevel', () => {
  it.each([
    ['a base de uma linha', RUVO, 1],
    ['a primeira evolução', RUVAK, 16],
    ['a evolução final', RUVAROTH, 36],
    ['a base da linha por Vínculo', HUSHLING, 1],
    ['uma evolução sem nível mínimo', ECHOFROST, 21],
  ])('%s', (_label, speciesId, expected) => {
    expect(naturalLevel(speciesId, EVOLUTIONS, CONFIG)).toBe(expected);
  });

  it('soma o intervalo sobre o nível natural da espécie anterior', () => {
    const chain: EvolutionLevel[] = [
      ...EVOLUTIONS,
      { speciesId: RUVAK, evolvedSpeciesId: 50, minLevel: null },
    ];
    expect(naturalLevel(50, chain, CONFIG)).toBe(36);
  });

  it('um ciclo de evoluções editado no painel não trava o servidor', () => {
    const cycle: EvolutionLevel[] = [
      { speciesId: 1, evolvedSpeciesId: 2, minLevel: null },
      { speciesId: 2, evolvedSpeciesId: 1, minLevel: null },
    ];
    expect(naturalLevel(1, cycle, CONFIG)).toBeGreaterThanOrEqual(1);
  });
});

describe('spawnWeight', () => {
  it.each([16, 20, 90])('com o time em %i, é a própria taxa', (average) => {
    expect(spawnWeight(40, 16, average, CONFIG)).toBe(40);
  });

  it.each([
    [15, 20],
    [14, 10],
    [10, 0.625],
  ])('com o time em %i, a taxa 40 vira %f', (average, weight) => {
    expect(spawnWeight(40, 16, average, CONFIG)).toBeCloseTo(weight);
  });

  it('funciona com uma média quebrada', () => {
    expect(spawnWeight(40, 16, 15.5, CONFIG)).toBeCloseTo(40 * 0.5 ** 0.5);
  });

  it('nunca chega a zero, por maior que seja a distância', () => {
    expect(spawnWeight(1, 100, 1, CONFIG)).toBeGreaterThan(0);
  });

  it('taxa 0 continua 0', () => {
    expect(spawnWeight(0, 16, 10, CONFIG)).toBe(0);
    expect(spawnWeight(0, 16, 20, CONFIG)).toBe(0);
  });
});

describe('wildLevel', () => {
  it.each([
    ['Ruvak, time 10', 16, 10, 10, 20],
    ['Ruvak, time 20', 16, 20, 14, 24],
    ['Ruvak, time 40', 16, 40, 29, 39],
    ['Ruvo, time 40', 1, 40, 25, 35],
    ['Ruvaroth, time 30', 36, 30, 30, 40],
    ['Ruvaroth, time 40', 36, 40, 34, 44],
  ])('%s', (_label, natural, average, lowest, highest) => {
    expect(wildLevel(natural, average, CONFIG, ALWAYS_LOW)).toBe(lowest);
    expect(wildLevel(natural, average, CONFIG, ALWAYS_HIGH)).toBe(highest);
  });

  it('não fica abaixo de 1: Ruvo com o time 5 vai de 1 a 9', () => {
    expect(wildLevel(1, 5, CONFIG, ALWAYS_LOW)).toBe(1);
    expect(wildLevel(1, 5, CONFIG, ALWAYS_HIGH)).toBe(9);
  });

  it('não passa de 100', () => {
    expect(wildLevel(90, 100, CONFIG, ALWAYS_HIGH)).toBe(100);
  });

  it('todo nível da faixa pode sair', () => {
    const random = seededRandom(1);
    const levels = new Set(
      Array.from({ length: 2000 }, () => wildLevel(16, 10, CONFIG, random)),
    );
    expect([...levels].sort((a, b) => a - b)).toEqual([
      10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
    ]);
  });
});

describe('rollSpawns', () => {
  const ELU: SpawnSpecies = {
    speciesId: 7,
    naturalLevel: 1,
    rates: { boreal: 100, mountain: 5 },
  };
  const NILU: SpawnSpecies = {
    speciesId: 4,
    naturalLevel: 1,
    rates: { wshallow: 100 },
  };

  it('devolve a quantidade da configuração, com ids de 1 em diante', () => {
    const spawns = rollSpawns(
      tiles('boreal', 50),
      [ELU],
      10,
      seededRandom(1),
      CONFIG,
    );
    expect(spawns).toHaveLength(CONFIG.count);
    expect(spawns.map(({ id }) => id)).toEqual(
      Array.from({ length: CONFIG.count }, (_, index) => index + 1),
    );
  });

  it('usa a configuração do jogo quando nenhuma é dada', () => {
    const spawns = rollSpawns(tiles('boreal', 50), [ELU], 10, seededRandom(1));
    expect(spawns).toHaveLength(DEFAULT_SPAWN_CONFIG.count);
  });

  it('todo Ecobeast fica em um hexágono do mapa', () => {
    const map = tiles('boreal', 10, 3);
    const keys = new Set(map.map(({ q, r }) => `${q},${r}`));
    const spawns = rollSpawns(map, [ELU], 10, seededRandom(2), CONFIG);
    expect(spawns.every(({ q, r }) => keys.has(`${q},${r}`))).toBe(true);
  });

  it('o nível sai da regra do selvagem, com o nível natural da espécie', () => {
    const ruvak: SpawnSpecies = {
      speciesId: RUVAK,
      naturalLevel: 16,
      rates: { temperate: 100 },
    };
    const spawns = rollSpawns(
      tiles('temperate', 20),
      [ruvak],
      10,
      seededRandom(3),
      CONFIG,
    );
    expect(spawns.every(({ level }) => level >= 10 && level <= 20)).toBe(true);
    expect(new Set(spawns.map(({ level }) => level)).size).toBe(11);
  });

  it('a chance por hexágono segue a taxa, entre biomas do mesmo tamanho', () => {
    const species: SpawnSpecies = {
      speciesId: 1,
      naturalLevel: 1,
      rates: { temperate: 100, stone: 10 },
    };
    const map = [...tiles('temperate', 100, 0), ...tiles('stone', 100, 1)];
    const spawns = rollSpawns(map, [species], 10, seededRandom(4), {
      ...CONFIG,
      count: 110_000,
    });
    const ratio =
      count(spawns, ({ r }) => r === 0) / count(spawns, ({ r }) => r === 1);
    expect(ratio).toBeGreaterThan(9.5);
    expect(ratio).toBeLessThan(10.5);
  });

  it('um bioma com o dobro de hexágonos recebe o dobro de Ecobeasts', () => {
    const species: SpawnSpecies = {
      speciesId: 1,
      naturalLevel: 1,
      rates: { temperate: 50, stone: 50 },
    };
    const map = [...tiles('temperate', 200, 0), ...tiles('stone', 100, 1)];
    const spawns = rollSpawns(map, [species], 10, seededRandom(5), {
      ...CONFIG,
      count: 60_000,
    });
    const ratio =
      count(spawns, ({ r }) => r === 0) / count(spawns, ({ r }) => r === 1);
    expect(ratio).toBeGreaterThan(1.9);
    expect(ratio).toBeLessThan(2.1);
  });

  it('a mesma espécie aparece na mesma proporção, com ou sem concorrente', () => {
    const elu: SpawnSpecies = {
      speciesId: 1,
      naturalLevel: 1,
      rates: { temperate: 100, stone: 10 },
    };
    const rival: SpawnSpecies = {
      speciesId: 2,
      naturalLevel: 1,
      rates: { stone: 90 },
    };
    const map = [...tiles('temperate', 100, 0), ...tiles('stone', 100, 1)];
    const spawns = rollSpawns(map, [elu, rival], 10, seededRandom(6), {
      ...CONFIG,
      count: 200_000,
    }).filter(({ speciesId }) => speciesId === 1);
    const ratio =
      count(spawns, ({ r }) => r === 0) / count(spawns, ({ r }) => r === 1);
    expect(ratio).toBeGreaterThan(9.5);
    expect(ratio).toBeLessThan(10.5);
  });

  it('dentro do bioma, a espécie sai pela parte dela na soma das taxas', () => {
    const strong: SpawnSpecies = {
      speciesId: 1,
      naturalLevel: 1,
      rates: { boreal: 100 },
    };
    const weak: SpawnSpecies = {
      speciesId: 2,
      naturalLevel: 1,
      rates: { boreal: 50 },
    };
    const spawns = rollSpawns(
      tiles('boreal', 30),
      [strong, weak],
      10,
      seededRandom(7),
      { ...CONFIG, count: 30_000 },
    );
    const share = count(spawns, ({ speciesId }) => speciesId === 1) / 30_000;
    expect(share).toBeGreaterThan(0.65);
    expect(share).toBeLessThan(0.68);
  });

  it('o nível do time abaixo do natural deixa a evolução rara', () => {
    const base: SpawnSpecies = {
      speciesId: RUVO,
      naturalLevel: 1,
      rates: { temperate: 40 },
    };
    const evolved: SpawnSpecies = {
      speciesId: RUVAK,
      naturalLevel: 16,
      rates: { temperate: 40 },
    };
    const share = (average: number) =>
      count(
        rollSpawns(
          tiles('temperate', 30),
          [base, evolved],
          average,
          seededRandom(8),
          { ...CONFIG, count: 64_000 },
        ),
        ({ speciesId }) => speciesId === RUVAK,
      ) / 64_000;
    expect(share(10)).toBeGreaterThan(0.01);
    expect(share(10)).toBeLessThan(0.02);
    expect(share(20)).toBeGreaterThan(0.48);
    expect(share(20)).toBeLessThan(0.52);
  });

  it('dois Ecobeasts podem cair no mesmo hexágono', () => {
    const spawns = rollSpawns(
      tiles('boreal', 5),
      [ELU],
      10,
      seededRandom(9),
      CONFIG,
    );
    expect(new Set(spawns.map(({ q }) => q)).size).toBeLessThan(spawns.length);
  });

  it('ninguém nasce onde não tem taxa', () => {
    const spawns = rollSpawns(
      [...tiles('boreal', 50, 0), ...tiles('wshallow', 50, 1)],
      [ELU, NILU],
      10,
      seededRandom(10),
      CONFIG,
    );
    const inWrongPlace = spawns.filter(
      ({ speciesId, r }) =>
        (speciesId === ELU.speciesId && r === 1) ||
        (speciesId === NILU.speciesId && r === 0),
    );
    expect(inWrongPlace).toEqual([]);
  });

  it('taxa 0 no banco é o mesmo que não ter linha', () => {
    const species: SpawnSpecies = {
      speciesId: 1,
      naturalLevel: 1,
      rates: { temperate: 0, stone: 10 },
    };
    const spawns = rollSpawns(
      [...tiles('temperate', 50, 0), ...tiles('stone', 50, 1)],
      [species],
      10,
      seededRandom(11),
      CONFIG,
    );
    expect(spawns.every(({ r }) => r === 1)).toBe(true);
  });

  it('nenhum Elu nasce na água de um mapa gerado, ilhas à parte', () => {
    const map = generateMap(1234);
    const spawns = rollSpawns(map.tiles, [ELU, NILU], 10, seededRandom(12), {
      ...CONFIG,
      count: 5000,
    });
    const byKey = new Map(
      map.tiles.map((tile) => [`${tile.q},${tile.r}`, tile]),
    );
    const eluBiomes = new Set(
      spawns
        .filter(({ speciesId }) => speciesId === ELU.speciesId)
        .map(({ q, r }) => byKey.get(`${q},${r}`)!.biome),
    );
    expect([...eluBiomes].sort()).toEqual(['boreal', 'mountain']);
  });

  it('sem nenhuma taxa, o mapa nasce vazio', () => {
    const none: SpawnSpecies = { speciesId: 1, naturalLevel: 1, rates: {} };
    expect(
      rollSpawns(tiles('boreal', 5), [none], 10, seededRandom(13), CONFIG),
    ).toEqual([]);
    expect(rollSpawns(tiles('boreal', 5), [], 10, ALWAYS_LOW, CONFIG)).toEqual(
      [],
    );
  });

  it('sem hexágono do bioma da espécie, o mapa nasce vazio', () => {
    expect(
      rollSpawns(tiles('stone', 5), [ELU], 10, seededRandom(14), CONFIG),
    ).toEqual([]);
  });

  it('não altera o que recebe', () => {
    const map = tiles('boreal', 5);
    const copy = structuredClone(map);
    rollSpawns(map, [ELU], 10, seededRandom(15), CONFIG);
    expect(map).toEqual(copy);
  });
});
