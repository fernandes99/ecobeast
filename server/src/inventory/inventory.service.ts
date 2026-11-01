import {
  BadRequestException,
  ConflictException,
  Injectable,
} from '@nestjs/common';
import { PlayerDto } from '../player/player.dto.js';
import { PlayerService } from '../player/player.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { INVALID_ITEM } from './inventory.dto.js';

export const NO_PLAYER = 'Crie seu Domador primeiro.';
export const NOT_ENOUGH_COINS = 'Moedas insuficientes.';
/** O maior `id` que o banco guarda: acima dele, o Prisma daria erro. */
const MAX_ITEM_ID = 2_147_483_647;

/** A Loja e a Mochila do jogador (.specs/inventory-shop/architecture.md). */
@Injectable()
export class InventoryService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly players: PlayerService,
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
