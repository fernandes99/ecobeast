import { Body, Controller, HttpCode, Post, UseGuards } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiConflictResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { AuthGuard } from '../auth/auth.guard.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { NO_ITEM } from '../domain/items/use-item.js';
import { PlayerResponseDto } from '../player/player.dto.js';
import { CREATURE_NOT_FOUND } from '../player/player.service.js';
import {
  BuyItemBodyDto,
  INVALID_ITEM,
  UseItemBodyDto,
} from './inventory.dto.js';
import {
  InventoryService,
  NO_PLAYER,
  NOT_ENOUGH_COINS,
} from './inventory.service.js';

@ApiTags('Mochila e Loja')
@ApiBearerAuth()
@ApiUnauthorizedResponse({
  description: 'Sem sessão, ou sessão inválida ou vencida.',
})
@ApiTooManyRequestsResponse({
  description: 'Limite de chamadas por minuto excedido.',
})
@UseGuards(AuthGuard)
@Controller('me')
export class InventoryController {
  constructor(private readonly inventory: InventoryService) {}

  @Post('shop/buy')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Comprar um item',
    description:
      'Compra 1 unidade. O preço vem do banco, e o jogador recebe o item na ' +
      'Mochila. Moedas e Mochila mudam juntas: ou as duas, ou nenhuma.',
  })
  @ApiOkResponse({ type: PlayerResponseDto })
  @ApiBadRequestResponse({ description: `Item inválido: "${INVALID_ITEM}"` })
  @ApiConflictResponse({
    description: `Sem Domador ou sem equipe: "${NO_PLAYER}" Sem saldo: "${NOT_ENOUGH_COINS}"`,
  })
  async buy(
    @CurrentUser() userId: string,
    @Body() body: BuyItemBodyDto,
  ): Promise<PlayerResponseDto> {
    return { player: await this.inventory.buy(userId, body.item_id) };
  }

  @Post('items/use')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Usar um item fora da luta',
    description:
      'Usa 1 unidade em um Ecobeast da equipe. Um item sem efeito não é gasto. ' +
      'A batalha aberta é descartada, sem gravar nada dela.',
  })
  @ApiOkResponse({ type: PlayerResponseDto })
  @ApiBadRequestResponse({ description: `Item inválido: "${INVALID_ITEM}"` })
  @ApiNotFoundResponse({
    description: `Fora da equipe do jogador: "${CREATURE_NOT_FOUND}"`,
  })
  @ApiConflictResponse({
    description:
      `Sem Domador ou sem equipe: "${NO_PLAYER}" Sem o item: "${NO_ITEM}" ` +
      'Item recusado: o motivo em pt-BR, como "Não teria efeito."',
  })
  async use(
    @CurrentUser() userId: string,
    @Body() body: UseItemBodyDto,
  ): Promise<PlayerResponseDto> {
    const { item_id: itemId, creature_uid: creatureUid } = body;
    return { player: await this.inventory.use(userId, itemId, creatureUid) };
  }
}
