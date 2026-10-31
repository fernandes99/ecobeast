import { rollEncounter } from './encounter.js';
import { sequence } from './testing.js';

const SPECIES = [1, 4, 7];

describe('rollEncounter', () => {
  it('com o sorteio 0, sai a primeira espécie e o nível menos 2', () => {
    expect(rollEncounter(SPECIES, 10, sequence(0, 0))).toEqual({
      speciesId: 1,
      level: 8,
    });
  });

  it('com o sorteio 0,99, sai a última espécie e o nível mais 1', () => {
    expect(rollEncounter(SPECIES, 10, sequence(0.99, 0.99))).toEqual({
      speciesId: 7,
      level: 11,
    });
  });

  it('sorteia a espécie primeiro e o nível depois', () => {
    expect(rollEncounter(SPECIES, 10, sequence(0.5, 0))).toEqual({
      speciesId: 4,
      level: 8,
    });
  });

  it.each([
    [0, 8],
    [0.25, 9],
    [0.5, 10],
    [0.75, 11],
  ])('o sorteio de nível %f dá %i', (roll, level) => {
    expect(rollEncounter(SPECIES, 10, sequence(0, roll)).level).toBe(level);
  });

  it('o nível não fica abaixo de 1', () => {
    expect(rollEncounter(SPECIES, 1, sequence(0, 0)).level).toBe(1);
  });

  it('o nível não passa de 100', () => {
    expect(rollEncounter(SPECIES, 100, sequence(0, 0.99)).level).toBe(100);
  });

  it('não altera a lista recebida', () => {
    const species = [...SPECIES];
    rollEncounter(species, 10, sequence(0, 0));
    expect(species).toEqual(SPECIES);
  });
});
