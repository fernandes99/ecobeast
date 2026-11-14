import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { hexKey } from '../domain/exploration/hex.js';
import {
  draftError,
  draftHash,
  type IslandDraft,
  type KnownIds,
  publishError,
} from '../domain/islands/island-draft.js';
import type { Prisma } from '../generated/prisma/client.js';
import {
  ISLAND_NOT_FOUND,
  IslandsService,
} from '../islands/islands.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import {
  toObjectDto,
  toPropDto,
  toTrailDto,
} from '../exploration/exploration.dto.js';
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
const MAX_ID = 2_147_483_647;
const TILE_CHUNK = 5_000;
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

export function toDraft(dto: IslandDraftDto): IslandDraft {
  return {
    name: dto.name,
    start: { q: dto.start.q, r: dto.start.r },
    tiles: dto.tiles.map(
      ({ q, r, biome, height, variant, ground, area, bare }) => ({
        q,
        r,
        biome,
        height,
        variant,
        ...(ground === undefined || ground === null ? {} : { ground }),
        ...(area === undefined || area === null ? {} : { area }),
        ...(bare === true ? { bare } : {}),
      }),
    ),
    actions: dto.actions.map(({ action_type_id, tiles }) => ({
      actionTypeId: action_type_id,
      tiles: tiles.map(({ q, r }) => ({ q, r })),
    })),
    objects: dto.objects.map((object) => ({
      objectTypeId: object.object_type_id,
      q: object.q,
      r: object.r,
      variant: object.variant,
      mirrored: object.mirrored,
      tiles: object.tiles.map(({ q, r, blocks }) => ({ q, r, blocks })),
    })),
    props: (dto.props ?? []).map((prop) => ({
      propTypeId: prop.prop_type_id,
      q: prop.q,
      r: prop.r,
      dx: prop.dx,
      dy: prop.dy,
      variant: prop.variant,
      mirrored: prop.mirrored,
    })),
    trails: (dto.trails ?? []).map(({ ground, width, points }) => ({
      ground,
      width,
      points: [...points],
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

function toDto(draft: IslandDraft): IslandDraftDto {
  return {
    name: draft.name,
    start: draft.start,
    tiles: draft.tiles,
    actions: draft.actions.map(({ actionTypeId, tiles }) => ({
      action_type_id: actionTypeId,
      tiles,
    })),
    objects: draft.objects.map(toObjectDto),
    props: draft.props.map(toPropDto),
    trails: (draft.trails ?? []).map(toTrailDto),
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
    const [actions, objects, grounds, species, props] = await Promise.all([
      this.prisma.actionType.findMany({ select: { id: true } }),
      this.prisma.mapObjectType.findMany({ select: { id: true } }),
      this.prisma.groundType.findMany({ select: { slug: true } }),
      this.prisma.species.findMany({ select: { id: true } }),
      this.prisma.propType.findMany({ select: { id: true, variants: true } }),
    ]);
    return {
      actionTypeIds: new Set(actions.map(({ id }) => id)),
      objectTypeIds: new Set(objects.map(({ id }) => id)),
      groundSlugs: new Set(grounds.map(({ slug }) => slug)),
      speciesIds: new Set(species.map(({ id }) => id)),
      propVariants: new Map(props.map(({ id, variants }) => [id, variants])),
    };
  }

  private async checked(dto: IslandDraftDto): Promise<IslandDraft> {
    const draft = toDraft(dto);
    const error = draftError(draft, await this.knownIds());
    if (error) throw new BadRequestException(error);
    return draft;
  }

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
    const groundIds = new Map(
      (await tx.groundType.findMany({ select: { id: true, slug: true } })).map(
        ({ id, slug }) => [slug, id],
      ),
    );
    const tiles = draft.tiles.map(
      ({ q, r, biome, height, variant, ground, area, bare }) => ({
        islandMapId: map.id,
        q,
        r,
        biomeId: biomeIds.get(biome)!,
        height,
        variant,
        groundTypeId: ground === undefined ? null : groundIds.get(ground)!,
        areaId: area === undefined ? null : areaIds.get(area)!,
        bare: bare === true,
      }),
    );
    for (let first = 0; first < tiles.length; first += TILE_CHUNK) {
      await tx.islandTile.createMany({
        data: tiles.slice(first, first + TILE_CHUNK),
      });
    }

    for (const action of draft.actions) {
      const created = await tx.islandAction.create({
        data: { islandMapId: map.id, actionTypeId: action.actionTypeId },
      });
      await tx.islandActionTile.createMany({
        data: action.tiles.map(({ q, r }) => ({
          actionId: created.id,
          islandMapId: map.id,
          q,
          r,
        })),
      });
    }

    // Em lote: um a um, 300 objetos passavam do tempo da transação até o Supabase.
    // O apoio de cada objeto é um hexágono só dele, e por isso acha o id.
    const objectIds = new Map<string, number>();
    for (let first = 0; first < draft.objects.length; first += TILE_CHUNK) {
      const created = await tx.islandObject.createManyAndReturn({
        data: draft.objects
          .slice(first, first + TILE_CHUNK)
          .map(({ objectTypeId, q, r, variant, mirrored }) => ({
            islandMapId: map.id,
            objectTypeId,
            q,
            r,
            variant,
            mirrored,
          })),
        select: { id: true, q: true, r: true },
      });
      for (const { id, q, r } of created) objectIds.set(hexKey({ q, r }), id);
    }
    const objectTiles = draft.objects.flatMap((object) =>
      object.tiles.map(({ q, r, blocks }) => ({
        objectId: objectIds.get(hexKey(object))!,
        islandMapId: map.id,
        q,
        r,
        blocks,
      })),
    );
    for (let first = 0; first < objectTiles.length; first += TILE_CHUNK) {
      await tx.islandObjectTile.createMany({
        data: objectTiles.slice(first, first + TILE_CHUNK),
      });
    }

    const props = draft.props.map(
      ({ propTypeId, q, r, dx, dy, variant, mirrored }) => ({
        islandMapId: map.id,
        propTypeId,
        q,
        r,
        dx,
        dy,
        variant,
        mirrored,
      }),
    );
    for (let first = 0; first < props.length; first += TILE_CHUNK) {
      await tx.islandProp.createMany({
        data: props.slice(first, first + TILE_CHUNK),
      });
    }

    const trails = (draft.trails ?? []).map(
      ({ ground, width, points }, position) => ({
        islandMapId: map.id,
        groundTypeId: groundIds.get(ground)!,
        position,
        width,
        points,
      }),
    );
    for (let first = 0; first < trails.length; first += TILE_CHUNK) {
      await tx.islandTrail.createMany({
        data: trails.slice(first, first + TILE_CHUNK),
      });
    }
    return map;
  }
}
