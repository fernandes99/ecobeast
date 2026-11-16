import { Controller, Get } from '@nestjs/common';
import {
  ApiOkResponse,
  ApiOperation,
  ApiProperty,
  ApiTags,
  ApiTooManyRequestsResponse,
} from '@nestjs/swagger';
import { minuteOfDay } from '../domain/world-clock/world-clock.js';

export class WorldClockDto {
  @ApiProperty({
    description:
      'O minuto do dia do jogo agora, de 0 (inclusive) a 1440. Um dia dura 24 minutos reais: 1 segundo real é 1 minuto do jogo.',
    example: 754.317,
  })
  minute_of_day: number;
}

@ApiTags('Relógio do mundo')
@Controller('world-clock')
export class WorldClockController {
  @Get()
  @ApiOperation({
    summary: 'A hora do mundo',
    description:
      'A hora do jogo, a mesma para todos os jogadores. O jogo pede ao abrir e ' +
      'conta sozinho a partir daí; a parte do dia sai da tabela `day_phases` do catálogo.',
  })
  @ApiOkResponse({ type: WorldClockDto })
  @ApiTooManyRequestsResponse({
    description: 'Limite de chamadas por minuto excedido.',
  })
  get(): WorldClockDto {
    return { minute_of_day: minuteOfDay(Date.now()) };
  }
}
