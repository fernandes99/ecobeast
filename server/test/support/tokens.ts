import {
  createLocalJWKSet,
  exportJWK,
  generateKeyPair,
  type JWTPayload,
  SignJWT,
} from 'jose';
import { TokenVerifier } from '../../src/auth/token-verifier.js';

const KID = 'chave-de-teste';

export interface TestTokens {
  verifier: TokenVerifier;
  sign(sub: string, claims?: JWTPayload): Promise<string>;
}

export async function createTestTokens(): Promise<TestTokens> {
  const issuer = `${process.env['SUPABASE_URL']}/auth/v1`;
  const { publicKey, privateKey } = await generateKeyPair('ES256');
  const jwk = { ...(await exportJWK(publicKey)), kid: KID, alg: 'ES256' };
  return {
    verifier: new TokenVerifier(createLocalJWKSet({ keys: [jwk] }), issuer),
    sign: (sub, claims = {}) =>
      new SignJWT({ aud: 'authenticated', iss: issuer, sub, ...claims })
        .setProtectedHeader({ alg: 'ES256', kid: KID })
        .setIssuedAt()
        .setExpirationTime('1h')
        .sign(privateKey),
  };
}
