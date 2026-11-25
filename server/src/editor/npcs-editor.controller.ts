import {
  Body,
  Controller,
  Delete,
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
  ApiConflictResponse,
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
import { AppearanceDto } from '../player/player.dto.js';
import { EditorGuard } from './editor.guard.js';
import {
  NpcAppearanceResponseDto,
  NpcCreateBodyDto,
  NpcDeleteResponseDto,
  NpcRowDto,
  NpcUpdateBodyDto,
  NpcVoiceBodyDto,
  NpcVoiceResponseDto,
} from './npcs-editor.dto.js';
import {
  BODY_NOT_FOUND,
  NPC_IS_CREATURE,
  NPC_IS_PERSON,
  NPC_KIND_REQUIRED,
  NPC_NOT_FOUND,
  NpcsEditorService,
  SPRITE_NOT_FOUND,
  VOICE_NOT_FOUND,
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

  @Put(':id/voice')
  @ApiOperation({
    summary: 'Trocar a voz de um NPC',
    description:
      'Troca a voz com que o NPC fala na caixa de fala, em todas as ilhas. ' +
      'O próximo `GET /v1/catalog` já a traz.',
  })
  @ApiOkResponse({ type: NpcVoiceResponseDto })
  @ApiBadRequestResponse({
    description: `Voz que não existe: "${VOICE_NOT_FOUND}"; \`voice_id\` que não é inteiro.`,
  })
  setVoice(
    @Param('id', npcId) id: number,
    @Body() body: NpcVoiceBodyDto,
  ): Promise<NpcVoiceResponseDto> {
    return this.npcs.setVoice(id, body.voice_id);
  }

  @Post()
  @ApiOperation({
    summary: 'Criar um NPC',
    description:
      'Cria um NPC no catálogo: Ecobeast, com `sprite`, ou pessoa, com `body_type_id`, ' +
      'que nasce vestido com uma peça em cada lugar obrigatório. O `slug` sai do nome. ' +
      'O próximo `GET /v1/catalog` já o traz.',
  })
  @ApiCreatedResponse({ type: NpcRowDto })
  @ApiBadRequestResponse({
    description: `Nome, descrição ou fala fora do tamanho; "${NPC_KIND_REQUIRED}"; "${SPRITE_NOT_FOUND}"; "${BODY_NOT_FOUND}"; "${VOICE_NOT_FOUND}".`,
  })
  create(@Body() body: NpcCreateBodyDto): Promise<NpcRowDto> {
    return this.npcs.create(body);
  }

  @Put(':id')
  @ApiOperation({
    summary: 'Editar um NPC',
    description:
      'Troca o nome, a descrição, a fala padrão e, de um NPC Ecobeast, a espécie (`sprite`). ' +
      'O `slug` e o tipo (Ecobeast ou pessoa) não mudam. O próximo `GET /v1/catalog` já traz a mudança.',
  })
  @ApiOkResponse({ type: NpcRowDto })
  @ApiBadRequestResponse({
    description: `Nome, descrição ou fala fora do tamanho; "${NPC_IS_PERSON}"; "${SPRITE_NOT_FOUND}".`,
  })
  update(
    @Param('id', npcId) id: number,
    @Body() body: NpcUpdateBodyDto,
  ): Promise<NpcRowDto> {
    return this.npcs.update(id, body);
  }

  @Delete(':id')
  @ApiOperation({
    summary: 'Apagar um NPC',
    description:
      'Apaga o NPC e as peças da aparência dele, só se ele não está posto em nenhuma ilha ' +
      'nem sala, não dá nem é alvo de missão e não é Domador de ilha. As cenas da história, ' +
      'que moram no jogo, o F2 confere antes.',
  })
  @ApiOkResponse({ type: NpcDeleteResponseDto })
  @ApiConflictResponse({
    description:
      'Em uso: "Esse NPC está em uso: posto em Liora (rascunho e publicada); dá 2 missões. Tire-o de lá antes de excluir."',
  })
  remove(@Param('id', npcId) id: number): Promise<NpcDeleteResponseDto> {
    return this.npcs.remove(id);
  }
}
