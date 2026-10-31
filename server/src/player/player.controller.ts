import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  NotFoundException,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiConflictResponse,
  ApiCreatedResponse,
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
  ChooseStarterBodyDto,
  CreatePlayerBodyDto,
  MaybePlayerResponseDto,
  PlayerResponseDto,
  SetNicknameBodyDto,
} from './player.dto.js';
import { CREATURE_NOT_FOUND, PlayerService } from './player.service.js';

/** O Domador do usuário logado (.specs/auth-google/03-player-api.md). */
@ApiTags('Jogador')
@ApiBearerAuth()
@ApiUnauthorizedResponse({
  description: 'Sem sessão, ou sessão inválida ou vencida.',
})
@ApiTooManyRequestsResponse({
  description: 'Limite de chamadas por minuto excedido.',
})
@UseGuards(AuthGuard)
@Controller('me')
export class PlayerController {
  constructor(private readonly players: PlayerService) {}

  @Get()
  @ApiOperation({
    summary: 'Ler o jogador',
    description:
      'O Domador desta conta, com a equipe e os stats calculados pelo servidor. ' +
      '`player` é nulo se a conta ainda não tem Domador.',
  })
  @ApiOkResponse({ type: MaybePlayerResponseDto })
  async read(@CurrentUser() userId: string): Promise<MaybePlayerResponseDto> {
    return { player: await this.players.get(userId) };
  }

  @Post()
  @ApiOperation({
    summary: 'Criar o Domador',
    description:
      'Cria o Domador desta conta, no nível 1, com 1000 moedas e sem equipe.',
  })
  @ApiCreatedResponse({ type: PlayerResponseDto })
  @ApiBadRequestResponse({
    description: 'Nome inválido: "Use de 2 a 16 letras, números ou espaços."',
  })
  @ApiConflictResponse({
    description: 'A conta já tem Domador: "Você já tem um Domador."',
  })
  async create(
    @CurrentUser() userId: string,
    @Body() body: CreatePlayerBodyDto,
  ): Promise<PlayerResponseDto> {
    return { player: await this.players.create(userId, body.name) };
  }

  @Post('starter')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Escolher o Ecobeast inicial',
    description:
      'O servidor gera a criatura no nível 5 (Genes, Temperamento, Traço e gênero ' +
      'sorteados) e a põe no slot 1 da equipe. Só pode ser feito uma vez.',
  })
  @ApiOkResponse({ type: PlayerResponseDto })
  @ApiBadRequestResponse({
    description:
      'A espécie não está entre os iniciais: "Esse Ecobeast não pode ser escolhido."',
  })
  @ApiConflictResponse({
    description:
      'Sem Domador: "Crie seu Domador primeiro." Já escolheu: "Você já escolheu seu Ecobeast."',
  })
  async chooseStarter(
    @CurrentUser() userId: string,
    @Body() body: ChooseStarterBodyDto,
  ): Promise<PlayerResponseDto> {
    return {
      player: await this.players.chooseStarter(userId, body.species_id),
    };
  }

  @Patch('creatures/:uid')
  @ApiOperation({
    summary: 'Dar apelido a um Ecobeast',
    description:
      'Grava o apelido de uma criatura deste Domador, da equipe ou do Santuário. Vazio remove o apelido.',
  })
  @ApiOkResponse({ type: PlayerResponseDto })
  @ApiBadRequestResponse({
    description:
      'Apelido inválido: "Use de 2 a 16 letras, números ou espaços."',
  })
  @ApiNotFoundResponse({
    description: `Criatura inexistente ou de outro Domador: "${CREATURE_NOT_FOUND}"`,
  })
  async setNickname(
    @CurrentUser() userId: string,
    // Um uid malformado é só uma criatura que não existe; sem o pipe, viraria erro do banco.
    @Param(
      'uid',
      new ParseUUIDPipe({
        exceptionFactory: () => new NotFoundException(CREATURE_NOT_FOUND),
      }),
    )
    uid: string,
    @Body() body: SetNicknameBodyDto,
  ): Promise<PlayerResponseDto> {
    return {
      player: await this.players.setNickname(userId, uid, body.nickname),
    };
  }

  @Delete()
  @HttpCode(204)
  @ApiOperation({
    summary: 'Apagar o progresso',
    description:
      'Apaga o Domador e tudo que é dele. A conta continua; responde `204` mesmo sem Domador.',
  })
  @ApiNoContentResponse({ description: 'Progresso apagado.' })
  async remove(@CurrentUser() userId: string): Promise<void> {
    await this.players.remove(userId);
  }
}
