import { Controller, Post, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { AuthGuard } from '../auth/auth.guard.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { ExplorationResponseDto } from './exploration.dto.js';
import { ExplorationService, NO_PLAYER } from './exploration.service.js';

/** O mapa de exploração (.specs/wild-battle/02-map-generator.md). */
@ApiTags('Exploração')
@ApiBearerAuth()
@ApiUnauthorizedResponse({
  description: 'Sem sessão, ou sessão inválida ou vencida.',
})
@ApiTooManyRequestsResponse({
  description: 'Limite de chamadas por minuto excedido.',
})
@UseGuards(AuthGuard)
@Controller('me/exploration')
export class ExplorationController {
  constructor(private readonly exploration: ExplorationService) {}

  @Post()
  @ApiOperation({
    summary: 'Começar uma exploração',
    description:
      'Gera um mapa hexagonal novo, com seed sorteada pelo servidor. O mapa não ' +
      'fica guardado: cada chamada devolve outro.',
  })
  @ApiCreatedResponse({ type: ExplorationResponseDto })
  @ApiConflictResponse({
    description: `Sem Domador ou sem equipe: "${NO_PLAYER}"`,
  })
  start(@CurrentUser() userId: string): Promise<ExplorationResponseDto> {
    return this.exploration.start(userId);
  }
}
