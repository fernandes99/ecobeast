import {
  Body,
  Controller,
  HttpCode,
  Post,
  Req,
  Res,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiGoneResponse,
  ApiNoContentResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiProperty,
  ApiResponse,
  ApiTags,
  ApiTooManyRequestsResponse,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsUUID } from 'class-validator';
import type { Response } from 'express';
import { AuthGuard } from './auth.guard.js';
import type { AuthenticatedRequest } from './auth.guard.js';
import { LoginSessionsService } from './login-sessions.service.js';
import {
  AuthTokens,
  SupabaseAuthClient,
  SupabaseAuthError,
} from './supabase-auth.client.js';

const SESSION_INVALID = 'Sessão inválida. Entre de novo.';

export class LoginStartDto {
  @ApiProperty({
    description: 'Id do login, mandado em cada pergunta.',
    example: '0b5c2f4e-8d1a-4c3b-9e7f-1a2b3c4d5e6f',
  })
  login_id: string;

  @ApiProperty({
    description:
      'Segredo do login, mandado em cada pergunta. Só o jogo o conhece; o servidor guarda só o hash.',
    example: 'q3Vf9yZ1kX0bA7cR2mN8pL4tW6sE5uH1jG0dK9iO3aB',
  })
  poll_secret: string;

  @ApiProperty({
    description: 'Página a abrir no navegador; leva ao Google.',
    example:
      'http://localhost:3100/auth/google/go?login=0b5c2f4e-8d1a-4c3b-9e7f-1a2b3c4d5e6f',
  })
  url: string;
}

export class LoginPollBodyDto {
  @ApiProperty({ example: '0b5c2f4e-8d1a-4c3b-9e7f-1a2b3c4d5e6f' })
  @IsUUID('all', { message: '`login_id` deve ser um UUID.' })
  login_id: string;

  @ApiProperty({ example: 'q3Vf9yZ1kX0bA7cR2mN8pL4tW6sE5uH1jG0dK9iO3aB' })
  @IsString({ message: '`poll_secret` deve ser um texto.' })
  @IsNotEmpty({ message: '`poll_secret` é obrigatório.' })
  poll_secret: string;
}

export class RefreshBodyDto {
  @ApiProperty({ example: 'v1.MZ3a…' })
  @IsString({ message: '`refresh_token` deve ser um texto.' })
  @IsNotEmpty({ message: '`refresh_token` é obrigatório.' })
  refresh_token: string;
}

export class AuthTokensDto implements AuthTokens {
  @ApiProperty({
    description:
      'Vai no cabeçalho `Authorization: Bearer` das rotas do jogador.',
    example: 'eyJhbGciOiJFUzI1NiIsImtpZCI6…',
  })
  access_token: string;

  @ApiProperty({
    description: 'Troca por um par novo em `POST /v1/auth/refresh`.',
    example: 'v1.MZ3a…',
  })
  refresh_token: string;

  @ApiProperty({
    description: 'Segundos até o `access_token` vencer.',
    example: 3600,
  })
  expires_in: number;
}

const TOO_MANY = ApiTooManyRequestsResponse({
  description: 'Limite de chamadas por minuto excedido.',
});

/** Login, renovação e saída (.specs/auth-google/01-auth-server.md, RF-09 a RF-12). */
@ApiTags('Login')
@Controller('auth')
export class AuthController {
  constructor(
    private readonly logins: LoginSessionsService,
    private readonly supabase: SupabaseAuthClient,
  ) {}

  @Post('google/start')
  @ApiOperation({
    summary: 'Começar o login com Google',
    description:
      'Cria um login que vale 10 minutos. O jogo abre a `url` no navegador e ' +
      'pergunta em `POST /v1/auth/google/poll` a cada 2 segundos até a sessão sair.',
  })
  @ApiCreatedResponse({ type: LoginStartDto })
  @TOO_MANY
  start(): Promise<LoginStartDto> {
    return this.logins.start();
  }

  @Post('google/poll')
  @ApiOperation({
    summary: 'Perguntar se o login terminou',
    description:
      'Enquanto o jogador não entrou no navegador, responde `202`. Quando entrou, ' +
      'responde `200` com a sessão, uma vez só: o login é apagado na entrega.',
  })
  @ApiOkResponse({ type: AuthTokensDto, description: 'O jogador entrou.' })
  @ApiResponse({
    status: 202,
    description: 'Ainda esperando o jogador no navegador.',
    schema: { example: { status: 'pending' } },
  })
  @ApiBadRequestResponse({ description: 'Corpo inválido.' })
  @ApiNotFoundResponse({
    description: 'Login inexistente, segredo errado ou sessão já entregue.',
  })
  @ApiGoneResponse({
    description: 'O login venceu ou falhou. Comece outro.',
  })
  @TOO_MANY
  async poll(
    @Body() body: LoginPollBodyDto,
    @Res({ passthrough: true }) res: Response,
  ): Promise<AuthTokensDto | { status: 'pending' }> {
    const result = await this.logins.poll(body.login_id, body.poll_secret);
    if (result.status === 'pending') {
      res.status(202);
      return { status: 'pending' };
    }
    res.status(200);
    return result.tokens;
  }

  @Post('refresh')
  @HttpCode(200)
  @ApiOperation({
    summary: 'Renovar a sessão',
    description:
      'Troca o `refresh_token` por um par novo. O antigo deixa de valer.',
  })
  @ApiOkResponse({ type: AuthTokensDto })
  @ApiBadRequestResponse({ description: 'Corpo inválido.' })
  @ApiUnauthorizedResponse({
    description: 'O `refresh_token` não vale mais. Entre de novo.',
  })
  @TOO_MANY
  async refresh(@Body() body: RefreshBodyDto): Promise<AuthTokensDto> {
    try {
      return await this.supabase.refresh(body.refresh_token);
    } catch (error) {
      if (error instanceof SupabaseAuthError && error.status < 500) {
        throw new UnauthorizedException(SESSION_INVALID);
      }
      throw error;
    }
  }

  @Post('logout')
  @HttpCode(204)
  @UseGuards(AuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Sair da conta',
    description:
      'Encerra a sessão no Supabase: o `refresh_token` deixa de valer. ' +
      'Responde `204` mesmo se a sessão já tinha acabado.',
  })
  @ApiNoContentResponse({ description: 'Sessão encerrada.' })
  @ApiUnauthorizedResponse({ description: SESSION_INVALID })
  @TOO_MANY
  async logout(@Req() req: AuthenticatedRequest): Promise<void> {
    const token = req.headers.authorization!.slice('Bearer '.length);
    try {
      await this.supabase.logout(token);
    } catch (error) {
      // Sessão já encerrada no Supabase: para o jogo, o resultado é o mesmo.
      if (!(error instanceof SupabaseAuthError)) throw error;
    }
  }
}
