import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  draftError,
  draftHash,
  type IslandDraft,
  type KnownIds,
  publishError,
} from '../domain/islands/island-draft.js';
import type { Prisma } from '../generated/prisma/client.js';
import { ISLAND_NOT_FOUND, IslandsService } from '../islands/islands.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import type {
  IslandCreatedResponseDto,
  IslandDraftDto,
  IslandDraftResponseDto,
  IslandListResponseDto,
  IslandPublishedResponseDto,
  IslandSavedResponseDto,
  IslandStatus,
} from './islands-editor.dto.js';

export const PUBLISHED_CANNOT_BE_DELETED =
  'Uma ilha publicada não pode ser apagada.';

const DRAFT = 'draft';
const PUBLISHED = 'published';
/** O maior id que cabe numa coluna `int` do Postgres. */
const MAX_ID = 2_147_483_647;
/** Hexágonos por INSERT: 7 colunas cada, longe do limite de parâmetros do Postgres. */
const TILE_CHUNK = 5_000;
/** Uma ilha de 20.000 hexágonos leva alguns segundos pela rede até o Supabase. */
const TRANSACTION = { maxWait: 10_000, timeout: 60_000 };

type Tx = Prisma.TransactionClient;

interface MapVersion {
  kind: string;
  contentHash: string;
}

function statusOf(maps: MapVersion[]): IslandStatus {
  const draft = maps.find((map) => map.kind === DRAFT);
  const published = maps.find((map) => map.kind === PUBLISHED);
  if (!published) return 'draft';
  return draft?.contentHash === published.contentHash ? 'published' : 'changed';
}

/** O corpo da rota, em snake_case, como o rascunho das regras. */
export function toDraft(dto: IslandDraftDto): IslandDraft {
  return {
    name: dto.name,
    start: { q: dto.start.q, r: dto.start.r },
    tiles: dto.tiles.map(({ q, r, biome, shape, variant, area }) => ({
      q,
      r,
      biome,
      shape,
      variant,
      ...(area === undefined || area === null ? {} : { area }),
    })),
    buildings: dto.buildings.map(({ building_type_id, tiles }) => ({
      buildingTypeId: building_type_id,
      tiles: tiles.map(({ q, r }) => ({ q, r })),
    })),
    areas: dto.areas.map(({ key, name, color_hex, spawn_count, species }) => ({
      key,
      name,
      colorHex: color_hex,
      spawnCount: spawn_count,
      species: species.map((entry) => ({
        speciesId: entry.species_id,
        weight: entry.weight,
        minLevel: entry.min_level,
        maxLevel: entry.max_level,
      })),
    })),
  };
}

/** O rascunho das regras no formato da resposta. */
function toDto(draft: IslandDraft): IslandDraftDto {
  return {
    name: draft.name,
    start: draft.start,
    tiles: draft.tiles,
    buildings: draft.buildings.map(({ buildingTypeId, tiles }) => ({
      building_type_id: buildingTypeId,
      tiles,
    })),
    areas: draft.areas.map(({ key, name, colorHex, spawnCount, species }) => ({
      key,
      name,
      color_hex: colorHex,
      spawn_count: spawnCount,
      species: species.map((entry) => ({
        species_id: entry.speciesId,
        weight: entry.weight,
        min_level: entry.minLevel,
        max_level: entry.maxLevel,
      })),
    })),
  };
}

/**
 * As ilhas do editor (.specs/map-editor/architecture.md). Cada ilha tem o
 * rascunho e, depois da primeira publicação, a versão publicada. Salvar e
 * publicar trocam todas as linhas de uma versão numa transação só.
 */
@Injectable()
export class IslandsEditorService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly islands: IslandsService,
  ) {}

  async list(): Promise<IslandListResponseDto> {
    const islands = await this.prisma.island.findMany({
      orderBy: { id: 'asc' },
      include: {
        maps: {
          select: {
            kind: true,
            name: true,
            contentHash: true,
            updatedAt: true,
          },
        },
      },
    });
    return {
      islands: islands.map((island) => {
        const draft = island.maps.find((map) => map.kind === DRAFT)!;
        return {
          id: island.id,
          name: draft.name,
          status: statusOf(island.maps),
          updated_at: draft.updatedAt.toISOString(),
          published_at: island.publishedAt?.toISOString() ?? null,
        };
      }),
    };
  }

  async create(dto: IslandDraftDto): Promise<IslandCreatedResponseDto> {
    const draft = await this.checked(dto);
    const island = await this.prisma.$transaction(async (tx) => {
      const created = await tx.island.create({ data: {} });
      await this.writeVersion(tx, created.id, DRAFT, draft);
      return created;
    }, TRANSACTION);
    return { id: island.id };
  }

  async read(id: number): Promise<IslandDraftResponseDto> {
    const island = await this.island(id);
    const draft = await this.islands.readVersion(this.prisma, island.draftId);
    return {
      id,
      status: statusOf(island.maps),
      ...toDto(draft),
      updated_at: island.draftUpdatedAt.toISOString(),
      published_at: island.publishedAt?.toISOString() ?? null,
    };
  }

  async saveDraft(
    id: number,
    dto: IslandDraftDto,
  ): Promise<IslandSavedResponseDto> {
    await this.island(id);
    const draft = await this.checked(dto);
    const saved = await this.prisma.$transaction(
      (tx) => this.writeVersion(tx, id, DRAFT, draft),
      TRANSACTION,
    );
    const maps = await this.prisma.islandMap.findMany({
      where: { islandId: id },
      select: { kind: true, contentHash: true },
    });
    return {
      status: statusOf(maps),
      updated_at: saved.updatedAt.toISOString(),
    };
  }

  async publish(id: number): Promise<IslandPublishedResponseDto> {
    const island = await this.island(id);
    const draft = await this.islands.readVersion(this.prisma, island.draftId);
    const error = publishError(draft, await this.knownIds());
    if (error) throw new ConflictException(error);
    const publishedAt = await this.prisma.$transaction(async (tx) => {
      await this.writeVersion(tx, id, PUBLISHED, draft);
      const updated = await tx.island.update({
        where: { id },
        data: { publishedAt: new Date() },
      });
      return updated.publishedAt!;
    }, TRANSACTION);
    return { status: 'published', published_at: publishedAt.toISOString() };
  }

  async remove(id: number): Promise<void> {
    const island = await this.island(id);
    if (island.publishedAt) {
      throw new ConflictException(PUBLISHED_CANNOT_BE_DELETED);
    }
    await this.prisma.island.delete({ where: { id } });
  }

  /** A ilha, com o id do rascunho e as versões; 404 se ela não existe. */
  private async island(id: number) {
    const island =
      id >= 1 && id <= MAX_ID
        ? await this.prisma.island.findUnique({
            where: { id },
            include: {
              maps: {
                select: {
                  id: true,
                  kind: true,
                  contentHash: true,
                  updatedAt: true,
                },
              },
            },
          })
        : null;
    if (!island) throw new NotFoundException(ISLAND_NOT_FOUND);
    const draft = island.maps.find((map) => map.kind === DRAFT)!;
    return {
      maps: island.maps,
      publishedAt: island.publishedAt,
      draftId: draft.id,
      draftUpdatedAt: draft.updatedAt,
    };
  }

  private async knownIds(): Promise<KnownIds> {
    const [types, species] = await Promise.all([
      this.prisma.buildingType.findMany({ select: { id: true } }),
      this.prisma.species.findMany({ select: { id: true } }),
    ]);
    return {
      buildingTypeIds: new Set(types.map(({ id }) => id)),
      speciesIds: new Set(species.map(({ id }) => id)),
    };
  }

  /** O rascunho do corpo, ou 400 com a primeira coisa errada. */
  private async checked(dto: IslandDraftDto): Promise<IslandDraft> {
    const draft = toDraft(dto);
    const error = draftError(draft, await this.knownIds());
    if (error) throw new BadRequestException(error);
    return draft;
  }

  /** Troca a versão `kind` da ilha pelo rascunho, criando-a se faltar. */
  private async writeVersion(
    tx: Tx,
    islandId: number,
    kind: string,
    draft: IslandDraft,
  ) {
    await tx.islandMap.deleteMany({ where: { islandId, kind } });
    const map = await tx.islandMap.create({
      data: {
        islandId,
        kind,
        name: draft.name,
        startQ: draft.start.q,
        startR: draft.start.r,
        contentHash: draftHash(draft),
        updatedAt: new Date(),
      },
    });

    // As áreas vêm primeiro, na ordem da key, porque os hexágonos apontam para elas.
    const areaIds = new Map<number, number>();
    for (const area of [...draft.areas].sort((a, b) => a.key - b.key)) {
      const created = await tx.islandArea.create({
        data: {
          islandMapId: map.id,
          name: area.name,
          colorHex: area.colorHex,
          spawnCount: area.spawnCount,
          species: { createMany: { data: area.species } },
        },
      });
      areaIds.set(area.key, created.id);
    }

    const biomeIds = new Map(
      (await tx.biome.findMany({ select: { id: true, slug: true } })).map(
        ({ id, slug }) => [slug, id],
      ),
    );
    const tiles = draft.tiles.map(({ q, r, biome, shape, variant, area }) => ({
      islandMapId: map.id,
      q,
      r,
      biomeId: biomeIds.get(biome)!,
      shape,
      variant,
      areaId: area === undefined ? null : areaIds.get(area)!,
    }));
    for (let first = 0; first < tiles.length; first += TILE_CHUNK) {
      await tx.islandTile.createMany({
        data: tiles.slice(first, first + TILE_CHUNK),
      });
    }

    for (const building of draft.buildings) {
      const created = await tx.islandBuilding.create({
        data: { islandMapId: map.id, buildingTypeId: building.buildingTypeId },
      });
      await tx.islandBuildingTile.createMany({
        data: building.tiles.map(({ q, r }) => ({
          buildingId: created.id,
          islandMapId: map.id,
          q,
          r,
        })),
      });
    }
    return map;
  }
}
