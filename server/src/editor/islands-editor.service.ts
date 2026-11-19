import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  DEFAULT_BRIDGE_WIDTH,
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
  toBridgeDto,
  toNpcDto,
  toPropDto,
  toTrailDto,
  toWallDto,
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
export const HOME_NEEDS_PUBLISHED =
  'Publique a ilha antes de fazer dela a casa do jogador.';

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
    props: (dto.props ?? []).map((prop) => ({
      propTypeId: prop.prop_type_id,
      q: prop.q,
      r: prop.r,
      dx: prop.dx,
      dy: prop.dy,
      variant: prop.variant,
      mirrored: prop.mirrored,
      ...(prop.block === undefined || prop.block === null
        ? {}
        : {
            block: prop.block.map(({ closed, points }) => ({
              closed,
              points: [...points],
            })),
          }),
      ...(prop.action_type_id === undefined || prop.action_type_id === null
        ? {}
        : { actionTypeId: prop.action_type_id }),
      ...(prop.no_smoke === true ? { noSmoke: true as const } : {}),
      ...(prop.interior_id === undefined || prop.interior_id === null
        ? {}
        : { interiorId: prop.interior_id }),
    })),
    trails: (dto.trails ?? []).map(({ ground, width, points }) => ({
      ground,
      width,
      points: [...points],
    })),
    walls: (dto.walls ?? []).map(({ type, points }) => ({
      type,
      points: [...points],
    })),
    bridges: (dto.bridges ?? []).map(({ type, points, width }) => ({
      type,
      points: [...points],
      ...(width === undefined ? {} : { width }),
    })),
    npcs: (dto.npcs ?? []).map((npc) => ({
      npcId: npc.npc_id,
      q: npc.q,
      r: npc.r,
      still: npc.still,
      tiles: (npc.tiles ?? []).map(({ q, r }) => ({ q, r })),
      dialogue: npc.dialogue ?? '',
      actionTypeId: npc.action_type_id ?? null,
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
    props: draft.props.map(toPropDto),
    trails: (draft.trails ?? []).map(toTrailDto),
    walls: (draft.walls ?? []).map(toWallDto),
    bridges: (draft.bridges ?? []).map(toBridgeDto),
    npcs: (draft.npcs ?? []).map(toNpcDto),
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
      home: island.isHome,
    };
  }

  /** Liga ou desliga a casa do jogador; ligar numa ilha desliga a de outra. */
  async setHome(id: number, home: boolean): Promise<IslandDraftResponseDto> {
    const island = await this.island(id);
    if (home && !island.publishedAt) {
      throw new BadRequestException(HOME_NEEDS_PUBLISHED);
    }
    await this.prisma.$transaction([
      ...(home
        ? [
            this.prisma.island.updateMany({
              where: { isHome: true, id: { not: id } },
              data: { isHome: false },
            }),
          ]
        : []),
      this.prisma.island.update({ where: { id }, data: { isHome: home } }),
    ]);
    return this.read(id);
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
      isHome: island.isHome,
      draftId: draft.id,
      draftUpdatedAt: draft.updatedAt,
    };
  }

  private async knownIds(): Promise<KnownIds> {
    const [actions, grounds, species, props, npcs, walls, bridges, blocks, interiors] =
      await Promise.all([
        this.prisma.actionType.findMany({ select: { id: true } }),
        this.prisma.groundType.findMany({ select: { slug: true } }),
        this.prisma.species.findMany({ select: { id: true } }),
        this.prisma.propType.findMany({ select: { id: true, variants: true } }),
        this.prisma.npc.findMany({ select: { id: true } }),
        this.prisma.wallType.findMany({ select: { slug: true } }),
        this.prisma.bridgeType.findMany({ select: { slug: true } }),
        this.islands.readTypeBlocks(),
        this.prisma.interior.findMany({ select: { id: true } }),
      ]);
    return {
      actionTypeIds: new Set(actions.map(({ id }) => id)),
      groundSlugs: new Set(grounds.map(({ slug }) => slug)),
      speciesIds: new Set(species.map(({ id }) => id)),
      propVariants: new Map(props.map(({ id, variants }) => [id, variants])),
      npcIds: new Set(npcs.map(({ id }) => id)),
      interiorIds: new Set(interiors.map(({ id }) => id)),
      wallSlugs: new Set(walls.map(({ slug }) => slug)),
      bridgeSlugs: new Set(bridges.map(({ slug }) => slug)),
      propBlocks: blocks,
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

    const props = draft.props
      .filter(({ block }) => block === undefined)
      .map(
        ({
          propTypeId,
          q,
          r,
          dx,
          dy,
          variant,
          mirrored,
          actionTypeId,
          noSmoke,
          interiorId,
        }) => ({
          islandMapId: map.id,
          propTypeId,
          q,
          r,
          dx,
          dy,
          variant,
          mirrored,
          actionTypeId: actionTypeId ?? null,
          noSmoke: noSmoke === true,
          interiorId: interiorId ?? null,
        }),
      );
    for (let first = 0; first < props.length; first += TILE_CHUNK) {
      await tx.islandProp.createMany({
        data: props.slice(first, first + TILE_CHUNK),
      });
    }
    // As ajustadas depois, com as linhas: o serial cresce na ordem da lista, e por
    // isso o id ordenado acha cada peça.
    const custom = draft.props.filter(({ block }) => block !== undefined);
    if (custom.length > 0) {
      const created = await tx.islandProp.createManyAndReturn({
        data: custom.map(
          ({
            propTypeId,
            q,
            r,
            dx,
            dy,
            variant,
            mirrored,
            actionTypeId,
            noSmoke,
            interiorId,
          }) => ({
            islandMapId: map.id,
            propTypeId,
            q,
            r,
            dx,
            dy,
            variant,
            mirrored,
            customBlock: true,
            actionTypeId: actionTypeId ?? null,
            noSmoke: noSmoke === true,
            interiorId: interiorId ?? null,
          }),
        ),
        select: { id: true },
      });
      const ids = created.map(({ id }) => id).sort((a, b) => a - b);
      const lines = custom.flatMap((prop, index) =>
        prop.block!.map(({ closed, points }, position) => ({
          islandPropId: ids[index]!,
          position,
          closed,
          points,
        })),
      );
      for (let first = 0; first < lines.length; first += TILE_CHUNK) {
        await tx.islandPropBlock.createMany({
          data: lines.slice(first, first + TILE_CHUNK),
        });
      }
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

    const wallIds = new Map(
      (await tx.wallType.findMany({ select: { id: true, slug: true } })).map(
        ({ id, slug }) => [slug, id],
      ),
    );
    const walls = (draft.walls ?? []).map(({ type, points }, position) => ({
      islandMapId: map.id,
      wallTypeId: wallIds.get(type)!,
      position,
      points,
    }));
    for (let first = 0; first < walls.length; first += TILE_CHUNK) {
      await tx.islandWall.createMany({
        data: walls.slice(first, first + TILE_CHUNK),
      });
    }

    const bridgeIds = new Map(
      (await tx.bridgeType.findMany({ select: { id: true, slug: true } })).map(
        ({ id, slug }) => [slug, id],
      ),
    );
    const bridges = (draft.bridges ?? []).map(
      ({ type, points, width }, position) => ({
        islandMapId: map.id,
        bridgeTypeId: bridgeIds.get(type)!,
        position,
        points,
        width: width ?? DEFAULT_BRIDGE_WIDTH,
      }),
    );
    for (let first = 0; first < bridges.length; first += TILE_CHUNK) {
      await tx.islandBridge.createMany({
        data: bridges.slice(first, first + TILE_CHUNK),
      });
    }

    const npcs = draft.npcs ?? [];
    if (npcs.length > 0) {
      // O serial cresce na ordem da lista, e por isso o id ordenado acha cada NPC.
      const created = await tx.islandNpc.createManyAndReturn({
        data: npcs.map(({ npcId, q, r, still, dialogue, actionTypeId }) => ({
          islandMapId: map.id,
          npcId,
          q,
          r,
          still,
          dialogue,
          actionTypeId,
        })),
        select: { id: true },
      });
      const ids = created.map(({ id }) => id).sort((a, b) => a - b);
      const npcTiles = npcs.flatMap((npc, index) =>
        npc.tiles.map(({ q, r }) => ({ islandNpcId: ids[index]!, q, r })),
      );
      for (let first = 0; first < npcTiles.length; first += TILE_CHUNK) {
        await tx.islandNpcTile.createMany({
          data: npcTiles.slice(first, first + TILE_CHUNK),
        });
      }
    }
    return map;
  }
}
