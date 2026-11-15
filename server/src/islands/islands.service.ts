import { Injectable } from '@nestjs/common';
import type { Biome } from '../domain/exploration/map-generator.js';
import {
  type BlockLine,
  type TypeBlocks,
  typeBlockKey,
} from '../domain/islands/blocked-hexes.js';
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

  /** As linhas de bloqueio padrão de cada tipo de peça (free-objects). */
  async readTypeBlocks(): Promise<TypeBlocks> {
    const rows = await this.prisma.propTypeBlock.findMany({
      orderBy: [{ propTypeId: 'asc' }, { variant: 'asc' }, { position: 'asc' }],
    });
    const blocks = new Map<string, BlockLine[]>();
    for (const { propTypeId, variant, closed, points } of rows) {
      const key = typeBlockKey(propTypeId, variant);
      const lines = blocks.get(key) ?? [];
      lines.push({ closed, points });
      blocks.set(key, lines);
    }
    return blocks;
  }

  async readVersion(
    client: Tx | PrismaService,
    islandMapId: number,
  ): Promise<IslandDraft> {
    const [map, tiles, actions, props, trails, walls, npcs, areas] =
      await Promise.all([
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
        client.islandProp.findMany({
          where: { islandMapId },
          orderBy: { id: 'asc' },
          include: { blocks: { orderBy: { position: 'asc' } } },
        }),
        client.islandTrail.findMany({
          where: { islandMapId },
          orderBy: { position: 'asc' },
          include: { groundType: { select: { slug: true } } },
        }),
        client.islandWall.findMany({
          where: { islandMapId },
          orderBy: { position: 'asc' },
          include: { wallType: { select: { slug: true } } },
        }),
        client.islandNpc.findMany({
          where: { islandMapId },
          orderBy: { id: 'asc' },
          include: { tiles: { orderBy: [{ r: 'asc' }, { q: 'asc' }] } },
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
      props: props.map(
        ({
          propTypeId,
          q,
          r,
          dx,
          dy,
          variant,
          mirrored,
          customBlock,
          blocks,
          actionTypeId,
        }) => ({
          propTypeId,
          q,
          r,
          dx,
          dy,
          variant,
          mirrored,
          ...(customBlock
            ? {
                block: blocks.map(({ closed, points }) => ({ closed, points })),
              }
            : {}),
          ...(actionTypeId === null ? {} : { actionTypeId }),
        }),
      ),
      trails: trails.map(({ groundType, width, points }) => ({
        ground: groundType.slug,
        width,
        points,
      })),
      walls: walls.map(({ wallType, points }) => ({
        type: wallType.slug,
        points,
      })),
      npcs: npcs.map((npc) => ({
        npcId: npc.npcId,
        q: npc.q,
        r: npc.r,
        still: npc.still,
        tiles: npc.tiles.map(({ q, r }) => ({ q, r })),
        dialogue: npc.dialogue,
        actionTypeId: npc.actionTypeId,
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
