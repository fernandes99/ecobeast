import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, Max, Min } from 'class-validator';
import { ResourceRef } from './resource-ref.js';

const LIMIT_MESSAGE = 'limit deve ser um inteiro de 1 a 100';
const OFFSET_MESSAGE = 'offset deve ser um inteiro maior ou igual a 0';

export class PaginationQueryDto {
  @ApiPropertyOptional({
    description: 'Quantos itens por página (1 a 100).',
    default: 20,
    minimum: 1,
    maximum: 100,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt({ message: LIMIT_MESSAGE })
  @Min(1, { message: LIMIT_MESSAGE })
  @Max(100, { message: LIMIT_MESSAGE })
  limit: number = 20;

  @ApiPropertyOptional({
    description: 'Quantos itens pular desde o começo.',
    default: 0,
    minimum: 0,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt({ message: OFFSET_MESSAGE })
  @Min(0, { message: OFFSET_MESSAGE })
  offset: number = 0;
}

export interface Page<T> {
  count: number;
  next: string | null;
  previous: string | null;
  results: T[];
}

export class ResourceRefPage implements Page<ResourceRef> {
  @ApiProperty({ description: 'Total de itens.', example: 9 })
  count: number;

  @ApiProperty({
    description: 'Caminho da página seguinte.',
    example: '/v1/species?limit=20&offset=20',
    nullable: true,
    type: String,
  })
  next: string | null;

  @ApiProperty({
    description: 'Caminho da página anterior.',
    example: null,
    nullable: true,
    type: String,
  })
  previous: string | null;

  @ApiProperty({ type: () => [ResourceRef] })
  results: ResourceRef[];
}

export function page<T>(
  path: string,
  total: number,
  query: PaginationQueryDto,
  results: T[],
): Page<T> {
  const { limit, offset } = query;
  const at = (start: number) => `${path}?limit=${limit}&offset=${start}`;
  return {
    count: total,
    next: offset + limit < total ? at(offset + limit) : null,
    previous: offset > 0 ? at(Math.max(offset - limit, 0)) : null,
    results,
  };
}
