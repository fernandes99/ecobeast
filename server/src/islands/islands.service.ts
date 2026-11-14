import { Injectable } from '@nestjs/common';
import type { Biome } from '../domain/exploration/map-generator.js';
import type { IslandDraft } from '../domain/islands/island-draft.js';
import type { Prisma } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';

export const ISLAND_NOT_FOUND = 'Ilha não encontrada.';

const PUBLISHED = 'published';

type Tx = Prisma.TransactionClient;

export interface PublishedIsland {
  id: number;
  name: string;
  draft: IslandDraft;
}

@Injectable()
export class IslandsService {
  constructor(private readonly prisma: PrismaService) {}

  async listPublished(): Promise<{ id: number; name: string }[]> {
    const maps = await this.prisma.islandMap.findMany({
      where: { kind: PUBLISHED },
      orderBy: { islandId: 'asc' },
      select: { islandId: true, name: true },
    });
    return maps.map(({ islandId, name }) => ({ id: islandId, name }));
  }

  async readPublished(islandId: number): Promise<PublishedIsland | null> {
    const map = await this.prisma.islandMap.findUnique({
      where: { islandId_kind: { islandId, kind: PUBLISHED } },
      select: { id: true },
    });
    if (!map) return null;
    const draft = await this.readVersion(this.prisma, map.id);
    return { id: islandId, name: draft.name, draft };
  }

  async readVersion(
    client: Tx | PrismaService,
    islandMapId: number,
  ): Promise<IslandDraft> {
    const [map, tiles, actions, objects, props, areas] = await Promise.all([
      client.islandMap.findUniqueOrThrow({ where: { id: islandMapId } }),
      client.islandTile.findMany({
        where: { islandMapId },
        orderBy: [{ r: 'asc' }, { q: 'asc' }],
        include: {
          biome: { select: { slug: true } },
          groundType: { select: { slug: true } },
        },
      }),
      client.islandAction.findMany({
        where: { islandMapId },
        orderBy: { id: 'asc' },
        include: { tiles: { orderBy: [{ r: 'asc' }, { q: 'asc' }] } },
      }),
      client.islandObject.findMany({
        where: { islandMapId },
        orderBy: { id: 'asc' },
        include: { tiles: { orderBy: [{ r: 'asc' }, { q: 'asc' }] } },
      }),
      client.islandProp.findMany({
        where: { islandMapId },
        orderBy: { id: 'asc' },
      }),
      client.islandArea.findMany({
        where: { islandMapId },
        orderBy: { id: 'asc' },
        include: { species: { orderBy: { speciesId: 'asc' } } },
      }),
    ]);
    const keys = new Map(areas.map((area, index) => [area.id, index + 1]));
    return {
      name: map.name,
      start: { q: map.startQ, r: map.startR },
      tiles: tiles.map(
        ({ q, r, biome, height, variant, groundType, areaId, bare }) => ({
          q,
          r,
          biome: biome.slug as Biome,
          height,
          variant,
          ...(groundType === null ? {} : { ground: groundType.slug }),
          ...(areaId === null ? {} : { area: keys.get(areaId)! }),
          ...(bare ? { bare } : {}),
        }),
      ),
      actions: actions.map(({ actionTypeId, tiles: occupied }) => ({
        actionTypeId,
        tiles: occupied.map(({ q, r }) => ({ q, r })),
      })),
      objects: objects.map((object) => ({
        objectTypeId: object.objectTypeId,
        q: object.q,
        r: object.r,
        variant: object.variant,
        mirrored: object.mirrored,
        tiles: object.tiles.map(({ q, r, blocks }) => ({ q, r, blocks })),
      })),
      props: props.map(({ propTypeId, q, r, dx, dy, variant, mirrored }) => ({
        propTypeId,
        q,
        r,
        dx,
        dy,
        variant,
        mirrored,
      })),
      areas: areas.map(({ id, name, colorHex, spawnCount, species }) => ({
        key: keys.get(id)!,
        name,
        colorHex,
        spawnCount,
        species: species.map(({ speciesId, weight, minLevel, maxLevel }) => ({
          speciesId,
          weight,
          minLevel,
          maxLevel,
        })),
      })),
    };
  }
}
