import { Controller, Get, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { AuthGuard } from '../auth/auth.guard.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { CountersResponseDto } from './counters.dto.js';
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
}
