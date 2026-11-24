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
import {
  ActiveQuestsResponseDto,
  INVALID_ACCEPT,
  INVALID_REACH,
  INVALID_TALK,
  QuestAcceptBodyDto,
  QuestAcceptResponseDto,
  QuestReachBodyDto,
  QuestReachResponseDto,
  QuestTalkBodyDto,
  QuestTalkResponseDto,
  toActiveQuestDto,
  toQuestOfferDto,
  toQuestPlaceDto,
} from './quests.dto.js';
import {
  NO_EXPLORATION,
  NOT_ON_ISLAND,
  NPC_NOT_HERE,
  QUEST_NOT_FOUND,
  QUEST_NOT_NEXT,
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

  @Get()
  @ApiOperation({
    summary: 'As missões aceitas',
    description:
      'As missões aceitas e ainda não entregues do Domador, das ilhas ' +
      'publicadas, da mais antiga à mais nova, com o progresso de agora (no ' +
      '"Explore", contado pelo descoberto da ilha) e o texto curto dele, para ' +
      'o quadro de missões de Explorar (explore-hud/01).',
  })
  @ApiOkResponse({ type: ActiveQuestsResponseDto })
  async list(@CurrentUser() userId: string): Promise<ActiveQuestsResponseDto> {
    const quests = await this.quests.active(userId);
    return { quests: quests.map(toActiveQuestDto) };
  }

  @Post('talk')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Conversa com um NPC',
    description:
      'Chamada pelo jogo ao tocar num NPC, numa exploração de ilha. Cumpre as ' +
      'missões aceitas "Fale com" esse NPC. Se ele dá missões nesta ilha ' +
      '(`quests`), olha a primeira da fila não entregue: se não foi aceita, ' +
      'responde a oferta (`offer`, com a conversa de início ou a cena), que o ' +
      'jogo aceita por `POST /v1/me/quests/accept`; se está cumprida, entrega ' +
      '(moedas, item e XP de Domador numa transação) e responde a conversa de ' +
      'fim e a próxima da fila em `next`, sem aceitar; senão, a conversa de ' +
      'durante e o progresso. Uma entrega que completa a ilha abre a seguinte ' +
      'do Arquipélago.',
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
      stage: result.stage,
      quest_id: result.questId,
      dialogue: result.dialogue,
      offer_scene: result.offerScene,
      next: result.next && toQuestOfferDto(result.next),
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

  @Post('accept')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Aceita a missão oferecida',
    description:
      'Chamada pelo jogo quando a conversa de início (ou a cena) termina ' +
      'aceitando a missão (auralis/10). A missão precisa ser a primeira não ' +
      'entregue do NPC dela nesta ilha, com o NPC posto. Uma já aceita ' +
      'responde sem falas. Recusar não chama o servidor.',
  })
  @ApiOkResponse({ type: QuestAcceptResponseDto })
  @ApiBadRequestResponse({
    description: `Sem \`quest_id\`: "${INVALID_ACCEPT}"`,
  })
  @ApiNotFoundResponse({
    description: `A missão não existe nesta ilha: "${QUEST_NOT_FOUND}"`,
  })
  @ApiConflictResponse({
    description:
      `Fora de uma ilha: "${NOT_ON_ISLAND}"; o NPC fora dela: "${NPC_NOT_HERE}"; ` +
      `ou outra missão da fila vem antes: "${QUEST_NOT_NEXT}"`,
  })
  async accept(
    @CurrentUser() userId: string,
    @Body() body: QuestAcceptBodyDto,
  ): Promise<QuestAcceptResponseDto> {
    const result = await this.quests.acceptQuest(userId, body.quest_id);
    return {
      lines: result.lines,
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
