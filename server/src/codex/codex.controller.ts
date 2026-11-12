import { Controller, Delete, Get, HttpCode, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
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
import { CodexResponseDto } from './codex.dto.js';
import { CodexService } from './codex.service.js';

@ApiTags('Bestiário')
@ApiBearerAuth()
@ApiUnauthorizedResponse({
  description: 'Sem sessão, ou sessão inválida ou vencida.',
})
@ApiTooManyRequestsResponse({
  description: 'Limite de chamadas por minuto excedido.',
})
@UseGuards(AuthGuard)
@Controller('me/codex')
export class CodexController {
  constructor(private readonly codex: CodexService) {}

  @Get()
  @ApiOperation({
    summary: 'Ler o Bestiário',
    description:
      'As espécies que o jogador já viu numa luta, com as que ele capturou. ' +
      'Ver conta quando o Ecobeast inimigo entra em campo; capturar conta na ' +
      'captura, na Evolução e na escolha do inicial. Sem Domador, a lista vem vazia.',
  })
  @ApiOkResponse({ type: CodexResponseDto })
  async list(@CurrentUser() userId: string): Promise<CodexResponseDto> {
    const entries = await this.codex.list(userId);
    return {
      entries: entries.map(({ speciesId, caught }) => ({
        species_id: speciesId,
        caught,
      })),
    };
  }

  @Delete()
  @HttpCode(204)
  @ApiOperation({
    summary: 'Limpar o Bestiário (depuração)',
    description:
      'Apaga os registros do jogador, para testar o aviso de registro de novo. ' +
      'A rota só existe com `ENABLE_TEST_BATTLE` ligada.',
  })
  @ApiNoContentResponse({ description: 'Bestiário apagado.' })
  @ApiNotFoundResponse({
    description: 'Sem `ENABLE_TEST_BATTLE`: "Rota não encontrada."',
  })
  async clear(@CurrentUser() userId: string): Promise<void> {
    await this.codex.clear(userId);
  }
}
