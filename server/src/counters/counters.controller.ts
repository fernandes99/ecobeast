import {
  Body,
  Controller,
  Get,
  HttpCode,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
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
import {
  CountersPingDto,
  CountersResponseDto,
  INVALID_PING,
} from './counters.dto.js';
import { CountersService, NO_PLAYER } from './counters.service.js';

@ApiTags('Contadores')
@ApiBearerAuth()
@ApiUnauthorizedResponse({
  description: 'Sem sessão, ou sessão inválida ou vencida.',
})
@ApiTooManyRequestsResponse({
  description: 'Limite de chamadas por minuto excedido.',
})
@UseGuards(AuthGuard)
@Controller('me/counters')
export class CountersController {
  constructor(private readonly counters: CountersService) {}

  @Get()
  @ApiOperation({
    summary: 'Ler os contadores do Domador',
    description:
      'Os números do Perfil, contados pelo servidor no fim de cada luta, na ' +
      'Loja, no Refúgio, ao explorar e no sinal de cada minuto. Os nomes e o ' +
      'recorte de cada contador estão no catálogo `counters`.',
  })
  @ApiOkResponse({ type: CountersResponseDto })
  @ApiNotFoundResponse({ description: `Sem Domador: "${NO_PLAYER}"` })
  async read(@CurrentUser() userId: string): Promise<CountersResponseDto> {
    const view = await this.counters.read(userId);
    return {
      counters: view.counters.map(({ counterId, subjectId, value }) => ({
        counter_id: counterId,
        subject_id: subjectId,
        value,
      })),
      partner: view.partner && {
        creature_uid: view.partner.creatureUid,
        species_id: view.partner.speciesId,
        battles: view.partner.battles,
      },
      created_at: view.createdAt.toISOString(),
      walkable_biomes: view.walkableBiomes,
    };
  }

  @Post('ping')
  @HttpCode(204)
  @ApiOperation({
    summary: 'Sinal de cada minuto',
    description:
      'O jogo manda a cada minuto com o app na frente, ao ir para o fundo e ao ' +
      'sair de Explorar. Soma o tempo desde o sinal anterior (nada se passou de ' +
      '90 s), conta o dia de jogo e os dias seguidos na hora de Brasília e os ' +
      'hexágonos andados por bioma. Os hexágonos só contam com uma exploração ' +
      'aberta, dos biomas do mapa dela, e no máximo um por passo mínimo do ' +
      'Domador desde o último crédito.',
  })
  @ApiNoContentResponse({ description: 'Sinal contado.' })
  @ApiBadRequestResponse({
    description: `\`hexes\` inválida: "${INVALID_PING}"`,
  })
  @ApiNotFoundResponse({ description: `Sem Domador: "${NO_PLAYER}"` })
  async ping(
    @CurrentUser() userId: string,
    @Body() body: CountersPingDto,
  ): Promise<void> {
    await this.counters.ping(userId, body.hexes);
  }
}
