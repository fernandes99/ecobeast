import {
  BadRequestException,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseIntPipe,
  Put,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiConflictResponse,
  ApiNoContentResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { AuthGuard } from '../auth/auth.guard.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { ArchipelagoResponseDto } from './archipelago.dto.js';
import {
  ARCHIPELAGO_NO_PLAYER,
  ArchipelagoService,
} from './archipelago.service.js';
import { ISLAND_NOT_FOUND } from './islands.service.js';

const islandId = new ParseIntPipe({
  exceptionFactory: () => new BadRequestException(ISLAND_NOT_FOUND),
});

@ApiTags('Ilhas')
@ApiBearerAuth()
@ApiUnauthorizedResponse({
  description: 'Sem sessão, ou sessão inválida ou vencida.',
})
@ApiTooManyRequestsResponse({
  description: 'Limite de chamadas por minuto excedido.',
})
@ApiConflictResponse({ description: `Sem Domador: "${ARCHIPELAGO_NO_PLAYER}"` })
@UseGuards(AuthGuard)
@Controller('me/archipelago')
export class ArchipelagoController {
  constructor(private readonly archipelago: ArchipelagoService) {}

  @Get()
  @ApiOperation({
    summary: 'Ver o Arquipélago',
    description:
      'As ilhas publicadas do Arquipélago Auralis (`islands.archipelago_order`), ' +
      'em ordem, com o estado de cada uma para o Domador: a 1ª está sempre ' +
      'aberta, as que ele abriu também, a próxima trancada vem com o nome e as ' +
      'outras vêm escondidas, sem id nem nome. Entrar numa ilha trancada dá 403 ' +
      'em `POST /v1/me/exploration`.',
  })
  @ApiOkResponse({ type: ArchipelagoResponseDto })
  async list(@CurrentUser() userId: string): Promise<ArchipelagoResponseDto> {
    return { islands: await this.archipelago.list(userId) };
  }

  @Put(':id/unlock')
  @HttpCode(204)
  @ApiOperation({
    summary: 'Abrir uma ilha (depuração)',
    description:
      'Abre a ilha do Arquipélago para o Domador, sem as condições. Repetir não ' +
      'dá erro. A rota só existe com `ENABLE_TEST_BATTLE` ligada.',
  })
  @ApiNoContentResponse({ description: 'Ilha aberta.' })
  @ApiBadRequestResponse({
    description: `\`id\` que não é inteiro: "${ISLAND_NOT_FOUND}"`,
  })
  @ApiNotFoundResponse({
    description:
      `A ilha não está publicada no Arquipélago: "${ISLAND_NOT_FOUND}"; ou ` +
      '`ENABLE_TEST_BATTLE` desligada.',
  })
  async unlock(
    @CurrentUser() userId: string,
    @Param('id', islandId) id: number,
  ): Promise<void> {
    await this.archipelago.unlock(userId, id);
  }

  @Delete(':id/unlock')
  @HttpCode(204)
  @ApiOperation({
    summary: 'Trancar uma ilha de novo (depuração)',
    description:
      'Fecha a ilha que o Domador abriu. A 1ª do Arquipélago continua aberta. ' +
      'A rota só existe com `ENABLE_TEST_BATTLE` ligada.',
  })
  @ApiNoContentResponse({ description: 'Ilha trancada.' })
  @ApiBadRequestResponse({
    description: `\`id\` que não é inteiro: "${ISLAND_NOT_FOUND}"`,
  })
  @ApiNotFoundResponse({
    description:
      `A ilha não está publicada no Arquipélago: "${ISLAND_NOT_FOUND}"; ou ` +
      '`ENABLE_TEST_BATTLE` desligada.',
  })
  async relock(
    @CurrentUser() userId: string,
    @Param('id', islandId) id: number,
  ): Promise<void> {
    await this.archipelago.relock(userId, id);
  }
}
