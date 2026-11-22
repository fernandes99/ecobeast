import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  checkQuestDraft,
  type QuestInput,
} from '../domain/quests/quest-input.js';
import {
  dialoguesFromRows,
  dialogueWrites,
  parseDialogues,
  parseOfferScene,
  type DialogueStepWrite,
  type QuestDialogues,
} from '../domain/quests/quest-dialogue.js';
import { QUEST_TYPES, questTitle } from '../domain/quests/quests.js';
import type { Prisma } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import type {
  QuestEditorBodyDto,
  QuestEditorDto,
  QuestsEditorResponseDto,
} from './quests-editor.dto.js';
import { INVALID_REQUIRED } from './quests-editor.dto.js';

export const ISLAND_NOT_FOUND = 'Ilha não encontrada.';
export const QUEST_NOT_FOUND = 'Missão não encontrada.';
export const NPC_MISSING = 'Escolha o NPC que dá a missão.';
export const TARGET_MISSING = 'Esse NPC alvo não existe.';
export const NOT_ISLAND_TAMER = 'Esse NPC não é um Domador desta ilha.';
export const SPECIES_MISSING = 'Essa espécie não existe.';
export const ITEM_MISSING = 'Esse item não existe.';
export const TILE_OUTSIDE = 'Um hexágono do lugar está fora da ilha.';

const DRAFT = 'draft';
const TRANSACTION = { maxWait: 10_000, timeout: 60_000 };
const PUBLISHED = 'published';

const QUEST_INCLUDE = {
  tiles: {
    select: { q: true, r: true },
    orderBy: [{ q: 'asc' as const }, { r: 'asc' as const }],
  },
  species: { select: { name: true } },
  targetNpc: { select: { name: true } },
  targetItem: { select: { name: true } },
  dialogue: { include: { options: true } },
} satisfies Prisma.QuestInclude;

/** A missão conferida, com as conversas e a cena do início. */
interface CheckedQuest {
  quest: QuestInput;
  dialogues: QuestDialogues;
  offerScene: string | null;
}

/** Os passos como escrita aninhada do Prisma: as opções levam as respostas. */
function stepCreates(
  questId: number,
  writes: DialogueStepWrite[],
): Prisma.QuestDialogueStepCreateWithoutOptionInput[] {
  return writes.map(({ options, ...step }) => ({
    ...step,
    quest: { connect: { id: questId } },
    options: {
      create: options.map(({ steps, ...option }) => ({
        ...option,
        steps: { create: stepCreates(questId, steps) },
      })),
    },
  }));
}

/** As missões das ilhas pelo F2 (auralis/07): salvas na hora, fora do rascunho. */
@Injectable()
export class QuestsEditorService {
  constructor(private readonly prisma: PrismaService) {}

  async list(islandId: number): Promise<QuestsEditorResponseDto> {
    const island = await this.prisma.island.findUnique({
      where: { id: islandId },
      select: {
        requiredQuests: true,
        maps: { select: { kind: true, name: true } },
      },
    });
    if (!island) throw new NotFoundException(ISLAND_NOT_FOUND);
    const name =
      island.maps.find(({ kind }) => kind === PUBLISHED)?.name ??
      island.maps.find(({ kind }) => kind === DRAFT)?.name ??
      '';
    const [types, quests] = await Promise.all([
      this.prisma.questType.findMany({ orderBy: { id: 'asc' } }),
      this.prisma.quest.findMany({
        where: { islandId },
        orderBy: [{ npcId: 'asc' }, { position: 'asc' }],
        include: QUEST_INCLUDE,
      }),
    ]);
    return {
      required_quests: island.requiredQuests,
      types: types.map(({ id, slug, name: typeName, description }) => ({
        id,
        slug,
        name: typeName,
        description,
      })),
      quests: quests.map((quest): QuestEditorDto => ({
        id: quest.id,
        npc_id: quest.npcId,
        position: quest.position,
        quest_type_id: quest.questTypeId,
        amount: quest.amount,
        species_id: quest.speciesId,
        target_npc_id: quest.targetNpcId,
        target_item_id: quest.targetItemId,
        place_name: quest.placeName,
        title: quest.title,
        coins: quest.coins,
        item_id: quest.itemId,
        item_quantity: quest.itemQuantity,
        counts_for_unlock: quest.countsForUnlock,
        tiles: quest.tiles,
        display_title: questTitle(quest, {
          island: name,
          species: quest.species?.name ?? null,
          targetNpc: quest.targetNpc?.name ?? null,
          targetItem: quest.targetItem?.name ?? null,
        }),
        dialogues: dialoguesFromRows(
          quest.dialogue,
          quest.dialogue.flatMap(({ options }) => options),
        ),
        offer_scene: quest.offerScene,
      })),
    };
  }

  async create(
    islandId: number,
    body: QuestEditorBodyDto,
  ): Promise<QuestsEditorResponseDto> {
    await this.requireIsland(islandId);
    const checked = await this.checked(islandId, body);
    const position = await this.nextPosition(islandId, body.npc_id);
    await this.prisma.$transaction(async (tx) => {
      const { id } = await tx.quest.create({
        data: {
          ...this.columns(checked),
          islandId,
          npcId: body.npc_id,
          position,
          tiles: { create: checked.quest.tiles },
        },
        select: { id: true },
      });
      await this.writeDialogues(tx, id, checked.dialogues);
    }, TRANSACTION);
    return this.list(islandId);
  }

  async update(
    id: number,
    body: QuestEditorBodyDto,
  ): Promise<QuestsEditorResponseDto> {
    const current = await this.findQuest(id);
    const checked = await this.checked(current.islandId, body);
    const position =
      body.npc_id === current.npcId
        ? current.position
        : await this.nextPosition(current.islandId, body.npc_id);
    await this.prisma.$transaction(async (tx) => {
      await tx.questTile.deleteMany({ where: { questId: id } });
      await tx.questDialogueStep.deleteMany({ where: { questId: id } });
      await tx.quest.update({
        where: { id },
        data: {
          ...this.columns(checked),
          npcId: body.npc_id,
          position,
          tiles: { create: checked.quest.tiles },
        },
      });
      await this.writeDialogues(tx, id, checked.dialogues);
    }, TRANSACTION);
    return this.list(current.islandId);
  }

  async remove(id: number): Promise<QuestsEditorResponseDto> {
    const current = await this.findQuest(id);
    await this.prisma.quest.delete({ where: { id } });
    return this.list(current.islandId);
  }

  /** Troca a posição com a vizinha da fila; a do meio evita o índice único. */
  async move(
    id: number,
    direction: 'up' | 'down',
  ): Promise<QuestsEditorResponseDto> {
    const current = await this.findQuest(id);
    const neighbor = await this.prisma.quest.findFirst({
      where: {
        islandId: current.islandId,
        npcId: current.npcId,
        position:
          direction === 'up'
            ? { lt: current.position }
            : { gt: current.position },
      },
      orderBy: { position: direction === 'up' ? 'desc' : 'asc' },
      select: { id: true, position: true },
    });
    if (neighbor) {
      const spare = await this.nextPosition(current.islandId, current.npcId);
      await this.prisma.$transaction([
        this.prisma.quest.update({ where: { id }, data: { position: spare } }),
        this.prisma.quest.update({
          where: { id: neighbor.id },
          data: { position: current.position },
        }),
        this.prisma.quest.update({
          where: { id },
          data: { position: neighbor.position },
        }),
      ]);
    }
    return this.list(current.islandId);
  }

  async setRequired(
    islandId: number,
    required: number | null,
  ): Promise<QuestsEditorResponseDto> {
    if (required !== null && required < 1) {
      throw new BadRequestException(INVALID_REQUIRED);
    }
    await this.requireIsland(islandId);
    await this.prisma.island.update({
      where: { id: islandId },
      data: { requiredQuests: required },
    });
    return this.list(islandId);
  }

  private async writeDialogues(
    tx: Prisma.TransactionClient,
    questId: number,
    dialogues: QuestDialogues,
  ): Promise<void> {
    for (const data of stepCreates(questId, dialogueWrites(dialogues))) {
      await tx.questDialogueStep.create({ data, select: { id: true } });
    }
  }

  private columns({ quest, offerScene }: CheckedQuest) {
    return {
      offerScene,
      questTypeId: quest.questTypeId,
      amount: quest.amount,
      speciesId: quest.speciesId,
      targetNpcId: quest.targetNpcId,
      targetItemId: quest.targetItemId,
      placeName: quest.placeName,
      title: quest.title,
      coins: quest.coins,
      itemId: quest.itemId,
      itemQuantity: quest.itemQuantity,
      countsForUnlock: quest.countsForUnlock,
    };
  }

  /** A conferência pura e a do banco: o que a missão cita precisa existir. */
  private async checked(
    islandId: number,
    body: QuestEditorBodyDto,
  ): Promise<CheckedQuest> {
    const dialogues = parseDialogues(body.dialogues);
    if ('error' in dialogues) throw new BadRequestException(dialogues.error);
    const scene = parseOfferScene(body.offer_scene);
    if ('error' in scene) throw new BadRequestException(scene.error);
    const result = checkQuestDraft({
      questTypeId: body.quest_type_id,
      amount: body.amount ?? null,
      speciesId: body.species_id ?? null,
      targetNpcId: body.target_npc_id ?? null,
      targetItemId: body.target_item_id ?? null,
      placeName: body.place_name ?? null,
      title: body.title ?? null,
      coins: body.coins ?? null,
      itemId: body.item_id ?? null,
      itemQuantity: body.item_quantity ?? null,
      countsForUnlock: body.counts_for_unlock ?? null,
      tiles: body.tiles ?? null,
    });
    if ('error' in result) throw new BadRequestException(result.error);
    const quest = result.quest;
    const [giver, target, species, item, targetItem, tiles] = await Promise.all(
      [
        this.prisma.npc.findUnique({
          where: { id: body.npc_id },
          select: { id: true },
        }),
        quest.targetNpcId === null
          ? null
          : this.prisma.npc.findUnique({
              where: { id: quest.targetNpcId },
              select: { tamer: { select: { islandId: true } } },
            }),
        quest.speciesId === null
          ? null
          : this.prisma.species.findUnique({
              where: { id: quest.speciesId },
              select: { id: true },
            }),
        quest.itemId === null
          ? null
          : this.prisma.item.findUnique({
              where: { id: quest.itemId },
              select: { id: true },
            }),
        quest.targetItemId === null
          ? null
          : this.prisma.item.findUnique({
              where: { id: quest.targetItemId },
              select: { id: true },
            }),
        quest.tiles.length === 0
          ? 0
          : this.prisma.islandTile.count({
              where: {
                islandMap: { islandId, kind: DRAFT },
                OR: quest.tiles.map(({ q, r }) => ({ q, r })),
              },
            }),
      ],
    );
    if (!giver) throw new BadRequestException(NPC_MISSING);
    if (quest.targetNpcId !== null && !target) {
      throw new BadRequestException(TARGET_MISSING);
    }
    if (
      quest.questTypeId === QUEST_TYPES.defeat_tamer &&
      target?.tamer?.islandId !== islandId
    ) {
      throw new BadRequestException(NOT_ISLAND_TAMER);
    }
    if (quest.speciesId !== null && !species) {
      throw new BadRequestException(SPECIES_MISSING);
    }
    if (quest.itemId !== null && !item) {
      throw new BadRequestException(ITEM_MISSING);
    }
    if (quest.targetItemId !== null && !targetItem) {
      throw new BadRequestException(ITEM_MISSING);
    }
    if (tiles !== quest.tiles.length)
      throw new BadRequestException(TILE_OUTSIDE);
    return { quest, dialogues: dialogues.dialogues, offerScene: scene.scene };
  }

  private async nextPosition(islandId: number, npcId: number): Promise<number> {
    const last = await this.prisma.quest.aggregate({
      where: { islandId, npcId },
      _max: { position: true },
    });
    return (last._max.position ?? 0) + 1;
  }

  private async requireIsland(islandId: number): Promise<void> {
    const island = await this.prisma.island.findUnique({
      where: { id: islandId },
      select: { id: true },
    });
    if (!island) throw new NotFoundException(ISLAND_NOT_FOUND);
  }

  private async findQuest(id: number) {
    const quest = await this.prisma.quest.findUnique({
      where: { id },
      select: { islandId: true, npcId: true, position: true },
    });
    if (!quest) throw new NotFoundException(QUEST_NOT_FOUND);
    return quest;
  }
}
