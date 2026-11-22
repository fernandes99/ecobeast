import { BadRequestException } from '@nestjs/common';
import { appearanceError } from '../domain/appearance/appearance.js';
import { PrismaService } from '../prisma/prisma.service.js';
import type { AppearanceDto } from './player.dto.js';

export interface WornPart {
  slotId: number;
  partId: number;
  paletteId: number | null;
}

/**
 * Confere uma aparência pelas regras do catálogo e devolve as peças com o lugar
 * de cada uma. Serve ao Domador e, com `npc`, aos NPCs pessoas (liora-intro/02),
 * que podem ter corpo de criança (village-crowd/02).
 */
export async function checkedAppearance(
  prisma: PrismaService,
  appearance: AppearanceDto,
  npc = false,
): Promise<WornPart[]> {
  const [bodies, slots, parts, palettes] = await Promise.all([
    prisma.bodyType.findMany({
      select: { id: true, name: true, adultBodyTypeId: true },
    }),
    prisma.appearanceSlot.findMany({
      select: { id: true, name: true, paletteKind: true, required: true },
    }),
    prisma.appearancePart.findMany({
      select: {
        id: true,
        name: true,
        appearanceSlotId: true,
        bodyTypeId: true,
      },
    }),
    prisma.palette.findMany({ select: { id: true, kind: true } }),
  ]);
  const catalogParts = parts.map(({ appearanceSlotId, ...part }) => ({
    ...part,
    slotId: appearanceSlotId,
  }));
  const worn = appearance.parts.map(({ part_id, palette_id }) => ({
    partId: part_id,
    paletteId: palette_id ?? null,
  }));
  const error = appearanceError(
    {
      bodyTypeId: appearance.body_type_id,
      skinPaletteId: appearance.skin_palette_id,
      parts: worn,
    },
    { bodies, slots, parts: catalogParts, palettes },
    npc,
  );
  if (error) throw new BadRequestException(error);
  return worn.map(({ partId, paletteId }) => ({
    slotId: catalogParts.find(({ id }) => id === partId)!.slotId,
    partId,
    paletteId,
  }));
}
