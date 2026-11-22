import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  availableGroundItems,
  foundLine,
} from '../domain/islands/ground-items.js';
import type { DraftItem } from '../domain/islands/island-draft.js';
import { ExplorationStore } from '../exploration/exploration.store.js';
import { Prisma } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { itemQuestWrite } from '../quests/item-quests.js';

export const NO_EXPLORATION = 'Essa exploração acabou. Saia e entre de novo.';
export const NOT_ON_ISLAND = 'Itens no chão só numa ilha.';
export const ITEM_GONE = 'Esse item não está mais aqui.';
export const TOO_FAR = 'Você não chegou até o item.';

const PUBLISHED = 'published';
const UNIQUE_VIOLATION = 'P2002';

export interface PickResult {
  itemId: number;
  quantity: number;
  line: string;
}

/** Os itens no chão das ilhas (auralis/09). */
@Injectable()
export class GroundItemsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly explorations: ExplorationStore,
  ) {}

  /** Os itens da versão publicada que o Domador ainda pode pegar, ao entrar. */
  async available(
    userId: string,
    islandId: number,
    items: readonly DraftItem[],
  ): Promise<DraftItem[]> {
    if (items.length === 0) return [];
    const picked = await this.prisma.playerGroundItem.findMany({
      where: { playerId: userId, islandId },
      select: { itemKey: true },
    });
    return availableGroundItems(
      items,
      new Set(picked.map(({ itemKey }) => itemKey)),
      new Set(),
    );
  }

  /** O Domador pisou no hexágono do item: vai para a Mochila e conta nas missões. */
  async pick(userId: string, key: number): Promise<PickResult> {
    const exploration = this.explorations.get(userId);
    if (!exploration) throw new NotFoundException(NO_EXPLORATION);
    const islandId = exploration.islandId;
    if (islandId === undefined) throw new ConflictException(NOT_ON_ISLAND);
    const item = await this.prisma.islandGroundItem.findFirst({
      where: { key, islandMap: { islandId, kind: PUBLISHED } },
      select: {
        itemId: true,
        q: true,
        r: true,
        quantity: true,
        once: true,
        item: { select: { name: true } },
      },
    });
    const pickedNow = exploration.pickedItemKeys ?? new Set<number>();
    if (!item || (!item.once && pickedNow.has(key))) {
      throw new NotFoundException(ITEM_GONE);
    }
    const confirmed = this.explorations.confirmPosition(userId, {
      q: item.q,
      r: item.r,
    });
    if (confirmed === 'none') throw new NotFoundException(NO_EXPLORATION);
    if (confirmed === 'unreachable') throw new ConflictException(TOO_FAR);
    // O que volta fica marcado antes da escrita, para dois toques não pegarem duas vezes.
    const current = item.once ? undefined : this.explorations.get(userId);
    if (current) {
      current.pickedItemKeys = new Set([
        ...(current.pickedItemKeys ?? []),
        key,
      ]);
    }

    const { itemId, quantity } = item;
    try {
      await this.prisma.$transaction([
        // O "só uma vez" pego antes bate na chave e desfaz tudo.
        ...(item.once
          ? [
              this.prisma.playerGroundItem.create({
                data: { playerId: userId, islandId, itemKey: key },
              }),
            ]
          : []),
        this.prisma.inventoryItem.upsert({
          where: { playerId_itemId: { playerId: userId, itemId } },
          create: { playerId: userId, itemId, quantity },
          update: { quantity: { increment: quantity } },
        }),
        itemQuestWrite(this.prisma, userId, itemId, quantity),
      ]);
    } catch (error) {
      current?.pickedItemKeys?.delete(key);
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === UNIQUE_VIOLATION
      ) {
        throw new NotFoundException(ITEM_GONE);
      }
      throw error;
    }
    return { itemId, quantity, line: foundLine(quantity, item.item.name) };
  }
}
