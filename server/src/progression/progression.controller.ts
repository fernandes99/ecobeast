import {
  Body,
  Controller,
  HttpCode,
  NotFoundException,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiConflictResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { AuthGuard } from '../auth/auth.guard.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import {
  EvolutionBodyDto,
  EvolutionResponseDto,
  INVALID_CHOICE,
  LearnSkillBodyDto,
  LearnSkillResponseDto,
} from './progression.dto.js';
import {
  EVOLVE_FIRST,
  NO_CHOICE,
  ProgressionService,
  UNKNOWN_SKILL,
} from './progression.service.js';

const NO_CHOICE_RESPONSE = `Nada pendente para esse Ecobeast, de outro Domador ou de uma luta anterior: "${NO_CHOICE}"`;
/** Um uid malformado é só uma escolha que não existe. */
const UID_PIPE = new ParseUUIDPipe({
  exceptionFactory: () => new NotFoundException(NO_CHOICE),
});

/** As escolhas depois da vitória (.specs/progression/architecture.md, "Contrato"). */
@ApiTags('Progressão')
@ApiBearerAuth()
@ApiUnauthorizedResponse({
  description: 'Sem sessão, ou sessão inválida ou vencida.',
})
@ApiTooManyRequestsResponse({
  description: 'Limite de chamadas por minuto excedido.',
})
@UseGuards(AuthGuard)
@Controller('me/creatures/:uid')
export class ProgressionController {
  constructor(private readonly progression: ProgressionService) {}

  @Post('evolution')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Evoluir ou cancelar a evolução',
    description:
      'Responde à evolução oferecida na última vitória. Depois, calcula as Técnicas do nível: as que cabem já são aprendidas, e as outras ficam pendentes.',
  })
  @ApiOkResponse({ type: EvolutionResponseDto })
  @ApiBadRequestResponse({ description: `Corpo inválido: "${INVALID_CHOICE}"` })
  @ApiNotFoundResponse({ description: NO_CHOICE_RESPONSE })
  async evolve(
    @CurrentUser() userId: string,
    @Param('uid', UID_PIPE) uid: string,
    @Body() body: EvolutionBodyDto,
  ): Promise<EvolutionResponseDto> {
    return this.progression.evolve(userId, uid, body.accept);
  }

  @Post('skills')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Escolher a Técnica pendente',
    description:
      'Com `forget_skill_id`, a nova entra na vaga da esquecida, com o PP cheio. Com `null`, ele não aprende a nova.',
  })
  @ApiOkResponse({ type: LearnSkillResponseDto })
  @ApiBadRequestResponse({
    description: `Corpo inválido: "${INVALID_CHOICE}" · Técnica que ele não conhece: "${UNKNOWN_SKILL}"`,
  })
  @ApiNotFoundResponse({ description: NO_CHOICE_RESPONSE })
  @ApiConflictResponse({
    description: `A evolução ainda não foi decidida: "${EVOLVE_FIRST}"`,
  })
  async learnSkill(
    @CurrentUser() userId: string,
    @Param('uid', UID_PIPE) uid: string,
    @Body() body: LearnSkillBodyDto,
  ): Promise<LearnSkillResponseDto> {
    return this.progression.learnSkill(
      userId,
      uid,
      body.skill_id,
      body.forget_skill_id,
    );
  }
}
