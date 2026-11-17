import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { AuthGuard } from '../auth/auth.guard.js';
import { CurrentUser } from '../auth/current-user.decorator.js';
import {
  MARKS_PER_CALL_MESSAGE,
  MAX_MARKS_MESSAGE,
  MAX_MARKS_PER_CALL,
  StoryMarksBodyDto,
  StoryMarksResponseDto,
} from './story.dto.js';
import { StoryService } from './story.service.js';

@ApiTags('História')
@ApiBearerAuth()
@ApiUnauthorizedResponse({ description: 'Sem sessão ou sessão vencida.' })
@UseGuards(AuthGuard)
@Controller('me/story')
export class StoryController {
  constructor(private readonly story: StoryService) {}

  @Post('marks')
  @ApiOperation({
    summary: 'Ligar Marcos da história',
    description:
      'Liga os Marcos que uma cena da história ligou, para o jogo voltar ao mesmo ' +
      'ponto ao reinstalar (`story_marks` em `GET /v1/me`). De 1 a ' +
      `${MAX_MARKS_PER_CALL} por chamada. Ligar um Marco que o Domador já tem não ` +
      'é erro. O servidor não sabe o que um Marco significa e não dá nada por ele.',
  })
  @ApiCreatedResponse({ type: StoryMarksResponseDto })
  @ApiBadRequestResponse({
    description:
      `"${MARKS_PER_CALL_MESSAGE}", "O Marco \\"<valor>\\" tem caracteres ` +
      `inválidos." ou "${MAX_MARKS_MESSAGE}"`,
  })
  @ApiConflictResponse({
    description: 'Sem Domador: "Crie seu Domador primeiro."',
  })
  async addMarks(
    @CurrentUser() userId: string,
    @Body() body: StoryMarksBodyDto,
  ): Promise<StoryMarksResponseDto> {
    return {
      story_marks: await this.story.addMarks(
        userId,
        (body as { marks?: unknown } | undefined)?.marks,
      ),
    };
  }
}
