import {
  Body,
  Controller,
  NotFoundException,
  Param,
  ParseIntPipe,
  Put,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { AuthGuard } from '../auth/auth.guard.js';
import { AppearanceDto } from '../player/player.dto.js';
import { EditorGuard } from './editor.guard.js';
import { NpcAppearanceResponseDto } from './npcs-editor.dto.js';
import {
  NPC_IS_CREATURE,
  NPC_NOT_FOUND,
  NpcsEditorService,
} from './npcs-editor.service.js';

const npcId = new ParseIntPipe({
  exceptionFactory: () => new NotFoundException(NPC_NOT_FOUND),
});

@ApiTags('Editor de NPCs')
@ApiBearerAuth()
@ApiUnauthorizedResponse({
  description: 'Sem sessão, ou sessão inválida ou vencida.',
})
@ApiForbiddenResponse({
  description: 'Quem chama não está em `MAP_EDITOR_USER_IDS`.',
})
@ApiNotFoundResponse({
  description: `Com \`MAP_EDITOR_USER_IDS\` vazia, "Rota não encontrada."; senão, "${NPC_NOT_FOUND}"`,
})
@ApiTooManyRequestsResponse({
  description: 'Limite de chamadas por minuto excedido.',
})
@UseGuards(AuthGuard, EditorGuard)
@Controller('editor/npcs')
export class NpcsEditorController {
  constructor(private readonly npcs: NpcsEditorService) {}

  @Put(':id/appearance')
  @ApiOperation({
    summary: 'Vestir um NPC pessoa',
    description:
      'Troca a aparência inteira de um NPC pessoa (o corpo, a pele e as peças), ' +
      'com as regras da aparência do Domador. O próximo `GET /v1/catalog` já a traz.',
  })
  @ApiOkResponse({ type: NpcAppearanceResponseDto })
  @ApiBadRequestResponse({
    description: `NPC de Ecobeast: "${NPC_IS_CREATURE}"; aparência inválida, com as mensagens do \`PUT /v1/me/appearance\`.`,
  })
  setAppearance(
    @Param('id', npcId) id: number,
    @Body() body: AppearanceDto,
  ): Promise<NpcAppearanceResponseDto> {
    return this.npcs.setAppearance(id, body);
  }
}
