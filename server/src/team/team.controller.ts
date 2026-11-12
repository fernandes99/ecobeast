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
  ApiConflictResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { AuthGuard } from '../auth/auth.guard.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import { PlayerResponseDto } from '../player/player.dto.js';
import { CREATURE_NOT_FOUND } from '../player/player.service.js';
import {
  BringToTeamBodyDto,
  INVALID_ORDER,
  SendToStorageBodyDto,
  StorageResponseDto,
  TeamOrderBodyDto,
} from './team.dto.js';
import {
  ALREADY_IN_TEAM,
  ALREADY_STORED,
  LAST_CREATURE,
  NO_PLAYER,
  TEAM_FULL,
  TeamService,
} from './team.service.js';

const NO_PLAYER_RESPONSE = `Sem Domador ou sem equipe: "${NO_PLAYER}"`;
const KEEPS_STATE =
  'HP, status e PP não mudam. A batalha aberta é descartada, sem gravar nada dela.';

@ApiTags('Equipe e Santuário')
@ApiBearerAuth()
@ApiUnauthorizedResponse({
  description: 'Sem sessão, ou sessão inválida ou vencida.',
})
@ApiTooManyRequestsResponse({
  description: 'Limite de chamadas por minuto excedido.',
})
@UseGuards(AuthGuard)
@Controller('me')
export class TeamController {
  constructor(private readonly team: TeamService) {}

  @Get('storage')
  @ApiOperation({
    summary: 'Listar o Santuário',
    description:
      'Todos os Ecobeasts fora da equipe. A busca e os filtros ficam no jogo.',
  })
  @ApiOkResponse({ type: StorageResponseDto })
  @ApiConflictResponse({ description: `Sem Domador: "${NO_PLAYER}"` })
  async storage(@CurrentUser() userId: string): Promise<StorageResponseDto> {
    return { creatures: await this.team.storage(userId) };
  }

  @Post('team/order')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Reordenar a equipe',
    description: `Os Ecobeasts ficam nas vagas de 1 em diante, na ordem recebida. ${KEEPS_STATE}`,
  })
  @ApiOkResponse({ type: PlayerResponseDto })
  @ApiBadRequestResponse({
    description: `A lista não é exatamente a equipe: "${INVALID_ORDER}"`,
  })
  @ApiConflictResponse({ description: NO_PLAYER_RESPONSE })
  async order(
    @CurrentUser() userId: string,
    @Body() body: TeamOrderBodyDto,
  ): Promise<PlayerResponseDto> {
    return { player: await this.team.order(userId, body.uids) };
  }

  @Post('team/bring')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Trazer um Ecobeast do Santuário',
    description:
      'Sem `replace_uid`, ele entra na primeira vaga livre. Com `replace_uid`, ' +
      `os dois trocam de lugar. ${KEEPS_STATE}`,
  })
  @ApiOkResponse({ type: PlayerResponseDto })
  @ApiBadRequestResponse({ description: `Já na equipe: "${ALREADY_IN_TEAM}"` })
  @ApiNotFoundResponse({
    description: `Inexistente ou de outro Domador: "${CREATURE_NOT_FOUND}"`,
  })
  @ApiConflictResponse({
    description: `${NO_PLAYER_RESPONSE} Sem vaga: "${TEAM_FULL}"`,
  })
  async bring(
    @CurrentUser() userId: string,
    @Body() body: BringToTeamBodyDto,
  ): Promise<PlayerResponseDto> {
    const { uid, replace_uid: replaceUid } = body;
    return { player: await this.team.bring(userId, uid, replaceUid) };
  }

  @Post('team/store')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Mandar um Ecobeast para o Santuário',
    description: `A vaga dele fica livre. ${KEEPS_STATE}`,
  })
  @ApiOkResponse({ type: PlayerResponseDto })
  @ApiBadRequestResponse({
    description: `Já no Santuário: "${ALREADY_STORED}" Último da equipe: "${LAST_CREATURE}"`,
  })
  @ApiNotFoundResponse({
    description: `Inexistente ou de outro Domador: "${CREATURE_NOT_FOUND}"`,
  })
  @ApiConflictResponse({ description: NO_PLAYER_RESPONSE })
  async store(
    @CurrentUser() userId: string,
    @Body() body: SendToStorageBodyDto,
  ): Promise<PlayerResponseDto> {
    return { player: await this.team.store(userId, body.uid) };
  }
}
