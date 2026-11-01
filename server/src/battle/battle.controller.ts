import { Body, Controller, HttpCode, Post, UseGuards } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiConflictResponse,
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
import {
  BattleActionBodyDto,
  BattleResponseDto,
  INVALID_ACTION,
  INVALID_ENEMY,
  StartBattleBodyDto,
} from './battle.dto.js';
import { toBattleAction } from './battle.mapper.js';
import { BattleService, NO_BATTLE } from './battle.service.js';

const NO_TEAM_RESPONSES =
  'Sem Domador ou sem equipe: "Crie seu Domador primeiro." ' +
  'Sem nenhum Ecobeast com HP: "Cure sua equipe no Refúgio."';

/** A batalha do jogador (.specs/battle-core/03-battle-api.md). */
@ApiTags('Batalha')
@ApiBearerAuth()
@ApiUnauthorizedResponse({
  description: 'Sem sessão, ou sessão inválida ou vencida.',
})
@ApiTooManyRequestsResponse({
  description: 'Limite de chamadas por minuto excedido.',
})
@UseGuards(AuthGuard)
@Controller('me/battle')
export class BattleController {
  constructor(private readonly battles: BattleService) {}

  @Post()
  @ApiOperation({
    summary: 'Começar uma batalha de teste',
    description:
      'Começa uma batalha contra um inimigo selvagem da espécie e do nível dados. ' +
      'A rota só existe com `ENABLE_TEST_BATTLE` ligada. ' +
      'Uma batalha em andamento é descartada, sem gravar nada.',
  })
  @ApiCreatedResponse({ type: BattleResponseDto })
  @ApiBadRequestResponse({
    description: `Espécie ou nível inválido: "${INVALID_ENEMY}"`,
  })
  @ApiNotFoundResponse({ description: '`ENABLE_TEST_BATTLE` desligada.' })
  @ApiConflictResponse({ description: NO_TEAM_RESPONSES })
  start(
    @CurrentUser() userId: string,
    @Body() body: StartBattleBodyDto,
  ): Promise<BattleResponseDto> {
    return this.battles.start(userId, body.species_id, body.level);
  }

  @Post('wild')
  @ApiOperation({
    summary: 'Começar um encontro selvagem',
    description:
      'Começa uma batalha contra um Ecobeast sorteado pelo servidor, com nível ' +
      'perto do Ecobeast que entra em campo. Uma batalha em andamento é ' +
      'descartada, sem gravar nada.',
  })
  @ApiCreatedResponse({ type: BattleResponseDto })
  @ApiConflictResponse({ description: NO_TEAM_RESPONSES })
  startWild(@CurrentUser() userId: string): Promise<BattleResponseDto> {
    return this.battles.startWild(userId);
  }

  @Post('action')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Agir na batalha',
    description:
      'O jogo diz o que o jogador quer fazer, e o servidor decide o resto. ' +
      'A resposta traz o estado e os eventos deste turno. Quando `phase` é ' +
      '`ended`, HP, PP e status da equipe já estão gravados.',
  })
  @ApiOkResponse({ type: BattleResponseDto })
  @ApiBadRequestResponse({
    description: `Corpo malformado: "${INVALID_ACTION}" Ação recusada: o motivo em pt-BR, como "Essa Técnica está sem PP."`,
  })
  @ApiNotFoundResponse({ description: `Sem batalha: "${NO_BATTLE}"` })
  act(
    @CurrentUser() userId: string,
    @Body() body: BattleActionBodyDto,
  ): Promise<BattleResponseDto> {
    return this.battles.act(userId, toBattleAction(body));
  }
}
