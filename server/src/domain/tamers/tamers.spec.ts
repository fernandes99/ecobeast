import { hexDistance, hexKey, type HexCoord } from '../exploration/hex.js';
import { generateMap, type MapTile } from '../exploration/map-generator.js';
import { seededRandom } from '../exploration/seeded-random.js';
import type { SpawnConfig } from '../exploration/spawn-config.js';
import type { SpawnSpecies } from '../exploration/spawns.js';
import type { TamerConfig } from './tamer-config.js';
import { rollChallenger, rollMapTamers, type TamerTexts } from './tamers.js';

/**
 * Fixas, separadas das do jogo: o dono ajusta `TAMER_CONFIG` e
 * `DEFAULT_SPAWN_CONFIG` sem reprovar estes testes, que conferem o algoritmo.
 */
const CONFIG: TamerConfig = {
  count: 25,
  minStartDistance: 3,
  sizeWeights: { 1: 1, 2: 1, 3: 1 },
};
const SPAWN: SpawnConfig = {
  count: 500,
  missingLevelFactor: 0.5,
  pullBelow: 0.25,
  pullAbove: 0.75,
  levelSpread: 5,
  unleveledEvolutionGap: 20,
};
const OPTIONS = { config: CONFIG, spawnConfig: SPAWN };
const TEXTS: TamerTexts = { nameIds: [1, 2, 3], greetingIds: [1, 2] };

const RUVO = 1;
const NILU = 4;
const ELU = 7;
const SPECIES: SpawnSpecies[] = [
  { speciesId: RUVO, naturalLevel: 1, rates: { temperate: 60, hill: 50 } },
  { speciesId: NILU, naturalLevel: 1, rates: { wshallow: 100, wdeep: 30 } },
  { speciesId: ELU, naturalLevel: 1, rates: { boreal: 100, temperate: 50 } },
];
const START: HexCoord = { q: 0, r: 0 };

function line(
  biome: MapTile['biome'],
  count: number,
  {
    shape = 'flat',
    r = 0,
    from = 0,
  }: Partial<MapTile> & { from?: number } = {},
): MapTile[] {
  return Array.from({ length: count }, (_, index) => ({
    q: from + index,
    r,
    biome,
    shape,
    variant: 1,
  }));
}

describe('rollMapTamers', () => {
  it('nunca põe Domador na água, perto da largada ou dividindo hexágono', () => {
    for (let seed = 1; seed <= 20; seed++) {
      const map = generateMap(seed);
      const water = new Set(
        map.tiles
          .filter(({ biome }) => biome === 'wshallow' || biome === 'wdeep')
          .map(hexKey),
      );
      const tamers = rollMapTamers(
        map.tiles,
        map.start,
        SPECIES,
        10,
        TEXTS,
        seededRandom(seed),
        OPTIONS,
      );
      expect(tamers.length).toBe(CONFIG.count);
      const keys = tamers.map(hexKey);
      expect(new Set(keys).size).toBe(keys.length);
      for (const tamer of tamers) {
        expect(water.has(hexKey(tamer))).toBe(false);
        expect(hexDistance(tamer, map.start)).toBeGreaterThan(
          CONFIG.minStartDistance,
        );
        expect(tamer.team).toHaveLength(tamer.size);
      }
    }
  });

  it('numera os Domadores de 1 em diante, sem repetir', () => {
    const tamers = rollMapTamers(
      line('temperate', 60, { from: 10 }),
      START,
      SPECIES,
      10,
      TEXTS,
      seededRandom(7),
      OPTIONS,
    );
    expect(tamers.map(({ id }) => id)).toEqual(
      Array.from({ length: CONFIG.count }, (_, index) => index + 1),
    );
  });

  it('sorteia o tamanho pelos pesos', () => {
    const tamers = rollMapTamers(
      line('temperate', 60, { from: 10 }),
      START,
      SPECIES,
      10,
      TEXTS,
      seededRandom(3),
      { ...OPTIONS, config: { ...CONFIG, sizeWeights: { 1: 0, 2: 0, 3: 1 } } },
    );
    expect(
      tamers.every(({ size, team }) => size === 3 && team.length === 3),
    ).toBe(true);
  });

  it('num hexágono de colina, só usa espécies com taxa em colina', () => {
    const tamers = rollMapTamers(
      line('boreal', 60, { shape: 'hill', from: 10 }),
      START,
      SPECIES,
      10,
      TEXTS,
      seededRandom(11),
      OPTIONS,
    );
    const species = tamers.flatMap(({ team }) =>
      team.map(({ speciesId }) => speciesId),
    );
    expect(species.length).toBeGreaterThan(0);
    expect(species.every((id) => id === RUVO)).toBe(true);
  });

  it('o nível sai do wildLevel: centro puxado pela média e 5 para cada lado', () => {
    // Nível natural 1 e média 20: centro 1 + 19 × 0,75 = 15, de 10 a 20.
    const tamers = rollMapTamers(
      line('temperate', 60, { from: 10 }),
      START,
      SPECIES,
      20,
      TEXTS,
      seededRandom(5),
      OPTIONS,
    );
    const levels = tamers.flatMap(({ team }) => team.map(({ level }) => level));
    expect(Math.min(...levels)).toBeGreaterThanOrEqual(10);
    expect(Math.max(...levels)).toBeLessThanOrEqual(20);
  });

  it('escolhe nome e fala entre os ids do catálogo', () => {
    const tamers = rollMapTamers(
      line('temperate', 60, { from: 10 }),
      START,
      SPECIES,
      10,
      TEXTS,
      seededRandom(9),
      OPTIONS,
    );
    for (const { nameId, greetingId } of tamers) {
      expect(TEXTS.nameIds).toContain(nameId);
      expect(TEXTS.greetingIds).toContain(greetingId);
    }
  });

  it('sem hexágonos possíveis para todos, devolve os que couberam', () => {
    // 4 a 7 estão longe da largada; 0 a 3 estão perto; o resto é água.
    const tiles = [...line('temperate', 8), ...line('wdeep', 20, { r: 1 })];
    const tamers = rollMapTamers(
      tiles,
      START,
      SPECIES,
      10,
      TEXTS,
      seededRandom(2),
      OPTIONS,
    );
    expect(tamers.map(({ q }) => q).sort((a, b) => a - b)).toEqual([
      4, 5, 6, 7,
    ]);
  });

  it('não usa um bioma sem nenhuma espécie com peso', () => {
    const tiles = [
      ...line('stone', 30, { from: 10 }),
      ...line('temperate', 2, { from: 10, r: 1 }),
    ];
    const tamers = rollMapTamers(
      tiles,
      START,
      SPECIES,
      10,
      TEXTS,
      seededRandom(4),
      OPTIONS,
    );
    expect(tamers.every(({ r }) => r === 1)).toBe(true);
    expect(tamers).toHaveLength(2);
  });

  it('sem espécies, sem nomes ou sem falas, não nasce nenhum', () => {
    const tiles = line('temperate', 60, { from: 10 });
    const roll = (species: SpawnSpecies[], texts: TamerTexts) =>
      rollMapTamers(tiles, START, species, 10, texts, seededRandom(1), OPTIONS);
    expect(roll([], TEXTS)).toEqual([]);
    expect(roll(SPECIES, { ...TEXTS, nameIds: [] })).toEqual([]);
    expect(roll(SPECIES, { ...TEXTS, greetingIds: [] })).toEqual([]);
  });
});

describe('rollChallenger', () => {
  it('soma as taxas de todos os biomas: até quem só vive na água aparece', () => {
    const species = new Set<number>();
    for (let seed = 1; seed <= 100; seed++) {
      const tamer = rollChallenger(SPECIES, 10, TEXTS, seededRandom(seed), {
        ...OPTIONS,
        size: 3,
      })!;
      expect(tamer.id).toBe(0);
      expect(tamer.size).toBe(3);
      expect(tamer.team).toHaveLength(3);
      for (const { speciesId } of tamer.team) species.add(speciesId);
    }
    expect([...species].sort((a, b) => a - b)).toEqual([RUVO, NILU, ELU]);
  });

  it('sem tamanho pedido, sorteia pelos pesos', () => {
    const tamer = rollChallenger(SPECIES, 10, TEXTS, seededRandom(1), {
      ...OPTIONS,
      config: { ...CONFIG, sizeWeights: { 1: 0, 2: 1, 3: 0 } },
    })!;
    expect(tamer.size).toBe(2);
    expect(tamer.team).toHaveLength(2);
  });

  it('sem nenhuma espécie com peso, ou sem textos, não há desafiante', () => {
    const none: SpawnSpecies[] = [
      { speciesId: RUVO, naturalLevel: 1, rates: { temperate: 0 } },
    ];
    const random = seededRandom(1);
    expect(rollChallenger(none, 10, TEXTS, random, OPTIONS)).toBeNull();
    expect(
      rollChallenger(SPECIES, 10, { ...TEXTS, nameIds: [] }, random, OPTIONS),
    ).toBeNull();
  });
});
