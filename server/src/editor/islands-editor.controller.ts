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
import { EditorGuard } from './editor.guard.js';
import {
  IslandCreatedResponseDto,
  IslandDraftDto,
  IslandDraftResponseDto,
  IslandListResponseDto,
  IslandPublishedResponseDto,
  IslandSavedResponseDto,
} from './islands-editor.dto.js';
import { ISLAND_NOT_FOUND } from '../islands/islands.service.js';
import { IslandsEditorService } from './islands-editor.service.js';

/** Um id de ilha; um texto que não é número responde como ilha que não existe. */
const islandId = new ParseIntPipe({
  exceptionFactory: () => new NotFoundException(ISLAND_NOT_FOUND),
});

/** As ilhas do editor (.specs/map-editor/architecture.md, "Rotas"). */
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
    'Com `MAP_EDITOR_USER_IDS` vazia, "Rota não encontrada."; senão, "Ilha não encontrada."',
})
@ApiTooManyRequestsResponse({
  description: 'Limite de chamadas por minuto excedido.',
})
@UseGuards(AuthGuard, EditorGuard)
@Controller('editor/islands')
export class IslandsEditorController {
  constructor(private readonly islands: IslandsEditorService) {}

  @Get()
  @ApiOperation({
    summary: 'Listar as ilhas',
    description: 'Todas as ilhas, com o nome do rascunho e o status.',
  })
  @ApiOkResponse({ type: IslandListResponseDto })
  list(): Promise<IslandListResponseDto> {
    return this.islands.list();
  }

  @Post()
  @ApiOperation({
    summary: 'Criar uma ilha',
    description:
      'Cria a ilha com o rascunho do corpo. Ela nasce como rascunho.',
  })
  @ApiCreatedResponse({ type: IslandCreatedResponseDto })
  @ApiBadRequestResponse({ description: 'O rascunho tem algo errado.' })
  create(@Body() body: IslandDraftDto): Promise<IslandCreatedResponseDto> {
    return this.islands.create(body);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Ler o rascunho de uma ilha' })
  @ApiOkResponse({ type: IslandDraftResponseDto })
  read(@Param('id', islandId) id: number): Promise<IslandDraftResponseDto> {
    return this.islands.read(id);
  }

  @Put(':id/draft')
  @ApiOperation({
    summary: 'Salvar o rascunho',
    description:
      'Troca o rascunho inteiro. Uma ilha pela metade pode ser salva; a ' +
      'versão publicada não muda.',
  })
  @ApiOkResponse({ type: IslandSavedResponseDto })
  @ApiBadRequestResponse({ description: 'O rascunho tem algo errado.' })
  save(
    @Param('id', islandId) id: number,
    @Body() body: IslandDraftDto,
  ): Promise<IslandSavedResponseDto> {
    return this.islands.saveDraft(id, body);
  }

  @Post(':id/publish')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Publicar a ilha',
    description: 'Confere o rascunho salvo e o copia para a versão publicada.',
  })
  @ApiOkResponse({ type: IslandPublishedResponseDto })
  @ApiConflictResponse({
    description:
      'O rascunho não está pronto para o jogo; a mensagem diz o quê.',
  })
  publish(
    @Param('id', islandId) id: number,
  ): Promise<IslandPublishedResponseDto> {
    return this.islands.publish(id);
  }

  @Delete(':id')
  @HttpCode(204)
  @ApiOperation({ summary: 'Apagar uma ilha que nunca foi publicada' })
  @ApiNoContentResponse({ description: 'Ilha apagada.' })
  @ApiConflictResponse({
    description: '"Uma ilha publicada não pode ser apagada."',
  })
  remove(@Param('id', islandId) id: number): Promise<void> {
    return this.islands.remove(id);
  }
}
