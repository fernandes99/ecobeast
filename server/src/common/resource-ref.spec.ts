import { ref } from './resource-ref.js';

describe('ref', () => {
  it('monta id, slug, name e o caminho do recurso, ignorando outras colunas', () => {
    const row = { id: 1, slug: 'fire', name: 'Fogo', colorHex: '#E25822' };
    expect(ref('elements', row)).toEqual({
      id: 1,
      slug: 'fire',
      name: 'Fogo',
      url: '/v1/elements/1',
    });
  });
});
