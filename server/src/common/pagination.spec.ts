import { plainToInstance } from 'class-transformer';
import { validateSync } from 'class-validator';
import { page, PaginationQueryDto } from './pagination.js';

const query = (limit: number, offset: number) =>
  Object.assign(new PaginationQueryDto(), { limit, offset });

describe('page', () => {
  const results = ['a', 'b'];

  it('meio da lista: next e previous apontam para as páginas vizinhas', () => {
    expect(page('/v1/species', 9, query(2, 2), results)).toEqual({
      count: 9,
      next: '/v1/species?limit=2&offset=4',
      previous: '/v1/species?limit=2&offset=0',
      results,
    });
  });

  it('última página: next null', () => {
    expect(page('/v1/species', 9, query(2, 8), ['i']).next).toBeNull();
  });

  it('primeira página: previous null', () => {
    expect(page('/v1/species', 9, query(2, 0), results).previous).toBeNull();
  });

  it('offset além do total: results vazio, previous na página anterior', () => {
    expect(page('/v1/species', 9, query(2, 20), [])).toEqual({
      count: 9,
      next: null,
      previous: '/v1/species?limit=2&offset=18',
      results: [],
    });
  });

  it('previous nunca fica negativo', () => {
    expect(page('/v1/species', 9, query(5, 3), results).previous).toBe(
      '/v1/species?limit=5&offset=0',
    );
  });
});

describe('PaginationQueryDto', () => {
  const errors = (raw: Record<string, unknown>) =>
    validateSync(plainToInstance(PaginationQueryDto, raw)).flatMap((error) =>
      Object.values(error.constraints ?? {}),
    );

  it('padrões: limit 20 e offset 0', () => {
    const dto = plainToInstance(PaginationQueryDto, {});
    expect(dto.limit).toBe(20);
    expect(dto.offset).toBe(0);
    expect(errors({})).toEqual([]);
  });

  it('converte texto em número', () => {
    const dto = plainToInstance(PaginationQueryDto, {
      limit: '5',
      offset: '10',
    });
    expect(dto.limit).toBe(5);
    expect(dto.offset).toBe(10);
  });

  it.each(['0', '101', 'abc', '2.5'])(
    'recusa limit=%s com a mensagem em pt-BR',
    (limit) => {
      expect(errors({ limit })).toContain(
        'limit deve ser um inteiro de 1 a 100',
      );
    },
  );

  it.each(['-1', 'abc'])(
    'recusa offset=%s com a mensagem em pt-BR',
    (offset) => {
      expect(errors({ offset })).toContain(
        'offset deve ser um inteiro maior ou igual a 0',
      );
    },
  );
});
