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
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiNoContentResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { AuthGuard } from '../auth/auth.guard.js';
import { InteriorBodyDto, InteriorDto } from '../interiors/interiors.dto.js';
import { EditorGuard } from './editor.guard.js';
import { InteriorListDto, NewInteriorDto } from './interiors-editor.dto.js';
import {
  EDITOR_INTERIOR_NOT_FOUND,
  INTERIOR_IN_USE,
  InteriorsEditorService,
} from './interiors-editor.service.js';

const interiorId = new ParseIntPipe({
  exceptionFactory: () => new NotFoundException(EDITOR_INTERIOR_NOT_FOUND),
});

@ApiTags('Editor de interiores')
@ApiBearerAuth()
@ApiUnauthorizedResponse({
  description: 'Sem sessão, ou sessão inválida ou vencida.',
})
@ApiForbiddenResponse({
  description: 'Quem chama não está em `MAP_EDITOR_USER_IDS`.',
})
@ApiNotFoundResponse({
  description: `Com \`MAP_EDITOR_USER_IDS\` vazia, "Rota não encontrada."; senão, "${EDITOR_INTERIOR_NOT_FOUND}"`,
})
@ApiTooManyRequestsResponse({
  description: 'Limite de chamadas por minuto excedido.',
})
@UseGuards(AuthGuard, EditorGuard)
@Controller('editor/interiors')
export class InteriorsEditorController {
  constructor(private readonly interiors: InteriorsEditorService) {}

  @Get()
  @ApiOperation({
    summary: 'Listar as salas',
    description: 'Todas as salas, por id.',
  })
  @ApiOkResponse({ type: InteriorListDto })
  list(): Promise<InteriorListDto> {
    return this.interiors.list();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Ler uma sala' })
  @ApiOkResponse({ type: InteriorDto })
  read(@Param('id', interiorId) id: number): Promise<InteriorDto> {
    return this.interiors.read(id);
  }

  @Post()
  @ApiOperation({
    summary: 'Criar uma sala',
    description:
      'Uma sala vazia, sem chão, com a porta no meio da linha de baixo. Ela só ' +
      'salva depois de ter chão livre na porta.',
  })
  @ApiCreatedResponse({ type: InteriorDto })
  @ApiBadRequestResponse({ description: 'O nome ou o tamanho fora da faixa.' })
  create(@Body() body: NewInteriorDto): Promise<InteriorDto> {
    return this.interiors.create(body);
  }

  @Put(':id')
  @ApiOperation({
    summary: 'Salvar uma sala',
    description:
      'Troca a sala inteira pelo corpo, numa transação, e a devolve com os `id` ' +
      'novos dos objetos e dos NPCs. Vale no jogo na próxima entrada, sem publicar.',
  })
  @ApiOkResponse({ type: InteriorDto })
  @ApiBadRequestResponse({
    description: 'A mensagem do primeiro erro da sala.',
  })
  save(
    @Param('id', interiorId) id: number,
    @Body() body: InteriorBodyDto,
  ): Promise<InteriorDto> {
    return this.interiors.save(id, body);
  }

  @Delete(':id')
  @HttpCode(204)
  @ApiOperation({ summary: 'Apagar uma sala' })
  @ApiNoContentResponse({ description: 'Apagada.' })
  @ApiConflictResponse({ description: `"${INTERIOR_IN_USE}"` })
  remove(@Param('id', interiorId) id: number): Promise<void> {
    return this.interiors.remove(id);
  }
}
