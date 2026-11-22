import { Body, Controller, HttpCode, Post, UseGuards } from '@nestjs/common';
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
import {
  INVALID_REACH,
  INVALID_TALK,
  QuestReachBodyDto,
  QuestReachResponseDto,
  QuestTalkBodyDto,
  QuestTalkResponseDto,
  toQuestPlaceDto,
} from './quests.dto.js';
import {
  NO_EXPLORATION,
  NOT_ON_ISLAND,
  NPC_NOT_HERE,
  QuestsService,
  UNREACHABLE,
} from './quests.service.js';

@ApiTags('Missões')
@ApiBearerAuth()
@ApiUnauthorizedResponse({
  description: 'Sem sessão, ou sessão inválida ou vencida.',
})
@ApiTooManyRequestsResponse({
  description: 'Limite de chamadas por minuto excedido.',
})
@UseGuards(AuthGuard)
@Controller('me/quests')
export class QuestsController {
  constructor(private readonly quests: QuestsService) {}

  @Post('talk')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Conversa com um NPC',
    description:
      'Chamada pelo jogo depois da última fala de um NPC, numa exploração de ' +
      'ilha. Cumpre as missões aceitas "Fale com" esse NPC. Se ele dá missões ' +
      'nesta ilha (`quests`), olha a primeira da fila não entregue: aceita se ' +
      'não foi aceita; entrega se está cumprida (moedas, item e XP de Domador ' +
      'numa transação, e a seguinte da fila aceita); senão, mostra o progresso. ' +
      'Uma entrega que completa a ilha abre a seguinte do Arquipélago.',
  })
  @ApiOkResponse({ type: QuestTalkResponseDto })
  @ApiBadRequestResponse({ description: `Sem \`npc_id\`: "${INVALID_TALK}"` })
  @ApiConflictResponse({
    description:
      `Fora de uma ilha: "${NOT_ON_ISLAND}"; ou o NPC não está posto nela ` +
      `(no mapa publicado ou numa sala dele): "${NPC_NOT_HERE}"`,
  })
  async talk(
    @CurrentUser() userId: string,
    @Body() body: QuestTalkBodyDto,
  ): Promise<QuestTalkResponseDto> {
    const result = await this.quests.talk(userId, body.npc_id);
    return {
      lines: result.lines,
      reward: result.reward && {
        coins: result.reward.coins,
        item_id: result.reward.itemId,
        item_quantity: result.reward.itemQuantity,
        xp: result.reward.xp,
      },
      tamer_progress: result.tamerProgress,
      island_unlocked: result.islandUnlocked,
      quest_places: result.questPlaces.map(toQuestPlaceDto),
    };
  }

  @Post('reach')
  @HttpCode(200)
  @ApiOperation({
    summary: 'O Domador pisou num lugar de missão',
    description:
      'O jogo avisa ao pisar num hexágono de `quest_places`. O servidor confere ' +
      'o passo como no Procurar (a posição e a velocidade) e cumpre as missões ' +
      '"Vá até" aceitas desta ilha com esse hexágono.',
  })
  @ApiOkResponse({ type: QuestReachResponseDto })
  @ApiBadRequestResponse({
    description: `\`q\` ou \`r\` inválidos: "${INVALID_REACH}"`,
  })
  @ApiNotFoundResponse({ description: `Sem exploração: "${NO_EXPLORATION}"` })
  @ApiConflictResponse({
    description: `Fora de uma ilha: "${NOT_ON_ISLAND}"; ou o passo rápido demais: "${UNREACHABLE}"`,
  })
  async reach(
    @CurrentUser() userId: string,
    @Body() body: QuestReachBodyDto,
  ): Promise<QuestReachResponseDto> {
    const result = await this.quests.reach(userId, { q: body.q, r: body.r });
    return {
      reached: result.reached,
      quest_places: result.questPlaces.map(toQuestPlaceDto),
    };
  }
}
