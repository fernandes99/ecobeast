import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  type InteriorBody,
  interiorError,
  MAX_NAME_LENGTH,
  MAX_SIZE,
  MIN_SIZE,
} from '../domain/interiors/interior-body.js';
import type {
  InteriorBodyDto,
  InteriorDto,
} from '../interiors/interiors.dto.js';
import { InteriorsService } from '../interiors/interiors.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import type {
  InteriorListDto,
  NewInteriorDto,
} from './interiors-editor.dto.js';

export const EDITOR_INTERIOR_NOT_FOUND = 'Interior não encontrado.';
export const INTERIOR_IN_USE = 'Uma peça de ilha leva a esse interior.';
const MAX_ID = 2_147_483_647;
const CHUNK = 2_000;
const TRANSACTION = { maxWait: 10_000, timeout: 60_000 };

@Injectable()
export class InteriorsEditorService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly interiors: InteriorsService,
  ) {}

  async list(): Promise<InteriorListDto> {
    const rows = await this.prisma.interior.findMany({
      select: { id: true, name: true },
      orderBy: { id: 'asc' },
    });
    return { interiors: rows };
  }

  async read(id: number): Promise<InteriorDto> {
    const room = await this.interiors.read(id);
    if (!room) throw new NotFoundException(EDITOR_INTERIOR_NOT_FOUND);
    return room;
  }

  /** Uma sala vazia, com a porta no meio da linha de baixo; a regra da porta vale no salvar. */
  async create(dto: NewInteriorDto): Promise<InteriorDto> {
    const sized = (value: number) => value >= MIN_SIZE && value <= MAX_SIZE;
    if (dto.name.length < 1 || dto.name.length > MAX_NAME_LENGTH) {
      throw new BadRequestException('O nome precisa ter de 1 a 40 caracteres.');
    }
    if (!sized(dto.width) || !sized(dto.height)) {
      throw new BadRequestException(
        'A largura e a altura vão de 4 a 64 quadrados.',
      );
    }
    const room = await this.prisma.interior.create({
      data: {
        name: dto.name,
        width: dto.width,
        height: dto.height,
        doorX: Math.floor(dto.width / 2),
        doorY: dto.height - 1,
        updatedAt: new Date(),
      },
    });
    return this.read(room.id);
  }

  async save(id: number, dto: InteriorBodyDto): Promise<InteriorDto> {
    await this.ensure(id);
    const body: InteriorBody = {
      name: dto.name,
      width: dto.width,
      height: dto.height,
      door: { x: dto.door.x, y: dto.door.y },
      tiles: dto.tiles,
      objects: dto.objects.map((object) => ({
        ...object,
        action_type_id: object.action_type_id ?? null,
      })),
      blocks: dto.blocks,
      npcs: dto.npcs.map((npc) => ({
        ...npc,
        action_type_id: npc.action_type_id ?? null,
      })),
    };
    const [npcs, actions] = await Promise.all([
      this.prisma.npc.findMany({ select: { id: true } }),
      this.prisma.actionType.findMany({ select: { id: true } }),
    ]);
    const error = interiorError(body, {
      npcIds: new Set(npcs.map(({ id: npcId }) => npcId)),
      actionTypeIds: new Set(actions.map(({ id: actionId }) => actionId)),
    });
    if (error) throw new BadRequestException(error);

    await this.prisma.$transaction(async (tx) => {
      const where = { interiorId: id };
      await tx.interiorTile.deleteMany({ where });
      await tx.interiorObject.deleteMany({ where });
      await tx.interiorBlock.deleteMany({ where });
      await tx.interiorNpc.deleteMany({ where });
      await tx.interior.update({
        where: { id },
        data: {
          name: body.name,
          width: body.width,
          height: body.height,
          doorX: body.door.x,
          doorY: body.door.y,
          updatedAt: new Date(),
        },
      });
      for (let first = 0; first < body.tiles.length; first += CHUNK) {
        await tx.interiorTile.createMany({
          data: body.tiles
            .slice(first, first + CHUNK)
            .map(({ layer, x, y, sheet, col, row }) => ({
              interiorId: id,
              layer,
              x,
              y,
              sheet,
              col,
              row,
            })),
        });
      }
      // Numa inserção só, o serial cresce na ordem do corpo, que é a ordem de desenho.
      await tx.interiorObject.createMany({
        data: body.objects.map(({ x, y, sheet, col, row, width, height, action_type_id }) => ({
          interiorId: id,
          x,
          y,
          sheet,
          col,
          row,
          width,
          height,
          actionTypeId: action_type_id,
        })),
      });
      await tx.interiorBlock.createMany({
        data: body.blocks.map(({ x, y }) => ({ interiorId: id, x, y })),
      });
      await tx.interiorNpc.createMany({
        data: body.npcs.map(({ npc_id, x, y, dialogue, action_type_id }) => ({
          interiorId: id,
          npcId: npc_id,
          x,
          y,
          dialogue,
          actionTypeId: action_type_id,
        })),
      });
    }, TRANSACTION);
    return this.read(id);
  }

  async remove(id: number): Promise<void> {
    await this.ensure(id);
    const linked = await this.prisma.islandProp.count({
      where: { interiorId: id },
    });
    if (linked > 0) throw new ConflictException(INTERIOR_IN_USE);
    await this.prisma.interior.delete({ where: { id } });
  }

  private async ensure(id: number): Promise<void> {
    const found =
      Number.isInteger(id) && id >= 1 && id <= MAX_ID
        ? await this.prisma.interior.findUnique({
            where: { id },
            select: { id: true },
          })
        : null;
    if (!found) throw new NotFoundException(EDITOR_INTERIOR_NOT_FOUND);
  }
}
