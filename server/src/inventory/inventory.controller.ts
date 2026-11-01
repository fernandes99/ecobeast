import { Body, Controller, HttpCode, Post, UseGuards } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiConflictResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { AuthGuard } from '../auth/auth.guard.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { PlayerResponseDto } from '../player/player.dto.js';
import { BuyItemBodyDto, INVALID_ITEM } from './inventory.dto.js';
import {
  InventoryService,
  NO_PLAYER,
  NOT_ENOUGH_COINS,
} from './inventory.service.js';

/** A Loja e a Mochila (.specs/inventory-shop/architecture.md). */
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
}
