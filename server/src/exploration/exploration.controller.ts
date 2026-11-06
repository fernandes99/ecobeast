import { Body, Controller, Delete, Post, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiConflictResponse,
  ApiBadRequestResponse,
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
import { INVALID_ENEMY, NO_EXPLORATION } from '../battle/battle.dto.js';
import {
  DebugClearResponseDto,
  DebugSpawnBodyDto,
  DebugSpawnResponseDto,
  ExplorationResponseDto,
} from './exploration.dto.js';
import { ExplorationService, NO_PLAYER } from './exploration.service.js';

const CLOSED =
  '`ENABLE_TEST_BATTLE` desligada, ou sem exploração: "' + NO_EXPLORATION + '"';

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

  @Post('spawns')
  @ApiOperation({
    summary: 'Spawn de depuração',
    description:
      'Põe um Ecobeast da espécie escolhida num hexágono da exploração guardada, ' +
      'para Procurar enfrentá-lo. Sem `level`, usa a média de nível da equipe. ' +
      'A rota só existe com `ENABLE_TEST_BATTLE` ligada.',
  })
  @ApiCreatedResponse({ type: DebugSpawnResponseDto })
  @ApiBadRequestResponse({
    description: `Espécie que não existe ou nível fora de 1 a 100: "${INVALID_ENEMY}"`,
  })
  @ApiNotFoundResponse({ description: CLOSED })
  debugSpawn(
    @CurrentUser() userId: string,
    @Body() body: DebugSpawnBodyDto,
  ): Promise<DebugSpawnResponseDto> {
    return this.exploration.debugSpawn(userId, body);
  }

  @Delete('spawns')
  @ApiOperation({
    summary: 'Remover os Ecobeasts do spawn de depuração',
    description:
      'Tira da exploração todos os Ecobeasts postos pelo spawn de depuração, e só ' +
      'eles. A rota só existe com `ENABLE_TEST_BATTLE` ligada.',
  })
  @ApiOkResponse({ type: DebugClearResponseDto })
  @ApiNotFoundResponse({ description: CLOSED })
  debugClear(@CurrentUser() userId: string): DebugClearResponseDto {
    return this.exploration.debugClear(userId);
  }
}
