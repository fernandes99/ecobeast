import { geneRank, genesTotal } from './genes.js';

describe('genesTotal', () => {
  it('soma os 6 Genes', () => {
    expect(
      genesTotal({ hp: 24, atk: 31, def: 18, sp_atk: 26, sp_def: 20, spd: 14 }),
    ).toBe(133);
  });

  it('vai de 0 a 186', () => {
    const zero = { hp: 0, atk: 0, def: 0, sp_atk: 0, sp_def: 0, spd: 0 };
    const max = { hp: 31, atk: 31, def: 31, sp_atk: 31, sp_def: 31, spd: 31 };
    expect(genesTotal(zero)).toBe(0);
    expect(genesTotal(max)).toBe(186);
  });
});

describe('geneRank', () => {
  it.each([
    [0, 'common', 'Comum'],
    [109, 'common', 'Comum'],
    [110, 'uncommon', 'Incomum'],
    [129, 'uncommon', 'Incomum'],
    [130, 'rare', 'Raro'],
    [144, 'rare', 'Raro'],
    [145, 'epic', 'Épico'],
    [159, 'epic', 'Épico'],
    [160, 'exceptional', 'Excepcional'],
    [186, 'exceptional', 'Excepcional'],
  ])('%i é %s', (total, slug, name) => {
    expect(geneRank(total)).toEqual({ slug, name });
  });
});
