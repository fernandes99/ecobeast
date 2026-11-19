import {
  Controller,
  Get,
  NotFoundException,
  Param,
  ParseIntPipe,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { AuthGuard } from '../auth/auth.guard.js';
import { InteriorDto } from './interiors.dto.js';
import { INTERIOR_NOT_FOUND, InteriorsService } from './interiors.service.js';

const interiorId = new ParseIntPipe({
  exceptionFactory: () => new NotFoundException(INTERIOR_NOT_FOUND),
});

@ApiTags('Interiores')
@ApiBearerAuth()
@ApiUnauthorizedResponse({
  description: 'Sem sessão, ou sessão inválida ou vencida.',
})
@ApiTooManyRequestsResponse({
  description: 'Limite de chamadas por minuto excedido.',
})
@UseGuards(AuthGuard)
@Controller('interiors')
export class InteriorsController {
  constructor(private readonly interiors: InteriorsService) {}

  @Get(':id')
  @ApiOperation({
    summary: 'Ler uma sala',
    description:
      'O lado de dentro de um prédio, que o jogo baixa ao entrar: as 4 camadas de ' +
      'tiles, os objetos, os quadrados bloqueados, os NPCs e a porta. A peça da ' +
      'ilha leva à sala pelo `interior_id`. Um quadrado bloqueia sem chão, em ' +
      '`blocks` ou com um NPC.',
  })
  @ApiOkResponse({ type: InteriorDto })
  @ApiNotFoundResponse({ description: `"${INTERIOR_NOT_FOUND}"` })
  async read(@Param('id', interiorId) id: number): Promise<InteriorDto> {
    const room = await this.interiors.read(id);
    if (!room) throw new NotFoundException(INTERIOR_NOT_FOUND);
    return room;
  }
}
