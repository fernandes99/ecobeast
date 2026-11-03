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

/**
 * O mapa de exploração (.specs/wild-battle/02-map-generator.md) e os Ecobeasts
 * dele (.specs/biome-encounters/03-exploration-session.md).
 */
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
      'Gera um mapa hexagonal novo, com seed sorteada pelo servidor, e sorteia os ' +
      'Ecobeasts dele pelas taxas de cada bioma e pela média de nível da equipe. ' +
      'O servidor guarda os Ecobeasts e a posição do Domador até a próxima ' +
      'exploração. Cada chamada devolve outro mapa.',
  })
  @ApiCreatedResponse({ type: ExplorationResponseDto })
  @ApiConflictResponse({
    description: `Sem Domador ou sem equipe: "${NO_PLAYER}"`,
  })
  start(@CurrentUser() userId: string): Promise<ExplorationResponseDto> {
    return this.exploration.start(userId);
  }
}
