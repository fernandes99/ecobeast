import { createRemoteJWKSet, jwtVerify, type JWTVerifyGetKey } from 'jose';

/**
 * Confere o access token do Supabase (.specs/auth-google/01-auth-server.md,
 * RF-15): assinatura pelas chaves públicas do projeto (JWKS, guardadas em
 * memória pela jose), emissor, audiência `authenticated` e validade.
 * Nos testes, recebe um JWKS local.
 */
export class TokenVerifier {
  constructor(
    private readonly keys: JWTVerifyGetKey,
    readonly issuer: string,
  ) {}

  static forSupabase(supabaseUrl: string): TokenVerifier {
    const issuer = `${supabaseUrl}/auth/v1`;
    return new TokenVerifier(
      createRemoteJWKSet(new URL(`${issuer}/.well-known/jwks.json`)),
      issuer,
    );
  }

  /** O id do usuário (o `sub`); lança se o token não vale. */
  async verify(token: string): Promise<{ userId: string }> {
    const { payload } = await jwtVerify(token, this.keys, {
      issuer: this.issuer,
      audience: 'authenticated',
      algorithms: ['ES256', 'RS256'],
    });
    if (typeof payload.sub !== 'string' || payload.sub === '') {
      throw new Error('token sem sub');
    }
    return { userId: payload.sub };
  }
}
