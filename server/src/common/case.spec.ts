import { camelToSnakeKeys, snakeToCamelKeys } from './case.js';

describe('conversão de nomes de coluna', () => {
  it('snake_case → camelCase', () => {
    expect(snakeToCamelKeys({ growth_rate_id: 2, slug: 'a' })).toEqual({
      growthRateId: 2,
      slug: 'a',
    });
  });

  it('camelCase → snake_case', () => {
    expect(camelToSnakeKeys({ growthRateId: 2, slug: 'a' })).toEqual({
      growth_rate_id: 2,
      slug: 'a',
    });
  });

  it('mantém a ordem das chaves e os valores, inclusive null', () => {
    const row = {
      evolves_from_species_id: null,
      height_m: 0.5,
      is_hidden: true,
    };
    const camel = snakeToCamelKeys(row);
    expect(Object.keys(camel)).toEqual([
      'evolvesFromSpeciesId',
      'heightM',
      'isHidden',
    ]);
    expect(Object.values(camel)).toEqual([null, 0.5, true]);
  });

  it('ida e volta devolve a linha original', () => {
    const row = {
      attacker_element_id: 1,
      defender_element_id: 3,
      multiplier: 2,
    };
    expect(camelToSnakeKeys(snakeToCamelKeys(row))).toEqual(row);
  });
});
