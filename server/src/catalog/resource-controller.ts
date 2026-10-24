import { Controller, Get, Inject, Param, Query, Type } from '@nestjs/common';
import { ApiProperty, ApiTags } from '@nestjs/swagger';
import { ApiDetailRoute, ApiListRoute } from '../common/api-docs.js';
import { notFound, parseIdOrSlug } from '../common/id-or-slug.js';
import { page, Page, PaginationQueryDto } from '../common/pagination.js';
import { ref, ResourceRef } from '../common/resource-ref.js';
import { PrismaService } from '../prisma/prisma.service.js';

/** Linha com o mínimo de um recurso do catálogo. */
export interface NamedRow {
  id: number;
  slug: string;
  name: string;
}

/** O pedaço de um delegate do Prisma que as rotas de recurso usam. */
interface ResourceDelegate {
  count(): Promise<number>;
  findMany(args: object): Promise<NamedRow[]>;
  findUnique(args: object): Promise<NamedRow | null>;
}

/** Um recurso do catálogo com lista paginada e detalhe por id ou slug. */
export interface ResourceDefinition<Row extends NamedRow, Dto> {
  /** Caminho sob /v1 (ex.: 'skill-categories'). */
  path: string;
  /** Delegate do Prisma (ex.: 'skillCategory'). */
  model: string;
  /** Tag da Scalar (ex.: 'Categorias de Técnica'). */
  tag: string;
  /** Início da mensagem de 404 (ex.: 'Categoria de Técnica não encontrada'). */
  notFound: string;
  list: { summary: string; description: string };
  detail: { summary: string; description: string; example: string };
  dto: Type<Dto>;
  /** O `include` do Prisma para o detalhe. */
  include?: object;
  toDto(row: Row): Dto;
}

/**
 * Monta o controller de um recurso do catálogo (.specs/backend-api/05-catalog-api.md,
 * RF-01 e RF-05): GET /v1/<path> e GET /v1/<path>/{idOrSlug}, com a mesma
 * paginação, referências e erros das espécies.
 */
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

/** Recurso que só tem id, slug e nome. */
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
