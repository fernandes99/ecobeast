import { parseIdOrSlug } from './id-or-slug.js';

describe('parseIdOrSlug', () => {
  it('só dígitos é id', () => {
    expect(parseIdOrSlug('1')).toEqual({ id: 1 });
  });

  it('o resto é slug', () => {
    expect(parseIdOrSlug('fagulho')).toEqual({ slug: 'fagulho' });
    expect(parseIdOrSlug('1a')).toEqual({ slug: '1a' });
  });

  it('slug vai para minúsculas', () => {
    expect(parseIdOrSlug('FAGULHO')).toEqual({ slug: 'fagulho' });
  });

  it('id maior que um inteiro do banco não vira id (dá 404, e não erro 500)', () => {
    expect(parseIdOrSlug('99999999999')).toEqual({ slug: '99999999999' });
  });
});
