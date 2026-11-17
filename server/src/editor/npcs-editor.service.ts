import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { BundleService } from '../catalog/bundle/bundle.service.js';
import { checkedAppearance } from '../player/appearance-check.js';
import type { AppearanceDto } from '../player/player.dto.js';
import { PrismaService } from '../prisma/prisma.service.js';
import type {
  NpcAppearanceResponseDto,
  NpcVoiceResponseDto,
} from './npcs-editor.dto.js';

export const NPC_NOT_FOUND = 'NPC não encontrado.';
export const NPC_IS_CREATURE = 'Esse NPC é um Ecobeast.';
export const VOICE_NOT_FOUND = 'Essa voz não existe.';
const MAX_ID = 2_147_483_647;

@Injectable()
export class NpcsEditorService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly bundle: BundleService,
  ) {}

  /** Troca a aparência inteira de um NPC pessoa e libera o catálogo novo. */
  async setAppearance(
    id: number,
    appearance: AppearanceDto,
  ): Promise<NpcAppearanceResponseDto> {
    const npc =
      id >= 1 && id <= MAX_ID
        ? await this.prisma.npc.findUnique({
            where: { id },
            select: { bodyTypeId: true },
          })
        : null;
    if (!npc) throw new NotFoundException(NPC_NOT_FOUND);
    if (npc.bodyTypeId === null) throw new BadRequestException(NPC_IS_CREATURE);

    const worn = await checkedAppearance(this.prisma, appearance);
    await this.prisma.$transaction([
      this.prisma.npc.update({
        where: { id },
        data: {
          bodyTypeId: appearance.body_type_id,
          skinPaletteId: appearance.skin_palette_id,
        },
      }),
      this.prisma.npcAppearancePart.deleteMany({ where: { npcId: id } }),
      this.prisma.npcAppearancePart.createMany({
        data: worn.map(({ slotId, partId, paletteId }) => ({
          npcId: id,
          appearanceSlotId: slotId,
          appearancePartId: partId,
          paletteId,
        })),
      }),
    ]);
    this.bundle.invalidate();
    return {
      id,
      body_type_id: appearance.body_type_id,
      skin_palette_id: appearance.skin_palette_id,
      parts: worn.map(({ partId, paletteId }) => ({
        part_id: partId,
        palette_id: paletteId,
      })),
    };
  }

  /** Troca a voz de um NPC e libera o catálogo novo. */
  async setVoice(id: number, voiceId: number): Promise<NpcVoiceResponseDto> {
    const npc =
      id >= 1 && id <= MAX_ID
        ? await this.prisma.npc.findUnique({
            where: { id },
            select: { id: true },
          })
        : null;
    if (!npc) throw new NotFoundException(NPC_NOT_FOUND);
    const voice =
      voiceId >= 1 && voiceId <= MAX_ID
        ? await this.prisma.voice.findUnique({
            where: { id: voiceId },
            select: { id: true },
          })
        : null;
    if (!voice) throw new BadRequestException(VOICE_NOT_FOUND);

    await this.prisma.npc.update({ where: { id }, data: { voiceId } });
    this.bundle.invalidate();
    return { id, voice_id: voiceId };
  }
}
