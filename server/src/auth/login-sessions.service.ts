import { GoneException, Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { isUUID } from 'class-validator';
import { createHash, randomBytes, timingSafeEqual } from 'node:crypto';
import { Env } from '../config/env.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { AuthTokens, SupabaseAuthClient } from './supabase-auth.client.js';

/** Quanto tempo um login pelo navegador vale. */
export const LOGIN_TTL_MS = 600_000;

/** 32 bytes aleatórios em base64url (o segredo do poll e o verificador do PKCE). */
export function randomToken(): string {
  return randomBytes(32).toString('base64url');
}

export function sha256Base64url(value: string): string {
  return createHash('sha256').update(value).digest('base64url');
}

/** O desafio S256 do PKCE: SHA-256 do verificador em base64url. */
export function codeChallenge(codeVerifier: string): string {
  return sha256Base64url(codeVerifier);
}

/** O login não existe, venceu, já foi usado ou não está na etapa certa. */
export class LoginUnavailableError extends Error {
  constructor() {
    super('login indisponível');
    this.name = 'LoginUnavailableError';
  }
}

export interface LoginStart {
  login_id: string;
  poll_secret: string;
  url: string;
}

export type PollResult =
  { status: 'pending' } | { status: 'complete'; tokens: AuthTokens };

/**
 * O login com Google pelo navegador (.specs/auth-google/01-auth-server.md,
 * RF-05 a RF-08): começar, ida, retorno e perguntar.
 */
@Injectable()
export class LoginSessionsService {
  private readonly publicBaseUrl: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly supabase: SupabaseAuthClient,
    config: ConfigService<Env, true>,
  ) {
    this.publicBaseUrl = config.get('PUBLIC_BASE_URL', { infer: true });
  }

  async start(): Promise<LoginStart> {
    const now = new Date();
    await this.prisma.authLoginSession.deleteMany({
      where: { expiresAt: { lt: now } },
    });
    const pollSecret = randomToken();
    const login = await this.prisma.authLoginSession.create({
      data: {
        pollSecretHash: sha256Base64url(pollSecret),
        codeVerifier: randomToken(),
        expiresAt: new Date(now.getTime() + LOGIN_TTL_MS),
      },
    });
    return {
      login_id: login.id,
      poll_secret: pollSecret,
      url: `${this.publicBaseUrl}/auth/google/go?login=${login.id}`,
    };
  }

  /** Marca a ida como usada (só uma vez) e devolve a URL de autorização. */
  async go(loginId: string): Promise<string> {
    if (!isUUID(loginId)) throw new LoginUnavailableError();
    // A condição na própria atualização garante uma ida só, mesmo com dois
    // pedidos ao mesmo tempo.
    const { count } = await this.prisma.authLoginSession.updateMany({
      where: {
        id: loginId,
        status: 'pending',
        opened: false,
        expiresAt: { gt: new Date() },
      },
      data: { opened: true },
    });
    const login =
      count === 1
        ? await this.prisma.authLoginSession.findUnique({
            where: { id: loginId },
          })
        : null;
    if (!login) throw new LoginUnavailableError();
    return this.supabase.authorizeUrl(
      `${this.publicBaseUrl}/auth/google/callback?login=${loginId}`,
      codeChallenge(login.codeVerifier),
    );
  }

  /** Troca o código do retorno pela sessão e a guarda no login. */
  async complete(loginId: string, code: string): Promise<void> {
    const login = isUUID(loginId)
      ? await this.prisma.authLoginSession.findUnique({
          where: { id: loginId },
        })
      : null;
    if (
      !login ||
      login.status !== 'pending' ||
      !login.opened ||
      login.expiresAt <= new Date()
    ) {
      throw new LoginUnavailableError();
    }
    let tokens: AuthTokens;
    try {
      tokens = await this.supabase.exchangeCode(code, login.codeVerifier);
    } catch (error) {
      await this.fail(loginId);
      throw error;
    }
    await this.prisma.authLoginSession.updateMany({
      where: { id: loginId, status: 'pending' },
      data: {
        status: 'complete',
        accessToken: tokens.access_token,
        refreshToken: tokens.refresh_token,
        expiresIn: tokens.expires_in,
      },
    });
  }

  /** Marca um login pendente como falho (o jogador recusou, ou a troca falhou). */
  async fail(loginId: string): Promise<void> {
    if (!isUUID(loginId)) return;
    await this.prisma.authLoginSession.updateMany({
      where: { id: loginId, status: 'pending' },
      data: { status: 'failed' },
    });
  }

  async poll(loginId: string, pollSecret: string): Promise<PollResult> {
    const login = isUUID(loginId)
      ? await this.prisma.authLoginSession.findUnique({
          where: { id: loginId },
        })
      : null;
    if (
      !login ||
      !sameHash(login.pollSecretHash, sha256Base64url(pollSecret))
    ) {
      throw new NotFoundException('Login não encontrado.');
    }
    if (login.status === 'failed' || login.expiresAt <= new Date()) {
      await this.prisma.authLoginSession.deleteMany({ where: { id: loginId } });
      throw new GoneException('Login expirado. Tente de novo.');
    }
    if (login.status === 'pending') return { status: 'pending' };

    // Só quem conseguir apagar a linha recebe a sessão: ela sai uma vez só.
    const { count } = await this.prisma.authLoginSession.deleteMany({
      where: { id: loginId, status: 'complete' },
    });
    if (count !== 1) throw new NotFoundException('Login não encontrado.');
    return {
      status: 'complete',
      tokens: {
        access_token: login.accessToken!,
        refresh_token: login.refreshToken!,
        expires_in: login.expiresIn!,
      },
    };
  }
}

/** Compara dois hashes em tempo constante. */
function sameHash(a: string, b: string): boolean {
  const left = Buffer.from(a);
  const right = Buffer.from(b);
  return left.length === right.length && timingSafeEqual(left, right);
}
