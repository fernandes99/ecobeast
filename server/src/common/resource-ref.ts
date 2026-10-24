import { ApiProperty } from '@nestjs/swagger';

/** Referência curta a outro recurso, como na PokeAPI (RF-03). */
export class ResourceRef {
  @ApiProperty({ example: 1 })
  id: number;

  @ApiProperty({ example: 'fagulho' })
  slug: string;

  @ApiProperty({ example: 'Fagulho' })
  name: string;

  @ApiProperty({
    description: 'Caminho do recurso a partir da raiz da API.',
    example: '/v1/species/1',
  })
  url: string;
}

/** `ref('elements', fogo)` → `{ id: 1, slug: 'fire', name: 'Fogo', url: '/v1/elements/1' }`. */
export function ref(
  resource: string,
  row: { id: number; slug: string; name: string },
): ResourceRef {
  return {
    id: row.id,
    slug: row.slug,
    name: row.name,
    url: `/v1/${resource}/${row.id}`,
  };
}
