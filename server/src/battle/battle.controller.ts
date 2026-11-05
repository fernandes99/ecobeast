import {
  BadRequestException,
  Body,
  Controller,
  HttpCode,
  Post,
  UseGuards,
} from '@nestjs/common';
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
  ENEMIES_OR_SPECIES,
  INVALID_ACTION,
  INVALID_ENEMY,
  INVALID_POSITION,
  NO_EXPLORATION,
  NOTHING_HERE,
  StartBattleBodyDto,
  StartWildBodyDto,
  UNREACHABLE,
} from './battle.dto.js';
import { toBattleActions } from './battle.mapper.js';
import { BattleService, NO_BATTLE } from './battle.service.js';

const NO_TEAM_RESPONSES =
  'Sem Domador ou sem equipe: "Crie seu Domador primeiro." ' +
  'Sem nenhum Ecobeast com HP: "Cure sua equipe no Refúgio."';

const LEGACY =
  'Legado: nenhuma tela do jogo usa esta rota. A luta de Explorar zona é a do ' +
  'tabuleiro, em `/v1/me/board-battle`. ';

/**
 * A batalha do jogador (.specs/battle-core/03-battle-api.md). Legado: nenhuma
 * tela abre mais esta luta, e Explorar zona usa a do tabuleiro
 * (board-battle/05, RF-07). Fica até o dono pedir para apagar.
 */
@ApiTags('Batalha (legado)')
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
    deprecated: true,
    description:
      LEGACY +
      'Começa uma batalha contra um inimigo selvagem da espécie e do nível dados, ' +
      'ou contra a equipe de `enemies`, com `slots` vagas de cada lado. ' +
      'A rota só existe com `ENABLE_TEST_BATTLE` ligada. ' +
      'Uma batalha em andamento é descartada, sem gravar nada.',
  })
  @ApiCreatedResponse({ type: BattleResponseDto })
  @ApiBadRequestResponse({
    description: `Espécie, nível ou vagas inválidos: "${INVALID_ENEMY}" Os dois jeitos juntos: "${ENEMIES_OR_SPECIES}"`,
  })
  @ApiNotFoundResponse({ description: '`ENABLE_TEST_BATTLE` desligada.' })
  @ApiConflictResponse({ description: NO_TEAM_RESPONSES })
  start(
    @CurrentUser() userId: string,
    @Body() body: StartBattleBodyDto,
  ): Promise<BattleResponseDto> {
    if (body.enemies && body.species_id !== undefined) {
      throw new BadRequestException(ENEMIES_OR_SPECIES);
    }
    const enemies = body.enemies ?? [
      { species_id: body.species_id!, level: body.level! },
    ];
    return this.battles.start(
      userId,
      enemies.map(({ species_id, level }) => ({
        speciesId: species_id,
        level,
      })),
      body.slots ?? 1,
    );
  }

  @Post('wild')
  @ApiOperation({
    summary: 'Começar um encontro selvagem',
    deprecated: true,
    description:
      LEGACY +
      'Começa uma batalha contra um Ecobeast do hexágono do Domador, escolhido ao ' +
      'acaso entre os que estão lá. O servidor confere se dava para chegar até a ' +
      'posição andando. O Ecobeast sai do mapa aqui, e `spawn_id` diz qual foi. ' +
      'Uma batalha em andamento é descartada, sem gravar nada.',
  })
  @ApiCreatedResponse({ type: BattleResponseDto })
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
  ): Promise<BattleResponseDto> {
    return this.battles.startWild(
      userId,
      { q: body.q, r: body.r },
      body.god === true,
    );
  }

  @Post('action')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Agir na batalha',
    deprecated: true,
    description:
      LEGACY +
      'O jogo diz o que o jogador quer fazer, uma ação por Ecobeast de pé em ' +
      'campo, e o servidor decide o resto. ' +
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
    return this.battles.act(userId, toBattleActions(body));
  }
}
