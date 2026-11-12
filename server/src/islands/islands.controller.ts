import { Controller, Get, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { AuthGuard } from '../auth/auth.guard.js';
import { PlayerIslandsResponseDto } from './islands.dto.js';
import { IslandsService } from './islands.service.js';

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
  constructor(private readonly islands: IslandsService) {}

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
}
