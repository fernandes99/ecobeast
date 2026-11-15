import {
  Body,
  Controller,
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
import { EditorGuard } from './editor.guard.js';
import { SkillDraftDto, SkillSavedResponseDto } from './skills-editor.dto.js';
import {
  SKILL_NOT_FOUND,
  SkillsEditorService,
} from './skills-editor.service.js';

const skillId = new ParseIntPipe({
  exceptionFactory: () => new NotFoundException(SKILL_NOT_FOUND),
});

@ApiTags('Editor de Técnicas')
@ApiBearerAuth()
@ApiUnauthorizedResponse({
  description: 'Sem sessão, ou sessão inválida ou vencida.',
})
@ApiForbiddenResponse({
  description: 'Quem chama não está em `MAP_EDITOR_USER_IDS`.',
})
@ApiNotFoundResponse({
  description:
    'Com `MAP_EDITOR_USER_IDS` vazia, "Rota não encontrada."; senão, "Técnica não encontrada."',
})
@ApiTooManyRequestsResponse({
  description: 'Limite de chamadas por minuto excedido.',
})
@UseGuards(AuthGuard, EditorGuard)
@Controller('editor/skills')
export class SkillsEditorController {
  constructor(private readonly skills: SkillsEditorService) {}

  @Post()
  @ApiOperation({
    summary: 'Criar uma Técnica',
    description:
      'Cria a Técnica com os efeitos e quem aprende. A próxima luta e o ' +
      'próximo `GET /v1/catalog` já a trazem.',
  })
  @ApiCreatedResponse({ type: SkillSavedResponseDto })
  @ApiBadRequestResponse({
    description: 'A Técnica tem algo errado; a mensagem diz o quê.',
  })
  @ApiConflictResponse({
    description: '"Já existe uma Técnica com esse slug."',
  })
  create(@Body() body: SkillDraftDto): Promise<SkillSavedResponseDto> {
    return this.skills.create(body);
  }

  @Put(':id')
  @ApiOperation({
    summary: 'Salvar uma Técnica',
    description:
      'Troca os campos, os efeitos e quem aprende, numa transação. O `slug` ' +
      'não muda. Uma luta em andamento continua com os dados antigos.',
  })
  @ApiOkResponse({ type: SkillSavedResponseDto })
  @ApiBadRequestResponse({
    description: 'A Técnica tem algo errado; a mensagem diz o quê.',
  })
  save(
    @Param('id', skillId) id: number,
    @Body() body: SkillDraftDto,
  ): Promise<SkillSavedResponseDto> {
    return this.skills.save(id, body);
  }
}
