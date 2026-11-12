import { Controller, Get, Inject, Param, Query, Type } from '@nestjs/common';
import { ApiProperty, ApiTags } from '@nestjs/swagger';
import { ApiDetailRoute, ApiListRoute } from '../common/api-docs.js';
import { notFound, parseIdOrSlug } from '../common/id-or-slug.js';
import { page, Page, PaginationQueryDto } from '../common/pagination.js';
import { ref, ResourceRef } from '../common/resource-ref.js';
import { PrismaService } from '../prisma/prisma.service.js';

export interface NamedRow {
  id: number;
  slug: string;
  name: string;
}

interface ResourceDelegate {
  count(): Promise<number>;
  findMany(args: object): Promise<NamedRow[]>;
  findUnique(args: object): Promise<NamedRow | null>;
}

export interface ResourceDefinition<Row extends NamedRow, Dto> {
  path: string;
  model: string;
  tag: string;
  notFound: string;
  list: { summary: string; description: string };
  detail: { summary: string; description: string; example: string };
  dto: Type<Dto>;
  include?: object;
  toDto(row: Row): Dto;
}

export function resourceController<Row extends NamedRow, Dto>(
  def: ResourceDefinition<Row, Dto>,
): Type<unknown> {
  @ApiTags(def.tag)
  @Controller(def.path)
  class ResourceController {
    constructor(
      @Inject(PrismaService) private readonly prisma: PrismaService,
    ) {}

    private get delegate(): ResourceDelegate {
      return (this.prisma as unknown as Record<string, ResourceDelegate>)[
        def.model
      ];
    }

    @Get()
    @ApiListRoute(def.list.summary, def.list.description)
    async list(@Query() query: PaginationQueryDto): Promise<Page<ResourceRef>> {
      const [total, rows] = await Promise.all([
        this.delegate.count(),
        this.delegate.findMany({
          select: { id: true, slug: true, name: true },
          orderBy: { id: 'asc' },
          skip: query.offset,
          take: query.limit,
        }),
      ]);
      return page(
        `/v1/${def.path}`,
        total,
        query,
        rows.map((row) => ref(def.path, row)),
      );
    }

    @Get(':idOrSlug')
    @ApiDetailRoute(
      def.detail.summary,
      def.detail.description,
      () => def.dto,
      def.detail.example,
    )
    async detail(@Param('idOrSlug') idOrSlug: string): Promise<Dto> {
      const row = await this.delegate.findUnique({
        where: parseIdOrSlug(idOrSlug),
        include: def.include,
      });
      if (!row) throw notFound(def.notFound, idOrSlug);
      return def.toDto(row as Row);
    }
  }
  Object.defineProperty(ResourceController, 'name', {
    value: `${def.model}ResourceController`,
  });
  return ResourceController;
}

export class NamedResourceDto {
  @ApiProperty({ example: 1 })
  id: number;

  @ApiProperty({ example: 'physical' })
  slug: string;

  @ApiProperty({ example: 'Física' })
  name: string;
}

export const named = (row: NamedRow): NamedResourceDto => ({
  id: row.id,
  slug: row.slug,
  name: row.name,
});
