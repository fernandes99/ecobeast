import { seededRandom } from '../exploration/seeded-random.js';
import { hexKey } from '../exploration/hex.js';
import { rollAreaSpawns, type SpawnArea, spawnAreas } from './area-spawns.js';
import type { IslandDraft } from './island-draft.js';

const RUVO = 1;
const NILU = 4;
const ELU = 7;

/** 4 hexágonos: dois da área 1 (um deles do Refúgio), um da área 2 e um sem área. */
function island(): IslandDraft {
  return {
    name: 'Ilha',
    start: { q: 0, r: 0 },
    tiles: [
      { q: 0, r: 0, biome: 'temperate', height: 1, variant: 1 },
      { q: 1, r: 0, biome: 'temperate', height: 1, variant: 1, area: 1 },
      { q: 2, r: 0, biome: 'hill', height: 2, variant: 1, area: 1 },
      { q: 0, r: 1, biome: 'wshallow', height: 0, variant: 1, area: 2 },
    ],
    actions: [{ actionTypeId: 1, tiles: [{ q: 2, r: 0 }] }],
    objects: [],
    areas: [
      {
        key: 2,
        name: 'Lago',
        colorHex: '#2255AA',
        spawnCount: 3,
        species: [{ speciesId: NILU, weight: 1, minLevel: 4, maxLevel: 4 }],
      },
      {
        key: 1,
        name: 'Campo',
        colorHex: '#5B8C3A',
        spawnCount: 5,
        species: [{ speciesId: RUVO, weight: 1, minLevel: 2, maxLevel: 6 }],
      },
    ],
  };
}

function area(overrides: Partial<SpawnArea> = {}): SpawnArea {
  return {
    tiles: [{ q: 1, r: 0 }],
    spawnCount: 3,
    species: [{ speciesId: RUVO, weight: 1, minLevel: 2, maxLevel: 6 }],
    ...overrides,
  };
}

describe('spawnAreas', () => {
  it('dá a cada área os hexágonos dela, sem os de ação, na ordem da key', () => {
    const areas = spawnAreas(island());
    expect(areas.map(({ tiles }) => tiles)).toEqual([
      [{ q: 1, r: 0 }],
      [{ q: 0, r: 1 }],
    ]);
    expect(areas.map(({ spawnCount }) => spawnCount)).toEqual([5, 3]);
    expect(areas[0]!.species[0]!.speciesId).toBe(RUVO);
  });

  it('deixa sem hexágonos a área que só tem ação', () => {
    const draft = island();
    draft.actions[0]!.tiles.push({ q: 1, r: 0 });
    expect(spawnAreas(draft)[0]!.tiles).toEqual([]);
  });

  it('tira os hexágonos bloqueados, e não os de objeto livre', () => {
    const draft = island();
    draft.objects.push({
      objectTypeId: 1,
      q: 1,
      r: 0,
      variant: 1,
      mirrored: false,
      tiles: [
        { q: 1, r: 0, blocks: true },
        { q: 0, r: 1, blocks: false },
      ],
    });
    expect(spawnAreas(draft).map(({ tiles }) => tiles)).toEqual([
      [],
      [{ q: 0, r: 1 }],
    ]);
  });
});

describe('rollAreaSpawns', () => {
  it('sorteia a quantidade de cada área, cada um num hexágono dela', () => {
    const draft = island();
    const areas = spawnAreas(draft);
    const spawns = rollAreaSpawns(areas, seededRandom(7));
    expect(spawns).toHaveLength(8);
    const field = spawns.filter((spawn) => spawn.speciesId === RUVO);
    const lake = spawns.filter((spawn) => spawn.speciesId === NILU);
    expect(field).toHaveLength(5);
    expect(lake).toHaveLength(3);
    for (const spawn of field)
      expect(hexKey(spawn)).toBe(hexKey({ q: 1, r: 0 }));
    for (const spawn of lake)
      expect(hexKey(spawn)).toBe(hexKey({ q: 0, r: 1 }));
  });

  it('numera os Ecobeasts de 1 em diante', () => {
    const spawns = rollAreaSpawns(spawnAreas(island()), seededRandom(3));
    expect(spawns.map(({ id }) => id)).toEqual([1, 2, 3, 4, 5, 6, 7, 8]);
  });

  it('nunca põe um Ecobeast em construção nem fora das áreas', () => {
    const allowed = new Set(['1,0', '0,1'].map((key) => key));
    const spawns = rollAreaSpawns(spawnAreas(island()), seededRandom(11));
    for (const spawn of spawns) {
      expect(allowed.has(`${spawn.q},${spawn.r}`)).toBe(true);
    }
  });

  it('não sorteia na área sem espécie nem na área sem hexágonos', () => {
    expect(rollAreaSpawns([area({ species: [] })], seededRandom(1))).toEqual(
      [],
    );
    expect(rollAreaSpawns([area({ tiles: [] })], seededRandom(1))).toEqual([]);
  });

  it('usa o nível mínimo e o máximo, com os dois inclusos', () => {
    const low = rollAreaSpawns([area({ spawnCount: 1 })], () => 0);
    expect(low[0]!.level).toBe(2);
    const high = rollAreaSpawns([area({ spawnCount: 1 })], () => 0.999_999);
    expect(high[0]!.level).toBe(6);
    const levels = new Set(
      rollAreaSpawns([area({ spawnCount: 200 })], seededRandom(5)).map(
        ({ level }) => level,
      ),
    );
    expect([...levels].sort()).toEqual([2, 3, 4, 5, 6]);
  });

  it('sorteia a espécie pelo peso', () => {
    const spawns = rollAreaSpawns(
      [
        area({
          spawnCount: 200,
          species: [
            { speciesId: RUVO, weight: 9, minLevel: 2, maxLevel: 2 },
            { speciesId: ELU, weight: 1, minLevel: 2, maxLevel: 2 },
          ],
        }),
      ],
      seededRandom(9),
    );
    const elu = spawns.filter(({ speciesId }) => speciesId === ELU).length;
    expect(elu).toBeGreaterThan(5);
    expect(elu).toBeLessThan(45);
  });

  it('espalha os Ecobeasts pelos hexágonos da área', () => {
    const tiles = [
      { q: 0, r: 0 },
      { q: 1, r: 0 },
      { q: 2, r: 0 },
    ];
    const used = new Set(
      rollAreaSpawns([area({ tiles, spawnCount: 60 })], seededRandom(2)).map(
        hexKey,
      ),
    );
    expect(used.size).toBe(3);
  });
});
