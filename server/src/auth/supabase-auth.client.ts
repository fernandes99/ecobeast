import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Env } from '../config/env.js';

/** A sessão do Supabase que o jogo guarda. */
export interface AuthTokens {
  access_token: string;
  refresh_token: string;
  /** Segundos até o access token vencer. */
  expires_in: number;
}

/** Resposta do Supabase Auth fora de 2xx (ou sem os tokens esperados). */
export class SupabaseAuthError extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message);
    this.name = 'SupabaseAuthError';
  }
}

/**
 * As chamadas REST ao Supabase Auth (.specs/auth-google/01-auth-server.md,
 * RF-03 e RF-04), sem o supabase-js. Trocado por um dublê nos testes.
 */
@Injectable()
export class SupabaseAuthClient {
  private readonly authUrl: string;
  private readonly key: string;

  constructor(config: ConfigService<Env, true>) {
    this.authUrl = `${config.get('SUPABASE_URL', { infer: true })}/auth/v1`;
    this.key = config.get('SUPABASE_PUBLISHABLE_KEY', { infer: true });
  }

  /** A página do Supabase que leva ao Google e volta em `redirectTo`. */
  authorizeUrl(redirectTo: string, codeChallenge: string): string {
    const params = new URLSearchParams({
      provider: 'google',
      redirect_to: redirectTo,
      code_challenge: codeChallenge,
      code_challenge_method: 's256',
    });
    return `${this.authUrl}/authorize?${params.toString()}`;
  }

  exchangeCode(code: string, codeVerifier: string): Promise<AuthTokens> {
    return this.token('pkce', { auth_code: code, code_verifier: codeVerifier });
  }

  refresh(refreshToken: string): Promise<AuthTokens> {
    return this.token('refresh_token', { refresh_token: refreshToken });
  }

  async logout(accessToken: string): Promise<void> {
    const response = await fetch(`${this.authUrl}/logout`, {
      method: 'POST',
      headers: { ...this.headers(), Authorization: `Bearer ${accessToken}` },
    });
    if (!response.ok) {
      throw new SupabaseAuthError(response.status, 'logout recusado');
    }
  }

  private async token(
    grantType: string,
    body: Record<string, string>,
  ): Promise<AuthTokens> {
    const response = await fetch(
      `${this.authUrl}/token?grant_type=${grantType}`,
      { method: 'POST', headers: this.headers(), body: JSON.stringify(body) },
    );
    if (!response.ok) {
      throw new SupabaseAuthError(response.status, `${grantType} recusado`);
    }
    const data = (await response.json()) as Partial<AuthTokens>;
    if (
      typeof data.access_token !== 'string' ||
      typeof data.refresh_token !== 'string' ||
      typeof data.expires_in !== 'number'
    ) {
      throw new SupabaseAuthError(response.status, 'resposta sem a sessão');
    }
    return {
      access_token: data.access_token,
      refresh_token: data.refresh_token,
      expires_in: data.expires_in,
    };
  }

  private headers(): Record<string, string> {
    return { apikey: this.key, 'Content-Type': 'application/json' };
  }
}
