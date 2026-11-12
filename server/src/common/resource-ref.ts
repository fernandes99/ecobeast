import { ApiProperty } from '@nestjs/swagger';

export class ResourceRef {
  @ApiProperty({ example: 1 })
  id: number;

  @ApiProperty({ example: 'ruvo' })
  slug: string;

  @ApiProperty({ example: 'Ruvo' })
  name: string;

  @ApiProperty({
    description: 'Caminho do recurso a partir da raiz da API.',
    example: '/v1/species/1',
  })
  url: string;
}

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
