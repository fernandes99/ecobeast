import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { BattleStore } from '../battle/battle.store.js';
import { resolveItem } from '../domain/items/use-item.js';
import { Prisma } from '../generated/prisma/client.js';
import { PlayerDto } from '../player/player.dto.js';
import { creatureStats, PLAYER_INCLUDE } from '../player/player.mapper.js';
import { CREATURE_NOT_FOUND, PlayerService } from '../player/player.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { INVALID_ITEM } from './inventory.dto.js';

export const NO_PLAYER = 'Crie seu Domador primeiro.';
export const NOT_ENOUGH_COINS = 'Moedas insuficientes.';
export const NO_ITEM = 'Você não tem esse item.';
/** O maior `id` que o banco guarda: acima dele, o Prisma daria erro. */
const MAX_ITEM_ID = 2_147_483_647;

/** A Loja e a Mochila do jogador (.specs/inventory-shop/architecture.md). */
@Injectable()
export class InventoryService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly players: PlayerService,
    private readonly battles: BattleStore,
  ) {}

  /**
   * O `coins >= price` fica no próprio `update`: de dois pedidos ao mesmo tempo,
   * o segundo espera o primeiro e encontra o saldo já descontado.
   */
  async buy(userId: string, itemId: number): Promise<PlayerDto> {
    await this.requireTeam(userId);
    const { price } = await this.findItem(itemId);

    await this.prisma.$transaction(async (tx) => {
      const { count } = await tx.player.updateMany({
        where: { id: userId, coins: { gte: price } },
        data: { coins: { decrement: price } },
      });
      if (count === 0) throw new ConflictException(NOT_ENOUGH_COINS);
      await tx.inventoryItem.upsert({
        where: { playerId_itemId: { playerId: userId, itemId } },
        create: { playerId: userId, itemId, quantity: 1 },
        update: { quantity: { increment: 1 } },
      });
    });
    return (await this.players.get(userId))!;
  }

  /**
   * Usa um item fora da luta. A batalha aberta sai antes da escrita: se
   * terminasse depois, gravaria o HP antigo por cima.
   */
  async use(
    userId: string,
    itemId: number,
    creatureUid: string,
  ): Promise<PlayerDto> {
    const player = await this.prisma.player.findUnique({
      where: { id: userId },
      include: PLAYER_INCLUDE,
    });
    if (!player || player.creatures.length === 0) {
      throw new ConflictException(NO_PLAYER);
    }
    const item = await this.findItem(itemId);
    const creature = player.creatures.find(({ uid }) => uid === creatureUid);
    if (!creature) throw new NotFoundException(CREATURE_NOT_FOUND);
    if (!player.inventory.some((slot) => slot.itemId === itemId)) {
      throw new ConflictException(NO_ITEM);
    }
    const effect = resolveItem(item, {
      currentHp: creature.currentHp,
      maxHp: creatureStats(creature).hp,
      hasStatus: creature.statusConditionId !== null,
    });
    if ('error' in effect) throw new ConflictException(effect.error);

    this.battles.delete(userId);
    await this.prisma.$transaction(async (tx) => {
      await this.spendItem(tx, userId, itemId);
      await tx.creatureInstance.updateMany({
        where: { uid: creature.uid },
        data: {
          currentHp: creature.currentHp + effect.healed,
          ...(effect.curesStatus && { statusConditionId: null }),
        },
      });
    });
    return (await this.players.get(userId))!;
  }

  /** Dois pedidos pela última unidade: o segundo espera e não acha mais nada. */
  private async spendItem(
    tx: Prisma.TransactionClient,
    playerId: string,
    itemId: number,
  ): Promise<void> {
    const { count } = await tx.inventoryItem.updateMany({
      where: { playerId, itemId, quantity: { gt: 1 } },
      data: { quantity: { decrement: 1 } },
    });
    if (count > 0) return;
    const removed = await tx.inventoryItem.deleteMany({
      where: { playerId, itemId, quantity: 1 },
    });
    if (removed.count === 0) throw new ConflictException(NO_ITEM);
  }

  private async requireTeam(userId: string): Promise<void> {
    const player = await this.prisma.player.findUnique({
      where: { id: userId },
      select: { _count: { select: { creatures: true } } },
    });
    if (!player || player._count.creatures === 0) {
      throw new ConflictException(NO_PLAYER);
    }
  }

  private async findItem(itemId: number) {
    const item =
      itemId <= MAX_ITEM_ID
        ? await this.prisma.item.findUnique({ where: { id: itemId } })
        : null;
    if (!item) throw new BadRequestException(INVALID_ITEM);
    return item;
  }
}
