import { catalogVersion } from './catalog-version.js';

const tables = () => ({
  elements: [
    { id: 1, slug: 'fire', name: 'Fogo' },
    { id: 2, slug: 'water', name: 'Água' },
  ],
  stats: [{ id: 1, slug: 'hp', name: 'HP' }],
});

describe('catalogVersion', () => {
  it('a mesma entrada dá a mesma versão', () => {
    expect(catalogVersion(tables())).toBe(catalogVersion(tables()));
  });

  it('trocar um valor muda a versão', () => {
    const changed = tables();
    changed.elements[1].name = 'Mar';
    expect(catalogVersion(changed)).not.toBe(catalogVersion(tables()));
  });

  it('as mesmas tabelas em outra ordem de chaves no objeto dão a mesma versão', () => {
    const { elements, stats } = tables();
    expect(catalogVersion({ stats, elements })).toBe(
      catalogVersion({ elements, stats }),
    );
  });

  it('é uma string hex de 64 caracteres', () => {
    expect(catalogVersion(tables())).toMatch(/^[0-9a-f]{64}$/);
  });
});
