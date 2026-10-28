import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { AuthenticatedRequest, AuthGuard } from './auth.guard.js';
import { TokenVerifier } from './token-verifier.js';

function context(request: Partial<AuthenticatedRequest>): ExecutionContext {
  return {
    switchToHttp: () => ({ getRequest: () => request }),
  } as unknown as ExecutionContext;
}

function guard(): AuthGuard {
  const verifier = {
    verify: (token: string) =>
      token === 'valido'
        ? Promise.resolve({ userId: 'u1' })
        : Promise.reject(new Error('assinatura inválida')),
  };
  return new AuthGuard(verifier as unknown as TokenVerifier);
}

const SESSION_INVALID = {
  response: { message: 'Sessão inválida. Entre de novo.' },
};

describe('AuthGuard', () => {
  it('aceita o Bearer válido e põe o id do usuário na requisição', async () => {
    const request: Partial<AuthenticatedRequest> = {
      headers: { authorization: 'Bearer valido' },
    };
    await expect(guard().canActivate(context(request))).resolves.toBe(true);
    expect(request.userId).toBe('u1');
  });

  it('recusa sem o cabeçalho Authorization', async () => {
    const error = await guard()
      .canActivate(context({ headers: {} }))
      .catch((e: unknown) => e);
    expect(error).toBeInstanceOf(UnauthorizedException);
    expect(error).toMatchObject(SESSION_INVALID);
  });

  it('recusa outro esquema que não Bearer', async () => {
    await expect(
      guard().canActivate(
        context({ headers: { authorization: 'Basic valido' } }),
      ),
    ).rejects.toMatchObject(SESSION_INVALID);
  });

  it('recusa o token que o verificador não aceita', async () => {
    await expect(
      guard().canActivate(
        context({ headers: { authorization: 'Bearer ruim' } }),
      ),
    ).rejects.toMatchObject(SESSION_INVALID);
  });
});
