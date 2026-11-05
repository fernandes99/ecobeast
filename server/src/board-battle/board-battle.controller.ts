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
  INVALID_ACTION,
  INVALID_ENEMY,
  INVALID_POSITION,
  NO_EXPLORATION,
  NOTHING_HERE,
  StartWildBodyDto,
  UNREACHABLE,
} from '../battle/battle.dto.js';
import { NO_BATTLE } from '../battle/battle.service.js';
import {
  BoardBattleResponseDto,
  BoardVezBodyDto,
  StartBoardBattleBodyDto,
} from './board-battle.dto.js';
import { toBoardInput } from './board-battle.mapper.js';
import { BoardBattleService } from './board-battle.service.js';

const NO_TEAM_RESPONSES =
  'Sem Domador ou sem equipe: "Crie seu Domador primeiro." ' +
  'Sem nenhum Ecobeast com HP: "Cure sua equipe no Refúgio."';

/** A luta no tabuleiro do jogador (.specs/board-battle/03-board-api.md). */
@ApiTags('Luta no tabuleiro')
@ApiBearerAuth()
@ApiUnauthorizedResponse({
  description: 'Sem sessão, ou sessão inválida ou vencida.',
})
@ApiTooManyRequestsResponse({
  description: 'Limite de chamadas por minuto excedido.',
})
@UseGuards(AuthGuard)
@Controller('me/board-battle')
export class BoardBattleController {
  constructor(private readonly battles: BoardBattleService) {}

  @Post()
  @ApiOperation({
    summary: 'Começar uma luta de teste no tabuleiro',
    description:
      'Começa uma luta no tabuleiro contra a equipe de `enemies`, com `slots` ' +
      'vagas de cada lado. A rota só existe com `ENABLE_TEST_BATTLE` ligada. ' +
      'Uma luta em andamento, de qualquer tipo, é descartada, sem gravar nada.',
  })
  @ApiCreatedResponse({ type: BoardBattleResponseDto })
  @ApiBadRequestResponse({
    description: `Espécie, nível ou vagas inválidos: "${INVALID_ENEMY}"`,
  })
  @ApiNotFoundResponse({ description: '`ENABLE_TEST_BATTLE` desligada.' })
  @ApiConflictResponse({ description: NO_TEAM_RESPONSES })
  start(
    @CurrentUser() userId: string,
    @Body() body: StartBoardBattleBodyDto,
  ): Promise<BoardBattleResponseDto> {
    return this.battles.start(
      userId,
      body.enemies.map(({ species_id, level }) => ({
        speciesId: species_id,
        level,
      })),
      body.slots ?? 1,
    );
  }

  @Post('wild')
  @ApiOperation({
    summary: 'Começar um encontro selvagem no tabuleiro',
    description:
      'Como `POST /v1/me/battle/wild`, com a luta no tabuleiro e 1 vaga: o ' +
      'Ecobeast sai do hexágono do Domador, e `spawn_id` diz qual foi. ' +
      'Uma luta em andamento, de qualquer tipo, é descartada, sem gravar nada.',
  })
  @ApiCreatedResponse({ type: BoardBattleResponseDto })
  @ApiBadRequestResponse({
    description: `Corpo malformado: "${INVALID_POSITION}"`,
  })
  @ApiNotFoundResponse({ description: `Sem exploração: "${NO_EXPLORATION}"` })
  @ApiConflictResponse({
    description:
      `${NO_TEAM_RESPONSES} Longe demais para o tempo que passou: "${UNREACHABLE}" ` +
      `Nenhum Ecobeast no hexágono: "${NOTHING_HERE}"`,
  })
  startWild(
    @CurrentUser() userId: string,
    @Body() body: StartWildBodyDto,
  ): Promise<BoardBattleResponseDto> {
    return this.battles.startWild(
      userId,
      { q: body.q, r: body.r },
      body.god === true,
    );
  }

  @Post('action')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Jogar a vez no tabuleiro',
    description:
      'No `choose_action`, a vez do Ecobeast do jogador que é o primeiro da ' +
      'fila: `position`, `move` (opcional, até 3 hexágonos livres) e `action`. ' +
      'No `choose_next`, `entries`: quem entra em cada vaga e em qual dos ' +
      '`entry_cells`. O servidor joga as vezes dos selvagens até a próxima vez ' +
      'do jogador, e a resposta traz todos os eventos. Quando `phase` é ' +
      '`ended`, a equipe, os itens, as moedas e os capturados já estão gravados.',
  })
  @ApiOkResponse({ type: BoardBattleResponseDto })
  @ApiBadRequestResponse({
    description:
      `Corpo malformado: "${INVALID_ACTION}" Vez recusada: o motivo em pt-BR, ` +
      'como "Não dá para chegar lá." ou "Esse hexágono está fora do alcance."',
  })
  @ApiNotFoundResponse({
    description: `Sem luta no tabuleiro: "${NO_BATTLE}"`,
  })
  act(
    @CurrentUser() userId: string,
    @Body() body: BoardVezBodyDto,
  ): Promise<BoardBattleResponseDto> {
    return this.battles.act(userId, toBoardInput(body));
  }
}
