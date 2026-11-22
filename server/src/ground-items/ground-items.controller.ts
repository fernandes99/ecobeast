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
import {
  INVALID_PICK,
  PickGroundItemBodyDto,
  PickGroundItemResponseDto,
} from './ground-items.dto.js';
import {
  GroundItemsService,
  ITEM_GONE,
  NO_EXPLORATION,
  NOT_ON_ISLAND,
  TOO_FAR,
} from './ground-items.service.js';

@ApiTags('Itens no chão')
@ApiBearerAuth()
@ApiUnauthorizedResponse({
  description: 'Sem sessão, ou sessão inválida ou vencida.',
})
@ApiTooManyRequestsResponse({
  description: 'Limite de chamadas por minuto excedido.',
})
@UseGuards(AuthGuard)
@Controller('me/ground-items')
export class GroundItemsController {
  constructor(private readonly groundItems: GroundItemsService) {}

  @Post('pick')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Pega um item no chão da ilha',
    description:
      'O jogo chama ao pisar no hexágono de um item de `ground_items` ' +
      '(auralis/09). O servidor confere que o item está na ilha publicada da ' +
      'exploração e não foi pego (o "só uma vez" pelo Domador, o que volta ' +
      'nesta entrada) e confere o passo até ele, como no Procurar. Então soma ' +
      'a quantidade na Mochila, guarda o "só uma vez" e soma nas missões ' +
      '"Encontre X item" aceitas, numa transação.',
  })
  @ApiOkResponse({ type: PickGroundItemResponseDto })
  @ApiBadRequestResponse({ description: `Sem \`key\`: "${INVALID_PICK}"` })
  @ApiNotFoundResponse({
    description: `Sem exploração: "${NO_EXPLORATION}"; ou o item não existe ou já foi pego: "${ITEM_GONE}"`,
  })
  @ApiConflictResponse({
    description: `Fora de uma ilha: "${NOT_ON_ISLAND}"; ou o passo rápido demais: "${TOO_FAR}"`,
  })
  async pick(
    @CurrentUser() userId: string,
    @Body() body: PickGroundItemBodyDto,
  ): Promise<PickGroundItemResponseDto> {
    const result = await this.groundItems.pick(userId, body.key);
    return {
      item_id: result.itemId,
      quantity: result.quantity,
      line: result.line,
    };
  }
}
