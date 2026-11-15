import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { BundleService } from '../catalog/bundle/bundle.service.js';
import { hexKey } from '../domain/exploration/hex.js';
import {
  type BlockLine,
  blockLineError,
  MAX_BLOCK_LINES,
} from '../domain/islands/blocked-hexes.js';
import { blockedKeys } from '../domain/islands/island-draft.js';
import { IslandsService } from '../islands/islands.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import type {
  BlockedStartDto,
  PropTypeBlocksDto,
  PropTypeBlocksSavedDto,
} from './prop-types-editor.dto.js';

export const PROP_TYPE_NOT_FOUND = 'Tipo de peça não encontrado.';

@Injectable()
export class PropTypesEditorService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly bundle: BundleService,
    private readonly islands: IslandsService,
  ) {}

  async saveBlocks(
    id: number,
    dto: PropTypeBlocksDto,
  ): Promise<PropTypeBlocksSavedDto> {
    if (!(await this.prisma.propType.findUnique({ where: { id } }))) {
      throw new NotFoundException(PROP_TYPE_NOT_FOUND);
    }
    const blocks: BlockLine[] = dto.blocks.map(({ closed, points }) => ({
      closed,
      points: [...points],
    }));
    const error = blocksError(blocks);
    if (error) throw new BadRequestException(error);
    await this.prisma.$transaction(async (tx) => {
      await tx.propTypeBlock.deleteMany({ where: { propTypeId: id } });
      if (blocks.length > 0) {
        await tx.propTypeBlock.createMany({
          data: blocks.map(({ closed, points }, position) => ({
            propTypeId: id,
            position,
            closed,
            points,
          })),
        });
      }
    });
    this.bundle.invalidate();
    return { blocks, blocked_starts: await this.blockedStarts(id) };
  }

  /** As versões de ilha com peças sem ajuste deste tipo e a chegada bloqueada. */
  private async blockedStarts(propTypeId: number): Promise<BlockedStartDto[]> {
    const maps = await this.prisma.islandMap.findMany({
      where: { props: { some: { propTypeId, customBlock: false } } },
      orderBy: [{ islandId: 'asc' }, { kind: 'asc' }],
      select: { id: true, islandId: true, kind: true, name: true },
    });
    if (maps.length === 0) return [];
    const typeBlocks = await this.islands.readTypeBlocks();
    const blocked: BlockedStartDto[] = [];
    for (const map of maps) {
      const draft = await this.islands.readVersion(this.prisma, map.id);
      if (blockedKeys(draft, typeBlocks).has(hexKey(draft.start))) {
        blocked.push({
          island_id: map.islandId,
          kind: map.kind,
          name: map.name,
        });
      }
    }
    return blocked;
  }
}

function blocksError(blocks: BlockLine[]): string | null {
  if (blocks.length > MAX_BLOCK_LINES) {
    return `O tipo pode ter até ${MAX_BLOCK_LINES} linhas de bloqueio.`;
  }
  for (const [index, line] of blocks.entries()) {
    const error = blockLineError(line);
    if (error) return `A linha de bloqueio ${index + 1} ${error}.`;
  }
  return null;
}
