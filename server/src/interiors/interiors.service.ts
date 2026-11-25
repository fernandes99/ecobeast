import { Injectable } from '@nestjs/common';
import { INTERIOR_LAYERS } from '../domain/interiors/interior-body.js';
import { PrismaService } from '../prisma/prisma.service.js';
import type { InteriorDto } from './interiors.dto.js';

export const INTERIOR_NOT_FOUND = 'Esse lugar não existe.';
const MAX_ID = 2_147_483_647;

@Injectable()
export class InteriorsService {
  constructor(private readonly prisma: PrismaService) {}

  /** A sala inteira, no corpo da architecture, ou `null`. */
  async read(id: number): Promise<InteriorDto | null> {
    if (!Number.isInteger(id) || id < 1 || id > MAX_ID) return null;
    const room = await this.prisma.interior.findUnique({
      where: { id },
      include: {
        tiles: true,
        objects: { orderBy: { id: 'asc' } },
        blocks: { orderBy: [{ y: 'asc' }, { x: 'asc' }] },
        npcs: { orderBy: { id: 'asc' } },
      },
    });
    if (!room) return null;
    const layer = (name: string) =>
      (INTERIOR_LAYERS as readonly string[]).indexOf(name);
    return {
      id: room.id,
      name: room.name,
      width: room.width,
      height: room.height,
      door: { x: room.doorX, y: room.doorY },
      tiles: [...room.tiles]
        .sort((a, b) => layer(a.layer) - layer(b.layer) || a.y - b.y || a.x - b.x)
        .map(({ layer: name, x, y, sheet, col, row }) => ({
          layer: name,
          x,
          y,
          sheet,
          col,
          row,
        })),
      objects: room.objects.map(
        ({ id: objectId, x, y, sheet, col, row, width, height, actionTypeId }) => ({
          id: objectId,
          x,
          y,
          sheet,
          col,
          row,
          width,
          height,
          action_type_id: actionTypeId,
        }),
      ),
      blocks: room.blocks.map(({ x, y }) => ({ x, y })),
      npcs: room.npcs.map(({ id: npcId, npcId: catalogId, x, y, dialogue, actionTypeId }) => ({
        id: npcId,
        npc_id: catalogId,
        x,
        y,
        dialogue,
        action_type_id: actionTypeId,
      })),
    };
  }
}
