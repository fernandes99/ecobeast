import { createRemoteJWKSet, jwtVerify, type JWTVerifyGetKey } from 'jose';

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
