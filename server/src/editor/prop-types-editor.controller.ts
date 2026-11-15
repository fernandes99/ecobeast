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
import { EditorGuard } from './editor.guard.js';
import {
  PropTypeBlocksDto,
  PropTypeBlocksSavedDto,
} from './prop-types-editor.dto.js';
import {
  PROP_TYPE_NOT_FOUND,
  PropTypesEditorService,
} from './prop-types-editor.service.js';

const propTypeId = new ParseIntPipe({
  exceptionFactory: () => new NotFoundException(PROP_TYPE_NOT_FOUND),
});

@ApiTags('Editor de ilhas')
@ApiBearerAuth()
@ApiUnauthorizedResponse({
  description: 'Sem sessão, ou sessão inválida ou vencida.',
})
@ApiForbiddenResponse({
  description: 'Quem chama não está em `MAP_EDITOR_USER_IDS`.',
})
@ApiNotFoundResponse({
  description:
    'Com `MAP_EDITOR_USER_IDS` vazia, "Rota não encontrada."; senão, "Tipo de peça não encontrado."',
})
@ApiTooManyRequestsResponse({
  description: 'Limite de chamadas por minuto excedido.',
})
@UseGuards(AuthGuard, EditorGuard)
@Controller('editor/prop-types')
export class PropTypesEditorController {
  constructor(private readonly propTypes: PropTypesEditorService) {}

  @Put(':id/blocks')
  @ApiOperation({
    summary: 'Salvar as linhas de bloqueio de um tipo de peça',
    description:
      'Troca as linhas padrão do tipo numa transação e libera o catálogo novo. ' +
      'As peças sem ajuste desse tipo, em todas as ilhas, passam a usá-las. ' +
      'A resposta lista as versões de ilha cuja chegada ficou bloqueada (free-objects/02).',
  })
  @ApiOkResponse({ type: PropTypeBlocksSavedDto })
  @ApiBadRequestResponse({
    description: 'Uma linha passa dos limites; a mensagem diz qual.',
  })
  saveBlocks(
    @Param('id', propTypeId) id: number,
    @Body() body: PropTypeBlocksDto,
  ): Promise<PropTypeBlocksSavedDto> {
    return this.propTypes.saveBlocks(id, body);
  }
}
