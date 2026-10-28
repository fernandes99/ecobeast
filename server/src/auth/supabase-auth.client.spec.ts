import { ConfigService } from '@nestjs/config';
import { Env } from '../config/env.js';
import {
  SupabaseAuthClient,
  SupabaseAuthError,
} from './supabase-auth.client.js';

const SUPABASE_URL = 'https://projeto.supabase.co';
const KEY = 'sb_publishable_exemplo';

function client(): SupabaseAuthClient {
  const env: Partial<Env> = {
    SUPABASE_URL,
    SUPABASE_PUBLISHABLE_KEY: KEY,
  };
  return new SupabaseAuthClient({
    get: (key: keyof Env) => env[key],
  } as unknown as ConfigService<Env, true>);
}

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

const SUPABASE_SESSION = {
  access_token: 'access',
  refresh_token: 'refresh',
  expires_in: 3600,
  expires_at: 1_900_000_000,
  token_type: 'bearer',
  user: { id: 'u1', email: 'alguem@exemplo.com' },
};

describe('SupabaseAuthClient', () => {
  let fetchMock: ReturnType<typeof vi.spyOn>;

  beforeEach(() => {
    fetchMock = vi.spyOn(globalThis, 'fetch');
  });

  afterEach(() => {
    fetchMock.mockRestore();
  });

  function lastCall(): { url: string; init: RequestInit } {
    const [url, init] = fetchMock.mock.calls.at(-1) as [string, RequestInit];
    return { url, init };
  }

  it('monta a URL de autorização do Google com PKCE e valores codificados', () => {
    const url = new URL(
      client().authorizeUrl(
        'http://localhost:3100/auth/google/callback?login=abc',
        'desafio-123',
      ),
    );
    expect(url.origin + url.pathname).toBe(`${SUPABASE_URL}/auth/v1/authorize`);
    expect(url.searchParams.get('provider')).toBe('google');
    expect(url.searchParams.get('redirect_to')).toBe(
      'http://localhost:3100/auth/google/callback?login=abc',
    );
    expect(url.searchParams.get('code_challenge')).toBe('desafio-123');
    expect(url.searchParams.get('code_challenge_method')).toBe('s256');
    // O "?" e o "=" do redirect_to não podem vazar para a URL de fora.
    expect(url.search).toContain(
      'redirect_to=http%3A%2F%2Flocalhost%3A3100%2Fauth%2Fgoogle%2Fcallback%3Flogin%3Dabc',
    );
  });

  it('troca o código pela sessão com o verificador do PKCE', async () => {
    fetchMock.mockResolvedValue(jsonResponse(200, SUPABASE_SESSION));
    const tokens = await client().exchangeCode('codigo', 'verificador');

    expect(tokens).toEqual({
      access_token: 'access',
      refresh_token: 'refresh',
      expires_in: 3600,
    });
    const { url, init } = lastCall();
    expect(url).toBe(`${SUPABASE_URL}/auth/v1/token?grant_type=pkce`);
    expect(init.method).toBe('POST');
    expect(init.headers).toMatchObject({
      apikey: KEY,
      'Content-Type': 'application/json',
    });
    expect(JSON.parse(init.body as string)).toEqual({
      auth_code: 'codigo',
      code_verifier: 'verificador',
    });
  });

  it('renova a sessão pelo refresh token', async () => {
    fetchMock.mockResolvedValue(jsonResponse(200, SUPABASE_SESSION));
    const tokens = await client().refresh('refresh-antigo');

    expect(tokens.access_token).toBe('access');
    const { url, init } = lastCall();
    expect(url).toBe(`${SUPABASE_URL}/auth/v1/token?grant_type=refresh_token`);
    expect(init.headers).toMatchObject({ apikey: KEY });
    expect(JSON.parse(init.body as string)).toEqual({
      refresh_token: 'refresh-antigo',
    });
  });

  it('encerra a sessão com o access token', async () => {
    fetchMock.mockResolvedValue(new Response(null, { status: 204 }));
    await client().logout('access');

    const { url, init } = lastCall();
    expect(url).toBe(`${SUPABASE_URL}/auth/v1/logout`);
    expect(init.method).toBe('POST');
    expect(init.headers).toMatchObject({
      apikey: KEY,
      Authorization: 'Bearer access',
    });
  });

  it('transforma uma resposta de erro em SupabaseAuthError com o código', async () => {
    fetchMock.mockResolvedValue(
      jsonResponse(400, { error: 'invalid_grant', error_description: 'x' }),
    );
    const error = await client()
      .refresh('ruim')
      .catch((e: unknown) => e);

    expect(error).toBeInstanceOf(SupabaseAuthError);
    expect((error as SupabaseAuthError).status).toBe(400);
  });

  it('recusa uma resposta 2xx sem os tokens', async () => {
    fetchMock.mockResolvedValue(jsonResponse(200, { user: {} }));
    await expect(client().exchangeCode('c', 'v')).rejects.toBeInstanceOf(
      SupabaseAuthError,
    );
  });

  it('logout também transforma erro em SupabaseAuthError', async () => {
    fetchMock.mockResolvedValue(
      jsonResponse(403, { msg: 'session_not_found' }),
    );
    await expect(client().logout('vencido')).rejects.toMatchObject({
      status: 403,
    });
  });
});
