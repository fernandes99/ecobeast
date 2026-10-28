import { Controller, Get, Logger, Query, Res } from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger';
import type { Response } from 'express';
import {
  LoginSessionsService,
  LoginUnavailableError,
} from './login-sessions.service.js';
import { ERROR_PAGE, SUCCESS_PAGE } from './pages.js';

/**
 * As duas páginas abertas no navegador do jogador
 * (.specs/auth-google/01-auth-server.md, RF-13 e RF-14). Ficam fora do /v1
 * e da documentação: quem as chama é o navegador, não o jogo.
 */
@ApiExcludeController()
@Controller('auth/google')
export class GoogleRedirectController {
  private readonly logger = new Logger(GoogleRedirectController.name);

  constructor(private readonly logins: LoginSessionsService) {}

  /** A ida: leva ao Google pelo Supabase. Vale uma vez por login. */
  @Get('go')
  async go(
    @Query('login') loginId: unknown,
    @Res() res: Response,
  ): Promise<void> {
    try {
      res.redirect(302, await this.logins.go(String(loginId ?? '')));
    } catch (error) {
      if (!(error instanceof LoginUnavailableError)) throw error;
      sendPage(res, 400, ERROR_PAGE);
    }
  }

  /** O retorno do Google: troca o código pela sessão e guarda no login. */
  @Get('callback')
  async callback(
    @Query('login') loginId: unknown,
    @Query('code') code: unknown,
    @Query('error') error: unknown,
    @Res() res: Response,
  ): Promise<void> {
    const id = String(loginId ?? '');
    if (typeof code !== 'string' || code === '' || error !== undefined) {
      await this.logins.fail(id);
      sendPage(res, 400, ERROR_PAGE);
      return;
    }
    try {
      await this.logins.complete(id, code);
      sendPage(res, 200, SUCCESS_PAGE);
    } catch (failure) {
      if (!(failure instanceof LoginUnavailableError)) {
        this.logger.warn(
          `Falha ao trocar o código do login: ${(failure as Error).message}`,
        );
      }
      sendPage(res, 400, ERROR_PAGE);
    }
  }
}

function sendPage(res: Response, status: number, html: string): void {
  res.status(status).type('html').setHeader('Cache-Control', 'no-store');
  res.send(html);
}
