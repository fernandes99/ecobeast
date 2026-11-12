import {
  BadRequestException,
  Body,
  Controller,
  Get,
  HttpCode,
  Post,
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
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { AuthGuard } from '../auth/auth.guard.js';
import { camelToSnakeKeys, snakeToCamelKeys } from '../common/case.js';
import {
  DEFAULT_MAP_CONFIG,
  MAP_CONFIG_RANGES,
  type MapConfig,
  mapConfigError,
  withDefaults,
} from '../domain/exploration/map-config.js';
import { generateMap } from '../domain/exploration/map-generator.js';
import { EditorGuard } from './editor.guard.js';
import {
  ConfigRangeDto,
  MapGeneratorBodyDto,
  MapGeneratorParamsResponseDto,
  MapGeneratorResponseDto,
} from './islands-editor.dto.js';

const snake = (field: string): string =>
  Object.keys(camelToSnakeKeys({ [field]: null }))[0]!;

function configOf(raw: Record<string, unknown> = {}): Partial<MapConfig> {
  const config = snakeToCamelKeys(raw);
  for (const [field, value] of Object.entries(config)) {
    if (!(field in MAP_CONFIG_RANGES)) {
      throw new BadRequestException(
        `${snake(field)} não é um parâmetro do gerador.`,
      );
    }
    if (typeof value !== 'number' || !Number.isFinite(value)) {
      throw new BadRequestException(`${snake(field)} precisa ser um número.`);
    }
  }
  const valid = config as Partial<MapConfig>;
  const error = mapConfigError(valid, snake);
  if (error) throw new BadRequestException(error);
  return valid;
}

@ApiTags('Editor de ilhas')
@ApiBearerAuth()
@ApiUnauthorizedResponse({
  description: 'Sem sessão, ou sessão inválida ou vencida.',
})
@ApiForbiddenResponse({
  description: 'Quem chama não está em `MAP_EDITOR_USER_IDS`.',
})
@ApiNotFoundResponse({
  description: 'Com `MAP_EDITOR_USER_IDS` vazia, "Rota não encontrada."',
})
@UseGuards(AuthGuard, EditorGuard)
@Controller('editor/map-generator')
export class MapGeneratorController {
  @Get()
  @ApiOperation({
    summary: 'Parâmetros do gerador',
    description: 'O padrão e a faixa aceita de cada parâmetro, em snake_case.',
  })
  @ApiOkResponse({ type: MapGeneratorParamsResponseDto })
  params(): MapGeneratorParamsResponseDto {
    return {
      defaults: camelToSnakeKeys({ ...DEFAULT_MAP_CONFIG }) as Record<
        string,
        number
      >,
      ranges: camelToSnakeKeys({ ...MAP_CONFIG_RANGES }) as Record<
        string,
        ConfigRangeDto
      >,
    };
  }

  @Post()
  @HttpCode(200)
  @ApiOperation({
    summary: 'Gerar um mapa',
    description:
      'Roda o gerador de Explorar zona com a seed e os parâmetros, sem gravar ' +
      'nada e sem Ecobeasts nem Domadores.',
  })
  @ApiOkResponse({ type: MapGeneratorResponseDto })
  @ApiBadRequestResponse({ description: 'Um parâmetro fora da faixa.' })
  generate(@Body() body: MapGeneratorBodyDto): MapGeneratorResponseDto {
    const map = generateMap(body.seed, withDefaults(configOf(body.config)));
    return { start: map.start, tiles: map.tiles };
  }
}
