import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { AuthGuard } from '../auth/auth.guard.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { DiscoveriesService } from './discoveries.service.js';
import {
  DiscoveriesAddedDto,
  DiscoveriesBodyDto,
  DiscoveriesRemovedDto,
  INVALID_DISCOVERY,
  MAX_DISCOVERIES,
  PlayerIslandsResponseDto,
} from './islands.dto.js';
import { ISLAND_NOT_FOUND, IslandsService } from './islands.service.js';

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
@UseGuards(AuthGuard)
@Controller('me/islands')
export class IslandsController {
  constructor(
    private readonly islands: IslandsService,
    private readonly discoveries: DiscoveriesService,
  ) {}

  @Get()
  @ApiOperation({
    summary: 'Listar as ilhas',
    description:
      'As ilhas publicadas pelo editor, em ordem de id, com o nome da versão ' +
      'publicada. Todas aparecem para todo jogador, mesmo sem Domador. Para ' +
      'entrar numa, `POST /v1/me/exploration` com `{island_id}`.',
  })
  @ApiOkResponse({ type: PlayerIslandsResponseDto })
  async list(): Promise<PlayerIslandsResponseDto> {
    return { islands: await this.islands.listPublished() };
  }

  @Post(':id/discoveries')
  @ApiOperation({
    summary: 'Gravar hexágonos descobertos',
    description:
      'Grava os hexágonos da ilha que o Domador descobriu andando, para a névoa ' +
      'da próxima entrada começar deles (`discovered` em `POST ' +
      `/v1/me/exploration\`). De 1 a ${MAX_DISCOVERIES} por chamada. Os que não ` +
      'existem na versão publicada da ilha e os já gravados ficam de fora, sem ' +
      'erro. O servidor não confere se o Domador passou perto: a descoberta só ' +
      'muda o que aparece na tela.',
  })
  @ApiCreatedResponse({ type: DiscoveriesAddedDto })
  @ApiBadRequestResponse({
    description:
      `\`id\` que não é inteiro: "${ISLAND_NOT_FOUND}"; \`tiles\` fora de 1 a ` +
      `${MAX_DISCOVERIES} itens ou com \`q\` e \`r\` que não são inteiros: ` +
      `"${INVALID_DISCOVERY}"`,
  })
  @ApiNotFoundResponse({
    description: `A ilha não existe ou nunca foi publicada: "${ISLAND_NOT_FOUND}"`,
  })
  async addDiscoveries(
    @CurrentUser() userId: string,
    @Param('id', islandId) id: number,
    @Body() body: DiscoveriesBodyDto,
  ): Promise<DiscoveriesAddedDto> {
    return { added: await this.discoveries.add(userId, id, body.tiles) };
  }

  @Delete(':id/discoveries')
  @ApiOperation({
    summary: 'Esquecer a ilha (depuração)',
    description:
      'Apaga todos os hexágonos descobertos pelo Domador nesta ilha, para a ' +
      'névoa recomeçar do zero. A rota só existe com `ENABLE_TEST_BATTLE` ligada.',
  })
  @ApiOkResponse({ type: DiscoveriesRemovedDto })
  @ApiBadRequestResponse({
    description: `\`id\` que não é inteiro: "${ISLAND_NOT_FOUND}"`,
  })
  @ApiNotFoundResponse({ description: '`ENABLE_TEST_BATTLE` desligada.' })
  async forgetDiscoveries(
    @CurrentUser() userId: string,
    @Param('id', islandId) id: number,
  ): Promise<DiscoveriesRemovedDto> {
    return { removed: await this.discoveries.forget(userId, id) };
  }
}
