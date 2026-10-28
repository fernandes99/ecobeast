import { INestApplication } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { codeChallenge } from '../src/auth/login-sessions.service.js';
import {
  AuthTokens,
  SupabaseAuthClient,
  SupabaseAuthError,
} from '../src/auth/supabase-auth.client.js';
import { Env } from '../src/config/env.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

const SUPABASE_URL = process.env['SUPABASE_URL']!;
const PUBLIC_BASE_URL = process.env['PUBLIC_BASE_URL']!;
const TOKENS: AuthTokens = {
  access_token: 'access-do-google',
  refresh_token: 'refresh-do-google',
  expires_in: 3600,
};

describe('Login com Google (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  // O cliente de verdade monta a URL de autorização; as chamadas de rede são dublês.
  const supabase = new SupabaseAuthClient({
    get: (key: keyof Env) =>
      ({ SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY: 'teste' })[
        key as 'SUPABASE_URL'
      ],
  } as unknown as ConfigService<Env, true>);
  const exchangeCode = vi.spyOn(supabase, 'exchangeCode');
  const refresh = vi.spyOn(supabase, 'refresh');
  const logout = vi.spyOn(supabase, 'logout');
  const created: string[] = [];

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({
      supabaseAuth: supabase,
      tokenVerifier: tokens.verifier,
    });
  });

  afterAll(async () => {
    await prisma.authLoginSession.deleteMany({
      where: { id: { in: created } },
    });
    await prisma.$disconnect();
    await app.close();
  });

  beforeEach(() => {
    exchangeCode.mockReset().mockResolvedValue(TOKENS);
    refresh.mockReset();
    logout.mockReset().mockResolvedValue(undefined);
  });

  async function start(): Promise<{
    login_id: string;
    poll_secret: string;
    url: string;
  }> {
    const res = await request(app.getHttpServer())
      .post('/v1/auth/google/start')
      .expect(201);
    created.push(res.body.login_id);
    return res.body;
  }

  function poll(loginId: string, pollSecret: string) {
    return request(app.getHttpServer())
      .post('/v1/auth/google/poll')
      .send({ login_id: loginId, poll_secret: pollSecret });
  }

  function go(loginId: string) {
    return request(app.getHttpServer()).get(`/auth/google/go?login=${loginId}`);
  }

  function callback(query: string) {
    return request(app.getHttpServer()).get(`/auth/google/callback?${query}`);
  }

  it('start → go → callback → poll entrega a sessão uma vez', async () => {
    const login = await start();
    expect(login.url).toBe(
      `${PUBLIC_BASE_URL}/auth/google/go?login=${login.login_id}`,
    );

    await poll(login.login_id, login.poll_secret)
      .expect(202)
      .expect({ status: 'pending' });

    const ida = await go(login.login_id).expect(302);
    const authorize = new URL(ida.headers['location'] as string);
    expect(authorize.origin + authorize.pathname).toBe(
      `${SUPABASE_URL}/auth/v1/authorize`,
    );
    expect(authorize.searchParams.get('provider')).toBe('google');
    expect(authorize.searchParams.get('code_challenge_method')).toBe('s256');
    expect(authorize.searchParams.get('redirect_to')).toBe(
      `${PUBLIC_BASE_URL}/auth/google/callback?login=${login.login_id}`,
    );

    const page = await callback(
      `login=${login.login_id}&code=codigo-do-google`,
    ).expect(200);
    expect(page.headers['content-type']).toMatch(/text\/html/);
    expect(page.text).toContain('Pronto!');
    expect(page.text).toContain('Pode voltar ao jogo.');

    // O código foi trocado com o verificador cujo desafio foi para o Supabase.
    const [code, verifier] = exchangeCode.mock.calls[0]!;
    expect(code).toBe('codigo-do-google');
    expect(codeChallenge(verifier)).toBe(
      authorize.searchParams.get('code_challenge'),
    );

    await poll(login.login_id, login.poll_secret).expect(200).expect(TOKENS);
    await poll(login.login_id, login.poll_secret).expect(404);
  });

  it('poll com o segredo errado dá 404', async () => {
    const login = await start();
    const res = await poll(login.login_id, 'segredo-errado').expect(404);
    expect(res.body.message).toBe('Login não encontrado.');
  });

  it('poll com corpo inválido dá 400', async () => {
    await poll('nao-e-uuid', 'x').expect(400);
    await request(app.getHttpServer())
      .post('/v1/auth/google/poll')
      .send({})
      .expect(400);
  });

  it('poll depois de 10 minutos dá 410', async () => {
    const login = await start();
    await prisma.authLoginSession.update({
      where: { id: login.login_id },
      data: { expiresAt: new Date(Date.now() - 1000) },
    });
    const res = await poll(login.login_id, login.poll_secret).expect(410);
    expect(res.body.message).toBe('Login expirado. Tente de novo.');
  });

  it('a ida aberta duas vezes mostra a página de erro na segunda', async () => {
    const login = await start();
    await go(login.login_id).expect(302);
    const page = await go(login.login_id).expect(400);
    expect(page.headers['content-type']).toMatch(/text\/html/);
    expect(page.text).toContain('Não foi possível entrar');
  });

  it('a ida de um login que não existe mostra a página de erro', async () => {
    await go('00000000-0000-4000-8000-000000000000').expect(400);
    await go('nao-e-uuid').expect(400);
    await request(app.getHttpServer()).get('/auth/google/go').expect(400);
  });

  it('o jogador recusar no Google mostra o erro e o poll dá 410', async () => {
    const login = await start();
    await go(login.login_id).expect(302);
    const page = await callback(
      `login=${login.login_id}&error=access_denied&error_description=recusou`,
    ).expect(400);
    expect(page.text).toContain('Volte ao Ecobeast e tente de novo.');
    expect(exchangeCode).not.toHaveBeenCalled();
    await poll(login.login_id, login.poll_secret).expect(410);
  });

  it('a troca do código falhar mostra o erro e o poll dá 410', async () => {
    const login = await start();
    await go(login.login_id).expect(302);
    exchangeCode.mockRejectedValueOnce(new SupabaseAuthError(400, 'x'));
    const page = await callback(`login=${login.login_id}&code=ruim`).expect(
      400,
    );
    expect(page.text).toContain('Não foi possível entrar');
    await poll(login.login_id, login.poll_secret).expect(410);
  });

  it('o retorno sem ida mostra o erro sem trocar o código', async () => {
    const login = await start();
    await callback(`login=${login.login_id}&code=codigo`).expect(400);
    expect(exchangeCode).not.toHaveBeenCalled();
  });

  it('refresh repassa ao Supabase e devolve o par novo', async () => {
    const novo = { ...TOKENS, access_token: 'novo' };
    refresh.mockResolvedValue(novo);
    await request(app.getHttpServer())
      .post('/v1/auth/refresh')
      .send({ refresh_token: 'refresh-antigo' })
      .expect(200)
      .expect(novo);
    expect(refresh).toHaveBeenCalledWith('refresh-antigo');
  });

  it('refresh recusado pelo Supabase dá 401', async () => {
    refresh.mockRejectedValue(new SupabaseAuthError(400, 'invalid_grant'));
    const res = await request(app.getHttpServer())
      .post('/v1/auth/refresh')
      .send({ refresh_token: 'vencido' })
      .expect(401);
    expect(res.body.message).toBe('Sessão inválida. Entre de novo.');
  });

  it('refresh sem refresh_token dá 400', async () => {
    await request(app.getHttpServer())
      .post('/v1/auth/refresh')
      .send({})
      .expect(400);
  });

  it('logout exige a sessão', async () => {
    const res = await request(app.getHttpServer())
      .post('/v1/auth/logout')
      .expect(401);
    expect(res.body.message).toBe('Sessão inválida. Entre de novo.');
    await request(app.getHttpServer())
      .post('/v1/auth/logout')
      .set('Authorization', 'Bearer token-falso')
      .expect(401);
    expect(logout).not.toHaveBeenCalled();
  });

  it('logout repassa o access token e dá 204', async () => {
    const access = await tokens.sign('5b1d2c9e-1111-4222-8333-444455556666');
    await request(app.getHttpServer())
      .post('/v1/auth/logout')
      .set('Authorization', `Bearer ${access}`)
      .expect(204);
    expect(logout).toHaveBeenCalledWith(access);
  });

  it('logout dá 204 mesmo se o Supabase já encerrou a sessão', async () => {
    logout.mockRejectedValue(new SupabaseAuthError(403, 'session_not_found'));
    const access = await tokens.sign('5b1d2c9e-1111-4222-8333-444455556666');
    await request(app.getHttpServer())
      .post('/v1/auth/logout')
      .set('Authorization', `Bearer ${access}`)
      .expect(204);
  });

  it('as páginas do navegador ficam fora do /v1 e da documentação', async () => {
    await request(app.getHttpServer()).get('/v1/auth/google/go').expect(404);
    const doc = await request(app.getHttpServer())
      .get('/docs/openapi.json')
      .expect(200);
    const paths = Object.keys(doc.body.paths as object);
    expect(paths).toEqual(
      expect.arrayContaining([
        '/v1/auth/google/start',
        '/v1/auth/google/poll',
        '/v1/auth/refresh',
        '/v1/auth/logout',
      ]),
    );
    expect(paths.some((path) => path.startsWith('/auth/'))).toBe(false);
    expect(doc.body.components.securitySchemes.bearer).toMatchObject({
      type: 'http',
      scheme: 'bearer',
    });
    expect(doc.body.paths['/v1/auth/logout'].post.security).toEqual([
      { bearer: [] },
    ]);
  });
});
