import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  NotFoundException,
  Param,
  ParseIntPipe,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { AuthGuard } from '../auth/auth.guard.js';
import { EditorGuard } from './editor.guard.js';
import {
  QuestEditorBodyDto,
  QuestMoveBodyDto,
  QuestRequiredBodyDto,
  QuestsEditorResponseDto,
} from './quests-editor.dto.js';
import {
  ISLAND_NOT_FOUND,
  QUEST_NOT_FOUND,
  QuestsEditorService,
} from './quests-editor.service.js';

const islandId = new ParseIntPipe({
  exceptionFactory: () => new NotFoundException(ISLAND_NOT_FOUND),
});
const questId = new ParseIntPipe({
  exceptionFactory: () => new NotFoundException(QUEST_NOT_FOUND),
});

const CHECKS =
  'Confere o tipo e os parâmetros dele, limpa os que o tipo não usa, e pede ' +
  'que o NPC, o NPC alvo, a espécie e o item existam; no "Derrote o NPC", o ' +
  'alvo é Domador desta ilha, e no "Vá até", os hexágonos estão no rascunho dela.';

@ApiTags('Editor de missões')
@ApiBearerAuth()
@ApiUnauthorizedResponse({
  description: 'Sem sessão, ou sessão inválida ou vencida.',
})
@ApiForbiddenResponse({
  description: 'Quem chama não está em `MAP_EDITOR_USER_IDS`.',
})
@ApiTooManyRequestsResponse({
  description: 'Limite de chamadas por minuto excedido.',
})
@UseGuards(AuthGuard, EditorGuard)
@Controller('editor')
export class QuestsEditorController {
  constructor(private readonly quests: QuestsEditorService) {}

  @Get('islands/:id/quests')
  @ApiOperation({
    summary: 'Ler as missões de uma ilha',
    description:
      'As missões da ilha (auralis/06), em ordem de NPC e de posição na fila, ' +
      'com o título que o jogador vê, os 9 tipos e as missões pedidas para ' +
      'abrir a próxima ilha. As missões ficam fora do rascunho: valem na hora.',
  })
  @ApiOkResponse({ type: QuestsEditorResponseDto })
  @ApiNotFoundResponse({ description: `"${ISLAND_NOT_FOUND}"` })
  list(@Param('id', islandId) id: number): Promise<QuestsEditorResponseDto> {
    return this.quests.list(id);
  }

  @Post('islands/:id/quests')
  @ApiOperation({
    summary: 'Criar uma missão',
    description: `A missão entra no fim da fila do NPC que dá. ${CHECKS}`,
  })
  @ApiCreatedResponse({ type: QuestsEditorResponseDto })
  @ApiBadRequestResponse({ description: 'A missão tem algo errado.' })
  @ApiNotFoundResponse({ description: `"${ISLAND_NOT_FOUND}"` })
  create(
    @Param('id', islandId) id: number,
    @Body() body: QuestEditorBodyDto,
  ): Promise<QuestsEditorResponseDto> {
    return this.quests.create(id, body);
  }

  @Put('islands/:id/required-quests')
  @ApiOperation({
    summary: 'Mudar as missões pedidas para abrir a próxima ilha',
    description: 'Nulo pede todas as que contam.',
  })
  @ApiOkResponse({ type: QuestsEditorResponseDto })
  @ApiBadRequestResponse({ description: 'Zero ou menos.' })
  @ApiNotFoundResponse({ description: `"${ISLAND_NOT_FOUND}"` })
  setRequired(
    @Param('id', islandId) id: number,
    @Body() body: QuestRequiredBodyDto,
  ): Promise<QuestsEditorResponseDto> {
    return this.quests.setRequired(id, body.required_quests ?? null);
  }

  @Put('quests/:id')
  @ApiOperation({
    summary: 'Salvar uma missão',
    description:
      'Troca tudo, menos a ilha. Com outro NPC, a missão vai para o fim da ' +
      `fila dele. ${CHECKS}`,
  })
  @ApiOkResponse({ type: QuestsEditorResponseDto })
  @ApiBadRequestResponse({ description: 'A missão tem algo errado.' })
  @ApiNotFoundResponse({ description: `"${QUEST_NOT_FOUND}"` })
  update(
    @Param('id', questId) id: number,
    @Body() body: QuestEditorBodyDto,
  ): Promise<QuestsEditorResponseDto> {
    return this.quests.update(id, body);
  }

  @Delete('quests/:id')
  @ApiOperation({
    summary: 'Apagar uma missão',
    description: 'Apaga junto o progresso de quem a aceitou.',
  })
  @ApiOkResponse({ type: QuestsEditorResponseDto })
  @ApiNotFoundResponse({ description: `"${QUEST_NOT_FOUND}"` })
  remove(@Param('id', questId) id: number): Promise<QuestsEditorResponseDto> {
    return this.quests.remove(id);
  }

  @Post('quests/:id/move')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Subir ou descer uma missão na fila do NPC',
    description: 'Troca com a vizinha; na ponta da fila, não muda nada.',
  })
  @ApiOkResponse({ type: QuestsEditorResponseDto })
  @ApiBadRequestResponse({ description: '`direction` sem "up" nem "down".' })
  @ApiNotFoundResponse({ description: `"${QUEST_NOT_FOUND}"` })
  move(
    @Param('id', questId) id: number,
    @Body() body: QuestMoveBodyDto,
  ): Promise<QuestsEditorResponseDto> {
    return this.quests.move(id, body.direction);
  }
}
