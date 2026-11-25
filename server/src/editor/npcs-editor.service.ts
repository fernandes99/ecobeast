import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { BundleService } from '../catalog/bundle/bundle.service.js';
import type {
  AppearanceCatalog,
  AppearanceInput,
} from '../domain/appearance/appearance.js';
import {
  defaultAppearance,
  MAX_NPC_DESCRIPTION,
  MAX_NPC_DIALOGUE,
  MAX_NPC_NAME,
  npcSlug,
  npcUsageText,
} from '../domain/npcs/npc-catalog.js';
import { checkedAppearance } from '../player/appearance-check.js';
import type { AppearanceDto } from '../player/player.dto.js';
import { PrismaService } from '../prisma/prisma.service.js';
import type {
  NpcAppearanceResponseDto,
  NpcCreateBodyDto,
  NpcDeleteResponseDto,
  NpcRowDto,
  NpcUpdateBodyDto,
  NpcVoiceResponseDto,
} from './npcs-editor.dto.js';

export const NPC_NOT_FOUND = 'NPC não encontrado.';
export const NPC_IS_CREATURE = 'Esse NPC é um Ecobeast.';
export const VOICE_NOT_FOUND = 'Essa voz não existe.';
export const NPC_IS_PERSON =
  'Esse NPC é uma pessoa: troque a roupa pela Aparência.';
export const NPC_KIND_REQUIRED =
  'Escolha um Ecobeast (`sprite`) ou um corpo (`body_type_id`), só um.';
export const SPRITE_NOT_FOUND = 'Esse Ecobeast não existe.';
export const BODY_NOT_FOUND = 'Esse corpo não existe.';
export const NPC_NAME_SIZE = `O nome precisa ter de 1 a ${MAX_NPC_NAME} letras.`;
export const NPC_DESCRIPTION_SIZE = `A descrição pode ter até ${MAX_NPC_DESCRIPTION} letras.`;
export const NPC_DIALOGUE_SIZE = `A fala padrão pode ter até ${MAX_NPC_DIALOGUE} letras.`;
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

    const worn = await checkedAppearance(this.prisma, appearance, true);
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

  /** Cria um NPC Ecobeast (`sprite`) ou pessoa (`body_type_id`), já vestido. */
  async create(body: NpcCreateBodyDto): Promise<NpcRowDto> {
    const fields = this.checkedFields(body);
    const hasSprite = body.sprite !== undefined && body.sprite !== null;
    const hasBody =
      body.body_type_id !== undefined && body.body_type_id !== null;
    if (hasSprite === hasBody) throw new BadRequestException(NPC_KIND_REQUIRED);
    const sprite = hasSprite ? await this.checkedSprite(body.sprite!) : null;
    if (body.voice_id !== undefined) await this.checkedVoice(body.voice_id);

    let look: AppearanceInput | null = null;
    if (hasBody) {
      look = defaultAppearance(
        body.body_type_id!,
        await appearanceCatalog(this.prisma),
      );
      if (!look) throw new BadRequestException(BODY_NOT_FOUND);
    }
    const taken = await this.prisma.npc.findMany({ select: { slug: true } });
    const slug = npcSlug(fields.name, new Set(taken.map((row) => row.slug)));
    const created = await this.prisma.$transaction(async (tx) => {
      const npc = await tx.npc.create({
        data: {
          slug,
          ...fields,
          sprite,
          bodyTypeId: look?.bodyTypeId ?? null,
          skinPaletteId: look?.skinPaletteId ?? null,
          ...(body.voice_id !== undefined ? { voiceId: body.voice_id } : {}),
        },
      });
      if (look) {
        const slots = await tx.appearancePart.findMany({
          where: { id: { in: look.parts.map(({ partId }) => partId) } },
          select: { id: true, appearanceSlotId: true },
        });
        await tx.npcAppearancePart.createMany({
          data: look.parts.map(({ partId, paletteId }) => ({
            npcId: npc.id,
            appearanceSlotId: slots.find(({ id }) => id === partId)!
              .appearanceSlotId,
            appearancePartId: partId,
            paletteId,
          })),
        });
      }
      return npc;
    });
    this.bundle.invalidate();
    return npcRow(created);
  }

  /** Troca o nome, a descrição, a fala padrão e, de um NPC Ecobeast, a espécie. */
  async update(id: number, body: NpcUpdateBodyDto): Promise<NpcRowDto> {
    const npc = await this.found(id);
    const fields = this.checkedFields(body);
    let sprite = npc.sprite;
    if (body.sprite !== undefined && body.sprite !== null) {
      if (npc.sprite === null) throw new BadRequestException(NPC_IS_PERSON);
      sprite = await this.checkedSprite(body.sprite);
    }
    const updated = await this.prisma.npc.update({
      where: { id },
      data: { ...fields, sprite },
    });
    this.bundle.invalidate();
    return npcRow(updated);
  }

  /** Apaga um NPC que não está em uso; em uso, diz onde. */
  async remove(id: number): Promise<NpcDeleteResponseDto> {
    await this.found(id);
    const [islandNpcs, interiorNpcs, givenQuests, targetQuests, tamer] =
      await Promise.all([
        this.prisma.islandNpc.findMany({
          where: { npcId: id },
          select: {
            islandMap: { select: { islandId: true, name: true, kind: true } },
          },
        }),
        this.prisma.interiorNpc.findMany({
          where: { npcId: id },
          select: { interior: { select: { name: true } } },
        }),
        this.prisma.quest.count({ where: { npcId: id } }),
        this.prisma.quest.count({ where: { targetNpcId: id } }),
        this.prisma.tamer.findUnique({
          where: { npcId: id },
          select: { id: true },
        }),
      ]);
    const usage = npcUsageText({
      islandMaps: islandNpcs.map(({ islandMap }) => islandMap),
      interiors: interiorNpcs.map(({ interior }) => interior.name),
      givenQuests,
      targetQuests,
      tamer: tamer !== null,
    });
    if (usage) throw new ConflictException(usage);
    await this.prisma.npc.delete({ where: { id } });
    this.bundle.invalidate();
    return { id };
  }

  private async found(id: number) {
    const npc =
      id >= 1 && id <= MAX_ID
        ? await this.prisma.npc.findUnique({ where: { id } })
        : null;
    if (!npc) throw new NotFoundException(NPC_NOT_FOUND);
    return npc;
  }

  private checkedFields(body: NpcUpdateBodyDto) {
    const name = body.name.trim();
    if (name.length === 0 || name.length > MAX_NPC_NAME) {
      throw new BadRequestException(NPC_NAME_SIZE);
    }
    const description = body.description.trim();
    if (description.length > MAX_NPC_DESCRIPTION) {
      throw new BadRequestException(NPC_DESCRIPTION_SIZE);
    }
    if (body.default_dialogue.length > MAX_NPC_DIALOGUE) {
      throw new BadRequestException(NPC_DIALOGUE_SIZE);
    }
    return { name, description, defaultDialogue: body.default_dialogue };
  }

  private async checkedSprite(sprite: string): Promise<string> {
    const species = await this.prisma.species.findUnique({
      where: { slug: sprite },
      select: { slug: true },
    });
    if (!species) throw new BadRequestException(SPRITE_NOT_FOUND);
    return species.slug;
  }

  private async checkedVoice(voiceId: number): Promise<void> {
    const voice =
      voiceId >= 1 && voiceId <= MAX_ID
        ? await this.prisma.voice.findUnique({
            where: { id: voiceId },
            select: { id: true },
          })
        : null;
    if (!voice) throw new BadRequestException(VOICE_NOT_FOUND);
  }
}

async function appearanceCatalog(
  prisma: PrismaService,
): Promise<AppearanceCatalog> {
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
  return {
    bodies,
    slots,
    parts: parts.map(({ appearanceSlotId, ...part }) => ({
      ...part,
      slotId: appearanceSlotId,
    })),
    palettes,
  };
}

function npcRow(npc: {
  id: number;
  slug: string;
  name: string;
  description: string;
  sprite: string | null;
  bodyTypeId: number | null;
  skinPaletteId: number | null;
  voiceId: number;
  defaultDialogue: string;
}): NpcRowDto {
  return {
    id: npc.id,
    slug: npc.slug,
    name: npc.name,
    description: npc.description,
    sprite: npc.sprite,
    body_type_id: npc.bodyTypeId,
    skin_palette_id: npc.skinPaletteId,
    voice_id: npc.voiceId,
    default_dialogue: npc.defaultDialogue,
  };
}
